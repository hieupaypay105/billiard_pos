import 'package:anholding_app/src/features/notification/data/models/notification_item_model.dart';

class NotificationListResponse {
  const NotificationListResponse({
    required this.items,
    required this.pagination,
    required this.unreadCount,
  });

  /// API response structure:
  /// { "item": [...], "pagination": {...}, "unread_count": {...} }
  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final itemList = json['item'];
    final items = <NotificationItemModel>[];

    if (itemList is List) {
      for (final item in itemList) {
        if (item is Map<String, dynamic>) {
          items.add(NotificationItemModel.fromJson(item));
        }
      }
    }

    return NotificationListResponse(
      items: items,
      pagination: NotificationPagination.fromJson(
        json['pagination'] is Map<String, dynamic>
            ? json['pagination'] as Map<String, dynamic>
            : {},
      ),
      unreadCount: NotificationUnreadCount.fromJson(
        json['unread_count'] is Map<String, dynamic>
            ? json['unread_count'] as Map<String, dynamic>
            : {},
      ),
    );
  }

  final List<NotificationItemModel> items;
  final NotificationPagination pagination;
  final NotificationUnreadCount unreadCount;
}

class NotificationPagination {
  const NotificationPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      total: _parseInt(json['total']),
      perPage: _parseInt(json['per_page']),
      currentPage: _parseInt(json['current_page']),
      lastPage: _parseInt(json['last_page']),
    );
  }

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class NotificationUnreadCount {
  const NotificationUnreadCount({
    this.customer = 0,
    this.data = 0,
    this.important = 0,
    this.other = 0,
    this.total = 0,
  });

  factory NotificationUnreadCount.fromJson(Map<String, dynamic> json) {
    return NotificationUnreadCount(
      customer: _parseInt(json['CUSTOMER']),
      data: _parseInt(json['DATA']),
      important: _parseInt(json['IMPORTANT']),
      other: _parseInt(json['OTHER']),
      total: _parseInt(json['total']),
    );
  }

  final int customer;
  final int data;
  final int important;
  final int other;
  final int total;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
