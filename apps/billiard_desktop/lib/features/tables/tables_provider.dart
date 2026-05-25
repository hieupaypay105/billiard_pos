import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/core_shared.dart';
import 'package:iot_controller/iot_controller.dart';
import '../../core/services/api_client.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/providers/providers.dart';
import '../sync/sync_provider.dart';


// ─── State ────────────────────────────────────────────────────────────────────

class TablesState {
  final List<TableModel> tables;
  final Map<String, IotConfigModel> iotConfigs;
  final Map<String, double> hourlyRates;
  final String? selectedTableId;
  final Map<String, DateTime> tableStartTimes;
  final Map<String, List<Map<String, dynamic>>> tableOrders;
  final Map<String, double> tableDiscounts;
  final Map<String, Map<String, dynamic>> tableMembers;
  final bool isLoading;
  final String? error;
  final bool useSimulator;

  const TablesState({
    this.tables = const [],
    this.iotConfigs = const {},
    // hourlyRates mặc định theo loại bàn: 1=Pool, 2=Carom, 3=Snooker
    this.hourlyRates = const {'1': 80000.0, '2': 90000.0, '3': 120000.0},
    this.selectedTableId,
    this.tableStartTimes = const {},
    this.tableOrders = const {},
    this.tableDiscounts = const {},
    this.tableMembers = const {},
    this.isLoading = false,
    this.error,
    this.useSimulator = true,
  });

  // Sử dụng Object? sentinel để phân biệt "không truyền" và "truyền null"
  static const _absent = Object();

  TablesState copyWith({
    List<TableModel>? tables,
    Map<String, IotConfigModel>? iotConfigs,
    Map<String, double>? hourlyRates,
    Object? selectedTableId = _absent,
    Map<String, DateTime>? tableStartTimes,
    Map<String, List<Map<String, dynamic>>>? tableOrders,
    Map<String, double>? tableDiscounts,
    Map<String, Map<String, dynamic>>? tableMembers,
    bool? isLoading,
    String? error,
    bool? useSimulator,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      iotConfigs: iotConfigs ?? this.iotConfigs,
      hourlyRates: hourlyRates ?? this.hourlyRates,
      selectedTableId: identical(selectedTableId, _absent)
          ? this.selectedTableId
          : selectedTableId as String?,
      tableStartTimes: tableStartTimes ?? this.tableStartTimes,
      tableOrders: tableOrders ?? this.tableOrders,
      tableDiscounts: tableDiscounts ?? this.tableDiscounts,
      tableMembers: tableMembers ?? this.tableMembers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      useSimulator: useSimulator ?? this.useSimulator,
    );
  }

  /// Bàn đang được chọn; null nếu danh sách rỗng hoặc chưa chọn.
  TableModel? get selectedTable {
    if (tables.isEmpty) return null;
    if (selectedTableId == null) return null;
    return tables.firstWhere(
      (t) => t.id == selectedTableId,
      orElse: () => tables.first,
    );
  }

  Duration playDuration(String tableId) {
    final start = tableStartTimes[tableId];
    if (start == null) return Duration.zero;
    return DateTime.now().difference(start);
  }

