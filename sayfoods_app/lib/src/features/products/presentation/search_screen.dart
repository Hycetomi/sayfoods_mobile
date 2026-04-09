import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/products/application/search_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/product_card.dart';
import 'package:sayfoods_app/src/features/products/presentation/product_details_screen.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We bind to the specific search query state
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for foods, spices...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(fontSize: 18, color: Colors.black87),
          onChanged: (value) {
            // Update Riverpod which triggers the debounced DB call automatically!
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black87),
              onPressed: () {
                // Clear the string
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'What are you looking for?',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  )
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: resultsAsync.when(
                // Error mapping (mostly swallowing the 'Debounce cancelled' errors to hide UI jerks)
                error: (error, stack) {
                   if (error.toString().contains('Debounce cancelled')) {
                     return const Center(child: CircularProgressIndicator(color: Colors.orange));
                   }
                   return Center(child: Text('Error: $error'));
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange)),
                data: (products) {
                  if (products.isEmpty) {
                     return Center(
                        child: Text(
                          'No items match "$query"',
                           style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                     );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    // Use standard bouncing physics so grid scrolls properly if it extends beyond screen
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
