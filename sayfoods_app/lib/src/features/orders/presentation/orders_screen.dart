import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/orders/application/order_provider.dart';
import 'package:sayfoods_app/src/features/orders/presentation/widgets/ongoing_timeline.dart';
import 'package:sayfoods_app/src/features/orders/presentation/widgets/completed_order_card.dart';
import 'package:sayfoods_app/src/features/orders/presentation/order_details_screen.dart';
import 'package:sayfoods_app/src/features/products/presentation/search_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderStateAsync = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Sayfoods',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87), 
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            }
          ),
          IconButton(icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.black87), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 2. Tab Bar
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.orange,
                indicatorWeight: 3,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ),

          // 3. Tab Views
          Expanded(
            child: orderStateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange)),
              error: (e, st) => Center(child: Text('Error loading orders: $e')),
              data: (state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // --- ONGOING TAB ---
                    state.ongoing.isEmpty
                        ? const Center(child: Text('No ongoing orders', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: state.ongoing.length,
                            itemBuilder: (context, index) {
                              final order = state.ongoing[index];
                              return CompletedOrderCard(
                                order: order,
                                isOngoing: true,
                                onViewDetails: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                                  );
                                },
                                onReorder: () {
                                  // Can just navigate to timeline as well for ongoing
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => OngoingTimelineScreen(order: order)),
                                  );
                                },
                              );
                            },
                          ),

                    // --- COMPLETED TAB ---
                    state.completed.isEmpty
                        ? const Center(child: Text('No completed orders', style: TextStyle(color: Colors.grey)))
                         : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: state.completed.length,
                            itemBuilder: (context, index) {
                              final order = state.completed[index];
                              return CompletedOrderCard(
                                order: order,
                                onViewDetails: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                                  );
                                },
                                onReorder: () {
                                  // Future: Add items back to cart
                                },
                              );
                            },
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
