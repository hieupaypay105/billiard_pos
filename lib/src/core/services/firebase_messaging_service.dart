import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/core/utils/deeplink_utils.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:anholding_app/src/core/utils/telegram_logger.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler.
///
/// Must be a top-level function (not a class method) as required by Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await ensureFirebaseInitialized();
  log(
    'FCM background: id=${message.messageId}, '
    'title=${message.notification?.title}, '
    'data=${message.data}',
  );

  // Background isolates do NOT share memory with main().
  // We MUST load the environment variables again here, otherwise dotenv.env is empty
  // and TelegramLogger will just return quietly.
  try {
    await dotenv.load();
  } catch (e) {
    log('Failed to load .env in background isolate: $e');
  }

  final platform = defaultTargetPlatform == TargetPlatform.iOS
      ? 'ios'
      : 'android';

  unawaited(
    TelegramLogger.logToChannel(
      '🟡 <b>[FCM Background]</b>\n'
      '<b>Platform:</b> $platform\n'
      '<b>Title:</b> ${message.notification?.title}\n'
      '<b>Data:</b> ${message.data}',
    ),
  );
}

/// Service that manages Firebase Cloud Messaging for push notifications.
///
/// Handles permission requests, token management, foreground/background
/// message handling, and local notification display.
class FirebaseMessagingService {
  FirebaseMessagingService({required this.dio, FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final Dio dio;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  FutureOr<void> Function(RemoteMessage message)? _onMessageTapped;
  bool _isActivated = false;
  bool _isPrewarmed = false;
  bool _localNotificationsConfigured = false;
  bool _initialMessageHandled = false;
  String? _lastSyncedToken;

  static const _channelId = 'anholding_notifications';
  static const _channelName = 'AnHolding Notifications';
  static const _channelDescription = 'Thông báo từ AnHolding CRM';

  /// Activates push notifications only after the user is authenticated.
  ///
  /// This keeps app-launch initialization separate from iOS phone auth APNs
  /// verification, which is handled natively in AppDelegate.
  Future<void> activateForAuthenticatedUser({
    FutureOr<void> Function(RemoteMessage message)? onMessageTapped,
  }) async {
    try {
      _onMessageTapped = onMessageTapped ?? _defaultOnMessageTapped;

      final settings = await _messaging.requestPermission();

      if (!_isNotificationPermissionGranted(settings.authorizationStatus)) {
        logger.w(
          'FCM: Notification permission not granted after auth '
          '(${settings.authorizationStatus.name})',
        );
        return;
      }

      if (!_localNotificationsConfigured) {
        await _setupLocalNotifications();
        _localNotificationsConfigured = true;
      }

      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
        logger.d('FCM token refreshed after auth activation: $token');
        unawaited(
          TelegramLogger.logToChannel(
            '🔄 <b>[FCM Token Refreshed]</b>\n'
            '<b>Platform:</b> ${defaultTargetPlatform.name}\n'
            '<b>Token:</b> $token',
          ),
        );
        _lastSyncedToken = null;
        unawaited(syncTokenToBackendIfAvailable());
      });

      _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen((
        message,
      ) {
        logger.i('FCM foreground message: ${message.notification?.title}');
        unawaited(
          TelegramLogger.logToChannel(
            '🔵 <b>[FCM Foreground]</b>\n'
            '<b>Platform:</b> ${defaultTargetPlatform.name}\n'
            '<b>Title:</b> ${message.notification?.title}\n'
            '<b>Data:</b> ${message.data}',
          ),
        );
        unawaited(_showLocalNotification(message));
      });

      _messageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp
          .listen((message) {
            logger.d('FCM message opened app: ${message.data}');
            unawaited(_handleTappedMessage(message));
          });

      _isActivated = true;

      if (!_initialMessageHandled) {
        final initialMessage = await _messaging.getInitialMessage();
        _initialMessageHandled = true;
        if (initialMessage != null) {
          await _handleTappedMessage(initialMessage);
        }
      }

      await syncTokenToBackendIfAvailable();
    } on Exception catch (e) {
      logger.e(
        'FCM: Failed to activate authenticated notification flow',
        error: e,
      );
    }
  }

