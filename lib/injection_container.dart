import 'package:anholding_app/src/config/router/app_router.dart';
import 'package:anholding_app/src/core/constants/env.dart';
import 'package:anholding_app/src/core/network/auth_interceptor.dart';
import 'package:anholding_app/src/core/network/token_storage.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/services/firebase_auth_service.dart';
import 'package:anholding_app/src/core/services/firebase_messaging_service.dart';
import 'package:anholding_app/src/core/storage/pin_storage.dart';
import 'package:anholding_app/src/core/storage/user_storage.dart';
import 'package:anholding_app/src/features/ai/data/datasources/ai_remote_data_source.dart';
import 'package:anholding_app/src/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:anholding_app/src/features/ai/domain/repositories/ai_repository.dart';
import 'package:anholding_app/src/features/ai/presentation/provider/ai_provider.dart';
import 'package:anholding_app/src/features/ai_assistant/data/datasources/ai_remote_data_source.dart';
import 'package:anholding_app/src/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/provider/ai_assistant_provider.dart';
import 'package:anholding_app/src/features/auth/data/datasources/auth_remote_source.dart';
import 'package:anholding_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_provider.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_view_model.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/bang_hang/data/datasources/bang_hang_remote_source.dart';
import 'package:anholding_app/src/features/bang_hang/data/repositories/bang_hang_repository_impl.dart';
import 'package:anholding_app/src/features/bang_hang/domain/repositories/bang_hang_repository.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/provider/bang_hang_provider.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/datasources/cong_tac_vien_remote_source.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/repositories/cong_tac_vien_repository_impl.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/repositories/cong_tac_vien_repository.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/provider/cong_tac_vien_provider.dart';
import 'package:anholding_app/src/features/dashboard/data/datasources/dashboard_mock_source.dart';
import 'package:anholding_app/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:anholding_app/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_notification_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/menu_provider.dart';
import 'package:anholding_app/src/features/du_an/data/datasources/du_an_remote_source.dart';
import 'package:anholding_app/src/features/du_an/data/repositories/du_an_repository_impl.dart';
import 'package:anholding_app/src/features/du_an/domain/repositories/du_an_repository.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';
import 'package:anholding_app/src/features/khach_hang/data/datasources/khach_hang_remote_source.dart';
import 'package:anholding_app/src/features/khach_hang/data/repositories/khach_hang_repository_impl.dart';
import 'package:anholding_app/src/features/khach_hang/domain/repositories/khach_hang_repository.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/notification/data/datasources/notification_remote_source.dart';
import 'package:anholding_app/src/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:anholding_app/src/features/notification/domain/repositories/notification_repository.dart';
import 'package:anholding_app/src/features/notification/presentation/provider/notification_provider.dart';
import 'package:anholding_app/src/features/quan_tri/data/datasources/quan_tri_remote_source.dart';
import 'package:anholding_app/src/features/quan_tri/data/repositories/quan_tri_repository_impl.dart';
import 'package:anholding_app/src/features/quan_tri/domain/repositories/quan_tri_repository.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // ─── Core ────────────────────────────────────────────────
  sl
    ..registerLazySingleton(TokenStorage.new)
    ..registerLazySingleton(PinStorage.new)
    ..registerLazySingleton(() {
      final dio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Thêm AuthInterceptor để tự động quản lý token
      dio.interceptors.add(
        AuthInterceptor(
          tokenStorage: sl(),
          onTokensUpdated: ({accessToken, refreshToken}) async {
            await sl<UserProvider>().updateTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
          },
          onLogout: () => appRouter.go(RoutePaths.phoneLogin),
        ),
      );

      return dio;
    })
    ..registerLazySingleton(FirebaseAuthService.new)
    ..registerLazySingleton<FirebaseMessagingService>(
      () => FirebaseMessagingService(dio: sl()),
    )
    ..registerLazySingleton(UserStorage.new)
    ..registerLazySingleton(
      () => UserProvider(userStorage: sl(), authRepository: sl()),
    )
    // ─── Data Sources (đăng ký trước Repository) ─────────────
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dio: sl(), tokenStorage: sl()),
    )
    ..registerLazySingleton<AiRemoteDataSource>(
      () => AiRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<BangHangRemoteDataSource>(
      () => BangHangRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<CongTacVienRemoteDataSource>(
      () => CongTacVienRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<DuAnRemoteDataSource>(
      () => DuAnRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<KhachHangRemoteDataSource>(
      () => KhachHangRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<QuanTriRemoteDataSource>(
      () => QuanTriRemoteDataSourceImpl(dio: sl()),
    )
    ..registerLazySingleton<AiAssistantRemoteDataSource>(
      () => AiAssistantRemoteDataSourceImpl(dio: sl()),
    )
    // ─── Repositories ────────────────────────────────────────
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton<AiRepository>(
      () => AiRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton<BangHangRepository>(
      () => BangHangRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<CongTacVienRepository>(
      () => CongTacVienRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<DuAnRepository>(
      () => DuAnRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<KhachHangRepository>(
      () => KhachHangRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<QuanTriRepository>(
      () => QuanTriRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<AiAssistantRepository>(
      () => AiAssistantRepositoryImpl(remoteDataSource: sl()),
    )
    // ─── Providers / ViewModels (đăng ký sau cùng) ──────────
    ..registerFactory(() => AuthProvider(repository: sl()))
    ..registerFactory(() => AiProvider(repository: sl()))
    ..registerFactory(
      () => AuthViewModel(
        pinStorage: sl(),
        firebaseAuthService: sl(),
        authRepository: sl(),
        userProvider: sl(),
      ),
    )
    ..registerFactory(() => DashboardProvider(repository: sl()))
    ..registerFactory(() => BangHangProvider(repository: sl()))
    ..registerFactory(() => CongTacVienProvider(repository: sl()))
    ..registerFactory(() => DuAnProvider(repository: sl()))
    ..registerFactory(() => KhachHangProvider(repository: sl()))
    ..registerFactory(() => NotificationProvider(repository: sl()))
    ..registerFactory(
      () => DashboardNotificationProvider(repository: sl()),
    )
    ..registerFactory(() => QuanTriProvider(repository: sl()))
    ..registerFactory(() => AiAssistantProvider(repository: sl()))
    ..registerLazySingleton(MenuProvider.new);
}
