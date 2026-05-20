import 'package:equatable/equatable.dart';

/// Domain entity for a row in Khách Hàng table.
class KhachHangItem extends Equatable {
  const KhachHangItem({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.status,
    required this.createdAt,
    this.saleId = const [],
    this.code,
    this.email,
    this.phone,
    this.address,
    this.note,
    this.updatedAt,
    this.regionId,
    this.districtId,
    this.dob,
    this.gender,
    this.projectId,
    this.area,
    this.type,
    this.financialRange,
    this.lastContact,
    this.scheduleContact,
    this.canUpdate = 0,
    this.canDelete = 0,
    this.statusLabel = const [],
    this.financialRangeLabel,
    this.regionLabel,
    this.projectLabel,
    this.sourceLabel,
  });

  final String id;
  final String? sourceId;
  final List<String> saleId;
  final String? code;
  final String name;
  final String? phone;
  final String? address;
  final String status;
  final String createdAt;
  final String? email;
  final String? note;
  final String? updatedAt;
  final String? regionId;
  final String? districtId;
  final String? dob;
  final String? gender;
  final String? projectId;
  final String? area;
  final String? type;
  final String? financialRange;
  final String? lastContact;
  final String? scheduleContact;
  final int canUpdate;
  final int canDelete;
  final List<String> statusLabel;
  final String? financialRangeLabel;
  final String? regionLabel;
  final String? projectLabel;
  final String? sourceLabel;

  @override
  List<Object?> get props => [
    id,
    sourceId,
    saleId,
    code,
    name,
    phone,
    address,
    status,
    createdAt,
    email,
    note,
    updatedAt,
    regionId,
    districtId,
    dob,
    gender,
    projectId,
    area,
    type,
    financialRange,
    lastContact,
    scheduleContact,
    canUpdate,
    canDelete,
    statusLabel,
    financialRangeLabel,
    regionLabel,
    projectLabel,
    sourceLabel,
  ];
}
