import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/products/domain/product_model.dart';
import 'dart:async';

// Holds the raw keyboard string as the user types
final searchQueryProvider = StateProvider<String>((ref) => '');

// Responsible for resolving the DB search against that string
final searchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  
  if (query.isEmpty) {
    return []; // Return instantly to avoid empty db dump
  }

  // 1. Setup the Debouncer
  // We read the built-in signal that Riverpod uses when this provider is about to be disposed/rebuilt
  bool isDisposed = false;
  ref.onDispose(() => isDisposed = true);

  // 2. Wait 500ms
  await Future.delayed(const Duration(milliseconds: 500));

  // 3. If the user typed another letter while we were waiting, this exact FutureProvider 
  // execution was cancelled/disposed. So we just abort this old network request!
  if (isDisposed) {
    throw Exception('Debounce cancelled: User kept typing');
  }

  // 4. If we made it here, the user stopped typing for 500ms! Hit the DB!
  final supabase = Supabase.instance.client;
  
  // ilike does a case-insensitive search. %query% means anything before or after
  final response = await supabase
      .from('products')
      .select()
      .ilike('name', '%$query%')
      .order('name'); 
      
  return (response as List<dynamic>)
      .map((json) => Product.fromJson(json))
      .toList();
});
