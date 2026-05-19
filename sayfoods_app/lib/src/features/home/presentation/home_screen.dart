import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/shared/utils/page_transitions.dart';
import 'package:sayfoods_app/src/features/products/presentation/product_details_screen.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/features/profile/presentation/profile_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';
// If you are keeping the cart navigation here, you will also need the CartScreen import!
//import 'package:sayfoods_app/src/features/cart/presentation/cart_screen.dart';

// Widgets
import 'package:sayfoods_app/src/shared/widgets/product_card.dart';
import 'package:sayfoods_app/src/shared/widgets/category_chip.dart';
import 'package:sayfoods_app/src/shared/widgets/cart_icon_badge.dart';
import 'package:sayfoods_app/src/features/home/presentation/widgets/ads_carousel.dart';

// Providers
import 'package:sayfoods_app/src/features/products/application/product_provider.dart';

import 'package:sayfoods_app/src/features/blog/presentation/blog_list_screen.dart';
import 'package:sayfoods_app/src/features/chat/presentation/client_messages_screen.dart';
import 'package:sayfoods_app/src/features/orders/presentation/orders_screen.dart';
import 'package:sayfoods_app/src/features/notifications/application/notifications_provider.dart';
import 'package:sayfoods_app/src/features/notifications/presentation/notifications_screen.dart';
import 'package:sayfoods_app/src/features/products/presentation/favorites_screen.dart';
import 'package:sayfoods_app/src/features/products/presentation/search_screen.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _gridController;
  bool _gridAnimated = false;

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeView(),
      const OrdersScreen(),
      const ClientMessagesScreen(),
      const FavoritesScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppColors.primary.withValues(alpha: 0.1),
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 300),
              destinations: const [
                NavigationDestination(
                    icon: Icon(LucideIcons.home),
                    selectedIcon: Icon(LucideIcons.home, color: AppColors.primary),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(LucideIcons.shoppingBag),
                    selectedIcon: Icon(LucideIcons.shoppingBag,
                        color: AppColors.primary),
                    label: 'Orders'),
                NavigationDestination(
                    icon: Icon(LucideIcons.messageSquare),
                    selectedIcon:
                        Icon(LucideIcons.messageSquare, color: AppColors.primary),
                    label: 'Messages'),
                NavigationDestination(
                    icon: Icon(LucideIcons.heart),
                    selectedIcon: Icon(LucideIcons.heart,
                        color: AppColors.primary),
                    label: 'Favourites'),
              ],
            ),
          ),
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
      backgroundColor: AppColors.background, 
      appBar: SayfoodsAppBar(
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context)
                .push(FadeSlideRoute(builder: (_) => const SearchScreen())),
          ),
          const CartIconBadge(),
          // Bell badge — shows red dot when unread notifications exist
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell,
                    color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).push(
                  FadeSlideRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
              if (ref.watch(unreadCountProvider) > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.user, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).push(
              FadeSlideRoute(builder: (_) => const ProfileScreen()),
            ),
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
              const SizedBox(height: 24),

              // Blog entry card
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  FadeSlideRoute(
                      builder: (_) => const BlogListScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B1380), Color(0xFF8B21C0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.article_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SayFoods Blog',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text('Recipes, tips & fresh ideas',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                      // Trigger stagger once on first load
                      if (!_gridAnimated && products.isNotEmpty) {
                        _gridAnimated = true;
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _gridController.forward(from: 0));
                      }

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
                          final start =
                              (index * 0.12).clamp(0.0, 0.7);
                          final end = (start + 0.3).clamp(0.0, 1.0);
                          final itemAnim = CurvedAnimation(
                            parent: _gridController,
                            curve: Interval(start, end,
                                curve: Curves.easeOutCubic),
                          );

                          return FadeTransition(
                            opacity: itemAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(itemAnim),
                              child: ProductCard(
                            productId: product.id,
                            title: product.name,
                            description: product.description,
                            price: '₦${product.price.toStringAsFixed(0)}',
                            rating: product.rating,
                            imagePath: product.imageUrl.isNotEmpty
                                ? product.imageUrl
                                : 'assets/images/meat.png',
                            onTap: () {
                              Navigator.of(context).push(
                                FadeSlideRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                          ),  // ProductCard
                            ),  // SlideTransition
                          );   // FadeTransition
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
