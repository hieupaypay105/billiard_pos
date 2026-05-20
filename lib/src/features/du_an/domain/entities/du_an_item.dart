import 'package:equatable/equatable.dart';

/// Domain entity for a row in Du An table.
class DuAnItem extends Equatable {
  const DuAnItem({
    required this.id,
    required this.name,
    required this.address,
    required this.investor,
    required this.hotline,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.projectType,
    this.note,
  });

  final String id;
  final String name;
  final String address;
  final String investor;
  final String hotline;
  final String status;
  final String statusLabel;
  final String createdAt;
  final String projectType;
  final String? note;

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    investor,
    hotline,
    status,
    statusLabel,
    createdAt,
    projectType,
    note,
  ];
}
