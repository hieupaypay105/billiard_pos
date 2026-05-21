import 'package:equatable/equatable.dart';

class ShiftModel extends Equatable {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final double initialCash;
  final double expectedCash;
  final double? actualCash;
  final double totalCardAmount;
  final double totalTransferAmount;
  final double discrepancyAmount;
  final String? note;
  final String status; // 'open', 'closed'

  const ShiftModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.initialCash,
    this.expectedCash = 0.0,
    this.actualCash,
    this.totalCardAmount = 0.0,
    this.totalTransferAmount = 0.0,
    this.discrepancyAmount = 0.0,
    this.note,
    this.status = 'open',
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      initialCash: (json['initial_cash'] as num).toDouble(),
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (json['actual_cash'] as num?)?.toDouble(),
      totalCardAmount: (json['total_card_amount'] as num?)?.toDouble() ?? 0.0,
      totalTransferAmount: (json['total_transfer_amount'] as num?)?.toDouble() ?? 0.0,
      discrepancyAmount: (json['discrepancy_amount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      status: json['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'initial_cash': initialCash,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'total_card_amount': totalCardAmount,
      'total_transfer_amount': totalTransferAmount,
      'discrepancy_amount': discrepancyAmount,
      'note': note,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        startTime,
        endTime,
        initialCash,
        expectedCash,
        actualCash,
        totalCardAmount,
        totalTransferAmount,
        discrepancyAmount,
        note,
        status,
      ];
}
