import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

/// Wrapper quanh [FirebaseAuth] cho đăng nhập bằng số điện thoại.
///
/// **Luồng khớp native + Console:**
/// - **iOS:** xác minh thiết bị qua APNs (silent push). `forceRecaptchaFlow`
///   không áp dụng cho iOS trong FlutterFire, nên cần key APNs (.p8) và native
///   forwarding đúng ở AppDelegate.
/// - **Android:** Play Integrity / SMS.
/// - **Số test (Console):** bật `--dart-define=FIREBASE_AUTH_TEST_PHONES=true` (debug) để
///   `appVerificationDisabledForTesting` — không bật khi dùng **số thật** + APNs, dễ lỗi
///   `notification-not-forwarded`.
class FirebaseAuthService {
  /// Creates a [FirebaseAuthService].
  ///
  /// Pass [auth] để override [FirebaseAuth.instance] (test).
  FirebaseAuthService({FirebaseAuth? auth}) : _authOverride = auth;

  static const bool _firebaseAuthTestPhones = bool.fromEnvironment(
    'FIREBASE_AUTH_TEST_PHONES',
  );

  /// The [FirebaseAuth] instance. Lazily defaults to [FirebaseAuth.instance].
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  final FirebaseAuth? _authOverride;

  /// Token từ callback `codeSent` — dùng khi gửi lại OTP.
  int? _forceResendingToken;

  /// Gọi trước mỗi lần gọi `verifyPhoneNumber` (Firebase khuyến nghị, settings không giữ mãi).
  Future<void> _applyPhoneAuthSettings() async {
    try {
      const useTestPhones = _firebaseAuthTestPhones && !kReleaseMode;
      if (useTestPhones) {
        await _auth.setSettings(
          appVerificationDisabledForTesting: true,
          forceRecaptchaFlow: false,
        );
      } else {
        // iOS thật dùng silent push APNs; forceRecaptchaFlow chỉ áp dụng cho Android.
        await _auth.setSettings();
      }
      logger.d(
        'Firebase Auth: testPhones=$useTestPhones '
        'appVerificationDisabled=$useTestPhones',
      );
    } on Exception catch (e) {
      logger.w('Firebase Auth setSettings: $e');
    }
  }

  /// Áp dụng cùng cấu hình như trước `sendOtp` — có thể gọi sớm từ `main`.
  Future<void> enableTestMode() => _applyPhoneAuthSettings();

  /// Gửi OTP tới [phoneNumber].
  ///
  /// [onCodeSent] trả `verificationId` để [verifyOtp]. [onError] khi thất bại.
  /// [onAutoVerified] chủ yếu trên Android (auto-retrieval).
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
    void Function(String verificationId)? onTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        try {
          // iOS thường không auto-complete như Android, nhưng vẫn nên để sẵn
          await _auth.signInWithCredential(credential);
          onAutoVerified?.call(credential);
        } on Exception catch (e) {
          logger.e('verificationCompleted failed', error: e);
        }
      },
      verificationFailed: (e) {
        final message = _mapFirebaseError(e);
        logger.e('verificationFailed: ${e.code} - ${e.message}');
        onError(message);
      },
      codeSent: (verificationId, resendToken) {
        _forceResendingToken = resendToken;
        logger.d('codeSent: $verificationId');
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        logger.d('timeout: $verificationId');
        onTimeout?.call(verificationId);
      },
    );
  }

  /// Xác nhận OTP [smsCode] với [verificationId] từ [sendOtp].
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'quota-exceeded':
        return 'Đã vượt giới hạn gửi SMS. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      case 'app-not-authorized':
        return 'Ứng dụng chưa được cấu hình xác thực. Liên hệ hỗ trợ.';
      case 'captcha-check-failed':
        return 'Xác thực thất bại. Vui lòng thử lại.';
      case 'missing-client-identifier':
      case 'missing-app-credential':
        return 'Ứng dụng chưa được nhận diện đúng. Kiểm tra cấu hình Firebase '
            '(SHA Android / bundle iOS) và thử lại.';
      case 'notification-not-forwarded':
        return 'Thiết bị không nhận/xử lý được thông báo xác minh (APNs). '
            'Kiểm tra: key .p8 + Bundle ID trên Firebase; Xcode → Push Notifications; '
            'entitlements aps-environment khớp bản build; không bật số test Dart '
            'khi dùng số thật. Thử cài lại app sau khi đổi cấu hình.';
      default:
        return e.message ?? 'Xác thực số điện thoại thất bại';
    }
  }
}
