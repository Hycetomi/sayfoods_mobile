import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/products/application/category_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/text_input_dialog.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsyncValue = ref.watch(categoryListProvider);
    final bgColor = const Color(0xFFFCFCFC);
    final primaryPurple = const Color(0xFF5B1380);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Manage Categories', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newName = await TextInputDialog.show(
            context: context,
            title: 'New Category Name',
            initialValue: '',
          );
          if (newName != null && newName.isNotEmpty) {
            try {
              await ref.read(categoryListProvider.notifier).addCategory(newName);
              if (context.mounted) {
                SayfoodsModal.show(
                  context: context,
                  type: SayfoodsModalType.success,
                  title: 'Category Added',
                  subtitle: 'Category added successfully!',
                );
              }
            } catch (e) {
              if (context.mounted) {
                SayfoodsModal.show(
                  context: context,
                  type: SayfoodsModalType.error,
                  title: 'Error',
                  subtitle: 'Error adding category: $e',
                );
              }
            }
          }
        },
        backgroundColor: primaryPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: categoriesAsyncValue.when(
        loading: () => Center(child: CircularProgressIndicator(color: primaryPurple)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found. Let\'s create one!', style: TextStyle(color: Colors.grey)));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];

              return Dismissible(
                key: Key(category.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  final result = await SayfoodsModal.showBottomSheet<int>(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Delete Category?',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You are about to delete "${category.name}".\nWould you like to delete JUST this category, or BOTH the category and all associated products?',
                            style: const TextStyle(color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('ONLY CATEGORY'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('CATEGORY & PRODUCTS'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(0),
                            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (result == null || result == 0) return false;

                  try {
                    bool deleteProducts = (result == 2);
                    await ref.read(categoryListProvider.notifier).deleteCategory(category.id, deleteProducts: deleteProducts);
                    if (context.mounted) {
                      SayfoodsModal.show(
                        context: context,
                        type: SayfoodsModalType.success,
                        title: 'Deleted',
                        subtitle: '${category.name} deleted${deleteProducts ? " along with products" : ""}',
                      );
                    }
                    return true;
                  } catch (e) {
                    if (context.mounted) {
                      SayfoodsModal.show(
                        context: context,
                        type: SayfoodsModalType.error,
                        title: 'Error',
                        subtitle: e.toString(),
                      );
                    }
                    return false;
                  }
                },
                onDismissed: (direction) {
                  // Handled during confirmDismiss to properly await the async provider method
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04), // soft shadow
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.category, color: primaryPurple),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    subtitle: Text(category.iconPath ?? 'No icon assigned', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () async {
                        final newName = await TextInputDialog.show(
                          context: context,
                          title: 'Edit Category Name',
                          initialValue: category.name,
                        );
                        if (newName != null && newName.isNotEmpty && newName != category.name) {
                          try {
                            await ref.read(categoryListProvider.notifier).updateCategory(category.id, newName);
                            if (context.mounted) {
                              SayfoodsModal.show(
                                context: context,
                                type: SayfoodsModalType.success,
                                title: 'Updated',
                                subtitle: 'Category updated successfully',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              SayfoodsModal.show(
                                context: context,
                                type: SayfoodsModalType.error,
                                title: 'Error',
                                subtitle: 'Error updating: $e',
                              );
                            }
                          }
                        }
                      },
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
