import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.repository});
  final AuthRepository repository;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.login(username, password);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      logger.e('login error', error: e);
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } finally {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> refreshToken() async {
    try {
      await repository.refreshToken();
      _isAuthenticated = true;
      return true;
    } catch (e) {
      logger.e('refreshToken error', error: e);
      _isAuthenticated = false;
      return false;
    }
  }
}
