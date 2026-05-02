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
import 'package:sayfoods_app/src/features/home/presentation/widgets/ads_carousel.dart';

// Providers
import 'package:sayfoods_app/src/features/products/application/product_provider.dart';

import 'package:sayfoods_app/src/features/chat/presentation/client_messages_screen.dart';
import 'package:sayfoods_app/src/features/orders/presentation/orders_screen.dart';
import 'package:sayfoods_app/src/features/products/presentation/search_screen.dart';

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
      const ClientMessagesScreen(),
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
              color: Colors.black.withValues(alpha: 0.05),
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
    final activeCat = ref.watch(selectedCategoryProvider);

    void handleCategoryTap(String dbCategory) {
      if (activeCat == dbCategory) {
        ref.read(selectedCategoryProvider.notifier).state = null; // Toggle off
      } else {
        ref.read(selectedCategoryProvider.notifier).state = dbCategory;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey background to make cards pop
      appBar: SayfoodsAppBar(
        showBackButton: false, // Home screen doesn't need a back button
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
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
                child: ref.watch(categoryListProvider).when(
                      loading: () => const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                        ),
                      ),
                      error: (err, stack) => const Center(
                        child: Text('Failed to load categories', style: TextStyle(color: Colors.red)),
                      ),
                      data: (categories) {
                        if (categories.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            // Provide a default emoji based on the name if possible, or a generic one
                            String fallbackEmoji = '🛒';
                            if (cat.name.toLowerCase().contains('meat')) fallbackEmoji = '🍗';
                            if (cat.name.toLowerCase().contains('dairy')) fallbackEmoji = '🥚';
                            if (cat.name.toLowerCase().contains('produce')) fallbackEmoji = '🌶️';
                            if (cat.name.toLowerCase().contains('pantry')) fallbackEmoji = '🍘';
                            
                            return CategoryChip(
                              emoji: fallbackEmoji,
                              imageUrl: cat.iconPath,
                              label: cat.name,
                              isSelected: activeCat == cat.name,
                              onTap: () => handleCategoryTap(cat.name),
                            );
                          },
                        );
                      },
                    ),
              ),
              const SizedBox(height: 32),

              // 2. Promo Banner
              const AdsCarousel(),
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
