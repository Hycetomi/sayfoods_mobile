import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/products/domain/product_model.dart';
import 'package:sayfoods_app/src/features/admin/application/admin_product_provider.dart';
import 'package:sayfoods_app/src/features/products/application/category_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  
  String? _selectedCategoryId;
  bool _isLoading = false;
  
  // Image picker state
  File? _selectedImageFile;
  bool _imageWasCleared = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stockQuantity.toString() ?? '');
    
    _selectedCategoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        // Compressing the image natively to save bandwidth
        imageQuality: 70, 
        maxWidth: 1024,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _imageWasCleared = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageFile = null;
      _imageWasCleared = true;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(adminProductListProvider.notifier);
      
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final price = double.parse(_priceCtrl.text.trim());
      final stock = int.parse(_stockCtrl.text.trim());

      if (widget.productToEdit == null) {
        // Add
        await notifier.addProduct(
          name: name,
          description: desc,
          price: price,
          stockQuantity: stock,
          categoryId: _selectedCategoryId,
          imageFile: _selectedImageFile,
        );
      } else {
        // Update
        await notifier.updateProduct(
          widget.productToEdit!.id,
          name: name,
          description: desc,
          price: price,
          stockQuantity: stock,
          categoryId: _selectedCategoryId,
          imageFile: _selectedImageFile,
          clearImage: _imageWasCleared,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productToEdit == null ? "Product Added" : "Product Updated"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFCFCFC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Image Picker UI
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _buildImagePreview(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Product Name'),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration('e.g. Fresh Milk'),
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Category'),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Error loading categories: $e', style: const TextStyle(color: Colors.red)),
                data: (categories) {
                   return DropdownButtonFormField<String>(
                     decoration: _inputDecoration('Select a Category'),
                     value: _selectedCategoryId,
                     items: categories.map((cat) {
                       return DropdownMenuItem(
                         value: cat.id,
                         child: Text(cat.name),
                       );
                     }).toList(),
                     onChanged: (val) {
                       setState(() {
                         _selectedCategoryId = val;
                       });
                     },
                     validator: (v) => v == null ? 'Please select a category' : null,
                   );
                }
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Price'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('0.00').copyWith(prefixText: '\$ '),
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Stock Quantity'),
                        TextFormField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0'),
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (int.tryParse(v) == null) return 'Invalid integer';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel('Description'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDecoration('Product details...'),
                validator: (v) => v!.isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B1380),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'UPDATE PRODUCT' : 'ADD PRODUCT',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImageFile!, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
              onPressed: _clearImage,
            ),
          )
        ],
      );
    }
    
    if (widget.productToEdit != null && widget.productToEdit!.imageUrl.isNotEmpty && !_imageWasCleared) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(widget.productToEdit!.imageUrl, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              onPressed: _clearImage,
            ),
          )
        ],
      );
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, size: 50, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text('Tap to select an image', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
