import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/sync_service.dart';
import '../../core/providers/providers.dart';

class SyncState {
  final bool isOnline;
  final int pendingCount;
  final List<String> logs;
  final bool isSyncing;
  final String? lastSyncTime;

  const SyncState({
    this.isOnline = true,
    this.pendingCount = 0,
    this.logs = const [],
    this.isSyncing = false,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    List<String>? logs,
    bool? isSyncing,
    String? lastSyncTime,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      logs: logs ?? this.logs,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService? _syncService;
  StreamSubscription<ConnectivityStatus>? _statusSub;
  StreamSubscription<String>? _logSub;

  SyncNotifier({SyncService? syncService})
      : _syncService = syncService,
        super(const SyncState()) {
    _init();
  }

  Future<void> _init() async {
    if (_syncService != null) {
      // Set initial status and logs from service
      state = state.copyWith(
        isOnline: _syncService.isOnline,
        pendingCount: _syncService.pendingCount,
        logs: _syncService.syncLog,
      );

      // Listen to connectivity status updates
      _statusSub = _syncService.statusStream.listen((status) {
        state = state.copyWith(
          isOnline: status == ConnectivityStatus.online,
          pendingCount: _syncService.pendingCount,
        );
      });

      // Listen to log changes
      _logSub = _syncService.logStream.listen((log) {
        state = state.copyWith(
          logs: _syncService.syncLog,
        );
      });

      // Initialize the service (checks current status and starts stream)
      await _syncService.initialize();
    } else {
      _addLog('Sync module initialized.');
      // Simulate online status
      state = state.copyWith(isOnline: true, pendingCount: 0);
    }
  }

  void _addLog(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    final logs = [...state.logs, '[$ts] $msg'];
    if (logs.length > 100) logs.removeAt(0);
    state = state.copyWith(logs: logs);
  }

  Future<void> syncNow() async {
    if (_syncService != null) {
      if (!_syncService.isOnline) {
        state = state.copyWith(logs: _syncService.syncLog);
        return;
      }
      state = state.copyWith(isSyncing: true, logs: _syncService.syncLog);
      
      // Push pending orders
      final pushResult = await _syncService.syncNow();
      
      // Pull online data
      final pullResult = await _syncService.pullOnlineDataToOffline();
      
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      state = state.copyWith(
        isSyncing: false,
        pendingCount: _syncService.pendingCount,
        logs: _syncService.syncLog,
        lastSyncTime: (pushResult.success || pullResult.success) ? timeStr : state.lastSyncTime,
      );
    } else {
      if (!state.isOnline) {
        _addLog('ERROR: Không có kết nối mạng, bỏ qua sync.');
        return;
      }
      state = state.copyWith(isSyncing: true);
      _addLog('Bắt đầu đồng bộ dữ liệu...');
      await Future.delayed(const Duration(seconds: 2)); // simulate
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _addLog('Đồng bộ hoàn tất. ${state.pendingCount} bản ghi được xử lý.');
      state = state.copyWith(
        isSyncing: false,
        pendingCount: 0,
        lastSyncTime: timeStr,
      );
    }
  }

  void simulateOffline() {
    if (_syncService != null) {
      _syncService.simulateOffline();
    } else {
      state = state.copyWith(isOnline: false);
      _addLog('WARNING: Mất kết nối mạng. Chuyển sang chế độ offline.');
    }
  }

  void simulateOnline() {
    if (_syncService != null) {
      _syncService.simulateOnline();
    } else {
      state = state.copyWith(isOnline: true);
      _addLog('Kết nối mạng được khôi phục.');
    }
  }

  /// Xóa toàn bộ dữ liệu SQLite local, cập nhật UI qua state.
  Future<void> clearAllLocalData() async {
    if (_syncService != null) {
      state = state.copyWith(isSyncing: true, logs: _syncService.syncLog);
      try {
        await _syncService.clearAllLocalData();
        state = state.copyWith(
          isSyncing: false,
          pendingCount: 0,
          logs: _syncService.syncLog,
        );
      } catch (_) {
        state = state.copyWith(
          isSyncing: false,
          logs: _syncService.syncLog,
        );
      }
    } else {
      state = state.copyWith(isSyncing: true);
      _addLog('Bắt đầu xóa dữ liệu SQLite local...');
      await Future.delayed(const Duration(milliseconds: 500));
      _addLog('Đã xóa dữ liệu SQLite local thành công.');
      state = state.copyWith(isSyncing: false, pendingCount: 0);
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }
}

final syncNotifierServiceProvider = Provider<SyncService?>((ref) {
  return ref.watch(syncServiceProvider);
});

final syncStateProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncNotifierServiceProvider);
  return SyncNotifier(syncService: syncService);
});

