import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_list_response.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_option_response.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';
import 'package:dio/dio.dart';

abstract class CongTacVienRemoteDataSource {
  Future<CongTacVienListResponse> getItems({
    required CongTacVienFilter filter,
  });

  Future<CongTacVienOptionResponse> getOptions();

  Future<String> genCode();

  Future<void> createPartner({required Map<String, dynamic> data});

  Future<void> updatePartner({required Map<String, dynamic> data});

  Future<void> deleteItem({required String id});
}

class CongTacVienRemoteDataSourceImpl implements CongTacVienRemoteDataSource {
  CongTacVienRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<CongTacVienListResponse> getItems({
    required CongTacVienFilter filter,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.congTacVienList,
        queryParameters: filter.toQueryParams(),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể lấy danh sách cộng tác viên');
      }

      final inner = data['data'];
      if (inner == null || inner is! Map<String, dynamic>) {
        throw Exception('Invalid data from server');
      }

      return CongTacVienListResponse.fromJson(inner);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to load cong tac vien data',
      );
    }
  }

  @override
  Future<CongTacVienOptionResponse> getOptions() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.congTacVienOption,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      return CongTacVienOptionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Không thể tải danh sách Sale QL',
      );
    }
  }

  @override
  Future<String> genCode() async {
    try {
      final response = await dio.get<dynamic>(ApiPaths.partnerGenCode);

      if (response.data == null) {
        throw Exception('Không thể tạo mã');
      }

      // Response là string trực tiếp: "LMOCSL7J"
      final data = response.data;
      if (data is String) return data;

      // Nếu trả về dưới dạng JSON wrapper
      if (data is Map<String, dynamic>) {
        final code = data['data']?.toString() ?? data['code']?.toString();
        if (code != null && code.isNotEmpty) return code;
      }

      throw Exception('Không thể parse mã từ server');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(message ?? e.message ?? 'Không thể tạo mã');
    }
  }

  @override
  Future<void> createPartner({required Map<String, dynamic> data}) async {
    try {
      final formData = FormData.fromMap(data);

      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.partnerCreate,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      final status = result['status'];
      if (status != 1) {
        final fieldErrors = _parseApiErrors(result['errors']);
        final message = result['message']?.toString() ?? 'Thêm mới thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final fieldErrors = _parseApiErrors(data['errors']);
        final message = data['message']?.toString() ?? 'Thêm mới thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }

      throw Exception(e.message ?? 'Không thể tạo cộng tác viên');
    }
  }

  @override
  Future<void> updatePartner({required Map<String, dynamic> data}) async {
    try {
      final formData = FormData.fromMap(data);

      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.partnerUpdate,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      final status = result['status'];
      if (status != 1) {
        final fieldErrors = _parseApiErrors(result['errors']);
        final message = result['message']?.toString() ?? 'Cập nhật thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final fieldErrors = _parseApiErrors(data['errors']);
        final message = data['message']?.toString() ?? 'Cập nhật thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }

      throw Exception(e.message ?? 'Không thể cập nhật cộng tác viên');
    }
  }

  @override
  Future<void> deleteItem({required String id}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.congTacVienDelete,
        data: FormData.fromMap({'id': id}),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể xoá cộng tác viên');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to delete cong tac vien',
      );
    }
  }

  Map<String, List<String>>? _parseApiErrors(errorsRaw) {
    if (errorsRaw is! Map || errorsRaw.isEmpty) return null;

    final fieldErrors = <String, List<String>>{};
    errorsRaw.forEach((key, value) {
      if (value is List) {
        fieldErrors[key.toString()] = value.map((e) => e.toString()).toList();
      } else if (value != null) {
        fieldErrors[key.toString()] = [value.toString()];
      }
    });
    return fieldErrors;
  }
}
