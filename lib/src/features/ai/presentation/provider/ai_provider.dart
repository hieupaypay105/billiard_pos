import 'package:anholding_app/src/features/ai/domain/entities/ai_search_result.dart';
import 'package:anholding_app/src/features/ai/domain/repositories/ai_repository.dart';
import 'package:flutter/material.dart';

class AiProvider extends ChangeNotifier {
  final AiRepository repository;

  AiProvider({required this.repository});

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;

  AiSearchResult? _lastResult;
  AiSearchResult? get lastResult => _lastResult;

  AiQuotaInfo? _quotaInfo;
  AiQuotaInfo? get quotaInfo => _quotaInfo;

  AiQuotaInfo? _quotaRequestInfo;
  AiQuotaInfo? get quotaRequestInfo => _quotaRequestInfo;

  /// Thường thì quota limits sẽ được load khi mở page từ một API lấy thông tin người dùng,
  /// nhưng tạm thời lấy từ result của API search. Nếu chưa search thì có thể null.
  
  Future<void> loadQuota() async {
    try {
      final quotaResult = await repository.getQuota();
      _quotaInfo = quotaResult.quotaInfo;
      _quotaRequestInfo = quotaResult.quotaRequestInfo;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load Ai quota: $e');
    }
  }
  
  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final result = await repository.search(query: query);
      _lastResult = result;
      if (result.quotaInfo != null) _quotaInfo = result.quotaInfo;
      if (result.quotaRequestInfo != null) _quotaRequestInfo = result.quotaRequestInfo;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _lastResult = null;
    _error = null;
    notifyListeners();
  }
}
