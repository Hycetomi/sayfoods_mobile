class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final String? type;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.isRead,
    this.type,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      type: json['type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
