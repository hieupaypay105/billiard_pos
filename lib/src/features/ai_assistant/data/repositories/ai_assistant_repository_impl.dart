import 'package:anholding_app/src/features/ai_assistant/data/datasources/ai_remote_data_source.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_chat_response.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_table_search_result.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  AiAssistantRepositoryImpl({required this.remoteDataSource});
  final AiAssistantRemoteDataSource remoteDataSource;

  @override
  Future<AiChatResponse> sendMessage(String message) {
    return remoteDataSource.sendMessage(message);
  }

  @override
  Future<AiTableSearchResult> searchTable(String query) {
    return remoteDataSource.searchTable(query);
  }

  @override
  Future<AiQuotaRequestInfo> fetchQuota() {
    return remoteDataSource.fetchQuota();
  }
}
