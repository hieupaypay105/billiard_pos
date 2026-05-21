import 'dart:async';
import 'package:core_shared/core_shared.dart';
import 'billiard_iot_controller.dart';

class SimulatedBilliardIoTController implements BilliardIoTController {
  IotConfigModel? _config;
  bool _isConnected = false;
  bool _isOn = false;

  final _statusController = StreamController<bool>.broadcast();
  final _logController = StreamController<String>.broadcast();

  SimulatedBilliardIoTController();

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logController.add('[$timestamp] $message');
  }

  /// Helper to format hex strings nicely, e.g. "01050000FF008C3A" -> "01 05 00 00 FF 00 8C 3A"
  String _formatHex(String hex) {
    final buffer = StringBuffer();
    for (int i = 0; i < hex.length; i += 2) {
      if (i > 0) buffer.write(' ');
      if (i + 1 < hex.length) {
        buffer.write(hex.substring(i, i + 2).toUpperCase());
      } else {
        buffer.write(hex.substring(i).toUpperCase());
      }
    }
    return buffer.toString();
  }

  @override
  Future<bool> connect(IotConfigModel config) async {
    if (_isConnected) {
      _log('Already connected to table ${config.tableId}');
      return true;
    }

    _config = config;
    final connInfo = config.connectionType == 'serial'
        ? 'COM Port: ${config.port ?? "COM1"}'
        : 'TCP/IP: ${config.ipAddress ?? "192.168.1.100"}:${config.port ?? "8080"}';

    _log('Connecting to Table ID: ${config.tableId} via protocol: ${config.connectionType.toUpperCase()} ($connInfo)...');
    
    // Simulate connection delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isConnected = true;
    _log('Connected successfully to Table ID: ${config.tableId}');
    return true;
  }

  @override
  Future<bool> disconnect() async {
    if (!_isConnected) {
      return true;
    }

    _log('Disconnecting from Table ID: ${_config?.tableId ?? "Unknown"}...');
    await Future.delayed(const Duration(milliseconds: 200));

    _isConnected = false;
    if (_isOn) {
      _isOn = false;
      _statusController.add(false);
    }
    _log('Disconnected successfully.');
    return true;
  }

  @override
  Future<bool> turnOn() async {
    if (!_isConnected || _config == null) {
      _log('ERROR: Cannot turn ON. Controller is not connected.');
      return false;
    }

    final hexCmd = _formatHex(_config!.commandOn);
    _log('TX: Sending Command -> $hexCmd');

    // Simulate response delay
    await Future.delayed(const Duration(milliseconds: 300));

    _log('RX: Received ACK from Relay Channel ${_config!.relayChannel}');
    _isOn = true;
    _statusController.add(true);
    _log('Table Light turned ON (Relay State changed).');
    return true;
  }

  @override
  Future<bool> turnOff() async {
    if (!_isConnected || _config == null) {
      _log('ERROR: Cannot turn OFF. Controller is not connected.');
      return false;
    }

    final hexCmd = _formatHex(_config!.commandOff);
    _log('TX: Sending Command -> $hexCmd');

    // Simulate response delay
    await Future.delayed(const Duration(milliseconds: 300));

    _log('RX: Received ACK from Relay Channel ${_config!.relayChannel}');
    _isOn = false;
    _statusController.add(false);
    _log('Table Light turned OFF (Relay State changed).');
    return true;
  }

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isOn => _isOn;

  @override
  Stream<bool> get statusStream => _statusController.stream;

  @override
  Stream<String> get logStream => _logController.stream;

  /// Closes stream controllers when no longer needed
  void dispose() {
    _statusController.close();
    _logController.close();
  }
}
