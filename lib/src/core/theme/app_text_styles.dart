import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Typography presets derived from the Figma auth screens.
///
/// All styles use the **Inter** font family via `google_fonts`.
sealed class AppTextStyles {
  // ─── Titles ──────────────────────────────────────────────

  /// Screen title — white, 16 sp, uppercase, regular.
  /// e.g. "XÁC THỰC", "THIẾT LẬP THÔNG TIN"
  static TextStyle screenTitle = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    letterSpacing: 1,
  );

  /// Card heading — dark, 14 sp, regular.
  /// e.g. "Thiết lập mã PIN", "Mã OTP đã được gửi đến"
  static TextStyle cardTitle = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  /// Bold phone number / user name — dark, 20 sp.
  static TextStyle phoneBold = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  // ─── Body ────────────────────────────────────────────────

  /// Regular body text — dark, 14 sp.
  static TextStyle body = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  /// Subtle body text — grey, 14 sp (white variant for dark bg).
  static TextStyle bodyWhite = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  /// Slogan / subtitle — subtle grey, 12 sp, uppercase.
  static TextStyle slogan = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.buttonText, // #BBC4CB
    letterSpacing: 0.5,
  );

  // ─── Buttons ─────────────────────────────────────────────

  /// Primary button label — dark, 14 sp, bold.
  static TextStyle buttonLabel = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  // ─── Links ───────────────────────────────────────────────

  /// Gold link text — 14 sp, bold.
  static TextStyle link = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryGold,
  );

  // ─── Input ───────────────────────────────────────────────

  /// Input hint — grey, 16 sp.
  static TextStyle inputHint = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  /// Input value — white, 16 sp.
  static TextStyle inputValue = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  /// User name in the returning-user card — semi-bold, 14 sp, dark.
  static TextStyle userName = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  /// White small text — 12 sp for "Đổi tài khoản" etc.
  static TextStyle smallWhite = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  /// Secondary text — 16 sp, bold.
  static TextStyle secondary = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  // ─── NEW Auth Flow ───────────────────────────────────────

  /// Screen titles in new Auth Flow.
  static TextStyle authScreenTitle = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w300, // Light
    color: Color(0xFFDBD1CD),
    letterSpacing: 1,
  );

  /// Label for form fields in auth.
  static TextStyle authLabel = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextSecondary,
    letterSpacing: 2,
  );

  /// Auth CTA Button Label.
  static TextStyle authButtonLabel = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.authButtonText,
    letterSpacing: 3,
  );

  /// Help link in auth (e.g., HỖ TRỢ KỸ THUẬT)
  static TextStyle authHelpLink = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextSecondary,
    letterSpacing: 1,
  );

  /// Footer text.
  static TextStyle authFooter = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: Color(0x4DEBE0DC), // 30% opacity of AppColors.authTextLight
    letterSpacing: 2.7,
  );

  /// Phone number display in OTP/PIN screens.
  static TextStyle authPhoneDisplay = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextLight,
    letterSpacing: 2.7,
  );

  // ─── Dashboard ────────────────────────────────────────

  static TextStyle dashboardLabel = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium in Figma
    color: AppColors.authButtonText, // Map to #FEDBAF
    letterSpacing: 2.4,
  );

  static TextStyle dashboardGreeting = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700, // Bold
    color: Colors.white,
    letterSpacing: -0.75,
  );

  static TextStyle dashboardUserName = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.authButtonText,
  );

  static TextStyle dashboardCardValue = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.authButtonText,
  );

  static TextStyle dashboardSectionTitle = const TextStyle(
    fontFamily: 'Inter', // Used Inter instead of Manrope to stick to project font
    fontSize: 20,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.authButtonText,
    letterSpacing: 2,
  );

  static TextStyle dashboardNotifBody = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.notifBodyColor,
    height: 1.625, // ≈ 19.5/12
  );
}
