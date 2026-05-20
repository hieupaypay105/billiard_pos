import 'dart:async';

import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_column_def.dart';
import 'package:anholding_app/src/core/widgets/an_data_table.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/ai/presentation/provider/ai_provider.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _queryController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // Load quota when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AiProvider>().loadQuota();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    unawaited(context.read<AiProvider>().search(query));
  }

  void _onClear() {
    _queryController.clear();
    context.read<AiProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AnFeatureAppBar(
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.dashboard);
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
          child: Consumer<AiProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  80 + bottomSafeInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Title ─────────────────────────────────────
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFDBB0),
                          Color(0xFF9C531B),
                          Color(0xFFFFDBB0),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'TRỢ LÝ AI',
                        style: AppTextStyles.authScreenTitle.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.75,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      width: 64,
                      color: const Color(0xFF665D58),
                    ),
                    const SizedBox(height: 24),

                    // ── Quota Info ────────────────────────────────
                    _buildQuotaSection(provider),
                    const SizedBox(height: 16),

                    // ── Search Input ─────────────────────────────
                    _buildSearchInput(),
                    const SizedBox(height: 12),

                    // ── Action Buttons ────────────────────────────
                    _buildActionButtons(provider),
                    const SizedBox(height: 16),

                    // ── Results ───────────────────────────────────
                    Expanded(
                      child: _buildResultsSection(provider),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Quota Section ────────────────────────────────────────────

  Widget _buildQuotaSection(AiProvider provider) {
    final quotaRequestInfo = provider.quotaRequestInfo;

    final dailyUsed = quotaRequestInfo != null
        ? int.tryParse(quotaRequestInfo.used) ?? 0
        : 0;
    final dailyQuota = quotaRequestInfo?.quota ?? 50;

    final requestsThisMonth = quotaRequestInfo?.monthRequests ?? '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF454545),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: Color(0xFFFFD700)),
              const SizedBox(width: 6),
              Text(
                'Hôm nay: ',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.authTextSecondary,
                ),
              ),
              Text(
                '$dailyUsed / $dailyQuota',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authButtonText,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Tháng: ',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.authTextSecondary,
                ),
              ),
              Text(
                '$requestsThisMonth requests',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Search Input ─────────────────────────────────────────────

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.searchBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FormBuilderTextField(
        name: 'ai_query',
        controller: _queryController,
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: AppColors.authTextLight,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập yêu cầu tìm kiếm (VD: Shophouse San Hô...)',
          hintStyle: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.authTextSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
        onSubmitted: (_) => _onSearch(),
      ),
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────

  Widget _buildActionButtons(AiProvider provider) {
    return Row(
      children: [
        // ── TÌM button ──
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.buttonGradientStart,
                  AppColors.buttonGradientEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.buttonGradientStart,
                    AppColors.buttonGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppColors.buttonBorder,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: provider.isSearching ? null : _onSearch,
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (provider.isSearching)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.authButtonText,
                            ),
                          )
                        else
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: AppColors.authButtonText,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          'TÌM',
                          style: AppTextStyles.authButtonLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ── XOÁ button ──
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF454545),
                width: 0.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onClear,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_fix_high,
                        size: 18,
                        color: AppColors.authTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'XOÁ',
                        style: AppTextStyles.authButtonLabel.copyWith(
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Results Section ──────────────────────────────────────────

  Widget _buildResultsSection(AiProvider provider) {
    if (provider.isSearching) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        child: AnDataTableSkeleton<BangHangItem>(
          columns: _buildColumns(),
          rowHeight: 60,
          headerDecoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.dashboardCardStart,
                AppColors.dashboardCardEnd,
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          headerTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.authButtonText,
            letterSpacing: 1.1,
          ),
          rowDecorationBuilder: (index) => const BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Colors.white24, width: 0.5),
            ),
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Text(
            provider.error!,
            style: AppTextStyles.bodyWhite,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final result = provider.lastResult;
    if (result == null || result.items.isEmpty) {
      return Center(
        child: Text(
          result == null
              ? 'Nhập yêu cầu để tìm kiếm'
              : 'Không tìm thấy kết quả',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.authTextSecondary,
          ),
        ),
      );
    }

    final visibleCols = _buildColumns();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnDataTable<BangHangItem>(
        columns: visibleCols,
        items: result.items,
        onRowTap: (item, _) {
          unawaited(
            context.push(RoutePaths.bangHangDetail, extra: item),
          );
        },
        rowHeight: 60,
        headerDecoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.dashboardCardStart,
              AppColors.dashboardCardEnd,
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        headerTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.authButtonText,
          letterSpacing: 1.1,
        ),
        rowDecorationBuilder: (index) => const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white24, width: 0.5),
          ),
        ),
        cellTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }

  // ─── Column Definitions ───────────────────────────────────────

  List<AnColumnDef<BangHangItem>> _buildColumns() {
    return [
      AnColumnDef<BangHangItem>(
        key: 'stt',
        label: 'STT',
        width: 45,
        valueGetter: (item) => item.id,
        cellBuilder: (item, index) => Text(
          (index + 1).toString().padLeft(2, '0'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      AnColumnDef<BangHangItem>(
        key: 'project',
        label: 'DỰ ÁN',
        width: 95,
        valueGetter: (item) => item.project,
        cellBuilder: (item, index) => Text(
          item.project,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      AnColumnDef<BangHangItem>(
        key: 'code',
        label: 'MÃ CĂN',
        width: 75,
        valueGetter: (item) => item.code,
        cellBuilder: (item, index) => Text(
          item.code,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      AnColumnDef<BangHangItem>(
        key: 'area',
        label: 'PHÂN KHU',
        width: 85,
        valueGetter: (item) => item.area,
        cellBuilder: (item, index) => Text(
          item.area,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      AnColumnDef<BangHangItem>(
        key: 'price',
        label: 'GIÁ',
        width: 80,
        valueGetter: (item) => item.price,
        cellBuilder: (item, index) => Text(
          item.price,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      AnColumnDef<BangHangItem>(
        key: 'tts',
        label: 'TTS',
        width: 80,
        valueGetter: (item) => item.tts,
      ),
      AnColumnDef<BangHangItem>(
        key: 'type',
        label: 'LOẠI HÌNH',
        width: 100,
        valueGetter: (item) => item.type,
      ),
      AnColumnDef<BangHangItem>(
        key: 'acreage',
        label: 'DIỆN TÍCH',
        width: 80,
        valueGetter: (item) => item.acreage,
      ),
      AnColumnDef<BangHangItem>(
        key: 'direction',
        label: 'HƯỚNG',
        width: 90,
        valueGetter: (item) => item.direction,
      ),
      AnColumnDef<BangHangItem>(
        key: 'status',
        label: 'TRẠNG THÁI',
        width: 100,
        valueGetter: (item) => item.status,
      ),
    ];
  }
}
