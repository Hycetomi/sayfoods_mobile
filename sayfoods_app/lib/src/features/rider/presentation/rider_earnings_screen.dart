import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/orders/domain/order_model.dart';
import 'package:sayfoods_app/src/features/rider/application/rider_earnings_provider.dart';
import 'package:sayfoods_app/src/features/rider/application/rider_schedule_provider.dart';

class RiderEarningsScreen extends ConsumerWidget {
  const RiderEarningsScreen({super.key});

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(riderEarningsProvider);
    final currentMonthEarnings = ref.watch(monthlyEarningsProvider);
    final upcomingShiftsAsync = ref.watch(riderUpcomingShiftsProvider);
    final currFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final currFmt2 = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    // Compute monthly stats from raw data
    final now = DateTime.now();
    final allOrders = earningsAsync.maybeWhen(
        data: (o) => o, orElse: () => <OrderModel>[]);
    final monthlyOrders = allOrders
        .where((o) =>
            o.completedAt != null &&
            o.completedAt!.month == now.month &&
            o.completedAt!.year == now.year &&
            o.commissionEarned > 0)
        .toList();
    final monthlyCount = monthlyOrders.length;
    final avgCommission =
        monthlyCount > 0 ? currentMonthEarnings / monthlyCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _purple,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroSection(
                earnings: currentMonthEarnings,
                deliveryCount: monthlyCount,
                avgCommission: avgCommission,
                currFmt: currFmt,
              ),
            ),
            title: const Text(
              'Earnings',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Upcoming Shifts ─────────────────────────────────
                _SectionHeader(
                  icon: Icons.calendar_month_rounded,
                  title: 'Upcoming Shifts',
                  trailing: 'Next 7 days',
                ),
                const SizedBox(height: 12),
                upcomingShiftsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Could not load shifts: $e',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ),
                  data: (shifts) => shifts.isEmpty
                      ? _EmptyShifts()
                      : _ShiftRow(shifts: shifts),
                ),

                const SizedBox(height: 28),

                // ── Delivery History ─────────────────────────────────
                _SectionHeader(
                  icon: Icons.history_rounded,
                  title: 'Delivery History',
                  trailing: '${allOrders.length} total',
                ),
                const SizedBox(height: 12),
                earningsAsync.when(
                  data: (orders) => orders.isEmpty
                      ? _EmptyHistory()
                      : _HistoryList(
                          orders: orders, currFmt: currFmt2),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('Error: $err')),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final double earnings;
  final int deliveryCount;
  final double avgCommission;
  final NumberFormat currFmt;

  const _HeroSection({
    required this.earnings,
    required this.deliveryCount,
    required this.avgCommission,
    required this.currFmt,
  });

  static const _purple = Color(0xFF5B1380);
  static const _purpleLight = Color(0xFF8B21C0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purple, _purpleLight],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This Month\'s Earnings',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currFmt.format(earnings),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.local_shipping_rounded,
                        label: '$deliveryCount trips',
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        icon: Icons.trending_up_rounded,
                        label: deliveryCount > 0
                            ? 'Avg ${currFmt.format(avgCommission)}'
                            : 'No data yet',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;

  const _SectionHeader(
      {required this.icon, required this.title, this.trailing});

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _purple),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }
}

// ── Shift Row ────────────────────────────────────────────────────────────────

class _ShiftRow extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  const _ShiftRow({required this.shifts});

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: shifts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final shift = shifts[index];
          final date = DateTime.parse(shift['shift_date'].toString());
          final isActive = shift['is_active'] as bool? ?? true;
          final isToday = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return Container(
            width: 72,
            decoration: BoxDecoration(
              color: isToday
                  ? _purple
                  : isActive
                      ? Colors.white
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday
                    ? _purple
                    : isActive
                        ? Colors.grey.shade200
                        : Colors.grey.shade300,
              ),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: _purple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.75)
                        : Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : Colors.black87,
                  ),
                ),
                if (!isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OFF',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Empty States ─────────────────────────────────────────────────────────────

class _EmptyShifts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy_rounded,
                color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Text(
              'No shifts scheduled for the next 7 days.',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No completed deliveries yet.',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History List ──────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<OrderModel> orders;
  final NumberFormat currFmt;

  const _HistoryList({required this.orders, required this.currFmt});

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final dateStr = order.completedAt != null
            ? DateFormat('MMM d • h:mm a')
                .format(order.completedAt!.toLocal())
            : '—';
        final isRevoked = order.commissionEarned <= 0;
        final shortId = order.id.substring(0, 8).toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isRevoked
                      ? Colors.red.withValues(alpha: 0.08)
                      : _purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRevoked
                      ? Icons.cancel_rounded
                      : Icons.delivery_dining_rounded,
                  color: isRevoked ? Colors.red : _purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$shortId',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.deliveryAddress.isNotEmpty
                          ? order.deliveryAddress
                          : dateStr,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        dateStr,
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Commission
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isRevoked
                        ? 'Revoked'
                        : '+${currFmt.format(order.commissionEarned)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isRevoked
                          ? Colors.red.shade400
                          : Colors.green.shade600,
                    ),
                  ),
                  if (!isRevoked) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Paid',
                        style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
