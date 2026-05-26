import 'package:equatable/equatable.dart';

class ProductCategoryModel extends Equatable {
  final int id;
  final String categoryName;
  final DateTime? createdAt;

  const ProductCategoryModel({
    required this.id,
    required this.categoryName,
    this.createdAt,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      categoryName: json['category_name'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_name': categoryName,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, categoryName, createdAt];
}
