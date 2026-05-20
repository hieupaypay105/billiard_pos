import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/contact_item_model.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_list_response.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_filter.dart';
import 'package:dio/dio.dart';

abstract class KhachHangRemoteDataSource {
  Future<KhachHangListResponse> getItems({
    required KhachHangFilter filter,
  });

  Future<KhachHangOptionResponse> getOptions();

  Future<void> createCustomer({required Map<String, dynamic> data});

  Future<void> updateCustomer({required Map<String, dynamic> data});

  Future<void> deleteItem({required String id});

  /// Fetches option values for a given filter [type] within a [projectId].
  ///
  /// Reuses the `/data/option` endpoint (same as BangHang).
  /// [type] values: 'area' | 'type' | 'direction' | 'handover_status'
  Future<List<String>> getFilterOptions({
    required int projectId,
    required String type,
  });

  Future<List<ContactItemModel>> getListContact({
    required String customerId,
  });

  Future<void> createContact({
    required String customerId,
    required String comment,
  });

  Future<String> deleteContact({required String contactId});

  Future<void> saveFilter({
    required String name,
    required Map<String, dynamic> data,
  });

  Future<void> setDefaultFilter({required String id, required int isDefault});

  Future<void> deleteFilter({required String id});
}

class KhachHangRemoteDataSourceImpl implements KhachHangRemoteDataSource {
  KhachHangRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<KhachHangListResponse> getItems({
    required KhachHangFilter filter,
  }) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        ApiPaths.khachHangList,
        data: filter.toPayload(),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể lấy danh sách khách hàng');
      }

      final inner = data['data'];

      // API trả về [] khi không có kết quả (empty list thay vì Map)
      if (inner is List && inner.isEmpty) {
        return const KhachHangListResponse(
          items: [],
          pagination: KhachHangPagination(
            total: 0,
            perPage: 50,
            currentPage: 1,
            lastPage: 1,
          ),
        );
      }

      if (inner == null || inner is! Map<String, dynamic>) {
        throw Exception('Invalid data from server');
      }

      return KhachHangListResponse.fromJson(inner);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to load khach hang data',
      );
    }
  }

  @override
  Future<KhachHangOptionResponse> getOptions() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.khachHangOption,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      return KhachHangOptionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Không thể tải danh sách tuỳ chọn khách hàng',
      );
    }
  }

  @override
  Future<void> createCustomer({required Map<String, dynamic> data}) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        ApiPaths.khachHangCreate,
        data: data,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      final status = result['status'];
      if (status != 1) {
        final errorsRaw = result['errors'];
        Map<String, List<String>>? fieldErrors;

        if (errorsRaw is Map) {
          fieldErrors = {};
          errorsRaw.forEach((key, value) {
            if (value is List) {
              fieldErrors![key.toString()] = value
                  .map((e) => e.toString())
                  .toList();
            } else if (value != null) {
              fieldErrors![key.toString()] = [value.toString()];
            }
          });
        }

        final message = result['message']?.toString() ?? 'Thêm mới thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errorsRaw = data['errors'];
        Map<String, List<String>>? fieldErrors;

        if (errorsRaw is Map) {
          fieldErrors = {};
          errorsRaw.forEach((key, value) {
            if (value is List) {
              fieldErrors![key.toString()] = value
                  .map((e) => e.toString())
                  .toList();
            } else if (value != null) {
              fieldErrors![key.toString()] = [value.toString()];
            }
          });
        }

        final message = data['message']?.toString() ?? 'Thêm mới thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }

      throw Exception(e.message ?? 'Không thể tạo khách hàng');
    }
  }

  @override
  Future<void> updateCustomer({required Map<String, dynamic> data}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.khachHangUpdate,
        data: data,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      final status = result['status'];
      if (status != 1) {
        final errorsRaw = result['errors'];
        Map<String, List<String>>? fieldErrors;

        if (errorsRaw is Map && errorsRaw.isNotEmpty) {
          fieldErrors = {};
          errorsRaw.forEach((key, value) {
            if (value is List) {
              fieldErrors![key.toString()] = value
                  .map((e) => e.toString())
                  .toList();
            } else if (value != null) {
              fieldErrors![key.toString()] = [value.toString()];
            }
          });
        }

        final message = result['message']?.toString() ?? 'Cập nhật thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errorsRaw = data['errors'];
        Map<String, List<String>>? fieldErrors;

        if (errorsRaw is Map) {
          fieldErrors = {};
          errorsRaw.forEach((key, value) {
            if (value is List) {
              fieldErrors![key.toString()] = value
                  .map((e) => e.toString())
                  .toList();
            } else if (value != null) {
              fieldErrors![key.toString()] = [value.toString()];
            }
          });
        }

        final message = data['message']?.toString() ?? 'Cập nhật thất bại';
        throw ApiException(message, fieldErrors: fieldErrors);
      }

      throw Exception(e.message ?? 'Không thể cập nhật khách hàng');
    }
  }

  @override
  Future<void> deleteItem({required String id}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.khachHangDelete,
        data: FormData.fromMap({'id': id}),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể xoá khách hàng');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to delete khach hang',
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
  Future<List<ContactItemModel>> getListContact({
    required String customerId,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.khachHangListContact,
        queryParameters: {'id': customerId},
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['msg']?.toString();
        throw Exception(message ?? 'Không thể lấy danh sách trao đổi');
      }

      final list = data['data'];
      if (list is! List) return const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ContactItemModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['msg'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to load contact list',
      );
    }
  }

  @override
  Future<void> createContact({
    required String customerId,
    required String comment,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.khachHangCreateContact,
        data: {
          'customer_id': customerId,
          'comment': comment,
        },
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status != 1) {
        final message = data['msg']?.toString();
        throw Exception(message ?? 'Không thể tạo trao đổi');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['msg'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to create contact',
      );
    }
  }

  @override
  Future<String> deleteContact({required String contactId}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.khachHangDeleteContact,
        queryParameters: {'id': contactId},
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      if (data['status'] != 1) {
        throw Exception(
          data['msg']?.toString() ?? 'Không thể xoá liên hệ',
        );
      }

      return data['msg']?.toString() ?? 'Xoá thành công';
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['msg'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to delete contact',
      );
    }
  }

  @override
  Future<void> saveFilter({
    required String name,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.khachHangSaveFilter,
        data: {'name': name, 'data': data},
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      if (result['status'] != 1) {
        final message = result['error']?.toString() ?? 'Không thể lưu bộ lọc';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['error'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Không thể lưu bộ lọc',
      );
    }
  }

  @override
  Future<void> setDefaultFilter({
    required String id,
    required int isDefault,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.khachHangSetDefaultFilter,
        data: {'id': id, 'default': isDefault},
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      if (result['status'] != 1) {
        final message =
            result['error']?.toString() ?? 'Không thể cập nhật bộ lọc';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['error'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Không thể cập nhật bộ lọc',
      );
    }
  }

  @override
  Future<void> deleteFilter({required String id}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiPaths.khachHangDeleteFilter,
        queryParameters: {'id': id},
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final result = response.data!;
      if (result['status'] != 1) {
        final message = result['error']?.toString() ?? 'Không thể xoá bộ lọc';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['error'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Không thể xoá bộ lọc',
      );
    }
  }
}
