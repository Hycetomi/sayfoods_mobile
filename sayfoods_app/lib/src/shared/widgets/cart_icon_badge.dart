import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers and Screens
import 'package:sayfoods_app/src/features/cart/application/cart_provider.dart';
import 'package:sayfoods_app/src/features/cart/presentation/cart_screen.dart';

class CartIconBadge extends ConsumerWidget {
  const CartIconBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the cart state
    final cartItems = ref.watch(cartProvider);

    // Calculate the total number of items in the cart
    final totalItems = cartItems.fold(0, (sum, item) => sum + item.quantity);

    return Badge(
      // The badge only shows up if there is at least 1 item in the cart
      isLabelVisible: totalItems > 0,
      label: Text(
        totalItems.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.orange, // A bright color to grab attention
      offset: const Offset(-4, 4), // Tweaks the position of the little circle
      child: IconButton(
        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const CartScreen()));
        },
      ),
    );
  }
}
