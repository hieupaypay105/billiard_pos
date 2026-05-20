import 'package:equatable/equatable.dart';

/// Domain entity for a contact/exchange item (Trao đổi).
class ContactItem extends Equatable {
  const ContactItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
  });

  final String id;
  final String userId;
  final String name;
  final String comment;
  final String createdAt;
  final String updatedAt;
  final String customerId;

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    comment,
    createdAt,
    updatedAt,
    customerId,
  ];
}
