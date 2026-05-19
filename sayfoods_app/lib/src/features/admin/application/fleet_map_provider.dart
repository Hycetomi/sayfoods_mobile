import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Streams all profiles where duty_status == true.
// Supabase .stream() only supports one .eq() server filter, so role == 'rider'
// and coordinate presence are filtered client-side — same pattern used elsewhere.
final onlineRidersStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('duty_status', true)
      .map((data) => data
          .where((r) =>
              r['role'] == 'rider' &&
              r['latitude'] != null &&
              r['longitude'] != null)
          .toList());
});
