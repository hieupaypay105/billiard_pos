import 'dart:async';

import 'package:anholding_app/src/config/router/app_router.dart';
import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_confirm_dialog.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/account/presentation/widgets/change_pin_sheet.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Account screen — profile info, change PIN, and logout.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _openChangePinSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ChangePinSheet(),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await AnConfirmDialog.show(
      context,
      title: 'Đăng xuất',
      description: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmText: 'ĐĂNG XUẤT',
      icon: SvgPicture.asset(
        AppIcons.logout,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppColors.authButtonText,
          BlendMode.srcIn,
        ),
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<UserProvider>().clearUser();
      appRouter.go(RoutePaths.phoneLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.dashboard);
          }
        },
        onNotificationTap: () async {
          await context.push(RoutePaths.notification);
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.currentUser;

            // Scrollable content
            return SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, safeTop + 72 + 40, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar
                    _AccountAvatar(avatarUrl: user?.avatar ?? ''),
                    const SizedBox(height: 32),

                    // Section 1: Thông tin tài khoản
                    const _SectionHeading(title: 'THÔNG TIN TÀI KHOẢN'),
                    const SizedBox(height: 18),
                    _DarkReadOnlyField(
                      label: 'TÊN ĐĂNG NHẬP',
                      value: user?.fullname ?? 'Tên đăng nhập',
                    ),
                    const SizedBox(height: 18),
                    _DarkReadOnlyField(
                      label: 'SỐ ĐIỆN THOẠI',
                      value: user?.mobile ?? '09xx xxx xxx',
                    ),
                    const SizedBox(height: 18),
                    _DarkReadOnlyField(
                      label: 'EMAIL',
                      value: user?.email ?? 'email@domain.com',
                    ),

                    const SizedBox(height: 24),

                    // ── Change PIN Row ─────────────
                    _ChangePinRow(
                      onTap: () => _openChangePinSheet(context),
                    ),

                    const SizedBox(height: 16),

                    // Logout Button
                    _LogoutButton(
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.authTextLight, width: 4),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.dashboardCardStart,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 20),
                ),
              ],
              image: avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 64, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 4,
            right: -4,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.authTextDisabled, // #665d58
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Headings ─────────────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.authButtonText,
        letterSpacing: 1.8,
      ),
    );
  }
}

// ── Dark Read-Only Field ─────────────────────────────────────────────────────

class _DarkReadOnlyField extends StatelessWidget {
  const _DarkReadOnlyField({
    required this.label,
    required this.value,
    this.isSecure = false,
  });

  final String label;
  final String value;
  final bool isSecure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.notifBodyColor,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.inputBackgroundDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isSecure ? 24 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Change PIN Row ────────────────────────────────────────────────────────────

class _ChangePinRow extends StatelessWidget {
  const _ChangePinRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.inputBackgroundDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, size: 20, color: AppColors.authButtonText),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đổi mã PIN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authButtonText,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Buttons ───────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppIcons
                    .logout, // Ensure it's roughly the same icon as Figma, or rely on AppIcons.logout
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.textHint,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Đăng xuất',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
