import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';

/// Mô hình dữ liệu cho một mục trong QuickMenu
class MenuItem {
  const MenuItem({
    required this.id,
    required this.iconPath,
    required this.label,
    this.route,
    this.enabled = true,
  });

  /// Khoá duy nhất (vd: 'du_an', 'bang_hang')
  final String id;

  /// Đường dẫn SVG asset (vd: AppIcons.duAn)
  final String iconPath;

  /// Nhãn hiển thị tiếng Việt
  final String label;

  /// Đường dẫn GoRouter hoặc null
  final String? route;

  /// Trạng thái khả dụng của menu
  final bool enabled;
}

// ── Mảng A — Danh mục đầy đủ tất cả menu ────────────────────────────────────

const List<MenuItem> allMenuItems = [
  MenuItem(
    id: 'du_an',
    iconPath: AppIcons.duAn,
    label: 'Dự án',
    route: RoutePaths.duAn,
    enabled: false,
  ),
  MenuItem(
    id: 'bang_hang',
    iconPath: AppIcons.bangHang,
    label: 'Bảng hàng',
    route: RoutePaths.bangHang,
  ),
  MenuItem(
    id: 'ctv',
    iconPath: AppIcons.ctv,
    label: 'CTV',
    route: RoutePaths.congTacVien,
  ),
  MenuItem(
    id: 'khach_hang',
    iconPath: AppIcons.khachHang,
    label: 'Khách hàng',
    route: RoutePaths.khachHang,
  ),
  MenuItem(
    id: 'quan_tri',
    iconPath: AppIcons.quanTri,
    label: 'Quản trị',
    route: RoutePaths.quanTri,
    enabled: false,
  ),
  // MenuItem(
  //   id: 'cham_cong',
  //   iconPath: AppIcons.chamCong,
  //   label: 'Chấm công',
  //   enabled: false,
  // ),
];

// ── Mảng B mặc định — 5 menu hiển thị ban đầu ───────────────────────────────

const List<String> defaultActiveMenuIds = [
  'du_an',
  'bang_hang',
  'ctv',
  'khach_hang',
  'quan_tri',
];
