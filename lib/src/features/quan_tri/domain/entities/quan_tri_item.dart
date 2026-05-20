import 'package:equatable/equatable.dart';

/// Domain entity for a row in Quản Trị table.
class QuanTriItem extends Equatable {
  const QuanTriItem({
    required this.id,
    required this.username,
    required this.fullname,
    required this.email,
    required this.mobile,
    required this.status,
    required this.statusLabel,
    required this.roleName,
    this.employeeCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String username;
  final String fullname;
  final String email;
  final String mobile;
  final String status;
  final String statusLabel;
  final String roleName;
  final String? employeeCode;
  final String? createdAt;
  final String? updatedAt;

  @override
  List<Object?> get props => [
    id,
    username,
    fullname,
    email,
    mobile,
    status,
    statusLabel,
    roleName,
    employeeCode,
    createdAt,
    updatedAt,
  ];
}
