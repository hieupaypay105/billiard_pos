import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'sync_provider.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final notifier = ref.read(syncStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Đồng bộ dữ liệu', style: AppTextStyles.headlineLarge),
          Text(
            'Quản lý đồng bộ dữ liệu giữa ứng dụng và server backend.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status Cards ──────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Online/Offline status card
                    _StatusCard(
                      isOnline: syncState.isOnline,
                      pendingCount: syncState.pendingCount,
                      lastSyncTime: syncState.lastSyncTime,
                      isSyncing: syncState.isSyncing,
                      onSyncNow: () => notifier.syncNow(),
                      onSimulateOffline: () => notifier.simulateOffline(),
                      onSimulateOnline: () => notifier.simulateOnline(),
                      onClearAllData: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red, size: 24),
                                SizedBox(width: 8),
                                Text('Xóa dữ liệu local'),
                              ],
                            ),
                            content: const Text(
                              'Bạn có chắc chắn muốn xóa toàn bộ dữ liệu lưu trữ '
                              'ngoại tuyến (bàn, sản phẩm, hội viên, đơn hàng chờ)?\n\n'
                              'Thao tác này không thể hoàn tác. Phiên đăng nhập '
                              'của bạn vẫn được giữ nguyên.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(ctx, true),
                                icon: const Icon(Icons.delete_forever,
                                    size: 16),
                                label: const Text('Xóa ngay'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await notifier.clearAllLocalData();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Info cards row
                    Row(children: [
                      _InfoCard(
                        icon: Icons.cloud_upload_outlined,
                        label: 'Chờ đồng bộ',
                        value: '${syncState.pendingCount}',
                        color: syncState.pendingCount > 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _InfoCard(
                        icon: Icons.check_circle_outline,
                        label: 'Đồng bộ lần cuối',
                        value: syncState.lastSyncTime ?? '—',
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      _InfoCard(
                        icon: syncState.isOnline
                            ? Icons.wifi
                            : Icons.wifi_off,
                        label: 'Trạng thái',
                        value: syncState.isOnline ? 'Online' : 'Offline',
                        color: syncState.isOnline
                            ? AppColors.online
                            : AppColors.offline,
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // ── Sync Log Console ──────────────────────────────────────────
              Expanded(
                flex: 4,
                child: _SyncLogConsole(logs: syncState.logs),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final String? lastSyncTime;
  final bool isSyncing;
  final VoidCallback onSyncNow;
  final VoidCallback onSimulateOffline;
  final VoidCallback onSimulateOnline;
  final VoidCallback onClearAllData;

  const _StatusCard({
    required this.isOnline,
    required this.pendingCount,
    this.lastSyncTime,
    required this.isSyncing,
    required this.onSyncNow,
    required this.onSimulateOffline,
    required this.onSimulateOnline,
    required this.onClearAllData,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: isOnline ? AppColors.success : AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'Đang kết nối' : 'Mất kết nối',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: isOnline ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Text(
                    isOnline
                        ? 'Dữ liệu được đồng bộ tự động'
                        : 'Đang lưu offline, sync khi có mạng',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isSyncing ? null : onSyncNow,
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync, size: 18),
                label: Text(isSyncing ? 'Đang sync...' : 'Sync ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Dev tools
            OutlinedButton(
              onPressed: isSyncing
                  ? null
                  : (isOnline ? onSimulateOffline : onSimulateOnline),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isOnline ? 'Giả lập Offline' : 'Khôi phục Online',
                  style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            // Xóa dữ liệu local
            OutlinedButton.icon(
              onPressed: isSyncing ? null : onClearAllData,
              icon: const Icon(Icons.delete_forever, size: 16,
                  color: Colors.red),
              label: const Text('Xóa local',
                  style: TextStyle(fontSize: 12, color: Colors.red)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value,
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: color, fontSize: 22)),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ),
      );
}

class _SyncLogConsole extends StatefulWidget {
  final List<String> logs;
  const _SyncLogConsole({required this.logs});

  @override
  State<_SyncLogConsole> createState() => _SyncLogConsoleState();
}

class _SyncLogConsoleState extends State<_SyncLogConsole> {
  final _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(_SyncLogConsole old) {
    super.didUpdateWidget(old);
    if (widget.logs.length != old.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 1)),
            ),
            child: Row(children: [
              Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.online)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Sync Log',
                    style: TextStyle(fontFamily: 'monospace',
                        fontSize: 13, color: Colors.white70)),
              ),
              const Icon(Icons.terminal, size: 14, color: Colors.white38),
            ]),
          ),
          // Log content
          Expanded(
            child: widget.logs.isEmpty
                ? const Center(
                    child: Text('Chưa có log nào.',
                        style: TextStyle(fontFamily: 'monospace',
                            fontSize: 12, color: Colors.white38)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.logs.length,
                    itemBuilder: (_, i) {
                      final log = widget.logs[i];
                      Color logColor = Colors.white70;
                      if (log.contains('ERROR')) {
                        logColor = AppColors.error;
                      } else if (log.contains('WARNING')) {
                        logColor = AppColors.warning;
                      } else if (log.contains('hoàn tất') ||
                          log.contains('Kết nối')) {
                        logColor = AppColors.online;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(log,
                            style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 12.5,
                                color: logColor)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
