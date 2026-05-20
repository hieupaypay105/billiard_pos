import 'package:equatable/equatable.dart';

/// Domain entity for a notification item.
class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.actionUrl,
    this.deepLink,
    this.readAt,
  });

  final String id;
  final String type;
  final String typeLabel;
  final String title;
  final String content;
  final String? actionUrl;
  final String? deepLink;
  final String createdAt;
  final bool isRead;
  final String? readAt;

  NotificationItem copyWith({
    String? id,
    String? type,
    String? typeLabel,
    String? title,
    String? content,
    String? actionUrl,
    String? deepLink,
    String? createdAt,
    bool? isRead,
    String? readAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      title: title ?? this.title,
      content: content ?? this.content,
      actionUrl: actionUrl ?? this.actionUrl,
      deepLink: deepLink ?? this.deepLink,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    typeLabel,
    title,
    content,
    actionUrl,
    deepLink,
    createdAt,
    isRead,
    readAt,
  ];
}
