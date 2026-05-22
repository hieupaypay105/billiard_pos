import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../router/app_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/sync/sync_provider.dart';
import 'status_bar.dart';

/// Navigation item model
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
    route: AppRoutes.billing,
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
    label: 'Hóa đơn',
  ),
  _NavItem(
    route: AppRoutes.statistics,
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label: 'Thống kê',
  ),
  _NavItem(
    route: AppRoutes.reports,
    icon: Icons.summarize_outlined,
    activeIcon: Icons.summarize_rounded,
    label: 'Báo cáo',
  ),
  _NavItem(
    route: AppRoutes.sync,
    icon: Icons.cloud_sync_outlined,
    activeIcon: Icons.cloud_sync_rounded,
    label: 'Đồng bộ',
  ),
];

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex =
        _navItems.indexWhere((n) => location.startsWith(n.route));
    final activeIndex = currentIndex < 0 ? 0 : currentIndex;
    final user = ref.watch(currentUserProvider);
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── TOP APP BAR ──────────────────────────────────────────────────
          _buildTopBar(context, ref, syncState),

          // ── MAIN CONTENT ROW ──────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── NAVIGATION RAIL ──────────────────────────────────────
                _buildNavRail(context, activeIndex),

                // ── CONTENT AREA ─────────────────────────────────────────
                Expanded(child: child),
              ],
            ),
          ),

          // ── STATUS BAR ───────────────────────────────────────────────────
          StatusBar(user: user, syncState: syncState),
        ],
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, WidgetRef ref, SyncState syncState) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Logo
          const Icon(Icons.table_bar_rounded,
              color: Colors.white, size: 26),
          const SizedBox(width: 10),
          const Text(
            'Billiard POS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 24,
            color: Colors.white24,
          ),
          // Clock
          _LiveClock(),
          const Spacer(),
          // Sync status chip
          _SyncChip(syncState: syncState),
          const SizedBox(width: 16),
          // User Avatar & Logout
          _UserMenu(),
        ],
      ),
    );
  }

  Widget _buildNavRail(BuildContext context, int activeIndex) {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        color: AppColors.navRailBg,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          ..._navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = i == activeIndex;

            return Tooltip(
              message: item.label,
              preferBelow: false,
              child: InkWell(
                onTap: () => context.go(item.route),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.navRailIndicator
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Live Clock Widget ────────────────────────────────────────────────────────

class _LiveClock extends StatefulWidget {
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late String _time;
  late String _date;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _update();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_update);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    final now = DateTime.now();
    _time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _time,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        Text(
          _date,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

// ─── Sync Status Chip ─────────────────────────────────────────────────────────

class _SyncChip extends StatelessWidget {
  final SyncState syncState;
  const _SyncChip({required this.syncState});

  @override
  Widget build(BuildContext context) {
    final isOnline = syncState.isOnline;
    final pending = syncState.pendingCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.success.withOpacity(0.2)
            : AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withOpacity(0.4)
              : AppColors.error.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.online : AppColors.offline,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline
                ? (pending > 0 ? 'Online · $pending chờ' : 'Online')
                : 'Offline',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOnline ? AppColors.online : AppColors.offline,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User Menu ────────────────────────────────────────────────────────────────

class _UserMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName,
                  style: AppTextStyles.labelLarge),
              Text(user.role,
                  style: AppTextStyles.labelSmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
            value: 'logout',
            child: Row(children: [
              Icon(Icons.logout, size: 16),
              SizedBox(width: 8),
              Text('Đăng xuất'),
            ])),
      ],
      onSelected: (val) async {
        if (val == 'logout') {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go(AppRoutes.login);
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                user.role,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.7), size: 18),
        ],
      ),
    );
  }
}
