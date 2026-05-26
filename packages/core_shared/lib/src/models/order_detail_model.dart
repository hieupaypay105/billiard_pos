import 'package:equatable/equatable.dart';

class OrderDetailModel extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String addedBy;
  final DateTime? createdAt;

  const OrderDetailModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.addedBy,
    this.createdAt,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '') ?? 0.0,
      addedBy: json['added_by'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'added_by': addedBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        quantity,
        unitPrice,
        totalPrice,
        addedBy,
        createdAt,
      ];
}
