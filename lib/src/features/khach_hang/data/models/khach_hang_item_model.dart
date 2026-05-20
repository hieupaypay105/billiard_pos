import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';

class KhachHangItemModel extends KhachHangItem {
  const KhachHangItemModel({
    required super.id,
    required super.name,
    required super.status,
    required super.createdAt,
    super.sourceId,
    super.saleId,
    super.code,
    super.email,
    super.phone,
    super.address,
    super.note,
    super.updatedAt,
    super.regionId,
    super.districtId,
    super.dob,
    super.gender,
    super.projectId,
    super.area,
    super.type,
    super.financialRange,
    super.lastContact,
    super.scheduleContact,
    super.canUpdate,
    super.canDelete,
    super.statusLabel,
    super.financialRangeLabel,
    super.regionLabel,
    super.projectLabel,
    super.sourceLabel,
  });

  factory KhachHangItemModel.fromJson(Map<String, dynamic> json) {
    return KhachHangItemModel(
      id: json['id']?.toString() ?? '',
      sourceId: json['source_id']?.toString(),
      saleId: _parseSaleIds(json['sales']),
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      email: json['email']?.toString(),
      note: json['note']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      regionId: json['region_id']?.toString(),
      districtId: json['district_id']?.toString(),
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      projectId: json['project_id']?.toString(),
      area: json['area']?.toString(),
      type: json['type']?.toString(),
      financialRange: json['financial_range']?.toString(),
      lastContact: json['last_contact']?.toString(),
      scheduleContact: json['schedule_contact']?.toString(),
      canUpdate: int.tryParse(json['can_update']?.toString() ?? '0') ?? 0,
      canDelete: int.tryParse(json['can_delete']?.toString() ?? '0') ?? 0,
      statusLabel: _parseStringList(json['status_label']),
      financialRangeLabel: json['financial_range_label']?.toString(),
      regionLabel: json['region_label']?.toString(),
      projectLabel: json['project_label']?.toString(),
      sourceLabel: json['source_label']?.toString(),
    );
  }

  /// Parses sale names/IDs from API — handles both plain strings `["Sale"]`
  /// and nested objects `[{"id": 1, "name": "..."}]`.
  static List<String> _parseSaleIds(Object? value) {
    if (value is! List) return const [];
    return value
        .map((e) {
          if (e is Map) {
            return (e['id'] ?? e['value'])?.toString();
          }
          return e?.toString();
        })
        .whereType<String>()
        .toList(growable: false);
  }

  static List<String> _parseStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString())
        .whereType<String>()
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_id': sourceId,
      'sales': saleId,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'status': status,
      'created_at': createdAt,
      'email': email,
      'note': note,
      'updated_at': updatedAt,
      'region_id': regionId,
      'district_id': districtId,
      'dob': dob,
      'gender': gender,
      'project_id': projectId,
      'area': area,
      'type': type,
      'financial_range': financialRange,
      'last_contact': lastContact,
      'schedule_contact': scheduleContact,
      'can_update': canUpdate,
      'can_delete': canDelete,
      'status_label': statusLabel,
      'financial_range_label': financialRangeLabel,
      'region_label': regionLabel,
      'project_label': projectLabel,
      'source_label': sourceLabel,
    };
  }
}
