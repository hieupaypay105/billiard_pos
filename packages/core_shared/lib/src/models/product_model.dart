import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String productName;
  final int? categoryId;
  final String unit;
  final double sellingPrice;
  final double costPrice;
  final int stockQuantity;
  final String? barcode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.productName,
    this.categoryId,
    required this.unit,
    required this.sellingPrice,
    this.costPrice = 0.0,
    this.stockQuantity = 0,
    this.barcode,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      unit: json['unit'] as String,
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '') ?? 0.0,
      costPrice: double.tryParse(json['cost_price']?.toString() ?? '') ?? 0.0,
      stockQuantity: int.tryParse(json['stock_quantity']?.toString() ?? '') ?? 0,
      barcode: json['barcode'] as String?,
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] == 1 ||
              json['is_active']?.toString() == '1' ||
              json['is_active']?.toString() == 'true'),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'category_id': categoryId,
      'unit': unit,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'barcode': barcode,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        productName,
        categoryId,
        unit,
        sellingPrice,
        costPrice,
        stockQuantity,
        barcode,
        isActive,
        createdAt,
        updatedAt,
      ];
}
