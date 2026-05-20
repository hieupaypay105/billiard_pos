import 'package:anholding_app/src/features/quan_tri/domain/entities/quan_tri_item.dart';

class QuanTriItemModel extends QuanTriItem {
  const QuanTriItemModel({
    required super.id,
    required super.username,
    required super.fullname,
    required super.email,
    required super.mobile,
    required super.status,
    required super.statusLabel,
    required super.roleName,
    super.employeeCode,
    super.createdAt,
    super.updatedAt,
  });

  factory QuanTriItemModel.fromJson(Map<String, dynamic> json) {
    return QuanTriItemModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      status: json['status']?.toString() ?? '0',
      statusLabel: json['status_label']?.toString() ?? '',
      roleName: json['role_name']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullname': fullname,
      'email': email,
      'mobile': mobile,
      'status': status,
      'status_label': statusLabel,
      'role_name': roleName,
      'employee_code': employeeCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
