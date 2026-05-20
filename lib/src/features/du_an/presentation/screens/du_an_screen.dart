import 'dart:async';

import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/utils/format_utils.dart';
import 'package:anholding_app/src/core/widgets/an_column_def.dart';
import 'package:anholding_app/src/core/widgets/an_data_table.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/du_an/domain/entities/du_an_item.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DuAnScreen extends StatefulWidget {
  const DuAnScreen({super.key});

  @override
  State<DuAnScreen> createState() => _DuAnScreenState();
}

class _DuAnScreenState extends State<DuAnScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onScroll() async {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      await context.read<DuAnProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.featureScaffoldStart,
              AppColors.featureScaffoldEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer2<DuAnProvider, UserProvider>(
            builder: (context, provider, userProvider, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App bar ──────────────────────────────────
                    AnFeatureAppBar(
                      featureTitle: 'DỰ ÁN',
                      avatarUrl: userProvider.currentUser?.avatar ?? '',
                      onBackTap: () => Navigator.of(context).maybePop(),
                      onFilterTap: () => _openColumnSettings(context, provider),
                      onAddTap: () => _openAddSheet(context, provider),
                      onSearchTap: () => _openFilterSheet(context, provider),
                    ),
                    const SizedBox(height: 12),

                    // ── Result count ─────────────────────────────
                    if (!provider.isLoading &&
                        provider.errorMessage == null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '(${FormatUtils.formatPrice(provider.total)} kết quả)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // ── Table ─────────────────────────────────────
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildTableContent(context, provider),
                      ),
                    ),

                    // ── Pagination ─────────────────────────────
                    // (Pagination has been refactored to Lazy Loading)
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTableContent(
    BuildContext context,
    DuAnProvider provider,
  ) {
    final columns = _buildColumns(provider);

    if (provider.isLoading) {
      return Padding(
        padding: EdgeInsets.zero,
        child: AnDataTableSkeleton<DuAnItem>(
          columns: columns,
          rowCount: 10,
          actionsCount: 2,
          actionsColumnWidth: 74,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Text(
            provider.errorMessage!,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (columns.isEmpty) {
      return const Center(
        child: Text(
          'Vui lòng chọn ít nhất 1 cột để hiển thị',
          style: TextStyle(color: AppColors.textDark),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: AppColors.textDark),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: AnDataTable<DuAnItem>(
              scrollController: _scrollController,
              columns: columns,
              items: provider.items,
              sortColumnKey: provider.sortColumnKey,
              sortAscending: provider.sortAscending,
              onSort: provider.sort,
              onFilterTap: (_) {},
              actionsBuilder: (item, index) => _RowActions(
                onEdit: () => _openEditSheet(context, provider, item),
                // onDelete: () => _confirmDelete(context, provider, item),
              ),
              actionsColumnWidth: 74,
            ),
          ),
          if (provider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DuAnProvider provider,
    DuAnItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Xác nhận xoá',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xoá dự án "${item.name}"',
          style: const TextStyle(color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textDark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Xoá',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await provider.deleteItem(item.id);
    }
  }

  List<AnColumnDef<DuAnItem>> _buildColumns(DuAnProvider provider) {
    final defs = <AnColumnDef<DuAnItem>>[];

    void add(
      String key, {
      required String label,
      required String Function(DuAnItem item) getter,
      required double width,
      AnColumnType type = AnColumnType.text,
      TextAlign align = TextAlign.left,
      Widget Function(DuAnItem item, int index)? cellBuilder,
    }) {
      if (!provider.isColumnVisible(key)) return;
      defs.add(
        AnColumnDef<DuAnItem>(
          key: key,
          label: label,
          valueGetter: getter,
          type: type,
          width: width,
          textAlign: align,
          cellBuilder: cellBuilder,
        ),
      );
    }

    add('id', label: 'STT', getter: (e) => e.id, width: 60);
    add('name', label: 'Tên', getter: (e) => e.name, width: 120);
    add('address', label: 'Địa chỉ', getter: (e) => e.address, width: 150);
    add('investor', label: 'Chủ đầu tư', getter: (e) => e.investor, width: 120);
    add(
      'hotline',
      label: 'SĐT',
      getter: (e) => e.hotline,
      width: 130,
    );
    add(
      'status',
      label: 'Tình trạng',
      getter: (e) => e.statusLabel,
      type: AnColumnType.filterable,
      width: 130,
    );
    add(
      'createdAt',
      label: 'Ngày tạo',
      getter: (e) => e.createdAt,
      width: 150,
    );
    add(
      'projectType',
      label: 'Loại dự án',
      getter: (e) => _projectTypeLabel(e.projectType),
      type: AnColumnType.filterable,
      width: 130,
    );

    return defs;
  }

  Future<void> _openColumnSettings(
    BuildContext context,
    DuAnProvider provider,
  ) async {
    await context.push(RoutePaths.duAnColumnSettings);
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    DuAnProvider provider,
  ) async {
    final result = await context.push<DuAnFilter>(
      RoutePaths.duAnFilter,
      extra: provider.filter,
    );
    if (result != null && context.mounted) {
      unawaited(provider.applyFilter(result));
    }
  }

  Future<void> _openAddSheet(
    BuildContext context,
    DuAnProvider provider,
  ) async {
    await context.push(RoutePaths.duAnAdd);
  }

  Future<void> _openEditSheet(
    BuildContext context,
    DuAnProvider provider,
    DuAnItem item,
  ) async {
    await context.push(RoutePaths.duAnEdit, extra: item);
  }

  String _projectTypeLabel(String value) {
    return switch (value) {
      'CN' => 'Chuyển nhượng',
      'CDT' => 'Chủ đầu tư',
      _ => value,
    };
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          _CircleActionButton(
            backgroundColor: const Color(0xFF35B2E9),
            icon: Icons.edit,
            onTap: onEdit!,
          ),
        const SizedBox(width: 4),
        if (onDelete != null)
          _CircleActionButton(
            backgroundColor: const Color(0xFFEA2D2D),
            icon: Icons.delete_outline,
            onTap: onDelete!,
          ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  });

  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: 11, color: Colors.white),
        ),
      ),
    );
  }
}
