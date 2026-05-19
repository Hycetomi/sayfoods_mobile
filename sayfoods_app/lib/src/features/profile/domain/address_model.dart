class AddressModel {
  final String id;
  final String street;
  final String zoneId;
  final String? label;
  final String? city;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.street,
    required this.zoneId,
    this.label,
    this.city,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      street: json['street_address'] as String? ?? '',
      zoneId: json['zone_id'].toString(),
      label: json['label'] as String?,
      city: json['city'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
