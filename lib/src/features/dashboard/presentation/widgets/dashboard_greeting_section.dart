import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_user_stats.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/customer_by_status_row.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/dashboard_greeting_stats_card.dart';
import 'package:flutter/material.dart';

/// Khu vực chào hỏi trên Dashboard.
///
/// Bao gồm:
/// - Tiêu đề + tên người dùng
/// - [DashboardGreetingStatsCard]: role + tổng khách hàng
/// - [CustomerByStatusRow]: Mới | Tiềm năng | Nóng | Chốt
class DashboardGreetingSection extends StatelessWidget {
  const DashboardGreetingSection({
    required this.fullname,
    required this.role,
    required this.totalCustomer,
    required this.byStatus,
    super.key,
  });

  final String fullname;
  final String role;
  final int totalCustomer;
  final DashboardByStatus byStatus;

  String get _greetingText {
    final now = DateTime.now().toUtc().toLocal();
    final hour = now.hour;
    if (hour >= 0 && hour < 12) {
      return 'Chào buổi sáng,';
    } else if (hour >= 12 && hour < 18) {
      return 'Chào buổi chiều,';
    } else {
      return 'Chào buổi tối,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('tổng quan'.toUpperCase(), style: AppTextStyles.dashboardLabel),
          // const SizedBox(height: 8),
          Text(_greetingText, style: AppTextStyles.dashboardGreeting),
          Text(fullname, style: AppTextStyles.dashboardUserName),
          const SizedBox(height: 32),
          DashboardGreetingStatsCard(
            role: role,
            totalCustomer: totalCustomer,
          ),
          const SizedBox(height: 12),
          CustomerByStatusRow(byStatus: byStatus),
        ],
      ),
    );
  }
}
