import 'package:equatable/equatable.dart';

/// Domain entity for a row in Cộng Tác Viên table.
class CongTacVienItem extends Equatable {
  const CongTacVienItem({
    required this.id,
    required this.parentId,
    required this.saleName,
    required this.code,
    required this.fullname,
    required this.email,
    required this.status,
    required this.mobile,
    required this.createdAt,
    required this.statusLabel,
    this.basePath,
    this.imageFile,
    this.dob,
    this.updatedAt,
  });

  final String id;
  final String parentId;
  final String saleName;
  final String code;
  final String fullname;
  final String email;
  final String status;
  final String mobile;
  final String? basePath;
  final String? imageFile;
  final String? dob;
  final String createdAt;
  final String? updatedAt;
  final String statusLabel;

  @override
  List<Object?> get props => [
    id,
    parentId,
    saleName,
    code,
    fullname,
    email,
    status,
    mobile,
    basePath,
    imageFile,
    dob,
    createdAt,
    updatedAt,
    statusLabel,
  ];
}
