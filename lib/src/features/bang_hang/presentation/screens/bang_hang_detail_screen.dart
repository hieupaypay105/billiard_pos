import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BangHangDetailScreen extends StatelessWidget {
  const BangHangDetailScreen({
    required this.item,
    super.key,
  });

  final BangHangItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBgStart,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        featureTitle: 'CHI TIẾT',
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  child: Column(
                    children: [
                      _FlatDetailField(
                        label: 'Phân khu',
                        value: item.area,
                      ),
                      const _Separator(),
                      _FlatDetailField(
                        label: 'Loại hình',
                        value: item.type,
                      ),
                      const _Separator(),
                      _FlatDetailField(
                        label: 'Giá full',
                        value: '${item.price} tỷ',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  child: Column(
                    children: [
                      _FlatDualDetailField(
                        leftLabel: 'Mã căn',
                        leftValue: item.code,
                        rightLabel: 'TCBG',
                        rightValue: item.handoverStatus,
                      ),
                      const _Separator(),
                      _FlatDualDetailField(
                        leftLabel: 'Hướng',
                        leftValue: item.direction,
                        rightLabel: 'DT đất',
                        rightValue: '${item.acreage} m²',
                      ),
                      const _Separator(),
                      _FlatDualDetailField(
                        leftLabel: 'DT xây dựng',
                        leftValue: '${item.constructionArea} m²',
                        rightLabel: 'Vay',
                        rightValue: '${item.loan} tỷ',
                      ),
                      const _Separator(),
                      _FlatDualDetailField(
                        leftLabel: 'TTS',
                        leftValue: '${item.tts} tỷ',
                        rightLabel: 'Thủ tục ký',
                        rightValue: item.proceduresSign,
                      ),
                      const _Separator(),
                      _FlatDualDetailField(
                        leftLabel: 'Giỏ bank',
                        leftValue: item.bankBasket,
                        rightLabel: 'Quà tặng',
                        rightValue: item.gift,
                      ),
                      const _Separator(),
                      _FlatDualDetailField(
                        leftLabel: 'Tình trạng cọc',
                        leftValue: item.depositStatus,
                        rightLabel: 'Ngày import',
                        rightValue: item.createdAt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.dashboardCardStart, // fallback
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dashboardCardBorder,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: child,
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        width: double.infinity,
        color: AppColors.dashboardCardBorder,
      ),
    );
  }
}

class _FlatDualDetailField extends StatelessWidget {
  const _FlatDualDetailField({
    required this.leftLabel,
    required this.rightLabel,
    this.leftValue,
    this.rightValue,
  });

  final String leftLabel;
  final String? leftValue;
  final String rightLabel;
  final String? rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _BuildColumn(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BuildColumn(label: rightLabel, value: rightValue),
        ),
      ],
    );
  }
}

class _BuildColumn extends StatelessWidget {
  const _BuildColumn({required this.label, this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.authLabel.copyWith(
            color: AppColors.searchLabel,
            fontWeight: FontWeight.w400,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value?.trim() ?? '-',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            color: AppColors.authButtonText,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _FlatDetailField extends StatelessWidget {
  const _FlatDetailField({
    required this.label,
    this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${label.toUpperCase()}:',
          style: AppTextStyles.authLabel.copyWith(
            color: AppColors.authTextSecondary.withOpacity(0.5),
            fontWeight: FontWeight.w400,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value?.trim() ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.authButtonText,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
