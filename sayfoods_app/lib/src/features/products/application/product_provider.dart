import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';

// A FutureProvider is perfect for fetching a list of items once when the screen loads
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final supabase = Supabase.instance.client;

  // Fetch all rows from the 'products' table
  final List<dynamic> response = await supabase.from('products').select();

  // Map the raw database rows into our neat Product Dart objects
  return response.map((json) => Product.fromJson(json)).toList();
});
