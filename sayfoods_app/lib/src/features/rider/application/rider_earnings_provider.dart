import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

final riderEarningsProvider = FutureProvider<List<OrderModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  final response = await supabase
      .from('orders')
      .select()
      .eq('rider_id', user.id)
      .eq('status', 'completed')
      .order('completed_at', ascending: false);

  return (response as List).map((json) => OrderModel.fromJson(json)).toList();
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
