import 'dart:ui';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Reusable top app bar for feature screens.
///
/// Refactored to match the Figma Dark Mode pattern:
/// gradient "AN HOLDINGS" text + transparent blur background.
class AnFeatureAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AnFeatureAppBar({
    super.key,
    this.avatarUrl = '',
    this.titleText,
    this.featureTitle,
    this.onBackTap,
    this.onNotificationTap,
    this.onFilterTap,
    this.onAddTap,
    this.onSearchTap,
    this.showNotification = true,
    this.showFilter = true,
    this.showAdd = true,
    this.showSearch = true,
  });

  final String avatarUrl;
  final String? titleText;

  /// Hero title displayed below the icon row, inside the blur container.
  /// Uses the gold gradient style (24px, w300) with a 64px underline.
  /// When set, [preferredSize] expands to 144px to accommodate the extra section.
  final String? featureTitle;
  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onSearchTap;
  final bool showNotification;
  final bool showFilter;
  final bool showAdd;
  final bool showSearch;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          // Ensure enough height if wrapped in standard PreferredSize.
          // If used outside an AppBar, SafeArea expands height internally.
          height: preferredSize.height + MediaQuery.paddingOf(context).top,
          decoration: const BoxDecoration(
            color: AppColors.topBarBlurBackground,
          ),
          child: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _ActionIcon(
                          iconPath: AppIcons.appBarBack,
                          semanticLabel: 'Back',
                          size: 15,
                          onTap:
                              onBackTap ??
                              () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 4),
                        if (titleText != null)
                          Text(
                            titleText!,
                            style: AppTextStyles.dashboardSectionTitle.copyWith(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          )
                        else
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFDBB0),
                                Color(0xFF9C531B),
                                Color(0xFFFFDBB0),
                              ],
                              stops: [0.0885, 0.5097, 0.9559],
                              transform: GradientRotation(
                                118.763 * 3.1415927 / 180,
                              ),
                            ).createShader(bounds),
                            child: Text(
                              featureTitle ?? 'AN HOLDINGS',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (showNotification) ...[
                          Consumer<DashboardNotificationProvider>(
                            builder: (context, provider, _) {
                              final unreadCount = provider.unreadCount;
                              return Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  _ActionIcon(
                                    iconPath: AppIcons.appBarNotification,
                                    semanticLabel: 'Notification',
                                    onTap: onNotificationTap,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 4,
                                      right: 6,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            final user = userProvider.currentUser;
                            final avatar = user?.avatar ?? avatarUrl;
                            return _Avatar(avatarUrl: avatar);
                          },
                        ),
                        // if (showFilter) ...[
                        //   const SizedBox(width: 8),
                        //   _ActionIcon(
                        //     iconPath: AppIcons.appBarFilter,
                        //     semanticLabel: 'Filter',
                        //     onTap: onFilterTap,
                        //   ),
                        // ],
                        // if (showAdd) ...[
                        //   const SizedBox(width: 8),
                        //   _ActionIcon(
                        //     iconPath: AppIcons.appBarAdd,
                        //     semanticLabel: 'Add',
                        //     onTap: onAddTap,
                        //   ),
                        // ],
                        // if (showSearch) ...[
                        //   const SizedBox(width: 8),
                        //   _ActionIcon(
                        //     iconPath: AppIcons.appBarSearch,
                        //     semanticLabel: 'Search',
                        //     onTap: onSearchTap,
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: 1,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFDBB0),
                      Color(0xFF9C531B),
                      Color(0xFFFFDBB0),
                    ],
                    stops: [0.0885, 0.5097, 0.9559],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(RoutePaths.account);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.titleGradientStart,
              ),
              color: AppColors.topBarBackground,
              image: avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF725C38),
                border: Border.all(
                  color: const Color(0xFFFFF8F5),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.iconPath,
    required this.semanticLabel,
    required this.onTap,
    this.size = 24,
  });

  final String iconPath;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: SvgPicture.asset(
              iconPath,
              width: size,
              height: size,
              semanticsLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}
