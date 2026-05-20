/// Centralized route path constants.
///
/// Import this file wherever navigation paths are needed
/// to avoid hardcoded strings.
sealed class RoutePaths {
  // ── Splash ─────────────────────────────────────────────
  static const splash = '/';

  // ── Auth flow — phone-based ────────────────────────────
  static const phoneLogin = '/phone-login';
  static const otpVerification = '/otp-verification';
  static const setupPin = '/setup-pin';
  static const confirmPin = '/confirm-pin';

  // ── Returning user (PIN login) ─────────────────────────
  static const pinLogin = '/pin-login';

  // ── Post-auth ──────────────────────────────────────────
  static const dashboard = '/dashboard';
  static const account = '/account';
  static const ai = '/ai';
  static const notification = '/notification';
  static const bangHang = '/bang-hang';
  static const bangHangDetail = '/bang-hang/detail';
  static const bangHangFilter = '/bang-hang/filter';
  static const bangHangColumnSettings = '/bang-hang/column-settings';
  static const congTacVien = '/cong-tac-vien';
  static const congTacVienFilter = '/cong-tac-vien/filter';
  static const congTacVienColumnSettings = '/cong-tac-vien/column-settings';
  static const congTacVienAdd = '/cong-tac-vien/add';
  static const congTacVienEdit = '/cong-tac-vien/edit';
  static const khachHang = '/khach-hang';
  static const khachHangFilter = '/khach-hang/filter';
  static const khachHangColumnSettings = '/khach-hang/column-settings';
  static const khachHangAdd = '/khach-hang/add';
  static const khachHangEdit = '/khach-hang/edit';
  static const khachHangDetail = '/khach-hang/detail';
  static const khachHangTraoDoi = '/khach-hang/trao-doi';
  static const duAn = '/du-an';
  static const duAnFilter = '/du-an/filter';
  static const duAnColumnSettings = '/du-an/column-settings';
  static const duAnAdd = '/du-an/add';
  static const duAnEdit = '/du-an/edit';
  static const quanTri = '/quan-tri';
  static const quanTriFilter = '/quan-tri/filter';
  static const quanTriColumnSettings = '/quan-tri/column-settings';
  static const quanTriAdd = '/quan-tri/add';
  static const quanTriEdit = '/quan-tri/edit';

  // ── AI Assistant ───────────────────────────────────────
  static const aiAssistant = '/ai-assistant';
}
