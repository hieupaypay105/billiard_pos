import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_user_stats.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getStats();
  Future<DashboardUserStats> getDashboardUserStats();
}
