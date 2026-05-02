class MessageModel {
  final String id;
  final String channelType;
  final String? orderId;
  final String? riderId;
  final String senderId;
  final String? senderName;
  final String content;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.channelType,
    this.orderId,
    this.riderId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      channelType: json['channel_type'] as String,
      orderId: json['order_id'] as String?,
      riderId: json['rider_id'] as String?,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
