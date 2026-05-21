import 'package:equatable/equatable.dart';

class TableModel extends Equatable {
  final String id;
  final String tableName;
  final int areaId;
  final int tableTypeId;
  final String status; // 'idle', 'active', 'booked', 'maintenance'
  final String? currentOrderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TableModel({
    required this.id,
    required this.tableName,
    required this.areaId,
    required this.tableTypeId,
    this.status = 'idle',
    this.currentOrderId,
    this.createdAt,
    this.updatedAt,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as String,
      tableName: json['table_name'] as String,
      areaId: json['area_id'] as int,
      tableTypeId: json['table_type_id'] as int,
      status: json['status'] as String? ?? 'idle',
      currentOrderId: json['current_order_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'area_id': areaId,
      'table_type_id': tableTypeId,
      'status': status,
      'current_order_id': currentOrderId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TableModel copyWith({
    String? id,
    String? tableName,
    int? areaId,
    int? tableTypeId,
    String? status,
    String? currentOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      areaId: areaId ?? this.areaId,
      tableTypeId: tableTypeId ?? this.tableTypeId,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tableName,
        areaId,
        tableTypeId,
        status,
        currentOrderId,
        createdAt,
        updatedAt,
      ];
}
