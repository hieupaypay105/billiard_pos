import 'package:equatable/equatable.dart';

class AiQuotaRequestInfo extends Equatable {
  final String used;
  final int quota;
  final int cost;
  final double percent;
  final String monthRequests;

  const AiQuotaRequestInfo({
    required this.used,
    required this.quota,
    required this.cost,
    required this.percent,
    required this.monthRequests,
  });

  @override
  List<Object?> get props => [used, quota, cost, percent, monthRequests];
}
