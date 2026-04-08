class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  // This factory converts the raw JSON map from Supabase into a Dart object
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Unknown Product',
      description:
          json['description'] as String? ?? 'No description available.',
      // We use 'num' here because Supabase might return an int (3000) or double (3000.50)
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl:
          json['image_url'] as String? ??
          '', // We'll handle empty images in the UI
    );
  }
}