  double playCost(String tableId) {
    if (tables.isEmpty) return 0.0;
    final table = tables.firstWhere(
      (t) => t.id == tableId,
      orElse: () => tables.first,
    );
    final rate = hourlyRates[table.tableTypeId.toString()] ?? 80000.0;
    return (playDuration(tableId).inSeconds / 3600.0) * rate;
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TablesNotifier extends StateNotifier<TablesState> {
  final Map<String, BilliardIoTController> _controllers = {};
  final LocalDbService? _localDb;
  final ApiClient? _apiClient;
  final SyncService? _syncService;

  TablesNotifier({
    LocalDbService? localDb,
    ApiClient? apiClient,
    SyncService? syncService,
  })  : _localDb = localDb,
        _apiClient = apiClient,
        _syncService = syncService,
        super(const TablesState()) {
    loadTables();
  }

  Future<void> loadTables({bool preventAutoPull = false}) async {
    state = state.copyWith(isLoading: true);

    // ── Nguồn duy nhất: SQLite local DB ──────────────────────────────────────
    if (_localDb != null) {
      try {
        final cachedTables = await _localDb!.getCachedTables();
        if (cachedTables.isNotEmpty) {
          final loadedTables =
              cachedTables.map((e) => TableModel.fromJson(e)).toList();
          loadedTables.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          // Load IoT Configs from local cache
          final Map<String, IotConfigModel> loadedIotConfigs = {};
          final cachedIot = await _localDb!.getCachedIotConfigs();
          if (cachedIot.isNotEmpty) {
            for (final item in cachedIot) {
              final config = IotConfigModel.fromJson(item);
              loadedIotConfigs[config.tableId] = config;
            }
          }

          // Load Table Prices from local cache and map to hourlyRates
          final Map<String, double> loadedHourlyRates = Map<String, double>.from(state.hourlyRates);
          final cachedPrices = await _localDb!.getCachedTablePrices();
          if (cachedPrices.isNotEmpty) {
            final prices = cachedPrices.map((e) => TablePriceModel.fromJson(e)).toList();
            for (final p in prices) {
              if (p.isActive) {
                loadedHourlyRates[p.tableTypeId.toString()] = p.pricePerHour;
              }
            }
          }

          state = state.copyWith(
            tables: loadedTables,
            selectedTableId: loadedTables.first.id,
            iotConfigs: loadedIotConfigs.isNotEmpty ? loadedIotConfigs : state.iotConfigs,
            hourlyRates: loadedHourlyRates,
          );
        } else {
          // Cache trống (sau khi xóa dữ liệu local): xóa hết session và dùng mock data làm fallback
          _initMockData();

          // Tự động tải dữ liệu từ server khi cache trống và có mạng
          if (!preventAutoPull && _syncService != null && _syncService!.isOnline) {
            _syncService!.pullOnlineDataToOffline().then((result) {
              if (result.success) {
                loadTables(preventAutoPull: true);
              }
            });
          }
        }
      } catch (e) {
        state = state.copyWith(error: e.toString(), isLoading: false);
        return;
      }
    } else {
      // Không có DB (môi trường test): dùng mock data làm fallback
      _initMockData();
    }

    state = state.copyWith(isLoading: false);
  }

  void _initMockData() {
    final hourlyRates = {'1': 80000.0, '2': 90000.0, '3': 120000.0};

    final tables = [
      const TableModel(id: 't-1', tableName: 'Bàn 01 (Pool)', areaId: 1, tableTypeId: 1, status: 'idle', sortOrder: 1),
      const TableModel(id: 't-2', tableName: 'Bàn 02 (Pool)', areaId: 1, tableTypeId: 1, status: 'idle', sortOrder: 2),
      const TableModel(id: 't-3', tableName: 'Bàn 03 (Pool)', areaId: 1, tableTypeId: 1, status: 'idle', sortOrder: 3),
      const TableModel(id: 't-4', tableName: 'Bàn 04 (Carom)', areaId: 2, tableTypeId: 2, status: 'idle', sortOrder: 4),
      const TableModel(id: 't-5', tableName: 'Bàn 05 (Carom)', areaId: 2, tableTypeId: 2, status: 'idle', sortOrder: 5),
      const TableModel(id: 't-6', tableName: 'Bàn 06 (Snooker)', areaId: 3, tableTypeId: 3, status: 'idle', sortOrder: 6),
      const TableModel(id: 't-7', tableName: 'Bàn VIP 01', areaId: 4, tableTypeId: 1, status: 'idle', sortOrder: 7),
      const TableModel(id: 't-8', tableName: 'Bàn VIP 02', areaId: 4, tableTypeId: 2, status: 'idle', sortOrder: 8),
    ];

    final iotConfigs = {
      't-1': const IotConfigModel(id: 1, tableId: 't-1', connectionType: 'serial', port: 'COM1', relayChannel: 1, commandOn: '01050000FF008C3A', commandOff: '010500000000CDCA'),
      't-2': const IotConfigModel(id: 2, tableId: 't-2', connectionType: 'serial', port: 'COM2', relayChannel: 2, commandOn: '01050001FF00DDFA', commandOff: '0105000100009C0A'),
      't-3': const IotConfigModel(id: 3, tableId: 't-3', connectionType: 'serial', port: 'COM3', relayChannel: 3, commandOn: '01050002FF002DFA', commandOff: '0105000200006C0A'),
      't-4': const IotConfigModel(id: 4, tableId: 't-4', connectionType: 'tcp_ip', ipAddress: '192.168.1.150', port: '8080', relayChannel: 1, commandOn: '01050000FF008C3A', commandOff: '010500000000CDCA'),
      't-5': const IotConfigModel(id: 5, tableId: 't-5', connectionType: 'tcp_ip', ipAddress: '192.168.1.150', port: '8080', relayChannel: 2, commandOn: '01050001FF00DDFA', commandOff: '0105000100009C0A'),
      't-6': const IotConfigModel(id: 6, tableId: 't-6', connectionType: 'tcp_ip', ipAddress: '192.168.1.160', port: '9000', relayChannel: 1, commandOn: '01050000FF008C3A', commandOff: '010500000000CDCA'),
      't-7': const IotConfigModel(id: 7, tableId: 't-7', connectionType: 'tcp_ip', ipAddress: '192.168.1.160', port: '9000', relayChannel: 2, commandOn: '01050001FF00DDFA', commandOff: '0105000100009C0A'),
      't-8': const IotConfigModel(id: 8, tableId: 't-8', connectionType: 'tcp_ip', ipAddress: '192.168.1.160', port: '9000', relayChannel: 3, commandOn: '01050002FF002DFA', commandOff: '0105000200006C0A'),
    };

    state = state.copyWith(
      tables: tables,
      iotConfigs: iotConfigs,
      hourlyRates: hourlyRates,
      selectedTableId: tables.first.id,
    );
  }

  void selectTable(String tableId) {
    state = state.copyWith(selectedTableId: tableId);
  }

  void toggleSimulator(bool useSimulator) {
    state = state.copyWith(useSimulator: useSimulator);
  }

  Future<bool> activateTable(String tableId, {bool ignoreIotError = false}) async {
    final tableIndex = state.tables.indexWhere((t) => t.id == tableId);
    if (tableIndex < 0) return false;

    final iotConfig = state.iotConfigs[tableId];
    if (iotConfig == null) {
      if (!ignoreIotError) return false;
    } else {
      final controller = state.useSimulator
          ? SimulatedBilliardIoTController() as BilliardIoTController
          : RealBilliardIoTController();
      _controllers[tableId] = controller;

      try {
        final connected = await controller.connect(iotConfig);
        if (!connected && !ignoreIotError) return false;

        if (connected) {
          final turnedOn = await controller.turnOn();
          if (!turnedOn && !ignoreIotError) return false;
        }
      } catch (e) {
        if (!ignoreIotError) return false;
      }
    }

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[tableIndex] = state.tables[tableIndex].copyWith(
      status: 'active',
      currentOrderId: 'ord-${DateTime.now().millisecondsSinceEpoch}',
    );

    final updatedStartTimes =
        Map<String, DateTime>.from(state.tableStartTimes);
    updatedStartTimes[tableId] = DateTime.now();

    final updatedOrders =
        Map<String, List<Map<String, dynamic>>>.from(state.tableOrders);
    updatedOrders[tableId] = [];

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
    );
    return true;
  }

  Future<bool> deactivateTable(String tableId) async {
    final controller = _controllers[tableId];
    if (controller != null) {
      await controller.turnOff();
      await controller.disconnect();
      _controllers.remove(tableId);
    }

    final tableIndex = state.tables.indexWhere((t) => t.id == tableId);
    if (tableIndex < 0) return false;

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[tableIndex] = state.tables[tableIndex].copyWith(
      status: 'idle',
      clearCurrentOrderId: true,
    );

    final updatedStartTimes =
        Map<String, DateTime>.from(state.tableStartTimes);
    updatedStartTimes.remove(tableId);

    final updatedOrders =
        Map<String, List<Map<String, dynamic>>>.from(state.tableOrders);
    updatedOrders.remove(tableId);

    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts);
    updatedDiscounts.remove(tableId);

    final updatedMembers = Map<String, Map<String, dynamic>>.from(state.tableMembers);
    updatedMembers.remove(tableId);

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tableDiscounts: updatedDiscounts,
      tableMembers: updatedMembers,
    );
    return true;
  }

  void applyDiscount(String tableId, double percent) {
    final updated = Map<String, double>.from(state.tableDiscounts);
    updated[tableId] = percent;
    state = state.copyWith(tableDiscounts: updated);
  }

  void removeDiscount(String tableId) {
    final updated = Map<String, double>.from(state.tableDiscounts);
    updated.remove(tableId);
    state = state.copyWith(tableDiscounts: updated);
  }

  void applyMember(String tableId, Map<String, dynamic> member) {
    final updated = Map<String, Map<String, dynamic>>.from(state.tableMembers);
    updated[tableId] = member;
    state = state.copyWith(tableMembers: updated);
  }

  void removeMember(String tableId) {
    final updated = Map<String, Map<String, dynamic>>.from(state.tableMembers);
    updated.remove(tableId);
    state = state.copyWith(tableMembers: updated);
  }

  Future<bool> transferTable(String sourceTableId, String targetTableId) async {
    final sourceIndex = state.tables.indexWhere((t) => t.id == sourceTableId);
    final targetIndex = state.tables.indexWhere((t) => t.id == targetTableId);
    if (sourceIndex < 0 || targetIndex < 0) return false;

    final sourceTable = state.tables[sourceIndex];
    final targetTable = state.tables[targetIndex];
    if (sourceTable.status != 'active' || targetTable.status != 'idle') return false;

    final iotConfig = state.iotConfigs[targetTableId];
    if (iotConfig == null) return false;

    final controller = state.useSimulator
        ? SimulatedBilliardIoTController() as BilliardIoTController
        : RealBilliardIoTController();
    
    final connected = await controller.connect(iotConfig);
    if (!connected) return false;

    final turnedOn = await controller.turnOn();
    if (!turnedOn) {
      await controller.disconnect();
      return false;
    }

    _controllers[targetTableId] = controller;

    final sourceController = _controllers[sourceTableId];
    if (sourceController != null) {
      await sourceController.turnOff();
      await sourceController.disconnect();
      _controllers.remove(sourceTableId);
    }

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[sourceIndex] = sourceTable.copyWith(
      status: 'idle',
      clearCurrentOrderId: true,
    );
    updatedTables[targetIndex] = targetTable.copyWith(
      status: 'active',
      currentOrderId: sourceTable.currentOrderId ?? 'ord-${DateTime.now().millisecondsSinceEpoch}',
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes);
    final startTime = updatedStartTimes.remove(sourceTableId);
    if (startTime != null) {
      updatedStartTimes[targetTableId] = startTime;
    }

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(state.tableOrders);
    final orders = updatedOrders.remove(sourceTableId);
    if (orders != null) {
      updatedOrders[targetTableId] = orders;
    }

    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts);
    final discount = updatedDiscounts.remove(sourceTableId);
    if (discount != null) {
      updatedDiscounts[targetTableId] = discount;
    }

    final updatedMembers = Map<String, Map<String, dynamic>>.from(state.tableMembers);
    final member = updatedMembers.remove(sourceTableId);
    if (member != null) {
      updatedMembers[targetTableId] = member;
    }

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tableDiscounts: updatedDiscounts,
      tableMembers: updatedMembers,
    );

    return true;
  }

  Future<bool> mergeTable(String sourceTableId, String targetTableId) async {
    final sourceIndex = state.tables.indexWhere((t) => t.id == sourceTableId);
    final targetIndex = state.tables.indexWhere((t) => t.id == targetTableId);
    if (sourceIndex < 0 || targetIndex < 0) return false;

    final sourceTable = state.tables[sourceIndex];
    final targetTable = state.tables[targetIndex];
    if (sourceTable.status != 'active' || targetTable.status != 'active') return false;

    final sourcePlayCost = state.playCost(sourceTableId);

    final sourceController = _controllers[sourceTableId];
    if (sourceController != null) {
      await sourceController.turnOff();
      await sourceController.disconnect();
      _controllers.remove(sourceTableId);
    }

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[sourceIndex] = sourceTable.copyWith(
      status: 'idle',
      clearCurrentOrderId: true,
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes);
    updatedStartTimes.remove(sourceTableId);

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(state.tableOrders);
    final sourceItems = updatedOrders.remove(sourceTableId) ?? [];
    final targetItems = List<Map<String, dynamic>>.from(updatedOrders[targetTableId] ?? []);

    if (sourcePlayCost > 0) {
      targetItems.add({
        'product_id': 'merged-playtime-$sourceTableId',
        'name': 'Tiền giờ gộp từ ${sourceTable.tableName}',
        'price': sourcePlayCost,
        'qty': 1,
      });
    }

    for (final item in sourceItems) {
      final existingIndex = targetItems.indexWhere((p) => p['product_id'] == item['product_id']);
      if (existingIndex >= 0) {
        targetItems[existingIndex] = {
          ...targetItems[existingIndex],
          'qty': (targetItems[existingIndex]['qty'] as int) + (item['qty'] as int),
        };
      } else {
        targetItems.add(Map<String, dynamic>.from(item));
      }
    }
    updatedOrders[targetTableId] = targetItems;

    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts);
    updatedDiscounts.remove(sourceTableId);

    final updatedMembers = Map<String, Map<String, dynamic>>.from(state.tableMembers);
    updatedMembers.remove(sourceTableId);

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tableDiscounts: updatedDiscounts,
      tableMembers: updatedMembers,
    );

    return true;
  }

  void setTableMaintenance(String tableId, bool isMaintenance) {
    final index = state.tables.indexWhere((t) => t.id == tableId);
    if (index < 0) return;
    final updated = List<TableModel>.from(state.tables);
    updated[index] = state.tables[index]
        .copyWith(status: isMaintenance ? 'maintenance' : 'idle');
    state = state.copyWith(tables: updated);
  }

  void addProductToTable(String tableId, Map<String, dynamic> product) {
    final updatedOrders =
        Map<String, List<Map<String, dynamic>>>.from(state.tableOrders);
    final items = List<Map<String, dynamic>>.from(
        updatedOrders[tableId] ?? []);

    final existing = items.indexWhere(
        (p) => p['product_id'] == product['product_id']);
    if (existing >= 0) {
      items[existing] = {
        ...items[existing],
        'qty': (items[existing]['qty'] as int) + (product['qty'] as int? ?? 1),
      };
    } else {
      items.add({...product, 'qty': product['qty'] ?? 1});
    }

    updatedOrders[tableId] = items;
    state = state.copyWith(tableOrders: updatedOrders);
  }

  void removeProductFromTable(String tableId, String productId) {
    final updatedOrders =
        Map<String, List<Map<String, dynamic>>>.from(state.tableOrders);
    final items = List<Map<String, dynamic>>.from(
        updatedOrders[tableId] ?? []);
    items.removeWhere((p) => p['product_id'] == productId);
    updatedOrders[tableId] = items;
    state = state.copyWith(tableOrders: updatedOrders);
  }

  void updateIotConfig(String tableId, IotConfigModel config) {
    final updated = Map<String, IotConfigModel>.from(state.iotConfigs);
    updated[tableId] = config;
    state = state.copyWith(iotConfigs: updated);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.disconnect();
    }
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final tablesProvider =
    StateNotifierProvider<TablesNotifier, TablesState>((ref) {
  final localDb = ref.watch(localDbServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final syncService = ref.watch(syncServiceProvider);
  final notifier = TablesNotifier(
    localDb: localDb,
    apiClient: apiClient,
    syncService: syncService,
  );

  // Tự động reload bàn khi sync hoàn tất hoặc cache bị xóa
  ref.listen<SyncState>(syncStateProvider, (prev, next) {
    final wasSyncing = prev?.isSyncing ?? false;
    final doneSyncing = wasSyncing && !next.isSyncing;
    if (doneSyncing) {
      notifier.loadTables();
    }
  });

  return notifier;
});

final selectedTableProvider = Provider<TableModel?>((ref) {
  return ref.watch(tablesProvider).selectedTable;
});

final activeTablesCountProvider = Provider<int>((ref) {
  return ref
      .watch(tablesProvider)
      .tables
      .where((t) => t.status == 'active')
      .length;
});
