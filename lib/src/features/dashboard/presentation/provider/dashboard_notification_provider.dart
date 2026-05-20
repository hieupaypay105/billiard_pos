import 'dart:async';

import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_filter.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_item.dart';
import 'package:anholding_app/src/features/notification/domain/repositories/notification_repository.dart';
import 'package:anholding_app/src/features/notification/presentation/provider/notification_provider.dart'
    show NotificationProvider;
import 'package:flutter/foundation.dart';

/// Lightweight provider for the dashboard notification card.
/// Always fetches ALL notifications (no type filter, no read/unread filter)
/// and is independent from the main [NotificationProvider] used by the
/// notification screen.
///
/// The dashboard shows the 5 most recent items regardless of read status.
class DashboardNotificationProvider extends ChangeNotifier {
  DashboardNotificationProvider({required this.repository});

  final NotificationRepository repository;

  bool _isLoading = false;
  String? _errorMessage;

  /// All notifications from the API — both read and unread.
  /// The UI renders only the first 5 (.take(5)) but this list is unfiltered.
  List<NotificationItem> _items = const [];
  int _unreadCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationItem> get items => _items;
  int get unreadCount => _unreadCount;

  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch up to 5 pages to find at least 5 unread items for the dashboard preview.
      var page = 1;
      var hasMore = true;
      final unreadList = <NotificationItem>[];

      while (unreadList.length < 5 && page <= 5 && hasMore) {
        final response = await repository.getItems(
          filter: const NotificationFilter(type: null),
          page: page,
          perPage: 20,
        );

        if (page == 1) {
          _unreadCount = response.unreadCount.total;
        }

        unreadList.addAll(response.items.where((item) => !item.isRead));

        if (response.pagination.currentPage >= response.pagination.lastPage) {
          hasMore = false;
        } else {
          page++;
        }
      }

      _items = unreadList.take(5).toList();
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      logger.w(
        'DashboardNotificationProvider.loadItems failed: $_errorMessage',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadItems();
  }

  /// Optimistically updates the unread count and item state without an API call.
  /// Used to instantly reflect status changes in global app bars before the
  /// actual [NotificationProvider.markAsRead] finishes its network request.
  void markAsReadOptimistic(String id) {
    var changed = false;

    // 1. Update the item if it exists in the dashboard's preview list
    // The dashboard only shows unread items, so we remove it completely.
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = List<NotificationItem>.from(_items);
      updated.removeAt(index);
      _items = updated;
      changed = true;
    }

    // 2. Safely decrement global unread count
    // (We decrement even if the item wasn't in our top 5 list,
    // because it might have been read from the full NotificationScreen)
    if (_unreadCount > 0) {
      _unreadCount -= 1;
      changed = true;
    }

    if (changed) {
      notifyListeners();

      // If we depleted the local list but there are still unread items globally,
      // trigger a background refresh to find the next batch.
      if (_items.isEmpty && _unreadCount > 0) {
        unawaited(refresh());
      }
    }
  }
}
