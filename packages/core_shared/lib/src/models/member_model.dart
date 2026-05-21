import 'package:equatable/equatable.dart';

class MemberModel extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final int? membershipTierId;
  final int totalPoints;
  final double accumulatedSpend;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MemberModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.membershipTierId,
    this.totalPoints = 0,
    this.accumulatedSpend = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String?,
      membershipTierId: json['membership_tier_id'] as int?,
      totalPoints: json['total_points'] as int? ?? 0,
      accumulatedSpend: (json['accumulated_spend'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'membership_tier_id': membershipTierId,
      'total_points': totalPoints,
      'accumulated_spend': accumulatedSpend,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phoneNumber,
        email,
        membershipTierId,
        totalPoints,
        accumulatedSpend,
        createdAt,
        updatedAt,
      ];
}
