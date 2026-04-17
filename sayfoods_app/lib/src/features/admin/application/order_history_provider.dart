import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

// --- Search Provider ---
final orderHistorySearchProvider = StateProvider<String>((ref) => '');

// --- Category Filter Provider (null = All) ---
final orderHistoryCategoryFilterProvider = StateProvider<String?>((ref) => null);

// --- Raw History Notifier ---
class OrderHistoryNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    return _fetchAllOrders();
  }

  Future<List<OrderModel>> _fetchAllOrders() async {
    final supabase = Supabase.instance.client;

    // Deep join: client name, rider name, items + products with category
    final response = await supabase
        .from('orders')
        .select('''
          *,
          client:profiles!orders_client_id_fkey(full_name),
          rider:profiles!orders_rider_id_fkey(full_name),
          order_items(*, products(*, categories(id, name)))
        ''')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final orderHistoryProvider = AsyncNotifierProvider<OrderHistoryNotifier, List<OrderModel>>(
  () => OrderHistoryNotifier(),
);

// --- Filtered list (search + category simultaneously) ---
final filteredOrderHistoryProvider = Provider<List<OrderModel>>((ref) {
  final ordersState = ref.watch(orderHistoryProvider);
  final searchQuery = ref.watch(orderHistorySearchProvider).trim().toLowerCase();
  final categoryFilter = ref.watch(orderHistoryCategoryFilterProvider);

  return ordersState.maybeWhen(
    data: (orders) {
      return orders.where((order) {
        // 1. Search filter (by customer name or order ID prefix)
        final matchesSearch = searchQuery.isEmpty ||
            (order.clientName?.toLowerCase().contains(searchQuery) ?? false) ||
            order.id.toLowerCase().startsWith(searchQuery);

        // 2. Category filter: check if any item in this order belongs to the category
        final matchesCategory = categoryFilter == null ||
            order.items.any((item) =>
                item.product?.categoryId == categoryFilter);

        return matchesSearch && matchesCategory;
      }).toList();
    },
    orElse: () => [],
  );
});
