import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_list_response.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_option_response.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_filter.dart';
import 'package:dio/dio.dart';

abstract class BangHangRemoteDataSource {
  Future<BangHangListResponse> getItems({required BangHangFilter filter});

  /// Fetches option values for a given filter [type] and [projectId].
  ///
  /// [type] values: 'area' | 'type' | 'direction' | 'handover_status'
  Future<List<String>> getFilterOptions({
    required int projectId,
    required String type,
  });

  /// Fetches column configuration.
  Future<Map<String, String>> getColumnConfigs({required int projectId});
}

class BangHangRemoteDataSourceImpl implements BangHangRemoteDataSource {
  BangHangRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<BangHangListResponse> getItems({
    required BangHangFilter filter,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.bangHangList,
        data: filter.toPayload(),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể lấy danh sách bảng hàng');
      }

      final inner = data['data'];
      if (inner == null || inner is! Map<String, dynamic>) {
        throw Exception('Invalid data from server');
      }

      return BangHangListResponse.fromJson(inner);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to load bang hang data',
      );
    }
  }

  @override
  Future<List<String>> getFilterOptions({
    required int projectId,
    required String type,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.bangHangOption,
        queryParameters: {'project_id': projectId, 'type': type},
      );

      final data = response.data;
      if (data == null) throw ApiException('Invalid response from server');

      // Only throw on explicit failure status.
      final status = data['status'];
      if (status == 0) {
        final message =
            data['message']?.toString() ?? 'Không thể tải dữ liệu lọc';
        throw ApiException(message);
      }

      final parsed = BangHangOptionResponse.fromJson(data);
      return parsed.options;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw ApiException(message ?? e.message ?? 'Không thể tải dữ liệu lọc');
    }
  }

  @override
  Future<Map<String, String>> getColumnConfigs({required int projectId}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.bangHangField,
        data: {'project_id': projectId},
      );

      final data = response.data;
      if (data == null) throw ApiException('Invalid response from server');

      final status = data['status'];
      if (status == 0) {
        final message =
            data['message']?.toString() ?? 'Không thể tải cấu hình cột';
        throw ApiException(message);
      }

      final dynamic innerData = data['atrtibute'];
      if (innerData is Map) {
        return innerData.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      } else if (innerData is List) {
        final map = <String, String>{};
        for (final item in innerData) {
          if (item is Map) {
            final key = item['key'] ?? item['field'] ?? item['id'];
            final value =
                item['label'] ?? item['name'] ?? item['title'] ?? item['value'];
            if (key != null && value != null) {
              map[key.toString()] = value.toString();
            }
          }
        }
        return map;
      }
      return {};
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Không thể tải cấu hình cột');
    }
  }
}
