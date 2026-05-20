import 'package:anholding_app/src/features/notification/data/models/notification_list_response.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_filter.dart';

abstract class NotificationRepository {
  Future<NotificationListResponse> getItems({
    required NotificationFilter filter,
    int page = 1,
    int perPage = 5,
    String recipientType = 'user',
  });

  Future<void> markAsRead({required String id});
}
