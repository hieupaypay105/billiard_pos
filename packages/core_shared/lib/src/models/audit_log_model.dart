import 'package:equatable/equatable.dart';

class AuditLogModel extends Equatable {
  final String id;
  final String? userId;
  final String actionType; // 'FORCE_ON_TABLE', 'FORCE_OFF_TABLE', 'DELETE_ORDER_ITEM', ...
  final String? tableId;
  final String? orderId;
  final String description;
  final String? deviceInfo;
  final DateTime? createdAt;

  const AuditLogModel({
    required this.id,
    this.userId,
    required this.actionType,
    this.tableId,
    this.orderId,
    required this.description,
    this.deviceInfo,
    this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      actionType: json['action_type'] as String,
      tableId: json['table_id'] as String?,
      orderId: json['order_id'] as String?,
      description: json['description'] as String,
      deviceInfo: json['device_info'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action_type': actionType,
      'table_id': tableId,
      'order_id': orderId,
      'description': description,
      'device_info': deviceInfo,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        actionType,
        tableId,
        orderId,
        description,
        deviceInfo,
        createdAt,
      ];
}
