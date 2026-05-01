import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/admin/application/order_history_provider.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:sayfoods_app/src/features/products/application/category_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _searchCtrl = TextEditingController();
  static const _primaryPurple = Color(0xFF5B1380);
  static const _colorOrange = Color(0xFFF28F2A);
  static const _bgColor = Color(0xFFFCFCFC);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
      case 'confirmed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    SayfoodsModal.showBottomSheet(
      context: context,
      isScrollControlled: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order Receipt', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(
                                  '#${order.id.substring(0, 8).toUpperCase()}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                            _buildStatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEE, d MMM yyyy • h:mm a').format(order.createdAt),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        const Divider(height: 32),

                        // Customer & Rider Info
                        _buildInfoSection(
                          icon: Icons.person_rounded,
                          label: 'Customer',
                          value: order.clientName ?? 'Unknown',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoSection(
                          icon: Icons.location_on_rounded,
                          label: 'Delivery Address',
                          value: order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'Not specified',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoSection(
                          icon: Icons.delivery_dining_rounded,
                          label: 'Assigned Rider',
                          value: order.riderName ?? 'Not assigned yet',
                          valueColor: order.riderName != null ? _primaryPurple : Colors.grey,
                        ),
                        const Divider(height: 32),

                        // Order Items
                        const Text('Items Ordered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ...order.items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryPurple.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.fastfood_rounded, color: _primaryPurple, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product?.name ?? 'Unknown item', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      if (item.product?.categoryName != null)
                                        Text(item.product!.categoryName!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(currencyFmt.format(item.priceAtPurchase), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 32),

                        // Financials
                        const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        _buildFinanceRow('Subtotal', currencyFmt.format(order.subtotal)),
                        const SizedBox(height: 8),
                        _buildFinanceRow('Delivery Fee', currencyFmt.format(order.deliveryFee)),
                        const Divider(height: 20),
                        _buildFinanceRow('Total', currencyFmt.format(order.totalAmount), isTotal: true),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Status', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: order.paymentStatus.toLowerCase() == 'paid' ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: order.paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
        ),
    );
  }

  Widget _buildInfoSection({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: valueColor ?? Colors.black87)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFinanceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isTotal ? Colors.black : Colors.grey.shade600,
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
        )),
        Text(value, style: TextStyle(
          color: isTotal ? _primaryPurple : Colors.black87,
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
        )),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(orderHistoryProvider);
    final filteredOrders = ref.watch(filteredOrderHistoryProvider);
    final selectedCategory = ref.watch(orderHistoryCategoryFilterProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(orderHistoryProvider),
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or order ID...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(orderHistorySearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) => ref.read(orderHistorySearchProvider.notifier).state = val,
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 44,
            child: categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // "All" chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedCategory == null,
                        onSelected: (_) => ref.read(orderHistoryCategoryFilterProvider.notifier).state = null,
                        selectedColor: _primaryPurple.withOpacity(0.15),
                        checkmarkColor: _primaryPurple,
                        labelStyle: TextStyle(
                          color: selectedCategory == null ? _primaryPurple : Colors.grey.shade700,
                          fontWeight: selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(orderHistoryCategoryFilterProvider.notifier).state =
                                isSelected ? null : cat.id;
                          },
                          selectedColor: _primaryPurple.withOpacity(0.15),
                          checkmarkColor: _primaryPurple,
                          labelStyle: TextStyle(
                            color: isSelected ? _primaryPurple : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Orders List
          Expanded(
            child: ordersState.when(
              loading: () => Center(child: CircularProgressIndicator(color: _primaryPurple)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (_) {
                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No orders found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final statusColor = _statusColor(order.status);

                    return InkWell(
                      onTap: () => _showOrderDetails(context, order),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            // Leading icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _primaryPurple.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_rounded, color: _primaryPurple, size: 20),
                            ),
                            const SizedBox(width: 14),
                            // Middle info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.clientName ?? 'Unknown Customer',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '#${order.id.substring(0, 8).toUpperCase()}  •  ${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    DateFormat('d MMM, h:mm a').format(order.createdAt),
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            // Trailing status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildStatusBadge(order.status),
                                const SizedBox(height: 6),
                                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
