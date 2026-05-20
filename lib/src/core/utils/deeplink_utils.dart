import 'package:anholding_app/src/config/router/app_router.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Utility class for handling deep links and action URLs
/// returned from backend APIs (e.g., Notifications).
class DeeplinkUtils {
  /// Parses the provided [deepLink] or [actionUrl] and navigates to the
  /// corresponding screen in the app using [GoRouter].
  /// If [context] is null, falls back to the global [appRouter].
  static Future<void> handleAppNavigation({
    BuildContext? context,
    String? deepLink,
    String? actionUrl,
  }) async {
    final url = (deepLink != null && deepLink.isNotEmpty)
        ? deepLink
        : actionUrl;
    if (url == null || url.isEmpty) return;

    Future<void> navigate(String path) async {
      if (context != null && context.mounted) {
        context.go(path);
      } else {
        appRouter.go(path);
      }
    }

    // We map these to our internal RoutePaths.
    if (url.startsWith('/khachhang')) {
      await navigate(RoutePaths.khachHang);
    } else if (url.startsWith('/duan')) {
      await navigate(RoutePaths.duAn);
    } else if (url.startsWith('/banghang')) {
      await navigate(RoutePaths.bangHang);
    } else if (url.startsWith('/congtacvien')) {
      await navigate(RoutePaths.congTacVien);
    } else if (url.startsWith('/quantri')) {
      await navigate(RoutePaths.quanTri);
    } else {
      logger.w('DeeplinkUtils: Unhandled deep link: $url');
    }
  }
}
