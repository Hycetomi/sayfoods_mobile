import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/products/domain/product_model.dart';

// --- 1. The Cart Item Model ---
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  // A handy method to update the quantity without mutating the original object
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

// --- 2. The Cart Notifier ---
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return []; // Start with an empty cart
  }

  void addItem(Product product, int quantity) {
    final currentState = state;

    // Check if the product is already in the cart
    final existingIndex = currentState.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // If it exists, just increase the quantity
      final updatedItem = currentState[existingIndex].copyWith(
        quantity: currentState[existingIndex].quantity + quantity,
      );

      // Create a new list with the updated item to trigger a UI rebuild
      final newState = List<CartItem>.from(currentState);
      newState[existingIndex] = updatedItem;
      state = newState;
    } else {
      // If it's a new product, add it to the list
      state = [...currentState, CartItem(product: product, quantity: quantity)];
    }
  }

  // --- ADD THESE TO CartNotifier ---
  void incrementItem(String productId) {
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
  }

  void decrementItem(String productId) {
    final existingItem = state.firstWhere(
      (item) => item.product.id == productId,
    );
    if (existingItem.quantity > 1) {
      // Decrease quantity
      state = state.map((item) {
        if (item.product.id == productId) {
          return item.copyWith(quantity: item.quantity - 1);
        }
        return item;
      }).toList();
    } else {
      // If it hits 0, remove the item from the cart entirely
      state = state.where((item) => item.product.id != productId).toList();
    }
  }

  void clearCart() {
    state = [];
  }
}

// --- 3. The Riverpod Providers ---

// The main provider that holds the list of items
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

// A derived provider that instantly calculates the grand total!
final cartTotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(
    0.0,
    (total, item) => total + (item.product.price * item.quantity),
  );
});
