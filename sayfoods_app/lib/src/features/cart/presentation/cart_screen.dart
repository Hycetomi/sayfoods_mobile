import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/cart/application/cart_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Need this to get the user's email
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --- New Imports for Dynamic Checkout ---
import 'package:sayfoods_app/src/features/profile/application/address_provider.dart';
import 'package:sayfoods_app/src/features/profile/application/delivery_zone_provider.dart';
import 'package:sayfoods_app/src/features/profile/domain/address_model.dart';
import 'package:sayfoods_app/src/features/profile/presentation/profile_screen.dart';

import 'package:sayfoods_app/src/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:sayfoods_app/src/features/cart/presentation/widgets/cart_summary_row.dart';

// 1. Upgraded to a Stateful Consumer Widget to hold the selected address state
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final Color _primaryPurple = const Color(0xFF5A189A);

  // Local state to remember which address they selected for this order
  String? _selectedAddressId;

  // NEW: Initialize the official SDK
  final _paystack = Paystack();

  @override
  void initState() {
    super.initState();
    // NEW: The setup is now async, so we just let it run
    _setupPaystack();
  }

  Future<void> _setupPaystack() async {
    try {
      await _paystack.initialize(
        'pk_test_5c808e19614b5e5596b4f269b335273d813473dc',
        true,
      );
      print('Paystack Official SDK Initialized!');
    } catch (e) {
      print('Failed to initialize Paystack: $e');
    }
  }

  Future<String?> _saveOrderToSupabase(
    String reference,
    double grandTotal,
    double subTotal,
    double deliveryFee,
    List<CartItem> items,
    String deliveryAddressText,
  ) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Insert Order
      final orderData = await supabase.from('orders').insert({
        'client_id': user.id,
        'status': 'pending',
        'delivery_address': deliveryAddressText,
        'subtotal': subTotal,
        'delivery_fee': deliveryFee,
        'total_amount': grandTotal,
        'payment_reference': reference,
        'payment_status': 'pending',
        'payment_method': 'Paystack',
      }).select().single();

      final orderId = orderData['id'] as String;

      // 2. Insert Order Items
      final orderItemsData = items.map((item) => {
        'order_id': orderId,
        'product_id': item.product.id,
        'quantity': item.quantity,
        'price_at_purchase': item.product.price,
      }).toList();

      await supabase.from('order_items').insert(orderItemsData);

      return orderId;
    } catch (e) {
      print('Database save error: $e');
      return null;
    }
  }

  Future<String?> _createAccessCode(
    String reference,
    int amountInKobo,
    String email,
    String orderId,
  ) async {
    // ⚠️ NOTE: We are using the Secret Key here purely for development/testing!
    // In production, you will want to move this 1 API call to a Supabase Edge Function for security.
    const String secretKey = 'sk_test_f67c30c4f53e95f01ad02b52546b3a3d449db57b';

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
          'metadata': {
            'order_id': orderId,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['access_code']; // We got the code!
      } else {
        print('Paystack API Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('HTTP Request failed: $e');
      return null;
    }
  }

  Future<void> _processPayment(
    double grandTotal,
    double subTotal,
    double deliveryFee,
    List<CartItem> cartItems,
    String deliveryAddressText,
  ) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to checkout.')),
      );
      return;
    }

    final amountInKobo = (grandTotal * 100).toInt();
    String reference = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Pre-save the Pending Order!
    String? orderId = await _saveOrderToSupabase(
      reference,
      grandTotal,
      subTotal,
      deliveryFee,
      cartItems,
      deliveryAddressText,
    );

    if (orderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create order. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Fetch Access Code with Metadata attached
    String? accessCode = await _createAccessCode(
      reference,
      amountInKobo,
      user.email!,
      orderId,
    );

    if (accessCode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize payment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 3. Launch Paystack Checkout UI
    try {
      final response = await _paystack.launch(accessCode);

      if (response.status == "success") {
        print('Payment local success! Reference: ${response.reference}');
        
        // 4. Handle Success State
        if (mounted) {
          ref.read(cartProvider.notifier).clearCart();
          
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Payment Successful! Order submitted.'),
               backgroundColor: Colors.green,
             ),
          );
          
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Paystack Launch Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred during checkout.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Bottom Sheet to Select Address ---
  void _showAddressSelector(List<AddressModel> addresses, var zones) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(
                    '${address.label != null ? '${address.label}: ' : ''}${address.street}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Zone: $zoneName'),
                  trailing:
                      _selectedAddressId == address.id ||
                          (_selectedAddressId == null &&
                              address.id == addresses.first.id)
                      ? const Icon(Icons.check_circle, color: Colors.green)
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
                icon: const Icon(Icons.add, color: Colors.black87),
                label: const Text(
                  'Add a new address',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        );
      },
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
      backgroundColor: Colors.white,
      appBar: SayfoodsAppBar(
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
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
              color: Colors.white,
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
                    onPressed: () {
                      if (activeAddress == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please add a delivery address first.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Format address
                      String addressText = '${activeAddress.street}, ${activeAddress.city ?? "Lagos"}';
                      if (activeAddress.label != null && activeAddress.label!.isNotEmpty) {
                        addressText = '${activeAddress.label}: $addressText';
                      }

                      _processPayment(
                        grandTotal,
                        subTotal,
                        deliveryFee,
                        cartItems,
                        addressText,
                      );
                    },
                    child: Column(
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
          ? const Center(
              child: Text(
                'Your cart is empty!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'CHECKOUT',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ADDRESS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Show dynamic address or a prompt to add one
                            activeAddress != null
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
                          Icons.edit_square,
                          color: Colors.black,
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
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₦${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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
