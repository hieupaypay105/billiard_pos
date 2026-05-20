import 'package:anholding_app/src/core/error/api_exception.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/contact_item.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_filter.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:anholding_app/src/features/khach_hang/domain/repositories/khach_hang_repository.dart';
import 'package:flutter/foundation.dart';

export 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_filter.dart';

class KhachHangProvider extends ChangeNotifier {
  KhachHangProvider({required this.repository}) {
    refresh();
    loadOptions();
  }

  final KhachHangRepository repository;

  // ── Column config ─────────────────────────────────────
  static const List<String> columnOrder = [
    'id',
    'projectId',
    'sourceId',
    'name',
    'regionLabel',
    'phone',
    'status',
    'financialRange',
    'saleId',
  ];

  static const Map<String, String> columnLabels = {
    'id': 'STT',
    'projectId': 'Dự Án',
    'sourceId': 'Nguồn',
    'name': 'Tên',
    'regionLabel': 'Tỉnh/Thành',
    'phone': 'Điện thoại',
    'status': 'Tình trạng',
    'financialRange': 'Tài chính',
    'saleId': 'Sale',
  };

  // ── State ─────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;

  bool _isSubmitting = false;
  String? _submitError;
  Map<String, List<String>>? _submitFieldErrors;
  bool _isLoadingOptions = false;
  String? _optionsError;

  // Project-dependent filter options (loaded via /data/option)
  Map<String, List<String>> _projectFilterOptions = {};
  bool _isLoadingProjectOptions = false;
  int? _selectedProjectId;

  String? _sortColumnKey;
  bool _sortAscending = true;

  // ── Contacts (Trao đổi) ────────────────────────────────
  List<ContactItem> _contacts = const [];
  bool _isLoadingContacts = false;
  String? _contactsError;

  KhachHangFilter _filter = const KhachHangFilter();
  KhachHangOptionResponse? _options;
  List<KhachHangItem> _allItems = const [];

  // Pagination & Lazy Loading
  int _nextPage = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Status counts from data_status
  Map<int, int> _dataStatus = const {};

  final Map<String, bool> _visibleColumns = {
    for (final key in columnOrder) key: true,
  };

  // ── Getters ───────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get sortColumnKey => _sortColumnKey;
  bool get sortAscending => _sortAscending;
  KhachHangFilter get filter => _filter;
  Map<String, bool> get visibleColumns => Map.unmodifiable(_visibleColumns);

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  Map<String, List<String>>? get submitFieldErrors => _submitFieldErrors;
  bool get isLoadingOptions => _isLoadingOptions;
  String? get optionsError => _optionsError;
  KhachHangOptionResponse? get options => _options;
  bool get isLoadingProjectOptions => _isLoadingProjectOptions;
  int? get selectedProjectId => _selectedProjectId;

  // ── Contacts getters ──────────────────────────────────
  List<ContactItem> get contacts => _contacts;
  bool get isLoadingContacts => _isLoadingContacts;
  String? get contactsError => _contactsError;

  /// Returns the list of options for the given filter [type]
  /// loaded from /data/option based on selected project.
  List<String> getProjectOptions(String type) =>
      _projectFilterOptions[type] ?? [];

  int get total => _total;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// Status index → count, e.g. {0: 338, 1: 554, ...}
  Map<int, int> get dataStatus => _dataStatus;

  List<KhachHangItem> get items {
    final list = List<KhachHangItem>.from(_allItems);
    _applySort(list);
    return list;
  }

  String projectLabel(String? projectId) =>
      _resolveMapLabel(_options?.project, projectId);

  String sourceLabel(String? sourceId) =>
      _resolveMapLabel(_options?.source, sourceId);

  String saleLabel(List<String> saleIds) {
    if (saleIds.isEmpty) return '';
    return saleIds.join(', ');
  }

  String statusLabel(String status) {
    final index = int.tryParse(status);
    final options = _options?.status;
    if (index != null &&
        options != null &&
        index >= 0 &&
        index < options.length) {
      return options[index];
    }
    return status;
  }

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

