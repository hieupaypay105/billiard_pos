import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:anholding_app/src/core/network/token_storage.dart';
import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/core/utils/jwt_utils.dart';
import 'package:dio/dio.dart';

typedef TokensUpdatedCallback =
    Future<void> Function({
      String? accessToken,
      String? refreshToken,
    });

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    Dio? refreshDio,
    this.refreshTokenEndpoint = ApiPaths.authRefreshToken,
    this.onLogout,
    this.onTokensUpdated,
  }) : _tokenStorage = tokenStorage,
       _refreshDio = refreshDio ?? Dio();

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final String refreshTokenEndpoint;
  final VoidCallback? onLogout;
  final TokensUpdatedCallback? onTokensUpdated;

  bool _isRefreshing = false;
  final List<({Completer<void> completer, RequestOptions options})>
  _pendingRequests = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      // Check if token is expired or about to expire
      if (JwtUtils.isExpired(accessToken)) {
        final refreshed = await _refreshToken(options);
        if (refreshed) {
          final newToken = await _tokenStorage.getAccessToken();
          options.headers['Authorization'] = 'Bearer $newToken';
        } else {
          await _handleLogout();
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Token expired and refresh failed',
            ),
          );
        }
      } else {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      await _extractAndSaveTokens(data);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final success = await _refreshToken(err.requestOptions);
      if (success) {
        try {
          final retryResponse = await _retry(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          // Retry failed
        }
      }
      await _handleLogout();
    }
    handler.next(err);
  }

  // ── Token Extraction ─────────────────────────────────────

  Future<void> _extractAndSaveTokens(Map<String, dynamic> data) async {
    final accessToken =
        data['access_token'] as String? ?? data['accessToken'] as String?;
    final refreshToken =
        data['refresh_token'] as String? ?? data['refreshToken'] as String?;

    if (accessToken != null) {
      await _tokenStorage.saveAccessToken(accessToken);
    }
    if (refreshToken != null) {
      await _tokenStorage.saveRefreshToken(refreshToken);
    }

    if (accessToken != null || refreshToken != null) {
      await onTokensUpdated?.call(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  // ── Refresh Token ────────────────────────────────────────

  Future<bool> _refreshToken(RequestOptions options) async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _pendingRequests.add((completer: completer, options: options));
      await completer.future;
      return true;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final formData = FormData.fromMap({'refresh_token': refreshToken});
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '${options.baseUrl}$refreshTokenEndpoint',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        await _extractAndSaveTokens(response.data!);

        for (final pending in _pendingRequests) {
          pending.completer.complete();
        }
        _pendingRequests.clear();

        return true;
      }
      return false;
    } catch (e) {
      for (final pending in _pendingRequests) {
        pending.completer.completeError(e);
      }
      _pendingRequests.clear();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final accessToken = await _tokenStorage.getAccessToken();
    options.headers['Authorization'] = 'Bearer $accessToken';
    return _refreshDio.fetch(options);
  }

  Future<void> _handleLogout() async {
    await _tokenStorage.clearTokens();
    onLogout?.call();
  }
}
