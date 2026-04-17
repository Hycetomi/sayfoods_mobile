class OrderGoal {
  final String id;
  final String monthYear; // Format: "yyyy-MM" e.g., "2026-04"
  final int targetOrders;
  final int achievedOrders;

  OrderGoal({
    required this.id,
    required this.monthYear,
    required this.targetOrders,
    this.achievedOrders = 0,
  });

  // Calculate percentage securely
  double get progressPercentage {
    if (targetOrders == 0) return 0.0;
    return (achievedOrders / targetOrders).clamp(0.0, 1.0);
  }

  // Calculate if the goal is completed
  bool get isCompleted => achievedOrders >= targetOrders;

  factory OrderGoal.fromJson(Map<String, dynamic> json, {int achieved = 0}) {
    return OrderGoal(
      id: json['id'].toString(),
      monthYear: json['month_year'].toString(),
      targetOrders: json['target_orders'] as int? ?? 0,
      achievedOrders: achieved,
    );
  }
}

// ------ CATEGORY ANALYTICS COMPONENT ------

class CategoryGoal {
  final String id;
  final String monthYear; 
  final String categoryId;
  final String categoryName; // Attached locally post-query
  final int targetVolume;
  final int achievedVolume;

  CategoryGoal({
    required this.id,
    required this.monthYear,
    required this.categoryId,
    required this.categoryName,
    required this.targetVolume,
    this.achievedVolume = 0,
  });

  double get progressPercentage {
    if (targetVolume == 0) return 0.0;
    return (achievedVolume / targetVolume).clamp(0.0, 1.0);
  }

  bool get isCompleted => achievedVolume >= targetVolume;

  factory CategoryGoal.fromJson(Map<String, dynamic> json, {int achieved = 0, String catName = 'Category'}) {
    return CategoryGoal(
      id: json['id'].toString(),
      monthYear: json['month_year'].toString(),
      categoryId: json['category_id'].toString(),
      categoryName: json['categories'] != null ? json['categories']['name'] : catName,
      targetVolume: json['target_volume'] as int? ?? 0,
      achievedVolume: achieved,
    );
  }
}
