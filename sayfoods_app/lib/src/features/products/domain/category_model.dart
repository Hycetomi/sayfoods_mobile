class CategoryModel {
  final String id;
  final String name;
  final String? iconPath;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconPath,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Unknown Category',
      iconPath: json['icon_path'] as String?,
    );
  }
}
