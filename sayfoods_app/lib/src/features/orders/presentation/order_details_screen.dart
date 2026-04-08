import 'package:flutter/material.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: const SayfoodsAppBar(
        title: 'Order Details',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header info
            _buildSectionCard(
              children: [
                _buildInfoRow('Order ID:', order.id.substring(0, 8).toUpperCase()),
                const SizedBox(height: 8),
                _buildInfoRow('Date:', '${order.formattedTime} - ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}'),
                const SizedBox(height: 8),
                _buildInfoRow('Status:', order.status.toUpperCase(), highlight: true),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: const TextStyle(height: 1.4, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Items Ordered',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              padding: EdgeInsets.zero,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    final productName = item.product?.name ?? 'Unknown Item';
                    final itemImage = item.product?.imageUrl ?? '';
                    final extPrice = item.priceAtPurchase * item.quantity;
                    
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: itemImage.isNotEmpty 
                              ? Image.network(itemImage, width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, trace) => Container(color: Colors.grey[200], width: 50, height: 50, child: const Icon(Icons.image, color: Colors.grey)))
                              : Container(color: Colors.grey[200], width: 50, height: 50, child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Qty: ${item.quantity}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(
                            '₦${extPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              children: [
                _buildInfoRow('Subtotal:', '₦${order.subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildInfoRow('Delivery Fee:', '₦${order.deliveryFee.toStringAsFixed(0)}'),
                const Divider(height: 24),
                _buildInfoRow(
                  'Total Amount:', 
                  '₦${order.totalAmount.toStringAsFixed(0)}', 
                  isTotal: true
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children, EdgeInsetsGeometry padding = const EdgeInsets.all(16.0)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: isTotal ? Colors.black : Colors.grey[600], 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          )
        ),
        Text(
          value, 
          style: TextStyle(
            color: highlight ? Colors.orange : Colors.black, 
            fontWeight: (highlight || isTotal) ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
          )
        ),
      ],
    );
  }
}
