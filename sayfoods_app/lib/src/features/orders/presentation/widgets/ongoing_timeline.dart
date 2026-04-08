import 'package:flutter/material.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';

class OngoingTimelineScreen extends StatelessWidget {
  final OrderModel order;
  const OngoingTimelineScreen({super.key, required this.order});

  // Determines if a status should be checked off based on the current order status
  int _getStatusRank(String dbStatus) {
    switch (dbStatus.toLowerCase()) {
      case 'pending':
        return 1;
      case 'confirmed':
        return 2;
      case 'processing': // or packaging
        return 3;
      case 'pickup':
      case 'on_way':
        return 4;
      case 'delivered':
        return 5;
      default:
        return 0; // unknown state
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = _getStatusRank(order.status);
    final timeStr = order.formattedTime;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SayfoodsAppBar(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Timeline items
            _TimelineTile(
              time: timeStr,
              title: 'ORDER PLACED',
              subtitle: 'Your Order ${order.id.substring(0, 6)} has been placed',
              isCompleted: rank >= 0, // Always true if it exists
              isLast: false,
            ),
            _TimelineTile(
              time: timeStr,
              title: 'PENDING',
              subtitle: 'Your Order ${order.id.substring(0, 6)} is currently waiting approval',
              isCompleted: rank >= 1,
              isLast: false,
            ),
            _TimelineTile(
              time: timeStr,
              title: 'ORDER CONFIRMED',
              subtitle: 'Your Order ${order.id.substring(0, 6)} has been approved by a Sayfoods personnel',
              isCompleted: rank >= 2,
              isLast: false,
            ),
            _TimelineTile(
              time: timeStr,
              title: 'PROCESSING',
              subtitle: 'Your Order ${order.id.substring(0, 6)} is being packaged',
              isCompleted: rank >= 3,
              isLast: false,
            ),
            _TimelineTile(
              time: timeStr,
              title: 'RIDER PICKUP',
              subtitle: 'Rider is waiting to pick up your order',
              isCompleted: rank >= 4,
              isLast: false,
              actionButton: rank >= 4 
                ? ElevatedButton(
                    onPressed: () {
                      // Navigate to messages
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    child: const Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                : null,
            ),
            _TimelineTile(
              time: timeStr,
              title: 'DELIVERED',
              subtitle: 'Order delivered to your address',
              isCompleted: rank >= 5,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLast;
  final Widget? actionButton;

  const _TimelineTile({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isLast,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Component
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                time,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          
          // Line & Circle Component
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? const Color(0xFF5A189A) : Colors.white,
                  border: Border.all(
                    color: const Color(0xFF5A189A),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: isCompleted
                         ? const LinearGradient(
                              colors: [Colors.orange, Colors.orange],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                         : const LinearGradient(
                              colors: [Colors.grey, Colors.grey],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                    ),
                  ),
                ),
                // Arrow head simulation if connected
                if (!isLast)
                  Icon(Icons.keyboard_arrow_down, size: 16, color: isCompleted ? Colors.orange : Colors.grey)
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Content Component
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (actionButton != null) ...[
                    const SizedBox(height: 8),
                    actionButton!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
