import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Fetches the current rider's upcoming shifts (today + next 7 days).
final riderUpcomingShiftsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final weekLater = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().add(const Duration(days: 7)));

  final response = await supabase
      .from('rider_schedules')
      .select()
      .eq('rider_id', user.id)
      .gte('shift_date', today)
      .lte('shift_date', weekLater)
      .order('shift_date', ascending: true);

  return List<Map<String, dynamic>>.from(response as List);
});
