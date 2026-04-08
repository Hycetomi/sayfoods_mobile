class AddressModel {
  final String id;
  final String street;
  final String zoneId; // Now expects the UUID from your database
  final String? label; // e.g., 'Home', 'Office'
  final String? city;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.street,
    required this.zoneId,
    this.label,
    this.city,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      street: json['street_address'] as String? ?? '',
      zoneId: json['zone_id'].toString(),
      label: json['label'] as String?,
      city: json['city'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
