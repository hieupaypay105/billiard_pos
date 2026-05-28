import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/tables/tables_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/sync/sync_screen.dart';
import '../widgets/app_shell.dart';

// Route name constants
class AppRoutes {
  static const login = '/login';
  static const tables = '/tables';
  static const billing = '/billing';
  static const statistics = '/statistics';
  static const reports = '/reports';
  static const sync = '/sync';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.tables,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuth = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // Wait for session restore
      if (isLoading) return null;
      if (!isAuth && !isLoginRoute) return AppRoutes.login;
      if (isAuth && isLoginRoute) return AppRoutes.tables;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tables,
            pageBuilder: (ctx, state) => NoTransitionPage(
              child: const TablesScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: AppRoutes.billing,
            redirect: (ctx, state) => AppRoutes.tables,
          ),
          GoRoute(
            path: AppRoutes.statistics,
            pageBuilder: (ctx, state) => NoTransitionPage(
              child: const StatisticsScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (ctx, state) => NoTransitionPage(
              child: const ReportsScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: AppRoutes.sync,
            pageBuilder: (ctx, state) =>
                NoTransitionPage(child: const SyncScreen(), key: state.pageKey),
          ),
        ],
      ),
    ],
  );
});
