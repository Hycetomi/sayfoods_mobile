import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';

class AdminDashboardStats {
  final int usersCount;
  final int ordersCount;
  final int totalStockCount;
  final Map<String, dynamic> stockBreakdown;
  final double totalRevenue;

  AdminDashboardStats({
    required this.usersCount,
    required this.ordersCount,
    required this.totalStockCount,
    required this.stockBreakdown,
    this.totalRevenue = 0.0,
  });
}

// 1. Core Analytics Pipeline
final adminStatsProvider = FutureProvider.autoDispose<AdminDashboardStats>((ref) async {
  final supabase = Supabase.instance.client;

  // Run analytics in parallel for extremely fast dashboard rendering!
  final usersFuture   = supabase.from('profiles').select('id');
  final ordersFuture  = supabase.from('orders').select('id');
  final productsFuture = supabase.from('products').select('*, categories(name)');
  final revenueFuture = supabase
      .from('orders')
      .select('total_amount')
      .eq('payment_status', 'paid');

  // Wait for all queries to finish
  final results = await Future.wait(
      [usersFuture, ordersFuture, productsFuture, revenueFuture]);

  int totalUsers = (results[0] as List<dynamic>).length;
  int totalOrders = (results[1] as List<dynamic>).length;
  List<dynamic> productsData = results[2] as List<dynamic>;
  final double totalRevenue = (results[3] as List<dynamic>).fold(
    0.0,
    (sum, row) => sum + ((row['total_amount'] as num?)?.toDouble() ?? 0.0),
  );

  // Process the top 3 items with the lowest stock count and compute the total sum
  int totalStockNumber = 0;
  List<Map<String, dynamic>> parsedProducts = [];

  for (var rawProduct in productsData) {
    int qty = 0;
    if (rawProduct['stock_quantity'] != null) {
      qty = int.tryParse(rawProduct['stock_quantity'].toString()) ?? 0;
    } else if (rawProduct['stock'] != null) {
      qty = int.tryParse(rawProduct['stock'].toString()) ?? 0; // Fallback to 'stock' column name
    }
    
    totalStockNumber += qty;
    parsedProducts.add({
      'name': rawProduct['name']?.toString() ?? 'Item',
      'qty': qty
    });
  }

  // Sort ascending (lowest stock first)
  parsedProducts.sort((a, b) => (a['qty'] as int).compareTo(b['qty'] as int));

  Map<String, dynamic> bottomThreeStock = {};
  for (int i = 0; i < 3 && i < parsedProducts.length; i++) {
    String shortName = parsedProducts[i]['name'].toString().split(' ')[0]; // Grab just the first word
    int q = parsedProducts[i]['qty'];
    bottomThreeStock[shortName] = '$q units';
  }

  // Removed hardcoded padding to allow dynamic length

  return AdminDashboardStats(
    usersCount: totalUsers,
    ordersCount: totalOrders,
    totalStockCount: totalStockNumber,
    stockBreakdown: bottomThreeStock,
    totalRevenue: totalRevenue,
  );
});

// Helper — fetch a single order with all relations by ID.
Future<OrderModel?> _fetchSingleOrder(
    SupabaseClient supabase, String orderId) async {
  final response = await supabase
      .from('orders')
      .select(
          '*, client:profiles!orders_client_id_fkey(full_name), rider:profiles!orders_rider_id_fkey(full_name), order_items(*, products(*, categories(id,name)))')
      .eq('id', orderId)
      .single();
  return OrderModel.fromJson(response);
}

// Stream a single order row — used by the admin detail screen for live updates.
final singleOrderProvider =
    StreamProvider.autoDispose.family<OrderModel?, String>((ref, orderId) {
  final supabase = Supabase.instance.client;
  final controller = StreamController<OrderModel?>();

  _fetchSingleOrder(supabase, orderId)
      .then(controller.add)
      .catchError(controller.addError);

  final channel = supabase
      .channel('order_detail_$orderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: orderId,
        ),
        callback: (_) => _fetchSingleOrder(supabase, orderId)
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

// Helper — shared fetch logic so both the initial load and realtime callbacks reuse it.
Future<List<OrderModel>> _fetchRecentOrders(SupabaseClient supabase) async {
  final response = await supabase
      .from('orders')
      .select(
          '*, client:profiles!orders_client_id_fkey(full_name), rider:profiles!orders_rider_id_fkey(full_name), order_items(*, products(*, categories(id,name)))')
      .order('created_at', ascending: false)
      .limit(5);
  return response.map((json) => OrderModel.fromJson(json)).toList();
}

// 2. Global Order Stream — switches to StreamProvider so the dashboard updates
// automatically whenever any order row is inserted or updated.
final adminRecentOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final supabase = Supabase.instance.client;
  final controller = StreamController<List<OrderModel>>();

  // Initial load
  _fetchRecentOrders(supabase).then(controller.add).catchError(controller.addError);

  // Realtime subscription — re-fetches on any INSERT or UPDATE to orders
  final channel = supabase
      .channel('admin_recent_orders')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (_) => _fetchRecentOrders(supabase)
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
