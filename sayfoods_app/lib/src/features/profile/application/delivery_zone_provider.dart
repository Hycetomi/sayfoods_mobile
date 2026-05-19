import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/profile/domain/delivery_zone_model.dart';

final deliveryZoneProvider = FutureProvider<List<DeliveryZone>>((ref) async {
  final supabase = Supabase.instance.client;

  // Fetch all delivery zones ordered by price ascending.
  // The is_active column is not in the current DB schema so we fetch all zones.
  final response = await supabase
      .from('delivery_zones')
      .select()
      .order('price', ascending: true);

  return response.map((json) => DeliveryZone.fromJson(json)).toList();
});
