import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Streams a single rider's profile row (including latitude/longitude) in
// real time. Used by LiveDeliveryMap to update the rider pin as they move.
final riderLocationStreamProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, riderId) {
  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', riderId)
      .map((data) => data.isNotEmpty ? data.first : null);
});
