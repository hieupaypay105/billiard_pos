import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/ai_assistant/data/models/ai_chat_response_model.dart';
import 'package:anholding_app/src/features/ai_assistant/data/models/ai_quota_request_info_model.dart';
import 'package:anholding_app/src/features/ai_assistant/data/models/ai_table_search_result_model.dart';
import 'package:dio/dio.dart';

abstract class AiAssistantRemoteDataSource {
  Future<AiChatResponseModel> sendMessage(String message);
  Future<AiTableSearchResultModel> searchTable(String query);
  Future<AiQuotaRequestInfoModel> fetchQuota();
}

class AiAssistantRemoteDataSourceImpl implements AiAssistantRemoteDataSource {
  AiAssistantRemoteDataSourceImpl({required this.dio});
  final Dio dio;

  @override
  Future<AiChatResponseModel> sendMessage(String message) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.aiChat,
        data: {'message': message},
      );

      final data = response.data;
      if (data == null) {
        throw ApiException('Dữ liệu từ máy chủ không hợp lệ');
      }

      // Check standard project wrapper pattern 'status: 1'
      if (data.containsKey('status')) {
        final status = data['status'];
        if (status == 0) {
          final errMsg = data['message']?.toString();
          throw ApiException(errMsg ?? 'Lỗi từ hệ thống AI');
        }
        final inner = data['data'];
        if (inner == null || inner is! Map<String, dynamic>) {
          throw ApiException('Định dạng dữ liệu không hợp lệ');
        }
        return AiChatResponseModel.fromJson(inner);
      }

      // Fallback: API returns raw response object as per screenshot
      return AiChatResponseModel.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw ApiException(message ?? e.message ?? 'Lỗi kết nối đến máy chủ AI');
    }
  }

  @override
  Future<AiTableSearchResultModel> searchTable(String query) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.aiSearch,
        data: {'query': query},
      );

      final data = response.data;
      if (data == null) {
        throw ApiException('Dữ liệu từ máy chủ không hợp lệ');
      }

      if (data.containsKey('status')) {
        final status = data['status'];
        if (status == 0) {
          final errMsg = data['message']?.toString();
          throw ApiException(errMsg ?? 'Lỗi tìm kiếm bảng hàng');
        }
        final inner = data['data'];
        if (inner == null || inner is! Map<String, dynamic>) {
          throw ApiException('Định dạng dữ liệu không hợp lệ');
        }
        return AiTableSearchResultModel.fromJson(inner);
      }

      return AiTableSearchResultModel.fromJson(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw ApiException(message ?? e.message ?? 'Lỗi kết nối tìm kiếm');
    }
  }

  @override
  Future<AiQuotaRequestInfoModel> fetchQuota() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(ApiPaths.aiQuota);

      final data = response.data;
      if (data == null) {
        throw ApiException('Dữ liệu quota không hợp lệ');
      }

      if (data.containsKey('status')) {
        final status = data['status'];
        if (status == 0) {
          final errMsg = data['message']?.toString();
          throw ApiException(errMsg ?? 'Lỗi lấy thông tin quota');
        }
        final inner = data['data'];
        if (inner == null || inner is! Map<String, dynamic>) {
          throw ApiException('Định dạng dữ liệu quota không hợp lệ');
        }
        final quotaRequestInfo = inner['quota_request_info'];
        if (quotaRequestInfo == null ||
            quotaRequestInfo is! Map<String, dynamic>) {
          throw ApiException('Không tìm thấy quota_request_info');
        }
        return AiQuotaRequestInfoModel.fromJson(quotaRequestInfo);
      }

      // Fallback: data trực tiếp có quota_request_info
      final quotaRequestInfo = data['quota_request_info'];
      if (quotaRequestInfo == null ||
          quotaRequestInfo is! Map<String, dynamic>) {
        throw ApiException('Không tìm thấy quota_request_info');
      }
      return AiQuotaRequestInfoModel.fromJson(quotaRequestInfo);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw ApiException(message ?? e.message ?? 'Lỗi lấy thông tin quota');
    }
  }
}
