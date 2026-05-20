import 'dart:ui';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    required this.avatar,
    required this.notificationCount,
    required this.onNotificationTap,
    super.key,
  });

  final String avatar;
  final int notificationCount;

  /// Callback triggered when the bell icon is tapped. Supplied by the parent
  /// screen so that the dashboard can refresh notification count on return.
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.topBarBlurBackground,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Avatar + Logo
                      Row(
                        children: [
                          _ExecutiveAvatarWidget(avatar: avatar),
                          const SizedBox(width: 16),
                          const _LogoText(),
                        ],
                      ),
                      // Right: Notification Bell
                      _NotificationBell(
                        notificationCount: notificationCount,
                        onTap: onNotificationTap,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      stops: [0.0885, 0.5097, 0.9559],
                      colors: [
                        Color(0xFFFFDBB0),
                        Color(0xFF9C531B),
                        Color(0xFFFFDBB0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExecutiveAvatarWidget extends StatelessWidget {
  const _ExecutiveAvatarWidget({required this.avatar});

  final String avatar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go(RoutePaths.account),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.authButtonBorder),
              borderRadius: BorderRadius.circular(12),
              image: avatar.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatar),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF725C38),
                border: Border.all(color: const Color(0xFFFFF8F5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoText extends StatelessWidget {
  const _LogoText();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          stops: [0.088, 0.509, 0.955],
          colors: [
            Color(0xFFFFDBB0),
            Color(0xFF9C531B),
            Color(0xFFFFDBB0),
          ],
          transform: GradientRotation(118.763 * 3.14159 / 180),
        ).createShader(bounds);
      },
      child: Text(
        'dashboard'.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.notificationCount,
    required this.onTap,
  });

  final int notificationCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SvgPicture.asset(
                AppIcons.appBarNotification,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.authButtonText,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          if (notificationCount > 0)
            Positioned(
              top: 4,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$notificationCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
