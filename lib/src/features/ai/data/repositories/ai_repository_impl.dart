import 'package:anholding_app/src/features/ai/data/datasources/ai_remote_data_source.dart';
import 'package:anholding_app/src/features/ai/data/models/ai_search_result_model.dart';
import 'package:anholding_app/src/features/ai/domain/entities/ai_search_result.dart';
import 'package:anholding_app/src/features/ai/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource remoteDataSource;

  AiRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AiSearchResult> search({required String query}) async {
    try {
      final json = await remoteDataSource.search(query: query);
      return AiSearchResultModel.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AiSearchResult> getQuota() async {
    try {
      final json = await remoteDataSource.getQuota();
      return AiSearchResultModel.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }
}
