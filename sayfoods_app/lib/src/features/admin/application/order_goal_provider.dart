import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/admin/domain/order_goal_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class OrderGoalNotifier extends AsyncNotifier<List<OrderGoal>> {
  @override
  Future<List<OrderGoal>> build() async {
    return _fetchGoals();
  }

  Future<List<OrderGoal>> _fetchGoals() async {
    final supabase = Supabase.instance.client;
    
    // Fetch all documented goals natively
    final rawGoals = await supabase
        .from('order_goals')
        .select('*')
        .order('month_year', ascending: false);

    List<OrderGoal> compiledGoals = [];

    // Map the actual live orders counts concurrently for total speed
    final List<Future<void>> calculationTasks = [];

    for (var raw in rawGoals) {
      calculationTasks.add((() async {
        final String monthYearStr = raw['month_year'].toString(); // e.g. "2026-04"
        final parts = monthYearStr.split('-');
        if (parts.length == 2) {
          final int year = int.tryParse(parts[0]) ?? DateTime.now().year;
          final int month = int.tryParse(parts[1]) ?? DateTime.now().month;
          
          final startBound = DateTime(year, month, 1).toIso8601String();
          final endBound = (month == 12) 
            ? DateTime(year + 1, 1, 1).toIso8601String()
            : DateTime(year, month + 1, 1).toIso8601String();

          // Rapid `.count()` operation avoids heavy database transfers
          final response = await supabase
              .from('orders')
              .select('id')
              .eq('status', 'delivered')
              .gte('created_at', startBound)
              .lt('created_at', endBound);

          final count = (response as List).length;
          compiledGoals.add(OrderGoal.fromJson(raw, achieved: count));
        } else {
          compiledGoals.add(OrderGoal.fromJson(raw));
        }
      })());
    }

    await Future.wait(calculationTasks);

    // Sort descending internally after parallel compilation (newest months at top)
    compiledGoals.sort((a, b) => b.monthYear.compareTo(a.monthYear));

    return compiledGoals;
  }

  /// Sets or updates the target goal ratio natively for the given month.
  Future<void> setGoal({required String monthYear, required int target}) async {
    state = const AsyncValue.loading();
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('order_goals').upsert(
        {
          'month_year': monthYear,
          'target_orders': target,
        },
        onConflict: 'month_year',
      );
      state = AsyncValue.data(await _fetchGoals());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      debugPrint('Error upserting order goal: $e');
      rethrow;
    }
  }
}

// ----------------------------------------------------------------------
// CATEGORY GOALS SYSTEM
// ----------------------------------------------------------------------

class CategoryGoalNotifier extends AsyncNotifier<List<CategoryGoal>> {
  @override
  Future<List<CategoryGoal>> build() async {
    return _fetchCategoryGoals();
  }

  Future<List<CategoryGoal>> _fetchCategoryGoals() async {
    final supabase = Supabase.instance.client;
    
    // Natively pulling joined data containing category names via Foreign Keys!
    final rawCatGoals = await supabase
        .from('category_goals')
        .select('*, categories(name)')
        .order('month_year', ascending: false);

    List<CategoryGoal> compiledCatGoals = [];
    final List<Future<void>> calculationTasks = [];

    for (var raw in rawCatGoals) {
      calculationTasks.add((() async {
        final String monthYearStr = raw['month_year'].toString(); 
        final String targetCategoryId = raw['category_id'].toString();

        final parts = monthYearStr.split('-');
        if (parts.length == 2) {
          final int year = int.tryParse(parts[0]) ?? DateTime.now().year;
          final int month = int.tryParse(parts[1]) ?? DateTime.now().month;
          
          final startBound = DateTime(year, month, 1).toIso8601String();
          final endBound = (month == 12) 
            ? DateTime(year + 1, 1, 1).toIso8601String()
            : DateTime(year, month + 1, 1).toIso8601String();

          // Safely execute cross-join counting natively via Dart loops 
          // Pulling ONLY delivered items within this month that contain this category
          final itemsRes = await supabase
              .from('order_items')
              .select('quantity, products!inner(category_id), orders!inner(status, created_at)')
              .eq('orders.status', 'delivered')
              .eq('products.category_id', targetCategoryId)
              .gte('orders.created_at', startBound)
              .lt('orders.created_at', endBound);

          int categoryVolumeCount = 0;
          for (var item in itemsRes) {
            categoryVolumeCount += (item['quantity'] as int? ?? 1);
          }

          compiledCatGoals.add(CategoryGoal.fromJson(raw, achieved: categoryVolumeCount));
        } else {
          compiledCatGoals.add(CategoryGoal.fromJson(raw));
        }
      })());
    }

    await Future.wait(calculationTasks);
    compiledCatGoals.sort((a, b) => b.monthYear.compareTo(a.monthYear));
    return compiledCatGoals;
  }

  /// Sets or updates the internal target limitation volume specifically mapped per category
  Future<void> setCategoryGoal({required String monthYear, required String categoryId, required int targetVolume}) async {
    state = const AsyncValue.loading();
    try {
      final supabase = Supabase.instance.client;
      // UPSERT using composite unique key constraint
      await supabase.from('category_goals').upsert(
        {
          'month_year': monthYear,
          'category_id': categoryId,
          'target_volume': targetVolume,
        },
        onConflict: 'month_year, category_id',
      );
      state = AsyncValue.data(await _fetchCategoryGoals());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      debugPrint('Error upserting category goal: $e');
      rethrow;
    }
  }
}

// Global hooks
final orderGoalsProvider = AsyncNotifierProvider<OrderGoalNotifier, List<OrderGoal>>(
  () => OrderGoalNotifier(),
);

final categoryGoalsProvider = AsyncNotifierProvider<CategoryGoalNotifier, List<CategoryGoal>>(
  () => CategoryGoalNotifier(),
);

final currentMonthCategoryGoalsProvider = Provider<List<CategoryGoal>>((ref) {
  final currentStr = DateFormat('yyyy-MM').format(DateTime.now());
  final goalsState = ref.watch(categoryGoalsProvider);
  
  return goalsState.maybeWhen(
    data: (goals) {
      return goals.where((g) => g.monthYear == currentStr).toList();
    },
    orElse: () => [],
  );
});

// We extract just the ACTIVE (current month) locally for specific hero visuals
final currentMonthOrderGoalProvider = Provider<OrderGoal?>((ref) {
  final currentStr = DateFormat('yyyy-MM').format(DateTime.now());
  final goalsState = ref.watch(orderGoalsProvider);
  
  return goalsState.maybeWhen(
    data: (goals) {
      try {
        return goals.firstWhere((g) => g.monthYear == currentStr);
      } catch (e) {
        return null;
      }
    },
    orElse: () => null,
  );
});
