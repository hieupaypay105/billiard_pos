import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../router/app_router.dart';
import '../../features/auth/auth_provider.dart';

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

    return Scaffold(
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
            // Context.go to profile or show a logout dialog
            showDialog(
              context: context,
              builder: (ctx) => Consumer(
                builder: (context, dialogRef, _) {
                  return AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          dialogRef.read(authProvider.notifier).logout();
                        },
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  );
                }
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
    );
  }
}
