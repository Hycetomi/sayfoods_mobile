import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/admin/application/order_goal_provider.dart';
import 'package:sayfoods_app/src/features/admin/domain/order_goal_model.dart';
import 'package:sayfoods_app/src/shared/widgets/text_input_dialog.dart';
import 'package:sayfoods_app/src/features/products/application/category_provider.dart';

class OrderGoalsScreen extends ConsumerStatefulWidget {
  const OrderGoalsScreen({super.key});

  @override
  ConsumerState<OrderGoalsScreen> createState() => _OrderGoalsScreenState();
}

class _OrderGoalsScreenState extends ConsumerState<OrderGoalsScreen> {
  final primaryPurple = const Color(0xFF5B1380);
  final colorOrange = const Color(0xFFF28F2A);
  final bgColor = const Color(0xFFFCFCFC);

  Future<void> _showSetGlobalGoalDialog(BuildContext context, String monthYear, [int? currentTarget]) async {
    final result = await TextInputDialog.show(
      context: context,
      title: 'Target: ${_formatMonthRaw(monthYear)}',
      initialValue: currentTarget?.toString() ?? '',
      hintText: 'e.g. 500 orders',
    );

    if (result != null && result.isNotEmpty) {
      final val = int.tryParse(result.trim());
      if (val != null && val > 0) {
        if (!mounted) return;
        try {
          await ref.read(orderGoalsProvider.notifier).setGoal(monthYear: monthYear, target: val);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Global Order Goal mathematically active!'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
          }
        }
      }
    }
  }

  Future<void> _showSetCategoryGoalDialog(BuildContext context, String monthYear, String categoryId, String catName, [int? currentTarget]) async {
    final result = await TextInputDialog.show(
      context: context,
      title: 'Volume Target: $catName',
      initialValue: currentTarget?.toString() ?? '',
      hintText: 'e.g. 150 items',
    );

    if (result != null && result.isNotEmpty) {
      final val = int.tryParse(result.trim());
      if (val != null && val > 0) {
        if (!mounted) return;
        try {
          await ref.read(categoryGoalsProvider.notifier).setCategoryGoal(
            monthYear: monthYear, 
            categoryId: categoryId, 
            targetVolume: val
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('$catName Limits natively locked!'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
          }
        }
      }
    }
  }

  String _formatMonthRaw(String monthYearRaw) {
    // raw is like "2026-04"
    final parts = monthYearRaw.split('-');
    if (parts.length == 2) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y != null && m != null) {
        final dt = DateTime(y, m);
        return DateFormat('MMMM yyyy').format(dt);
      }
    }
    return monthYearRaw;
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthRaw = DateFormat('yyyy-MM').format(DateTime.now());
    
    // Global Systems
    final goalsState = ref.watch(orderGoalsProvider);
    final currentGlobalGoal = ref.watch(currentMonthOrderGoalProvider);
    
    // Category Systems
    final catGoalsState = ref.watch(categoryGoalsProvider);
    final activeCatGoals = ref.watch(currentMonthCategoryGoalsProvider);
    final activeCategories = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Analytical Target Suite', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: goalsState.when(
        loading: () => Center(child: CircularProgressIndicator(color: primaryPurple)),
        error: (e, st) => Center(child: Text('Error: $e\nCheck RLS policies!', style: const TextStyle(color: Colors.red))),
        data: (goals) {
          final history = goals.where((g) => g.monthYear != currentMonthRaw).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orderGoalsProvider);
              ref.invalidate(categoryGoalsProvider);
            },
            child: CustomScrollView(
              slivers: [
                // 1. Hero Section (Global Goal)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildCurrentGoalHero(currentGlobalGoal, currentMonthRaw),
                  ),
                ),
                
                // 2. Category Sub-Deck Header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Category Volume Limitations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),

                // 3. Mini Category Cards Flow Array
                SliverToBoxAdapter(
                  child: catGoalsState.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (_) {
                      return activeCategories.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                        data: (categories) {
                           if (categories.isEmpty) {
                             return const Padding(
                               padding: EdgeInsets.all(24),
                               child: Text("No product categories exist natively yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                             );
                           }

                           return SingleChildScrollView(
                             scrollDirection: Axis.horizontal,
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                             child: Row(
                               children: categories.map((cat) {
                                 // Check if this specific category has a loaded goal this active month
                                 final matchedGoal = activeCatGoals.firstWhere(
                                   (g) => g.categoryId == cat.id,
                                   orElse: () => CategoryGoal(id: '', monthYear: '', categoryId: cat.id, categoryName: cat.name, targetVolume: 0)
                                 );

                                 return _buildCategoryMiniCard(context, currentMonthRaw, cat.id, cat.name, matchedGoal);
                               }).toList(),
                             ),
                           );
                        }
                      );
                    }
                  ),
                ),
                
                // 4. Timeline History Header
                if (history.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
                      child: Text(
                        'Global Historical Timeline',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ),

                // 5. Timeline List
                if (history.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildHistoryCard(history[index]);
                      },
                      childCount: history.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryMiniCard(BuildContext context, String currentMonthStr, String categoryId, String catName, CategoryGoal goal) {
    final bool hasGoal = goal.targetVolume > 0;
    
    return GestureDetector(
      onTap: () => _showSetCategoryGoalDialog(context, currentMonthStr, categoryId, catName, hasGoal ? goal.targetVolume : null),
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
             const SizedBox(height: 12),
             if (hasGoal) ...[
               Text('${(goal.progressPercentage * 100).toStringAsFixed(0)}% Complete', style: TextStyle(color: colorOrange, fontSize: 12, fontWeight: FontWeight.w600)),
               const SizedBox(height: 8),
               LinearProgressIndicator(
                  value: goal.progressPercentage,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(goal.isCompleted ? Colors.green : colorOrange),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
               ),
               const SizedBox(height: 8),
               Text('${goal.achievedVolume} / ${goal.targetVolume} items', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
             ] else ...[
               const Icon(Icons.add_chart, color: Colors.grey),
               const SizedBox(height: 4),
               const Text('Tap to set limit', style: TextStyle(color: Colors.grey, fontSize: 12)),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentGoalHero(OrderGoal? goal, String currentMonthRaw) {
    if (goal == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: primaryPurple.withOpacity(0.1), width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.public, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("No Global Target", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("You haven't set an overarching operations limit for ${_formatMonthRaw(currentMonthRaw)}.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showSetGlobalGoalDialog(context, currentMonthRaw),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_task),
              label: const Text('Set Global Operation Limit', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    double percentage = goal.progressPercentage;
    bool completed = goal.isCompleted;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryPurple, primaryPurple.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: primaryPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text('GLOBAL OPERATIONS: ${_formatMonthRaw(currentMonthRaw).toUpperCase()}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percentage),
                  duration: const Duration(seconds: 2),
                  curve: Curves.fastOutSlowIn,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 14,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(completed ? Colors.greenAccent : colorOrange),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  if (completed) const Icon(Icons.verified, color: Colors.greenAccent, size: 20)
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatMetric('Delivered', goal.achievedOrders.toString(), completed ? Colors.greenAccent : Colors.white),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatMetric('Global Limit', goal.targetOrders.toString(), Colors.white54),
            ],
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _showSetGlobalGoalDialog(context, currentMonthRaw, goal.targetOrders),
            icon: const Icon(Icons.edit, color: Colors.white70, size: 16),
            label: const Text('Update Global Limit', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
          )
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildHistoryCard(OrderGoal goal) {
    bool passed = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: passed ? Colors.green.shade50 : Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(passed ? Icons.check_circle : Icons.trending_down, color: passed ? Colors.green : Colors.red, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatMonthRaw(goal.monthYear), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: goal.progressPercentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(passed ? Colors.green : colorOrange),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${goal.achievedOrders} / ${goal.targetOrders}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Orders', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
