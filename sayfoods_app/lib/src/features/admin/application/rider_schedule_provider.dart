import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches all schedules for a specific rider, ordered by date descending.
final riderSchedulesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, riderId) async {
  final response = await Supabase.instance.client
      .from('rider_schedules')
      .select()
      .eq('rider_id', riderId)
      .order('shift_date', ascending: false);
  return List<Map<String, dynamic>>.from(response as List);
});

/// Notifier for creating, toggling, and deleting rider schedules.
class RiderScheduleNotifier extends StateNotifier<AsyncValue<void>> {
  RiderScheduleNotifier() : super(const AsyncValue.data(null));

  final _supabase = Supabase.instance.client;

  /// Add a new shift for [riderId] on [shiftDate].
  Future<void> addShift(String riderId, DateTime shiftDate) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('rider_schedules').insert({
        'rider_id': riderId,
        'shift_date': shiftDate.toIso8601String().split('T').first,
        'is_active': true,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Toggle [is_active] for a schedule row.
  Future<void> toggleActive(String scheduleId, bool newValue) async {
    state = const AsyncValue.loading();
    try {
      await _supabase
          .from('rider_schedules')
          .update({'is_active': newValue})
          .eq('id', scheduleId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete a schedule row entirely.
  Future<void> deleteShift(String scheduleId) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('rider_schedules').delete().eq('id', scheduleId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final riderScheduleNotifierProvider =
    StateNotifierProvider<RiderScheduleNotifier, AsyncValue<void>>(
  (ref) => RiderScheduleNotifier(),
);
