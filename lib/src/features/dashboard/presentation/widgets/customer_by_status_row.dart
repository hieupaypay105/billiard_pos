import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_user_stats.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/dashboard_greeting_stats_card.dart'
    show DashboardGreetingStatsCard;
import 'package:flutter/material.dart';

/// Row compact hiển thị 4 trạng thái khách hàng từ `by_status`.
///
/// Layout: [ Mới | Tiềm năng | Nóng | Chốt ]
/// — Mỗi cell: số lớn + label nhỏ bên dưới
/// — Divider dọc 1px giữa các cell
/// — Cùng gradient background như [DashboardGreetingStatsCard]
class CustomerByStatusRow extends StatelessWidget {
  const CustomerByStatusRow({
    required this.byStatus,
    super.key,
  });

  final DashboardByStatus byStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardCardBorder),
        gradient: const LinearGradient(
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
          transform: GradientRotation(138.654 * 3.14159 / 180),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatusCell(
              label: 'Mới',
              count: byStatus.moi,
            ),
            _Divider(),
            _StatusCell(
              label: 'Tiềm năng',
              count: byStatus.tiemNang,
            ),
            _Divider(),
            _StatusCell(
              label: 'Nóng',
              count: byStatus.nong,
            ),
            _Divider(),
            _StatusCell(
              label: 'Chốt',
              count: byStatus.chot,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: AppTextStyles.dashboardCardValue.copyWith(
              fontSize: 18,
              color: AppColors.authButtonText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.authLabel.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}
