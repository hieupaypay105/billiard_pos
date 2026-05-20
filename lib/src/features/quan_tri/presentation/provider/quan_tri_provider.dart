import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/quan_tri/domain/entities/quan_tri_item.dart';
import 'package:anholding_app/src/features/quan_tri/domain/repositories/quan_tri_repository.dart';
import 'package:flutter/foundation.dart';

class QuanTriProvider extends ChangeNotifier {
  QuanTriProvider({required this.repository}) {
    refresh();
  }

  final QuanTriRepository repository;

  // ── Column config ─────────────────────────────────────
  static const List<String> columnOrder = [
    'id',
    'username',
    'fullname',
    'mobile',
    'email',
    'roleName',
    'statusLabel',
  ];

  static const Map<String, String> columnLabels = {
    'id': 'STT',
    'username': 'Tên đăng nhập',
    'fullname': 'Họ và tên',
    'mobile': 'Điện thoại',
    'email': 'Email',
    'roleName': 'Nhóm quyền',
    'statusLabel': 'Trạng thái',
  };

  // ── State ─────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;

  bool _isSubmitting = false;
  String? _submitError;
  Map<String, List<String>>? _submitFieldErrors;

  String? _sortColumnKey;
  bool _sortAscending = true;

  QuanTriFilter _filter = const QuanTriFilter();
  List<QuanTriItem> _allItems = const [];

  // Pagination (Lazy Scroll)
  int _nextPage = 1;
  int _total = 0;
  int _perPage = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final Map<String, bool> _visibleColumns = {
    for (final key in columnOrder) key: true,
  };

  // ── Getters ───────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get sortColumnKey => _sortColumnKey;
  bool get sortAscending => _sortAscending;
  QuanTriFilter get filter => _filter;
  Map<String, bool> get visibleColumns => Map.unmodifiable(_visibleColumns);

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  Map<String, List<String>>? get submitFieldErrors => _submitFieldErrors;

  int get total => _total;
  int get perPage => _perPage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  List<QuanTriItem> get items {
    final list = List<QuanTriItem>.from(_allItems);
    _applySort(list);
    return list;
  }

  // ── Data loading (Lazy Scroll) ────────────────────────
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    _nextPage = 1;
    _hasMore = true;
    _allItems = [];
    notifyListeners();

    try {
      final filterWithPagination = _filter.copyWith(
        page: _nextPage,
        perPage: _perPage,
      );

      final response = await repository.getItems(filter: filterWithPagination);
      _allItems = response.items;
      _total = response.pagination.total;
      _perPage = response.pagination.perPage;

      if (_allItems.length >= _total) {
        _hasMore = false;
      } else {
        _nextPage++;
      }
    } catch (e) {
      logger.e('refresh failed', error: e);
      _errorMessage = 'Không có dữ liệu hiển thị';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final filterWithPagination = _filter.copyWith(
        page: _nextPage,
        perPage: _perPage,
      );

      final response = await repository.getItems(filter: filterWithPagination);
      _allItems.addAll(response.items);
      _total = response.pagination.total;

      if (_allItems.length >= _total || response.items.isEmpty) {
        _hasMore = false;
      } else {
        _nextPage++;
      }
    } catch (e) {
      logger.e('loadMore failed', error: e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Sorting (client-side) ──────────────────────────────
  void sort(String columnKey, {required bool ascending}) {
    _sortColumnKey = columnKey;
    _sortAscending = ascending;
    notifyListeners();
  }

  // ── Filtering (server-side) ────────────────────────────
  Future<void> applyFilter(QuanTriFilter filter) async {
    _filter = filter;
    await refresh();
  }

  Future<void> clearFilter() async {
    _filter = const QuanTriFilter();
    await refresh();
  }

  // ── Column visibility ─────────────────────────────────
  void toggleColumn(String columnKey) {
    if (!_visibleColumns.containsKey(columnKey)) return;
    _visibleColumns[columnKey] = !(_visibleColumns[columnKey] ?? true);
    notifyListeners();
  }

  void toggleAllColumns(bool visible) {
    for (final key in _visibleColumns.keys) {
      _visibleColumns[key] = visible;
    }
    notifyListeners();
  }

  bool get allColumnsSelected => _visibleColumns.values.every((value) => value);

  bool isColumnVisible(String key) => _visibleColumns[key] ?? false;

  // ── Create Item ───────────────────────────────────────
  Future<bool> createItem({required Map<String, dynamic> data}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitFieldErrors = null;
    notifyListeners();

    try {
      await repository.createItem(data: data);
      _isSubmitting = false;
      notifyListeners();
      await refresh();
      return true;
    } on ApiException catch (e) {
      logger.e('createItem ApiException', error: e);
      _submitError = e.message;
      _submitFieldErrors = e.fieldErrors;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      logger.e('createItem failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete Item ───────────────────────────────────────
  Future<bool> deleteItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.deleteItem(id: id);
      _isLoading = false;
      notifyListeners();
      await refresh();
      return true;
    } catch (e) {
      logger.e('deleteItem failed', error: e);
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Update Item ───────────────────────────────────────
  Future<bool> updateItem({required Map<String, dynamic> data}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitFieldErrors = null;
    notifyListeners();

    try {
      await repository.updateItem(data: data);
      _isSubmitting = false;
      notifyListeners();
      await refresh();
      return true;
    } on ApiException catch (e) {
      logger.e('updateItem ApiException', error: e);
      _submitError = e.message;
      _submitFieldErrors = e.fieldErrors;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      logger.e('updateItem failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Sort helpers ──────────────────────────────────────
  void _applySort(List<QuanTriItem> data) {
    final key = _sortColumnKey;
    if (key == null) return;

    int compareString(String a, String b) => a.compareTo(b);

    int resultFor(QuanTriItem left, QuanTriItem right) {
      return switch (key) {
        'username' => compareString(left.username, right.username),
        'fullname' => compareString(left.fullname, right.fullname),
        'email' => compareString(left.email, right.email),
        'mobile' => compareString(left.mobile, right.mobile),
        'roleName' => compareString(left.roleName, right.roleName),
        'statusLabel' => compareString(left.statusLabel, right.statusLabel),
        _ => 0,
      };
    }

    data.sort((left, right) {
      final result = resultFor(left, right);
      return _sortAscending ? result : -result;
    });
  }
}

// ── Filter ──────────────────────────────────────────────

class QuanTriFilter {
  const QuanTriFilter({
    this.keyword,
    this.status,
    this.roleId,
    this.page = 1,
    this.perPage = 50,
  });

  final String? keyword;
  final int? status;
  final String? roleId;
  final int page;
  final int perPage;

  Map<String, dynamic> toQueryParams() {
    return {
      if (keyword != null && keyword!.isNotEmpty) 'keyword': keyword,
      if (status != null) 'status': '$status',
      if (roleId != null && roleId!.isNotEmpty) 'role_id': roleId,
      'page': '$page',
      'per_page': '$perPage',
    };
  }

  QuanTriFilter copyWith({
    String? keyword,
    int? status,
    String? roleId,
    int? page,
    int? perPage,
  }) {
    return QuanTriFilter(
      keyword: keyword ?? this.keyword,
      status: status ?? this.status,
      roleId: roleId ?? this.roleId,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}
