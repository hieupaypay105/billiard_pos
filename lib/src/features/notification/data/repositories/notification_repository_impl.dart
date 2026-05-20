import 'package:anholding_app/src/features/notification/data/datasources/notification_remote_source.dart';
import 'package:anholding_app/src/features/notification/data/models/notification_list_response.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_filter.dart';
import 'package:anholding_app/src/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({required this.dataSource});

  final NotificationRemoteDataSource dataSource;

  @override
  Future<NotificationListResponse> getItems({
    required NotificationFilter filter,
    int page = 1,
    int perPage = 5,
    String recipientType = 'user',
  }) {
    return dataSource.getItems(
      page: page,
      perPage: perPage,
      recipientType: recipientType,
      filter: filter,
    );
  }

  @override
  Future<void> markAsRead({required String id}) {
    return dataSource.markAsRead(id: id);
  }
}
