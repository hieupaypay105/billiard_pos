import 'dart:async' show unawaited;

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_column_def.dart';
import 'package:anholding_app/src/core/widgets/an_data_table.dart';
import 'package:anholding_app/src/core/widgets/an_gradient_border.dart';
import 'package:anholding_app/src/core/widgets/an_zoomable_table_card.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/provider/ai_assistant_provider.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AiTableTab extends StatefulWidget {
  const AiTableTab({super.key});

  @override
  State<AiTableTab> createState() => _AiTableTabState();
}

class _AiTableTabState extends State<AiTableTab> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _highlightedItemCode;

  @override
  Widget build(BuildContext context) {
    return Consumer<AiAssistantProvider>(
      builder: (context, provider, child) {
        final bangHangItems = provider.tableItems ?? [];
        final isSearching = provider.isSearchingTable;
        final error = provider.tableError;
        final info = provider.quotaRequestInfo;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequestsProgress(info),
              const SizedBox(height: 16),
              _buildUsageStatsRow(info),
              const SizedBox(height: 24),
              _buildSearchBox(),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    Expanded(
                      child: _buildTableSection(
                        items: bangHangItems,
                        isSearching: isSearching,
                        error: error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsProgress(AiQuotaRequestInfo? info) {
    final used = info?.used ?? '0';
    final quota = info?.quota ?? 0;
    final percent = info?.percent ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              AppIcons.thunder,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Requests hôm nay',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF909090),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.75,
              ),
            ),
            const Spacer(),
            Text(
              '$used /$quota',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.75,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 6,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: percent / 100,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        // const SizedBox(height: 8),
        // Text(
        //   'Tháng: $monthRequests requests',
        //   style: AppTextStyles.body.copyWith(
        //     color: const Color(0xFF909090),
        //     fontSize: 12,
        //     fontWeight: FontWeight.w400,
        //     letterSpacing: -0.75,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildUsageStatsRow(AiQuotaRequestInfo? info) {
    final monthRequests = info?.monthRequests ?? '0';
    final cost = info?.cost ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF242426),
            Color(0xFF3B3537),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3F3F3F)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStat('Requests tháng', monthRequests),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactStat('Phí tháng', '$costđ'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          AppIcons.thunderSolid,
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: '$label: ',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF909090),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.75,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.75,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return FormBuilder(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FormBuilderTextField(
                name: 'searchQuery',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.authTextLight,
                ),
                onSubmitted: (value) {
                  _formKey.currentState?.save();
                  final query =
                      _formKey.currentState?.fields['searchQuery']?.value
                          as String?;
                  if (query != null && query.trim().isNotEmpty) {
                    unawaited(
                      context.read<AiAssistantProvider>().searchTable(query),
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Nhập yêu cầu tìm kiếm ...',
                  hintStyle: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.authTextSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.authTextSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _formKey.currentState?.fields['searchQuery']?.didChange(
                        '',
                      );
                      context.read<AiAssistantProvider>().clearTableSearch();
                    },
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 16,
                    right: 8,
                    top: 12,
                    bottom: 12,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnGradientBorder(
            width: 44,
            height: 44,
            backgroundColor: AppColors.buttonBgDark,
            child: InkWell(
              onTap: () {
                _formKey.currentState?.save();
                final query =
                    _formKey.currentState?.fields['searchQuery']?.value
                        as String?;
                if (query != null && query.trim().isNotEmpty) {
                  unawaited(
                    context.read<AiAssistantProvider>().searchTable(query),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: SvgPicture.asset(
                  AppIcons.aiSearch,
                  width: 26,
                  height: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<BangHangItem> items) {
    return AnZoomableTableCard(
      borderRadius: BorderRadius.circular(16),
      child: AnDataTable<BangHangItem>(
        columns: _allColumnDefs(),
        items: items,
        listPadding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 120,
        ),
        onRowTap: _handleRowTap,
        headerHeight: 30,
        rowHeight: 34,
        headerCellPadding: const EdgeInsets.symmetric(horizontal: 6),
        cellPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        actionsColumnWidth: 28,
        actionsLabel: '',
        actionsBuilder: (item, index) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openDetail(item),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
        headerDecoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.tableCardBorder,
              width: 0.7,
            ),
          ),
        ),
        headerTextStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.authButtonText,
          letterSpacing: 1.1,
        ),
        rowDecorationBuilder: (index) {
          final isLast = index == items.length - 1;
          final item = items[index];
          final isHighlighted = item.code == _highlightedItemCode;

          return BoxDecoration(
            color: isHighlighted
                ? AppColors.primaryGold.withAlpha(65)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isHighlighted
                    ? AppColors.primaryGold
                    : AppColors.tableCardBorder,
                width: isLast ? 0.0 : 0.45,
              ),
            ),
          );
        },
        cellTextStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTableSection({
    required List<BangHangItem> items,
    required bool isSearching,
    required String? error,
  }) {
    if (isSearching && items.isEmpty) {
      return _buildTableSkeletonCard();
    }

    if (error != null && items.isEmpty) {
      return _buildFeedbackCard(
        error,
        textStyle: AppTextStyles.bodyWhite,
      );
    }

    if (items.isEmpty) {
      return _buildFeedbackCard(
        'Chưa tìm thấy dữ liệu, vui lòng nhập yêu cầu tìm kiếm.',
        textStyle: AppTextStyles.body.copyWith(
          color: AppColors.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: _buildDataTable(items)),
        if (isSearching)
          Positioned.fill(
            child: IgnorePointer(
              child: _buildTableSkeletonCard(),
            ),
          ),
      ],
    );
  }

  Widget _buildTableSkeletonCard() {
    return AnZoomableTableCard(
      enableZoom: false,
      borderRadius: BorderRadius.circular(16),
      child: AnDataTableSkeleton<BangHangItem>(
        columns: _allColumnDefs(),
        headerHeight: 30,
        rowHeight: 34,
        headerCellPadding: const EdgeInsets.symmetric(horizontal: 6),
        cellPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        headerDecoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.tableCardBorder,
              width: 0.7,
            ),
          ),
        ),
        headerTextStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.authButtonText,
          letterSpacing: 1.1,
        ),
        rowDecorationBuilder: (index) => const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.tableCardBorder,
              width: 0.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
    String message, {
    required TextStyle textStyle,
  }) {
    return AnZoomableTableCard(
      enableZoom: false,
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
      ),
    );
  }

  void _handleRowTap(BangHangItem item, int index) {
    setState(() {
      _highlightedItemCode = item.code;
    });
    _openDetail(item);
  }

  void _openDetail(BangHangItem item) {
    unawaited(
      context.push(RoutePaths.bangHangDetail, extra: item),
    );
  }

  List<AnColumnDef<BangHangItem>> _allColumnDefs() {
    return [
      // ── STT (index, not a real field) ─────────────────────
      AnColumnDef<BangHangItem>(
        key: 'id',
        label: 'STT',
        width: 46,
        valueGetter: (item) => item.id,
        cellBuilder: (item, index) => Text(
          (index + 1).toString().padLeft(2, '0'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      // ── Tên dự án ─────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'project',
        label: 'TÊN DỰ ÁN',
        width: 110,
        valueGetter: (item) => item.project,
        cellBuilder: (item, index) => Text(
          item.project,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      // ── Phân khu (badge) ──────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'area',
        label: 'PHÂN KHU',
        width: 88,
        valueGetter: (item) => item.area,
        cellBuilder: (item, index) => Container(
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.badgeBlue,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            item.area,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
      // ── Mã căn ────────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'code',
        label: 'MÃ CĂN',
        width: 78,
        valueGetter: (item) => item.code,
      ),
      // ── Loại hình ─────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'type',
        label: 'LOẠI HÌNH',
        width: 92,
        valueGetter: (item) => item.type,
      ),
      // ── TCBG ──────────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'handoverStatus',
        label: 'TCBG',
        width: 64,
        valueGetter: (item) => item.handoverStatus,
      ),
      // ── Hướng ─────────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'direction',
        label: 'HƯỚNG',
        width: 70,
        valueGetter: (item) => item.direction,
      ),
      // ── KT đất ────────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'landSize',
        label: 'KT ĐẤT',
        width: 74,
        valueGetter: (item) => item.landSize ?? '',
      ),
      // ── DTXD ──────────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'constructionArea',
        label: 'DTXD',
        width: 60,
        valueGetter: (item) => item.constructionArea,
      ),
      // ── Giá full (bold, right) ────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'price',
        label: 'GIÁ FULL',
        width: 108,
        valueGetter: (item) => item.price,
        cellBuilder: (item, index) => Text(
          item.price,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      // ── TTS ───────────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'tts',
        label: 'TTS',
        width: 62,
        valueGetter: (item) => item.tts,
      ),
      // ── Thủ tục ký ────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'proceduresSign',
        label: 'THỦ TỤC KÝ',
        width: 92,
        valueGetter: (item) => item.proceduresSign,
      ),
      // ── Quỹ ĐT ────────────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'investmentFund',
        label: 'QUỸ ĐT',
        width: 86,
        valueGetter: (item) => item.investmentFund ?? '',
      ),
      // ── Giỏ bank F1 ───────────────────────────────────────
      AnColumnDef<BangHangItem>(
        key: 'bankBasket',
        label: 'GIỎ BANK F1',
        width: 92,
        valueGetter: (item) => item.bankBasket,
      ),
    ];
  }
}
