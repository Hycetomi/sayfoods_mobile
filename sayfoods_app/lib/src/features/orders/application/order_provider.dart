import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

class OrderState {
  final List<OrderModel> ongoing;
  final List<OrderModel> completed;

  OrderState({required this.ongoing, required this.completed});
}

// Terminal statuses — anything here moves to the Completed tab.
const _completedStatuses = {'delivered', 'completed', 'cancelled'};

Future<OrderState> _fetchOrders(SupabaseClient supabase, String userId) async {
  final response = await supabase
      .from('orders')
      .select('*, order_items(*, products(*))')
      .eq('client_id', userId)
      .order('created_at', ascending: false);

  final allOrders = (response as List<dynamic>)
      .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
      .toList();

  return OrderState(
    ongoing: allOrders
        .where((o) => !_completedStatuses.contains(o.status))
        .toList(),
    completed: allOrders
        .where((o) => _completedStatuses.contains(o.status))
        .toList(),
  );
}

// StreamProvider — re-fetches whenever an order row for this client changes.
final orderProvider = StreamProvider.autoDispose<OrderState>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return Stream.value(OrderState(ongoing: [], completed: []));
  }

  final controller = StreamController<OrderState>();

  // Initial load
  _fetchOrders(supabase, user.id)
      .then(controller.add)
      .catchError(controller.addError);

  // Realtime — re-fetch on any change to this client's orders
  final channel = supabase
      .channel('client_orders_${user.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'client_id',
          value: user.id,
        ),
        callback: (_) => _fetchOrders(supabase, user.id)
            .then(controller.add)
            .catchError(controller.addError),
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
