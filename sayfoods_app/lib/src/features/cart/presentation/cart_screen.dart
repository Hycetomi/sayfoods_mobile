import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/cart/application/cart_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --- New Imports for Dynamic Checkout ---
import 'package:sayfoods_app/src/features/profile/application/address_provider.dart';
import 'package:sayfoods_app/src/features/profile/application/delivery_zone_provider.dart';
import 'package:sayfoods_app/src/features/profile/domain/address_model.dart';
import 'package:sayfoods_app/src/features/profile/presentation/profile_screen.dart';
import 'package:sayfoods_app/src/features/cart/presentation/paystack_webview.dart';

import 'package:sayfoods_app/src/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:sayfoods_app/src/features/cart/presentation/widgets/cart_summary_row.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';

// 1. Upgraded to a Stateful Consumer Widget to hold the selected address state
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final Color _primaryPurple = AppColors.primary;

  String? _selectedAddressId;
  bool _isProcessingPayment = false;

  Future<String?> _saveOrderToSupabase(
    String reference,
    double grandTotal,
    double subTotal,
    double deliveryFee,
    List<CartItem> items,
    String deliveryAddressText, {
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Insert Order
      final orderData = await supabase
          .from('orders')
          .insert({
            'client_id': user.id,
            'status': 'pending',
            'delivery_address': deliveryAddressText,
            'delivery_latitude': deliveryLat,
            'delivery_longitude': deliveryLng,
            'subtotal': subTotal,
            'delivery_fee': deliveryFee,
            'total_amount': grandTotal,
            'payment_reference': reference,
            'payment_status': 'pending',
            'payment_method': 'Paystack',
          })
          .select()
          .single();

      final orderId = orderData['id'] as String;

      // 2. Insert Order Items
      final orderItemsData = items
          .map(
            (item) => {
              'order_id': orderId,
              'product_id': item.product.id,
              'quantity': item.quantity,
              'price_at_purchase': item.product.price,
            },
          )
          .toList();

      await supabase.from('order_items').insert(orderItemsData);

      return orderId;
    } catch (e, st) {
      debugPrint('[CHECKOUT] ❌ _saveOrderToSupabase error: $e\n$st');
      return null;
    }
  }

  Future<String?> _createAuthorizationUrl(
    String reference,
    int amountInKobo,
    String email,
    String orderId,
  ) async {
    // ⚠️ NOTE: Secret Key used here for dev/testing only.
    // Move this call to a Supabase Edge Function before production.
    const String secretKey = 'sk_test_f67c30c4f53e95f01ad02b52546b3a3d449db57b';

    debugPrint('[CHECKOUT] 🌐 Calling Paystack /transaction/initialize — ref: $reference  amount: ${amountInKobo}kobo  orderId: $orderId');
    try {
      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'amount': amountInKobo,
          'reference': reference,
          'callback_url': 'https://sayfoods.app/checkout/success',
          'metadata': {'order_id': orderId},
        }),
      );

      debugPrint('[CHECKOUT] 🌐 Paystack API status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['data']['authorization_url'] as String?;
        debugPrint('[CHECKOUT] ✅ Authorization URL received: $url');
        return url;
      } else {
        debugPrint('[CHECKOUT] ❌ Paystack API error body: ${response.body}');
        return null;
      }
    } catch (e, st) {
      debugPrint('[CHECKOUT] ❌ HTTP request failed: $e\n$st');
      return null;
    }
  }

  Future<void> _verifyPaymentWithServer(String reference, String orderId) async {
    const secretKey = 'sk_test_f67c30c4f53e95f01ad02b52546b3a3d449db57b';

    // Step A — try the shared Supabase edge function first
    debugPrint('[CHECKOUT] 🔍 [A] Calling paystack-verify edge function — ref: $reference  orderId: $orderId');
    try {
      final edgeResponse = await Supabase.instance.client.functions.invoke(
        'paystack-verify',
        body: {'reference': reference},
      );
      debugPrint('[CHECKOUT] 🔍 [A] Edge function raw response: ${edgeResponse.data}');
      final data = edgeResponse.data;
      if (data is Map && data['status'] == 'success') {
        debugPrint('[CHECKOUT] ✅ [A] Edge function verified & updated DB');
        return;
      }
      debugPrint('[CHECKOUT] ⚠️  [A] Edge function returned non-success status — falling through to direct verify');
    } catch (e, st) {
      debugPrint('[CHECKOUT] ⚠️  [A] Edge function threw: $e\n$st — falling through to direct verify');
    }

    // Step B — direct Paystack verify + Supabase update as fallback
    debugPrint('[CHECKOUT] 🔍 [B] Direct Paystack verify — ref: $reference');
    try {
      final verifyRes = await http.get(
        Uri.parse('https://api.paystack.co/transaction/verify/$reference'),
        headers: {'Authorization': 'Bearer $secretKey'},
      );
      debugPrint('[CHECKOUT] 🔍 [B] Paystack verify HTTP status: ${verifyRes.statusCode}');
      if (verifyRes.statusCode == 200) {
        final body = jsonDecode(verifyRes.body) as Map<String, dynamic>;
        final paystackStatus = (body['data'] as Map?)?['status'] as String?;
        debugPrint('[CHECKOUT] 🔍 [B] Paystack transaction status: $paystackStatus');
        if (paystackStatus == 'success') {
          final updateRes = await Supabase.instance.client
              .from('orders')
              .update({'payment_status': 'paid', 'status': 'accepted'})
              .eq('id', orderId)
              .select();
          debugPrint('[CHECKOUT] ✅ [B] Supabase updated — rows affected: ${(updateRes as List).length}');
        } else {
          debugPrint('[CHECKOUT] ⚠️  [B] Paystack says payment not successful: $paystackStatus');
        }
      } else {
        debugPrint('[CHECKOUT] ❌ [B] Paystack verify HTTP error: ${verifyRes.body}');
      }
    } catch (e, st) {
      debugPrint('[CHECKOUT] ❌ [B] Direct verify failed: $e\n$st');
    }
  }

  Future<void> _processPayment(
    double grandTotal,
    double subTotal,
    double deliveryFee,
    List<CartItem> cartItems,
    String deliveryAddressText, {
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    if (_isProcessingPayment) return;

    debugPrint('[CHECKOUT] ▶️  _processPayment started — grandTotal: $grandTotal  subTotal: $subTotal  deliveryFee: $deliveryFee');
    setState(() => _isProcessingPayment = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null || user.email == null) {
        debugPrint('[CHECKOUT] ⚠️  No authenticated user found');
        if (mounted) {
          SayfoodsModal.show(
            context: context,
            type: SayfoodsModalType.warning,
            title: 'Login Required',
            subtitle: 'Please log in to checkout.',
          );
        }
        return;
      }

      debugPrint('[CHECKOUT] 👤 User: ${user.id}  email: ${user.email}');
      final amountInKobo = (grandTotal * 100).toInt();
      final reference = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('[CHECKOUT] 💰 amountInKobo: $amountInKobo  reference: $reference');

      // Step 1 — persist pending order to Supabase
      debugPrint('[CHECKOUT] 📝 Step 1: saving order to Supabase...');
      final orderId = await _saveOrderToSupabase(
        reference,
        grandTotal,
        subTotal,
        deliveryFee,
        cartItems,
        deliveryAddressText,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
      );
      debugPrint('[CHECKOUT] 📝 Step 1 result — orderId: $orderId');

      if (orderId == null) {
        if (mounted) {
          SayfoodsModal.show(
            context: context,
            type: SayfoodsModalType.error,
            title: 'Order Failed',
            subtitle: 'Could not create order. Try again.',
          );
        }
        return;
      }

      // Step 2 — fetch Paystack authorization URL
      debugPrint('[CHECKOUT] 🔑 Step 2: fetching Paystack authorization URL...');
      final authUrl = await _createAuthorizationUrl(
        reference,
        amountInKobo,
        user.email!,
        orderId,
      );
      debugPrint('[CHECKOUT] 🔑 Step 2 result — authUrl: $authUrl');

      if (authUrl == null) {
        if (mounted) {
          SayfoodsModal.show(
            context: context,
            type: SayfoodsModalType.error,
            title: 'Payment Error',
            subtitle: 'Failed to initialize payment. Please try again.',
          );
        }
        return;
      }

      // Step 3 — open Paystack checkout in WebView (pure Dart, no native SDK)
      debugPrint('[CHECKOUT] 🚀 Step 3: opening PaystackWebView...');
      if (!mounted) return;

      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => PaystackWebView(
            authorizationUrl: authUrl,
            reference: reference,
          ),
        ),
      );

      debugPrint('[CHECKOUT] 🚀 Step 3 result — $result');

      if (!mounted) return;

      final status = result?['status'] as String? ?? 'cancelled';

      if (status == 'success') {
        debugPrint('[CHECKOUT] ✅ Payment successful! reference: $reference');
        // Verify with server — updates payment_status → 'paid' and status → 'accepted'
        await _verifyPaymentWithServer(reference, orderId);
        if (!mounted) return;
        ref.read(cartProvider.notifier).clearCart();
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Success!',
          subtitle: 'Payment Successful! Order submitted.',
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        debugPrint('[CHECKOUT] ⚠️  Payment not completed — status: $status');
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.warning,
          title: 'Payment Cancelled',
          subtitle: 'Your payment was not completed. Your order has been saved — tap Place Order to try again.',
        );
      }
    } catch (e, st) {
      debugPrint('[CHECKOUT] 💥 CRASH in _processPayment: $e\n$st');
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Checkout Error',
          subtitle: 'An error occurred during checkout. See logs for details.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  // --- Bottom Sheet to Select Address ---
  void _showAddressSelector(List<AddressModel> addresses, var zones) {
    SayfoodsModal.showBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (addresses.isEmpty)
              const Text(
                'No addresses saved.',
                style: TextStyle(color: Colors.grey),
              ),
            ...addresses.map((address) {
              // Find the zone name for the list
              String zoneName = 'Unknown Zone';
              if (zones != null) {
                final matched = zones
                    .where((z) => z.id == address.zoneId)
                    .toList();
                if (matched.isNotEmpty) zoneName = matched.first.name;
              }

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.mapPin, color: AppColors.error),
                title: Text(
                  '${address.label != null ? '${address.label}: ' : ''}${address.street}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Zone: $zoneName'),
                trailing:
                    _selectedAddressId == address.id ||
                        (_selectedAddressId == null &&
                            address.id == addresses.first.id)
                    ? const Icon(LucideIcons.checkCircle, color: AppColors.success)
                    : null,
                onTap: () {
                  // Update the state and recalculate the cart!
                  setState(() => _selectedAddressId = address.id);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
            const Divider(),
            // Quick link to go add a new address
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              icon: const Icon(LucideIcons.plus, color: AppColors.textPrimary),
              label: const Text(
                'Add a new address',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Providers ---
    final cartItems = ref.watch(cartProvider);
    final subTotal = ref.watch(cartTotalProvider);
    final addressesAsyncValue = ref.watch(addressProvider);
    final zonesAsyncValue = ref.watch(deliveryZoneProvider);

    // --- Dynamic Delivery Logic (Optimized) ---
    double deliveryFee = 0.0;
    AddressModel? activeAddress;

    final addresses = addressesAsyncValue.value ?? [];

    if (addresses.isNotEmpty) {
      final targetId = _selectedAddressId ?? addresses.first.id;
      for (final a in addresses) {
        if (a.id == targetId) {
          activeAddress = a;
          break;
        }
      }
    }

    if (activeAddress != null && zonesAsyncValue.hasValue) {
      for (final z in zonesAsyncValue.value!) {
        if (z.id == activeAddress.zoneId) {
          deliveryFee = z.price;
          break;
        }
      }
    }

    // Final Math
    final grandTotal = subTotal > 0 ? subTotal + deliveryFee : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SayfoodsAppBar(
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.user, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),

      // Sticky Bottom Button
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: AppColors.surface,
              child: SafeArea(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isProcessingPayment
                        ? null
                        : () {
                            if (activeAddress == null) {
                              SayfoodsModal.show(
                                context: context,
                                type: SayfoodsModalType.warning,
                                title: 'Address Required',
                                subtitle: 'Please add a delivery address first.',
                              );
                              return;
                            }

                            // Format address
                            String addressText =
                                '${activeAddress.street}, ${activeAddress.city ?? "Lagos"}';
                            if (activeAddress.label != null &&
                                activeAddress.label!.isNotEmpty) {
                              addressText = '${activeAddress.label}: $addressText';
                            }

                            _processPayment(
                              grandTotal,
                              subTotal,
                              deliveryFee,
                              cartItems,
                              addressText,
                              deliveryLat: activeAddress.latitude,
                              deliveryLng: activeAddress.longitude,
                            );
                          },
                    child: _isProcessingPayment
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Place order',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Total - ₦${grandTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.shoppingCart,
                    size: 80,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Cart is Empty',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Looks like you haven\'t added anything yet.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Start Shopping',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'CHECKOUT',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),

                  // 1. Cart Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartItemCard(item: item);
                    },
                  ),
                  const SizedBox(height: 32),

                  // 2. Dynamic Address Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ADDRESS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Show dynamic address or a prompt to add one
                            addressesAsyncValue.isLoading
                                ? const Text(
                                    'Loading address...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      height: 1.4,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : activeAddress != null
                                    ? Text(
                                        '${activeAddress.label != null ? '${activeAddress.label}\n' : ''}${activeAddress.street},\n${activeAddress.city ?? 'Lagos'}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      )
                                    : const Text(
                                        'No address selected.\nPlease add an address.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          height: 1.4,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.edit3,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          // Open the address selector!
                          _showAddressSelector(
                            addresses,
                            zonesAsyncValue.value,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 3. Dynamic Order Summary
                  CartSummaryRow(label: 'Sub - total', amount: subTotal),
                  const SizedBox(height: 12),
                  CartSummaryRow(label: 'Delivery fee', amount: deliveryFee),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₦${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
