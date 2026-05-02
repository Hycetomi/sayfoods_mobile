import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/chat/application/chat_provider.dart';
import 'package:sayfoods_app/src/features/chat/presentation/chat_screen.dart';
import 'package:sayfoods_app/src/features/orders/application/order_provider.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';

class ClientMessagesScreen extends ConsumerWidget {
  const ClientMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const SayfoodsAppBar(
        title: 'Messages',
        showBackButton: false,
      ),
      body: ordersAsync.when(
        data: (state) {
          final allOrders = [...state.ongoing, ...state.completed];
          if (allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Place an order to start a\nconversation with support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allOrders.length,
            itemBuilder: (context, index) {
              return _OrderChatCard(order: allOrders[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _OrderChatCard extends StatelessWidget {
  final OrderModel order;
  const _OrderChatCard({required this.order});

  static const _purple = Color(0xFF5B1380);

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'delivering':
      case 'out_for_delivery':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _labelOf(String s) {
    final spaced = s.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  bool get _isDelivering =>
      order.status == 'delivering' || order.status == 'out_for_delivery';

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final shortId = order.id.substring(0, 8).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order #$shortId',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _labelOf(order.status),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.displayTitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          // Channel A — always available
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.support_agent_rounded, size: 16),
              label: const Text('Support Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: _purple),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    params: ChatChannelParams(
                        channelType: 'admin_client', orderId: order.id),
                    title: 'Support',
                    subtitle: 'Order #$shortId',
                  ),
                ),
              ),
            ),
          ),
          // Channel B — only while delivering
          if (_isDelivering) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delivery_dining_rounded, size: 16),
                label: const Text('Chat with Rider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      params: ChatChannelParams(
                          channelType: 'rider_client', orderId: order.id),
                      title: 'Your Rider',
                      subtitle: 'Order #$shortId',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
