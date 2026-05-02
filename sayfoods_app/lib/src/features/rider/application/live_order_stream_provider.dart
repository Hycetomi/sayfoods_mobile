import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

final liveOrderStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('status', 'ready_for_pickup')
      .map((data) {
        // We receive a list of row maps from Supabase
        return data
            .map((json) => OrderModel.fromJson(json))
            .where((order) => order.riderId == null) // Client-side filter
            .toList();
      });
});
