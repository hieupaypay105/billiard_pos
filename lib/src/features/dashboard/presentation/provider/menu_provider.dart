import 'dart:convert';

import 'package:anholding_app/src/features/dashboard/data/models/menu_item.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý danh sách menu đã chọn (mảng B).
///
/// Load từ SharedPreferences khi khởi tạo.
/// Nếu chưa có dữ liệu thì dùng [defaultActiveMenuIds].
class MenuProvider extends ChangeNotifier {
  MenuProvider() {
    _loadFromPrefs();
  }

  static const _key = 'active_menu_ids';

  /// Danh sách ID menu đang hiển thị (mảng B)
  List<String> _activeIds = List.from(defaultActiveMenuIds);
  List<String> get activeIds => List.unmodifiable(_activeIds);

  /// Bản sao tạm khi chỉnh sửa (dùng trong EditMenuSheet)
  List<String> _editingIds = [];
  List<String> get editingIds => List.unmodifiable(_editingIds);

  /// Lấy danh sách MenuItem tương ứng với mảng B hiện tại
  List<MenuItem> get activeMenuItems {
    return _activeIds
        .map(
          (id) => allMenuItems.cast<MenuItem?>().firstWhere(
            (m) => m?.id == id,
            orElse: () => null,
          ),
        )
        .whereType<MenuItem>()
        .toList();
  }

  // ── Editing Flow ──────────────────────────────────────────

  /// Bắt đầu chỉnh sửa: copy mảng B hiện tại sang bản nháp
  void startEditing() {
    _editingIds = List.from(_activeIds);
    notifyListeners();
  }

  /// Kiểm tra ID có trong bản nháp hay không
  bool isInEditing(String id) => _editingIds.contains(id);

  /// Thêm menu vào bản nháp
  void addToEditing(String id) {
    if (!_editingIds.contains(id)) {
      _editingIds.add(id);
      notifyListeners();
    }
  }

  /// Xoá menu khỏi bản nháp
  void removeFromEditing(String id) {
    _editingIds.remove(id);
    notifyListeners();
  }

  /// Lưu bản nháp → cập nhật mảng B chính thức + persist
  Future<void> saveEditing() async {
    _activeIds = List.from(_editingIds);
    notifyListeners();
    await _saveToPrefs();
  }

  // ── Persistence ───────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      final decoded = (jsonDecode(stored) as List).cast<String>();
      if (decoded.isNotEmpty) {
        _activeIds = decoded;
        notifyListeners();
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_activeIds));
  }
}
