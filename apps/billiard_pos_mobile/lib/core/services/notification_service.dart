import 'dart:typed_data';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service quản lý local push notifications.
/// Dùng để gửi thông báo hệ thống khi Desktop cập nhật dịch vụ,
/// kể cả khi app đang chạy background.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 200, 100, 200, 100, 300]);

  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {},
      );

      // Tạo notification channel (Android 8+)
      final androidChannel = AndroidNotificationChannel(
        'desktop_updates',
        'Cập nhật từ Thu ngân',
        description: 'Thông báo khi thu ngân duyệt hoặc cập nhật dịch vụ',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Xin quyền notification (Android 13+)
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      // Bỏ qua lỗi MissingPluginException khi chạy debug/test
      print('NotificationService init failed (có thể do debug mode): $e');
    }
  }

  /// Gửi push notification về cập nhật dịch vụ từ Desktop.
  Future<void> showDesktopUpdateNotification({
    required String title,
    required String body,
    bool isApproved = false,
  }) async {
    if (!_initialized) {
      await init();
      if (!_initialized) return; // Nếu init vẫn thất bại thì bỏ qua
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'desktop_updates',
        'Cập nhật từ Thu ngân',
        channelDescription:
            'Thông báo khi thu ngân duyệt hoặc cập nhật dịch vụ',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: isApproved
            ? const Color(0xFF16A34A)
            : const Color(0xFF2563EB),
        playSound: false,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        ticker: title,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
        ),
      );

      await _plugin.show(
        isApproved ? 1001 : 1002,
        title,
        body,
        NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      print('NotificationService.show failed: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
