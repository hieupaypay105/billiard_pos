import 'package:equatable/equatable.dart';

/// Entity cho user stats từ API `/dashboard`.
class DashboardByStatus extends Equatable {
  const DashboardByStatus({
    required this.moi,
    required this.tiemNang,
    required this.nong,
    required this.chot,
  });

  final int moi;
  final int tiemNang;
  final int nong;
  final int chot;

  static const empty = DashboardByStatus(
    moi: 0,
    tiemNang: 0,
    nong: 0,
    chot: 0,
  );

  @override
  List<Object?> get props => [moi, tiemNang, nong, chot];
}

class DashboardUserStats extends Equatable {
  const DashboardUserStats({
    required this.role,
    required this.totalCustomer,
    required this.byStatus,
  });

  final String role;
  final int totalCustomer;
  final DashboardByStatus byStatus;

  static const empty = DashboardUserStats(
    role: '--',
    totalCustomer: 0,
    byStatus: DashboardByStatus.empty,
  );

  @override
  List<Object?> get props => [role, totalCustomer, byStatus];
}
