import 'package:equatable/equatable.dart';

class AreaModel extends Equatable {
  final int id;
  final String areaName;
  final String? description;
  final DateTime? createdAt;

  const AreaModel({
    required this.id,
    required this.areaName,
    this.description,
    this.createdAt,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] as int,
      areaName: json['area_name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area_name': areaName,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, areaName, description, createdAt];
}
