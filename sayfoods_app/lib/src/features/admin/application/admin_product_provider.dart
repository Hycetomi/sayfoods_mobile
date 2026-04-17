import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/products/domain/product_model.dart';
import 'package:sayfoods_app/src/features/admin/application/admin_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

// StateProvider for the search bar inside the Admin Manage Products screen
final adminProductSearchQueryProvider = StateProvider<String>((ref) => '');

class AdminProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final query = ref.watch(adminProductSearchQueryProvider).trim();
    // Add a slight debounce if query is changing rapidly
    if (query.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return _fetchProducts(query);
  }

  Future<List<Product>> _fetchProducts(String searchQuery) async {
    final supabase = Supabase.instance.client;
    
    // We left join categories to get the categoryName securely
    var queryBuilder = supabase.from('products').select('*, categories(name)');
    
    if (searchQuery.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('name', '%$searchQuery%');
    }

    final response = await queryBuilder.order('name');
    return response.map((json) => Product.fromJson(json)).toList();
  }

  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required int stockQuantity,
    String? categoryId,
    File? imageFile,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      String? parsedImageUrl;
      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await supabase.storage.from('product_images').upload(fileName, imageFile);
        parsedImageUrl = supabase.storage.from('product_images').getPublicUrl(fileName);
      }

      final res = await supabase.from('products').insert({
        'name': name,
        'description': description,
        'price': price,
        'stock_quantity': stockQuantity, // Explicitly writing to standard column
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (parsedImageUrl != null) 'image_path': parsedImageUrl,
      }).select();
      if (res.isEmpty) throw Exception('Insert rejected by database. Check RLS policies.');
      ref.invalidateSelf();
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, {
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? categoryId,
    File? imageFile,
    bool clearImage = false, // true if user deletes existing image
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      String? parsedImageUrl;
      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await supabase.storage.from('product_images').upload(fileName, imageFile);
        parsedImageUrl = supabase.storage.from('product_images').getPublicUrl(fileName);
      }

      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (stockQuantity != null) updates['stock_quantity'] = stockQuantity;
      if (categoryId != null) updates['category_id'] = categoryId;
      
      if (parsedImageUrl != null) {
        updates['image_path'] = parsedImageUrl;
      } else if (clearImage) {
        updates['image_path'] = null;
      }

      if (updates.isNotEmpty) {
        final res = await supabase.from('products').update(updates).eq('id', id).select();
        if (res.isEmpty) throw Exception('Update rejected. No rows modified (Check RLS policies).');
        ref.invalidateSelf();
        ref.invalidate(adminStatsProvider);
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.from('products').delete().eq('id', id).select();
      if (res.isEmpty) throw Exception('Delete rejected. No rows modified (Check RLS policies).');
      ref.invalidateSelf();
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }
}

final adminProductListProvider = AsyncNotifierProvider<AdminProductNotifier, List<Product>>(
  () => AdminProductNotifier(),
);
