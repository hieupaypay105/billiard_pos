import 'dart:async';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_confirm_dialog.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_item.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/provider/cong_tac_vien_provider.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/widgets/cong_tac_vien_card.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/widgets/cong_tac_vien_skeleton_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CongTacVienScreen extends StatefulWidget {
  const CongTacVienScreen({super.key});

  @override
  State<CongTacVienScreen> createState() => _CongTacVienScreenState();
}

class _CongTacVienScreenState extends State<CongTacVienScreen> {
  late final ScrollController _scrollController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      if (mounted) {
        context.read<CongTacVienProvider>().loadMore();
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final provider = context.read<CongTacVienProvider>();
        provider.applyFilter(provider.filter.copyWith(keyword: query));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AnFeatureAppBar(
        featureTitle: 'CỘNG TÁC VIÊN',
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
          top: false,
          bottom: false,
          child: Consumer2<CongTacVienProvider, UserProvider>(
            builder: (context, provider, userProvider, _) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  80 + bottomSafeInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search & Filter ─────────────────────────────
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
                            child: FormBuilderTextField(
                              name: 'keyword',
                              initialValue: provider.filter.keyword,
                              onChanged: (value) =>
                                  _onSearchChanged(value ?? ''),
                              style: AppTextStyles.body.copyWith(
                                fontSize: 16,
                                color: AppColors.authTextLight,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm',
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
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _openFilterSheet(context, provider),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.searchBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.searchGold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Card List ─────────────────────────────────────
                    Expanded(
                      child: _buildListContent(context, provider),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 24 + bottomSafeInset),
        child: GestureDetector(
          onTap: () =>
              _openAddSheet(context, context.read<CongTacVienProvider>()),
          child: SvgPicture.asset(
            AppIcons.addFab,
            width: 81,
            height: 83,
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    CongTacVienProvider provider,
  ) {
    if (provider.isLoading) {
      return const CongTacVienSkeletonList();
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

    if (provider.items.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.primaryGold,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGold,
                ),
              ),
            );
          }

          final item = provider.items[index];
          return CongTacVienCard(
            item: item,
            onEdit: () => _openEditSheet(context, provider, item),
            onDelete: () => _confirmDelete(context, provider, item),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CongTacVienProvider provider,
    CongTacVienItem item,
  ) async {
    final confirmed = await AnConfirmDialog.show(
      context,
      title: 'Xác nhận xóa CTV',
      description:
          'Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa "${item.fullname}" khỏi danh mục hệ thống vĩnh viễn không?',
    );

    if ((confirmed ?? false) && context.mounted) {
      await provider.deleteItem(item.id);
    }
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    CongTacVienProvider provider,
  ) async {
    final result = await context.push<CongTacVienFilter>(
      RoutePaths.congTacVienFilter,
      extra: provider.filter,
    );
    if (result != null && context.mounted) {
      unawaited(provider.applyFilter(result));
    }
  }

  Future<void> _openAddSheet(
    BuildContext context,
    CongTacVienProvider provider,
  ) async {
    await context.push(RoutePaths.congTacVienAdd);
  }

  Future<void> _openEditSheet(
    BuildContext context,
    CongTacVienProvider provider,
    CongTacVienItem item,
  ) async {
    await context.push(RoutePaths.congTacVienEdit, extra: item);
  }
}
