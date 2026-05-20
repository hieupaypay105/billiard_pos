import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats_model.g.dart';

@JsonSerializable()
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalRevenue,
    required super.activeUsers,
    required super.newOrders,
    required super.monthlySales,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardStatsModelToJson(this);
}
