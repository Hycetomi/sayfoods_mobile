import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Manages the set of favourited product IDs with optimistic updates ─────────
// Uses optimistic UI (state updates instantly on tap) then syncs with DB.
// This avoids relying on Supabase Realtime for the table.

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  final _db = Supabase.instance.client;

  Future<void> _load() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _db
          .from('user_favorites')
          .select('product_id')
          .eq('user_id', user.id);
      state = (data as List)
          .map((r) => r['product_id'] as String)
          .toSet();
    } catch (_) {
      state = {};
    }
  }

  Future<void> toggle(String productId) async {
    if (productId.isEmpty) return;
    final user = _db.auth.currentUser;
    if (user == null) return;

    final current = Set<String>.from(state);

    if (current.contains(productId)) {
      // Optimistic remove
      state = current..remove(productId);
      try {
        await _db
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
      } catch (_) {
        // Roll back on error
        state = current..add(productId);
      }
    } else {
      // Optimistic add
      state = current..add(productId);
      try {
        await _db.from('user_favorites').insert({
          'user_id': user.id,
          'product_id': productId,
        });
      } catch (_) {
        // Roll back on error
        state = current..remove(productId);
      }
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);
