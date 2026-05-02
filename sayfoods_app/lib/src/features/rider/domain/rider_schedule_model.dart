import 'package:intl/intl.dart';

class RiderScheduleModel {
  final String id;
  final String riderId;
  final DateTime shiftDate;
  final bool isActive;
  final DateTime createdAt;

  RiderScheduleModel({
    required this.id,
    required this.riderId,
    required this.shiftDate,
    required this.isActive,
    required this.createdAt,
  });

  factory RiderScheduleModel.fromJson(Map<String, dynamic> json) {
    return RiderScheduleModel(
      id: json['id'].toString(),
      riderId: json['rider_id'].toString(),
      shiftDate: DateTime.parse(json['shift_date'].toString()).toLocal(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()).toLocal() 
          : DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(shiftDate);
  }
}
