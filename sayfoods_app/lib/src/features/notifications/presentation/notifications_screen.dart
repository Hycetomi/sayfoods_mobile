import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/notifications/application/notifications_provider.dart';
import 'package:sayfoods_app/src/features/notifications/domain/notification_model.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: SayfoodsAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsNotifierProvider.notifier).markAllRead(),
            child: const Text(
              'Mark all read',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) =>
                _NotificationTile(notification: notifications[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  static const _purple = Color(0xFF5B1380);

  IconData _iconFor(String? type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'payment':
        return Icons.payment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          ref
              .read(notificationsNotifierProvider.notifier)
              .markRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: isUnread ? _purple : Colors.transparent,
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconFor(notification.type),
                    color: _purple, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(notification.createdAt.toLocal()),
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: _purple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
