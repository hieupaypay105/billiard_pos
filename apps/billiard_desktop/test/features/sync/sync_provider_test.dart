import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billiard_desktop/features/sync/sync_provider.dart';
import 'package:billiard_desktop/core/services/sync_service.dart';
import 'package:billiard_desktop/core/services/local_db_service.dart';
import 'package:billiard_desktop/core/services/api_client.dart';

// A fake SyncService subclass that avoids real sqlite/connectivity plugins
class FakeSyncService extends SyncService {
  final _fakeStatusController = StreamController<ConnectivityStatus>.broadcast();
  final _fakeLogController = StreamController<String>.broadcast();
  ConnectivityStatus _fakeCurrentStatus = ConnectivityStatus.online;
  int _fakePendingCount = 2; // Start with some pending count to test syncNow decrement
  final List<String> _fakeSyncLog = [];

  FakeSyncService() : super(localDb: LocalDbService(), apiClient: ApiClient());

  @override
  Stream<ConnectivityStatus> get statusStream => _fakeStatusController.stream;

  @override
  Stream<String> get logStream => _fakeLogController.stream;

  @override
  ConnectivityStatus get currentStatus => _fakeCurrentStatus;

  @override
  bool get isOnline => _fakeCurrentStatus == ConnectivityStatus.online;

  @override
  int get pendingCount => _fakePendingCount;

  @override
  List<String> get syncLog => _fakeSyncLog;

  @override
  Future<void> initialize() async {
    _fakeSyncLog.add('FakeSyncService initialized');
  }

  @override
  Future<SyncResult> syncNow() async {
    _fakeSyncLog.add('FakeSyncService.syncNow called');
    _fakeLogController.add('FakeSyncService.syncNow called');
    _fakePendingCount = 0;
    return const SyncResult(success: true, message: 'Success', synced: 2);
  }

  @override
  Future<SyncResult> pullOnlineDataToOffline() async {
    _fakeSyncLog.add('FakeSyncService.pullOnlineDataToOffline called');
    _fakeLogController.add('FakeSyncService.pullOnlineDataToOffline called');
    return const SyncResult(success: true, message: 'Success', synced: 10);
  }

  @override
  void simulateOffline() {
    _fakeCurrentStatus = ConnectivityStatus.offline;
    _fakeStatusController.add(ConnectivityStatus.offline);
    _fakeSyncLog.add('FakeSyncService offline');
    _fakeLogController.add('FakeSyncService offline');
  }

  @override
  void simulateOnline() {
    _fakeCurrentStatus = ConnectivityStatus.online;
    _fakeStatusController.add(ConnectivityStatus.online);
    _fakeSyncLog.add('FakeSyncService online');
    _fakeLogController.add('FakeSyncService online');
  }

  @override
  Future<void> dispose() async {
    await _fakeStatusController.close();
    await _fakeLogController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncNotifier (Mock Mode)', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          syncNotifierServiceProvider.overrideWithValue(null),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is online with 0 pending', () {
      final state = container.read(syncStateProvider);
      expect(state.isOnline, isTrue);
      expect(state.pendingCount, 0);
      expect(state.isSyncing, isFalse);
    });

    test('simulateOffline changes status', () {
      container.read(syncStateProvider.notifier).simulateOffline();
      expect(container.read(syncStateProvider).isOnline, isFalse);
    });

    test('simulateOnline restores status', () {
      container.read(syncStateProvider.notifier).simulateOffline();
      container.read(syncStateProvider.notifier).simulateOnline();
      expect(container.read(syncStateProvider).isOnline, isTrue);
    });

    test('sync logs are appended', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      final logs = container.read(syncStateProvider).logs;
      expect(logs.isNotEmpty, isTrue);
    });

    test('syncNow when offline does not crash', () async {
      container.read(syncStateProvider.notifier).simulateOffline();
      await container.read(syncStateProvider.notifier).syncNow();
      expect(container.read(syncStateProvider).isSyncing, isFalse);
    });
  });

  group('SyncNotifier (Concrete SyncService Integration)', () {
    late ProviderContainer container;
    late FakeSyncService fakeSyncService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeSyncService = FakeSyncService();
      container = ProviderContainer(
        overrides: [
          syncNotifierServiceProvider.overrideWithValue(fakeSyncService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeSyncService.dispose();
    });

    test('initial state matches FakeSyncService status', () {
      final state = container.read(syncStateProvider);
      expect(state.isOnline, isTrue);
      expect(state.pendingCount, 2);
      expect(state.logs.contains('FakeSyncService initialized'), isTrue);
    });

    test('syncNow triggers syncService syncNow & pullOnlineDataToOffline and updates state', () async {
      final notifier = container.read(syncStateProvider.notifier);
      
      expect(container.read(syncStateProvider).isSyncing, isFalse);
      
      final future = notifier.syncNow();
      
      // Should briefly enter isSyncing state
      expect(container.read(syncStateProvider).isSyncing, isTrue);
      
      await future;
      
      final state = container.read(syncStateProvider);
      expect(state.isSyncing, isFalse);
      expect(state.pendingCount, 0);
      expect(state.logs.contains('FakeSyncService.syncNow called'), isTrue);
      expect(state.logs.contains('FakeSyncService.pullOnlineDataToOffline called'), isTrue);
      expect(state.lastSyncTime, isNotNull);
    });

    test('simulateOffline updates state status and logs through SyncService', () async {
      final notifier = container.read(syncStateProvider.notifier);
      notifier.simulateOffline();
      
      await Future.delayed(Duration.zero);
      
      final state = container.read(syncStateProvider);
      expect(state.isOnline, isFalse);
      expect(state.logs.contains('FakeSyncService offline'), isTrue);
    });

    test('simulateOnline updates state status and logs through SyncService', () async {
      final notifier = container.read(syncStateProvider.notifier);
      notifier.simulateOffline();
      await Future.delayed(Duration.zero);
      
      notifier.simulateOnline();
      await Future.delayed(Duration.zero);
      
      final state = container.read(syncStateProvider);
      expect(state.isOnline, isTrue);
      expect(state.logs.contains('FakeSyncService online'), isTrue);
    });
  });
}
