import 'dart:ui';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A reusable dark-themed confirmation dialog matching the Figma design system.
///
/// Usage:
/// ```dart
/// final confirmed = await AnConfirmDialog.show(
///   context,
///   title: 'Xác nhận xóa CTV',
///   description: 'Hành động này không thể hoàn tác...',
/// );
/// if (confirmed ?? false) { /* perform action */ }
/// ```
class AnConfirmDialog extends StatelessWidget {
  const AnConfirmDialog({
    required this.title,
    required this.description,
    this.confirmText = 'XÓA',
    this.cancelText = 'HỦY',
    this.icon,
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  /// Title text displayed prominently below the icon.
  final String title;

  /// Descriptive body text explaining the action.
  final String description;

  /// Label for the primary (destructive) button.
  final String confirmText;

  /// Label for the secondary (cancel) button.
  final String cancelText;

  /// Optional custom icon widget. Defaults to the delete icon.
  final Widget? icon;

  /// Called when the confirm button is tapped. If null, pops with `true`.
  final VoidCallback? onConfirm;

  /// Called when the cancel button is tapped. If null, pops with `false`.
  final VoidCallback? onCancel;

  /// Shows the dialog and returns `true` if confirmed, `false` if cancelled.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    String confirmText = 'XÓA',
    String cancelText = 'HỦY',
    Widget? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => AnConfirmDialog(
        title: title,
        description: description,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Backdrop blur ──────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: const Color(0x3337312E), // rgba(55,49,46,0.2)
              ),
            ),
          ),
        ),

        // ── Dialog content ─────────────────────────────────
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.dashboardCardBorder, // #3F3F3F
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0606, 0.9648],
                      colors: [
                        AppColors.dashboardCardStart, // #242426
                        AppColors.dashboardCardEnd, // #3B3537
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F37312E), // rgba(55,49,46,0.12)
                        blurRadius: 80,
                        offset: Offset(0, 40),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Status Icon ────────────────────────
                        _buildIcon(),
                        const SizedBox(height: 32),

                        // ── Title ──────────────────────────────
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authButtonText, // #FEDBAF
                            letterSpacing: -0.6,
                            height: 32 / 24,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Description ────────────────────────
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.notifBodyColor, // #645E5A
                            height: 26 / 16,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Action Buttons ─────────────────────
                        _buildPrimaryButton(context),
                        const SizedBox(height: 16),
                        _buildSecondaryButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.dialogIconBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child:
            icon ??
            SvgPicture.asset(
              AppIcons.deleteDialog,
              width: 20,
              height: 22.5,
              colorFilter: const ColorFilter.mode(
                AppColors.authButtonText,
                BlendMode.srcIn,
              ),
            ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onConfirm ?? () => Navigator.of(context).pop(true),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.buttonBgDark, // #302D33
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.authButtonBorder), // #FFDBB0
            ),
            alignment: Alignment.center,
            child: Text(
              confirmText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.authButtonText, // #FEDBAF
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCancel ?? () => Navigator.of(context).pop(false),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.dialogSecondaryBtnBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              cancelText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFF6F2),
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
