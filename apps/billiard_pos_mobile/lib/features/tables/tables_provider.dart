import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_shared/core_shared.dart';
import 'package:iot_controller/iot_controller.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/api_client.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/providers/providers.dart';
import '../sync/sync_provider.dart';
import 'shift_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class UnpaidInvoice {
  final String id;
  final String tableId;
  final String tableName;
  final DateTime startTime;
  final DateTime endTime;
  final int playMinutes;
  final double playAmount;
  final double hourlyRate;
  final List<Map<String, dynamic>> products;
  final double manualDiscountPercent; // Deprecated fallback
  final double discountPlayPercent;
  final double discountServicePercent;
  final double discountBillPercent;
  final Map<String, dynamic>? member;
  final String? note;

  const UnpaidInvoice({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.startTime,
    required this.endTime,
    required this.playMinutes,
    required this.playAmount,
    required this.hourlyRate,
    required this.products,
    this.manualDiscountPercent = 0.0,
    this.discountPlayPercent = 0.0,
    this.discountServicePercent = 0.0,
    this.discountBillPercent = 0.0,
    this.member,
    this.note,
  });

  UnpaidInvoice copyWith({
    String? id,
    String? tableId,
    String? tableName,
    DateTime? startTime,
    DateTime? endTime,
    int? playMinutes,
    double? playAmount,
    double? hourlyRate,
    List<Map<String, dynamic>>? products,
    double? manualDiscountPercent,
    double? discountPlayPercent,
    double? discountServicePercent,
    double? discountBillPercent,
    Map<String, dynamic>? member,
    bool clearMember = false,
    String? note,
  }) {
    return UnpaidInvoice(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      playMinutes: playMinutes ?? this.playMinutes,
      playAmount: playAmount ?? this.playAmount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      products: products ?? this.products,
      manualDiscountPercent:
          manualDiscountPercent ?? this.manualDiscountPercent,
      discountPlayPercent: discountPlayPercent ?? this.discountPlayPercent,
      discountServicePercent:
          discountServicePercent ?? this.discountServicePercent,
      discountBillPercent: discountBillPercent ?? this.discountBillPercent,
      member: clearMember ? null : (member ?? this.member),
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'tableName': tableName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'playMinutes': playMinutes,
      'playAmount': playAmount,
      'hourlyRate': hourlyRate,
      'products': products,
      'manualDiscountPercent': manualDiscountPercent,
      'discountPlayPercent': discountPlayPercent,
      'discountServicePercent': discountServicePercent,
      'discountBillPercent': discountBillPercent,
      'member': member,
      'note': note,
    };
  }

  factory UnpaidInvoice.fromJson(Map<String, dynamic> json) {
    final double playPct = (json['discountPlayPercent'] as num?)?.toDouble() ?? 0.0;
    final double svcPct = (json['discountServicePercent'] as num?)?.toDouble() ?? 0.0;
    final double fallbackManual = (json['manualDiscountPercent'] as num?)?.toDouble() ?? 0.0;
    final double billPct = (json['discountBillPercent'] as num?)?.toDouble() ?? fallbackManual;
    
    return UnpaidInvoice(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      tableName: json['tableName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      playMinutes: json['playMinutes'] as int,
      playAmount: (json['playAmount'] as num).toDouble(),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      products: List<Map<String, dynamic>>.from(json['products'] as List),
      manualDiscountPercent: fallbackManual,
      discountPlayPercent: playPct,
      discountServicePercent: svcPct,
      discountBillPercent: billPct,
      member: json['member'] as Map<String, dynamic>?,
      note: json['note'] as String?,
    );
  }
}

class TablesState {
  final List<TableModel> tables;
  final Map<String, IotConfigModel> iotConfigs;
  final Map<String, double> hourlyRates;
  final Map<String, double> tableCustomRates;
  final String? selectedTableId;
  final Map<String, DateTime> tableStartTimes;
  final Map<String, List<Map<String, dynamic>>> tableOrders;
  final Map<String, List<Map<String, dynamic>>> tablePendingOrders;
  final String? connectedIp;
  final Map<String, double> tableDiscounts; // Deprecated fallback
  final Map<String, double> tablePlayDiscounts;
  final Map<String, double> tableServiceDiscounts;
  final Map<String, double> tableBillDiscounts;
  final Map<String, Map<String, dynamic>> tableMembers;
  final bool isLoading;
  final String? error;
  final bool useSimulator;
  final List<TableTypeModel> tableTypes;
  final List<UnpaidInvoice> unpaidInvoices;
  final String? selectedUnpaidInvoiceId;
  final List<TablePriceModel> tablePrices;

  /// Map tableId → server order ID (lấy từ backend khi gọi POST /order/open).
  final Map<String, String> tableServerOrderIds;

  final Map<String, double> tableExtraPlayAmounts;
  final Map<String, int> tableExtraPlayMinutes;
  final Map<String, String> tableNotes;

  const TablesState({
    this.tables = const [],
    this.iotConfigs = const {},
    // hourlyRates mặc định theo loại bàn: 1=Pool, 2=Carom, 3=Snooker
    // this.hourlyRates = const {'1': 85000.0, '2': 90000.0, '3': 120000.0},
    this.hourlyRates = const {'1': 85000.0},
    this.tableCustomRates = const {},
    this.selectedTableId,
    this.tableStartTimes = const {},
    this.tableOrders = const {},
    this.tablePendingOrders = const {},
    this.connectedIp,
    this.tableDiscounts = const {},
    this.tablePlayDiscounts = const {},
    this.tableServiceDiscounts = const {},
    this.tableBillDiscounts = const {},
    this.tableMembers = const {},
    this.isLoading = false,
    this.error,
    this.useSimulator = true,
    this.tableTypes = const [
      TableTypeModel(id: 1, typeName: 'Pool (Bàn lỗ)'),
      // TableTypeModel(id: 2, typeName: 'Carom (Băng)'),
      // TableTypeModel(id: 3, typeName: 'Snooker'),
    ],
    this.unpaidInvoices = const [],
    this.selectedUnpaidInvoiceId,
    this.tablePrices = const [],
    this.tableServerOrderIds = const {},
    this.tableExtraPlayAmounts = const {},
    this.tableExtraPlayMinutes = const {},
    this.tableNotes = const {},
  });

  // Sử dụng Object? sentinel để phân biệt "không truyền" và "truyền null"
  static const _absent = Object();

