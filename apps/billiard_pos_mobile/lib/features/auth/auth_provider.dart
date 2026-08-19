import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/services/api_client.dart';
import '../../core/providers/providers.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    // Khi refresh token thất bại (401), tự động logout về màn hình đăng nhập
    _apiClient.onUnauthorized = () {
      logout();
    };
    _tryRestoreSession();
  }

  /// Khôi phục phiên đăng nhập cũ khi khởi chạy ứng dụng.
  Future<void> _tryRestoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('current_user');
      
      if (token != null && token.isNotEmpty && userJson != null && userJson.isNotEmpty) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = _userFromMap(userMap);
        if (mounted) {
          state = AuthState(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
        }
        return;
      }
      
      if (mounted) {
        state = const AuthState(isLoading: false, isAuthenticated: false);
      }
    } catch (_) {
      if (mounted) {
        state = const AuthState(isLoading: false, isAuthenticated: false);
      }
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    // Set isAuthenticated = false để router KHÔNG redirect sang /tables
    // trong khi đang chờ API response (tránh flash màn hình)
    state = AuthState(isLoading: true, isAuthenticated: false);
    try {
      final data = await _apiClient.login(
        username: username,
        password: password,
      );

      // Normalize user from API response
      final userMap = (data['user'] ?? data['data'] ?? data) as Map<String, dynamic>;
      final user = _userFromMap(userMap);

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(userMap));

      state = AuthState(user: user, isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      String errorMsg;
      final raw = e.toString();
      if (raw.contains('SocketException') ||
          raw.contains('network') ||
          raw.contains('Connection refused') ||
          raw.contains('Failed host lookup')) {
        errorMsg = 'Không có kết nối mạng. Vui lòng thử lại.';
      } else {
        // Lấy message từ Exception('...') do ApiClient ném ra từ response body
        final match = RegExp(r'^Exception:\s*(.+)$').firstMatch(raw);
        errorMsg = match?.group(1) ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
      }
      // isAuthenticated giữ false, giữ user ở lại màn hình login
      state = AuthState(isLoading: false, isAuthenticated: false, error: errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.logout();
    state = const AuthState();
  }

  UserModel _userFromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      passwordHash: '',
      displayName: map['display_name']?.toString() ??
          map['name']?.toString() ??
          map['username']?.toString() ??
          '',
      role: map['role']?.toString() ?? 'cashier',
      phoneNumber: map['phone_number']?.toString(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
