import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/category_model.dart';
import 'package:flutter/foundation.dart';

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    return _fetchCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('categories').select().order('name');
    return response.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<void> addCategory(String name, {String? iconPath}) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('categories').insert({
        'name': name,
        if (iconPath != null && iconPath.isNotEmpty) 'icon_path': iconPath,
      });
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(String id, String newName) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('categories').update({
        'name': newName,
      }).eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id, {bool deleteProducts = false}) async {
    try {
      final supabase = Supabase.instance.client;
      if (deleteProducts) {
        await supabase.from('products').delete().eq('category_id', id);
      } else {
        await supabase.from('products').update({'category_id': null}).eq('category_id', id);
      }
      await supabase.from('categories').delete().eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }
}

final categoryListProvider = AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(
  () => CategoryNotifier(),
);
