import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

class OrderState {
  final List<OrderModel> ongoing;
  final List<OrderModel> completed;

  OrderState({required this.ongoing, required this.completed});
}

final orderProvider = FutureProvider.autoDispose<OrderState>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return OrderState(ongoing: [], completed: []);
  }

  // Fetch orders with their items and the related product details
  final response = await supabase
      .from('orders')
      .select('*, order_items(*, products(*))')
      .eq('client_id', user.id)
      .order('created_at', ascending: false);

  final List<OrderModel> allOrders = (response as List<dynamic>)
      .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
      .toList();

  final ongoingOrders = allOrders
      .where((order) => order.status != 'delivered' && order.status != 'cancelled')
      .toList();

  final completedOrders = allOrders
      .where((order) => order.status == 'delivered' || order.status == 'cancelled')
      .toList();

  return OrderState(ongoing: ongoingOrders, completed: completedOrders);
});
