import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_filter.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:anholding_app/src/features/bang_hang/domain/repositories/bang_hang_repository.dart';
import 'package:flutter/foundation.dart';

export 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_filter.dart';

class BangHangProvider extends ChangeNotifier {
  BangHangProvider({required this.repository}) {
    _init();
  }

  Future<void> _init() async {
    await loadColumnConfig();
    refresh();
    loadFilterOptions();
  }

  final BangHangRepository repository;

  // ── Tabs ──────────────────────────────────────────────
  static const List<BangHangTab> tabs = [
    BangHangTab(id: 'quy_moi_vin_2', label: 'Quỹ mới Vin 2', projectId: 2),
    BangHangTab(id: 'quy_moi_vin_3', label: 'Quỹ mới Vin 3', projectId: 3),
    BangHangTab(
      id: 'chuyen_nhuong_vin_2',
      label: 'Chuyển nhượng Vin 2',
      projectId: 18,
    ),
    BangHangTab(
      id: 'chuyen_nhuong_vin_3',
      label: 'Chuyển nhượng Vin 3',
      projectId: 19,
    ),
  ];

  // ── Column config ─────────────────────────────────────
  List<String> columnOrder = [];
  Map<String, String> columnLabels = {};
  // ── State ─────────────────────────────────────────────
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  String? _sortColumnKey;
  bool _sortAscending = true;

  BangHangFilter _filter = const BangHangFilter();
  List<BangHangItem> _allItems = const [];
  List<BangHangItem>? _sortedCache;
  String? _highlightedItemCode;

  // Pagination (Lazy Scroll)
  int _nextPage = 1;
  int _total = 0;
  int _perPage = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Filter options are project-scoped and follow the currently active tab.
  Map<String, List<String>> _filterOptions = {};
  bool _isLoadingOptions = false;

  Map<String, bool> _visibleColumns = {};

  // ── Getters ───────────────────────────────────────────
  int get selectedTabIndex => _selectedTabIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get sortColumnKey => _sortColumnKey;
  bool get sortAscending => _sortAscending;
  BangHangFilter get filter => _filter;
  Map<String, bool> get visibleColumns => Map.unmodifiable(_visibleColumns);
  String? get highlightedItemCode => _highlightedItemCode;

  int get total => _total;
  int get perPage => _perPage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool get isLoadingOptions => _isLoadingOptions;

  List<String> getOptions(String type) => _filterOptions[type] ?? [];

  String get selectedTabId => tabs[_selectedTabIndex].id;
  int get selectedProjectId => tabs[_selectedTabIndex].projectId;

  /// Returns sorted items, using cache to avoid re-sorting every rebuild.
  List<BangHangItem> get items {
    _sortedCache ??= _buildSortedList();
    return _sortedCache!;
  }

  // ── Data loading ──────────────────────────────────────
  // ── Data loading (Lazy Scroll) ────────────────────────
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    _nextPage = 1;
    _hasMore = true;
    _allItems = [];
    _sortedCache = null;
    _highlightedItemCode = null;
    notifyListeners();

    try {
      final filterWithPagination = _filter.copyWith(
        projectId: selectedProjectId,
        page: _nextPage,
        perPage: _perPage,
      );

      final response = await repository.getItems(filter: filterWithPagination);
      _allItems = response.items;
      _total = response.pagination.total;
      _perPage = response.pagination.perPage;
      _sortedCache = null; // Fix: clear cache after assigning new items

      if (_allItems.length >= _total) {
        _hasMore = false;
      } else {
        _nextPage++;
      }
    } on Exception catch (e) {
      logger.e('refresh bang hang failed', error: e);
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
        projectId: selectedProjectId,
        page: _nextPage,
        perPage: _perPage,
      );

      final response = await repository.getItems(filter: filterWithPagination);
      _allItems.addAll(response.items);
      _total = response.pagination.total;
      _sortedCache = null;

