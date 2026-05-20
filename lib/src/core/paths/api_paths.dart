import 'package:anholding_app/src/core/constants/env.dart' show Env;

/// Centralized API endpoint path constants.
///
/// Import this file wherever API paths are needed
/// to avoid hardcoded strings.
///
/// Note: Base URL is loaded from `.env` via [Env.apiBaseUrl].
/// These are relative paths appended to the base URL.
sealed class ApiPaths {
  // ── Auth ───────────────────────────────────────────────
  static const authLogin = '/auth/login';
  static const authRefreshToken = '/user/refresh';

  // ── User ───────────────────────────────────────────────
  static const userInfo = '/user/info';

  // ── BangHang ──────────────────────────────────────────
  static const bangHangList = '/data/list';
  static const bangHangOption = '/data/option';
  static const bangHangField = '/data/field';

  // ── CongTacVien ────────────────────────────────────────
  static const congTacVienList = '/partner/list';
  static const congTacVienOption = '/partner/option';
  static const congTacVienDelete = '/partner/delete';
  static const partnerGenCode = '/partner/gencode';
  static const partnerCreate = '/partner/create';
  static const partnerUpdate = '/partner/update';

  // ── QuanTri ───────────────────────────────────────────
  static const quanTriList = '';
  static const quanTriCreate = '';
  static const quanTriUpdate = '';
  static const quanTriDelete = '';

  // ── DuAn ──────────────────────────────────────────────
  static const duAnList = '/project/list';
  static const duAnDelete = '/project/delete';
  static const duAnCreate = '/project/create';
  static const duAnUpdate = '/project/update';

  // ── KhachHang ──────────────────────────────────────────
  static const khachHangList = '/customer/list';
  static const khachHangDelete = '/customer/delete';
  static const khachHangCreate = '/customer/create';
  static const khachHangUpdate = '/customer/update';
  static const khachHangOption = '/customer/option';
  static const khachHangListContact = '/customer/listContact';
  static const khachHangCreateContact = '/customer/createContact';
  static const khachHangDeleteContact = '/customer/deletecontact';
  static const khachHangSaveFilter = '/customer/saveFilter';
  static const khachHangSetDefaultFilter = '/customer/setDefaultFilter';
  static const khachHangDeleteFilter = '/customer/deletefilter';

  // ── Notification ───────────────────────────────────────
  static const notificationFcmToken = '/notification/fcmToken';
  static const notificationList = '/notification/list';
  static const notificationRead = '/notification/read';

  // ── Dashboard ──────────────────────────────────────────
  static const dashboard = '/dashboard';

  // ── AI Assistant ───────────────────────────────────────
  static const aiChat = '/ai/chat';
  static const aiSearch = '/ai/search';
  static const aiQuota = '/ai/quota';
}
