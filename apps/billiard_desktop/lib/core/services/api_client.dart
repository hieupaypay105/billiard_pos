import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

/// HTTP client wrapper sử dụng Dio.
/// - Tự động đính kèm JWT Bearer token vào mọi request.
/// - Tự động refresh token khi nhận 401.
/// - Queue request khi offline (handled by sync_service).
class ApiClient {
  static String get _baseUrl => EnvConfig.apiBaseUrl;
  static String get _loginEndpoint => EnvConfig.userLogin;
  static String get _refreshEndpoint => EnvConfig.userRefresh;

  late final Dio _dio;
  bool _isRefreshing = false;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_logInterceptor());
  }

  // ─── Interceptors ────────────────────────────────────────────────────────────

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          final refreshed = await _tryRefreshToken();
          _isRefreshing = false;
          if (refreshed) {
            // Retry original request with new token
            final prefs = await SharedPreferences.getInstance();
            final newToken = prefs.getString('auth_token') ?? '';
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final retryResponse = await _dio.fetch(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    );
  }

  Interceptor _logInterceptor() {
    return LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => debugPrint('[ApiClient] $obj'),
    );
  }

  // ─── Auth ────────────────────────────────────────────────────────────────────

  /// Đăng nhập, trả về user data + lưu token vào SharedPreferences.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(_loginEndpoint, data: {
      'username': username,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final innerData = (data['data'] ?? data) as Map<String, dynamic>;
    final token = innerData['token'] as String? ?? innerData['access_token'] as String? ?? '';
    final refreshToken = innerData['refresh_token'] as String? ?? '';
    if (token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
      }
    }
    return data;
  }

  /// Thử refresh token. Trả về true nếu thành công.
  Future<bool> _tryRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token') ?? '';
      if (refreshToken.isEmpty) return false;
      final response = await _dio.post(
        _refreshEndpoint,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {}), // no auth header for refresh
      );
      final data = response.data as Map<String, dynamic>;
      final innerData = (data['data'] ?? data) as Map<String, dynamic>;
      final newToken = innerData['token'] as String? ?? innerData['access_token'] as String? ?? '';
      if (newToken.isNotEmpty) {
        await prefs.setString('auth_token', newToken);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('current_user');
  }

  // ─── Tables ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getTables() async {
    final res = await _dio.get(EnvConfig.tableList);
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateTableStatus(
      String tableId, String status) async {
    final res = await _dio.patch('/tables/$tableId', data: {'status': status});
    return res.data as Map<String, dynamic>;
  }

  // ─── Orders ──────────────────────────────────────────────────────────────────

  /// Mở hóa đơn mới khi bật bàn. Trả về toàn bộ response (có data.order.id).
  Future<Map<String, dynamic>> openOrder({
    required String tableId,
    required String shiftId,
    String? memberId,
  }) async {
    final res = await _dio.post(EnvConfig.orderOpen, data: {
      'table_id': tableId,
      'shift_id': shiftId,
      if (memberId != null && memberId.isNotEmpty) 'member_id': memberId,
    });
    return res.data as Map<String, dynamic>;
  }

  /// [Legacy] Tạo order với body tùy ý (dùng cho sync batch).
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async {
    final res = await _dio.post(EnvConfig.orderOpen, data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOrder(
      String orderId, Map<String, dynamic> body) async {
    final res = await _dio.patch('/orders/$orderId', data: body);
    return res.data as Map<String, dynamic>;
  }

  /// Checkout hóa đơn trực tiếp (real-time). Trả về toàn bộ response.
  Future<Map<String, dynamic>> checkoutOrder({
    required String orderId,
    required String paymentMethod,
    double discountAmount = 0.0,
    double taxPercentage = 0.0,
  }) async {
    final res = await _dio.post(EnvConfig.orderCheckout, data: {
      'order_id': orderId,
      'payment_method': paymentMethod,
      'discount_amount': discountAmount,
      'tax_percentage': taxPercentage,
    });
    return res.data as Map<String, dynamic>;
  }

  /// [Legacy] closeOrder dùng body tùy ý.
  Future<Map<String, dynamic>> closeOrder(
      String orderId, Map<String, dynamic> body) async {
    final res = await _dio.post(EnvConfig.orderCheckout, data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> voidOrder(
      String orderId, String reason) async {
    final res = await _dio.post(EnvConfig.orderVoid, data: {
      'order_id': orderId,
      'reason': reason,
      'cancelled_at': DateTime.now().toIso8601String(),
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getOrders({
    String? status,
    String? shiftId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final res = await _dio.get(EnvConfig.orderHistory, queryParameters: {
      if (status != null) 'status': status,
      if (shiftId != null) 'shift_id': shiftId,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    });
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  // ─── Order Details ────────────────────────────────────────────────────────────

  /// Thêm sản phẩm vào order. Trả về detail data (có id là detailId server).
  Future<Map<String, dynamic>> addProductToOrder({
    required String orderId,
    required String productId,
    required int quantity,
  }) async {
    final res = await _dio.post(EnvConfig.orderAddDetail, data: {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Cập nhật số lượng sản phẩm trong order.
  Future<Map<String, dynamic>> updateProductQty({
    required String detailId,
    required int quantity,
  }) async {
    final res = await _dio.post(EnvConfig.orderUpdateDetail, data: {
      'detail_id': detailId,
      'quantity': quantity,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Xóa sản phẩm khỏi order.
  Future<void> deleteProductFromOrder({required String detailId}) async {
    await _dio.post(EnvConfig.orderDeleteDetail, data: {'detail_id': detailId});
  }

  /// [Legacy] addOrderDetail dùng body tùy ý.
  Future<Map<String, dynamic>> addOrderDetail(
      String orderId, Map<String, dynamic> body) async {
    final res = await _dio.post(EnvConfig.orderAddDetail, data: body);
    return res.data as Map<String, dynamic>;
  }

  /// [Legacy] deleteOrderDetail dùng orderId + detailId.
  Future<void> deleteOrderDetail(String orderId, String detailId) async {
    await _dio.post(EnvConfig.orderDeleteDetail, data: {'detail_id': detailId});
  }

  // ─── Products ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getProducts({String? categoryId, bool? isActive}) async {
    final res = await _dio.get(EnvConfig.productList, queryParameters: {
      if (categoryId != null) 'category_id': categoryId,
      if (isActive != null) 'is_active': isActive,
    });
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  Future<List<dynamic>> getProductCategories() async {
    final res = await _dio.get(EnvConfig.productCategories);
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  // ─── Members ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getMemberByPhone(String phone) async {
    try {
      final res = await _dio.get(EnvConfig.memberSearch, queryParameters: {'phone_number': phone});
      final data = res.data as Map<String, dynamic>;
      final innerData = data['data'] ?? data;
      if (innerData is Map<String, dynamic>) {
        return innerData;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> getMembers({int page = 1, int limit = 50}) async {
    final res = await _dio.get(EnvConfig.memberList,
        queryParameters: {'page': page, 'limit': limit});
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  // ─── Shifts ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> openShift(Map<String, dynamic> body) async {
    final res = await _dio.post(EnvConfig.shiftOpen, data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> closeShift(
      String shiftId, Map<String, dynamic> body) async {
    final res = await _dio.post(EnvConfig.shiftClose, data: {
      ...body,
      'shift_id': shiftId,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getActiveShift() async {
    try {
      final res = await _dio.get(EnvConfig.shiftCurrent);
      return res.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── Statistics ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStatistics({
    required String dateFrom,
    required String dateTo,
  }) async {
    final res = await _dio.get('/statistics', queryParameters: {
      'date_from': dateFrom,
      'date_to': dateTo,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTopProducts({
    required String dateFrom,
    required String dateTo,
    int limit = 10,
  }) async {
    final res = await _dio.get('/statistics/top-products', queryParameters: {
      'date_from': dateFrom,
      'date_to': dateTo,
      'limit': limit,
    });
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  // ─── IoT Configurations ──────────────────────────────────────────────────────

  Future<List<dynamic>> getIotConfigs() async {
    final res = await _dio.get(EnvConfig.iotConfigs);
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  Future<List<dynamic>> getTableTypes() async {
    final res = await _dio.get(EnvConfig.tableTypes);
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  Future<List<dynamic>> getTablePrices() async {
    final res = await _dio.get(EnvConfig.tablePrices);
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  Future<List<dynamic>> getMembershipTiers() async {
    final res = await _dio.get(EnvConfig.membershipTiers);
    return (res.data['data'] ?? res.data) as List<dynamic>;
  }

  Future<List<dynamic>> getUsers() async {
    final res = await _dio.get(EnvConfig.userList);
    final data = res.data['data'] ?? res.data;
    if (data is Map<String, dynamic> && data.containsKey('items')) {
      return data['items'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  // ─── Sync ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> syncOrders(Map<String, dynamic> payload) async {
    final res = await _dio.post(EnvConfig.syncDesktop, data: payload);
    return res.data as Map<String, dynamic>;
  }
}

// ignore: avoid_print
void debugPrint(Object? obj) => print(obj);
