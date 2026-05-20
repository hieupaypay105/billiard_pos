import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CongTacVienCard extends StatelessWidget {
  const CongTacVienCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final CongTacVienItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = item.status == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 21, right: 21, top: 21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dashboardCardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // 5% black
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0606, 0.9648],
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name & Status ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.fullname.toUpperCase(),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.authButtonText,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.statusGreen
                      : const Color(0xFFDBDBDB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.statusLabel.toUpperCase(),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    color: isActive ? Colors.white : const Color(0xFF363636),
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Details ──
          _buildDetailRow('Sale quản lý', item.saleName),
          _buildDetailRow('Email', item.email),
          _buildDetailRow('Điện thoại', item.mobile),
          const SizedBox(height: 16),

          // ── Footer: Date & Actions ──
          Container(
            padding: const EdgeInsets.only(top: 7, bottom: 6),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.authInputBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.calendar,
                      width: 12,
                      height: 13,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.createdAt.isEmpty ? 'N/A' : item.createdAt,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          AppIcons.edit,
                          width: 15,
                          height: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          AppIcons.delete,
                          width: 13,
                          height: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Text(
      '$label: ${value.isEmpty ? 'N/A' : value}',
      style: AppTextStyles.body.copyWith(
        fontSize: 12,
        color: AppColors.textHint,
        height: 1.5,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
