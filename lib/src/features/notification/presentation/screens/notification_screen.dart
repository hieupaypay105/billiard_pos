import 'dart:async';

import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/utils/deeplink_utils.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_notification_provider.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_item.dart';
import 'package:anholding_app/src/features/notification/presentation/provider/notification_provider.dart';
import 'package:anholding_app/src/features/notification/presentation/widgets/notification_skeleton_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      // Always refresh on open so that tapping a notification from the dashboard
      // never shows a stale (or empty / black) screen. The pull-to-refresh still
      // works as a secondary manual trigger.
      if (!provider.isLoading) {
        await provider.refresh();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onScroll() async {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      await context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AnFeatureAppBar(
        featureTitle: 'THÔNG BÁO',
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.dashboard);
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
          top: false,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: _buildModalCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 50),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.dashboardCardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F37312E),
            offset: Offset(0, 40),
            blurRadius: 80,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Filter Tabs
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterTab(
                        0,
                        'Quan trọng',
                        provider.unreadCount.important,
                        notificationType: 'IMPORTANT',
                        provider: provider,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        1,
                        'Khách hàng',
                        provider.unreadCount.customer,
                        notificationType: 'CUSTOMER',
                        provider: provider,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        2,
                        'Bảng hàng',
                        provider.unreadCount.data,
                        notificationType: 'DATA',
                        provider: provider,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        3,
                        'Khác',
                        provider.unreadCount.other,
                        notificationType: 'OTHER',
                        provider: provider,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // List Title/Divider
          const Divider(
            height: 1,
            color: Color(0x4DDADADA),
          ),
          // Notifications List
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const NotificationSkeletonList(itemCount: 6);
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (provider.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có thông báo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  color: AppColors.primaryGold,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount:
                        provider.items.length +
                        (provider.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0x33B9B0AC),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      if (index == provider.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildNotificationItem(
                        provider.items[index],
                        provider,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    int index,
    String label,
    int count, {
    required String notificationType,
    required NotificationProvider provider,
  }) {
    final isSelected = provider.selectedFilterIndex == index;
    return GestureDetector(
      onTap: () async {
        await provider.setNotificationType(
          notificationType,
          filterIndex: index,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 37,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [
                        AppColors.dashboardCardStart,
                        AppColors.dashboardCardEnd,
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.authButtonText
                    : AppColors.textHint,
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA3E1B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem item,
    NotificationProvider provider,
  ) {
    final initials = item.title
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return GestureDetector(
      onTap: () async {
        if (!item.isRead && context.mounted) {
          // Instantly sync the global/dashboard badge count
          context
              .read<DashboardNotificationProvider>()
              .markAsReadOptimistic(item.id);
        }
        unawaited(provider.markAsRead(item.id));
        await DeeplinkUtils.handleAppNavigation(
          context: context,
          deepLink: item.deepLink,
          actionUrl: item.actionUrl,
        );
      },
      child: Container(
        color: !item.isRead
            ? AppColors.primaryGold.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2CB5E8),
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: !item.isRead
                                ? AppColors.primaryGold
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          _formatRelativeTime(item.createdAt),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: !item.isRead
                                ? AppColors.primaryGold
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.content,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: !item.isRead
                                ? Colors.white
                                : AppColors.textHint,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isRead)
                        const Padding(
                          padding: EdgeInsets.only(left: 12, top: 4),
                          child: Icon(
                            Icons.check,
                            size: 20,
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 30) return '${diff.inDays} ngày trước';
      if (diff.inDays < 365) return '${diff.inDays ~/ 30} tháng trước';
      return '${diff.inDays ~/ 365} năm trước';
    } on Exception catch (_) {
      return dateString;
    }
  }
}
