import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:flutter/material.dart';

class AiQuotaCard extends StatelessWidget {
  const AiQuotaCard({required this.requestInfo, super.key});
  final AiQuotaRequestInfo requestInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundSolid.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('Requests\ntháng', requestInfo.monthRequests),
          _buildInfoItem('Đã dùng\nhôm nay', requestInfo.used),
          _buildInfoItem('Hạn mức\nngày', requestInfo.quota.toString()),
          _buildInfoItem('Tỷ lệ', '${requestInfo.percent}%'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
