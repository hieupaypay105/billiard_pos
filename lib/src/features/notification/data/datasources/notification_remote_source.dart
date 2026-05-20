import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/notification/data/models/notification_list_response.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_filter.dart';
import 'package:dio/dio.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationListResponse> getItems({
    required NotificationFilter filter,
    int page = 1,
    int perPage = 5,
    String recipientType = 'user',
  });

  Future<void> markAsRead({required String id});
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<NotificationListResponse> getItems({
    required NotificationFilter filter,
    int page = 1,
    int perPage = 5,
    String recipientType = 'user',
  }) async {
    try {
      final formData = FormData.fromMap({
        'recipient_type': recipientType,
        'page': '$page',
        'per_page': '$perPage',
        ...filter.toQueryParams(),
      });

      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.notificationList,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final errors = data['errors'];
        final message = (errors is Map<String, dynamic>)
            ? errors['target']?.toString()
            : null;
        throw Exception(message ?? 'Không thể lấy danh sách thông báo');
      }

      final inner = data['data'];
      if (inner == null || inner is! Map<String, dynamic>) {
        throw Exception('Invalid data from server');
      }

      return NotificationListResponse.fromJson(inner);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message']?.toString()
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to load notification data',
      );
    }
  }

  @override
  Future<void> markAsRead({required String id}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiPaths.notificationRead,
        data: FormData.fromMap({'id': id}),
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể đánh dấu đã đọc');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;
      throw Exception(
        message ?? e.message ?? 'Failed to mark notification as read',
      );
    }
  }
}
