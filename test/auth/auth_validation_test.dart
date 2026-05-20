import 'package:anholding_app/src/core/services/firebase_auth_service.dart';
import 'package:anholding_app/src/core/storage/pin_storage.dart';
import 'package:anholding_app/src/core/storage/user_storage.dart';
import 'package:anholding_app/src/features/auth/data/models/auth_response_model.dart';
import 'package:anholding_app/src/features/auth/data/models/user_model.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_view_model.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/otp_verification_view.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/phone_login_view.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/setup_pin_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ─── Mock PinStorage ──────────────────────────────────────────────────────────

class MockPinStorage extends PinStorage {
  bool _pinSaved = false;

  @override
  Future<bool> hasPin() async => _pinSaved;

  @override
  Future<void> savePin(String pin) async => _pinSaved = true;

  @override
  Future<bool> verifyPin(String pin) async => true;

  @override
  Future<void> saveUserInfo({required String phone, String? name}) async {}

  @override
  Future<String?> getSavedPhone() async => null;

  @override
  Future<String?> getSavedName() async => null;
}

// ─── Mock UserStorage ─────────────────────────────────────────────────────────

class MockUserStorage extends UserStorage {
  UserModel? _storedUser;

  @override
  Future<void> saveUser(UserModel user) async {
    _storedUser = user;
  }

  @override
  Future<UserModel?> getUser() async {
    return _storedUser;
  }

  @override
  Future<void> deleteUser() async {
    _storedUser = null;
  }
}

// ─── Mock FirebaseAuthService ─────────────────────────────────────────────────

class MockFirebaseAuthService extends FirebaseAuthService {
  MockFirebaseAuthService({
    this.shouldError = false,
    this.shouldTimeout = false,
    this.errorMessage = 'mock-error',
    this.verificationId = 'mock-verification-id',
  }) : super(auth: null);

  final bool shouldError;
  final bool shouldTimeout;
  final String errorMessage;
  final String verificationId;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
    void Function(String verificationId)? onTimeout,
  }) async {
    if (shouldError) {
      onError(errorMessage);
      return;
    }

    if (shouldTimeout) {
      onTimeout?.call('mock-timeout-id');
      return;
    }

    // Simulate successful OTP send
    onCodeSent(verificationId);
  }
}

// ─── Mock AuthRepository ──────────────────────────────────────────────────────

class MockAuthRepository implements AuthRepository {
  @override
  Future<AuthResponseModel> login(String username, String password) async {
    return const AuthResponseModel(
      accessToken: 'mock-access',
      refreshToken: 'mock-refresh',
    );
  }

  @override
  Future<UserModel> loginFirebase(String idToken) async {
    return const UserModel(
      id: '1',
      username: 'test',
      email: 'test@test.com',
      fullname: 'Test User',
      status: '1',
      userCode: 'test',
      mobile: '0999999999',
      dob: '1990-01-01',
      parentId: '0',
      accessToken: 'mock-access',
      refreshToken: 'mock-refresh',
      expires: '2026-12-31',
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
      groupPerName: 'User',
      firebaseUid: 'mock-uid',
      avatar: '',
    );
  }

  @override
  Future<AuthResponseModel> refreshToken() async {
    return const AuthResponseModel(
      accessToken: 'mock-access',
      refreshToken: 'mock-refresh',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel> getUserInfo() async {
    return loginFirebase('');
  }
}

// ─── Test Helpers ─────────────────────────────────────────────────────────────

Widget buildTestApp({required Widget home, required AuthViewModel vm}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/otp-verification',
        builder: (_, _) => const Scaffold(body: Text('OTP Screen')),
      ),
      GoRoute(
        path: '/setup-pin',
        builder: (_, _) => const Scaffold(body: Text('Setup PIN')),
      ),
      GoRoute(
        path: '/confirm-pin',
        builder: (_, _) => const Scaffold(body: Text('Confirm PIN')),
      ),
      GoRoute(
        path: '/phone-login',
        builder: (_, _) => const Scaffold(body: Text('Phone Login')),
      ),
    ],
  );

  return ChangeNotifierProvider<AuthViewModel>.value(
    value: vm,
    child: MaterialApp.router(routerConfig: router),
  );
}

AuthViewModel buildVmWithAuthService(FirebaseAuthService firebaseAuthService) {
  final mockRepo = MockAuthRepository();
  return AuthViewModel(
    pinStorage: MockPinStorage(),
    firebaseAuthService: firebaseAuthService,
    authRepository: mockRepo,
    userProvider: UserProvider(
      userStorage: MockUserStorage(),
      authRepository: mockRepo,
    ),
  );
}

/// Finds the Continue button by its label text.
Finder get _continueBtn => find.text('Tiếp tục');

// ─── Unit Tests: AuthViewModel ────────────────────────────────────────────────

