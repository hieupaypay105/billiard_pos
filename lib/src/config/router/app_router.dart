import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/widgets/main_shell_scaffold.dart';
import 'package:anholding_app/src/features/account/presentation/screens/account_screen.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/confirm_pin_view.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/otp_verification_view.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/phone_login_view.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/pin_login_view.dart';
import 'package:anholding_app/src/features/auth/presentation/screens/setup_pin_view.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_item_model.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/provider/bang_hang_provider.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/screens/bang_hang_column_settings_screen.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/screens/bang_hang_detail_screen.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/screens/bang_hang_filter_screen.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/screens/bang_hang_screen.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_item_model.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_item.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/screens/cong_tac_vien_add_screen.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/screens/cong_tac_vien_column_settings_screen.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/screens/cong_tac_vien_edit_screen.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/screens/cong_tac_vien_filter_screen.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/screens/cong_tac_vien_screen.dart';
import 'package:anholding_app/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:anholding_app/src/features/du_an/data/models/du_an_item_model.dart';
import 'package:anholding_app/src/features/du_an/domain/entities/du_an_item.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';
import 'package:anholding_app/src/features/du_an/presentation/screens/du_an_add_screen.dart';
import 'package:anholding_app/src/features/du_an/presentation/screens/du_an_column_settings_screen.dart';
import 'package:anholding_app/src/features/du_an/presentation/screens/du_an_edit_screen.dart';
import 'package:anholding_app/src/features/du_an/presentation/screens/du_an_filter_screen.dart';
import 'package:anholding_app/src/features/du_an/presentation/screens/du_an_screen.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_item_model.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_add_screen.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_column_settings_screen.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_detail_screen.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_edit_screen.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_filter_screen.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_screen.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_trao_doi_screen.dart';
import 'package:anholding_app/src/features/notification/presentation/screens/notification_screen.dart';
import 'package:anholding_app/src/features/quan_tri/data/models/quan_tri_item_model.dart';
import 'package:anholding_app/src/features/quan_tri/domain/entities/quan_tri_item.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/screens/quan_tri_add_screen.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/screens/quan_tri_column_settings_screen.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/screens/quan_tri_edit_screen.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/screens/quan_tri_filter_screen.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/screens/quan_tri_screen.dart';
import 'package:anholding_app/src/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates a [CustomTransitionPage] with a fade animation.
CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

