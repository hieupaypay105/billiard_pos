import 'package:anholding_app/src/features/khach_hang/domain/entities/contact_item.dart';

class ContactItemModel extends ContactItem {
  const ContactItemModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.comment,
    required super.createdAt,
    required super.updatedAt,
    required super.customerId,
  });

  factory ContactItemModel.fromJson(Map<String, dynamic> json) {
    return ContactItemModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
    );
  }
}
