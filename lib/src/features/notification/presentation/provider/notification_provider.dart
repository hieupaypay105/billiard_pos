import 'package:anholding_app/src/features/notification/data/models/notification_list_response.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_filter.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_item.dart';
import 'package:anholding_app/src/features/notification/domain/repositories/notification_repository.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required this.repository});
  // NOTE: Initial load is intentionally deferred to NotificationScreen.initState
  // (via postFrameCallback) so that it runs only after the user has authenticated
  // and the AuthInterceptor has a valid token. Calling loadItems() here (at app
  // startup) would fire before login and produce a 401 / empty-items state that
  // hides the real data when the screen is first opened.

  final NotificationRepository repository;

  // ── Constants ──────────────────────────────────────────
  static const kDefaultNotificationType = 'CUSTOMER';
  static const kDefaultPerPage = 20;

  // ── State ─────────────────────────────────────────────
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  List<NotificationItem> _items = const [];
  // Default filter = CUSTOMER (type: 'CUSTOMER') — in sync with _selectedFilterIndex = 1.
  // NotificationFilter already defaults to 'CUSTOMER', so no explicit arg needed.
  NotificationFilter _filter = const NotificationFilter();

  // Pagination (used internally for lazy scroll)
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  final int _perPage = kDefaultPerPage;
  NotificationUnreadCount _unreadCount = const NotificationUnreadCount();

  // Filter tab state (synced with UI)
  int _selectedFilterIndex = 1; // 1 = Khách hàng (CUSTOMER)

  // ── Getters ───────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<NotificationItem> get items => _items;
  NotificationFilter get filter => _filter;
  String? get notificationType => _filter.type;

  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  int get perPage => _perPage;

  NotificationUnreadCount get unreadCount => _unreadCount;
  int get selectedFilterIndex => _selectedFilterIndex;

  // ── Initial / Reset load ──────────────────────────────
  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    _items = [];
    notifyListeners();

    try {
      final response = await repository.getItems(
        perPage: _perPage,
        filter: _filter,
      );
      _items = response.items;
      _unreadCount = response.unreadCount;
      _currentPage = response.pagination.currentPage;
      _lastPage = response.pagination.lastPage;
      _total = response.pagination.total;
      _hasMore = _currentPage < _lastPage;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Lazy scroll: load more ────────────────────────────
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await repository.getItems(
        page: nextPage,
        perPage: _perPage,
        filter: _filter,
      );
      _items = [..._items, ...response.items];
      _unreadCount = response.unreadCount;
      _currentPage = response.pagination.currentPage;
      _lastPage = response.pagination.lastPage;
      _total = response.pagination.total;
      _hasMore = _currentPage < _lastPage;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Filter by type ────────────────────────────────────
  Future<void> setNotificationType(
    String? type, {
    required int filterIndex,
  }) async {
    if (_filter.type == type) return;
    _filter = _filter.copyWith(type: type);
    _selectedFilterIndex = filterIndex;
    await loadItems();
  }

  // ── Mark As Read ──────────────────────────────────────
  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    // Already read — skip
    if (_items[index].isRead) return;

    // Optimistic update: reflect change immediately in UI
    final original = _items[index];
    final updated = List<NotificationItem>.from(_items);
    updated[index] = original.copyWith(
      isRead: true,
      readAt: DateTime.now().toIso8601String(),
    );
    _items = updated;
    notifyListeners();

    try {
      await repository.markAsRead(id: id);
      // Reload current data to sync unread counts
      await loadItems();
    } on Exception catch (_) {
      // Rollback on failure
      final rollback = List<NotificationItem>.from(_items);
      rollback[index] = original;
      _items = rollback;
      notifyListeners();
    }
  }

  // ── Refresh (keep current filter) ─────────────────────
  Future<void> refresh() async {
    await loadItems();
  }
}
