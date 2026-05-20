import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/utils/format_utils.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:flutter/material.dart';

class BangHangCard extends StatelessWidget {
  const BangHangCard({
    required this.item,
    super.key,
    this.onTap,
  });

  final BangHangItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.dashboardCardStart,
              AppColors.dashboardCardEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dashboardCardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000), // 5% black
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Code and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${item.area} ',
                          style: AppTextStyles.dashboardCardValue.copyWith(
                            color: AppColors.authButtonText,
                          ),
                        ),
                        TextSpan(
                          text: '• ',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.authButtonText,
                          ),
                        ),
                        TextSpan(
                          text: item.code,
                          style: AppTextStyles.dashboardCardValue.copyWith(
                            color: AppColors.authButtonText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: FormatUtils.formatPriceString(item.price),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.statusGreen,
                        ),
                      ),
                      const TextSpan(
                        text: ' tỷ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          color: AppColors.statusGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: DT đất & DTXD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'DT đất: ${FormatUtils.formatPriceString(item.landSize)}m2',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DTXD: ${FormatUtils.formatPriceString(item.constructionArea)}m2',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Row 3: Thủ tục ký & Quỹ ĐT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Thủ tục ký: ${item.proceduresSign}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Quỹ ĐT: ${item.investmentFund ?? ''}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 4: Badge & Direction
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.type,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.direction,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Divider Bottom Row
            const Divider(color: AppColors.dashboardCardBorder, height: 1),
            const SizedBox(height: 8),

            // Row 5: Date (or Handover) & Bank
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.handoverStatus.isNotEmpty
                          ? item.handoverStatus
                          : 'TCBG',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Giỏ bank: ${item.bankBasket}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
