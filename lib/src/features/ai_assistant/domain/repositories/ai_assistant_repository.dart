import 'package:anholding_app/src/core/error/api_exception.dart'
    show ApiException;
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_chat_response.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_table_search_result.dart';

abstract class AiAssistantRepository {
  /// Gửi tin nhắn chat chatbot.
  /// Ném [ApiException] nếu có lỗi từ server.
  Future<AiChatResponse> sendMessage(String message);

  /// Tìm kiếm bảng hàng thông qua AI assistant.
  /// Ném [ApiException] nếu có lỗi từ server.
  Future<AiTableSearchResult> searchTable(String query);

  /// Lấy thông tin quota hiện tại khi vào màn hình lần đầu.
  /// Ném [ApiException] nếu có lỗi từ server.
  Future<AiQuotaRequestInfo> fetchQuota();
}
