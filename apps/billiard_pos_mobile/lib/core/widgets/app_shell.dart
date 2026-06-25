import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../router/app_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/tables/tables_provider.dart';
import 'desktop_connection_dialog.dart';

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _navItems = [
  _NavItem(
    route: AppRoutes.tables,
    icon: Icons.table_bar_outlined,
    activeIcon: Icons.table_bar_rounded,
    label: 'Bàn',
  ),
  _NavItem(
    route: AppRoutes.reports,
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label: 'Báo cáo',
  ),
  _NavItem(
    route: '/profile', // Placeholder route for account/logout
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Tài khoản',
  ),
];

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = _navItems.indexWhere((n) => location.startsWith(n.route));
    if (currentIndex < 0) currentIndex = 0;

    final tablesState = ref.watch(tablesProvider);
    final hasConfiguredDesktop = tablesState.connectedIp != null && tablesState.connectedIp!.isNotEmpty;
    final showLockOverlay = hasConfiguredDesktop && !tablesState.isDesktopConnected;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == 0) {
                context.go(AppRoutes.tables);
              } else if (index == 1) {
                context.go(AppRoutes.reports);
              } else if (index == 2) {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.wifi_tethering, color: Colors.blue),
                            title: const Text('Kết nối máy tính (Wifi)'),
                            onTap: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (context) => const DesktopConnectionDialog(),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Đăng xuất'),
                            onTap: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Đăng xuất'),
                                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(dialogCtx);
                                        ref.read(authProvider.notifier).logout();
                                      },
                                      child: const Text('Đăng xuất'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: _navItems.map((n) => BottomNavigationBarItem(
              icon: Icon(n.icon),
              activeIcon: Icon(n.activeIcon),
              label: n.label,
            )).toList(),
          ),
        ),
        if (showLockOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 72,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Mất Kết Nối Máy Tính',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể kết nối đến máy chủ desktop tại:\n${tablesState.connectedIp}\n\n'
                          'Vui lòng kiểm tra:\n'
                          '• Ứng dụng New World Pos trên máy tính đã mở.\n'
                          '• Điện thoại và máy tính đã kết nối chung một mạng Wifi.\n\n'
                          'Đang tự động thử kết nối lại...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                            fontWeight: FontWeight.normal,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 48),
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const DesktopConnectionDialog(),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          label: const Text(
                            'Đổi địa chỉ IP máy tính',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
}
