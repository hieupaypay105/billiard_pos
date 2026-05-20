import 'package:anholding_app/src/core/storage/user_storage.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/auth/data/models/user_model.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

/// Global user state — holds the currently logged-in user data.
class UserProvider extends ChangeNotifier {
  UserProvider({required this.userStorage, required this.authRepository});
  final UserStorage userStorage;
  final AuthRepository authRepository;

  UserModel? _currentUser;
  bool _isFetchingUser = false;
  String? _fetchError;

  UserModel? get currentUser => _currentUser;
  bool get isFetchingUser => _isFetchingUser;
  String? get fetchError => _fetchError;

  bool get isLoggedIn => _currentUser != null;

  /// Load global user state from secure storage
  Future<void> loadUser() async {
    _currentUser = await userStorage.getUser();
    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _currentUser = user;
    notifyListeners();
    await userStorage.saveUser(user);
  }

  /// Fetch fresh user info from GET /user/info API.
  Future<void> fetchUserInfo() async {
    _isFetchingUser = true;
    _fetchError = null;
    notifyListeners();

    var shouldKeepSkeleton = false;

    try {
      final user = await authRepository.getUserInfo();
      // Preserve tokens from current user (API doesn't return them)
      if (_currentUser != null) {
        _currentUser = user.copyWith(
          accessToken: _currentUser!.accessToken,
          refreshToken: _currentUser!.refreshToken,
        );
      } else {
        _currentUser = user;
      }
      await userStorage.saveUser(_currentUser!);
    } on Exception catch (e) {
      logger.w('fetchUserInfo failed: $e');
      _fetchError = e.toString().replaceFirst('Exception: ', '');
      if (_fetchError == 'Token expired and refresh failed') {
        shouldKeepSkeleton = true;
      }
    } finally {
      if (!shouldKeepSkeleton) {
        _isFetchingUser = false;
        notifyListeners();
      }
    }
  }

  /// Update only the tokens on the current user (e.g. after a token refresh).
  Future<void> updateTokens({
    String? accessToken,
    String? refreshToken,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    notifyListeners();
    await userStorage.saveUser(_currentUser!);
  }

  Future<void> clearUser() async {
    _currentUser = null;
    notifyListeners();
    await userStorage.deleteUser();
  }
}
