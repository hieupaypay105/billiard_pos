import 'dart:async';
import 'dart:convert';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/core/widgets/an_gradient_border.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class KhachHangFilterScreen extends StatefulWidget {
  const KhachHangFilterScreen({required this.initialFilter, super.key});

  final KhachHangFilter initialFilter;

  @override
  State<KhachHangFilterScreen> createState() => _KhachHangFilterScreenState();
}

class _KhachHangFilterScreenState extends State<KhachHangFilterScreen> {
  // ── UI state ──────────────────────────────────────────────
  bool _isFilterExpanded = true;
  bool _isSavedFilterExpanded = false;
  bool _isTimeExpanded = false;

  // ── Project tracking (for dependent filters) ───────────────
  int? _selectedProjectId;

  // ── Form State ──────────────────────────────────────────────
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialFilter.projectId.firstOrNull;

    // Load project-dependent options if project was pre-selected
    if (_selectedProjectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<KhachHangProvider>().setSelectedProject(
          _selectedProjectId!,
        );
      });
    }

    // Restore time filter selection from the active provider filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final createdAt = context.read<KhachHangProvider>().filter.createdAt;
      if (createdAt.isNotEmpty) {
        setState(() => _selectedTimeKeys.add(createdAt));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KhachHangProvider>();
    final options = provider.options;

    // ── Build int-keyed option maps ──────────────────────────
    final statusOptions = <int, String>{
      if (options != null)
        for (var i = 0; i < options.status.length; i++) i: options.status[i],
    };

    final sourceOptions = options?.source ?? const <int, String>{};
    final projectOptions = options?.project ?? const <int, String>{};
    final saleOptions = options?.sale ?? const <int, String>{};

    // ── Build string-keyed option maps ───────────────────────
    final financialRangeOptions =
        options?.financialRange ?? const <String, String>{};

    // Project-dependent options (area, type)
    final areaStrings = provider.getProjectOptions('area');
    final areaOptions = <String, String>{
      for (final e in areaStrings) e: e,
    };

    final typeStrings = provider.getProjectOptions('type');
    final typeOptions = <String, String>{
      for (final e in typeStrings) e: e,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        featureTitle: 'TÌM KIẾM',
        avatarUrl: context.read<UserProvider>().currentUser?.avatar ?? '',
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard'); // Fallback if can't pop
          }
        },
        showNotification: false,
        showFilter: false,
        showAdd: false,
        showSearch: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              // ── Filter Card ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    0,
                    10,
                    0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      // color: AppColors.cardBackgroundSolid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: FormBuilder(
                        key: _formKey,
                        child: Column(
                          children: [
                            // ─ 1. Search bar + Bộ lọc (expand) ──
                            _buildSearchBar(
                              saleOptions: saleOptions,
                              sourceOptions: sourceOptions,
                              projectOptions: projectOptions,
                              statusOptions: statusOptions,
                              financialRangeOptions: financialRangeOptions,
                              areaOptions: areaOptions,
                              typeOptions: typeOptions,
                              provider: provider,
                            ),

                            // ─ 2. Bộ lọc đã lưu ────────────────
                            _buildSavedFilterDropdown(),

                            // ─ 3. Tất cả (time) ─────────────────
                            _buildTimeDropdown(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── XONG submit button ───────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.viewPaddingOf(context).bottom + 24,
                ),
                child: Center(
                  child: AnGradientBorder(
                    width: double.infinity,
                    backgroundColor: AppColors.buttonBgDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: InkWell(
                      onTap: _onDone,
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          'XONG',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.authButtonText,
                            letterSpacing: 2.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  1. SEARCH BAR + BỘ LỌC TOGGLE
  // ═══════════════════════════════════════════════════════════

  Widget _buildSearchBar({
    required Map<int, String> saleOptions,
    required Map<int, String> sourceOptions,
    required Map<int, String> projectOptions,
    required Map<int, String> statusOptions,
    required Map<String, String> financialRangeOptions,
    required Map<String, String> areaOptions,
    required Map<String, String> typeOptions,
    required KhachHangProvider provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TÌM KIẾM'.toUpperCase(),
                style: AppTextStyles.authLabel.copyWith(
                  color: AppColors.searchIconHint,
                ),
                textAlign: TextAlign.left,
              ),
              GestureDetector(
                onTap: () {
                  // Clear each form field to null
                  final fields = _formKey.currentState?.fields;
                  if (fields != null) {
                    for (final field in fields.values) {
                      field.didChange(null);
                    }
                  }
                  // Reset local state
                  setState(() {
                    _selectedProjectId = null;
                    _selectedTimeKeys.clear();
                  });
                  // Clear provider filter & reload
                  context.read<KhachHangProvider>().clearFilter();
                },
                child: Text(
                  'Xoá bộ lọc'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.authButtonText,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Search row ──────────────────────────────────
        Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _isFilterExpanded
                ? AppColors.filterDropdownActive
                : AppColors.inputFillLight,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: _isFilterExpanded
                  ? Radius.zero
                  : const Radius.circular(8),
              bottomRight: _isFilterExpanded
                  ? Radius.zero
                  : const Radius.circular(8),
            ),
            border: Border.all(
              color: _isFilterExpanded
                  ? Colors.transparent
                  : AppColors.inputBorderLight,
            ),
          ),
          child: Row(
            children: [
              // Search icon
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SvgPicture.asset(
                  AppIcons.khachHangSearch,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.authTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Search text / input
              Expanded(
                child: FormBuilderTextField(
                  name: 'keyword',
                  initialValue: widget.initialFilter.keyword,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tìm kiếm theo tên, SĐT',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.authTextSecondary,
                    ),
                    isDense: true,
                  ),
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                height: 42,
                color: _isFilterExpanded
                    ? Colors.transparent
                    : AppColors.inputBorderLight,
              ),

              // "Bộ lọc" toggle
              GestureDetector(
                onTap: () =>
                    setState(() => _isFilterExpanded = !_isFilterExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        AppIcons.khachHangFilterSharp,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          _isFilterExpanded
                              ? AppColors.authButtonText
                              : AppColors.authTextSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 16,
                          color: _isFilterExpanded
                              ? AppColors.authButtonText
                              : AppColors.authTextSecondary,
                          fontWeight: _isFilterExpanded
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Filter grid (expandable child) ──────────
        if (_isFilterExpanded) ...[
          _buildFilterGrid(
            saleOptions: saleOptions,
            sourceOptions: sourceOptions,
            projectOptions: projectOptions,
            statusOptions: statusOptions,
            financialRangeOptions: financialRangeOptions,
            areaOptions: areaOptions,
            typeOptions: typeOptions,
            provider: provider,
          ),
          _buildCreateFilterSection(),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. BỘ LỌC ĐÃ LƯU DROPDOWN
  // ═══════════════════════════════════════════════════════════

  Widget _buildSavedFilterDropdown() {
    final provider = context.watch<KhachHangProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'BỘ LỌC ĐÃ LƯU'.toUpperCase(),
              style: AppTextStyles.authLabel.copyWith(
                color: AppColors.searchIconHint,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(
            () => _isSavedFilterExpanded = !_isSavedFilterExpanded,
          ),
          child: Container(
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.filterDropdownActive,
              borderRadius: _isSavedFilterExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : BorderRadius.circular(8),
              border: Border.all(
                color: _isSavedFilterExpanded
                    ? Colors.transparent
                    : AppColors.inputBorderLight,
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  AppIcons.khachHangSave,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.authTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bộ lọc đã lưu',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isSavedFilterExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded: list of saved filters
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: AppColors.filterDropdownPanel,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Builder(
              builder: (context) {
                final savedFilters = provider.options?.filterSaved ?? [];

                if (savedFilters.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        'Chưa có bộ lọc nào',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: List.generate(savedFilters.length, (index) {
                    final item = savedFilters[index];
                    final isDefault = item.isDefault == '1';

                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(
                            height: 1,
                            color: AppColors.inputBorderLight,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final json =
                                        jsonDecode(item.data)
                                            as Map<String, dynamic>;
                                    final filter = KhachHangFilter.fromJson(
                                      json,
                                    );
                                    await provider.applyFilter(filter);
                                    if (!context.mounted) return;
                                    context.pop();
                                  },
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.authTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (!isDefault)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final success = await provider
                                        .setDefaultFilter(
                                          id: item.id,
                                          isDefault: 1,
                                        );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Cập nhật bộ lọc thành công'
                                              : (provider.submitError ??
                                                    'Cập nhật bộ lọc thất bại'),
                                        ),
                                        backgroundColor: success
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Set default',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF3F8CFE),
                                      fontStyle: FontStyle.italic,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF3F8CFE),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  final success = await provider.deleteFilter(
                                    id: item.id,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Xoá bộ lọc thành công'
                                            : (provider.submitError ??
                                                  'Xoá bộ lọc thất bại'),
                                      ),
                                      backgroundColor: success
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.authTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
          crossFadeState: _isSavedFilterExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  final Set<String> _selectedTimeKeys = {};

  Widget _buildTimeDropdown() {
    final provider = context.watch<KhachHangProvider>();
    final createdAtMap = provider.options?.createdAt ?? {};
    final keys = createdAtMap.keys.toList();

    // Build header label from selected items
    String headerLabel;
    if (_selectedTimeKeys.isEmpty) {
      headerLabel = 'Tất cả';
    } else {
      headerLabel = _selectedTimeKeys
          .map((k) => createdAtMap[k] ?? k)
          .join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TÌM KIẾM THEO THỜI GIAN'.toUpperCase(),
              style: AppTextStyles.authLabel.copyWith(
                color: AppColors.searchIconHint,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isTimeExpanded = !_isTimeExpanded),
          child: Container(
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.filterDropdownActive,
              borderRadius: _isTimeExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : BorderRadius.circular(8),
              border: Border.all(
                color: _isTimeExpanded
                    ? Colors.transparent
                    : AppColors.inputBorderLight,
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  AppIcons.khachHangClock,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.authTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headerLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.authTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _isTimeExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded: checkbox list
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: AppColors.filterDropdownPanel,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: List.generate(keys.length, (index) {
                final key = keys[index];
                final label = createdAtMap[key] ?? key;
                final isChecked = _selectedTimeKeys.contains(key);
                return InkWell(
                  onTap: () {
                    final newKey = isChecked ? '' : key;
                    setState(() {
                      // Radio behaviour: only one time range at a time
                      if (isChecked) {
                        _selectedTimeKeys.clear();
                      } else {
                        _selectedTimeKeys
                          ..clear()
                          ..add(key);
                      }
                    });
                    // Apply immediately — no need to press Áp dụng
                    unawaited(
                      provider.applyFilter(
                        provider.filter.copyWith(createdAt: newKey),
                      ),
                    );
                  },
                  child: Container(
                    color: isChecked
                        ? AppColors.filterDropdownChecked
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppColors.primaryGold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isChecked
                                  ? AppColors.primaryGold
                                  : AppColors.inputBorderLight,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.authTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          crossFadeState: _isTimeExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        // Bottom padding when no filter grid displayed
        if (!_isFilterExpanded) const SizedBox(height: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  4. FILTER GRID (4×2) + ÁP DỤNG BUTTON
  // ═══════════════════════════════════════════════════════════

  Widget _buildFilterGrid({
    required Map<int, String> saleOptions,
    required Map<int, String> sourceOptions,
    required Map<int, String> projectOptions,
    required Map<int, String> statusOptions,
    required Map<String, String> financialRangeOptions,
    required Map<String, String> areaOptions,
    required Map<String, String> typeOptions,
    required KhachHangProvider provider,
  }) {
    return Container(
      color: AppColors.filterDropdownPanel,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          _buildMultiSelect<int>(
            name: 'project_id',
            label: 'DỰ ÁN',
            initialValue: widget.initialFilter.projectId,
            options: projectOptions,
            onChanged: (values) {
              final v = values.isNotEmpty ? values.last : null;
              if (v != null) {
                setState(() => _selectedProjectId = v);
                provider.setSelectedProject(v);
              } else {
                setState(() => _selectedProjectId = null);
              }
              _formKey.currentState?.fields['area']?.didChange(<String>[]);
              _formKey.currentState?.fields['type']?.didChange(<String>[]);
            },
          ),
          const SizedBox(height: 12),
          _buildFilterColumn(
            label: 'PHÂN KHU',
            child: provider.isLoadingProjectOptions
                ? _buildLoadingPlaceholder()
                : _buildMultiSelectOnly<String>(
                    name: 'area',
                    initialValue: widget.initialFilter.area,
                    enabled: _selectedProjectId != null,
                    options: areaOptions,
                    hintText: _selectedProjectId == null
                        ? 'Vui lòng chọn dự án trước'
                        : 'Chọn phân khu',
                  ),
          ),
          const SizedBox(height: 12),
          _buildFilterColumn(
            label: 'LOẠI HÌNH',
            child: provider.isLoadingProjectOptions
                ? _buildLoadingPlaceholder()
                : _buildMultiSelectOnly<String>(
                    name: 'type',
                    initialValue: widget.initialFilter.type,
                    enabled: _selectedProjectId != null,
                    options: typeOptions,
                    hintText: _selectedProjectId == null
                        ? 'Vui lòng chọn dự án trước'
                        : 'Chọn loại hình',
                  ),
          ),
          const SizedBox(height: 12),
          _buildMultiSelect<int>(
            name: 'sale_id',
            label: 'SALE PHỤ TRÁCH',
            hintText: 'Chọn sale',
            initialValue: widget.initialFilter.saleId,
            options: saleOptions,
          ),
          const SizedBox(height: 12),
          _buildMultiSelect<String>(
            name: 'financial_range',
            label: 'KHOẢNG TÀI CHÍNH',
            hintText: 'Chọn tài chính',
            initialValue: widget.initialFilter.financialRange,
            options: financialRangeOptions,
          ),
          const SizedBox(height: 12),
          _buildMultiSelect<int>(
            name: 'source_id',
            label: 'NGUỒN',
            initialValue: widget.initialFilter.sourceId,
            options: sourceOptions,
          ),
          const SizedBox(height: 12),
          _buildMultiSelect<int>(
            name: 'status',
            label: 'TÌNH TRẠNG',
            initialValue: widget.initialFilter.status,
            options: statusOptions,
          ),
        ],
      ),
    );
  }

  /// Multi-select dropdown with label — opens bottom sheet with checkboxes.
  Widget _buildMultiSelect<T>({
    required String name,
    required String label,
    required List<T> initialValue,
    required Map<T, String> options,
    ValueChanged<List<T>>? onChanged,
    bool enabled = true,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.authLabel.copyWith(
            color: AppColors.searchLabel,
          ),
        ),
        const SizedBox(height: 4),
        _buildMultiSelectOnly<T>(
          name: name,
          initialValue: initialValue,
          options: options,
          onChanged: onChanged,
          enabled: enabled,
          hintText: hintText ?? 'Chọn ${label.toLowerCase()}',
        ),
      ],
    );
  }

  /// Multi-select without label — used inside _buildFilterColumn.
  Widget _buildMultiSelectOnly<T>({
    required String name,
    required List<T> initialValue,
    required Map<T, String> options,
    ValueChanged<List<T>>? onChanged,
    bool enabled = true,
    String hintText = 'Chọn',
  }) {
    return FormBuilderField<List<T>>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      builder: (field) {
        final selected = field.value ?? <T>[];
        final displayText = selected.isEmpty
            ? null
            : selected.map((k) => options[k] ?? k.toString()).join(', ');

        return GestureDetector(
          onTap: enabled
              ? () async {
                  final result = await _showMultiSelectSheet<T>(
                    title: hintText,
                    options: options,
                    selected: selected,
                  );
                  if (result != null) {
                    field.didChange(result);
                    onChanged?.call(result);
                  }
                }
              : null,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.inputFillLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText ?? hintText,
                    style: TextStyle(
                      fontSize: 14,
                      color: displayText != null
                          ? AppColors.authTextSecondary
                          : AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bottom sheet with checkboxes for multi-select.
  Future<List<T>?> _showMultiSelectSheet<T>({
    required String title,
    required Map<T, String> options,
    required List<T> selected,
  }) async {
    final tempSelected = List<T>.from(selected);

    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.filterDropdownPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.authTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setSheetState(tempSelected.clear);
                          },
                          child: const Text(
                            'Bỏ chọn tất cả',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Options list
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (_, i) {
                          final entry = options.entries.elementAt(i);
                          final isChecked = tempSelected.contains(entry.key);
                          return CheckboxListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primaryGold,
                            checkColor: AppColors.darkBackground2,
                            title: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.authTextSecondary,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked ?? false) {
                                  tempSelected.add(entry.key);
                                } else {
                                  tempSelected.remove(entry.key);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(tempSelected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.authButtonBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: AppColors.authButtonBorder,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.authButtonText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Label + child column for project-dependent fields.
  Widget _buildFilterColumn({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.authLabel.copyWith(
            color: AppColors.searchLabel,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  /// Loading placeholder shown while project options are being fetched.
  Widget _buildLoadingPlaceholder() {
    return const SizedBox(
      height: 30,
      child: Center(
        child: Text(
          'Đang tải ...',
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _filterRow({required Widget left, required Widget right}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  5. TẠO BỘ LỌC SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildCreateFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.filterDropdownPanel,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + "Áp dụng" (for create)
          Row(
            children: [
              Expanded(
                child: Text(
                  'TẠO BỘ LỌC'.toUpperCase(),
                  style: AppTextStyles.authLabel.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: 94,
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.authButtonText,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onDone,
                      borderRadius: BorderRadius.circular(24),
                      child: Center(
                        child: Text(
                          'ÁP DỤNG'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input + "Tạo bộ lọc" button row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x80D9D9D9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderInactive),
                  ),
                  child: FormBuilderTextField(
                    name: 'filterName',
                    validator: FormBuilderValidators.required(
                      errorText: 'Vui lòng nhập tên bộ lọc',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nhập tên bộ lọc',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 94,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.authButtonBackground,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.authButtonBorder),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onSaveFilter,
                      borderRadius: BorderRadius.circular(4),
                      child: Center(
                        child: Text(
                          'Tạo bộ lọc'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════

  void _onDone() {
    _formKey.currentState?.save();
    final fields = _formKey.currentState?.value ?? {};

    final projectId =
        (fields['project_id'] as List?)?.cast<int>() ?? const <int>[];
    final area = (fields['area'] as List?)?.cast<String>() ?? const <String>[];
    final type = (fields['type'] as List?)?.cast<String>() ?? const <String>[];
    final financialRange =
        (fields['financial_range'] as List?)?.cast<String>() ??
        const <String>[];
    final sourceId =
        (fields['source_id'] as List?)?.cast<int>() ?? const <int>[];
    final saleId = (fields['sale_id'] as List?)?.cast<int>() ?? const <int>[];
    final status = (fields['status'] as List?)?.cast<int>() ?? const <int>[];
    final keyword = (fields['keyword'] as String?)?.trim() ?? '';

    context.pop(
      KhachHangFilter(
        projectId: projectId,
        area: area,
        type: type,
        financialRange: financialRange,
        sourceId: sourceId,
        saleId: saleId,
        status: status,
        keyword: keyword,
        // customerType được quản lý bởi tabs ở màn list, không thay đổi trong form
        customerType: widget.initialFilter.customerType,
      ),
    );
  }

  Future<void> _onSaveFilter() async {
    _formKey.currentState?.save();
    final fields = _formKey.currentState?.value ?? {};

    // Validate filter name
    final filterName = (fields['filterName'] as String?)?.trim() ?? '';
    if (filterName.isEmpty) {
      _formKey.currentState?.fields['filterName']?.invalidate(
        'Vui lòng nhập tên bộ lọc',
      );
      return;
    }

    // Collect active filter values into data payload
    final data = <String, dynamic>{};

    final projectId = (fields['project_id'] as List?)?.cast<int>() ?? <int>[];
    if (projectId.isNotEmpty) {
      data['project_id'] = projectId.map((e) => '$e').toList();
    }

    final area = (fields['area'] as List?)?.cast<String>() ?? <String>[];
    if (area.isNotEmpty) data['area'] = area;

    final type = (fields['type'] as List?)?.cast<String>() ?? <String>[];
    if (type.isNotEmpty) data['type'] = type;

    final financialRange =
        (fields['financial_range'] as List?)?.cast<String>() ?? <String>[];
    if (financialRange.isNotEmpty) data['financial_range'] = financialRange;

    final sourceId = (fields['source_id'] as List?)?.cast<int>() ?? <int>[];
    if (sourceId.isNotEmpty) {
      data['source_id'] = sourceId.map((e) => '$e').toList();
    }

    final saleId = (fields['sale_id'] as List?)?.cast<int>() ?? <int>[];
    if (saleId.isNotEmpty) data['sale_id'] = saleId.map((e) => '$e').toList();

    final status = (fields['status'] as List?)?.cast<int>() ?? <int>[];
    if (status.isNotEmpty) data['status'] = status.map((e) => '$e').toList();

    final provider = context.read<KhachHangProvider>();
    final success = await provider.saveFilter(
      name: filterName,
      data: data,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo bộ lọc thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState?.fields['filterName']?.didChange('');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.submitError ?? 'Tạo bộ lọc thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
