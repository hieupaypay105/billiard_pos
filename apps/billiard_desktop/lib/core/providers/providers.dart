import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../services/local_api_server.dart';

// ─── Core Services ────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiClient(prefs);
});

final localDbServiceProvider = Provider<LocalDbService>((ref) {
  return LocalDbService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final localDb = ref.watch(localDbServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final service = SyncService(localDb: localDb, apiClient: apiClient);
  ref.onDispose(service.dispose);
  return service;
});

final localApiServerProvider = Provider<LocalApiServer>((ref) {
  final db = ref.watch(localDbServiceProvider);
  final server = LocalApiServer(ref, db);
  ref.onDispose(server.stop);
  return server;
});

final localIpsProvider = FutureProvider<List<String>>((ref) async {
  final List<String> ips = [];
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        final ip = addr.address;
        if (!ip.startsWith('127.') && ip != '0.0.0.0') {
          ips.add(ip);
        }
      }
    }
  } catch (_) {}
  return ips;
});

