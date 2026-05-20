import 'dart:async';

import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/utils/deeplink_utils.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_notification_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/dashboard_greeting_section.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/dashboard_notification_item_card.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:anholding_app/src/features/dashboard/presentation/widgets/dashboard_top_bar.dart';
import 'package:anholding_app/src/features/notification/presentation/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<UserProvider>().fetchUserInfo());

      final notifProvider = context.read<DashboardNotificationProvider>();
      if (notifProvider.items.isEmpty && !notifProvider.isLoading) {
        unawaited(notifProvider.refresh());
      }

      // Load real metrics from DashboardProvider (role + customer stats).
      final dashProvider = context.read<DashboardProvider>();
      if (!dashProvider.isLoading) {
        unawaited(dashProvider.loadAll());
      }
    });
  }

  /// Bug #2 (Option C): Push NotificationScreen and refresh the
  /// DashboardNotificationProvider when the user returns. This keeps the
  /// unread badge count in sync without coupling the two providers.
  Future<void> _openNotificationScreen() async {
    await context.push(RoutePaths.notification);
    // User has returned from NotificationScreen — refresh so badge reflects
    // any items they marked as read.
    if (mounted) {
      unawaited(context.read<DashboardNotificationProvider>().refresh());
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
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final isInitialLoading =
                userProvider.currentUser == null &&
                userProvider.fetchError == null;

            if (userProvider.isFetchingUser || isInitialLoading) {
              return const SafeArea(child: DashboardSkeleton());
            }

            if (userProvider.fetchError != null &&
                userProvider.currentUser == null) {
              return SafeArea(child: _buildErrorState(userProvider));
            }

            final user = userProvider.currentUser;
            if (user == null) {
              return const SafeArea(
                child: Center(
                  child: Text(
                    'Chưa đăng nhập',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            final unreadCount = context
                .watch<DashboardNotificationProvider>()
                .unreadCount;

            return Stack(
              children: [
                // Main Scrollable Content
                SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await userProvider.fetchUserInfo();
                      if (context.mounted) {
                        unawaited(
                          context
                              .read<DashboardNotificationProvider>()
                              .refresh(),
                        );
                        unawaited(
                          context.read<DashboardProvider>().loadAll(),
                        );
                      }
                    },
                    color: AppColors.primaryGold,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Add top padding to offset behind the sticky top bar,
                      // and bottom padding for the bottom bar.
                      padding: const EdgeInsets.fromLTRB(0, 60, 0, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          Builder(
                            builder: (context) {
                              final dashProvider = context
                                  .watch<DashboardProvider>();
                              return DashboardGreetingSection(
                                fullname: user.fullname.isNotEmpty
                                    ? user.fullname
                                    : 'Người dùng',
                                role: dashProvider.role,
                                totalCustomer: dashProvider.totalCustomer,
                                byStatus: dashProvider.byStatus,
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          _NotificationSection(
                            onOpenNotificationScreen: _openNotificationScreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sticky Top Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: DashboardTopBar(
                    avatar: user.avatar,
                    notificationCount: unreadCount,
                    onNotificationTap: _openNotificationScreen,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(UserProvider userProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              userProvider.fetchError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => userProvider.fetchUserInfo(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Section ──────────────────────────────────────────────────────

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({required this.onOpenNotificationScreen});

  /// Callback supplied by the parent [_DashboardScreenState] that pushes
  /// NotificationScreen and refreshes DashboardNotificationProvider on pop
  /// (Bug #2 Option C fix).
  final VoidCallback onOpenNotificationScreen;

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardNotificationProvider>(
      builder: (context, provider, _) {
        final items = provider.items;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('THÔNG BÁO', style: AppTextStyles.dashboardSectionTitle),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpenNotificationScreen,
                    child: Text(
                      'XEM TẤT CẢ',
                      style: AppTextStyles.authLabel.copyWith(
                        color: AppColors.authTextDisabled,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.isLoading)
                    const DashboardShimmer(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: NotificationItemSkeleton(),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: NotificationItemSkeleton(),
                          ),
                        ],
                      ),
                    )
                  else if (items.isEmpty)
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Không có thông báo',
                          style: AppTextStyles.bodyWhite,
                        ),
                      ),
                    )
                  else
                    ...items
                        .take(5)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                if (!item.isRead && context.mounted) {
                                  // Instantly update badge count
                                  context
                                      .read<DashboardNotificationProvider>()
                                      .markAsReadOptimistic(item.id);
                                  // Background API call via full notification provider
                                  unawaited(
                                    context
                                        .read<NotificationProvider>()
                                        .markAsRead(item.id),
                                  );
                                }

                                final hasLink =
                                    (item.deepLink != null &&
                                        item.deepLink!.isNotEmpty) ||
                                    (item.actionUrl != null &&
                                        item.actionUrl!.isNotEmpty);

                                if (hasLink) {
                                  await DeeplinkUtils.handleAppNavigation(
                                    context: context,
                                    deepLink: item.deepLink,
                                    actionUrl: item.actionUrl,
                                  );
                                } else {
                                  onOpenNotificationScreen();
                                }
                              },
                              child: DashboardNotificationItemCard(
                                title: item.title,
                                body: item.content,
                                createdAt:
                                    DateTime.tryParse(item.createdAt) ??
                                    DateTime.now(),
                                isRead: item.isRead,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
