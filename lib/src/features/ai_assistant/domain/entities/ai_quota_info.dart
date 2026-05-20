import 'package:equatable/equatable.dart';

class AiQuotaInfo extends Equatable {
  final String used;
  final int quota;
  final int cost;
  final double percent;

  const AiQuotaInfo({
    required this.used,
    required this.quota,
    required this.cost,
    required this.percent,
  });

  @override
  List<Object?> get props => [used, quota, cost, percent];
}
