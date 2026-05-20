import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KhachHangDetailScreen extends StatelessWidget {
  const KhachHangDetailScreen({
    required this.item,
    super.key,
  });

  final KhachHangItem item;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        featureTitle: 'CHI TIẾT',
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.khachHang);
          }
        },
        onNotificationTap: () async {
          await context.push(RoutePaths.notification);
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
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: bottomSafe + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Card (Avatar + Name + Status) ────────
                _buildHeroCard(),
                const SizedBox(height: 12),

                // ── Section 1: Thông tin cơ bản ───────────────
                _buildSectionInfo1(),
                const SizedBox(height: 12),

                // ── Section 2: Thông tin kinh doanh ──────────
                _buildSectionInfo2(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
          transform: GradientRotation(120.747 * 3.1415927 / 180),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardCardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkBackground2,
              border: Border.all(
                color: AppColors.primaryGold.withAlpha(102),
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 16),

          // Name + Badge + Financial
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    letterSpacing: 1,
                    color: AppColors.authButtonText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Status badge
                if (item.statusLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.buttonBorder),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.authButtonText,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.statusLabel.first.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                              letterSpacing: 1,
                              color: AppColors.authButtonText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                if ((item.financialRangeLabel ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tài chính: ${item.financialRangeLabel}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      letterSpacing: 1,
                      color: AppColors.authButtonText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionInfo1() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
          transform: GradientRotation(124.9 * 3.1415927 / 180),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardCardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FlatDetailRow(label: 'Họ và tên:', value: item.name),
          _divider(),
          _FlatDetailRow(label: 'Số điện thoại:', value: item.phone),
          _divider(),
          _FlatDetailRow(label: 'Email:', value: item.email),
          _divider(),
          _FlatDetailRow(label: 'Tỉnh/Thành phố:', value: item.regionLabel),
        ],
      ),
    );
  }

  Widget _buildSectionInfo2() {
    final saleNames = item.saleId.isNotEmpty ? item.saleId.join(', ') : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
          transform: GradientRotation(99.18 * 3.1415927 / 180),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardCardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineTwoColGridBlock(
            items: [
              MapEntry(
                MapEntry('DỰ ÁN:', item.projectLabel),
                MapEntry('PHÂN KHU:', item.area),
              ),
              MapEntry(
                MapEntry('LOẠI HÌNH:', item.type),
                MapEntry('KHOẢNG TC:', item.financialRangeLabel),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _divider(),
          _FullWidthRow(
            label: 'SALE PHỤ TRÁCH',
            value: saleNames,
          ),
          _divider(),
          _StatusBadgeRow(
            label: 'TÌNH TRẠNG',
            statuses: item.statusLabel,
            statusValues: item.status
                .split(',')
                .map((status) => status.trim())
                .where((status) => status.isNotEmpty)
                .toList(growable: false),
          ),
          _divider(),
          const SizedBox(height: 16),
          _InlineTwoColGridBlock(
            items: [
              MapEntry(
                MapEntry('LỊCH TT:', item.lastContact),
                MapEntry('NGUỒN:', item.sourceLabel),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NoteField(value: item.note),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: AppColors.authTextDisabled.withAlpha(51),
    );
  }
}

// ── Private Widgets ───────────────────────────────────────────────────────────

class _FlatDetailRow extends StatelessWidget {
  const _FlatDetailRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: '${label.toUpperCase()} ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 10,
            color: AppColors.authTextDisabled,
            letterSpacing: 1,
          ),
          children: [
            TextSpan(
              text: value?.trim() ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.authButtonText,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineTwoColGridBlock extends StatelessWidget {
  const _InlineTwoColGridBlock({
    required this.items,
  });

  /// List of pairs: MapEntry(MapEntry(leftLabel, leftValue), MapEntry(rightLabel, rightValue))
  final List<MapEntry<MapEntry<String, String?>, MapEntry<String, String?>>>
  items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (e) => _buildCell(e.key.key, e.key.value, isLeft: true),
                    )
                    .toList(),
              ),
            ),
            Container(
              width: 1,
              color: AppColors.authTextDisabled.withAlpha(51),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (e) =>
                          _buildCell(e.value.key, e.value.value, isLeft: false),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String label, String? value, {required bool isLeft}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: '${label.toUpperCase()} ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 10,
            color: AppColors.authTextDisabled,
            letterSpacing: 1,
          ),
          children: [
            TextSpan(
              text: (value?.trim().isNotEmpty ?? false) ? value!.trim() : ' ',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppColors.authButtonText,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullWidthRow extends StatelessWidget {
  const _FullWidthRow({
    required this.label,
    this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.authTextDisabled,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value?.trim().isNotEmpty ?? false ? value!.trim() : ' ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: AppColors.authButtonText,
            ),
            // maxLines: 2,
            // overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeRow extends StatelessWidget {
  const _StatusBadgeRow({
    required this.label,
    required this.statuses,
    this.statusValues = const [],
  });

  final String label;
  final List<String> statuses;
  final List<String> statusValues;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.authTextDisabled,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (statuses.isEmpty)
            const Text(
              ' ',
              style: TextStyle(fontSize: 16),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(statuses.length, (index) {
                final status = statuses[index];
                final color = _getStatusColor(
                  index < statusValues.length ? statusValues[index] : '',
                );

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      color: Colors.white,
                      letterSpacing: 0.45,
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String statusStr) {
    final idx = int.tryParse(statusStr.trim());
    if (idx != null && idx >= 0 && idx < AppColors.khStatusColors.length) {
      return AppColors.khStatusColors[idx];
    }
    return Colors.grey;
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GHI CHÚ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 10,
            letterSpacing: 1,
            color: AppColors.authTextDisabled,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 132,
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x33FAF2EF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value?.trim() ?? '',
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: AppColors.authButtonText,
            ),
          ),
        ),
      ],
    );
  }
}