void main() {
  late AuthViewModel vm;

  setUp(() {
    final mockRepo = MockAuthRepository();
    vm = AuthViewModel(
      pinStorage: MockPinStorage(),
      firebaseAuthService: MockFirebaseAuthService(),
      authRepository: mockRepo,
      userProvider: UserProvider(
        userStorage: MockUserStorage(),
        authRepository: mockRepo,
      ),
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // AuthViewModel — Pure unit tests (no UI, fast)
  // ════════════════════════════════════════════════════════════════════════════

  group('AuthViewModel.validatePin', () {
    test('returns false when pin length < 6', () {
      vm.pin = '12345';
      expect(vm.validatePin(), isFalse);
      expect(vm.errorMessage, isNotNull);
    });

    test('returns false when pin is empty', () {
      vm.pin = '';
      expect(vm.validatePin(), isFalse);
    });

    test('returns true when pin is exactly 6 digits', () {
      vm.pin = '123456';
      expect(vm.validatePin(), isTrue);
      expect(vm.errorMessage, isNull);
    });

    test('returns false when pin length > 6', () {
      vm.pin = '1234567';
      expect(vm.validatePin(), isFalse);
    });
  });

  group('AuthViewModel.submitPhone', () {
    test('returns true and sets verificationId when codeSent', () async {
      final localVm = buildVmWithAuthService(
        MockFirebaseAuthService(verificationId: 'verification-123'),
      );
      localVm.phoneNumber = '0901234567';

      final result = await localVm.submitPhone();

      expect(result, isTrue);
      expect(localVm.debugVerificationId, equals('verification-123'));
      expect(localVm.errorMessage, isNull);
    });

    test('returns false and sets error when sendOtp fails', () async {
      final localVm = buildVmWithAuthService(
        MockFirebaseAuthService(
          shouldError: true,
          errorMessage: 'Lỗi gửi OTP',
        ),
      );
      localVm.phoneNumber = '0901234567';

      final result = await localVm.submitPhone();

      expect(result, isFalse);
      expect(localVm.errorMessage, contains('Lỗi gửi OTP'));
      expect(localVm.debugVerificationId, isNull);
    });

    test('returns false and sets error on timeout', () async {
      final localVm = buildVmWithAuthService(
        MockFirebaseAuthService(shouldTimeout: true),
      );
      localVm.phoneNumber = '0901234567';

      final result = await localVm.submitPhone();

      expect(result, isFalse);
      expect(localVm.errorMessage, contains('Hết thời gian chờ'));
      expect(localVm.debugVerificationId, isNull);
    });
  });

  group('AuthViewModel.confirmAndSetPin', () {
    test('returns false when confirmPin < 6 chars', () async {
      vm
        ..pin = '123456'
        ..confirmPin = '123';
      expect(await vm.confirmAndSetPin(), isFalse);
    });

    test('returns false and sets error when pins do not match', () async {
      vm
        ..pin = '123456'
        ..confirmPin = '654321';
      expect(await vm.confirmAndSetPin(), isFalse);
      expect(vm.errorMessage, contains('không khớp'));
    });

    test('returns true when pins match', () async {
      vm
        ..pin = '123456'
        ..confirmPin = '123456';
      expect(await vm.confirmAndSetPin(), isTrue);
      expect(vm.errorMessage, isNull);
    });
  });

  group('AuthViewModel.loginWithPin', () {
    test('returns false and sets error when pinCode < 6 chars', () async {
      expect(await vm.loginWithPin('123'), isFalse);
      expect(vm.errorMessage, isNotNull);
    });

    test('returns true when pin is valid (mock always returns true)', () async {
      expect(await vm.loginWithPin('123456'), isTrue);
    });
  });

  group('AuthViewModel.reset', () {
    test('clears all state', () {
      vm
        ..phoneNumber = '0901234567'
        ..otp = '123456'
        ..pin = '654321'
        ..confirmPin = '654321';
      vm.reset();
      expect(vm.phoneNumber, isEmpty);
      expect(vm.otp, isEmpty);
      expect(vm.pin, isEmpty);
      expect(vm.confirmPin, isEmpty);
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // PhoneLoginView — Widget tests
  // ════════════════════════════════════════════════════════════════════════════

  group('PhoneLoginView — validation', () {
    Future<void> pump(WidgetTester tester) =>
        tester.pumpWidget(buildTestApp(home: const PhoneLoginView(), vm: vm));

    testWidgets('shows required error when field is empty', (tester) async {
      await pump(tester);
      await tester.tap(_continueBtn);
      await tester.pump();
      expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
    });

    testWidgets('shows minLength error for 9 digits', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(EditableText).first, '090413261');
      await tester.tap(_continueBtn);
      await tester.pump();
      expect(find.text('Số điện thoại cần có ít nhất 10 số'), findsOneWidget);
    });

    testWidgets('shows maxLength error for 12 digits', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(EditableText).first, '090413261199');
      await tester.tap(_continueBtn);
      await tester.pump();
      expect(find.text('Số điện thoại có tối đa 11 số'), findsOneWidget);
    });

    testWidgets('no error for valid 10-digit phone', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(EditableText).first, '0904132611');
      await tester.pump();
      await tester.tap(_continueBtn);
      // Pump once to trigger validation
      await tester.pump();
      expect(find.text('Vui lòng nhập số điện thoại'), findsNothing);
      expect(find.text('Số điện thoại cần có ít nhất 10 số'), findsNothing);
      expect(find.text('Số điện thoại có tối đa 11 số'), findsNothing);
      // Drain the 1-second timer from submitPhone()
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('no error for valid 11-digit phone', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(EditableText).first, '09041326119');
      await tester.pump();
      await tester.tap(_continueBtn);
      // Pump once to trigger validation
      await tester.pump();
      expect(find.text('Số điện thoại có tối đa 11 số'), findsNothing);
      // Drain the 1-second timer from submitPhone()
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('FilteringInputFormatter blocks non-digit characters', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(EditableText).first, 'abc!0904132611');
      await tester.pump();
      // OTP/Phone widget uses FilteringTextInputFormatter.digitsOnly
      // so only the digit part should remain
      final editableWidget = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(RegExp(r'^\d*$').hasMatch(editableWidget.controller.text), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // OtpVerificationView — Widget tests
  // ════════════════════════════════════════════════════════════════════════════

  group('OtpVerificationView — validation', () {
    Future<void> pump(WidgetTester tester) {
      vm.phoneNumber = '0904132611';
      return tester.pumpWidget(
        buildTestApp(home: const OtpVerificationView(), vm: vm),
      );
    }

    testWidgets('shows required error when OTP is empty', (tester) async {
      await pump(tester);
      await tester.tap(_continueBtn);
      await tester.pump();
      expect(find.text('Vui lòng nhập mã OTP'), findsOneWidget);
    });

    testWidgets('shows minLength error for OTP shorter than 6', (tester) async {
      await pump(tester);
      // The hidden TextField inside OtpPinInputWidget handles input.
      // We enter text via the hidden EditableText (first OTP widget).
      final hiddenFields = find.byType(EditableText);
      // OTP screen has 1 OtpPinInputWidget → first EditableText is the hidden input
      await tester.enterText(hiddenFields.first, '12345');
      await tester.pump();
      await tester.tap(_continueBtn);
      await tester.pump();
      expect(find.text('Vui lòng nhập đủ 6 số OTP'), findsOneWidget);
    });

    testWidgets('no error when OTP is exactly 6 digits', (tester) async {
      await pump(tester);
      final hiddenFields = find.byType(EditableText);
      await tester.enterText(hiddenFields.first, '123456');
      await tester.pump();
      await tester.tap(_continueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mã OTP'), findsNothing);
      expect(find.text('Vui lòng nhập đủ 6 số OTP'), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // SetupPinView — Widget tests
  // ════════════════════════════════════════════════════════════════════════════

  group('SetupPinView — validation', () {
    Future<void> pump(WidgetTester tester) =>
        tester.pumpWidget(buildTestApp(home: const SetupPinView(), vm: vm));

    testWidgets('shows required error when PIN is empty', (tester) async {
      await pump(tester);
      await tester.tap(_continueBtn);
      await tester.pump();
      expect(find.text('Vui lòng nhập mã PIN'), findsOneWidget);
    });

    testWidgets('shows minLength error for PIN shorter than 6', (tester) async {
      await pump(tester);
      final hiddenFields = find.byType(EditableText);
      await tester.enterText(hiddenFields.first, '1234');
      await tester.pump();
      await tester.tap(_continueBtn);
      await tester.pump();
      expect(find.text('Vui lòng nhập đủ 6 số mã PIN'), findsOneWidget);
    });

    testWidgets('no error for valid 6-digit PIN', (tester) async {
      await pump(tester);
      final hiddenFields = find.byType(EditableText);
      await tester.enterText(hiddenFields.first, '123456');
      await tester.pump();
      await tester.tap(_continueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mã PIN'), findsNothing);
      expect(find.text('Vui lòng nhập đủ 6 số mã PIN'), findsNothing);
    });

    testWidgets('Quay lại button pops route', (tester) async {
      final router = GoRouter(
        initialLocation: '/prev',
        routes: [
          GoRoute(
            path: '/prev',
            builder: (_, _) => const Scaffold(body: Text('Previous')),
          ),
          GoRoute(
            path: '/setup-pin',
            builder: (_, _) => ChangeNotifierProvider<AuthViewModel>.value(
              value: vm,
              child: const SetupPinView(),
            ),
          ),
          GoRoute(
            path: '/confirm-pin',
            builder: (_, _) => const Scaffold(body: Text('Confirm PIN')),
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: vm,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/setup-pin');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Previous'), findsOneWidget);
    });
  });
}
