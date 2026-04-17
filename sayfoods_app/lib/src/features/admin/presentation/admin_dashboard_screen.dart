import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/admin/application/admin_provider.dart';
import 'package:sayfoods_app/src/features/admin/application/order_goal_provider.dart';
import 'package:sayfoods_app/src/features/admin/presentation/admin_order_detail_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Brand colors based on design
    const colorPurple = Color(0xFF5B1380);
    const colorOrange = Color(0xFFF28F2A);
    const bgColor = Color(0xFFFCFCFC); // extremely light off-white

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sayfoods',
                    style: TextStyle(
                      color: colorPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.w900, // Extra bold
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. Dashboard Title
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),

              // 3. Top Stats Cards (Row)
              Builder(builder: (context) {
                final currentGoal = ref.watch(currentMonthOrderGoalProvider);
                final int goalAchieved = currentGoal?.achievedOrders ?? 0;
                final double goalPercentage = currentGoal?.progressPercentage ?? 0.0;
                final String targetStr = currentGoal?.targetOrders.toString() ?? "N/A";

                return ref.watch(adminStatsProvider).when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: colorOrange),
                  )),
                  error: (err, stack) => Center(child: Text('Error loading stats: $err', style: const TextStyle(color: Colors.red))),
                  data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        // Left Card (Stock)
                        Expanded(
                          child: _buildNeumorphicCard(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${stats.totalStockCount}', style: const TextStyle(color: colorPurple, fontSize: 32, fontWeight: FontWeight.w900)),
                                const Text('Stock count', style: TextStyle(color: colorOrange, fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: stats.stockBreakdown.entries
                                      .map((e) => _buildMiniStat(e.key, e.value.toString()))
                                      .toList(),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Right Card (Orders Goal)
                        Expanded(
                          child: _buildNeumorphicCard(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$goalAchieved', style: const TextStyle(color: colorPurple, fontSize: 32, fontWeight: FontWeight.w900)),
                                const Text('Mthly Orders', style: TextStyle(color: colorOrange, fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 16),
                                
                                // Custom Progress Bar
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Order Goal', style: TextStyle(color: colorOrange, fontSize: 8, fontWeight: FontWeight.bold)),
                                          Text('${(goalPercentage * 100).toStringAsFixed(0)}%', style: TextStyle(color: colorOrange.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text('$goalAchieved ', style: const TextStyle(color: colorOrange, fontSize: 8, fontWeight: FontWeight.bold)),
                                          Expanded(
                                            child: Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                                gradient: LinearGradient(
                                                  colors: const [colorPurple, Colors.black12],
                                                  stops: [goalPercentage, goalPercentage],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(' $targetStr', style: const TextStyle(color: colorOrange, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Center Card (Users)
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: _buildNeumorphicCard(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(stats.usersCount > 1000 ? '${(stats.usersCount/1000).toStringAsFixed(1)}k' : '${stats.usersCount}', style: const TextStyle(color: colorPurple, fontSize: 32, fontWeight: FontWeight.w900)),
                              const Text('Users', style: TextStyle(color: colorOrange, fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline, size: 28),
                                  SizedBox(width: 8),
                                  Icon(Icons.person_outline, size: 28),
                                  SizedBox(width: 8),
                                  Icon(Icons.person_outline, size: 28),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
              }),
              const SizedBox(height: 48),

              // 5. Orders Section Header
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Orders',
                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Orders List
              ref.watch(adminRecentOrdersProvider).when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: colorOrange),
                )),
                error: (err, stack) => Center(child: Text('Error loading orders: $err')),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No orders found.', style: TextStyle(color: Colors.grey))),
                    );
                  }

                   return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      Color sColor = Colors.grey;
                      String statusLabel = order.status.toLowerCase();
                      if (statusLabel == 'pending') sColor = Colors.orange;
                      if (statusLabel == 'processing' || statusLabel == 'confirmed') sColor = Colors.blue;
                      if (statusLabel == 'out_for_delivery') sColor = Colors.teal;
                      if (statusLabel == 'delivered' || statusLabel == 'completed') sColor = Colors.green;
                      if (statusLabel == 'cancelled') sColor = Colors.red;

                      return GestureDetector(
                        onTap: () async {
                          final refreshed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminOrderDetailScreen(order: order),
                            ),
                          );
                          if (refreshed == true) {
                            ref.invalidate(adminRecentOrdersProvider);
                          }
                        },
                        child: _buildOrderTile(
                          order.displayTitle.toUpperCase(),
                          order.clientName ?? 'Unknown Customer',
                          order.status[0].toUpperCase() + order.status.substring(1),
                          sColor,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for the white rounded soft-shadow panels
  Widget _buildNeumorphicCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Ultra soft shadow 
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ]
      ),
      child: child,
    );
  }

  Widget _buildMiniStat(String label, String subLabel) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
        Text(subLabel, style: TextStyle(color: Colors.grey[600], fontSize: 8)),
      ],
    );
  }

  // Replicates the pill-shaped order list items
  Widget _buildOrderTile(String title, String subtitle, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Heavy rounding for pill shape
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.04),
             blurRadius: 10,
             offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          // Graphic leading circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: Colors.green, width: 1.5),
            ),
            child: const Icon(Icons.egg, color: Colors.orange, size: 16), // Proxy logo
          ),
          const SizedBox(width: 12),
          
          Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                 Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
               ],
             )
          ),
          
          // Trailing Status
          Text(status, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          const SizedBox(width: 4),
          Container(
             width: 8, 
             height: 8,
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               color: statusColor,
             ),
          )
        ],
      ),
    );
  }
}
