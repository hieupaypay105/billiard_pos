import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String passwordHash;
  final String displayName;
  final String role; // 'admin', 'manager', 'cashier', 'waiter'
  final String? phoneNumber;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      passwordHash: json['password_hash'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
      phoneNumber: json['phone_number'] as String?,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active'] == 1 || json['is_active'] == 'true'),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'display_name': displayName,
      'role': role,
      'phone_number': phoneNumber,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        username,
        passwordHash,
        displayName,
        role,
        phoneNumber,
        isActive,
        createdAt,
        updatedAt,
      ];
}
