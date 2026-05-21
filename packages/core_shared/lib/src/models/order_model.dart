import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final String id;
  final String tableId;
  final String? memberId;
  final String shiftId;
  final String status; // 'active', 'paid', 'cancelled'
  final DateTime startTime;
  final DateTime? endTime;
  final int totalPlayTimeMinutes;
  final double totalPlayTimeAmount;
  final double totalProductAmount;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String? paymentMethod; // 'cash', 'card', 'transfer'
  final String createdBy;
  final String? closedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.tableId,
    this.memberId,
    required this.shiftId,
    this.status = 'active',
    required this.startTime,
    this.endTime,
    this.totalPlayTimeMinutes = 0,
    this.totalPlayTimeAmount = 0.0,
    this.totalProductAmount = 0.0,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
    this.paymentMethod,
    required this.createdBy,
    this.closedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      tableId: json['table_id'] as String,
      memberId: json['member_id'] as String?,
      shiftId: json['shift_id'] as String,
      status: json['status'] as String? ?? 'active',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      totalPlayTimeMinutes: json['total_play_time_minutes'] as int? ?? 0,
      totalPlayTimeAmount: (json['total_play_time_amount'] as num?)?.toDouble() ?? 0.0,
      totalProductAmount: (json['total_product_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String?,
      createdBy: json['created_by'] as String,
      closedBy: json['closed_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_id': tableId,
      'member_id': memberId,
      'shift_id': shiftId,
      'status': status,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_play_time_minutes': totalPlayTimeMinutes,
      'total_play_time_amount': totalPlayTimeAmount,
      'total_product_amount': totalProductAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'created_by': createdBy,
      'closed_by': closedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? tableId,
    String? memberId,
    String? shiftId,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    int? totalPlayTimeMinutes,
    double? totalPlayTimeAmount,
    double? totalProductAmount,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    String? paymentMethod,
    String? createdBy,
    String? closedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      memberId: memberId ?? this.memberId,
      shiftId: shiftId ?? this.shiftId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPlayTimeMinutes: totalPlayTimeMinutes ?? this.totalPlayTimeMinutes,
      totalPlayTimeAmount: totalPlayTimeAmount ?? this.totalPlayTimeAmount,
      totalProductAmount: totalProductAmount ?? this.totalProductAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdBy: createdBy ?? this.createdBy,
      closedBy: closedBy ?? this.closedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tableId,
        memberId,
        shiftId,
        status,
        startTime,
        endTime,
        totalPlayTimeMinutes,
        totalPlayTimeAmount,
        totalProductAmount,
        discountAmount,
        taxAmount,
        totalAmount,
        paymentMethod,
        createdBy,
        closedBy,
        createdAt,
        updatedAt,
      ];
}
