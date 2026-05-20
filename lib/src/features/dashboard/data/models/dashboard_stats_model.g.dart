// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStatsModel _$DashboardStatsModelFromJson(Map<String, dynamic> json) =>
    DashboardStatsModel(
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      activeUsers: (json['activeUsers'] as num).toInt(),
      newOrders: (json['newOrders'] as num).toInt(),
      monthlySales: (json['monthlySales'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$DashboardStatsModelToJson(
  DashboardStatsModel instance,
) => <String, dynamic>{
  'totalRevenue': instance.totalRevenue,
  'activeUsers': instance.activeUsers,
  'newOrders': instance.newOrders,
  'monthlySales': instance.monthlySales,
};
