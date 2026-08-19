import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/providers/providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo communication port cho foreground task
  try {
    BackgroundSyncService().initCommunicationPort();
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();

  // Khởi tạo local notification service (tạo channel + xin quyền)
  // Bọc try-catch để không crash nếu chạy debug/emulator
  try {
    await NotificationService().init();
  } catch (_) {}

  // Khởi chạy Foreground Service để giữ app luôn chạy nền và giữ kết nối WebSocket
  try {
    await BackgroundSyncService().startService();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BilliardPosMobileApp(),
    ),
  );
}
