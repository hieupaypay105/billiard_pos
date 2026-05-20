import 'dart:async';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_column_def.dart';
import 'package:anholding_app/src/core/widgets/an_data_table.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/core/widgets/an_zoomable_table_card.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/provider/bang_hang_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BangHangScreen extends StatefulWidget {
  const BangHangScreen({super.key});

  @override
  State<BangHangScreen> createState() => _BangHangScreenState();
}

class _BangHangScreenState extends State<BangHangScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  BangHangProvider? _provider;
  String _lastProviderCode = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<BangHangProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_syncSearchField);
      _provider = provider;
      _lastProviderCode = provider.filter.code ?? '';
      _searchController.text = _lastProviderCode;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
      _provider?.addListener(_syncSearchField);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_syncSearchField);
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _syncSearchField() {
    final nextCode = _provider?.filter.code ?? '';
    if (nextCode == _lastProviderCode) return;
    _lastProviderCode = nextCode;
    if (_searchController.text == nextCode) return;
    _searchController.value = _searchController.value.copyWith(
      text: nextCode,
      selection: TextSelection.collapsed(offset: nextCode.length),
      composing: TextRange.empty,
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final provider = context.read<BangHangProvider>();
      final normalizedCode = value.trim();
      final currentCode = provider.filter.code ?? '';
      if (normalizedCode == currentCode) return;
      _lastProviderCode = normalizedCode;
      unawaited(
        provider.applyFilter(
          provider.filter.copyWith(
            code: normalizedCode.isEmpty ? null : normalizedCode,
          ),
        ),
      );
    });
  }

  Future<void> _onScroll() async {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      await context.read<BangHangProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AnFeatureAppBar(
        featureTitle: 'BẢNG HÀNG',
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
          bottom: false,
          child: Consumer2<BangHangProvider, UserProvider>(
            builder: (context, provider, userProvider, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Toolbar ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.searchBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FormBuilderTextField(
                                name: 'code',
                                controller: _searchController,
                                onChanged: (value) =>
                                    _onSearchChanged(value ?? ''),
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 16,
                                  color: AppColors.authTextLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm mã căn',
                                  hintStyle: AppTextStyles.body.copyWith(
                                    fontSize: 16,
                                    color: AppColors.authTextSecondary,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _openFilterSheet(context, provider),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.searchBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.bangHangSearch,
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _openColumnSettings(context, provider),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.searchBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.bangHangFilter,
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Tabs ────────────────────────────────────
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: BangHangProvider.tabs.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final tab = BangHangProvider.tabs[index];
                          final isSelected = provider.selectedTabIndex == index;
                          return GestureDetector(
                            onTap: () => unawaited(provider.setTab(index)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.filterBg
                                    : const Color(0x802D2B47),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.authButtonBorder
                                      : Colors.transparent,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                tab.label.toUpperCase(),
                                style: AppTextStyles.buttonLabel.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.authButtonText,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── List ─────────────────────────────────────
                    Expanded(
                      child: _buildListContent(
                        context,
                        provider,
                        bottomSafeInset,
                      ),
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

  Widget _buildListContent(
    BuildContext context,
    BangHangProvider provider,
    double bottomSafeInset,
  ) {
    final visibleCols = _buildVisibleColumns(provider);

    Widget content;

    if (provider.isLoading) {
      content = _buildTableSkeletonCard(visibleCols);
    } else if (provider.errorMessage != null) {
      content = Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Text(
            provider.errorMessage!,
            style: AppTextStyles.bodyWhite,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (provider.items.isEmpty) {
      content = AnZoomableTableCard(
        enableZoom: false,
        borderRadius: BorderRadius.circular(16),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Không có dữ liệu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    } else {
      content = Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnZoomableTableCard(
                  borderRadius: BorderRadius.circular(16),
                  child: AnDataTable<BangHangItem>(
                    columns: visibleCols,
                    items: provider.items,
                    scrollController: _scrollController,
                    listPadding: EdgeInsets.only(bottom: bottomSafeInset + 120),
                    onRowTap: (item, _) {
                      provider.setHighlightedItemCode(item.code);
                    },
                    headerHeight: 30,
                    rowHeight: 34,
                    headerCellPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                    ),
                    cellPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    actionsColumnWidth: 28,
                    actionsLabel: '',
                    actionsBuilder: (item, index) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        unawaited(
                          context.push(RoutePaths.bangHangDetail, extra: item),
                        );
                      },
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
                    onSort: provider.sort,
                    sortColumnKey: provider.sortColumnKey,
                    sortAscending: provider.sortAscending,
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
                      final isLast = index == provider.items.length - 1;
                      final item = provider.items[index];
                      final isHighlighted =
                          item.code == provider.highlightedItemCode;

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
                ),
                if (provider.isLoadingMore)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _buildTableSkeletonCard(visibleCols),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // Wrapper to handle refresh. We expand the table to the very bottom, creating the bleed effect.
    // The internal listPadding handles clearing the bottom bar.
    return RefreshIndicator(
      onRefresh: () async {
        await provider.refresh();
      },
      color: AppColors.primaryGold,
      backgroundColor: AppColors.dashboardBgStart,
      child: content,
    );
  }

  Widget _buildTableSkeletonCard(List<AnColumnDef<BangHangItem>> visibleCols) {
    return AnZoomableTableCard(
      enableZoom: false,
      borderRadius: BorderRadius.circular(16),
      child: AnDataTableSkeleton<BangHangItem>(
        columns: visibleCols,
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

  /// Returns only the columns that are currently visible per provider config.
  List<AnColumnDef<BangHangItem>> _buildVisibleColumns(
    BangHangProvider provider,
  ) {
    final allDefs = _allColumnDefs(provider.items);
    final defMap = {for (final def in allDefs) def.key: def};
    
    final result = <AnColumnDef<BangHangItem>>[];
    for (final key in provider.columnOrder) {
      if (provider.isColumnVisible(key) && defMap.containsKey(key)) {
        final def = defMap[key]!;
        result.add(def.copyWith(label: provider.columnLabels[key] ?? def.label));
      }
    }
    return result;
  }

  final Map<String, double> _textWidthCache = {};

  double _getTextWidth(String text, TextStyle style) {
    final key = '${text}_${style.fontSize}_${style.fontWeight}';
    if (_textWidthCache.containsKey(key)) return _textWidthCache[key]!;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final width = textPainter.size.width.ceilToDouble();
    _textWidthCache[key] = width;
    return width;
  }

  double _detectWidth({
    required String header,
    required Iterable<String> values,
    double extraPadding = 0,
    double iconPadding = 0,
    double minWidth = 36.0,
    double maxWidth = 300.0,
    TextStyle? customCellStyle,
  }) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      fontFamily: 'Inter',
    );
    const baseCellStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.normal,
      fontFamily: 'Inter',
    );

    var maxW = _getTextWidth(header, headerStyle) + extraPadding + iconPadding;

    final styleToUse = customCellStyle ?? baseCellStyle;

    for (final val in values) {
      final w = _getTextWidth(val, styleToUse) + extraPadding;
      if (w > maxW) maxW = w;
    }

    maxW += 12.0;

    return maxW.clamp(minWidth, maxWidth);
  }

  /// Full column definitions matching [BangHangProvider.columnOrder].
  List<AnColumnDef<BangHangItem>> _allColumnDefs(List<BangHangItem> items) {
    final getters = <String, String Function(BangHangItem)>{
      'id': (e) => e.id,
      'project': (e) => e.project,
      'area': (e) => e.area,
      'code': (e) => e.code,
      'type': (e) => e.type,
      'handover_status': (e) => e.handoverStatus,
      'direction': (e) => e.direction,
      'land_size': (e) => e.landSize ?? '',
      'acreage': (e) => e.acreage,
      'construction_area': (e) => e.constructionArea,
      'price': (e) => e.price,
      'tts': (e) => e.tts,
      'procedures_sign': (e) => e.proceduresSign,
      'investment_fund': (e) => e.investmentFund ?? '',
      'bank_basket': (e) => e.bankBasket,
      'status': (e) => e.status,
      'agent': (e) => e.agent,
      'loan': (e) => e.loan,
      'note': (e) => e.note ?? '',
      'contract_price': (e) => e.contractPrice ?? '',
      'fee': (e) => e.fee ?? '',
      'unit_price': (e) => e.unitPrice ?? '',
      'telesale': (e) => e.telesale ?? '',
      'cutting_ratio': (e) => e.cuttingRatio ?? '',
      'host_name': (e) => e.hostName ?? '',
      'phone': (e) => e.phone ?? '',
      'created_at': (e) => e.createdAt ?? '',
      'sale_id': (e) => e.saleId ?? '',
      'ptg_link': (e) => e.ptgLink ?? '',
      'point_link': (e) => e.pointLink ?? '',
      'warranty_policy': (e) => e.warrantyPolicy ?? '',
      'gift': (e) => e.gift ?? '',
      'deposit_status': (e) => e.depositStatus ?? '',
      'update_day': (e) => e.updateDay ?? '',
      'is_selled': (e) => e.isSelled ?? '',
      'tttd': (e) => e.tttd ?? '',
      'sale_bonus': (e) => e.saleBonus ?? '',
    };

    final labels = <String, String>{
      'id': 'STT',
      'project': 'DỰ ÁN',
      'area': 'PHÂN KHU',
      'code': 'MÃ CĂN',
      'type': 'LOẠI HÌNH',
      'handover_status': 'TCBG',
      'direction': 'HƯỚNG',
      'land_size': 'KT ĐẤT',
      'acreage': 'DIỆN TÍCH',
      'construction_area': 'DTXD',
      'price': 'GIÁ FULL',
      'tts': 'TTS',
      'procedures_sign': 'THỦ TỤC KÝ',
      'investment_fund': 'QUỸ ĐT',
      'bank_basket': 'GIỎ BANK F1',
      'status': 'TRẠNG THÁI',
      'agent': 'ĐẠI LÝ',
      'loan': 'KHOẢN VAY',
      'note': 'GHI CHÚ',
      'contract_price': 'GIÁ HĐ',
      'fee': 'PHÍ',
      'unit_price': 'ĐƠN GIÁ',
      'telesale': 'TELESALE',
      'cutting_ratio': 'TỶ LỆ CẮT',
      'host_name': 'TÊN CHỦ NHÀ',
      'phone': 'SĐT',
      'created_at': 'NGÀY TẠO',
      'sale_id': 'SALE ID',
      'ptg_link': 'PTG LINK',
      'point_link': 'POINT LINK',
      'warranty_policy': 'CHÍNH SÁCH BẢO HÀNH',
      'gift': 'QUÀ TẶNG',
      'deposit_status': 'TRẠNG THÁI CỌC',
      'update_day': 'NGÀY CẬP NHẬT',
      'is_selled': 'ĐÃ BÁN',
      'tttd': 'TTTD',
      'sale_bonus': 'THƯỞNG SALE',
    };

    return getters.entries.map((entry) {
      final key = entry.key;
      final getter = entry.value;
      final defaultLabel = labels[key] ?? key.toUpperCase();

      final isId = key == 'id';
      final values = isId
          ? List.generate(
              items.isEmpty ? 1 : items.length,
              (i) => (i + 1).toString().padLeft(2, '0'),
            )
          : (key == 'ptg_link' ? const [''] : items.map((e) => getter(e)));

      TextStyle? customStyle;
      if (key == 'area') {
        customStyle = const TextStyle(fontSize: 10, fontWeight: FontWeight.w600);
      } else if (key == 'price') {
        customStyle = const TextStyle(fontSize: 10);
      }

      final width = _detectWidth(
        header: defaultLabel,
        values: values,
        customCellStyle: customStyle,
      );

      Widget Function(BangHangItem, int)? cellBuilder;
      if (isId) {
        cellBuilder = (item, index) => Text(
              (index + 1).toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 10),
            );
      } else if (key == 'area') {
        cellBuilder = (item, index) => Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.badgeBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                getter(item),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
      } else if (key == 'price') {
        cellBuilder = (item, index) => Text(
              getter(item),
              style: const TextStyle(fontSize: 10, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
      } else if (key == 'ptg_link') {
        cellBuilder = (item, index) {
          final link = getter(item);
          if (link.isEmpty) return const SizedBox();
          return GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(link);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Icon(
              Icons.language,
              size: 16,
              color: AppColors.primaryGold,
            ),
          );
        };
      }

      return AnColumnDef<BangHangItem>(
        key: key,
        label: defaultLabel,
        width: width,
        valueGetter: getter,
        cellBuilder: cellBuilder,
      );
    }).toList();
  }

  Future<void> _openColumnSettings(
    BuildContext context,
    BangHangProvider provider,
  ) async {
    await context.push(RoutePaths.bangHangColumnSettings);
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    BangHangProvider provider,
  ) async {
    final result = await context.push<BangHangFilter>(
      RoutePaths.bangHangFilter,
      extra: provider.filter,
    );
    if (result != null) {
      unawaited(provider.applyFilter(result));
    }
  }
}