      if (_allItems.length >= _total || response.items.isEmpty) {
        _hasMore = false;
      } else {
        _nextPage++;
      }
    } on Exception catch (e) {
      logger.e('loadMore bang hang failed', error: e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Filter options loading ────────────────────────────
  static const _optionTypes = ['area', 'type', 'direction', 'handover_status'];

  Future<void> loadFilterOptions() async {
    final projectId = selectedProjectId;
    _filterOptions = {};
    _isLoadingOptions = true;
    notifyListeners();

    try {
      final results = await Future.wait(
        _optionTypes.map(
          (t) => repository.getFilterOptions(
            projectId: projectId,
            type: t,
          ),
        ),
      );

      _filterOptions = {
        for (var i = 0; i < _optionTypes.length; i++)
          _optionTypes[i]: results[i],
      };
    } on Exception catch (e) {
      logger.e('loadFilterOptions failed', error: e);
      // Keep previous options on error.
    } finally {
      _isLoadingOptions = false;
      notifyListeners();
    }
  }

  // ── Tab switching ─────────────────────────────────────
  Future<void> setTab(int index) async {
    if (index == _selectedTabIndex || index < 0 || index >= tabs.length) return;
    _selectedTabIndex = index;
    _filter = const BangHangFilter();
    _sortedCache = null;
    _highlightedItemCode = null;
    _filterOptions = {};
    notifyListeners();
    await loadColumnConfig();
    await Future.wait([refresh(), loadFilterOptions()]);
  }

  // ── Column config loading ─────────────────────────────
  Future<void> loadColumnConfig() async {
    try {
      final config = await repository.getColumnConfigs(projectId: selectedProjectId);
      columnLabels = config;
      columnOrder = config.keys.toList();
      _visibleColumns = {
        for (final key in columnOrder) key: true,
      };
      notifyListeners();
    } on Exception catch (e) {
      logger.e('loadColumnConfig failed', error: e);
      // Fallback
      if (columnOrder.isEmpty) {
        columnOrder = ['id', 'area', 'code', 'type', 'price'];
        columnLabels = {
          'id': 'STT',
          'area': 'PHÂN KHU',
          'code': 'MÃ CĂN',
          'type': 'LOẠI HÌNH',
          'price': 'GIÁ FULL',
        };
        _visibleColumns = {
          for (final key in columnOrder) key: true,
        };
        notifyListeners();
      }
    }
  }

  // ── Sorting (client-side) ──────────────────────────────
  void sort(String columnKey, {required bool ascending}) {
    _sortColumnKey = columnKey;
    _sortAscending = ascending;
    _sortedCache = null;
    notifyListeners();
  }

  // ── Filtering (server-side) ────────────────────────────
  Future<void> applyFilter(BangHangFilter filter) async {
    _filter = filter;
    await refresh();
  }

  Future<void> clearFilter() async {
    _filter = const BangHangFilter();
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

  bool get allColumnsSelected => _visibleColumns.values.every((v) => v);

  bool isColumnVisible(String key) => _visibleColumns[key] ?? false;

  void setHighlightedItemCode(String? code) {
    if (_highlightedItemCode == code) return;
    _highlightedItemCode = code;
    notifyListeners();
  }

  // ── Sort helpers ──────────────────────────────────────
  List<BangHangItem> _buildSortedList() {
    final list = List<BangHangItem>.from(_allItems);
    final key = _sortColumnKey;
    if (key == null) return list;

    int compareNumeric(String a, String b) =>
        _toNumber(a).compareTo(_toNumber(b));

    list.sort((left, right) {
      final result = switch (key) {
        'land_size' => compareNumeric(
          left.landSize ?? '0',
          right.landSize ?? '0',
        ),
        'construction_area' => compareNumeric(
          left.constructionArea,
          right.constructionArea,
        ),
        'price' => compareNumeric(left.price, right.price),
        'tts' => compareNumeric(left.tts, right.tts),
        _ => 0,
      };
      return _sortAscending ? result : -result;
    });

    return list;
  }

  double _toNumber(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
}
