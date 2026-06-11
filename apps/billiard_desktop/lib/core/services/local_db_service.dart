import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// SQLite local database service cho chế độ Offline-First.
///
/// Lưu trữ orders chờ sync, cache dữ liệu sản phẩm, bàn, etc.
class LocalDbService {
  static const _dbName = 'billiard_pos_local.db';
  static const _dbVersion = 5;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    print("Đường dẫn chính xác của DB là: $path");
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Pending orders chờ sync
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_orders (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache bảng
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_tables (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache sản phẩm
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_products (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache thành viên (tìm kiếm offline)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_members (
        id TEXT PRIMARY KEY,
        phone_number TEXT,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache IoT configs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_iot_configs (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache product categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_product_categories (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache table types
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_table_types (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache table prices
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_table_prices (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cache membership tiers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_membership_tiers (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Cancelled invoices (local audit log)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cancelled_invoices (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        table_name TEXT NOT NULL,
        cancel_reason TEXT NOT NULL,
        cancelled_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0,
        data TEXT NOT NULL
      )
    ''');

    // Active shift (ca làm việc đang mở, lưu local)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_shifts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        opened_at TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');


    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_members_phone ON cached_members(phone_number)',
    );

    // Cache invoice template (mẫu hóa đơn K80)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_invoice_template (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_iot_configs (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updated_at TEXT DEFAULT (datetime('now'))
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_product_categories (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updated_at TEXT DEFAULT (datetime('now'))
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_table_types (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updated_at TEXT DEFAULT (datetime('now'))
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_table_prices (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updated_at TEXT DEFAULT (datetime('now'))
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_membership_tiers (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updated_at TEXT DEFAULT (datetime('now'))
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cancelled_invoices (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          table_name TEXT NOT NULL,
          cancel_reason TEXT NOT NULL,
          cancelled_at TEXT DEFAULT (datetime('now')),
          synced INTEGER DEFAULT 0,
          data TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS active_shifts (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          opened_at TEXT NOT NULL,
          data TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_invoice_template (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updated_at TEXT DEFAULT (datetime('now'))
        )
      ''');
    }
  }

  // ─── Pending Orders ───────────────────────────────────────────────────────────

  Future<void> saveOrderLocally(
    String id,
    Map<String, dynamic> orderData,
  ) async {
    final db = await database;
    await db.insert('pending_orders', {
      'id': id,
      'data': jsonEncode(orderData),
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await database;
    final rows = await db.query(
      'pending_orders',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> markOrderSynced(String id) async {
    final db = await database;
    await db.update(
      'pending_orders',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final ordersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_orders WHERE synced = 0',
    );
    final cancelsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cancelled_invoices WHERE synced = 0',
    );
    final ordersCount = (ordersResult.first['count'] as int?) ?? 0;
    final cancelsCount = (cancelsResult.first['count'] as int?) ?? 0;
    return ordersCount + cancelsCount;
  }

  /// Lấy tất cả orders trong local DB (bao gồm cả đã sync) để dùng cho báo cáo offline.
  Future<List<Map<String, dynamic>>> getAllLocalOrders() async {
    final db = await database;
    final rows = await db.query(
      'pending_orders',
      orderBy: 'created_at DESC',
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Lấy orders trong khoảng ngày (dựa theo created_at) để tạo báo cáo offline.
  Future<List<Map<String, dynamic>>> getOrdersInDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final fromStr = from.toIso8601String().substring(0, 10);
    final toStr = to.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final rows = await db.query(
      'pending_orders',
      where: "date(created_at) >= ? AND date(created_at) < ?",
      whereArgs: [fromStr, toStr],
      orderBy: 'created_at ASC',
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache Tables ─────────────────────────────────────────────────────────────

  Future<void> cacheTable(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('cached_tables', {
      'id': id,
      'data': jsonEncode(data),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCachedTables() async {
    final db = await database;
    final rows = await db.query('cached_tables');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache Products ───────────────────────────────────────────────────────────

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    final batch = db.batch();
    for (final p in products) {
      batch.insert('cached_products', {
        'id': p['id'] as String,
        'data': jsonEncode(p),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    final db = await database;
    final rows = await db.query('cached_products');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache Members ────────────────────────────────────────────────────────────

  Future<void> cacheMembers(List<Map<String, dynamic>> members) async {
    final db = await database;
    final batch = db.batch();
    for (final m in members) {
      batch.insert('cached_members', {
        'id': m['id'] as String,
        'phone_number': m['phone_number'] as String?,
        'data': jsonEncode(m),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> getMemberByPhone(String phone) async {
    final db = await database;
    final rows = await db.query(
      'cached_members',
      where: 'phone_number = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> searchMembers(String query) async {
    final db = await database;
    final rows = await db.query(
      'cached_members',
      where: 'phone_number LIKE ?',
      whereArgs: ['%$query%'],
      limit: 10,
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache IoT Configs ────────────────────────────────────────────────────────

  Future<void> cacheIotConfigs(List<Map<String, dynamic>> configs) async {
    final db = await database;
    final batch = db.batch();
    for (final c in configs) {
      batch.insert('cached_iot_configs', {
        'id': c['id']?.toString() ?? c['table_id']?.toString() ?? '',
        'data': jsonEncode(c),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedIotConfigs() async {
    final db = await database;
    final rows = await db.query('cached_iot_configs');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache Product Categories ─────────────────────────────────────────────────

  Future<void> cacheProductCategories(
    List<Map<String, dynamic>> categories,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final c in categories) {
      batch.insert('cached_product_categories', {
        'id': c['id']?.toString() ?? '',
        'data': jsonEncode(c),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedProductCategories() async {
    final db = await database;
    final rows = await db.query('cached_product_categories');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache Table Types ────────────────────────────────────────────────────────

  Future<void> cacheTableTypes(List<Map<String, dynamic>> types) async {
    final db = await database;
    final batch = db.batch();
    for (final t in types) {
      batch.insert('cached_table_types', {
        'id': t['id']?.toString() ?? '',
        'data': jsonEncode(t),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedTableTypes() async {
    final db = await database;
    final rows = await db.query('cached_table_types');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache Table Prices ───────────────────────────────────────────────────────

  Future<void> cacheTablePrices(List<Map<String, dynamic>> prices) async {
    final db = await database;
    final batch = db.batch();
    for (final p in prices) {
      batch.insert('cached_table_prices', {
        'id': p['id']?.toString() ?? '',
        'data': jsonEncode(p),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedTablePrices() async {
    final db = await database;
    final rows = await db.query('cached_table_prices');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── Cache Membership Tiers ───────────────────────────────────────────────────

  Future<void> cacheMembershipTiers(List<Map<String, dynamic>> tiers) async {
    final db = await database;
    final batch = db.batch();
    for (final t in tiers) {
      batch.insert('cached_membership_tiers', {
        'id': t['id']?.toString() ?? '',
        'data': jsonEncode(t),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedMembershipTiers() async {
    final db = await database;
    final rows = await db.query('cached_membership_tiers');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }


  // ─── Cancelled Invoices ───────────────────────────────────────────────────────

  Future<void> saveCancelledInvoice({
    required String id,
    required String orderId,
    required String tableName,
    required String cancelReason,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert('cancelled_invoices', {
      'id': id,
      'order_id': orderId,
      'table_name': tableName,
      'cancel_reason': cancelReason,
      'data': jsonEncode(data),
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCancelledInvoices() async {
    final db = await database;
    return db.query('cancelled_invoices', where: 'synced = 0', orderBy: 'cancelled_at ASC');
  }

  Future<void> markCancelledInvoiceSynced(String id) async {
    final db = await database;
    await db.update('cancelled_invoices', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Active Shifts ────────────────────────────────────────────────────────────

  Future<void> saveActiveShift({
    required String id,
    required String userId,
    required DateTime openedAt,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    // Only one active shift at a time — clear old ones first
    await db.delete('active_shifts');
    await db.insert('active_shifts', {
      'id': id,
      'user_id': userId,
      'opened_at': openedAt.toIso8601String(),
      'data': jsonEncode(data),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getActiveShift() async {
    final db = await database;
    final rows = await db.query('active_shifts', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
    // Merge top-level fields into data for convenience
    return {
      ...data,
      'id': row['id'],
      'user_id': row['user_id'],
      'opened_at': row['opened_at'],
    };
  }

  Future<void> clearActiveShift() async {
    final db = await database;
    await db.delete('active_shifts');
  }

  // ─── App Settings ─────────────────────────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // ─── Clear Specific Cache ─────────────────────────────────────────────────────

  /// Xóa cache bàn chơi (dùng khi sync mới về từ server).
  Future<void> clearCachedTables() async {
    final db = await database;
    await db.delete('cached_tables');
  }

  /// Xóa cache sản phẩm (dùng khi sync mới về từ server).
  Future<void> clearCachedProducts() async {
    final db = await database;
    await db.delete('cached_products');
  }

  /// Xóa cache hội viên (dùng khi sync mới về từ server).
  Future<void> clearCachedMembers() async {
    final db = await database;
    await db.delete('cached_members');
  }

  Future<void> clearCachedIotConfigs() async {
    final db = await database;
    await db.delete('cached_iot_configs');
  }

  Future<void> clearCachedProductCategories() async {
    final db = await database;
    await db.delete('cached_product_categories');
  }

  Future<void> clearCachedTableTypes() async {
    final db = await database;
    await db.delete('cached_table_types');
  }

  Future<void> clearCachedTablePrices() async {
    final db = await database;
    await db.delete('cached_table_prices');
  }

  Future<void> clearCachedMembershipTiers() async {
    final db = await database;
    await db.delete('cached_membership_tiers');
  }

  // ─── Invoice Template Cache ────────────────────────────────────────────────────

  /// Lưu cấu hình mẫu hóa đơn xuống local DB.
  Future<void> saveInvoiceTemplate(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'cached_invoice_template',
      {
        'id': 'default',
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Đọc cấu hình mẫu hóa đơn từ local DB.
  Future<Map<String, dynamic>?> getInvoiceTemplate() async {
    final db = await database;
    final rows = await db.query(
      'cached_invoice_template',
      where: 'id = ?',
      whereArgs: ['default'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  /// Xóa cache mẫu hóa đơn.
  Future<void> clearInvoiceTemplate() async {
    final db = await database;
    await db.delete('cached_invoice_template');
  }


  // ─── Clear All Data ───────────────────────────────────────────────────────────

  /// Xóa toàn bộ dữ liệu trong tất cả các bảng SQLite local.
  /// Phiên đăng nhập (SharedPreferences) vẫn được giữ nguyên.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('pending_orders');
    await db.delete('cached_tables');
    await db.delete('cached_products');
    await db.delete('cached_members');
    await db.delete('cached_iot_configs');
    await db.delete('cached_product_categories');
    await db.delete('cached_table_types');
    await db.delete('cached_table_prices');
    await db.delete('cached_membership_tiers');
    await db.delete('app_settings');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
