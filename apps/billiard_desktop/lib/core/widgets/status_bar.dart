import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/core_shared.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../../features/sync/sync_provider.dart';
import '../providers/providers.dart';

class StatusBar extends ConsumerWidget {
  final UserModel? user;
  final SyncState syncState;
  const StatusBar({super.key, this.user, required this.syncState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.navRailBg,
        border: Border(
            top: BorderSide(color: Color(0xFF0D2020), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // User info
          Icon(Icons.person_pin, size: 14,
              color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 6),
          Text(
            user?.displayName ?? '—',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          if (user != null) ...[
            _separator(),
            _chip(_roleLabel(user!.role),
                color: _roleColor(user!.role)),
          ],

          // Local IP display
          ref.watch(localIpsProvider).when(
            data: (ips) {
              if (ips.isEmpty) return const SizedBox();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _separator(),
                  Icon(Icons.wifi_tethering, size: 14,
                      color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Text(
                    'IP Kết nối: ${ips.join(", ")} (Port: 8085)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),


          const Spacer(),
          // Pending sync count
          if (syncState.pendingCount > 0) ...[
            Icon(Icons.upload_outlined, size: 14,
                color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              '${syncState.pendingCount} bản ghi chờ sync',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.warning),
            ),
            _separator(),
          ],
          // Version
          Text(
            'v1.0.0',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _separator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 14,
      color: Colors.white.withOpacity(0.15),
    );
  }

  Widget _chip(String label, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'admin' => 'Admin',
      'manager' => 'Manager',
      'cashier' => 'Thu ngân',
      'waiter' => 'Phục vụ',
      _ => role,
    };
  }

  Color _roleColor(String role) {
    return switch (role) {
      'admin' => AppColors.error,
      'manager' => AppColors.accent,
      'cashier' => AppColors.success,
      'waiter' => AppColors.info,
      _ => AppColors.textMuted,
    };
  }
}
