import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_chat_message.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_info.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:flutter/material.dart';

class AiAssistantProvider extends ChangeNotifier {
  AiAssistantProvider({required this.repository});
  final AiAssistantRepository repository;

  // --- Shared State ---
  AiQuotaInfo? _quotaInfo;
  AiQuotaInfo? get quotaInfo => _quotaInfo;

  AiQuotaRequestInfo? _quotaRequestInfo;
  AiQuotaRequestInfo? get quotaRequestInfo => _quotaRequestInfo;

  bool _isLoadingQuota = false;
  bool get isLoadingQuota => _isLoadingQuota;

  // --- Chat State ---
  static AiMessage get _greetingMessage => AiMessage(
    text:
        'Chào bạn, mình là Trợ lý AI Anholding CRM. Mình có thể giúp bạn phân tích thông tin khách hàng, tư vấn kịch bản bán hàng hoặc giải đáp các thắc mắc về bất động sản. Mình có thể giúp gì cho bạn hôm nay?',
    isUser: false,
    timestamp: DateTime.now(),
  );

  final List<AiMessage> _messages = [_greetingMessage];
  List<AiMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // We keep latestItems for backward compatibility, but tableItems is better
  List<dynamic>? _latestItems;
  List<dynamic>? get latestItems => _latestItems;

  // --- Table Search State ---
  List<BangHangItem>? _tableItems;
  List<BangHangItem>? get tableItems => _tableItems;

  Map<String, dynamic>? _tableFilters;
  Map<String, dynamic>? get tableFilters => _tableFilters;

  bool _isSearchingTable = false;
  bool get isSearchingTable => _isSearchingTable;

  String? _tableError;
  String? get tableError => _tableError;

  /// Fetch quota thông tin lần đầu khi vào màn hình.
  /// Chỉ gọi nếu chưa có quotaRequestInfo.
  /// Silently fails — quota là thông tin phụ trợ, không block UX.
  Future<void> fetchInitialQuota() async {
    if (_quotaRequestInfo != null) return; // đã có dữ liệu, bỏ qua
    if (_isLoadingQuota) return; // đang load, bỏ qua

    _isLoadingQuota = true;
    notifyListeners();

    try {
      _quotaRequestInfo = await repository.fetchQuota();
    } on ApiException catch (_) {
      // Silently fail — không block trải nghiệm người dùng
    } catch (_) {
      // Silently fail
    } finally {
      _isLoadingQuota = false;
      notifyListeners();
    }
  }

  /// Xóa toàn bộ hội thoại, reset về tin nhắn chào mừng ban đầu.
  void clearChat() {
    _messages
      ..clear()
      ..add(_greetingMessage);
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final sanitizedText = text.trim();
    if (sanitizedText.isEmpty) return;

    _messages.add(
      AiMessage(
        text: sanitizedText,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await repository.sendMessage(sanitizedText);

      if (response.reply != null && response.reply!.isNotEmpty) {
        _messages.add(
          AiMessage(
            text: response.reply!,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }

      if (response.quotaInfo != null) {
        _quotaInfo = response.quotaInfo;
      }
      if (response.quotaRequestInfo != null) {
        _quotaRequestInfo = response.quotaRequestInfo;
      }
      if (response.items != null) {
        _latestItems = response.items;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Lỗi không xác định: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchTable(String query) async {
    final sanitizedQuery = query.trim();
    if (sanitizedQuery.isEmpty) return;

    _isSearchingTable = true;
    _tableError = null;
    notifyListeners();

    try {
      final response = await repository.searchTable(sanitizedQuery);

      if (response.quotaInfo != null) {
        _quotaInfo = response.quotaInfo;
      }
      // quota_request_info từ /ai/search override quota ban đầu từ /ai/quota
      if (response.quotaRequestInfo != null) {
        _quotaRequestInfo = response.quotaRequestInfo;
      }

      _tableFilters = response.filters;
      _tableItems = response.items;
      _latestItems = response.items;
    } on ApiException catch (e) {
      _tableError = e.message;
    } catch (e) {
      _tableError = 'Lỗi không xác định: $e';
    } finally {
      _isSearchingTable = false;
      notifyListeners();
    }
  }

  void clearTableSearch() {
    _tableItems = null;
    _tableFilters = null;
    _tableError = null;
    // We intentionally do NOT clear shared quota info
    notifyListeners();
  }
}
