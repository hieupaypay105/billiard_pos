import 'package:equatable/equatable.dart';

class MembershipTierModel extends Equatable {
  final int id;
  final String tierName;
  final int minPoints;
  final double discountPercentage;
  final DateTime? createdAt;

  const MembershipTierModel({
    required this.id,
    required this.tierName,
    this.minPoints = 0,
    this.discountPercentage = 0.0,
    this.createdAt,
  });

  factory MembershipTierModel.fromJson(Map<String, dynamic> json) {
    return MembershipTierModel(
      id: json['id'] as int,
      tierName: json['tier_name'] as String,
      minPoints: json['min_points'] as int? ?? 0,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier_name': tierName,
      'min_points': minPoints,
      'discount_percentage': discountPercentage,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        tierName,
        minPoints,
        discountPercentage,
        createdAt,
      ];
}
