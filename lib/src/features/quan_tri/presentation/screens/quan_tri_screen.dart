import 'dart:async';

import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/utils/format_utils.dart';
import 'package:anholding_app/src/core/widgets/an_column_def.dart';
import 'package:anholding_app/src/core/widgets/an_data_table.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/quan_tri/domain/entities/quan_tri_item.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class QuanTriScreen extends StatefulWidget {
  const QuanTriScreen({super.key});

  @override
  State<QuanTriScreen> createState() => _QuanTriScreenState();
}

class _QuanTriScreenState extends State<QuanTriScreen> {
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
      await context.read<QuanTriProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.appBackgroundGradient),
        child: SafeArea(
          child: Consumer2<QuanTriProvider, UserProvider>(
            builder: (context, provider, userProvider, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App bar ──────────────────────────────────
                    AnFeatureAppBar(
                      featureTitle: 'QUẢN TRỊ',
                      avatarUrl: userProvider.currentUser?.avatar ?? '',
                      onBackTap: () => Navigator.of(context).maybePop(),
                      onFilterTap: () => _openColumnSettings(context, provider),
                      onAddTap: () => _openAddSheet(context, provider),
                      onSearchTap: () => _openFilterSheet(context, provider),
                    ),
                    const SizedBox(height: 12),

                    // ── Result count ─────────────────────────────
                    if (!provider.isLoading && provider.errorMessage == null)
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
    QuanTriProvider provider,
  ) {
    final columns = _buildColumns(provider);

    if (provider.isLoading) {
      return Padding(
        padding: EdgeInsets.zero,
        child: AnDataTableSkeleton<QuanTriItem>(
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

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: AnDataTable<QuanTriItem>(
              scrollController: _scrollController,
              columns: columns,
              items: provider.items,
              sortColumnKey: provider.sortColumnKey,
              sortAscending: provider.sortAscending,
              onSort: provider.sort,
              onFilterTap: (_) {},
              actionsBuilder: (item, index) => _RowActions(
                onEdit: () => _openEditSheet(context, provider, item),
                onDelete: () => _confirmDelete(context, provider, item),
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
    QuanTriProvider provider,
    QuanTriItem item,
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
          'Bạn có chắc chắn muốn xoá "${item.fullname}"?',
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

  List<AnColumnDef<QuanTriItem>> _buildColumns(
    QuanTriProvider provider,
  ) {
    final defs = <AnColumnDef<QuanTriItem>>[];

    void add(
      String key, {
      required String label,
      required String Function(QuanTriItem item) getter,
      required double width,
      AnColumnType type = AnColumnType.text,
      TextAlign align = TextAlign.left,
      Widget Function(QuanTriItem item, int index)? cellBuilder,
    }) {
      if (!provider.isColumnVisible(key)) return;
      defs.add(
        AnColumnDef<QuanTriItem>(
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
    add(
      'username',
      label: 'Tên đăng nhập',
      getter: (e) => e.username,
      width: 140,
    );
    add(
      'fullname',
      label: 'Họ và tên',
      getter: (e) => e.fullname,
      width: 120,
    );
    add(
      'mobile',
      label: 'Điện thoại',
      getter: (e) => e.mobile,
      width: 120,
    );
    add('email', label: 'Email', getter: (e) => e.email, width: 180);
    add(
      'roleName',
      label: 'Nhóm quyền',
      getter: (e) => e.roleName,
      type: AnColumnType.filterable,
      width: 130,
    );
    add(
      'statusLabel',
      label: 'Trạng thái',
      getter: (e) => e.statusLabel,
      type: AnColumnType.filterable,
      width: 130,
      cellBuilder: (item, _) {
        final isActive = item.status == '1';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFD1F9D1) : const Color(0xFFF9D1D1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.statusLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
            ),
          ),
        );
      },
    );

    return defs;
  }

  Future<void> _openColumnSettings(
    BuildContext context,
    QuanTriProvider provider,
  ) async {
    await context.push(RoutePaths.quanTriColumnSettings);
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    QuanTriProvider provider,
  ) async {
    final result = await context.push<QuanTriFilter>(
      RoutePaths.quanTriFilter,
      extra: provider.filter,
    );
    if (result != null && context.mounted) {
      unawaited(provider.applyFilter(result));
    }
  }

  Future<void> _openAddSheet(
    BuildContext context,
    QuanTriProvider provider,
  ) async {
    await context.push(RoutePaths.quanTriAdd);
  }

  Future<void> _openEditSheet(
    BuildContext context,
    QuanTriProvider provider,
    QuanTriItem item,
  ) async {
    await context.push(RoutePaths.quanTriEdit, extra: item);
  }


}



class _RowActions extends StatelessWidget {
  const _RowActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleActionButton(
          backgroundColor: const Color(0xFF35B2E9),
          icon: Icons.edit,
          onTap: onEdit,
        ),
        const SizedBox(width: 4),
        _CircleActionButton(
          backgroundColor: const Color(0xFFEA2D2D),
          icon: Icons.delete_outline,
          onTap: onDelete,
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
