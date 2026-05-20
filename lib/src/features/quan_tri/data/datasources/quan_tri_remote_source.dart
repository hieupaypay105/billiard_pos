import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/quan_tri/data/models/quan_tri_list_response.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:dio/dio.dart';

abstract class QuanTriRemoteDataSource {
  Future<QuanTriListResponse> getItems({
    required QuanTriFilter filter,
  });

  Future<void> createItem({required Map<String, dynamic> data});

  Future<void> updateItem({required Map<String, dynamic> data});

  Future<void> deleteItem({required String id});
}

class QuanTriRemoteDataSourceImpl implements QuanTriRemoteDataSource {
  QuanTriRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<QuanTriListResponse> getItems({
    required QuanTriFilter filter,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.quanTriList,
        queryParameters: filter.toQueryParams(),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể lấy danh sách quản trị');
      }

      final inner = data['data'];
      if (inner == null || inner is! Map<String, dynamic>) {
        throw Exception('Invalid data from server');
      }

      return QuanTriListResponse.fromJson(inner);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to load quan tri data',
      );
    }
  }

  @override
  Future<void> createItem({required Map<String, dynamic> data}) async {
    try {
      final formData = FormData.fromMap(data);

      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.quanTriCreate,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      final status = result['status'];
      if (status != 1) {
        final errors = result['errors'] as List<dynamic>?;
        final message = result['message']?.toString();
        final errorMsg = errors != null && errors.isNotEmpty
            ? errors.join(', ')
            : message ?? 'Thêm mới thất bại';
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(message ?? e.message ?? 'Không thể tạo quản trị');
    }
  }

  @override
  Future<void> updateItem({required Map<String, dynamic> data}) async {
    try {
      final formData = FormData.fromMap(data);

      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.quanTriUpdate,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      final status = result['status'];
      if (status != 1) {
        final errors = result['errors'] as List<dynamic>?;
        final message = result['message']?.toString();
        final errorMsg = errors != null && errors.isNotEmpty
            ? errors.join(', ')
            : message ?? 'Cập nhật thất bại';
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Không thể cập nhật quản trị',
      );
    }
  }

  @override
  Future<void> deleteItem({required String id}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.quanTriDelete,
        data: FormData.fromMap({'id': id}),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể xoá quản trị');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to delete quan tri',
      );
    }
  }
}
