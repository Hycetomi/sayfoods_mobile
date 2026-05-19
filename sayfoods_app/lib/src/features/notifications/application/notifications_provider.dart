import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/notifications/domain/notification_model.dart';

// ── Stream — newest-first notifications for current user ─────────────────────

final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value([]);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data
          .map((json) => NotificationModel.fromJson(json))
          .toList());
});

// ── Unread count — derived from the stream ────────────────────────────────────

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsStreamProvider).maybeWhen(
        data: (notifications) =>
            notifications.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

// ── Notifier — mark read / mark all read ─────────────────────────────────────

class NotificationsNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationsNotifier() : super(const AsyncValue.data(null));

  final _db = Supabase.instance.client;

  Future<void> markRead(String id) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (_) {}
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<void>>(
  (ref) => NotificationsNotifier(),
);
