import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

// ─── Core Services ────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
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