  TablesState copyWith({
    List<TableModel>? tables,
    Map<String, IotConfigModel>? iotConfigs,
    Map<String, double>? hourlyRates,
    Map<String, double>? tableCustomRates,
    Object? selectedTableId = _absent,
    Map<String, DateTime>? tableStartTimes,
    Map<String, List<Map<String, dynamic>>>? tableOrders,
    Map<String, List<Map<String, dynamic>>>? tablePendingOrders,
    Object? connectedIp = _absent,
    Map<String, double>? tableDiscounts,
    Map<String, double>? tablePlayDiscounts,
    Map<String, double>? tableServiceDiscounts,
    Map<String, double>? tableBillDiscounts,
    Map<String, Map<String, dynamic>>? tableMembers,
    bool? isLoading,
    String? error,
    bool? useSimulator,
    List<TableTypeModel>? tableTypes,
    List<UnpaidInvoice>? unpaidInvoices,
    Object? selectedUnpaidInvoiceId = _absent,
    List<TablePriceModel>? tablePrices,
    Map<String, String>? tableServerOrderIds,
    Map<String, double>? tableExtraPlayAmounts,
    Map<String, int>? tableExtraPlayMinutes,
    Map<String, String>? tableNotes,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      iotConfigs: iotConfigs ?? this.iotConfigs,
      hourlyRates: hourlyRates ?? this.hourlyRates,
      tableCustomRates: tableCustomRates ?? this.tableCustomRates,
      selectedTableId: identical(selectedTableId, _absent)
          ? this.selectedTableId
          : selectedTableId as String?,
      tableStartTimes: tableStartTimes ?? this.tableStartTimes,
      tableOrders: tableOrders ?? this.tableOrders,
      tablePendingOrders: tablePendingOrders ?? this.tablePendingOrders,
      connectedIp: identical(connectedIp, _absent)
          ? this.connectedIp
          : connectedIp as String?,
      tableDiscounts: tableDiscounts ?? this.tableDiscounts,
      tablePlayDiscounts: tablePlayDiscounts ?? this.tablePlayDiscounts,
      tableServiceDiscounts:
          tableServiceDiscounts ?? this.tableServiceDiscounts,
      tableBillDiscounts: tableBillDiscounts ?? this.tableBillDiscounts,
      tableMembers: tableMembers ?? this.tableMembers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      useSimulator: useSimulator ?? this.useSimulator,
      tableTypes: tableTypes ?? this.tableTypes,
      unpaidInvoices: unpaidInvoices ?? this.unpaidInvoices,
      selectedUnpaidInvoiceId: identical(selectedUnpaidInvoiceId, _absent)
          ? this.selectedUnpaidInvoiceId
          : selectedUnpaidInvoiceId as String?,
      tablePrices: tablePrices ?? this.tablePrices,
      tableServerOrderIds: tableServerOrderIds ?? this.tableServerOrderIds,
      tableExtraPlayAmounts:
          tableExtraPlayAmounts ?? this.tableExtraPlayAmounts,
      tableExtraPlayMinutes:
          tableExtraPlayMinutes ?? this.tableExtraPlayMinutes,
      tableNotes: tableNotes ?? this.tableNotes,
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

  double getTableHourlyRate(TableModel table, [DateTime? time]) {
    final customRate = tableCustomRates[table.id];
    if (customRate != null && customRate > 0) {
      return customRate;
    }

    final targetTime = time ?? DateTime.now();
    final typeId = table.tableTypeId;

    if (tablePrices.isNotEmpty) {
      final matchingPrices = tablePrices.where((p) {
        if (p.tableTypeId != typeId) return false;
        if (!p.isActive) return false;

        // Check day of week (Monday is 1, Sunday is 7)
        if (p.daysOfWeek != null && p.daysOfWeek!.isNotEmpty) {
          if (!p.daysOfWeek!.contains(targetTime.weekday)) {
            return false;
          }
        }

        // Check hours: startHour and endHour format is 'HH:mm:ss'
        try {
          final startParts = p.startHour.split(':');
          final endParts = p.endHour.split(':');

          final sh = int.parse(startParts[0]);
          final sm = int.parse(startParts[1]);
          final ss = startParts.length > 2 ? int.parse(startParts[2]) : 0;

          final eh = int.parse(endParts[0]);
          final em = int.parse(endParts[1]);
          final es = endParts.length > 2 ? int.parse(endParts[2]) : 0;

          final targetSecs =
              targetTime.hour * 3600 +
              targetTime.minute * 60 +
              targetTime.second;
          final startSecs = sh * 3600 + sm * 60 + ss;
          final endSecs = eh * 3600 + em * 60 + es;

          if (targetSecs < startSecs || targetSecs > endSecs) {
            return false;
          }
        } catch (_) {
          // Ignore time check if parsing fails
        }

        return true;
      }).toList();

      if (matchingPrices.isNotEmpty) {
        matchingPrices.sort((a, b) => b.priority.compareTo(a.priority));
        return matchingPrices.first.pricePerHour;
      }
    }

    return hourlyRates[typeId.toString()] ?? 85000.0;
  }

  double playCost(String tableId) {
    if (tables.isEmpty) return 0.0;
    final table = tables.firstWhere(
      (t) => t.id == tableId,
      orElse: () => tables.first,
    );
    final rate = getTableHourlyRate(table);
    final baseCost = (playDuration(tableId).inSeconds / 3600.0) * rate;
    return baseCost + (tableExtraPlayAmounts[tableId] ?? 0.0);
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TablesNotifier extends StateNotifier<TablesState> {
  final Map<String, BilliardIoTController> _controllers = {};
  final LocalDbService? _localDb;
  final ApiClient? _apiClient;
  final SyncService? _syncService;
  final SharedPreferences? _prefs;
  Timer? _syncTimer;
  WebSocket? _ws;
  Timer? _reconnectTimer;
  String? _connectedIp;
  String? _lastSessionStr;

  bool get _isOnline => _syncService?.isOnline ?? true;

  TablesNotifier({
    LocalDbService? localDb,
    ApiClient? apiClient,
    SyncService? syncService,
    SharedPreferences? prefs,
  }) : _localDb = localDb,
       _apiClient = apiClient,
       _syncService = syncService,
       _prefs = prefs,
       super(const TablesState()) {
    loadTables();
    _startSyncTimer();
    _connectWebSocket();
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final prefs = _prefs;
      final desktopIp = prefs?.getString('desktop_server_ip') ?? '';
      if (desktopIp.isNotEmpty) {
        await loadTables(preventAutoPull: true, isSilent: true);
      }
    });
  }

  void _connectWebSocket() {
    _ws?.close();
    _reconnectTimer?.cancel();

    final prefs = _prefs;
    final desktopIp = prefs?.getString('desktop_server_ip') ?? '';
    if (desktopIp.isEmpty) return;

    try {
      final deviceId = prefs?.getString('device_id') ?? '';
      WebSocket.connect(
        'ws://$desktopIp:8085/ws',
        headers: {'x-device-id': deviceId},
      ).then((socket) {
        _ws = socket;
        print("Đã kết nối WebSocket tới Desktop Server");
        
        socket.listen((message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            if (data['event'] == 'session_updated') {
              print("Nhận sự kiện session_updated từ Desktop: Reloading...");
              loadTables(preventAutoPull: true, isSilent: true);
            }
          } catch (e) {
            print("Lỗi xử lý tin nhắn WebSocket: $e");
          }
        }, onDone: () {
          print("Mất kết nối WebSocket tới Desktop, đang kết nối lại...");
          _scheduleReconnect();
        }, onError: (e) {
          print("Lỗi kết nối WebSocket: $e, đang kết nối lại...");
          _scheduleReconnect();
        });
      }).catchError((e) {
        print("Lỗi kết nối WebSocket tới Desktop: $e");
        _scheduleReconnect();
      });
    } catch (e) {
      print("Lỗi khởi tạo kết nối WebSocket: $e");
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _connectWebSocket();
    });
  }

