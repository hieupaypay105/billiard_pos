import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_db_service.dart';
import 'providers.dart';

class DeviceRequest {
  final String deviceId;
  final String deviceName;
  final String os;
  final String ip;

  DeviceRequest({
    required this.deviceId,
    required this.deviceName,
    required this.os,
    required this.ip,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'os': os,
        'ip': ip,
      };
}

class DeviceConnectionState {
  final List<DeviceRequest> pendingRequests;
  final Set<String> approvedDevices;
  final Set<String> deniedDevices;

  DeviceConnectionState({
    this.pendingRequests = const [],
    this.approvedDevices = const {},
    this.deniedDevices = const {},
  });

  DeviceConnectionState copyWith({
    List<DeviceRequest>? pendingRequests,
    Set<String>? approvedDevices,
    Set<String>? deniedDevices,
  }) {
    return DeviceConnectionState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      approvedDevices: approvedDevices ?? this.approvedDevices,
      deniedDevices: deniedDevices ?? this.deniedDevices,
    );
  }
}

class DeviceConnectionNotifier extends StateNotifier<DeviceConnectionState> {
  final LocalDbService _localDb;

  DeviceConnectionNotifier(this._localDb) : super(DeviceConnectionState()) {
    _loadStoredDevices();
  }

  Future<void> _loadStoredDevices() async {
    try {
      final approvedJson = await _localDb.getSetting('desktop_approved_devices');
      final deniedJson = await _localDb.getSetting('desktop_denied_devices');

      final Set<String> approved = approvedJson != null
          ? Set<String>.from(jsonDecode(approvedJson) as List)
          : {};
      final Set<String> denied = deniedJson != null
          ? Set<String>.from(jsonDecode(deniedJson) as List)
          : {};

      state = state.copyWith(approvedDevices: approved, deniedDevices: denied);
    } catch (e) {
      print("Lỗi tải danh sách thiết bị: $e");
    }
  }

  void addRequest(DeviceRequest req) {
    if (state.pendingRequests.any((r) => r.deviceId == req.deviceId)) return;
    state = state.copyWith(
      pendingRequests: [...state.pendingRequests, req],
    );
  }

  Future<void> approveDevice(String deviceId) async {
    final reqs = List<DeviceRequest>.from(state.pendingRequests)
      ..removeWhere((r) => r.deviceId == deviceId);
    final approved = Set<String>.from(state.approvedDevices)..add(deviceId);
    final denied = Set<String>.from(state.deniedDevices)..remove(deviceId);

    state = state.copyWith(
      pendingRequests: reqs,
      approvedDevices: approved,
      deniedDevices: denied,
    );

    await _localDb.setSetting(
        'desktop_approved_devices', jsonEncode(approved.toList()));
    await _localDb.setSetting(
        'desktop_denied_devices', jsonEncode(denied.toList()));
  }

  Future<void> denyDevice(String deviceId) async {
    final reqs = List<DeviceRequest>.from(state.pendingRequests)
      ..removeWhere((r) => r.deviceId == deviceId);
    final approved = Set<String>.from(state.approvedDevices)..remove(deviceId);
    final denied = Set<String>.from(state.deniedDevices)..add(deviceId);

    state = state.copyWith(
      pendingRequests: reqs,
      approvedDevices: approved,
      deniedDevices: denied,
    );

    await _localDb.setSetting(
        'desktop_approved_devices', jsonEncode(approved.toList()));
    await _localDb.setSetting(
        'desktop_denied_devices', jsonEncode(denied.toList()));
  }

  bool isApproved(String deviceId) => state.approvedDevices.contains(deviceId);
  bool isDenied(String deviceId) => state.deniedDevices.contains(deviceId);
}

final deviceConnectionProvider =
    StateNotifierProvider<DeviceConnectionNotifier, DeviceConnectionState>((ref) {
  final db = ref.watch(localDbServiceProvider);
  return DeviceConnectionNotifier(db);
});
