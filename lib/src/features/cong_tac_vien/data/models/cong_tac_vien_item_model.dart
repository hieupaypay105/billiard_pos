import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_item.dart';

class CongTacVienItemModel extends CongTacVienItem {
  const CongTacVienItemModel({
    required super.id,
    required super.parentId,
    required super.saleName,
    required super.code,
    required super.fullname,
    required super.email,
    required super.status,
    required super.mobile,
    required super.createdAt,
    required super.statusLabel,
    super.basePath,
    super.imageFile,
    super.dob,
    super.updatedAt,
  });

  factory CongTacVienItemModel.fromJson(Map<String, dynamic> json) {
    return CongTacVienItemModel(
      id: json['id']?.toString() ?? '',
      parentId: json['parent_id']?.toString() ?? '',
      saleName: json['sale_name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? '0',
      mobile: json['mobile']?.toString() ?? '',
      basePath: json['base_path']?.toString(),
      imageFile: json['image_file']?.toString(),
      dob: json['dob']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
      statusLabel: json['status_label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'sale_name': saleName,
      'code': code,
      'fullname': fullname,
      'email': email,
      'status': status,
      'mobile': mobile,
      'base_path': basePath,
      'image_file': imageFile,
      'dob': dob,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'status_label': statusLabel,
    };
  }
}
