import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(BilliardTaskHandler());
}

class BilliardTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('BilliardTaskHandler onStart');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Keep alive tick
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('BilliardTaskHandler onDestroy');
  }
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._();

  bool _isServiceInitialized = false;

  void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  Future<void> initService() async {
    if (_isServiceInitialized) return;

    if (Platform.isAndroid) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'billiard_pos_foreground',
          channelName: 'NW Waiter Dịch vụ nền',
          channelDescription:
              'Duy trì kết nối đồng bộ với máy thu ngân và nhận thông báo',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    }
    _isServiceInitialized = true;
  }

  Future<void> startService() async {
    if (!Platform.isAndroid) return;
    try {
      await initService();

      // Xin miễn tối ưu pin để Android không đóng socket/kết nối mạng khi tắt màn hình
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      if (await FlutterForegroundTask.isRunningService) {
        return;
      }

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'NW Waiter đang chạy nền',
        notificationText: 'Đang duy trì kết nối đồng bộ với quầy thu ngân',
        callback: startForegroundCallback,
      );
    } catch (e) {
      print('Lỗi khởi động Foreground Service: $e');
    }
  }

  Future<void> stopService() async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      print('Lỗi dừng Foreground Service: $e');
    }
  }
}
