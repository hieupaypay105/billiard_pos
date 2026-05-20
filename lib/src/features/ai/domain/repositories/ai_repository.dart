import 'package:anholding_app/src/features/ai/domain/entities/ai_search_result.dart';

abstract class AiRepository {
  Future<AiSearchResult> search({required String query});
  Future<AiSearchResult> getQuota();
}
