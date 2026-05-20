import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:anholding_app/src/features/dashboard/domain/entities/dashboard_user_stats.dart';
import 'package:anholding_app/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({required this.repository});
  final DashboardRepository repository;

  DashboardStats? _stats;
  DashboardUserStats _userStats = DashboardUserStats.empty;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardStats? get stats => _stats;
  DashboardUserStats get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Convenience getters
  String get role => _userStats.role;
  int get totalCustomer => _userStats.totalCustomer;
  DashboardByStatus get byStatus => _userStats.byStatus;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await repository.getStats();
    } catch (e) {
      logger.e('loadStats failed', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userStats = await repository.getDashboardUserStats();
    } catch (e) {
      logger.e('loadUserStats failed', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load cả stats và user stats cùng lúc.
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        repository.getStats().then((v) => _stats = v),
        repository.getDashboardUserStats().then((v) => _userStats = v),
      ]);
    } catch (e) {
      logger.e('loadAll failed', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
