import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final riderDutyProvider = StateNotifierProvider<RiderDutyNotifier, AsyncValue<bool>>((ref) {
  return RiderDutyNotifier();
});

class RiderDutyNotifier extends StateNotifier<AsyncValue<bool>> {
  RiderDutyNotifier() : super(const AsyncValue.loading()) {
    _initDutyStatus();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _initDutyStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data(false);
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select('duty_status')
          .eq('id', user.id)
          .maybeSingle();

      final isOnline = data?['duty_status'] as bool? ?? false;
      state = AsyncValue.data(isOnline);
    } catch (e, st) {
      // Default to offline if we can't read the profile (missing column, RLS, etc.)
      state = const AsyncValue.data(false);
    }
  }

  Future<void> toggleDutyStatus(bool newStatus) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      if (newStatus) {
        // Going online - validate shift
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final scheduleData = await _supabase
            .from('rider_schedules')
            .select()
            .eq('rider_id', user.id)
            .eq('shift_date', todayStr)
            .eq('is_active', true)
            .maybeSingle();

        if (scheduleData == null) {
          throw Exception("You are not scheduled for a shift today. Please contact dispatch.");
        }
      }

      // Update duty status
      await _supabase
          .from('profiles')
          .update({'duty_status': newStatus})
          .eq('id', user.id);

      state = AsyncValue.data(newStatus);
    } catch (e) {
      rethrow;
    }
  }
}
