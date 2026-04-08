import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/products/presentation/product_details_screen.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/features/profile/presentation/profile_screen.dart';
// If you are keeping the cart navigation here, you will also need the CartScreen import!
//import 'package:sayfoods_app/src/features/cart/presentation/cart_screen.dart';

// Widgets
import 'package:sayfoods_app/src/shared/widgets/product_card.dart';
import 'package:sayfoods_app/src/shared/widgets/category_chip.dart';
import 'package:sayfoods_app/src/shared/widgets/cart_icon_badge.dart';

// Providers
import 'package:sayfoods_app/src/features/products/application/product_provider.dart';

import 'package:sayfoods_app/src/features/orders/presentation/orders_screen.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeView(),
      const OrdersScreen(),
      const Center(child: Text('Messages Coming Soon', style: TextStyle(fontSize: 18, color: Colors.grey))),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey background to make cards pop
      appBar: SayfoodsAppBar(
        showBackButton: false, // Home screen doesn't need a back button
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),

          const CartIconBadge(),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Categories
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryChip(
                      emoji: '🥚',
                      label: 'Eggs',
                      onTap: () {
                        // TODO: Filter grid by Eggs
                      },
                    ),
                    const SizedBox(width: 12),
                    CategoryChip(emoji: '🍘', label: 'Snacks', onTap: () {}),
                    const SizedBox(width: 12),
                    CategoryChip(emoji: '🍗', label: 'Meat', onTap: () {}),
                    const SizedBox(width: 12),
                    CategoryChip(emoji: '🌶️', label: 'Spices', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Promo Banner
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/banner.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SayFoods',
                          style: TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          'Introducing',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          'Eggs & Cousins',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 3. Product Grid (Powered by Riverpod!)
              ref
                  .watch(productListProvider)
                  .when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Oops! Could not load products: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    data: (products) {
                      // Empty State
                      if (products.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No products available yet.\nCheck back soon!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

                      // Data State
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];

                          return ProductCard(
                            title: product.name,
                            description: product.description,
                            price: '₦${product.price.toStringAsFixed(0)}',
                            rating: product.rating,
                            imagePath: product.imageUrl.isNotEmpty
                                ? product.imageUrl
                                : 'assets/images/meat.png',
                            onTap: () {
                              // Navigate to the Product Details Screen!
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