  /// Backward-compatible alias for older callers.
  Future<void> initialize({
    FutureOr<void> Function(RemoteMessage message)? onMessageTapped,
  }) => activateForAuthenticatedUser(onMessageTapped: onMessageTapped);

  /// Pre-warms FCM/APNs registration early to support iOS phone auth.
  ///
  /// This avoids requesting notification permission and simply forces
  /// token registration so silent push verification can work reliably.
  Future<void> prewarmForAuth() async {
    if (_isPrewarmed) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        logger.d('FCM prewarm APNs token: ${apnsToken ?? "-"}');
      }

      final fcmToken = await _messaging.getToken();
      logger.d('FCM prewarm token: ${fcmToken ?? "-"}');

      if (fcmToken != null) {
        unawaited(
          TelegramLogger.logToChannel(
            '⚡ <b>[FCM Prewarm Token]</b>\n'
            '<b>Platform:</b> ${defaultTargetPlatform.name}\n'
            '<b>Token:</b> $fcmToken',
          ),
        );
      }
    } on Exception catch (e) {
      logger.w('FCM prewarm failed', error: e);
    } finally {
      _isPrewarmed = true;
    }
  }

  /// Returns the current FCM token, or `null` if unavailable.
  Future<String?> getToken() => _messaging.getToken();

  /// Subscribes the device to a [topic] for broadcast notifications.
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  /// Unsubscribes the device from a [topic].
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  // ─── Private helpers ──────────────────────────────────────

  bool _isNotificationPermissionGranted(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_gemini_generated_image_atlv3katlv3katlv',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create Android notification channel (required for Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_gemini_generated_image_atlv3katlv3katlv',
          largeIcon: DrawableResourceAndroidBitmap(
            '@mipmap/ic_launcher',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Syncs the current FCM token to the backend when authentication is ready.
  Future<void> syncTokenToBackendIfAvailable() async {
    try {
      if (!_isActivated) {
        logger.d('FCM not activated yet; skipping backend token sync');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        logger.w('FCM token unavailable, skipping backend sync');
        return;
      }

      if (_lastSyncedToken == token) {
        logger.d(
          'FCM token already synced in this runtime, skipping duplicate',
        );
        return;
      }

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      final payload = {
        'token': token,
        'os': platform,
        'owner_type': 'user',
      };
      final formData = FormData.fromMap(payload);

      await dio.post<void>(ApiPaths.notificationFcmToken, data: formData);
      _lastSyncedToken = token;
      logger.d('FCM token synced to backend successfully: $token');

      final fullUrl = '${dio.options.baseUrl}${ApiPaths.notificationFcmToken}';

      unawaited(
        TelegramLogger.logToChannel(
          '✅ <b>[FCM Token Synced]</b>\n'
          '<b>URL:</b> $fullUrl\n'
          '<b>Payload:</b> $payload\n'
          '<b>Platform:</b> $platform\n'
          '<b>Token:</b> $token',
        ),
      );
    } on Exception catch (e) {
      logger.w('Failed to sync FCM token to backend: $e');
    }
  }

  Future<void> _handleTappedMessage(RemoteMessage message) async {
    final handler = _onMessageTapped ?? _defaultOnMessageTapped;
    await handler(message);
  }

  Future<void> _defaultOnMessageTapped(RemoteMessage message) async {
    logger.d('FCM message tapped: ${message.data}');
    final actionUrl = message.data['action_url']?.toString();
    final deepLink = message.data['deep_link']?.toString();

    await DeeplinkUtils.handleAppNavigation(
      actionUrl: actionUrl,
      deepLink: deepLink,
    );
  }

  /// Backward-compatible alias for callers still using the old method name.
  Future<void> sendTokenToBackend() => syncTokenToBackendIfAvailable();

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
  }
}
