import 'package:equatable/equatable.dart';

class TableTypeModel extends Equatable {
  final int id;
  final String typeName;
  final String? description;
  final DateTime? createdAt;

  const TableTypeModel({
    required this.id,
    required this.typeName,
    this.description,
    this.createdAt,
  });

  factory TableTypeModel.fromJson(Map<String, dynamic> json) {
    return TableTypeModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      typeName: json['type_name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_name': typeName,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, typeName, description, createdAt];
}
