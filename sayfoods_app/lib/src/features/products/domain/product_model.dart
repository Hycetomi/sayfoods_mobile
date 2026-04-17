class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final String imageUrl;
  final String? categoryName; // Maps the text from categories table
  final String? categoryId;
  final int stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.categoryName,
    this.categoryId,
    this.stockQuantity = 0,
  });

  // This factory converts the raw JSON map from Supabase into a Dart object
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Unknown Product',
      description:
          json['description'] as String? ?? 'No description available.',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_path'] as String? ?? json['image_url'] as String? ?? '', 
      categoryName: json['categories'] != null 
          ? json['categories']['name'] as String?
          : null,
      categoryId: json['category_id']?.toString(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}
