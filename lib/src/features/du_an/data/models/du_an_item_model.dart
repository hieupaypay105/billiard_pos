import 'package:anholding_app/src/features/du_an/domain/entities/du_an_item.dart';

class DuAnItemModel extends DuAnItem {
  const DuAnItemModel({
    required super.id,
    required super.name,
    required super.address,
    required super.investor,
    required super.hotline,
    required super.status,
    required super.statusLabel,
    required super.createdAt,
    required super.projectType,
    super.note,
  });

  factory DuAnItemModel.fromJson(Map<String, dynamic> json) {
    return DuAnItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      investor: json['investor']?.toString() ?? '',
      hotline: json['hotline']?.toString() ?? '',
      status: json['status']?.toString() ?? '0',
      statusLabel: json['status_label']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      projectType: json['type']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'investor': investor,
      'hotline': hotline,
      'status': status,
      'status_label': statusLabel,
      'created_at': createdAt,
      'project_type': projectType,
      if (note != null) 'note': note,
    };
  }
}
