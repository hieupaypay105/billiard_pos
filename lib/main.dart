import 'package:anholding_app/injection_container.dart' as di;
import 'package:anholding_app/src/config/router/app_router.dart';
import 'package:anholding_app/src/core/firebase_bootstrap.dart';
import 'package:anholding_app/src/core/services/firebase_auth_service.dart';
import 'package:anholding_app/src/core/services/firebase_messaging_service.dart';
import 'package:anholding_app/src/core/storage/pin_storage.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/features/ai/presentation/provider/ai_provider.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/provider/ai_assistant_provider.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_provider.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_view_model.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/provider/bang_hang_provider.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/provider/cong_tac_vien_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_notification_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/menu_provider.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/notification/presentation/provider/notification_provider.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // logger.i('[1/5] Loading .env...');
  await dotenv.load();

  // logger.i('[2/5] Firebase.initializeApp...');
  await ensureFirebaseInitialized();
  await ensureAppCheckActivated();
  logFirebaseConfiguration();

  // logger.i('[3/5] DI init...');
  await di.init();

  // logger.i('[3.5/5] FCM prewarm for iOS phone auth...');
  try {
    await di.sl<FirebaseMessagingService>().prewarmForAuth();
  } on Exception catch (e) {
    logger.w('FCM prewarm failed (non-fatal)', error: e);
  }

  // logger.i('[4/5] Firebase Auth test mode...');
  try {
    await di.sl<FirebaseAuthService>().enableTestMode();
  } on Exception catch (e) {
    logger.w('Firebase Auth test mode failed (non-fatal)', error: e);
  }

  // logger.i('[5/5] Starting app — FCM will init in background...');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const AnHoldingApp());
}

class AnHoldingApp extends StatelessWidget {
  const AnHoldingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PinStorage>(create: (_) => di.sl<PinStorage>()),
        ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AiProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<UserProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<DashboardProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<BangHangProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<CongTacVienProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<DuAnProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<KhachHangProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<QuanTriProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AiAssistantProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<MenuProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<NotificationProvider>()),
        ChangeNotifierProvider(
          create: (_) => di.sl<DashboardNotificationProvider>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'AnHolding CRM',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'),
        ],
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: AppColors.primaryGold,
                brightness: Brightness.dark,
              ).copyWith(
                surface: AppColors.darkBackground,
                primary: AppColors.primaryGold,
              ),
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: AppColors.darkBackground,
          splashFactory: InkRipple.splashFactory,
          splashColor: AppColors.primaryGold.withOpacity(0.18),
          highlightColor: AppColors.primaryGold.withOpacity(0.08),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
