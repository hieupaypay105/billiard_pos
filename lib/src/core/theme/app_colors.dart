import 'package:flutter/material.dart';

/// Design token colors extracted from Figma auth flow screens.
sealed class AppColors {
  // ─── Brand ───────────────────────────────────────────────
  static const Color primaryGold = Color(0xFFB58C5F);
  static const Color darkBackground = Color(0xFF080807);
  static const Color darkBackground2 = Color(0xFF2F2A29);

  // ─── Scaffolds / Gradients ───────────────────────────────
  static const Color featureScaffoldStart = Color(0xFFE4DED1);
  static const Color featureScaffoldEnd = Color(0xFF756F61);
  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF322F36), // var(--bg1) start
      Color(0xFF1A1A18), // var(--bg1) end
    ],
  );

  // ─── Card / Surface ──────────────────────────────────────
  /// Semi-transparent cream used for bottom card overlays.
  static const Color cardBackground = Color(0xB3FCFAF4); // 70 % opacity
  /// Solid background for bottom card overlays.
  static const Color cardBackgroundSolid = Color(0xFFECECEC);

  // ─── Text ────────────────────────────────────────────────
  static const Color textDark = Color(0xFF363636);
  static const Color textHint = Color(0xFF909090);
  static const Color textSubtle = Color(0xFF7E7E7E);
  static const Color textSecondary = Color(0xFF2F2A29);

  // ─── Input / Border ──────────────────────────────────────
  static const Color borderActive = Color(0xFFB58C5F);
  static const Color borderInactive = Color(0xFFD9D9D9);

  /// Phone input field background (5 % white).
  static const Color inputBackground = Color(0x0DD9D9D9);

  /// Dark input background for forms on dark theme.
  static const Color inputBackgroundDark = Color(0x33FAF2EF);

  /// Button background for dark theme.
  static const Color buttonBgDark = Color(0xFF302D33);

  // ─── Refactored Auth Buttons ──────────────────────────────
  static const Color buttonGradientStart = Color(0xFF2F2A29);
  static const Color buttonGradientEnd = Color(0xFF635A55);
  static const Color buttonBorder = Color(0xFFFFF4E2);
  static const Color buttonText = Color(0xFFBBC4CB);

  // ─── NEW Auth Flow ────────────────────────────────────────
  static const Color authCardBackground = Color(
    0x991A1614,
  ); // rgba(26,22,20,0.6)
  static const Color authTextLight = Color(0xFFEBE0DC);
  static const Color authTextMuted = Color(0xB3645E5A); // 70% opacity
  static const Color authTextSecondary = Color(0xFFB9B0AC);
  static const Color authTextDisabled = Color(0xFF665D58);
  static const Color authButtonBackground = Color(0xFF38312E);
  static const Color authButtonBorder = Color(0xFFFFDBB0);
  static const Color authButtonText = Color(0xFFFEDBAF);
  static const Color authInputBorder = Color(0x33B9B0AC); // 20% opacity
  static const Color pinBoxBorderInactive = Color(0x80B9B0AC); // 50% opacity
  static const Color authOutlinedButtonBorder = Color(
    0x80FFF6F2,
  ); // 50% opacity

  // ─── Table ──────────────────────────────────────────────
  static const Color tableHeaderBg = Color(0xFF625954);
  static const Color tableHeaderBgNew = Color(0xFFFFF9D0);
  static const Color tableRowEven = Color(0xFFFFFFFF);
  static const Color tableRowOdd = Color(0xFFF9F9F9);
  static const Color tableBorder = Color(0xFFE0E0E0);
  static const Color tableActionEdit = Color(0xFF4CAF50);
  static const Color tableActionDelete = Color(0xFFE57373);

  // ─── Dashboard Dark Theme ──────────────────────────────
  static const Color dashboardBgStart = Color(0xFF322F36);
  static const Color dashboardBgEnd = Color(0xFF1A1A18);
  static const Color topBarBackground = Color(0xFF37343B);
  static const Color topBarBlurBackground = Color(0xCC37343B); // 80% opacity
  static const Color dashboardCardBorder = Color(0xFF3F3F3F);
  static const Color dashboardCardStart = Color(0xFF242426);
  static const Color dashboardCardEnd = Color(0xFF3B3537);
  static const Color tableCardBorder = authButtonBorder;
  static const Color notifTimestampColor = Color(0xFF817975);
  static const Color notifBodyColor = Color(0xFF645E5A);

  // ─── Bảng Hàng Refactor ────────────────────────────────
  static const Color statusGreen = Color(0xFF10B981);
  static const Color badgeBlue = Color(0xFF4D8DF2);
  static const Color filterBg = Color(0xFF2D2B47);
  static const Color inputFillLight = Color(
    0x33FAF2EF,
  ); // rgba(250,242,239,0.2)
  static const Color filterButtonBg = Color(0xFF38312E);
  static const Color inputBorderLight = Color(
    0x4DB9B0AC,
  ); // rgba(185,176,172,0.3)

  // ─── Khách Hàng Refactor ────────────────────────────────
  static const Color khScreenBg = Color(0xFF1F1E1C);
  static const Color titleUnderline = Color(0xFF665D58);
  static const Color titleGradientStart = Color(0xFFFFDBB0);
  static const Color titleGradientMiddle = Color(0xFF9C531B);
  static const Color searchLabel = Color(0xFF645E5A);
  static const Color searchIconHint = Color(0x99B9B0AC);
  static const Color searchBg = Color(0x4D7A7A7A); // rgba(122,122,122,0.3)
  static const Color cardGradientStart = Color(0xFF242426);
  static const Color cardGradientEnd = Color(0xFF3B3537);
  static const Color cardTagBorder = Color(0xFF454545);
  static const Color cardActionBg = Color(0xFF383636);
  static const Color filterDropdownActive = Color(0xFF545153);
  static const Color filterDropdownPanel = Color(0xFF383735);
  static const Color filterDropdownChecked = Color(0x66FAF2EF);

  // ─── Dialog ──────────────────────────────────────────
  static const Color dialogIconBg = Color(0x1AFAF2EF); // rgba(250,242,239,0.1)
  static const Color dialogSecondaryBtnBg = Color(
    0x33FAF2EF,
  ); // rgba(250,242,239,0.2)

  static const List<Color> khStatusColors = [
    Color(0xFFD55118), // 0 - Mới
    Color(0xFF1065B9), // 1 - Đang tiếp cận
    Color(0xFF208CFF), // 2 - Đang tư vấn
    Color(0xFFB91046), // 3 - Tiềm năng
    Color(0xFF10B981), // 4 - Đang hẹn gặp
    Color(0xFF7B10B9), // 5 - Đã hẹn / Đã gặp
    Color(0xFFA9A9A9), // 6 - Nghiên cứu tiếp/Chờ
    Color(0xFFDD00C0), // 7 - Nóng
    Color(0xFFFF4920), // 8 - Chốt
    Color(0xFFFF2079), // 9 - Mua tiếp
    Color(0xFF6A6A6A), // 10 - Dừng mua
    Color(0xFF838383), // 11 - Mua bên khác
    Color(0xFFBBD300), // 12 - Mua dự án khác
  ];
}
