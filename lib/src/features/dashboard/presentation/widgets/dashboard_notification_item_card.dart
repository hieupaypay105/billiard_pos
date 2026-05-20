import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardNotificationItemCard extends StatelessWidget {
  const DashboardNotificationItemCard({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    super.key,
  });

  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm • dd MMM');
    final formattedDate = dateFormat.format(createdAt).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardCardBorder),
        gradient: const LinearGradient(
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
          transform: GradientRotation(115.174 * 3.14159 / 180),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isRead ? AppColors.authTextSecondary : AppColors.authButtonText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formattedDate,
                style: AppTextStyles.authLabel.copyWith(
                  color: AppColors.notifTimestampColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.dashboardCardValue),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTextStyles.dashboardNotifBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
