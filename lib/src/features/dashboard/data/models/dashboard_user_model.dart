import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_user_stats.dart';

/// DTO model cho response của `GET /dashboard`.
///
/// Response shape:
/// ```json
/// {
///   "status": 1,
///   "data": {
///     "user": {
///       "role": "Giám đốc kinh doanh",
///       "total_customer": 1,
///       "by_status": { "moi": 1, "tiem_nang": 0, "nong": 0, "chot": 0 }
///     }
///   }
/// }
/// ```
class DashboardUserModel extends DashboardUserStats {
  const DashboardUserModel({
    required super.role,
    required super.totalCustomer,
    required super.byStatus,
  });

  factory DashboardUserModel.fromJson(Map<String, dynamic> json) {
    final user = (json['data'] as Map<String, dynamic>?)?['user']
        as Map<String, dynamic>? ??
        {};
    final byStatusRaw =
        user['by_status'] as Map<String, dynamic>? ?? {};

    return DashboardUserModel(
      role: (user['role'] as String?) ?? '--',
      totalCustomer: (user['total_customer'] as num?)?.toInt() ?? 0,
      byStatus: DashboardByStatus(
        moi: (byStatusRaw['moi'] as num?)?.toInt() ?? 0,
        tiemNang: (byStatusRaw['tiem_nang'] as num?)?.toInt() ?? 0,
        nong: (byStatusRaw['nong'] as num?)?.toInt() ?? 0,
        chot: (byStatusRaw['chot'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
