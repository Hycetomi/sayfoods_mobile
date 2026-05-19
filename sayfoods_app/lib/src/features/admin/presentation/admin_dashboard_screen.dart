import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/admin/application/admin_provider.dart';
import 'package:sayfoods_app/src/features/admin/application/order_goal_provider.dart';
import 'package:sayfoods_app/src/features/admin/presentation/admin_order_detail_screen.dart';
import 'package:sayfoods_app/src/shared/utils/page_transitions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  static const _orange = AppColors.warning;
  static const _bg     = AppColors.background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              _DashboardHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats section ────────────────────────────────────────
                    ref.watch(adminStatsProvider).when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(color: _orange),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e',
                          style: const TextStyle(color: Colors.red)),
                      data: (stats) => _StatsSection(
                          stats: stats,
                          ref: ref,
                          currFmt: currFmt),
                    ),

                    const SizedBox(height: 32),

                    // ── Recent orders ────────────────────────────────────────
                    const Text('Recent Orders',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 14),

                    ref.watch(adminRecentOrdersProvider).when(
                      loading: () => const Center(
                          child:
                              CircularProgressIndicator(color: _orange)),
                      error: (e, _) => Text('Error: $e',
                          style: const TextStyle(color: Colors.red)),
                      data: (orders) {
                        if (orders.isEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('No orders yet.',
                                  style: TextStyle(
                                      color: Colors.grey.shade400)),
                            ),
                          );
                        }
                        return Column(
                          children: orders
                              .map((order) => _OrderTile(
                                    order: order,
                                    onTap: () async {
                                      final refreshed =
                                          await Navigator.push<bool>(
                                        context,
                                        FadeSlideRoute(
                                          builder: (_) =>
                                              AdminOrderDetailScreen(
                                                  order: order),
                                        ),
                                      );
                                      if (refreshed == true) {
                                        ref.invalidate(
                                            adminRecentOrdersProvider);
                                      }
                                    },
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard header ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceVariant, AppColors.primary, AppColors.primary],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sayfoods',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.search,
                          color: Colors.white, size: 22),
                      onPressed: () {},
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Overview of your store',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats section ─────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final AdminDashboardStats stats;
  final WidgetRef ref;
  final NumberFormat currFmt;

  const _StatsSection(
      {required this.stats, required this.ref, required this.currFmt});

  static const _purple = AppColors.primary;
  static const _orange = AppColors.warning;
  static const _green  = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(currentMonthOrderGoalProvider);
    final achieved = goal?.achievedOrders ?? 0;
    final progress = goal?.progressPercentage ?? 0.0;
    final target = goal?.targetOrders.toString() ?? '–';

    return Column(
      children: [
        // Row 1 — Stock + Goal
        Row(
          children: [
            Expanded(
              child: _StatCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${stats.totalStockCount}',
                        style: const TextStyle(
                            color: _purple,
                            fontSize: 34,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Stock Count',
                        style: TextStyle(
                            color: _orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: stats.stockBreakdown.entries
                          .map((e) => _MiniStat(e.key, e.value.toString()))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$achieved',
                        style: const TextStyle(
                            color: _purple,
                            fontSize: 34,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Mthly Orders',
                        style: TextStyle(
                            color: _orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    _GoalBar(
                        achieved: achieved,
                        progress: progress,
                        target: target),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 2 — Users | Revenue | Orders total (3 mini cards)
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: LucideIcons.users,
                iconBg: _purple.withValues(alpha: 0.10),
                iconColor: _purple,
                value: stats.usersCount > 1000
                    ? '${(stats.usersCount / 1000).toStringAsFixed(1)}k'
                    : '${stats.usersCount}',
                label: 'Users',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatCard(
                icon: LucideIcons.trendingUp,
                iconBg: _green.withValues(alpha: 0.15),
                iconColor: _green,
                value: _formatRevenue(stats.totalRevenue),
                label: 'Revenue',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatCard(
                icon: LucideIcons.receipt,
                iconBg: _orange.withValues(alpha: 0.12),
                iconColor: _orange,
                value: '${stats.ordersCount}',
                label: 'Orders',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatRevenue(double v) {
    if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(0)}k';
    return '₦${v.toStringAsFixed(0)}';
  }
}

// ── Reusable card widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final Widget child;
  const _StatCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 10)),
        Text(value,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
      ],
    );
  }
}

class _GoalBar extends StatelessWidget {
  final int achieved;
  final double progress;
  final String target;
  const _GoalBar(
      {required this.achieved,
      required this.progress,
      required this.target});

  static const _purple = Color(0xFF5B1380);
  static const _orange = Color(0xFFF28F2A);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Order Goal',
                style: TextStyle(
                    color: _orange, fontSize: 9, fontWeight: FontWeight.bold)),
            Text('${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    color: _orange.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade100,
            valueColor:
                const AlwaysStoppedAnimation<Color>(_purple),
            minHeight: 7,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$achieved',
                style: const TextStyle(
                    color: _orange,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
            Text(target,
                style: const TextStyle(
                    color: _orange,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final dynamic order;
  final VoidCallback onTap;
  const _OrderTile({required this.order, required this.onTap});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':        return Colors.orange;
      case 'accepted':       return Colors.blue;
      case 'out_for_delivery':
      case 'delivering':     return Colors.teal;
      case 'delivered':
      case 'completed':      return Colors.green;
      case 'cancelled':      return Colors.red;
      default:               return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status as String);
    final statusLabel = (order.status as String)
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.shoppingBag,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (order.displayTitle as String).toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.clientName as String? ?? 'Unknown',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: statusColor)),
                  const SizedBox(width: 4),
                  Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
