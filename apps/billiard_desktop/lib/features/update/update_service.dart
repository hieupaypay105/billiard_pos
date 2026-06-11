import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/config/env_config.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String changelog;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
  });
}

class UpdateService {
  final Dio _dio;

  UpdateService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// So sánh hai phiên bản theo dạng Semantic Versioning (ví dụ '1.0.1' > '1.0.0').
  @visibleForTesting
  bool isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (var i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) {
          // Ví dụ: 1.0.0.1 > 1.0.0
          if (latestParts[i] > 0) return true;
          continue;
        }
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Kiểm tra xem có bản cập nhật mới hay không.
  Future<UpdateInfo> checkUpdate() async {
    try {
      final checkUrl = '${EnvConfig.apiBaseUrl}${EnvConfig.appCheckUpdate}';
      final response = await _dio.get(checkUrl);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // API response format: 
        // {
        //   "status": 1,
        //   "data": {
         //     "version": "1.0.1",
        //     "download_url_windows": "...",
        //     "download_url_macos": "...",
        //     "changelog": "..."
        //   }
        // }
        final innerData = (data['data'] ?? data) as Map<String, dynamic>;
        final latestVersion = (innerData['version'] ?? '').toString();
        final changelog = (innerData['changelog'] ?? 'Không có mô tả chi tiết.').toString();

        String downloadUrl = '';
        if (Platform.isWindows) {
          downloadUrl = (innerData['download_url_windows'] ?? innerData['download_url'] ?? '').toString();
        } else if (Platform.isMacOS) {
          downloadUrl = (innerData['download_url_macos'] ?? innerData['download_url'] ?? '').toString();
        }

        final currentVersion = EnvConfig.appVersion;
        final hasUpdate = isNewerVersion(currentVersion, latestVersion) && downloadUrl.isNotEmpty;

        return UpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          changelog: changelog,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Check update failed or endpoint not found: $e');
    }

    // Fallback: coi như không có update
    return UpdateInfo(
      hasUpdate: false,
      latestVersion: EnvConfig.appVersion,
      downloadUrl: '',
      changelog: '',
    );
  }

  /// Tải về file cài đặt và báo cáo tiến trình.
  Future<String?> downloadInstaller(
    String url,
    String fileName,
    Function(int received, int total) onProgress,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';
      
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return savePath;
      }
    } catch (e) {
      debugPrint('[UpdateService] Download failed: $e');
    }
    return null;
  }

  /// Khởi chạy trình cài đặt và tự động tắt ứng dụng Flutter.
  Future<void> executeInstaller(String filePath) async {
    try {
      if (Platform.isWindows) {
        // Chạy file cài đặt .exe / .msi trên Windows
        await Process.start('cmd', ['/c', 'start', '', filePath]);
      } else if (Platform.isMacOS) {
        // Chạy lệnh open trên macOS để mở file .dmg hoặc chạy trình cài đặt .pkg
        await Process.start('open', [filePath]);
      }
      // Đóng ngay lập tức ứng dụng Flutter để trình cài đặt nâng cấp ghi đè file
      exit(0);
    } catch (e) {
      debugPrint('[UpdateService] Execute installer failed: $e');
    }
  }
}

// Providers
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateCheckProvider = FutureProvider<UpdateInfo>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.checkUpdate();
});
