import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/du_an/data/models/du_an_list_response.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';
import 'package:dio/dio.dart';

abstract class DuAnRemoteDataSource {
  Future<DuAnListResponse> getItems({
    required DuAnFilter filter,
  });

  Future<void> createItem({required Map<String, dynamic> data});

  Future<void> updateItem({required Map<String, dynamic> data});

  Future<void> deleteItem({required String id});
}

class DuAnRemoteDataSourceImpl implements DuAnRemoteDataSource {
  DuAnRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<DuAnListResponse> getItems({
    required DuAnFilter filter,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.duAnList,
        queryParameters: filter.toQueryParams(),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể lấy danh sách dự án');
      }

      final inner = data['data'];
      if (inner == null || inner is! Map<String, dynamic>) {
        throw Exception('Invalid data from server');
      }

      return DuAnListResponse.fromJson(inner);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to load du an data',
      );
    }
  }

  @override
  Future<void> createItem({required Map<String, dynamic> data}) async {
    try {
      final formData = FormData.fromMap(data);

      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.duAnCreate,
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
      throw Exception(message ?? e.message ?? 'Không thể tạo dự án');
    }
  }

  @override
  Future<void> updateItem({required Map<String, dynamic> data}) async {
    try {
      final formData = FormData.fromMap(data);

      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.duAnUpdate,
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
        message ?? e.message ?? 'Không thể cập nhật dự án',
      );
    }
  }

  @override
  Future<void> deleteItem({required String id}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.duAnDelete,
        data: FormData.fromMap({'id': id}),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể xoá dự án');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to delete du an',
      );
    }
  }
}
