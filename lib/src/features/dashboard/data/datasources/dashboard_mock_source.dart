import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:anholding_app/src/features/dashboard/data/models/dashboard_user_model.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_user_stats.dart';
import 'package:dio/dio.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getStats();
  Future<DashboardUserStats> getDashboardUserStats();
}

/// Mock source — kept for unit tests / offline dev.
class DashboardMockDataSource implements DashboardRemoteDataSource {
  @override
  Future<DashboardStatsModel> getStats() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const DashboardStatsModel(
      totalRevenue: 125000.50,
      activeUsers: 1234,
      newOrders: 56,
      monthlySales: [12, 15, 18, 14, 22, 28, 35, 32, 40, 45, 42, 50],
    );
  }

  @override
  Future<DashboardUserStats> getDashboardUserStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const DashboardUserStats(
      role: 'Nhân viên',
      totalCustomer: 0,
      byStatus: DashboardByStatus.empty,
    );
  }
}

/// Real remote data source using Dio.
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<DashboardStatsModel> getStats() async {
    // Legacy method — returns empty model; actual data flows via getDashboardUserStats.
    return const DashboardStatsModel(
      totalRevenue: 0,
      activeUsers: 0,
      newOrders: 0,
      monthlySales: [],
    );
  }

  @override
  Future<DashboardUserStats> getDashboardUserStats() async {
    final response = await dio.get<Map<String, dynamic>>(ApiPaths.dashboard);
    final data = response.data ?? {};
    return DashboardUserModel.fromJson(data);
  }
}
