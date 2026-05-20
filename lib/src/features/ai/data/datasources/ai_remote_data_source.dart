import 'package:dio/dio.dart';

abstract class AiRemoteDataSource {
  Future<Map<String, dynamic>> search({required String query});
  Future<Map<String, dynamic>> getQuota();
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final Dio dio;

  AiRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> search({required String query}) async {
    final response = await dio.post('/ai/search', data: {'query': query});
    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] == 1) {
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['errors']?.toString() ?? 'Lỗi không xác định từ API');
      }
    }
    throw Exception('Failed to search AI. Status code: ${response.statusCode}');
  }

  @override
  Future<Map<String, dynamic>> getQuota() async {
    final response = await dio.get('/ai/quota');
    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] == 1) {
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['errors']?.toString() ?? 'Lỗi không xác định từ API');
      }
    }
    throw Exception('Failed to get quota. Status code: ${response.statusCode}');
  }
}
