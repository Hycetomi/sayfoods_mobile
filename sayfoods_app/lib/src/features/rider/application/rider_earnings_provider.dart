import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

// StreamProvider — uses Supabase Realtime so the earnings screen updates
// automatically the moment the rider marks an order as completed.
// Server-side filter: rider_id (one .eq() allowed on .stream())
// Client-side filter: status == 'completed'
final riderEarningsProvider = StreamProvider<List<OrderModel>>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return Stream.value([]);

  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('rider_id', user.id)
      .order('completed_at', ascending: false)
      .map((data) => data
          .map((json) => OrderModel.fromJson(json))
          .where((order) => order.status == 'completed')
          .toList());
});

final monthlyEarningsProvider = Provider<double>((ref) {
  final earningsAsync = ref.watch(riderEarningsProvider);

  return earningsAsync.maybeWhen(
    data: (orders) {
      final now = DateTime.now();
      double total = 0;
      for (final order in orders) {
        if (order.completedAt != null &&
            order.completedAt!.month == now.month &&
            order.completedAt!.year == now.year) {
          total += order.commissionEarned;
        }
      }
      return total;
    },
    orElse: () => 0.0,
  );
});
