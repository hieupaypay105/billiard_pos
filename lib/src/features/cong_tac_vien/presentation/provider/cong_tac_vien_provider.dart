import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_option_response.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_item.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/repositories/cong_tac_vien_repository.dart';
import 'package:flutter/foundation.dart';

class CongTacVienProvider extends ChangeNotifier {
  CongTacVienProvider({required this.repository}) {
    refresh();
    loadOptions();
  }

  final CongTacVienRepository repository;

  // ── Column config ─────────────────────────────────────
  static const List<String> columnOrder = [
    'id',
    'saleName',
    'code',
    'fullname',
    'email',
    'statusLabel',
    'mobile',
    'createdAt',
  ];

  static const Map<String, String> columnLabels = {
    'id': 'STT',
    'saleName': 'Sale QL',
    'code': 'Mã bảo mật',
    'fullname': 'Họ và tên',
    'email': 'Email',
    'statusLabel': 'Tình trạng',
    'mobile': 'Điện thoại',
    'createdAt': 'Ngày tạo',
  };

  // ── State ─────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;

  bool _isSubmitting = false;
  String? _submitError;
  Map<String, List<String>>? _submitFieldErrors;
  bool _isGenningCode = false;
  bool _isLoadingOptions = false;
  String? _optionsError;

  String? _sortColumnKey;
  bool _sortAscending = true;

  CongTacVienFilter _filter = const CongTacVienFilter();
  CongTacVienOptionResponse? _options;
  List<CongTacVienItem> _allItems = const [];

  // Pagination
  static const int _kPageSize = 10;
  int _nextPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _total = 0;

  final Map<String, bool> _visibleColumns = {
    for (final key in columnOrder) key: true,
  };

  // ── Getters ───────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get sortColumnKey => _sortColumnKey;
  bool get sortAscending => _sortAscending;
  CongTacVienFilter get filter => _filter;
  Map<String, bool> get visibleColumns => Map.unmodifiable(_visibleColumns);

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  Map<String, List<String>>? get submitFieldErrors => _submitFieldErrors;
  bool get isGenningCode => _isGenningCode;
  bool get isLoadingOptions => _isLoadingOptions;
  String? get optionsError => _optionsError;
  CongTacVienOptionResponse? get options => _options;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get total => _total;

  List<CongTacVienItem> get items => List.unmodifiable(_allItems);

  Future<void> loadOptions({bool force = false}) async {
    if (_isLoadingOptions) return;
    if (!force && _options != null) return;

    _isLoadingOptions = true;
    _optionsError = null;
    notifyListeners();

    try {
      _options = await repository.getOptions();
    } catch (e) {
      logger.e('loadOptions failed', error: e);
      _optionsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingOptions = false;
      notifyListeners();
    }
  }

  // ── Data loading ──────────────────────────────────────
  Future<void> refresh() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _allItems = const [];
    _nextPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final filterWithPagination = _filter.copyWith(
        page: 1,
        perPage: _kPageSize,
      );

      final response = await repository.getItems(filter: filterWithPagination);
      _allItems = response.items;
      _total = response.pagination.total;
      _hasMore = response.pagination.currentPage < response.pagination.lastPage;
      _nextPage = 2;
    } catch (e) {
      logger.e('refresh failed', error: e);
      _errorMessage = 'Không có dữ liệu hiển thị';
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final filterWithPagination = _filter.copyWith(
        page: _nextPage,
        perPage: _kPageSize,
      );

      final response = await repository.getItems(filter: filterWithPagination);
      _allItems = [..._allItems, ...response.items];
      _total = response.pagination.total;
      _hasMore = response.pagination.currentPage < response.pagination.lastPage;
      _nextPage = response.pagination.currentPage + 1;
    } catch (e) {
      logger.e('loadMore failed', error: e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Sorting (server-side) ──────────────────────────────
  void sort(String columnKey, {required bool ascending}) {
    _sortColumnKey = columnKey;
    _sortAscending = ascending;

    final apiSortKey = switch (columnKey) {
      'fullname' => 'fullname',
      'email' => 'email',
      'mobile' => 'mobile',
      'statusLabel' => 'status',
      'createdAt' => 'created_at',
      'saleName' => 'sale_id',
      _ => columnKey,
    };

    _filter = _filter.copyWith(
      sortBy: apiSortKey,
      order: ascending ? 'asc' : 'desc',
      page: 1,
    );

    refresh();
  }

  // ── Filtering (server-side) ────────────────────────────
  Future<void> applyFilter(CongTacVienFilter filter) async {
    _filter = filter;
    await refresh();
  }

  Future<void> clearFilter() async {
    _filter = const CongTacVienFilter();
    await refresh();
  }

  // ── Pagination ────────────────────────────────────────

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

  // ── GenCode ───────────────────────────────────────────
  Future<String> genCode() async {
    _isGenningCode = true;
    notifyListeners();

    try {
      final code = await repository.genCode();
      return code;
    } catch (e) {
      logger.e('genCode failed', error: e);
      rethrow;
    } finally {
      _isGenningCode = false;
      notifyListeners();
    }
  }

  // ── Create Partner ────────────────────────────────────
  Future<bool> createPartner({required Map<String, dynamic> data}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitFieldErrors = null;
    notifyListeners();

    try {
      await repository.createPartner(data: data);
      _isSubmitting = false;
      notifyListeners();
      await refresh();
      return true;
    } on ApiException catch (e) {
      logger.e('createPartner ApiException', error: e);
      _submitError = e.message;
      _submitFieldErrors = e.fieldErrors;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      logger.e('createPartner failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete Partner ─────────────────────────────────────
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

  // ── Update Partner ────────────────────────────────────
  Future<bool> updatePartner({required Map<String, dynamic> data}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitFieldErrors = null;
    notifyListeners();

    try {
      await repository.updatePartner(data: data);
      _isSubmitting = false;
      notifyListeners();
      await refresh();
      return true;
    } on ApiException catch (e) {
      logger.e('updatePartner ApiException', error: e);
      _submitError = e.message;
      _submitFieldErrors = e.fieldErrors;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      logger.e('updatePartner failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