  // ── Contact list (Trao đổi) ───────────────────────────
  Future<void> loadContacts(String customerId) async {
    if (_isLoadingContacts) return;

    _isLoadingContacts = true;
    _contactsError = null;
    notifyListeners();

    try {
      if (_options == null && !_isLoadingOptions) {
        await loadOptions();
      }

      _contacts = await repository.getListContact(customerId: customerId);
    } on Exception catch (e) {
      logger.e('loadContacts failed', error: e);
      _contactsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  /// Resolves a user_id to a display name using the sale options map.
  String contactUserName(String userId) {
    final id = int.tryParse(userId);
    if (id == null) return userId;
    return _options?.sale[id] ?? userId;
  }

  /// Creates a new contact/exchange for a customer.
  /// Returns true on success, false on failure.
  Future<bool> createContact({
    required String customerId,
    required String comment,
  }) async {
    try {
      await repository.createContact(
        customerId: customerId,
        comment: comment,
      );
      // Reload contacts to show the new one
      await loadContacts(customerId);
      return true;
    } on Exception catch (e) {
      _contactsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Deletes a contact by its ID and reloads the list.
  /// Returns the success message from API, or null on failure.
  Future<String?> deleteContact({
    required String contactId,
    required String customerId,
  }) async {
    try {
      final msg = await repository.deleteContact(contactId: contactId);
      await loadContacts(customerId);
      return msg;
    } on Exception catch (e) {
      _contactsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Project-dependent filter options ──────────────────
  static const _optionTypes = ['area', 'type', 'direction', 'handover_status'];

  /// Called when user selects a project in the form.
  /// Triggers loading of dependent filter options.
  void setSelectedProject(int projectId) {
    if (_selectedProjectId == projectId) return;
    _selectedProjectId = projectId;
    _projectFilterOptions = {};
    notifyListeners();
    loadProjectFilterOptions();
  }

  /// Fetches all filter option lists in parallel for the selected project.
  /// Same pattern as BangHangProvider.loadFilterOptions().
  Future<void> loadProjectFilterOptions() async {
    final projectId = _selectedProjectId;
    if (projectId == null) return;

    _isLoadingProjectOptions = true;
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

      _projectFilterOptions = {
        for (var i = 0; i < _optionTypes.length; i++)
          _optionTypes[i]: results[i],
      };
    } on Exception catch (e) {
      logger.e('loadProjectFilterOptions failed', error: e);
      // Keep previous options on error (or empty on first load).
    } finally {
      _isLoadingProjectOptions = false;
      notifyListeners();
    }
  }

  // ── Data loading ──────────────────────────────────────
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    _nextPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _allItems = const []; // clear stale data immediately
    notifyListeners();

    try {
      final filterWithPagination = _filter.copyWith(page: _nextPage);
      final response = await repository.getItems(filter: filterWithPagination);

      _allItems = response.items;
      _total = response.pagination.total;
      _dataStatus = response.dataStatus;

      _hasMore = response.pagination.currentPage < response.pagination.lastPage;
      if (_hasMore) {
        _nextPage++;
      }
    } on Exception catch (_) {
      _errorMessage = 'Không có dữ liệu hiển thị';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final filterWithPagination = _filter.copyWith(page: _nextPage);
      final response = await repository.getItems(filter: filterWithPagination);

      if (response.items.isNotEmpty) {
        _allItems.addAll(response.items);
      }

      _hasMore = response.pagination.currentPage < response.pagination.lastPage;
      if (_hasMore) {
        _nextPage++;
      }
    } on Exception catch (_) {
      // If error occurs while loading more, we just stop loading more
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
  Future<void> applyFilter(KhachHangFilter filter) async {
    _filter = filter;
    await refresh();
  }

  Future<void> clearFilter() async {
    _filter = const KhachHangFilter();
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

  // ── Create Customer ────────────────────────────────────
  Future<bool> createCustomer({required Map<String, dynamic> data}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitFieldErrors = null;
    notifyListeners();

    try {
      await repository.createCustomer(data: data);
      _isSubmitting = false;
      notifyListeners();
      await refresh();
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      _submitFieldErrors = e.fieldErrors;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      logger.e('createCustomer failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete Customer ─────────────────────────────────────
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

  // ── Update Customer ────────────────────────────────────
  Future<bool> updateCustomer({required Map<String, dynamic> data}) async {
    _isSubmitting = true;
    _submitError = null;
    _submitFieldErrors = null;
    notifyListeners();

    try {
      await repository.updateCustomer(data: data);
      _isSubmitting = false;
      notifyListeners();
      await refresh();
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      _submitFieldErrors = e.fieldErrors;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      logger.e('updateCustomer failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Save Filter ────────────────────────────────────────
  Future<bool> saveFilter({
    required String name,
    required Map<String, dynamic> data,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await repository.saveFilter(name: name, data: data);
      _isSubmitting = false;
      notifyListeners();
      await loadOptions(force: true);
      return true;
    } catch (e) {
      logger.e('saveFilter failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Set Default Filter ────────────────────────────────
  Future<bool> setDefaultFilter({
    required String id,
    required int isDefault,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await repository.setDefaultFilter(id: id, isDefault: isDefault);
      _isSubmitting = false;
      notifyListeners();
      await loadOptions(force: true);
      return true;
    } catch (e) {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete Filter ──────────────────────────────────────
  Future<bool> deleteFilter({required String id}) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await repository.deleteFilter(id: id);
      _isSubmitting = false;
      notifyListeners();
      await loadOptions(force: true);
      return true;
    } catch (e) {
      logger.e('deleteFilter failed', error: e);
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Sort helpers ──────────────────────────────────────
  void _applySort(List<KhachHangItem> data) {
    final key = _sortColumnKey;
    if (key == null) return;

    int compareString(String a, String b) => a.compareTo(b);

    int resultFor(KhachHangItem left, KhachHangItem right) {
      return switch (key) {
        'name' => compareString(left.name, right.name),
        'phone' => compareString(left.phone ?? '', right.phone ?? ''),
        'status' => compareString(
          left.statusLabel.join(', '),
          right.statusLabel.join(', '),
        ),
        'createdAt' => compareString(left.createdAt, right.createdAt),
        'saleId' => compareString(
          saleLabel(left.saleId),
          saleLabel(right.saleId),
        ),
        'projectId' => compareString(
          left.projectLabel ?? '',
          right.projectLabel ?? '',
        ),
        'sourceId' => compareString(
          left.sourceLabel ?? '',
          right.sourceLabel ?? '',
        ),
        'regionLabel' => compareString(
          left.regionLabel ?? '',
          right.regionLabel ?? '',
        ),
        'financialRange' => compareString(
          left.financialRangeLabel ?? '',
          right.financialRangeLabel ?? '',
        ),
        'email' => compareString(left.email ?? '', right.email ?? ''),
        'lastContact' => compareString(
          left.lastContact ?? '',
          right.lastContact ?? '',
        ),
        _ => 0,
      };
    }

    data.sort((left, right) {
      final result = resultFor(left, right);
      return _sortAscending ? result : -result;
    });
  }

  String _resolveMapLabel(Map<int, String>? values, String? rawId) {
    final id = int.tryParse(rawId ?? '');
    if (id == null) return rawId ?? '';
    return values?[id] ?? rawId ?? '';
  }
}
