class DeliveryZone {
  final String id;
  final String name;
  final double price;

  DeliveryZone({required this.id, required this.name, required this.price});

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Unknown Zone',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
