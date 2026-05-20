import 'dart:async';
import 'dart:io';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_confirm_dialog.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/utils/phone_call_utils.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/widgets/khach_hang_card.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/widgets/khach_hang_skeleton_list.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/widgets/khach_hang_status_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class KhachHangScreen extends StatefulWidget {
  const KhachHangScreen({super.key});

  @override
  State<KhachHangScreen> createState() => _KhachHangScreenState();
}

class _KhachHangScreenState extends State<KhachHangScreen> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormBuilderState>();
  Timer? _debounce;
  _KhachHangSegment _segment = _KhachHangSegment.personal;
  KhachHangProvider? _provider;
  String _lastProviderKeyword = '';

  static const _kSearchField = 'keyword';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<KhachHangProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_syncSearchField);
      _provider = provider;
      _lastProviderKeyword = provider.filter.keyword;
      _provider?.addListener(_syncSearchField);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncSearchField(force: true);
      });
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_syncSearchField);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      context.read<KhachHangProvider>().loadMore();
    }
  }

  void _onSearchChanged(String value, KhachHangProvider provider) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmed = value.trim();
      if (trimmed == provider.filter.keyword) return;
      unawaited(
        provider.applyFilter(
          provider.filter.copyWith(
            keyword: trimmed,
            page: 1,
          ),
        ),
      );
    });
  }

  void _syncSearchField({bool force = false}) {
    final nextKeyword = _provider?.filter.keyword ?? '';
    if (!force && nextKeyword == _lastProviderKeyword) return;

    _lastProviderKeyword = nextKeyword;
    final field = _formKey.currentState?.fields[_kSearchField];
    if (field == null) return;

    final currentKeyword = (field.value as String?) ?? '';
    if (currentKeyword == nextKeyword) return;
    field.didChange(nextKeyword);
  }

  void _showCallMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleZaloTap(KhachHangItem item) async {
    final phoneNumber = normalizePhoneNumber(item.phone);
    if (phoneNumber == null) {
      _showCallMessage('Khách hàng chưa có số điện thoại hợp lệ');
      return;
    }

    final zaloPhone = phoneNumber.startsWith('+')
        ? phoneNumber.substring(1)
        : phoneNumber;
    final zaloUri = Uri.parse('https://zalo.me/$zaloPhone');
    final didLaunch = await launchUrl(
      zaloUri,
      mode: LaunchMode.externalApplication,
    );
    if (!didLaunch) {
      _showCallMessage('Không thể mở Zalo lúc này');
    }
  }

  Future<void> _handleCallTap(KhachHangItem item) async {
    final phoneNumber = normalizePhoneNumber(item.phone);
    if (phoneNumber == null) {
      _showCallMessage('Khách hàng chưa có số điện thoại hợp lệ');
      return;
    }

    if (Platform.isAndroid) {
      final permissionStatus = await Permission.phone.request();
      if (!permissionStatus.isGranted) {
        _showCallMessage('Ứng dụng cần quyền gọi điện để gọi bằng nhà mạng');
        return;
      }

      final didCall = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
      if (didCall ?? false) return;
    }

    final callUri = Uri(scheme: 'tel', path: phoneNumber);
    final didLaunch = await launchUrl(callUri);
    if (!didLaunch) {
      _showCallMessage('Không thể thực hiện cuộc gọi lúc này');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AnFeatureAppBar(
        featureTitle: 'KHÁCH HÀNG',
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 24 + bottomSafeInset),
        child: GestureDetector(
          onTap: () => context.push(RoutePaths.khachHangAdd),
          child: SvgPicture.asset(AppIcons.addFab, width: 81, height: 83),
        ),
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
          child: Consumer<KhachHangProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  80 + bottomSafeInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search & Filter Input ─────────────────────
                    _buildSearchSection(provider),
                    const SizedBox(height: 12),

                    // ── Team / Personal Segment ───────────────────
                    _buildSegmentSection(provider),
                    const SizedBox(height: 14),

                    // ── Status Pills ──────────────────────────────
                    if (provider.options != null) ...[
                      KhachHangStatusPills(
                        options: provider.options!,
                        selectedStatuses: provider.filter.status,
                        statusCounts: provider.dataStatus,
                        onStatusTap: (index) {
                          final currentStatus = List<int>.from(
                            provider.filter.status,
                          );
                          if (currentStatus.contains(index)) {
                            currentStatus.remove(index);
                          } else {
                            currentStatus.add(index);
                          }
                          unawaited(
                            provider.applyFilter(
                              provider.filter.copyWith(
                                status: currentStatus,
                                page: 1,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Card List (scrollable only) ───────────────
                    Expanded(
                      child: _buildListContent(provider),
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

  Widget _buildSearchSection(KhachHangProvider provider) {
    return FormBuilder(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FormBuilderTextField(
                name: _kSearchField,
                initialValue: provider.filter.keyword,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  color: AppColors.authTextLight,
                ),
                onChanged: (value) => _onSearchChanged(value ?? '', provider),
                cursorColor: AppColors.primaryGold,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm',
                  hintStyle: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    color: AppColors.authTextSecondary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildIconControlButton(
            icon: Icons.filter_list,
            onTap: () => _openFilterSheet(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentSection(KhachHangProvider provider) {
    return Row(
      children: [
        _buildSegmentTab(
          text: 'KHÁCH HÀNG CÁ NHÂN',
          selected: _segment == _KhachHangSegment.personal,
          onTap: () {
            if (_segment == _KhachHangSegment.personal) return;
            setState(() => _segment = _KhachHangSegment.personal);
            _scrollController.jumpTo(0);
            unawaited(
              provider.applyFilter(
                provider.filter.copyWith(
                  customerType: 'personal',
                  page: 1,
                ),
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 1,
          height: 22,
          color: AppColors.authInputBorder,
        ),
        _buildSegmentTab(
          text: 'KHÁCH HÀNG TEAM',
          selected: _segment == _KhachHangSegment.team,
          onTap: () {
            if (_segment == _KhachHangSegment.team) return;
            setState(() => _segment = _KhachHangSegment.team);
            _scrollController.jumpTo(0);
            unawaited(
              provider.applyFilter(
                provider.filter.copyWith(
                  customerType: 'team',
                  page: 1,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSegmentTab({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected
        ? AppColors.authButtonText
        : AppColors.authButtonText.withValues(alpha: 0.3);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: color,
            letterSpacing: -0.75,
            decoration: selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: AppColors.authButtonText,
            decorationThickness: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildIconControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.searchBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24,
          color: AppColors.authButtonText,
        ),
      ),
    );
  }

  Widget _buildListContent(KhachHangProvider provider) {
    // Loading initial state
    if (provider.isLoading && provider.items.isEmpty) {
      return const KhachHangSkeletonList();
    }

    // Error state (empty list)
    if (provider.errorMessage != null && provider.items.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Text(
          provider.errorMessage!,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      );
    }

    // Empty state
    if (provider.items.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy khách hàng nào',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // ── Data list: only this scrolls ──────────────────────
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.primaryGold,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load-more spinner at the bottom
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
          return GestureDetector(
            onTap: () => context.push(RoutePaths.khachHangDetail, extra: item),
            child: KhachHangCard(
              item: item,
              saleName: provider.saleLabel(item.saleId),
              isTeam: _segment == _KhachHangSegment.team,
              onCallTap: () => _handleCallTap(item),
              onChatTap: () async {
                await context.push(RoutePaths.khachHangTraoDoi, extra: item);
              },
              onZaloTap: () => _handleZaloTap(item),
              onEditTap: () => _openEditSheet(context, provider, item),
              onDeleteTap: () => _confirmDelete(context, provider, item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    KhachHangProvider provider,
  ) async {
    final result = await context.push<KhachHangFilter>(
      RoutePaths.khachHangFilter,
      extra: provider.filter,
    );
    if (result != null && context.mounted) {
      _formKey.currentState?.fields[_kSearchField]?.didChange(result.keyword);
      unawaited(provider.applyFilter(result));
    }
  }

  Future<void> _openEditSheet(
    BuildContext context,
    KhachHangProvider provider,
    KhachHangItem item,
  ) async {
    await context.push(RoutePaths.khachHangEdit, extra: item);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    KhachHangProvider provider,
    KhachHangItem item,
  ) async {
    final confirmed = await AnConfirmDialog.show(
      context,
      title: 'Xác nhận xoá',
      description: 'Bạn có chắc chắn muốn xoá khách hàng "${item.name}"',
      confirmText: 'XOÁ',
    );

    if ((confirmed ?? false) && context.mounted) {
      await provider.deleteItem(item.id);
    }
  }
}

enum _KhachHangSegment {
  team,
  personal,
}