  Future<void> loadTables({bool preventAutoPull = false, bool isSilent = false}) async {
    if (!isSilent) {
      state = state.copyWith(isLoading: true);
    }

    // ── Check if connected to Desktop Server ──────────────────────────────────
    final prefs = _prefs;
    final desktopIp = prefs?.getString('desktop_server_ip') ?? '';
    if (desktopIp != _connectedIp) {
      _connectedIp = desktopIp;
      _connectWebSocket();
    }
    if (desktopIp.isNotEmpty) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        final request = await client.getUrl(Uri.parse('http://$desktopIp:8085/api/session'));
        final deviceId = prefs?.getString('device_id') ?? '';
        if (deviceId.isNotEmpty) {
          request.headers.add('x-device-id', deviceId);
        }
        final response = await request.close();
        if (response.statusCode == 403) {
          print("Connection unauthorized. Disconnecting.");
          await prefs?.remove('desktop_server_ip');
          _connectedIp = null;
          _ws?.close();
          state = state.copyWith(connectedIp: null);
          return;
        }
        if (response.statusCode == 200) {
          final body = await utf8.decodeStream(response);
          final res = jsonDecode(body) as Map<String, dynamic>;
          if (res['status'] == 1 && _localDb != null) {
            final sessionStr = res['session'] as String?;
            if (isSilent && sessionStr != null && sessionStr == _lastSessionStr) {
              // No change in session data, skip updates to prevent UI stutter/rebuilds
              return;
            }
            _lastSessionStr = sessionStr;

            // Write caches to local storage only during explicit/initial reload to avoid UI freeze/stutter
            if (!isSilent) {
              if (res['tables'] != null) {
                await _localDb!.clearCachedTables();
                for (final t in res['tables'] as List) {
                  final tableMap = Map<String, dynamic>.from(t as Map);
                  await _localDb!.cacheTable(tableMap['id'].toString(), tableMap);
                }
              }
              if (res['products'] != null) {
                await _localDb!.clearCachedProducts();
                await _localDb!.cacheProducts(List<Map<String, dynamic>>.from(
                  (res['products'] as List).map((e) => Map<String, dynamic>.from(e as Map))
                ));
              }
              if (res['categories'] != null) {
                await _localDb!.clearCachedProductCategories();
                await _localDb!.cacheProductCategories(List<Map<String, dynamic>>.from(
                  (res['categories'] as List).map((e) => Map<String, dynamic>.from(e as Map))
                ));
              }
              if (res['members'] != null) {
                await _localDb!.clearCachedMembers();
                await _localDb!.cacheMembers(List<Map<String, dynamic>>.from(
                  (res['members'] as List).map((e) => Map<String, dynamic>.from(e as Map))
                ));
              }
              if (res['prices'] != null) {
                await _localDb!.clearCachedTablePrices();
                await _localDb!.cacheTablePrices(List<Map<String, dynamic>>.from(
                  (res['prices'] as List).map((e) => Map<String, dynamic>.from(e as Map))
                ));
              }
              if (res['types'] != null) {
                await _localDb!.clearCachedTableTypes();
                await _localDb!.cacheTableTypes(List<Map<String, dynamic>>.from(
                  (res['types'] as List).map((e) => Map<String, dynamic>.from(e as Map))
                ));
              }
              if (res['tiers'] != null) {
                await _localDb!.clearCachedMembershipTiers();
                await _localDb!.cacheMembershipTiers(List<Map<String, dynamic>>.from(
                  (res['tiers'] as List).map((e) => Map<String, dynamic>.from(e as Map))
                ));
              }
              if (res['invoice_template'] != null) {
                await _localDb!.clearInvoiceTemplate();
                await _localDb!.saveInvoiceTemplate(Map<String, dynamic>.from(res['invoice_template'] as Map));
              }
            }
            
            if (sessionStr != null) {
              await _localDb!.setSetting('billiard_active_session', sessionStr);
            } else {
              await _localDb!.setSetting('billiard_active_session', '{}');
            }
          }
        }
      } catch (e) {
        print("Lỗi đồng bộ từ Desktop: $e");
      }
    }

    // ── Nguồn duy nhất: SQLite local DB ──────────────────────────────────────
    if (_localDb != null) {
      try {
        final cachedTables = await _localDb!.getCachedTables();
        if (cachedTables.isNotEmpty) {
          final loadedTables = cachedTables
              .map((e) => TableModel.fromJson(e))
              .toList();
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
          final Map<String, double> loadedHourlyRates =
              Map<String, double>.from(state.hourlyRates);
          final cachedPrices = await _localDb!.getCachedTablePrices();
          final List<TablePriceModel> loadedPrices = [];
          if (cachedPrices.isNotEmpty) {
            final prices = cachedPrices
                .map((e) => TablePriceModel.fromJson(e))
                .toList();
            loadedPrices.addAll(prices);
            for (final p in prices) {
              if (p.isActive) {
                loadedHourlyRates[p.tableTypeId.toString()] = p.pricePerHour;
              }
            }
          }

          // Load Table Types from local cache
          final List<TableTypeModel> loadedTableTypes = [];
          final cachedTypes = await _localDb!.getCachedTableTypes();
          if (cachedTypes.isNotEmpty) {
            loadedTableTypes.addAll(
              cachedTypes.map((e) => TableTypeModel.fromJson(e)),
            );
          }

          // Load Table Custom Rates from cachedTables (if set)
          final Map<String, double> loadedTableCustomRates = {};
          for (final e in cachedTables) {
            final tableId = (e['id'] ?? e['table_id'] ?? '').toString();
            final rateVal =
                e['hourly_rate'] ?? e['price_per_hour'] ?? e['price'];
            if (rateVal != null) {
              final parsedRate = double.tryParse(rateVal.toString());
              if (parsedRate != null && parsedRate > 0) {
                loadedTableCustomRates[tableId] = parsedRate;
              }
            }
          }

          final currentSelectedTableId = state.selectedTableId;
          final currentSelectedUnpaidInvoiceId = state.selectedUnpaidInvoiceId;

          String? newSelectedTableId;
          if (currentSelectedUnpaidInvoiceId != null) {
            newSelectedTableId = null;
          } else {
            newSelectedTableId = (currentSelectedTableId != null &&
                    loadedTables.any((t) => t.id == currentSelectedTableId))
                ? currentSelectedTableId
                : (loadedTables.isNotEmpty ? loadedTables.first.id : null);
          }

          if (!mounted) return;
          state = state.copyWith(
            tables: loadedTables,
            selectedTableId: newSelectedTableId,
            iotConfigs: loadedIotConfigs.isNotEmpty
                ? loadedIotConfigs
                : state.iotConfigs,
            hourlyRates: loadedHourlyRates,
            tableCustomRates: loadedTableCustomRates,
            tableTypes: loadedTableTypes.isNotEmpty
                ? loadedTableTypes
                : state.tableTypes,
            tablePrices: loadedPrices,
            connectedIp: desktopIp.isNotEmpty ? desktopIp : null,
          );
        } else {
          // Cache trống (sau khi xóa dữ liệu local): xóa hết session và dùng mock data làm fallback
          _initMockData();

          // Tự động tải dữ liệu từ server khi cache trống và có mạng
          if (!preventAutoPull &&
              _syncService != null &&
              _syncService!.isOnline) {
            _syncService!.pullOnlineDataToOffline().then((result) {
              if (result.success) {
                loadTables(preventAutoPull: true);
              }
            });
          }
        }
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(error: e.toString(), isLoading: false);
        return;
      }
    } else {
      // Không có DB (môi trường test): dùng mock data làm fallback
      _initMockData();
    }

    await _restoreSessionState();
    if (!mounted) return;
    state = state.copyWith(isLoading: false);
  }

  Future<void> _saveSessionState() async {
    if (_localDb == null) return;
    try {
      final data = {
        'tableStartTimes': state.tableStartTimes.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        'tableOrders': state.tableOrders,
        'tablePendingOrders': state.tablePendingOrders,
        'tableDiscounts': state.tableDiscounts,
        'tablePlayDiscounts': state.tablePlayDiscounts,
        'tableServiceDiscounts': state.tableServiceDiscounts,
        'tableBillDiscounts': state.tableBillDiscounts,
        'tableMembers': state.tableMembers,
        'tableStatuses': {
          for (final t in state.tables)
            t.id: {'status': t.status, 'currentOrderId': t.currentOrderId},
        },
        'unpaidInvoices': state.unpaidInvoices
            .map((inv) => inv.toJson())
            .toList(),
        'tableExtraPlayAmounts': state.tableExtraPlayAmounts,
        'tableExtraPlayMinutes': state.tableExtraPlayMinutes,
        'tableNotes': state.tableNotes,
      };
      final sessionJson = jsonEncode(data);
      _lastSessionStr = sessionJson;
      await _localDb!.setSetting('billiard_active_session', sessionJson);

      // Push to desktop server if connected
      final prefs = _prefs;
      final desktopIp = prefs?.getString('desktop_server_ip') ?? '';
      if (desktopIp.isNotEmpty) {
        try {
          final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
          final request = await client.postUrl(Uri.parse('http://$desktopIp:8085/api/session'));
          request.headers.contentType = ContentType.json;
          final deviceId = prefs?.getString('device_id') ?? '';
          if (deviceId.isNotEmpty) {
            request.headers.add('x-device-id', deviceId);
          }
          request.write(jsonEncode({'session': sessionJson}));
          final response = await request.close();
          if (response.statusCode == 403) {
            print("Connection unauthorized. Disconnecting.");
            await prefs?.remove('desktop_server_ip');
            _connectedIp = null;
            _ws?.close();
            state = state.copyWith(connectedIp: null);
          } else if (response.statusCode != 200) {
            print("Lỗi push session lên Desktop: ${response.statusCode}");
          }
        } catch (e) {
          print("Lỗi kết nối push session lên Desktop: $e");
        }
      }
    } catch (e) {
      print("Lỗi lưu session: $e");
    }
  }

  Future<void> _restoreSessionState() async {
    if (_localDb == null) return;
    try {
      final sessionJson = await _localDb!.getSetting('billiard_active_session');
      _lastSessionStr = sessionJson;
      if (sessionJson != null) {
        final data = jsonDecode(sessionJson) as Map<String, dynamic>;

        // Restore table start times
        final restoredStartTimes = <String, DateTime>{};
        if (data['tableStartTimes'] != null) {
          (data['tableStartTimes'] as Map<String, dynamic>).forEach((k, v) {
            final parsed = DateTime.tryParse(v.toString());
            if (parsed != null) restoredStartTimes[k] = parsed;
          });
        }

        // Restore table orders
        final restoredOrders = <String, List<Map<String, dynamic>>>{};
        if (data['tableOrders'] != null) {
          (data['tableOrders'] as Map<String, dynamic>).forEach((k, v) {
            restoredOrders[k] = List<Map<String, dynamic>>.from(
              (v as List).map((item) => Map<String, dynamic>.from(item as Map)),
            );
          });
        }

        // Restore table pending orders
        final restoredPendingOrders = <String, List<Map<String, dynamic>>>{};
        if (data['tablePendingOrders'] != null) {
          (data['tablePendingOrders'] as Map<String, dynamic>).forEach((k, v) {
            restoredPendingOrders[k] = List<Map<String, dynamic>>.from(
              (v as List).map((item) => Map<String, dynamic>.from(item as Map)),
            );
          });
        }

        // Restore table discounts
        final restoredDiscounts = <String, double>{};
        if (data['tableDiscounts'] != null) {
          (data['tableDiscounts'] as Map<String, dynamic>).forEach((k, v) {
            restoredDiscounts[k] = double.tryParse(v.toString()) ?? 0.0;
          });
        }

        final restoredPlayDiscounts = <String, double>{};
        if (data['tablePlayDiscounts'] != null) {
          (data['tablePlayDiscounts'] as Map<String, dynamic>).forEach((k, v) {
            restoredPlayDiscounts[k] = double.tryParse(v.toString()) ?? 0.0;
          });
        }

        final restoredServiceDiscounts = <String, double>{};
        if (data['tableServiceDiscounts'] != null) {
          (data['tableServiceDiscounts'] as Map<String, dynamic>).forEach((k, v) {
            restoredServiceDiscounts[k] = double.tryParse(v.toString()) ?? 0.0;
          });
        }

        final restoredBillDiscounts = <String, double>{};
        if (data['tableBillDiscounts'] != null) {
          (data['tableBillDiscounts'] as Map<String, dynamic>).forEach((k, v) {
            restoredBillDiscounts[k] = double.tryParse(v.toString()) ?? 0.0;
          });
        } else {
          // Fallback from tableDiscounts if new fields are not stored
          restoredDiscounts.forEach((k, v) {
            restoredBillDiscounts[k] = v;
          });
        }

        // Restore table members
        final restoredMembers = <String, Map<String, dynamic>>{};
        if (data['tableMembers'] != null) {
          (data['tableMembers'] as Map<String, dynamic>).forEach((k, v) {
            restoredMembers[k] = Map<String, dynamic>.from(v as Map);
          });
        }

        // Restore table statuses in tables list
        final restoredTables = List<TableModel>.from(state.tables);
        if (data['tableStatuses'] != null) {
          final statusesMap = data['tableStatuses'] as Map<String, dynamic>;
          for (int i = 0; i < restoredTables.length; i++) {
            final t = restoredTables[i];
            if (statusesMap.containsKey(t.id)) {
              final tData = statusesMap[t.id] as Map<String, dynamic>;
              restoredTables[i] = t.copyWith(
                status: tData['status']?.toString() ?? 'idle',
                currentOrderId: tData['currentOrderId']?.toString(),
                clearCurrentOrderId: tData['currentOrderId'] == null,
              );
            }
          }
        }

        // Restore unpaid invoices
        final restoredUnpaid = <UnpaidInvoice>[];
        if (data['unpaidInvoices'] != null) {
          for (final item in (data['unpaidInvoices'] as List)) {
            restoredUnpaid.add(
              UnpaidInvoice.fromJson(item as Map<String, dynamic>),
            );
          }
        }

        // Restore table extra play amounts
        final restoredExtraAmounts = <String, double>{};
        if (data['tableExtraPlayAmounts'] != null) {
          (data['tableExtraPlayAmounts'] as Map<String, dynamic>).forEach((
            k,
            v,
          ) {
            restoredExtraAmounts[k] = double.tryParse(v.toString()) ?? 0.0;
          });
        }

        // Restore table extra play minutes
        final restoredExtraMinutes = <String, int>{};
        if (data['tableExtraPlayMinutes'] != null) {
          (data['tableExtraPlayMinutes'] as Map<String, dynamic>).forEach((
            k,
            v,
          ) {
            restoredExtraMinutes[k] = int.tryParse(v.toString()) ?? 0;
          });
        }

        // Restore table notes
        final restoredNotes = <String, String>{};
        if (data['tableNotes'] != null) {
          (data['tableNotes'] as Map<String, dynamic>).forEach((k, v) {
            restoredNotes[k] = v.toString();
          });
        }

        final currentSelectedUnpaidId = state.selectedUnpaidInvoiceId;
        String? newSelectedUnpaidId = currentSelectedUnpaidId;
        String? newSelectedTableId = state.selectedTableId;

        if (currentSelectedUnpaidId != null &&
            !restoredUnpaid.any((inv) => inv.id == currentSelectedUnpaidId)) {
          newSelectedUnpaidId = null;
          newSelectedTableId = restoredTables.isNotEmpty ? restoredTables.first.id : null;
        }

        final prefs = _prefs;
        final desktopIp = prefs?.getString('desktop_server_ip') ?? '';

        state = state.copyWith(
          tables: restoredTables,
          tableStartTimes: restoredStartTimes,
          tableOrders: restoredOrders,
          tablePendingOrders: restoredPendingOrders,
          tableDiscounts: restoredDiscounts,
          tablePlayDiscounts: restoredPlayDiscounts,
          tableServiceDiscounts: restoredServiceDiscounts,
          tableBillDiscounts: restoredBillDiscounts,
          tableMembers: restoredMembers,
          unpaidInvoices: restoredUnpaid,
          tableExtraPlayAmounts: restoredExtraAmounts,
          tableExtraPlayMinutes: restoredExtraMinutes,
          tableNotes: restoredNotes,
          selectedUnpaidInvoiceId: newSelectedUnpaidId,
          selectedTableId: newSelectedTableId,
          connectedIp: desktopIp.isNotEmpty ? desktopIp : null,
        );
      }
    } catch (e) {
      print("Lỗi khôi phục session: $e");
    }
  }

  void _initMockData() {
    final hourlyRates = {'1': 85000.0};

    final tables = [
      const TableModel(
        id: 't-1',
        tableName: 'Bàn 01 (Pool)',
        areaId: 1,
        tableTypeId: 1,
        status: 'idle',
        sortOrder: 1,
      ),
      const TableModel(
        id: 't-2',
        tableName: 'Bàn 02 (Pool)',
        areaId: 1,
        tableTypeId: 1,
        status: 'idle',
        sortOrder: 2,
      ),
      const TableModel(
        id: 't-3',
        tableName: 'Bàn 03 (Pool)',
        areaId: 1,
        tableTypeId: 1,
        status: 'idle',
        sortOrder: 3,
      ),
      const TableModel(
        id: 't-4',
        tableName: 'Bàn 04 (Carom)',
        areaId: 2,
        tableTypeId: 1,
        status: 'idle',
        sortOrder: 4,
      ),
    ];

    final iotConfigs = {
      't-1': const IotConfigModel(
        id: 1,
        tableId: 't-1',
        connectionType: 'serial',
        port: 'COM1',
        relayChannel: 1,
        commandOn: '01050000FF008C3A',
        commandOff: '010500000000CDCA',
      ),
      't-2': const IotConfigModel(
        id: 2,
        tableId: 't-2',
        connectionType: 'serial',
        port: 'COM2',
        relayChannel: 2,
        commandOn: '01050001FF00DDFA',
        commandOff: '0105000100009C0A',
      ),
      't-3': const IotConfigModel(
        id: 3,
        tableId: 't-3',
        connectionType: 'serial',
        port: 'COM3',
        relayChannel: 3,
        commandOn: '01050002FF002DFA',
        commandOff: '0105000200006C0A',
      ),
      't-4': const IotConfigModel(
        id: 4,
        tableId: 't-4',
        connectionType: 'tcp_ip',
        ipAddress: '192.168.1.150',
        port: '8080',
        relayChannel: 1,
        commandOn: '01050000FF008C3A',
        commandOff: '010500000000CDCA',
      ),
    };

    final tableCustomRates = {
      't-7': 150000.0, // Mock custom rate for VIP Table 01
    };

    state = state.copyWith(
      tables: tables,
      iotConfigs: iotConfigs,
      hourlyRates: hourlyRates,
      tableCustomRates: tableCustomRates,
      selectedTableId: tables.first.id,
    );
  }

  void selectTable(String tableId) {
    state = state.copyWith(
      selectedTableId: tableId,
      selectedUnpaidInvoiceId: null,
    );
  }

  void selectUnpaidInvoice(String invoiceId) {
    state = state.copyWith(
      selectedUnpaidInvoiceId: invoiceId,
      selectedTableId: null,
    );
  }

  void toggleSimulator(bool useSimulator) {
    state = state.copyWith(useSimulator: useSimulator);
  }

  Future<bool> activateTable(
    String tableId, {
    bool ignoreIotError = false,
    String? shiftId,
    String? memberId,
  }) async {
    final tableIndex = state.tables.indexWhere((t) => t.id == tableId);
    if (tableIndex < 0) return false;

    final iotConfig = state.iotConfigs[tableId];
    if (iotConfig != null) {
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

    // 1. Tạo order trên backend (nếu online)
    String serverOrderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';
    if (_apiClient != null && _isOnline) {
      try {
        final res = await _apiClient!.openOrder(
          tableId: tableId,
          shiftId: shiftId,
          memberId: memberId,
        );
        final status = res['status'];
        if (status == 1 || status == '1') {
          final data = res['data'] as Map<String, dynamic>?;
          final orderData = data?['order'] as Map<String, dynamic>?;
          final backendId = orderData?['id']?.toString();
          if (backendId != null && backendId.isNotEmpty) {
            serverOrderId = backendId;
          }
        }
      } catch (e) {
        // Offline hoặc lỗi — tiếp tục với local ID
        print('Lỗi tạo order trên backend (offline?): $e');
      }
    }

    // 2. Cập nhật state local
    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[tableIndex] = state.tables[tableIndex].copyWith(
      status: 'active',
      currentOrderId: serverOrderId,
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes);
    updatedStartTimes[tableId] = DateTime.now();

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    updatedOrders[tableId] = [];

    final updatedPending = Map<String, List<Map<String, dynamic>>>.from(
      state.tablePendingOrders,
    );
    updatedPending[tableId] = [];

    // 3. Lưu server orderId vào state
    final updatedServerOrderIds = Map<String, String>.from(
      state.tableServerOrderIds,
    );
    updatedServerOrderIds[tableId] = serverOrderId;

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tablePendingOrders: updatedPending,
      tableServerOrderIds: updatedServerOrderIds,
    );
    await _saveSessionState();
    return true;
  }

  Future<bool> deactivateTable(String tableId) async {
    final controller = _controllers[tableId];
    if (controller != null) {
      try {
        await controller.turnOff();
        await controller.disconnect();
      } catch (e) {
        print('Lỗi tắt IoT controller khi tắt bàn: $e');
      }
      _controllers.remove(tableId);
    }

    if (_apiClient != null && _isOnline) {
      try {
        await _apiClient!.updateTableStatus(tableId, 'idle');
      } catch (e) {
        print(
          'Lỗi cập nhật trạng thái bàn về idle trên backend khi checkout: $e',
        );
      }
    }

    final tableIndex = state.tables.indexWhere((t) => t.id == tableId);
    if (tableIndex < 0) return false;

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[tableIndex] = state.tables[tableIndex].copyWith(
      status: 'idle',
      clearCurrentOrderId: true,
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes);
    updatedStartTimes.remove(tableId);

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    updatedOrders.remove(tableId);

    final updatedPending = Map<String, List<Map<String, dynamic>>>.from(
      state.tablePendingOrders,
    );
    updatedPending.remove(tableId);

    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts);
    updatedDiscounts.remove(tableId);

    final updatedPlayDiscounts = Map<String, double>.from(state.tablePlayDiscounts);
    updatedPlayDiscounts.remove(tableId);

    final updatedServiceDiscounts = Map<String, double>.from(state.tableServiceDiscounts);
    updatedServiceDiscounts.remove(tableId);

    final updatedBillDiscounts = Map<String, double>.from(state.tableBillDiscounts);
    updatedBillDiscounts.remove(tableId);

    final updatedMembers = Map<String, Map<String, dynamic>>.from(
      state.tableMembers,
    );
    updatedMembers.remove(tableId);

    final updatedExtraAmounts = Map<String, double>.from(
      state.tableExtraPlayAmounts,
    )..remove(tableId);
    final updatedExtraMinutes = Map<String, int>.from(
      state.tableExtraPlayMinutes,
    )..remove(tableId);
    final updatedNotes = Map<String, String>.from(state.tableNotes)
      ..remove(tableId);

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tablePendingOrders: updatedPending,
      tableDiscounts: updatedDiscounts,
      tablePlayDiscounts: updatedPlayDiscounts,
      tableServiceDiscounts: updatedServiceDiscounts,
      tableBillDiscounts: updatedBillDiscounts,
      tableMembers: updatedMembers,
      tableExtraPlayAmounts: updatedExtraAmounts,
      tableExtraPlayMinutes: updatedExtraMinutes,
      tableNotes: updatedNotes,
    );
    await _saveSessionState();
    return true;
  }

  Future<bool> deactivateTableAndFreezeInvoice(String tableId) async {
    final controller = _controllers[tableId];
    if (controller != null) {
      try {
        await controller.turnOff();
        await controller.disconnect();
      } catch (e) {
        print('Lỗi tắt IoT controller khi tắt bàn và treo hóa đơn: $e');
      }
      _controllers.remove(tableId);
    }

    final tableIndex = state.tables.indexWhere((t) => t.id == tableId);
    if (tableIndex < 0) return false;

    final table = state.tables[tableIndex];
    final startTime = state.tableStartTimes[tableId] ?? DateTime.now();
    final endTime = DateTime.now();
    final rate = state.getTableHourlyRate(table, startTime);

    final baseMinutes = endTime.difference(startTime).inMinutes + 1;
    final billedMinutes = ((baseMinutes + 4) ~/ 5) * 5;
    final playMinutes =
        billedMinutes + (state.tableExtraPlayMinutes[tableId] ?? 0);
    final playAmount =
        (billedMinutes / 60.0) * rate +
        (state.tableExtraPlayAmounts[tableId] ?? 0.0);

    final products = state.tableOrders[tableId] ?? [];
    
    final discountPlay = state.tablePlayDiscounts[tableId] ?? 0.0;
    final discountService = state.tableServiceDiscounts[tableId] ?? 0.0;
    final discountBill = state.tableBillDiscounts[tableId] ?? 0.0;
    final discount = state.tableDiscounts[tableId] ?? 0.0;
    
    final member = state.tableMembers[tableId];
    final note = state.tableNotes[tableId];
    final orderId =
        table.currentOrderId ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';

    // Cập nhật tình trạng bàn về idle trên backend khi tắt bàn
    if (_apiClient != null && _isOnline) {
      try {
        await _apiClient!.updateTableStatus(tableId, 'idle');
      } catch (e) {
        print('Lỗi cập nhật trạng thái bàn về idle trên backend: $e');
      }
    }

    final unpaidInvoice = UnpaidInvoice(
      id: orderId,
      tableId: tableId,
      tableName: table.tableName,
      startTime: startTime,
      endTime: endTime,
      playMinutes: playMinutes,
      playAmount: playAmount,
      hourlyRate: rate,
      products: List<Map<String, dynamic>>.from(products),
      manualDiscountPercent: discountBill,
      discountPlayPercent: discountPlay,
      discountServicePercent: discountService,
      discountBillPercent: discountBill,
      member: member,
      note: note,
    );

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[tableIndex] = table.copyWith(
      status: 'idle',
      clearCurrentOrderId: true,
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes)
      ..remove(tableId);
    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    )..remove(tableId);
    final updatedPending = Map<String, List<Map<String, dynamic>>>.from(
      state.tablePendingOrders,
    )..remove(tableId);
    
    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts)
      ..remove(tableId);
    final updatedPlayDiscounts = Map<String, double>.from(state.tablePlayDiscounts)
      ..remove(tableId);
    final updatedServiceDiscounts = Map<String, double>.from(state.tableServiceDiscounts)
      ..remove(tableId);
    final updatedBillDiscounts = Map<String, double>.from(state.tableBillDiscounts)
      ..remove(tableId);
      
    final updatedMembers = Map<String, Map<String, dynamic>>.from(
      state.tableMembers,
    )..remove(tableId);
    final updatedUnpaidInvoices = List<UnpaidInvoice>.from(state.unpaidInvoices)
      ..add(unpaidInvoice);

    final updatedExtraAmounts = Map<String, double>.from(
      state.tableExtraPlayAmounts,
    )..remove(tableId);
    final updatedExtraMinutes = Map<String, int>.from(
      state.tableExtraPlayMinutes,
    )..remove(tableId);
    final updatedNotes = Map<String, String>.from(state.tableNotes)
      ..remove(tableId);

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tablePendingOrders: updatedPending,
      tableDiscounts: updatedDiscounts,
      tablePlayDiscounts: updatedPlayDiscounts,
      tableServiceDiscounts: updatedServiceDiscounts,
      tableBillDiscounts: updatedBillDiscounts,
      tableMembers: updatedMembers,
      unpaidInvoices: updatedUnpaidInvoices,
      selectedUnpaidInvoiceId: unpaidInvoice.id,
      selectedTableId: null,
      tableExtraPlayAmounts: updatedExtraAmounts,
      tableExtraPlayMinutes: updatedExtraMinutes,
      tableNotes: updatedNotes,
    );

    if (_localDb != null) {
      try {
        final productTotal = products.fold(
          0.0,
          (sum, p) =>
              sum +
              (double.tryParse(p['price']?.toString() ?? '') ?? 0.0) *
                  (int.tryParse(p['qty']?.toString() ?? '') ?? 1),
        );
        
        final playDiscountAmount = playAmount * (discountPlay / 100.0);
        final serviceDiscountAmount = productTotal * (discountService / 100.0);
        final memberDiscountPercent = member != null ? (double.tryParse(member['discount']?.toString() ?? '') ?? 0.0) : 0.0;
        final billDiscountPercentTotal = (discountBill + memberDiscountPercent).clamp(0.0, 100.0);
        final billDiscountAmount = (playAmount + productTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
        final totalDiscountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
        
        final orderModel = OrderModel(
          id: orderId,
          tableId: tableId,
          memberId: member?['id']?.toString(),
          shiftId: 'shift-default',
          status: 'active',
          startTime: startTime,
          endTime: endTime,
          totalPlayTimeMinutes: playMinutes,
          totalPlayTimeAmount: playAmount,
          totalProductAmount: productTotal,
          discountAmount: totalDiscountAmount,
          taxAmount: 0.0,
          totalAmount: playAmount + productTotal - totalDiscountAmount,
          paymentMethod: null,
          createdBy: 'system',
          closedBy: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          note: note,
        );

        final details = <OrderDetailModel>[];
        for (int i = 0; i < products.length; i++) {
          final p = products[i];
          final pid = p['product_id']?.toString() ?? '';
          final qty = int.tryParse(p['qty']?.toString() ?? '') ?? 1;
          final price = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
          details.add(
            OrderDetailModel(
              id: const Uuid().v4(),
              orderId: orderId,
              productId: pid,
              quantity: qty,
              unitPrice: price,
              totalPrice: price * qty,
              addedBy: 'system',
              createdAt: DateTime.now(),
            ),
          );
        }

        final payload = {
          'order': orderModel.toJson(),
          'details': details.map((d) => d.toJson()).toList(),
          if (member != null) 'member': member,
        };

        await _localDb!.saveOrderLocally(orderId, payload);
      } catch (e) {
        print('Lỗi lưu order tắt bàn vào pending_orders: $e');
      }
    }

    await _saveSessionState();
    return true;
  }

  void applyDiscount(
    String targetId, {
    required double playPercent,
    required double servicePercent,
    required double billPercent,
  }) {
    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == targetId,
    );
    if (invoiceIndex >= 0) {
      final updated = List<UnpaidInvoice>.from(state.unpaidInvoices);
      updated[invoiceIndex] = updated[invoiceIndex].copyWith(
        discountPlayPercent: playPercent,
        discountServicePercent: servicePercent,
        discountBillPercent: billPercent,
        manualDiscountPercent: billPercent,
      );
      state = state.copyWith(unpaidInvoices: updated);
      _saveSessionState();
      return;
    }

    final updatedPlay = Map<String, double>.from(state.tablePlayDiscounts);
    final updatedService = Map<String, double>.from(state.tableServiceDiscounts);
    final updatedBill = Map<String, double>.from(state.tableBillDiscounts);
    final updatedManual = Map<String, double>.from(state.tableDiscounts);

    updatedPlay[targetId] = playPercent;
    updatedService[targetId] = servicePercent;
    updatedBill[targetId] = billPercent;
    updatedManual[targetId] = billPercent;

    state = state.copyWith(
      tablePlayDiscounts: updatedPlay,
      tableServiceDiscounts: updatedService,
      tableBillDiscounts: updatedBill,
      tableDiscounts: updatedManual,
    );
    _saveSessionState();
  }

  void removeDiscount(String targetId) {
    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == targetId,
    );
    if (invoiceIndex >= 0) {
      final updated = List<UnpaidInvoice>.from(state.unpaidInvoices);
      updated[invoiceIndex] = updated[invoiceIndex].copyWith(
        discountPlayPercent: 0.0,
        discountServicePercent: 0.0,
        discountBillPercent: 0.0,
        manualDiscountPercent: 0.0,
      );
      state = state.copyWith(unpaidInvoices: updated);
      _saveSessionState();
      return;
    }

    final updatedPlay = Map<String, double>.from(state.tablePlayDiscounts)..remove(targetId);
    final updatedService = Map<String, double>.from(state.tableServiceDiscounts)..remove(targetId);
    final updatedBill = Map<String, double>.from(state.tableBillDiscounts)..remove(targetId);
    final updatedManual = Map<String, double>.from(state.tableDiscounts)..remove(targetId);

    state = state.copyWith(
      tablePlayDiscounts: updatedPlay,
      tableServiceDiscounts: updatedService,
      tableBillDiscounts: updatedBill,
      tableDiscounts: updatedManual,
    );
    _saveSessionState();
  }

  void applyMember(String targetId, Map<String, dynamic> member) {
    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == targetId,
    );
    if (invoiceIndex >= 0) {
      final updated = List<UnpaidInvoice>.from(state.unpaidInvoices);
      updated[invoiceIndex] = updated[invoiceIndex].copyWith(member: member);
      state = state.copyWith(unpaidInvoices: updated);
      _saveSessionState();
      return;
    }

    final updated = Map<String, Map<String, dynamic>>.from(state.tableMembers);
    updated[targetId] = member;
    state = state.copyWith(tableMembers: updated);
    _saveSessionState();
  }

  void removeMember(String targetId) {
    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == targetId,
    );
    if (invoiceIndex >= 0) {
      final updated = List<UnpaidInvoice>.from(state.unpaidInvoices);
      updated[invoiceIndex] = updated[invoiceIndex].copyWith(clearMember: true);
      state = state.copyWith(unpaidInvoices: updated);
      _saveSessionState();
      return;
    }

    final updated = Map<String, Map<String, dynamic>>.from(state.tableMembers);
    updated.remove(targetId);
    state = state.copyWith(tableMembers: updated);
    _saveSessionState();
  }

  Future<bool> transferTable(
    String sourceTableId,
    String targetTableId, {
    bool ignoreIotError = false,
  }) async {
    final sourceIndex = state.tables.indexWhere((t) => t.id == sourceTableId);
    final targetIndex = state.tables.indexWhere((t) => t.id == targetTableId);
    if (sourceIndex < 0 || targetIndex < 0) return false;

    final sourceTable = state.tables[sourceIndex];
    final targetTable = state.tables[targetIndex];
    if (sourceTable.status != 'active' || targetTable.status != 'idle')
      return false;

    final iotConfig = state.iotConfigs[targetTableId];
    if (iotConfig != null) {
      final controller = state.useSimulator
          ? SimulatedBilliardIoTController() as BilliardIoTController
          : RealBilliardIoTController();

      try {
        final connected = await controller.connect(iotConfig);
        if (!connected && !ignoreIotError) return false;

        if (connected) {
          final turnedOn = await controller.turnOn();
          if (!turnedOn && !ignoreIotError) return false;
          _controllers[targetTableId] = controller;
        }
      } catch (e) {
        if (!ignoreIotError) return false;
      }
    }

    final sourceController = _controllers[sourceTableId];
    if (sourceController != null) {
      try {
        await sourceController.turnOff();
        await sourceController.disconnect();
      } catch (e) {
        print('Lỗi tắt IoT controller nguồn khi chuyển bàn: $e');
      }
      _controllers.remove(sourceTableId);
    }

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[sourceIndex] = sourceTable.copyWith(
      status: 'idle',
      clearCurrentOrderId: true,
    );
    updatedTables[targetIndex] = targetTable.copyWith(
      status: 'active',
      currentOrderId:
          sourceTable.currentOrderId ??
          'ord-${DateTime.now().millisecondsSinceEpoch}',
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes);
    final startTime = updatedStartTimes.remove(sourceTableId);
    if (startTime != null) {
      updatedStartTimes[targetTableId] = startTime;
    }

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    final orders = updatedOrders.remove(sourceTableId);
    if (orders != null) {
      updatedOrders[targetTableId] = orders;
    }

    final updatedPending = Map<String, List<Map<String, dynamic>>>.from(
      state.tablePendingOrders,
    );
    final pending = updatedPending.remove(sourceTableId);
    if (pending != null) {
      updatedPending[targetTableId] = pending;
    }

    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts);
    final discount = updatedDiscounts.remove(sourceTableId);
    if (discount != null) {
      updatedDiscounts[targetTableId] = discount;
    }

    final updatedPlayDiscounts = Map<String, double>.from(state.tablePlayDiscounts);
    final playDiscount = updatedPlayDiscounts.remove(sourceTableId);
    if (playDiscount != null) {
      updatedPlayDiscounts[targetTableId] = playDiscount;
    }

    final updatedServiceDiscounts = Map<String, double>.from(state.tableServiceDiscounts);
    final serviceDiscount = updatedServiceDiscounts.remove(sourceTableId);
    if (serviceDiscount != null) {
      updatedServiceDiscounts[targetTableId] = serviceDiscount;
    }

    final updatedBillDiscounts = Map<String, double>.from(state.tableBillDiscounts);
    final billDiscount = updatedBillDiscounts.remove(sourceTableId);
    if (billDiscount != null) {
      updatedBillDiscounts[targetTableId] = billDiscount;
    }

    final updatedMembers = Map<String, Map<String, dynamic>>.from(
      state.tableMembers,
    );
    final member = updatedMembers.remove(sourceTableId);
    if (member != null) {
      updatedMembers[targetTableId] = member;
    }

    final updatedExtraAmounts = Map<String, double>.from(
      state.tableExtraPlayAmounts,
    );
    final extraAmount = updatedExtraAmounts.remove(sourceTableId);
    if (extraAmount != null) {
      updatedExtraAmounts[targetTableId] = extraAmount;
    }

    final updatedExtraMinutes = Map<String, int>.from(
      state.tableExtraPlayMinutes,
    );
    final extraMinutes = updatedExtraMinutes.remove(sourceTableId);
    if (extraMinutes != null) {
      updatedExtraMinutes[targetTableId] = extraMinutes;
    }

    final updatedNotes = Map<String, String>.from(state.tableNotes);
    final note = updatedNotes.remove(sourceTableId);
    if (note != null) {
      updatedNotes[targetTableId] = note;
    }

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tablePendingOrders: updatedPending,
      tableDiscounts: updatedDiscounts,
      tablePlayDiscounts: updatedPlayDiscounts,
      tableServiceDiscounts: updatedServiceDiscounts,
      tableBillDiscounts: updatedBillDiscounts,
      tableMembers: updatedMembers,
      tableExtraPlayAmounts: updatedExtraAmounts,
      tableExtraPlayMinutes: updatedExtraMinutes,
      tableNotes: updatedNotes,
    );

    final orderId = sourceTable.currentOrderId;
    if (_apiClient != null && _isOnline && orderId != null && !orderId.startsWith('ord-')) {
      try {
        await _apiClient!.updateOrder(orderId, {
          'table_id': targetTableId,
          if (note != null) 'note': note,
        });
        await _apiClient!.updateTableStatus(sourceTableId, 'idle');
        await _apiClient!.updateTableStatus(targetTableId, 'active');
      } catch (e) {
        print('Lỗi đồng bộ chuyển bàn lên backend: $e');
      }
    }

    await _saveSessionState();
    return true;
  }

  Future<bool> mergeTable(String sourceTableId, String targetTableId) async {
    final sourceIndex = state.tables.indexWhere((t) => t.id == sourceTableId);
    final targetIndex = state.tables.indexWhere((t) => t.id == targetTableId);
    if (sourceIndex < 0 || targetIndex < 0) return false;

    final sourceTable = state.tables[sourceIndex];
    final targetTable = state.tables[targetIndex];
    if (sourceTable.status != 'active' || targetTable.status != 'active')
      return false;

    final sourcePlayCost = state.playCost(sourceTableId);
    final sourcePlayMinutes = state.playDuration(sourceTableId).inMinutes + 1;

    final sourceController = _controllers[sourceTableId];
    if (sourceController != null) {
      try {
        await sourceController.turnOff();
        await sourceController.disconnect();
      } catch (e) {
        print('Lỗi tắt IoT controller nguồn khi gộp bàn: $e');
      }
      _controllers.remove(sourceTableId);
    }

    final updatedTables = List<TableModel>.from(state.tables);
    updatedTables[sourceIndex] = sourceTable.copyWith(
      status: 'idle',
      clearCurrentOrderId: true,
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes);
    updatedStartTimes.remove(sourceTableId);

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    final sourceItems = updatedOrders.remove(sourceTableId) ?? [];
    final targetItems = List<Map<String, dynamic>>.from(
      updatedOrders[targetTableId] ?? [],
    );

    for (final item in sourceItems) {
      final existingIndex = targetItems.indexWhere(
        (p) => p['product_id'] == item['product_id'],
      );
      if (existingIndex >= 0) {
        targetItems[existingIndex] = {
          ...targetItems[existingIndex],
          'qty':
              (targetItems[existingIndex]['qty'] as int) + (item['qty'] as int),
        };
      } else {
        targetItems.add(Map<String, dynamic>.from(item));
      }
    }
    updatedOrders[targetTableId] = targetItems;

    final updatedPending = Map<String, List<Map<String, dynamic>>>.from(
      state.tablePendingOrders,
    );
    final sourcePending = updatedPending.remove(sourceTableId) ?? [];
    final targetPending = List<Map<String, dynamic>>.from(
      updatedPending[targetTableId] ?? [],
    );

    for (final item in sourcePending) {
      final existingIndex = targetPending.indexWhere(
        (p) => p['product_id'] == item['product_id'],
      );
      if (existingIndex >= 0) {
        targetPending[existingIndex] = {
          ...targetPending[existingIndex],
          'qty':
              (targetPending[existingIndex]['qty'] as int) + (item['qty'] as int),
        };
      } else {
        targetPending.add(Map<String, dynamic>.from(item));
      }
    }
    updatedPending[targetTableId] = targetPending;

    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts);
    updatedDiscounts.remove(sourceTableId);

    final updatedPlayDiscounts = Map<String, double>.from(state.tablePlayDiscounts)..remove(sourceTableId);
    final updatedServiceDiscounts = Map<String, double>.from(state.tableServiceDiscounts)..remove(sourceTableId);
    final updatedBillDiscounts = Map<String, double>.from(state.tableBillDiscounts)..remove(sourceTableId);

    final updatedMembers = Map<String, Map<String, dynamic>>.from(
      state.tableMembers,
    );
    updatedMembers.remove(sourceTableId);

    // Update play cost, minutes and notes
    final updatedExtraAmounts = Map<String, double>.from(
      state.tableExtraPlayAmounts,
    );
    final existingExtraAmount = updatedExtraAmounts[targetTableId] ?? 0.0;
    updatedExtraAmounts[targetTableId] = existingExtraAmount + sourcePlayCost;
    updatedExtraAmounts.remove(sourceTableId);

    final updatedExtraMinutes = Map<String, int>.from(
      state.tableExtraPlayMinutes,
    );
    final existingExtraMinutes = updatedExtraMinutes[targetTableId] ?? 0;
    updatedExtraMinutes[targetTableId] =
        existingExtraMinutes + sourcePlayMinutes;
    updatedExtraMinutes.remove(sourceTableId);

    final updatedNotes = Map<String, String>.from(state.tableNotes);
    final sourceNote = updatedNotes[sourceTableId];
    final targetNote = updatedNotes[targetTableId];
    String mergeNote =
        'Gộp từ ${sourceTable.tableName} (Tiền giờ: ${sourcePlayCost.toStringAsFixed(0)}đ)';
    if (sourceNote != null && sourceNote.isNotEmpty) {
      mergeNote += ' [Ghi chú cũ: $sourceNote]';
    }
    updatedNotes[targetTableId] = (targetNote != null && targetNote.isNotEmpty)
        ? '$targetNote\n$mergeNote'
        : mergeNote;
    updatedNotes.remove(sourceTableId);

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tablePendingOrders: updatedPending,
      tableDiscounts: updatedDiscounts,
      tablePlayDiscounts: updatedPlayDiscounts,
      tableServiceDiscounts: updatedServiceDiscounts,
      tableBillDiscounts: updatedBillDiscounts,
      tableMembers: updatedMembers,
      tableExtraPlayAmounts: updatedExtraAmounts,
      tableExtraPlayMinutes: updatedExtraMinutes,
      tableNotes: updatedNotes,
    );

    final sourceOrderId = sourceTable.currentOrderId;
    if (_apiClient != null &&
        _isOnline &&
        sourceOrderId != null &&
        !sourceOrderId.startsWith('ord-')) {
      try {
        await _apiClient!.voidOrder(
          sourceOrderId,
          'Gộp bàn vào ${targetTable.tableName}',
        );
        await _apiClient!.updateTableStatus(sourceTableId, 'idle');
      } catch (e) {
        print('Lỗi đồng bộ gộp bàn lên backend: $e');
      }
    }

    final targetOrderId = targetTable.currentOrderId;
    if (_apiClient != null &&
        _isOnline &&
        targetOrderId != null &&
        !targetOrderId.startsWith('ord-')) {
      try {
        await _apiClient!.updateOrder(targetOrderId, {
          'note': updatedNotes[targetTableId],
        });
      } catch (e) {
        print('Lỗi cập nhật ghi chú bàn đích: $e');
      }
    }

    await _saveSessionState();
    return true;
  }

  Future<bool> transferUnpaidInvoiceToTable(
    String invoiceId,
    String targetTableId, {
    bool ignoreIotError = false,
  }) async {
    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == invoiceId,
    );
    final targetIndex = state.tables.indexWhere((t) => t.id == targetTableId);
    if (invoiceIndex < 0 || targetIndex < 0) return false;

    final invoice = state.unpaidInvoices[invoiceIndex];
    final targetTable = state.tables[targetIndex];
    if (targetTable.status != 'idle') return false;

    final iotConfig = state.iotConfigs[targetTableId];
    if (iotConfig != null) {
      final controller = state.useSimulator
          ? SimulatedBilliardIoTController() as BilliardIoTController
          : RealBilliardIoTController();
      _controllers[targetTableId] = controller;

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
    updatedTables[targetIndex] = targetTable.copyWith(
      status: 'active',
      currentOrderId: invoice.id,
    );

    // Calculate simulated start time to preserve playMinutes
    final calculatedStartTime = DateTime.now().subtract(
      Duration(minutes: invoice.playMinutes),
    );

    final updatedStartTimes = Map<String, DateTime>.from(state.tableStartTimes);
    updatedStartTimes[targetTableId] = calculatedStartTime;

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    updatedOrders[targetTableId] = List<Map<String, dynamic>>.from(
      invoice.products,
    );

    final updatedDiscounts = Map<String, double>.from(state.tableDiscounts);
    updatedDiscounts[targetTableId] = invoice.discountBillPercent;

    final updatedPlayDiscounts = Map<String, double>.from(state.tablePlayDiscounts);
    updatedPlayDiscounts[targetTableId] = invoice.discountPlayPercent;

    final updatedServiceDiscounts = Map<String, double>.from(state.tableServiceDiscounts);
    updatedServiceDiscounts[targetTableId] = invoice.discountServicePercent;

    final updatedBillDiscounts = Map<String, double>.from(state.tableBillDiscounts);
    updatedBillDiscounts[targetTableId] = invoice.discountBillPercent;

    final updatedMembers = Map<String, Map<String, dynamic>>.from(
      state.tableMembers,
    );
    if (invoice.member != null) {
      updatedMembers[targetTableId] = invoice.member!;
    }

    final updatedUnpaid = List<UnpaidInvoice>.from(state.unpaidInvoices)
      ..removeAt(invoiceIndex);

    final updatedNotes = Map<String, String>.from(state.tableNotes);
    if (invoice.note != null && invoice.note!.isNotEmpty) {
      updatedNotes[targetTableId] = invoice.note!;
    }

    state = state.copyWith(
      tables: updatedTables,
      tableStartTimes: updatedStartTimes,
      tableOrders: updatedOrders,
      tableDiscounts: updatedDiscounts,
      tablePlayDiscounts: updatedPlayDiscounts,
      tableServiceDiscounts: updatedServiceDiscounts,
      tableBillDiscounts: updatedBillDiscounts,
      tableMembers: updatedMembers,
      unpaidInvoices: updatedUnpaid,
      selectedUnpaidInvoiceId: null,
      selectedTableId: targetTableId,
      tableNotes: updatedNotes,
    );

    if (_apiClient != null && _isOnline && !invoiceId.startsWith('ord-')) {
      try {
        await _apiClient!.updateOrder(invoiceId, {
          'table_id': targetTableId,
          'status': 'active',
          if (invoice.note != null) 'note': invoice.note,
        });
        await _apiClient!.updateTableStatus(targetTableId, 'active');
      } catch (e) {
        print('Lỗi đồng bộ chuyển hóa đơn chờ lên backend: $e');
      }
    }

    await _saveSessionState();
    return true;
  }

  Future<bool> mergeUnpaidInvoiceToTable(
    String invoiceId,
    String targetTableId,
  ) async {
    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == invoiceId,
    );
    final targetIndex = state.tables.indexWhere((t) => t.id == targetTableId);
    if (invoiceIndex < 0 || targetIndex < 0) return false;

    final invoice = state.unpaidInvoices[invoiceIndex];
    final targetTable = state.tables[targetIndex];
    if (targetTable.status != 'active') return false;

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    final targetItems = List<Map<String, dynamic>>.from(
      updatedOrders[targetTableId] ?? [],
    );

    for (final item in invoice.products) {
      final existingIndex = targetItems.indexWhere(
        (p) => p['product_id'] == item['product_id'],
      );
      if (existingIndex >= 0) {
        targetItems[existingIndex] = {
          ...targetItems[existingIndex],
          'qty':
              (targetItems[existingIndex]['qty'] as int) + (item['qty'] as int),
        };
      } else {
        targetItems.add(Map<String, dynamic>.from(item));
      }
    }
    updatedOrders[targetTableId] = targetItems;

    // Update play cost, minutes and notes
    final updatedExtraAmounts = Map<String, double>.from(
      state.tableExtraPlayAmounts,
    );
    final existingExtraAmount = updatedExtraAmounts[targetTableId] ?? 0.0;
    updatedExtraAmounts[targetTableId] =
        existingExtraAmount + invoice.playAmount;

    final updatedExtraMinutes = Map<String, int>.from(
      state.tableExtraPlayMinutes,
    );
    final existingExtraMinutes = updatedExtraMinutes[targetTableId] ?? 0;
    updatedExtraMinutes[targetTableId] =
        existingExtraMinutes + invoice.playMinutes;

    final updatedNotes = Map<String, String>.from(state.tableNotes);
    final invoiceNote = invoice.note;
    final targetNote = updatedNotes[targetTableId];
    String mergeNote =
        'Gộp từ ${invoice.tableName} (Tiền giờ: ${invoice.playAmount.toStringAsFixed(0)}đ)';
    if (invoiceNote != null && invoiceNote.isNotEmpty) {
      mergeNote += ' [Ghi chú cũ: $invoiceNote]';
    }
    updatedNotes[targetTableId] = (targetNote != null && targetNote.isNotEmpty)
        ? '$targetNote\n$mergeNote'
        : mergeNote;

    // Remove from unpaid invoices
    final updatedUnpaid = List<UnpaidInvoice>.from(state.unpaidInvoices)
      ..removeAt(invoiceIndex);

    state = state.copyWith(
      tableOrders: updatedOrders,
      unpaidInvoices: updatedUnpaid,
      selectedUnpaidInvoiceId: null,
      selectedTableId: targetTableId,
      tableExtraPlayAmounts: updatedExtraAmounts,
      tableExtraPlayMinutes: updatedExtraMinutes,
      tableNotes: updatedNotes,
    );

    if (_apiClient != null && _isOnline && !invoiceId.startsWith('ord-')) {
      try {
        await _apiClient!.voidOrder(
          invoiceId,
          'Gộp hóa đơn chờ vào ${targetTable.tableName}',
        );
      } catch (e) {
        print('Lỗi đồng bộ gộp hóa đơn chờ lên backend: $e');
      }
    }

    final targetOrderId = targetTable.currentOrderId;
    if (_apiClient != null &&
        _isOnline &&
        targetOrderId != null &&
        !targetOrderId.startsWith('ord-')) {
      try {
        await _apiClient!.updateOrder(targetOrderId, {
          'note': updatedNotes[targetTableId],
        });
      } catch (e) {
        print('Lỗi cập nhật ghi chú bàn đích: $e');
      }
    }

    await _saveSessionState();
    return true;
  }

  void cancelUnpaidInvoice(String invoiceId, String reason) {
    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == invoiceId,
    );
    if (invoiceIndex < 0) return;

    final invoice = state.unpaidInvoices[invoiceIndex];

    // 1. Remove from in-memory state immediately
    final updatedUnpaid = List<UnpaidInvoice>.from(state.unpaidInvoices)
      ..removeAt(invoiceIndex);
    final newSelectedId = state.selectedUnpaidInvoiceId == invoiceId
        ? null
        : state.selectedUnpaidInvoiceId;
    state = state.copyWith(
      unpaidInvoices: updatedUnpaid,
      selectedUnpaidInvoiceId: newSelectedId,
    );
    _saveSessionState();

    // 2. Persist to local DB and attempt backend sync
    _persistCancelledInvoice(invoice, reason);
  }

  Future<void> _persistCancelledInvoice(
    UnpaidInvoice invoice,
    String reason,
  ) async {
    if (_localDb == null) return;

    final cancelData = {
      'order_id': invoice.id,
      'table_id': invoice.tableId,
      'table_name': invoice.tableName,
      'start_time': invoice.startTime.toIso8601String(),
      'end_time': invoice.endTime.toIso8601String(),
      'play_minutes': invoice.playMinutes,
      'play_amount': invoice.playAmount,
      'products': invoice.products,
      'cancel_reason': reason,
      'cancelled_at': DateTime.now().toIso8601String(),
    };

    try {
      await _localDb!.saveCancelledInvoice(
        id: 'cancel-${invoice.id}',
        orderId: invoice.id,
        tableName: invoice.tableName,
        cancelReason: reason,
        data: cancelData,
      );
    } catch (e) {
      print('Lỗi lưu huỷ hóa đơn local: $e');
    }

    // 3. Attempt immediate backend sync
    if (_apiClient != null && _isOnline) {
      try {
        await _apiClient!.voidOrder(invoice.id, reason);
        await _localDb!.markCancelledInvoiceSynced('cancel-${invoice.id}');
      } catch (e) {
        // Offline or error — record stays as unsynced for later sync
        print('Lỗi sync huỷ hóa đơn lên backend (sẽ thử lại sau): $e');
      }
    }
  }

  void setTableMaintenance(String tableId, bool isMaintenance) {
    final index = state.tables.indexWhere((t) => t.id == tableId);
    if (index < 0) return;
    final updated = List<TableModel>.from(state.tables);
    updated[index] = state.tables[index].copyWith(
      status: isMaintenance ? 'maintenance' : 'idle',
    );
    state = state.copyWith(tables: updated);
    _saveSessionState();
  }

  void addProductToTable(String targetId, Map<String, dynamic> product) {
    if (state.connectedIp != null) {
      final updatedPending = Map<String, List<Map<String, dynamic>>>.from(state.tablePendingOrders);
      final items = List<Map<String, dynamic>>.from(updatedPending[targetId] ?? []);
      
      final existing = items.indexWhere((p) => p['product_id'] == product['product_id']);
      final int addedQty = product['qty'] as int? ?? 1;

      if (existing >= 0) {
        items[existing] = {
          ...items[existing],
          'qty': (items[existing]['qty'] as int) + addedQty,
        };
      } else {
        items.add({...product, 'qty': addedQty});
      }

      updatedPending[targetId] = items;
      state = state.copyWith(tablePendingOrders: updatedPending);
      _saveSessionState();
      return;
    }

    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == targetId,
    );
    if (invoiceIndex >= 0) {
      final inv = state.unpaidInvoices[invoiceIndex];
      final items = List<Map<String, dynamic>>.from(inv.products);
      final existing = items.indexWhere(
        (p) => p['product_id'] == product['product_id'],
      );
      if (existing >= 0) {
        items[existing] = {
          ...items[existing],
          'qty':
              (items[existing]['qty'] as int) + (product['qty'] as int? ?? 1),
        };
      } else {
        items.add({...product, 'qty': product['qty'] ?? 1});
      }
      final updatedUnpaid = List<UnpaidInvoice>.from(state.unpaidInvoices);
      updatedUnpaid[invoiceIndex] = inv.copyWith(products: items);
      state = state.copyWith(unpaidInvoices: updatedUnpaid);
      _saveSessionState();
      return;
    }

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    final items = List<Map<String, dynamic>>.from(
      updatedOrders[targetId] ?? [],
    );

    final existing = items.indexWhere(
      (p) => p['product_id'] == product['product_id'],
    );
    final int addedQty = product['qty'] as int? ?? 1;

    if (existing >= 0) {
      items[existing] = {
        ...items[existing],
        'qty': (items[existing]['qty'] as int) + addedQty,
      };
    } else {
      items.add({...product, 'qty': addedQty});
    }

    updatedOrders[targetId] = items;
    state = state.copyWith(tableOrders: updatedOrders);
    _saveSessionState();
  }

  void removeProductFromTable(String targetId, String productId) {
    if (state.connectedIp != null) {
      final updatedPending = Map<String, List<Map<String, dynamic>>>.from(state.tablePendingOrders);
      final items = List<Map<String, dynamic>>.from(updatedPending[targetId] ?? []);
      items.removeWhere((p) => p['product_id'] == productId);
      updatedPending[targetId] = items;
      state = state.copyWith(tablePendingOrders: updatedPending);
      _saveSessionState();
      return;
    }

    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == targetId,
    );
    if (invoiceIndex >= 0) {
      final inv = state.unpaidInvoices[invoiceIndex];
      final items = List<Map<String, dynamic>>.from(inv.products);
      items.removeWhere((p) => p['product_id'] == productId);
      final updatedUnpaid = List<UnpaidInvoice>.from(state.unpaidInvoices);
      updatedUnpaid[invoiceIndex] = inv.copyWith(products: items);
      state = state.copyWith(unpaidInvoices: updatedUnpaid);
      _saveSessionState();
      return;
    }

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    final items = List<Map<String, dynamic>>.from(
      updatedOrders[targetId] ?? [],
    );
    items.removeWhere((p) => p['product_id'] == productId);
    updatedOrders[targetId] = items;
    state = state.copyWith(tableOrders: updatedOrders);
    _saveSessionState();
  }

  void updateProductQty(String targetId, String productId, int delta) {
    if (state.connectedIp != null) {
      final updatedPending = Map<String, List<Map<String, dynamic>>>.from(state.tablePendingOrders);
      final items = List<Map<String, dynamic>>.from(updatedPending[targetId] ?? []);
      final existing = items.indexWhere((p) => p['product_id'] == productId);
      if (existing >= 0) {
        final newQty = (items[existing]['qty'] as int) + delta;
        if (newQty <= 0) {
          items.removeAt(existing);
        } else {
          items[existing] = {...items[existing], 'qty': newQty};
        }
        updatedPending[targetId] = items;
        state = state.copyWith(tablePendingOrders: updatedPending);
        _saveSessionState();
      }
      return;
    }

    final invoiceIndex = state.unpaidInvoices.indexWhere(
      (inv) => inv.id == targetId,
    );
    if (invoiceIndex >= 0) {
      final inv = state.unpaidInvoices[invoiceIndex];
      final items = List<Map<String, dynamic>>.from(inv.products);
      final existing = items.indexWhere((p) => p['product_id'] == productId);
      if (existing >= 0) {
        final newQty = (items[existing]['qty'] as int) + delta;
        if (newQty <= 0) {
          items.removeAt(existing);
        } else {
          items[existing] = {...items[existing], 'qty': newQty};
        }
        final updatedUnpaid = List<UnpaidInvoice>.from(state.unpaidInvoices);
        updatedUnpaid[invoiceIndex] = inv.copyWith(products: items);
        state = state.copyWith(unpaidInvoices: updatedUnpaid);
        _saveSessionState();
      }
      return;
    }

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(
      state.tableOrders,
    );
    final items = List<Map<String, dynamic>>.from(
      updatedOrders[targetId] ?? [],
    );
    final existing = items.indexWhere((p) => p['product_id'] == productId);
    if (existing >= 0) {
      final newQty = (items[existing]['qty'] as int) + delta;
      if (newQty <= 0) {
        items.removeAt(existing);
      } else {
        items[existing] = {...items[existing], 'qty': newQty};
      }
      updatedOrders[targetId] = items;
      state = state.copyWith(tableOrders: updatedOrders);
      _saveSessionState();
    }
  }

  void approvePendingProduct(String targetId, String productId) {
    final pendingItems = List<Map<String, dynamic>>.from(state.tablePendingOrders[targetId] ?? []);
    final itemIndex = pendingItems.indexWhere((p) => p['product_id'] == productId);
    if (itemIndex < 0) return;
    final approvedItem = pendingItems.removeAt(itemIndex);

    final updatedPending = Map<String, List<Map<String, dynamic>>>.from(state.tablePendingOrders);
    updatedPending[targetId] = pendingItems;

    final updatedOrders = Map<String, List<Map<String, dynamic>>>.from(state.tableOrders);
    final approvedItems = List<Map<String, dynamic>>.from(state.tableOrders[targetId] ?? []);
    
    final existingIndex = approvedItems.indexWhere((p) => p['product_id'] == productId);
    if (existingIndex >= 0) {
      approvedItems[existingIndex] = {
        ...approvedItems[existingIndex],
        'qty': (approvedItems[existingIndex]['qty'] as int) + (approvedItem['qty'] as int),
      };
    } else {
      approvedItems.add(approvedItem);
    }
    updatedOrders[targetId] = approvedItems;

    state = state.copyWith(
      tablePendingOrders: updatedPending,
      tableOrders: updatedOrders,
    );
    _saveSessionState();
  }

  void denyPendingProduct(String targetId, String productId) {
    final pendingItems = List<Map<String, dynamic>>.from(state.tablePendingOrders[targetId] ?? []);
    final itemIndex = pendingItems.indexWhere((p) => p['product_id'] == productId);
    if (itemIndex < 0) return;
    pendingItems.removeAt(itemIndex);

    final updatedPending = Map<String, List<Map<String, dynamic>>>.from(state.tablePendingOrders);
    updatedPending[targetId] = pendingItems;

    state = state.copyWith(
      tablePendingOrders: updatedPending,
    );
    _saveSessionState();
  }

  void completeUnpaidInvoicePayment(String invoiceId) {
    final updatedUnpaid = List<UnpaidInvoice>.from(state.unpaidInvoices)
      ..removeWhere((inv) => inv.id == invoiceId);
    state = state.copyWith(
      unpaidInvoices: updatedUnpaid,
      selectedUnpaidInvoiceId: null,
      selectedTableId: state.tables.isNotEmpty ? state.tables.first.id : null,
    );
    _saveSessionState();
  }

  void updateIotConfig(String tableId, IotConfigModel config) {
    final updated = Map<String, IotConfigModel>.from(state.iotConfigs);
    updated[tableId] = config;
    state = state.copyWith(iotConfigs: updated);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _reconnectTimer?.cancel();
    _ws?.close();
    for (final c in _controllers.values) {
      c.disconnect();
    }
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final tablesProvider = StateNotifierProvider<TablesNotifier, TablesState>((
  ref,
) {
  final localDb = ref.watch(localDbServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final syncService = ref.watch(syncServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final notifier = TablesNotifier(
    localDb: localDb,
    apiClient: apiClient,
    syncService: syncService,
    prefs: prefs,
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
