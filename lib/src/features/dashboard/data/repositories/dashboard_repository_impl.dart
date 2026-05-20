import 'package:anholding_app/src/features/dashboard/data/datasources/dashboard_mock_source.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_user_stats.dart';
import 'package:anholding_app/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required this.remoteDataSource});
  final DashboardRemoteDataSource remoteDataSource;

  @override
  Future<DashboardStats> getStats() async {
    return remoteDataSource.getStats();
  }

  @override
  Future<DashboardUserStats> getDashboardUserStats() async {
    return remoteDataSource.getDashboardUserStats();
  }
}
