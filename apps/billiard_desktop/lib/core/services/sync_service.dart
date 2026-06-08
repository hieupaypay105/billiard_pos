import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db_service.dart';
import 'api_client.dart';

/// Trạng thái kết nối mạng.
enum ConnectivityStatus { online, offline }

/// Service quản lý đồng bộ dữ liệu Offline-First.
///
/// Khi offline: dữ liệu lưu xuống SQLite local DB.
/// Khi online trở lại: tự động push pending records lên backend.
class SyncService {
  final LocalDbService _localDb;
  final ApiClient _apiClient;

  final _statusController =
      StreamController<ConnectivityStatus>.broadcast();
  final _logController = StreamController<String>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;
  Stream<String> get logStream => _logController.stream;
  ConnectivityStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  final List<String> _syncLog = [];
  List<String> get syncLog => List.unmodifiable(_syncLog);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncService({required LocalDbService localDb, required ApiClient apiClient})
      : _localDb = localDb,
        _apiClient = apiClient;

  /// Khởi động listener kết nối mạng.
  Future<void> initialize() async {
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final hasNetwork = results.any((r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.mobile);
        final newStatus = hasNetwork
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline;
        if (newStatus != _currentStatus) {
          _currentStatus = newStatus;
          _statusController.add(newStatus);
          _log('Network status changed: ${newStatus.name.toUpperCase()}');
          if (newStatus == ConnectivityStatus.online) {
            await _syncPendingRecords();
            await pullOnlineDataToOffline();
          }
        }
      },
    );

