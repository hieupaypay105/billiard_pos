import 'dart:async';

import 'package:anholding_app/injection_container.dart' as di;
import 'package:anholding_app/src/core/services/firebase_auth_service.dart';
import 'package:anholding_app/src/core/services/firebase_messaging_service.dart';
import 'package:anholding_app/src/core/storage/pin_storage.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AuthFlowMode { initialSetup, forgotPin }
enum ForgotPinStartResult { started, missingPhone, failed }

/// Manages UI state for the multi-step auth flow:
///   Phone → OTP → Setup PIN → Confirm PIN (and PIN Login).
///
/// Uses [PinStorage] to securely persist the PIN on device.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this.pinStorage,
    required this.firebaseAuthService,
    required this.authRepository,
    required this.userProvider,
  });

  final PinStorage pinStorage;
  final FirebaseAuthService firebaseAuthService;
  final AuthRepository authRepository;
  final UserProvider userProvider;

  AuthFlowMode _flowMode = AuthFlowMode.initialSetup;
  AuthFlowMode get flowMode => _flowMode;
  bool get isForgotPinFlow => _flowMode == AuthFlowMode.forgotPin;

  /// Verification ID returned by Firebase after OTP is sent.
  String? _verificationId;
  @visibleForTesting
  String? get debugVerificationId => _verificationId;

  // ─── Phone ───────────────────────────────────────────────
  String _phoneNumber = '';
  String get phoneNumber => _phoneNumber;
  set phoneNumber(String value) {
    _phoneNumber = value;
    notifyListeners();
  }

  // ─── OTP ─────────────────────────────────────────────────
  String _otp = '';
  String get otp => _otp;
  set otp(String value) {
    _otp = value;
    notifyListeners();
  }

  // ─── PIN ─────────────────────────────────────────────────
  String _pin = '';
  String get pin => _pin;
  set pin(String value) {
    _pin = value;
    notifyListeners();
  }

  String _confirmPin = '';
  String get confirmPin => _confirmPin;
  set confirmPin(String value) {
    _confirmPin = value;
    notifyListeners();
  }

  // ─── Loading / Error ─────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ─── Returning user info ─────────────────────────────────
  String? _savedName;
  String? get savedName => _savedName;

  String? _savedPhone;
  String? get savedPhone => _savedPhone;

  /// Load returning-user info from secure storage.
  Future<void> loadSavedUser() async {
    _savedName = await pinStorage.getSavedName();
    _savedPhone = await pinStorage.getSavedPhone();
    notifyListeners();
  }

  /// Check if user has a PIN set (for routing to PinLoginView).
  Future<bool> hasSavedPin() => pinStorage.hasPin();

  // ─── Flow Actions ────────────────────────────────────────

  Future<ForgotPinStartResult> startForgotPin() async {
    final currentPhone = userProvider.currentUser?.mobile;
    final storedPhone = await pinStorage.getSavedPhone();
    var phone = (currentPhone ?? storedPhone ?? '').trim();
    phone = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }

    if (phone.isEmpty) {
      _errorMessage = 'Không tìm thấy số điện thoại để xác thực.';
      notifyListeners();
      return ForgotPinStartResult.missingPhone;
    }

    _flowMode = AuthFlowMode.forgotPin;
    _resetFlowState(clearPhone: false);
    _phoneNumber = phone;
    notifyListeners();

    final sent = await submitPhone();
    return sent ? ForgotPinStartResult.started : ForgotPinStartResult.failed;
  }

  void cancelForgotPin() {
    _flowMode = AuthFlowMode.initialSetup;
    _resetFlowState(clearPhone: true);
    notifyListeners();
  }

  /// Validate phone number format and request an OTP via Firebase.
  Future<bool> submitPhone() async {
    final normalized = _phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (normalized.isEmpty) {
      _errorMessage = 'Vui lòng nhập số điện thoại';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(normalized)) {
      _errorMessage = 'Số điện thoại không hợp lệ';
      notifyListeners();
      return false;
    }

    if (normalized.length < 10) {
      _errorMessage = 'Số điện thoại cần có ít nhất 10 số';
      notifyListeners();
      return false;
    }

    if (normalized.length > 11) {
      _errorMessage = 'Số điện thoại có tối đa 11 số';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<bool>();

    try {
      final formattedPhone = _formatPhone(normalized);
      await firebaseAuthService.sendOtp(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (error) {
          _errorMessage = error;
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        },
        onAutoVerified: (credential) {
          // Android auto-verification — can be handled later
        },
        onTimeout: (_) {
          _errorMessage = 'Hết thời gian chờ. Vui lòng thử lại.';
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      // Safety timeout: if no callback fires within 60s, fail gracefully.
      return completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _errorMessage = 'Hết thời gian chờ. Vui lòng thử lại.';
          _isLoading = false;
          notifyListeners();
          return false;
        },
      );
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
  }

  /// Verify the 6-digit OTP code via Firebase, then login with backend.
  Future<bool> verifyOtp() async {
    if (_otp.isEmpty) {
      _errorMessage = 'Vui lòng nhập mã OTP';
      notifyListeners();
      return false;
    }

    if (_otp.length < 6) {
      _errorMessage = 'Vui lòng nhập đủ 6 số OTP';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(_otp)) {
      _errorMessage = 'Mã OTP không hợp lệ';
      notifyListeners();
      return false;
    }

    if (_verificationId == null) {
      _errorMessage = 'Chưa gửi OTP. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await firebaseAuthService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: _otp,
      );
      final user = result.user;

      if (user == null) {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final idToken = await user.getIdToken();
      logger.d('idToken: $idToken');

      if (idToken == null) {
        _errorMessage = 'Không lấy được token. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      try {
        final loginUser = await authRepository.loginFirebase(idToken);
        await userProvider.setUser(loginUser);
        logger.d('Login Firebase thành công: ${loginUser.fullname}');

        await di.sl<FirebaseMessagingService>().activateForAuthenticatedUser();
      } on Exception catch (e) {
        logger.e('Backend login after OTP failed: $e');
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase OTP failed: ${e.code} — ${e.message}');
      _errorMessage = _mapFirebaseOtpError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } on Exception catch (e) {
      logger.e('OTP verification failed: $e');
      _errorMessage = 'Xác thực OTP thất bại. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Validate the initial PIN (must be 6 digits).
  bool validatePin() {
    if (_pin.length != 6) {
      _errorMessage = 'Vui lòng nhập đủ 6 số PIN';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Validate confirm PIN matches original, hash & persist to secure storage.
  Future<bool> confirmAndSetPin() async {
    if (_confirmPin.length != 6) {
      _errorMessage = 'Vui lòng nhập đủ 6 số PIN';
      notifyListeners();
      return false;
    }
    if (_confirmPin != _pin) {
      _errorMessage = 'Mã PIN không khớp';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Save PIN hash + user info to secure storage
      await pinStorage.savePin(_pin);
      await pinStorage.saveUserInfo(phone: _phoneNumber);

      _flowMode = AuthFlowMode.initialSetup;
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with PIN for returning users — verifies against stored hash.
  Future<bool> loginWithPin(String pinCode) async {
    if (pinCode.isEmpty) {
      _errorMessage = 'Vui lòng nhập mã PIN';
      notifyListeners();
      return false;
    }

    if (pinCode.length < 6) {
      _errorMessage = 'Vui lòng nhập đủ 6 số mã PIN';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pinCode)) {
      _errorMessage = 'Mã PIN không hợp lệ';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await pinStorage.verifyPin(pinCode);

      if (!isValid) {
        _errorMessage = 'Mã PIN không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Token refresh is handled automatically by AuthInterceptor (Dio layer).

      await di.sl<FirebaseMessagingService>().activateForAuthenticatedUser();

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset all fields (e.g. when switching accounts).
  void reset() {
    _flowMode = AuthFlowMode.initialSetup;
    _phoneNumber = '';
    _otp = '';
    _pin = '';
    _confirmPin = '';
    _verificationId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear only the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _resetFlowState({required bool clearPhone}) {
    if (clearPhone) {
      _phoneNumber = '';
    }
    _otp = '';
    _pin = '';
    _confirmPin = '';
    _verificationId = null;
    _isLoading = false;
    _errorMessage = null;
  }

  /// Convert local format "0999999999" / "84999999999" → E.164 (+84…).
  ///
  /// Phải khớp số test trong Firebase Console (ví dụ +84123123123).
  String _formatPhone(String phone) {
    final trimmed = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (trimmed.startsWith('+')) return trimmed;
    // Đã nhập 84xxxxxxxxx — tránh lỗi thành +8484...
    if (RegExp(r'^84\d{9}$').hasMatch(trimmed)) {
      return '+$trimmed';
    }
    if (trimmed.startsWith('0')) return '+84${trimmed.substring(1)}';
    return '+84$trimmed';
  }

  String _mapFirebaseOtpError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Mã OTP không chính xác';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'Mã OTP đã hết hạn. Vui lòng gửi lại mã.';
      default:
        return e.message ?? 'Xác thực OTP thất bại';
    }
  }
}
