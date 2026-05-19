import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/admin/application/admin_product_provider.dart';
import 'package:sayfoods_app/src/features/admin/presentation/add_edit_product_screen.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';
import 'package:sayfoods_app/src/shared/utils/error_handler.dart';

class ManageProductsScreen extends ConsumerStatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  ConsumerState<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends ConsumerState<ManageProductsScreen> {
  final bgColor = AppColors.background;
  final primaryPurple = AppColors.primary;
  final colorOrange = AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = ref.watch(adminProductListProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Manage Products', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) {
                ref.read(adminProductSearchQueryProvider.notifier).state = val;
              },
              decoration: InputDecoration(
                hintText: 'Search products by name...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
        },
        backgroundColor: primaryPurple,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('New Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: productsAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator(color: primaryPurple)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products match your criteria.', style: TextStyle(color: AppColors.textSecondary)));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24).copyWith(bottom: 100),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];

              return Dismissible(
                key: Key(product.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LucideIcons.trash2, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  return await SayfoodsModal.show<bool>(
                    context: context,
                    type: SayfoodsModalType.warning,
                    title: 'Delete Product?',
                    subtitle: 'You are about to delete "${product.name}".\n\nThis action removes it entirely from the database and cannot be undone. Proceed?',
                    primaryButtonText: 'DELETE',
                    onPrimaryPressed: () => Navigator.of(context).pop(true),
                    secondaryButtonText: 'CANCEL',
                    onSecondaryPressed: () => Navigator.of(context).pop(false),
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await ref.read(adminProductListProvider.notifier).deleteProduct(product.id);
                    if (context.mounted) {
                      SayfoodsModal.show(
                        context: context,
                        type: SayfoodsModalType.success,
                        title: 'Deleted',
                        subtitle: '${product.name} deleted',
                      );
                    }
                  } catch (e) {
                     if (context.mounted) {
                      SayfoodsModal.show(
                        context: context,
                        type: SayfoodsModalType.error,
                        title: 'Error',
                        subtitle: ErrorHelper.getErrorMessage(e),
                      );
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), // soft shadow
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(product.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(LucideIcons.imageOff, color: AppColors.textDisabled))
                          : const Icon(LucideIcons.utensils, color: AppColors.textDisabled),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          product.categoryName ?? 'No Category', 
                          style: TextStyle(fontSize: 12, color: primaryPurple, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stock Indicator Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.stockQuantity > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Stock: ${product.stockQuantity}',
                            style: TextStyle(
                              color: product.stockQuantity > 0 ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, color: AppColors.info),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddEditProductScreen(productToEdit: product)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
