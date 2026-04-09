import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:sayfoods_app/src/features/products/domain/product_model.dart';

class AdminDashboardStats {
  final int usersCount;
  final int ordersCount;
  final int totalStockCount;
  final Map<String, dynamic> stockBreakdown;
  
  AdminDashboardStats({
    required this.usersCount,
    required this.ordersCount,
    required this.totalStockCount,
    required this.stockBreakdown,
  });
}

// 1. Core Analytics Pipeline
final adminStatsProvider = FutureProvider.autoDispose<AdminDashboardStats>((ref) async {
  final supabase = Supabase.instance.client;

  // Run analytics in parallel for extremely fast dashboard rendering!
  final usersFuture = supabase.from('profiles').select('id');
  final ordersFuture = supabase.from('orders').select('id');
  
  // We need to fetch products joined with categories to sum the actual mapped stock
  final productsFuture = supabase.from('products').select('*, categories(name)');

  // Wait for all queries to finish
  final results = await Future.wait([usersFuture, ordersFuture, productsFuture]);

  int totalUsers = (results[0] as List<dynamic>).length;
  int totalOrders = (results[1] as List<dynamic>).length;
  List<dynamic> productsData = results[2] as List<dynamic>;

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

  // Ensure there are always 3 entries to prevent UI breaking
  if (bottomThreeStock.length < 3) {
     int fillersNeeded = 3 - bottomThreeStock.length;
     for(int i = 0; i < fillersNeeded; i++) {
        bottomThreeStock['Empty$i'] = '0 units';
     }
  }

  return AdminDashboardStats(
    usersCount: totalUsers,
    ordersCount: totalOrders,
    totalStockCount: totalStockNumber,
    stockBreakdown: bottomThreeStock
  );
});

// 2. Global Order Stream (Bypassing User Row Level Security constraints!)
final adminRecentOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final supabase = Supabase.instance.client;
  
  // Explicitly mapping the 'client_id' foreign key since 'orders' also has 'rider_id' pointing to profiles!
  final response = await supabase
      .from('orders')
      .select('*, profiles!orders_client_id_fkey(full_name), order_items(*, products(*))')
      .order('created_at', ascending: false)
      .limit(5);

  return response.map((json) => OrderModel.fromJson(json)).toList();
});
