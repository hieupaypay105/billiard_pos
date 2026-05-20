import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/dashboard_greeting_section.dart'
    show DashboardGreetingSection;
import 'package:flutter/material.dart';

/// Card gradient hiển thị VỊ TRÍ HIỆN TẠI và TỔNG KHÁCH HÀNG.
///
/// Tách ra từ [DashboardGreetingSection] để tái sử dụng độc lập.
class DashboardGreetingStatsCard extends StatelessWidget {
  const DashboardGreetingStatsCard({
    required this.role,
    required this.totalCustomer,
    super.key,
  });

  final String role;
  final int totalCustomer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      child: Row(
        spacing: 16,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'VỊ TRÍ HIỆN TẠI',
                  style: AppTextStyles.authLabel.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: AppTextStyles.dashboardCardValue.copyWith(
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TỔNG KHÁCH HÀNG',
                  style: AppTextStyles.authLabel.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCustomer',
                  style: AppTextStyles.dashboardCardValue.copyWith(
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
