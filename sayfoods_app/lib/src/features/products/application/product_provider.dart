import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';
import '../domain/category_model.dart';

// Tracks which category the user has currently tapped (null means "All")
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Fetches the list of categories from Supabase
final categoryListProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('categories').select();
  return response.map((json) => CategoryModel.fromJson(json)).toList();
});

// A FutureProvider is perfect for fetching a list of items once when the screen loads
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final supabase = Supabase.instance.client;
  
  // Watch the selected category
  final String? activeCategory = ref.watch(selectedCategoryProvider);

  // 1. We start mapping our request. The inner join forces Supabase to return the category string
  var query = supabase.from('products').select('*, categories!inner(name)');

  // 2. If the user clicked a specific chip, we tell Supabase to filter the results securely!
  if (activeCategory != null) {
     query = query.eq('categories.name', activeCategory);
  }

  // 3. Dispatch Network execution
  final List<dynamic> response = await query;

  // Map the raw database rows into our neat Product Dart objects
  return response.map((json) => Product.fromJson(json)).toList();
});
