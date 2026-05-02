import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/chat/domain/message_model.dart';

@immutable
class ChatChannelParams {
  final String channelType; // 'admin_client' | 'admin_rider' | 'rider_client'
  final String? orderId;    // required for admin_client and rider_client
  final String? riderId;    // required for admin_rider

  const ChatChannelParams({
    required this.channelType,
    this.orderId,
    this.riderId,
  });

  @override
  bool operator ==(Object other) =>
      other is ChatChannelParams &&
      other.channelType == channelType &&
      other.orderId == orderId &&
      other.riderId == riderId;

  @override
  int get hashCode => Object.hash(channelType, orderId, riderId);
}

// Streams messages for a given channel.
// For A & B: scopes by order_id server-side, filters channel_type client-side.
// For C: scopes by rider_id server-side, filters channel_type client-side.
final chatMessagesProvider =
    StreamProvider.family<List<MessageModel>, ChatChannelParams>((ref, params) {
  final supabase = Supabase.instance.client;

  late Stream<List<Map<String, dynamic>>> raw;

  if (params.channelType == 'admin_rider') {
    assert(params.riderId != null, 'riderId required for admin_rider channel');
    raw = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('rider_id', params.riderId!)
        .order('created_at');
  } else {
    assert(params.orderId != null, 'orderId required for $params.channelType channel');
    raw = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', params.orderId!)
        .order('created_at');
  }

  return raw.map((data) => data
      .map(MessageModel.fromJson)
      .where((m) => m.channelType == params.channelType)
      .toList());
});

// ── Send Message ─────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  ChatNotifier() : super(const AsyncValue.data(null));

  final _supabase = Supabase.instance.client;

  Future<void> sendMessage({
    required ChatChannelParams params,
    required String content,
    String? senderName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await _supabase.from('messages').insert({
        'channel_type': params.channelType,
        'order_id': params.orderId,
        'rider_id': params.riderId,
        'sender_id': user.id,
        'sender_name': senderName,
        'content': content.trim(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>(
  (ref) => ChatNotifier(),
);
