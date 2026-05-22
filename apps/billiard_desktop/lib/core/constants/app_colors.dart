import 'package:flutter/material.dart';

/// Bảng màu chính của Billiard POS – Scandinavian Minimalism
class AppColors {
  AppColors._();

  // --- Primary Brand ---
  static const Color primary = Color(0xFF2E4F4F);
  static const Color primaryLight = Color(0xFF3D6666);
  static const Color primaryDark = Color(0xFF1E3535);
  static const Color primarySurface = Color(0xFFEDF5F5);

  // --- Accent / Highlight ---
  static const Color accent = Color(0xFFE28743);
  static const Color accentLight = Color(0xFFFAEDD8);

  // --- Background ---
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFECEFF1);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // --- Text ---
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Colors.white;

  // --- Table Status Colors ---
  static const Color tableIdle = Color(0xFFF5F5F5);
  static const Color tableActive = Color(0xFFE2ECF7);
  static const Color tableActiveAccent = Color(0xFF1E3A8A);
  static const Color tableBooked = Color(0xFFFEF9C3);
  static const Color tableBookedAccent = Color(0xFFCA8A04);
  static const Color tableMaintenance = Color(0xFFFDE8E8);
  static const Color tableMaintenanceAccent = Color(0xFF9B1C1C);

  // --- Status / Semantic Colors ---
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // --- Navigation Rail ---
  static const Color navRailBg = Color(0xFF1A3333);
  static const Color navRailSelected = Color(0xFF2E4F4F);
  static const Color navRailIndicator = Color(0xFF3D6666);

  // --- Border ---
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // --- Payment Methods ---
  static const Color cash = Color(0xFF16A34A);
  static const Color card = Color(0xFF2563EB);
  static const Color transfer = Color(0xFF7C3AED);

  // --- Sync Status ---
  static const Color online = Color(0xFF16A34A);
  static const Color offline = Color(0xFFDC2626);
  static const Color syncing = Color(0xFFD97706);
}