    // Kiểm tra trạng thái hiện tại ngay lập tức
    final result = await Connectivity().checkConnectivity();
    final hasNetwork = result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.mobile);
    _currentStatus = hasNetwork
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
    _statusController.add(_currentStatus);
    await _refreshPendingCount();

    if (_currentStatus == ConnectivityStatus.online) {
      Future.microtask(() async {
        await _syncPendingRecords();
        await pullOnlineDataToOffline();
      });
    }
  }

  /// Kích hoạt sync thủ công.
  Future<SyncResult> syncNow() async {
    if (!isOnline) {
      return SyncResult(success: false, message: 'Không có kết nối mạng', synced: 0);
    }
    return _syncPendingRecords();
  }

  /// Giả lập trạng thái offline.
  void simulateOffline() {
    _currentStatus = ConnectivityStatus.offline;
    _statusController.add(ConnectivityStatus.offline);
    _log('WARNING: Mất kết nối mạng. Chuyển sang chế độ offline.');
  }

  /// Giả lập trạng thái online.
  void simulateOnline() {
    _currentStatus = ConnectivityStatus.online;
    _statusController.add(ConnectivityStatus.online);
    _log('Kết nối mạng được khôi phục.');
  }

  /// Xóa toàn bộ dữ liệu cache SQLite local.
  Future<void> clearAllLocalData() async {
    _log('Bắt đầu xóa dữ liệu SQLite local...');
    try {
      await _localDb.clearAllData();
      _pendingCount = 0;
      _log('Đã xóa dữ liệu SQLite local thành công.');
    } catch (e) {
      _log('LỖI khi xóa dữ liệu local: $e');
      rethrow;
    }
  }

  /// Pull toàn bộ dữ liệu từ server (Online) về lưu trữ SQLite (Offline).
  /// Luôn xóa cache cũ trước khi ghi mới để tránh hiển thị dữ liệu lỗi thời.
  Future<SyncResult> pullOnlineDataToOffline() async {
    if (!isOnline) {
      return SyncResult(success: false, message: 'Không có kết nối mạng', synced: 0);
    }
    _log('Bắt đầu tải dữ liệu từ server về local...');
    int totalPulled = 0;

    // 1. Đồng bộ Danh sách bàn
    try {
      _log('Đang tải danh sách bàn từ server...');
      final tables = await _apiClient.getTables();
      final validTables = tables
          .whereType<Map<String, dynamic>>()
          .where((t) =>
              (t['id']?.toString() ?? t['table_id']?.toString() ?? '').isNotEmpty)
          .toList();

      // ⚠️ Xóa cache cũ TRƯỚC khi ghi mới để tránh dữ liệu lỗi thời
      await _localDb.clearCachedTables();
      for (final table in validTables) {
        final id = table['id']?.toString() ?? table['table_id']!.toString();
        await _localDb.cacheTable(id, table);
      }
      _log('Đã lưu offline ${validTables.length} bàn.');
      totalPulled += validTables.length;
    } catch (e) {
      _log('LỖI tải danh sách bàn: $e');
    }

    // 2. Đồng bộ sản phẩm
    try {
      _log('Đang tải danh sách sản phẩm từ server...');
      final products = await _apiClient.getProducts();
      final productsToCache =
          products.whereType<Map<String, dynamic>>().toList();

      // ⚠️ Xóa cache cũ TRƯỚC khi ghi mới
      await _localDb.clearCachedProducts();
      if (productsToCache.isNotEmpty) {
        await _localDb.cacheProducts(productsToCache);
      }
      _log('Đã lưu offline ${productsToCache.length} sản phẩm.');
      totalPulled += productsToCache.length;
    } catch (e) {
      _log('LỖI tải danh sách sản phẩm: $e');
    }

    // 3. Đồng bộ Khách hàng hội viên
    try {
      _log('Đang tải danh sách hội viên từ server...');
      final members = await _apiClient.getMembers(page: 1, limit: 100);
      final membersToCache = members.whereType<Map<String, dynamic>>().toList();

      // ⚠️ Xóa cache cũ TRƯỚC khi ghi mới
      await _localDb.clearCachedMembers();
      if (membersToCache.isNotEmpty) {
        await _localDb.cacheMembers(membersToCache);
      }
      _log('Đã lưu offline ${membersToCache.length} hội viên.');
      totalPulled += membersToCache.length;
    } catch (e) {
      _log('LỖI tải danh sách hội viên: $e');
    }

    // 4. Đồng bộ Cấu hình IoT
    try {
      _log('Đang tải cấu hình IoT từ server...');
      final configs = await _apiClient.getIotConfigs();
      final configsToCache = configs.whereType<Map<String, dynamic>>().toList();
      await _localDb.clearCachedIotConfigs();
      if (configsToCache.isNotEmpty) {
        await _localDb.cacheIotConfigs(configsToCache);
      }
      _log('Đã lưu offline ${configsToCache.length} cấu hình IoT.');
      totalPulled += configsToCache.length;
    } catch (e) {
      _log('LỖI tải cấu hình IoT: $e');
    }

    // 5. Đồng bộ Danh mục sản phẩm
    try {
      _log('Đang tải danh mục sản phẩm từ server...');
      final categories = await _apiClient.getProductCategories();
      final categoriesToCache = categories.whereType<Map<String, dynamic>>().toList();
      await _localDb.clearCachedProductCategories();
      if (categoriesToCache.isNotEmpty) {
        await _localDb.cacheProductCategories(categoriesToCache);
      }
      _log('Đã lưu offline ${categoriesToCache.length} danh mục sản phẩm.');
      totalPulled += categoriesToCache.length;
    } catch (e) {
      _log('LỖI tải danh mục sản phẩm: $e');
    }

    // 6. Đồng bộ Loại bàn chơi
    try {
      _log('Đang tải loại bàn chơi từ server...');
      final types = await _apiClient.getTableTypes();
      final typesToCache = types.whereType<Map<String, dynamic>>().toList();
      await _localDb.clearCachedTableTypes();
      if (typesToCache.isNotEmpty) {
        await _localDb.cacheTableTypes(typesToCache);
      }
      _log('Đã lưu offline ${typesToCache.length} loại bàn chơi.');
      totalPulled += typesToCache.length;
    } catch (e) {
      _log('LỖI tải loại bàn chơi: $e');
    }

    // 7. Đồng bộ Khung giá giờ
    try {
      _log('Đang tải khung giá giờ từ server...');
      final prices = await _apiClient.getTablePrices();
      final pricesToCache = prices.whereType<Map<String, dynamic>>().toList();
      await _localDb.clearCachedTablePrices();
      if (pricesToCache.isNotEmpty) {
        await _localDb.cacheTablePrices(pricesToCache);
      }
      _log('Đã lưu offline ${pricesToCache.length} khung giá giờ.');
      totalPulled += pricesToCache.length;
    } catch (e) {
      _log('LỖI tải khung giá giờ: $e');
    }

    // 8. Đồng bộ Hạng thành viên
    try {
      _log('Đang tải hạng thành viên từ server...');
      final tiers = await _apiClient.getMembershipTiers();
      final tiersToCache = tiers.whereType<Map<String, dynamic>>().toList();
      await _localDb.clearCachedMembershipTiers();
      if (tiersToCache.isNotEmpty) {
        await _localDb.cacheMembershipTiers(tiersToCache);
      }
      _log('Đã lưu offline ${tiersToCache.length} hạng thành viên.');
      totalPulled += tiersToCache.length;
    } catch (e) {
      _log('LỖI tải hạng thành viên: $e');
    }

    // 9. Đồng bộ mẫu hóa đơn K80
    try {
      _log('Đang tải cấu hình mẫu hóa đơn từ server...');
      final template = await _apiClient.getInvoiceTemplate();
      if (template != null) {
        await _localDb.saveInvoiceTemplate(template);
        totalPulled += 1;
        _log('Đã lưu mẫu hóa đơn xuống local.');
      }
    } catch (e) {
      _log('LỖI tải mẫu hóa đơn: $e');
    }

    _log('Đồng bộ tải dữ liệu online -> offline hoàn tất. Tổng cộng $totalPulled bản ghi.');
    return SyncResult(
      success: true,
      message: 'Đồng bộ tải thành công $totalPulled bản ghi.',
      synced: totalPulled,
    );
  }


  Future<SyncResult> _syncPendingRecords() async {
    _log('Starting sync...');
    int synced = 0;

    try {
      final pendingOrders = await _localDb.getPendingOrders();
      if (pendingOrders.isEmpty) {
        _log('No pending records to sync.');
        return const SyncResult(success: true, message: 'Không có dữ liệu chờ', synced: 0);
      }

      _log('Syncing ${pendingOrders.length} pending orders...');

      final List<Map<String, dynamic>> orders = [];
      final List<Map<String, dynamic>> details = [];
      final List<Map<String, dynamic>> members = [];
      final List<Map<String, dynamic>> shifts = [];
      final List<Map<String, dynamic>> auditLogs = [];

      for (final item in pendingOrders) {
        if (item.containsKey('order')) {
          final orderMap = item['order'] as Map<String, dynamic>?;
          if (orderMap != null) {
            orders.add(orderMap);
          }
        }
        if (item.containsKey('details')) {
          final detailsList = item['details'] as List<dynamic>?;
          if (detailsList != null) {
            for (final d in detailsList) {
              if (d is Map<String, dynamic>) {
                details.add(d);
              }
            }
          }
        }
        if (item.containsKey('member')) {
          final memberMap = item['member'] as Map<String, dynamic>?;
          if (memberMap != null) {
            members.add(memberMap);
          }
        }
        if (item.containsKey('shift')) {
          final shiftMap = item['shift'] as Map<String, dynamic>?;
          if (shiftMap != null) {
            shifts.add(shiftMap);
          }
        }
        if (item.containsKey('audit_logs')) {
          final logsList = item['audit_logs'] as List<dynamic>?;
          if (logsList != null) {
            for (final log in logsList) {
              if (log is Map<String, dynamic>) {
                auditLogs.add(log);
              }
            }
          }
        }
      }

      final payload = {
        'orders': orders,
        'order_details': details,
        'members': members,
        'shifts': shifts,
        'audit_logs': auditLogs,
      };

      final result = await _apiClient.syncOrders(payload);
      final status = result['status'];
      final isSuccess = status == 1 || status == '1';

      if (isSuccess) {
        final syncedIds = (result['synced_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        if (syncedIds.isNotEmpty) {
          for (final id in syncedIds) {
            await _localDb.markOrderSynced(id);
            synced++;
          }
        } else {
          // Fallback: mark all orders in this batch as synced
          for (final o in orders) {
            final id = o['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              await _localDb.markOrderSynced(id);
              synced++;
            }
          }
        }
      } else {
        throw Exception(result['message'] ?? 'Unknown backend error');
      }

      final failed = pendingOrders.length - synced;
      await _refreshPendingCount();
      _log('Sync complete: $synced synced, $failed failed.');
      return SyncResult(
          success: true,
          message: 'Đồng bộ xong: $synced thành công${failed > 0 ? ", $failed lỗi" : ""}',
          synced: synced);
    } catch (e) {
      _log('Sync error: $e');
      return SyncResult(success: false, message: 'Lỗi đồng bộ: $e', synced: synced);
    }
  }

  Future<void> _refreshPendingCount() async {
    _pendingCount = await _localDb.getPendingCount();
  }

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    final entry = '[$ts] $msg';
    _syncLog.add(entry);
    if (_syncLog.length > 200) _syncLog.removeAt(0);
    _logController.add(entry);
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _statusController.close();
    await _logController.close();
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int synced;
  const SyncResult(
      {required this.success, required this.message, required this.synced});
}
