import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billiard_desktop/features/auth/auth_provider.dart';
import 'package:billiard_desktop/core/services/api_client.dart';
import 'package:billiard_desktop/core/providers/providers.dart';

class FakeApiClient extends ApiClient {
  Map<String, dynamic>? mockLoginResponse;
  bool shouldThrowLoginError = false;
  String? loginErrorMsg;
  bool logoutCalled = false;

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    if (shouldThrowLoginError) {
      throw Exception(loginErrorMsg ?? 'Login failed');
    }
    return mockLoginResponse ?? {
      'user': {
        'id': 'u-1',
        'username': username,
        'display_name': 'Test User',
        'role': 'admin',
        'is_active': true,
      },
      'token': 'mock-jwt-token',
      'refresh_token': 'mock-refresh-token',
    };
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    await super.logout();
  }
}

void main() {
  // Ensure Flutter binding is initialized because we use SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier Tests', () {
    late FakeApiClient fakeApiClient;
    late ProviderContainer container;

    setUp(() {
      fakeApiClient = FakeApiClient();
      // Setup mock values for SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is not authenticated, not loading, and has no error', () async {
      // Trigger provider initialization
      container.read(authProvider.notifier);
      // Allow _tryRestoreSession() to complete SharedPreferences initialization
      await Future.delayed(const Duration(milliseconds: 50));
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.user, isNull);
    });

    test('login success updates state and persists user data', () async {
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.login(username: 'admin', password: 'password');
      expect(success, isTrue);

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.user?.username, 'admin');
      expect(state.user?.displayName, 'Test User');
      expect(state.user?.role, 'admin');

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_user'), isNotNull);
      final storedUserMap = jsonDecode(prefs.getString('current_user')!) as Map<String, dynamic>;
      expect(storedUserMap['username'], 'admin');
    });

    test('login failure sets error message', () async {
      fakeApiClient.shouldThrowLoginError = true;
      fakeApiClient.loginErrorMsg = 'Exception: Sai tên đăng nhập hoặc mật khẩu.';

      final notifier = container.read(authProvider.notifier);
      final success = await notifier.login(username: 'admin', password: 'wrong_password');
      expect(success, isFalse);

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('Sai tên đăng nhập hoặc mật khẩu.'));
      expect(state.user, isNull);
    });

    test('logout clears credentials and state', () async {
      final notifier = container.read(authProvider.notifier);

      // Perform a mock login first
      await notifier.login(username: 'admin', password: 'password');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      // Verify that shared preferences have been populated
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_user'), isNotNull);

      // Now logout
      await notifier.logout();
      expect(fakeApiClient.logoutCalled, isTrue);

      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);

      // Shared preferences should be cleared
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_user'), isNull);
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
    });
  });
}
