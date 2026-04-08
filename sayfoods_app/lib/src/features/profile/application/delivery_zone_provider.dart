import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/profile/domain/delivery_zone_model.dart';

final deliveryZoneProvider = FutureProvider<List<DeliveryZone>>((ref) async {
  final supabase = Supabase.instance.client;

  // Only fetch zones that you have marked as active in your dashboard!
  final response = await supabase
      .from('delivery_zones')
      .select()
      .eq('is_active', true)
      .order(
        'price',
        ascending: true,
      ); // Orders from cheapest to most expensive

  return response.map((json) => DeliveryZone.fromJson(json)).toList();
});
