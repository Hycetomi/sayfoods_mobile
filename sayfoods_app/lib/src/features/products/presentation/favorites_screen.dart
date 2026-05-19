import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/products/application/favorites_provider.dart';
import 'package:sayfoods_app/src/features/products/application/product_provider.dart';
import 'package:sayfoods_app/src/features/products/presentation/product_details_screen.dart';
import 'package:sayfoods_app/src/shared/widgets/product_card.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);
    final allProductsAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const SayfoodsAppBar(
        title: 'Favourites',
        showBackButton: false,
      ),
      body: allProductsAsync.when(
        data: (all) {
          final favourites =
              all.where((p) => favIds.contains(p.id)).toList();

          if (favourites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No favourites yet.\nTap the ♡ on any product to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                        height: 1.5),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: favourites.length,
            itemBuilder: (context, index) {
              final product = favourites[index];
              return ProductCard(
                productId: product.id,
                title: product.name,
                description: product.description,
                price: '₦${product.price.toStringAsFixed(0)}',
                rating: product.rating,
                imagePath: product.imageUrl.isNotEmpty
                    ? product.imageUrl
                    : 'assets/images/meat.png',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailsScreen(product: product)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
