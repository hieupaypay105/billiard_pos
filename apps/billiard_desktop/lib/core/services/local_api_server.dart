import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tables/tables_provider.dart';
import '../providers/providers.dart';
import '../providers/device_connection_provider.dart';
import 'local_db_service.dart';

class LocalApiServer {
  final Ref _ref;
  final LocalDbService _localDb;
  HttpServer? _server;
  bool _isRunning = false;
  final List<WebSocket> _clients = [];

  LocalApiServer(this._ref, this._localDb);

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8085);
      _isRunning = true;
      print("Local API Server running on port 8085");
      
      _server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path == '/ws') {
          final deviceId = request.headers.value('x-device-id');
          if (deviceId == null || !_ref.read(deviceConnectionProvider.notifier).isApproved(deviceId)) {
            await _sendError(request, HttpStatus.forbidden, 'Unauthorized WebSocket connection');
            return;
          }
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            try {
              final socket = await WebSocketTransformer.upgrade(request);
              _clients.add(socket);
              print("Mobile client connected via WebSocket");
              socket.listen((msg) {}, onDone: () {
                _clients.remove(socket);
                print("Mobile client disconnected");
              }, onError: (e) {
                _clients.remove(socket);
                print("Mobile client connection error: $e");
              });
            } catch (e) {
              print("Lỗi nâng cấp WebSocket: $e");
            }
            return;
          }
        }

        // Enable CORS
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, X-Requested-With, x-device-id');
        
        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        // Validate access
        if (path.startsWith('/api/') && path != '/api/ping' && path != '/api/request-access') {
          final deviceId = request.headers.value('x-device-id');
          if (deviceId == null || !_ref.read(deviceConnectionProvider.notifier).isApproved(deviceId)) {
            await _sendError(request, HttpStatus.forbidden, 'Unauthorized device connection');
            return;
          }
        }

        try {
          final path = request.uri.path;
          if (path == '/api/ping') {
            await _sendJson(request, {'status': 1, 'app': 'billiard_pos'});
          } else if (path == '/api/request-access' && request.method == 'POST') {
            final body = await _readBody(request);
            final deviceId = body['device_id'] as String?;
            final deviceName = body['device_name'] as String? ?? 'Thiết bị';
            final os = body['os'] as String? ?? 'Unknown';
            final ip = request.connectionInfo?.remoteAddress.address ?? 'Unknown';

            if (deviceId != null) {
              final notifier = _ref.read(deviceConnectionProvider.notifier);
              if (notifier.isApproved(deviceId)) {
                await _sendJson(request, {'status': 1, 'access': 'approved'});
              } else if (notifier.isDenied(deviceId)) {
                await _sendJson(request, {'status': 0, 'access': 'denied'});
              } else {
                notifier.addRequest(DeviceRequest(
                  deviceId: deviceId,
                  deviceName: deviceName,
                  os: os,
                  ip: ip,
                ));
                await _sendJson(request, {'status': 1, 'access': 'pending'});
              }
            } else {
              await _sendError(request, HttpStatus.badRequest, 'Missing device_id');
            }
          } else if (path == '/api/session' && request.method == 'GET') {
            final session = await _localDb.getSetting('billiard_active_session');
            final tables = await _localDb.getCachedTables();
            final products = await _localDb.getCachedProducts();
            final categories = await _localDb.getCachedProductCategories();
            final members = await _localDb.getCachedMembers();
            final prices = await _localDb.getCachedTablePrices();
            final types = await _localDb.getCachedTableTypes();
            final tiers = await _localDb.getCachedMembershipTiers();
            final invoiceTemplate = await _localDb.getInvoiceTemplate();

            await _sendJson(request, {
              'status': 1,
              'session': session,
              'tables': tables,
              'products': products,
              'categories': categories,
              'members': members,
              'prices': prices,
              'types': types,
              'tiers': tiers,
              'invoice_template': invoiceTemplate,
            });
          } else if (path == '/api/session' && request.method == 'POST') {
            final body = await _readBody(request);
            final session = body['session'] as String?;
            if (session != null) {
              await _localDb.setSetting('billiard_active_session', session);
              // Trigger reload in desktop app
              _ref.read(tablesProvider.notifier).loadTables();
              await _sendJson(request, {'status': 1, 'message': 'Session updated'});
            } else {
              await _sendError(request, HttpStatus.badRequest, 'Missing session');
            }
          } else if (path == '/api/order' && request.method == 'POST') {
            final body = await _readBody(request);
            final id = body['id'] as String?;
            final payload = body['payload'] as Map<String, dynamic>?;
            if (id != null && payload != null) {
              await _localDb.saveOrderLocally(id, payload);
              // Trigger desktop sync with cloud backend
              _ref.read(syncServiceProvider).syncNow();
              await _sendJson(request, {'status': 1, 'message': 'Order saved'});
            } else {
              await _sendError(request, HttpStatus.badRequest, 'Missing id or payload');
            }
          } else if (path == '/api/cancel-invoice' && request.method == 'POST') {
            final body = await _readBody(request);
            final id = body['id'] as String?;
            final orderId = body['orderId'] as String?;
            final tableName = body['tableName'] as String?;
            final cancelReason = body['cancelReason'] as String?;
            final data = body['data'] as Map<String, dynamic>?;
            if (id != null && orderId != null && tableName != null && cancelReason != null && data != null) {
              await _localDb.saveCancelledInvoice(
                id: id,
                orderId: orderId,
                tableName: tableName,
                cancelReason: cancelReason,
                data: data,
              );
              // Trigger desktop sync with cloud backend
              _ref.read(syncServiceProvider).syncNow();
              await _sendJson(request, {'status': 1, 'message': 'Cancelled invoice saved'});
            } else {
              await _sendError(request, HttpStatus.badRequest, 'Missing fields');
            }
          } else if (path == '/api/db-query' && request.method == 'POST') {
            final body = await _readBody(request);
            final method = body['method'] as String?;
            final args = body['args'] as Map<String, dynamic>? ?? {};
            if (method != null) {
              final result = await _handleDbQuery(method, args);
              await _sendJson(request, {'status': 1, 'result': result});
            } else {
              await _sendError(request, HttpStatus.badRequest, 'Missing method');
            }
          } else if (path == '/api/iot/control' && request.method == 'POST') {
            final body = await _readBody(request);
            final tableId = body['tableId'] as String?;
            final turnOn = body['turnOn'] as bool?;
            if (tableId != null && turnOn != null) {
              final success = await _ref.read(tablesProvider.notifier).controlRelay(tableId, turnOn);
              await _sendJson(request, {
                'status': success ? 1 : 0,
                'message': success ? 'Relay command executed' : 'Failed to execute relay command',
              });
            } else {
              await _sendError(request, HttpStatus.badRequest, 'Missing tableId or turnOn');
            }
          } else {
            await _sendError(request, HttpStatus.notFound, 'Not Found');
          }
        } catch (e) {
          await _sendError(request, HttpStatus.internalServerError, e.toString());
        }
      });
    } catch (e) {
      print("Error starting Local API Server: $e");
    }
  }

  void notifyClients() {
    print("Broadcasting session update to ${_clients.length} clients...");
    for (final client in _clients) {
      try {
        client.add(jsonEncode({'event': 'session_updated'}));
      } catch (e) {
        print("Lỗi gửi tin nhắn cho client: $e");
      }
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    print("Local API Server stopped");
  }

  Future<Map<String, dynamic>> _readBody(HttpRequest request) async {
    final bodyStr = await utf8.decodeStream(request);
    if (bodyStr.isEmpty) return {};
    return jsonDecode(bodyStr) as Map<String, dynamic>;
  }

  Future<void> _sendJson(HttpRequest request, Map<String, dynamic> data) async {
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    await request.response.close();
  }

  Future<dynamic> _handleDbQuery(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'saveOrderLocally':
        await _localDb.saveOrderLocally(
          args['id'] as String,
          Map<String, dynamic>.from(args['orderData'] as Map),
        );
        return null;
      case 'getPendingOrders':
        return await _localDb.getPendingOrders();
      case 'markOrderSynced':
        await _localDb.markOrderSynced(args['id'] as String);
        return null;
      case 'getPendingCount':
        return await _localDb.getPendingCount();
      case 'getAllLocalOrders':
        return await _localDb.getAllLocalOrders();
      case 'getOrdersInDateRange':
        return await _localDb.getOrdersInDateRange(
          DateTime.parse(args['from'] as String),
          DateTime.parse(args['to'] as String),
        );
      case 'cacheTable':
        await _localDb.cacheTable(
          args['id'] as String,
          Map<String, dynamic>.from(args['data'] as Map),
        );
        return null;
      case 'getCachedTables':
        return await _localDb.getCachedTables();
      case 'cacheProducts':
        await _localDb.cacheProducts(
          List<Map<String, dynamic>>.from(args['products'] as List),
        );
        return null;
      case 'getCachedProducts':
        return await _localDb.getCachedProducts();
      case 'cacheMembers':
        await _localDb.cacheMembers(
          List<Map<String, dynamic>>.from(args['members'] as List),
        );
        return null;
      case 'getCachedMembers':
        return await _localDb.getCachedMembers();
      case 'getMemberByPhone':
        return await _localDb.getMemberByPhone(args['phone'] as String);
      case 'searchMembers':
        return await _localDb.searchMembers(args['query'] as String);
      case 'cacheIotConfigs':
        await _localDb.cacheIotConfigs(
          List<Map<String, dynamic>>.from(args['configs'] as List),
        );
        return null;
      case 'getCachedIotConfigs':
        return await _localDb.getCachedIotConfigs();
      case 'cacheProductCategories':
        await _localDb.cacheProductCategories(
          List<Map<String, dynamic>>.from(args['categories'] as List),
        );
        return null;
      case 'getCachedProductCategories':
        return await _localDb.getCachedProductCategories();
      case 'cacheTableTypes':
        await _localDb.cacheTableTypes(
          List<Map<String, dynamic>>.from(args['types'] as List),
        );
        return null;
      case 'getCachedTableTypes':
        return await _localDb.getCachedTableTypes();
      case 'cacheTablePrices':
        await _localDb.cacheTablePrices(
          List<Map<String, dynamic>>.from(args['prices'] as List),
        );
        return null;
      case 'getCachedTablePrices':
        return await _localDb.getCachedTablePrices();
      case 'cacheMembershipTiers':
        await _localDb.cacheMembershipTiers(
          List<Map<String, dynamic>>.from(args['tiers'] as List),
        );
        return null;
      case 'getCachedMembershipTiers':
        return await _localDb.getCachedMembershipTiers();
      case 'saveCancelledInvoice':
        await _localDb.saveCancelledInvoice(
          id: args['id'] as String,
          orderId: args['orderId'] as String,
          tableName: args['tableName'] as String,
          cancelReason: args['cancelReason'] as String,
          data: Map<String, dynamic>.from(args['data'] as Map),
        );
        return null;
      case 'getUnsyncedCancelledInvoices':
        return await _localDb.getUnsyncedCancelledInvoices();
      case 'markCancelledInvoiceSynced':
        await _localDb.markCancelledInvoiceSynced(args['id'] as String);
        return null;
      case 'saveActiveShift':
        await _localDb.saveActiveShift(
          id: args['id'] as String,
          userId: args['userId'] as String,
          openedAt: DateTime.parse(args['openedAt'] as String),
          data: Map<String, dynamic>.from(args['data'] as Map),
        );
        return null;
      case 'getActiveShift':
        return await _localDb.getActiveShift();
      case 'clearActiveShift':
        await _localDb.clearActiveShift();
        return null;
      case 'setSetting':
        final key = args['key'] as String;
        final value = args['value'] as String;
        await _localDb.setSetting(key, value);
        if (key == 'billiard_active_session') {
          _ref.read(tablesProvider.notifier).loadTables();
          notifyClients();
        }
        return null;
      case 'getSetting':
        return await _localDb.getSetting(args['key'] as String);
      case 'saveInvoiceTemplate':
        await _localDb.saveInvoiceTemplate(
          Map<String, dynamic>.from(args['data'] as Map),
        );
        return null;
      case 'getInvoiceTemplate':
        return await _localDb.getInvoiceTemplate();
      case 'clearInvoiceTemplate':
        await _localDb.clearInvoiceTemplate();
        return null;
      case 'clearAllData':
        await _localDb.clearAllData();
        return null;
      default:
        throw UnimplementedError('Method $method not implemented');
    }
  }

  Future<void> _sendError(HttpRequest request, int code, String message) async {
    request.response.statusCode = code;
    request.response.headers.contentType = ContentType.text;
    request.response.write(message);
    await request.response.close();
  }
}
