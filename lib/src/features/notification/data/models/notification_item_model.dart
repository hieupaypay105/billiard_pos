import 'package:anholding_app/src/features/notification/domain/entities/notification_item.dart';

class NotificationItemModel extends NotificationItem {
  const NotificationItemModel({
    required super.id,
    required super.type,
    required super.typeLabel,
    required super.title,
    required super.content,
    required super.createdAt,
    required super.isRead,
    super.actionUrl,
    super.deepLink,
    super.readAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      actionUrl: json['action_url']?.toString(),
      deepLink: json['deep_link']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      isRead: json['is_read']?.toString() == '1',
      readAt: json['read_at']?.toString(),
    );
  }
}
