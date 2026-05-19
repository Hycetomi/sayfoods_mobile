import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/rider/application/rider_location_service.dart';

final riderDutyProvider =
    StateNotifierProvider<RiderDutyNotifier, AsyncValue<bool>>((ref) {
  return RiderDutyNotifier(ref.watch(riderLocationServiceProvider));
});

class RiderDutyNotifier extends StateNotifier<AsyncValue<bool>> {
  RiderDutyNotifier(this._locationService) : super(const AsyncValue.loading()) {
    _initDutyStatus();
  }

  final _supabase = Supabase.instance.client;
  final RiderLocationService _locationService;

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
      // Resume GPS broadcast if rider was already online
      if (isOnline) await _locationService.start(userId: user.id);
      state = AsyncValue.data(isOnline);
    } catch (e) {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> toggleDutyStatus(bool newStatus) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      if (newStatus) {
        // Validate shift before going online
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final scheduleData = await _supabase
            .from('rider_schedules')
            .select()
            .eq('rider_id', user.id)
            .eq('shift_date', todayStr)
            .eq('is_active', true)
            .maybeSingle();

        if (scheduleData == null) {
          throw Exception(
              "You are not scheduled for a shift today. Please contact dispatch.");
        }

        await _supabase
            .from('profiles')
            .update({'duty_status': true})
            .eq('id', user.id);

        await _locationService.start(userId: user.id);
      } else {
        _locationService.stop();
        await _supabase
            .from('profiles')
            .update({'duty_status': false})
            .eq('id', user.id);
      }

      state = AsyncValue.data(newStatus);
    } catch (e) {
      rethrow;
    }
  }
}