/// Application router.
///
/// Auth flow:  /phone-login → /otp-verification → /setup-pin → /confirm-pin
/// Returning:  /pin-login  (direct entry for cached sessions)
/// Post-auth:  /dashboard, /account  (wrapped in ShellRoute with bottom bar)
final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  redirect: (context, state) {
    // Firebase Auth uses a custom scheme callback like:
    // com.googleusercontent.apps.<id>://firebaseauth/link?...
    // This is not an in-app route, so ignore it.
    if (state.uri.host == 'firebaseauth' && state.uri.path == '/link') {
      return RoutePaths.splash;
    }
    return null;
  },
  routes: [
    // ── Splash ───────────────────────────────────────────
    GoRoute(
      path: RoutePaths.splash,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const SplashScreen()),
    ),

    // ── Auth flow — new phone-based ───────────────────────
    GoRoute(
      path: RoutePaths.phoneLogin,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const PhoneLoginView()),
    ),
    GoRoute(
      path: RoutePaths.otpVerification,
      builder: (context, state) => const OtpVerificationView(),
    ),
    GoRoute(
      path: RoutePaths.setupPin,
      builder: (context, state) => const SetupPinView(),
    ),
    GoRoute(
      path: RoutePaths.confirmPin,
      builder: (context, state) => const ConfirmPinView(),
    ),

    // ── Returning user (PIN login) ─────────────────────────
    GoRoute(
      path: RoutePaths.pinLogin,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const PinLoginView()),
    ),

    // ── Bang hang (moved to shell route) ────────────────────

    // ── Bang hang filter ────────────────────────────────────
    GoRoute(
      path: RoutePaths.bangHangFilter,
      builder: (context, state) {
        final extra = state.extra;
        var filter = const BangHangFilter();
        if (extra is BangHangFilter) filter = extra;
        if (extra is Map<String, dynamic>) {
          // Fallback if GoRouter serializes it
        }
        return BangHangFilterScreen(initialFilter: filter);
      },
    ),

    // ── Bang hang column settings ────────────────────────────
    GoRoute(
      path: RoutePaths.bangHangColumnSettings,
      builder: (context, state) => const BangHangColumnSettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.bangHangDetail,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is BangHangItem) {
          return BangHangDetailScreen(item: extra);
        }
        if (extra is Map<String, dynamic>) {
          return BangHangDetailScreen(
            item: BangHangItemModel.fromJson(extra),
          );
        }
        if (extra is Map) {
          return BangHangDetailScreen(
            item: BangHangItemModel.fromJson(Map<String, dynamic>.from(extra)),
          );
        }
        throw StateError('Expected BangHangItem in state.extra');
      },
    ),

    // ── Cong tac vien (moved to shell route) ────────────────
    GoRoute(
      path: RoutePaths.congTacVienFilter,
      builder: (context, state) {
        final extra = state.extra;
        var filter = const CongTacVienFilter();
        if (extra is CongTacVienFilter) filter = extra;
        if (extra is Map<String, dynamic>) {
          filter = CongTacVienFilter.fromJson(extra);
        } else if (extra is Map) {
          filter = CongTacVienFilter.fromJson(Map<String, dynamic>.from(extra));
        }
        return CongTacVienFilterScreen(initialFilter: filter);
      },
    ),
    GoRoute(
      path: RoutePaths.congTacVienColumnSettings,
      builder: (context, state) => const CongTacVienColumnSettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.congTacVienAdd,
      builder: (context, state) => const CongTacVienAddScreen(),
    ),
    GoRoute(
      path: RoutePaths.congTacVienEdit,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is CongTacVienItem) {
          return CongTacVienEditScreen(item: extra);
        }
        if (extra is Map<String, dynamic>) {
          return CongTacVienEditScreen(
            item: CongTacVienItemModel.fromJson(extra),
          );
        }
        if (extra is Map) {
          return CongTacVienEditScreen(
            item: CongTacVienItemModel.fromJson(
              Map<String, dynamic>.from(extra),
            ),
          );
        }
        throw StateError('Expected CongTacVienItem in state.extra');
      },
    ),

    // ── Du an ────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.duAn,
      builder: (context, state) => const DuAnScreen(),
    ),
    GoRoute(
      path: RoutePaths.duAnFilter,
      builder: (context, state) {
        final extra = state.extra;
        var filter = const DuAnFilter();
        if (extra is DuAnFilter) filter = extra;
        if (extra is Map<String, dynamic>) {
          // Will add fromJson later
        }
        return DuAnFilterScreen(initialFilter: filter);
      },
    ),
    GoRoute(
      path: RoutePaths.duAnColumnSettings,
      builder: (context, state) => const DuAnColumnSettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.duAnAdd,
      builder: (context, state) => const DuAnAddScreen(),
    ),
    GoRoute(
      path: RoutePaths.duAnEdit,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is DuAnItem) {
          return DuAnEditScreen(item: extra);
        }
        if (extra is Map<String, dynamic>) {
          return DuAnEditScreen(item: DuAnItemModel.fromJson(extra));
        }
        if (extra is Map) {
          return DuAnEditScreen(
            item: DuAnItemModel.fromJson(Map<String, dynamic>.from(extra)),
          );
        }
        throw StateError('Expected DuAnItem in state.extra');
      },
    ),

    // ── Khach hang (moved to shell route) ───────────────────
    GoRoute(
      path: RoutePaths.khachHangFilter,
      builder: (context, state) {
        final extra = state.extra;
        var filter = const KhachHangFilter();
        if (extra is KhachHangFilter) filter = extra;
        if (extra is Map<String, dynamic>) {
          // Will add fromJson later
        }
        return KhachHangFilterScreen(initialFilter: filter);
      },
    ),
    GoRoute(
      path: RoutePaths.khachHangColumnSettings,
      builder: (context, state) => const KhachHangColumnSettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.khachHangAdd,
      builder: (context, state) => const KhachHangAddScreen(),
    ),
    GoRoute(
      path: RoutePaths.khachHangEdit,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is KhachHangItem) {
          return KhachHangEditScreen(item: extra);
        }
        if (extra is Map<String, dynamic>) {
          return KhachHangEditScreen(
            item: KhachHangItemModel.fromJson(extra),
          );
        }
        if (extra is Map) {
          return KhachHangEditScreen(
            item: KhachHangItemModel.fromJson(
              Map<String, dynamic>.from(extra),
            ),
          );
        }
        throw StateError('Expected KhachHangItem in state.extra');
      },
    ),
    GoRoute(
      path: RoutePaths.khachHangDetail,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is KhachHangItem) {
          return KhachHangDetailScreen(item: extra);
        }
        if (extra is Map<String, dynamic>) {
          return KhachHangDetailScreen(
            item: KhachHangItemModel.fromJson(extra),
          );
        }
        if (extra is Map) {
          return KhachHangDetailScreen(
            item: KhachHangItemModel.fromJson(
              Map<String, dynamic>.from(extra),
            ),
          );
        }
        throw StateError('Expected KhachHangItem in state.extra');
      },
    ),
    GoRoute(
      path: RoutePaths.khachHangTraoDoi,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is KhachHangItem) {
          return KhachHangTraoDoiScreen(item: extra);
        }
        if (extra is Map<String, dynamic>) {
          return KhachHangTraoDoiScreen(
            item: KhachHangItemModel.fromJson(extra),
          );
        }
        if (extra is Map) {
          return KhachHangTraoDoiScreen(
            item: KhachHangItemModel.fromJson(
              Map<String, dynamic>.from(extra),
            ),
          );
        }
        throw StateError('Expected KhachHangItem in state.extra');
      },
    ),

    // ── Quan tri ─────────────────────────────────────────
    GoRoute(
      path: RoutePaths.quanTri,
      builder: (context, state) => const QuanTriScreen(),
    ),
    GoRoute(
      path: RoutePaths.quanTriFilter,
      builder: (context, state) {
        final extra = state.extra;
        var filter = const QuanTriFilter();
        if (extra is QuanTriFilter) filter = extra;
        if (extra is Map<String, dynamic>) {
          // Will add fromJson later
        }
        return QuanTriFilterScreen(initialFilter: filter);
      },
    ),
    GoRoute(
      path: RoutePaths.quanTriColumnSettings,
      builder: (context, state) => const QuanTriColumnSettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.quanTriAdd,
      builder: (context, state) => const QuanTriAddScreen(),
    ),
    GoRoute(
      path: RoutePaths.quanTriEdit,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is QuanTriItem) {
          return QuanTriEditScreen(item: extra);
        }
        if (extra is Map<String, dynamic>) {
          return QuanTriEditScreen(item: QuanTriItemModel.fromJson(extra));
        }
        if (extra is Map) {
          return QuanTriEditScreen(
            item: QuanTriItemModel.fromJson(Map<String, dynamic>.from(extra)),
          );
        }
        throw StateError('Expected QuanTriItem in state.extra');
      },
    ),

    // ── Account ──────────────────────────────────────────
    GoRoute(
      path: RoutePaths.account,
      builder: (context, state) => const AccountScreen(),
    ),

    // ── Notification ─────────────────────────────────────
    GoRoute(
      path: RoutePaths.notification,
      builder: (context, state) => const NotificationScreen(),
    ),

    // ── Post-auth (with global FloatingBottomBar) ──────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.bangHang,
              builder: (context, state) => const BangHangScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.congTacVien,
              builder: (context, state) => const CongTacVienScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.khachHang,
              builder: (context, state) => const KhachHangScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.aiAssistant,
              builder: (context, state) => const AiAssistantScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
