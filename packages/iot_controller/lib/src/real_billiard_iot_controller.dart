import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:core_shared/core_shared.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'billiard_iot_controller.dart';

class RealBilliardIoTController implements BilliardIoTController {
  IotConfigModel? _config;
  bool _isConnected = false;
  bool _isOn = false;
  Socket? _tcpSocket;
  SerialPort? _serialPort;
  SerialPortReader? _serialPortReader;
  StreamSubscription<Uint8List>? _serialPortSubscription;

  final _statusController = StreamController<bool>.broadcast();
  final _logController = StreamController<String>.broadcast();

  RealBilliardIoTController();

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    if (!_logController.isClosed) {
      _logController.add('[$timestamp] $message');
    }
  }

  List<int> _hexToBytes(String hex) {
    // Strip space or non-hex characters
    final cleanHex = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i + 1 < cleanHex.length) {
        bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
      }
    }
    return bytes;
  }

  String _formatHex(String hex) {
    final cleanHex = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i > 0) buffer.write(' ');
      if (i + 1 < cleanHex.length) {
        buffer.write(cleanHex.substring(i, i + 2));
      } else {
        buffer.write(cleanHex.substring(i));
      }
    }
    return buffer.toString();
  }

  @override
  Future<bool> connect(IotConfigModel config) async {
    if (_isConnected) {
      return true;
    }

    _config = config;
    _log('Attempting Real Connection to Table ${config.tableId} via: ${config.connectionType.toUpperCase()}...');

    if (config.connectionType == 'tcp_ip') {
      final ip = config.ipAddress ?? '192.168.1.100';
      final port = int.tryParse(config.port ?? '8080') ?? 8080;
      _log('Connecting to TCP/IP Relay Module at $ip:$port (timeout 5s)...');

      try {
        _tcpSocket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
        _isConnected = true;

        // Set up socket listener
        _tcpSocket!.listen(
          (List<int> data) {
            final hexResp = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
            _log('RX Socket: Received bytes -> $hexResp');
          },
          onError: (Object error) {
            _log('ERROR Socket: $error');
            disconnect();
          },
          onDone: () {
            _log('Socket connection closed by remote device.');
            disconnect();
          },
        );

        _log('Connected successfully to TCP/IP Relay.');
        return true;
      } catch (e) {
        _log('ERROR Socket Connection Failed: $e');
        _isConnected = false;
        return false;
      }
    } else if (config.connectionType == 'serial') {
      var comPort = config.port ?? 'COM3';
      if (!Platform.isWindows && !comPort.startsWith('/dev/')) {
        comPort = '/dev/$comPort';
      }
      _log('Connecting to Serial/RS485 COM Port $comPort...');
      
      try {
        final available = SerialPort.availablePorts;
        _log('Available system serial ports: $available');
        
        _serialPort = SerialPort(comPort);
        if (!_serialPort!.openReadWrite()) {
          final err = SerialPort.lastError;
          _log('ERROR Serial Open: Failed to open $comPort. Error: $err');
          _serialPort = null;
          _isConnected = false;
          return false;
        }

        // Apply standard configs
        final config = SerialPortConfig();
        config.baudRate = 9600;
        config.bits = 8;
        config.stopBits = 1;
        config.parity = SerialPortParity.none;
        _serialPort!.config = config;
        // Note: Do not call config.dispose() here as _serialPort takes ownership
        // and will automatically dispose of it when _serialPort.dispose() is called.
        
        _isConnected = true;
        _log('Serial COM ($comPort) connected successfully.');
        
        // Listen to reader
        _serialPortReader = SerialPortReader(_serialPort!);
        _serialPortSubscription = _serialPortReader!.stream.listen(
          (Uint8List data) {
            final hexResp = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
            _log('RX Serial: Received bytes -> $hexResp');
          },
          onError: (Object error) {
            _log('ERROR Serial Reader: $error');
            disconnect();
          },
        );
        return true;
      } catch (e) {
        _log('ERROR Serial Init: $e');
        _serialPort = null;
        _isConnected = false;
        return false;
      }
    } else {
      _log('ERROR: Unsupported connection type ${config.connectionType}');
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    if (!_isConnected) {
      return true;
    }

    _log('Disconnecting table IoT controller...');
    
    if (_tcpSocket != null) {
      try {
        await _tcpSocket!.close();
      } catch (_) {}
      _tcpSocket = null;
    }

    if (_serialPortSubscription != null) {
      try {
        await _serialPortSubscription!.cancel();
      } catch (_) {}
      _serialPortSubscription = null;
    }

    if (_serialPortReader != null) {
      try {
        _serialPortReader!.close();
      } catch (_) {}
      _serialPortReader = null;
    }

    // Give a brief delay for the background port reader thread to shut down cleanly
    await Future.delayed(const Duration(milliseconds: 100));

    if (_serialPort != null) {
      try {
        _serialPort!.close();
        _serialPort!.dispose();
      } catch (_) {}
      _serialPort = null;
    }

    _isConnected = false;
    if (_isOn) {
      _isOn = false;
      if (!_statusController.isClosed) {
        _statusController.add(false);
      }
    }
    
    _log('Disconnected.');
    return true;
  }

  @override
  Future<bool> turnOn() async {
    if (!_isConnected || _config == null) {
      _log('ERROR: Cannot send turnOn command, controller is disconnected.');
      return false;
    }

    final cmd = _config!.commandOn;
    final cmdBytes = _hexToBytes(cmd);

    _log('TX Command ON: Hex [${_formatHex(cmd)}] Bytes: $cmdBytes');

    if (_config!.connectionType == 'tcp_ip' && _tcpSocket != null) {
      try {
        _tcpSocket!.add(cmdBytes);
        await _tcpSocket!.flush();
        _isOn = true;
        _statusController.add(true);
        return true;
      } catch (e) {
        _log('ERROR: Failed to write command to socket: $e');
        return false;
      }
    } else if (_config!.connectionType == 'serial') {
      if (_serialPort == null) {
        _log('ERROR Serial: Port is not opened.');
        return false;
      }
      try {
        final bytesWritten = _serialPort!.write(Uint8List.fromList(cmdBytes));
        _log('Serial TX: Sent $bytesWritten bytes.');
        _isOn = true;
        _statusController.add(true);
        return true;
      } catch (e) {
        _log('ERROR Serial Write: $e');
        return false;
      }
    }

    return false;
  }

  @override
  Future<bool> turnOff() async {
    if (!_isConnected || _config == null) {
      _log('ERROR: Cannot send turnOff command, controller is disconnected.');
      return false;
    }

    final cmd = _config!.commandOff;
    final cmdBytes = _hexToBytes(cmd);

    _log('TX Command OFF: Hex [${_formatHex(cmd)}] Bytes: $cmdBytes');

    if (_config!.connectionType == 'tcp_ip' && _tcpSocket != null) {
      try {
        _tcpSocket!.add(cmdBytes);
        await _tcpSocket!.flush();
        _isOn = false;
        _statusController.add(false);
        return true;
      } catch (e) {
        _log('ERROR: Failed to write command to socket: $e');
        return false;
      }
    } else if (_config!.connectionType == 'serial') {
      if (_serialPort == null) {
        _log('ERROR Serial: Port is not opened.');
        return false;
      }
      try {
        final bytesWritten = _serialPort!.write(Uint8List.fromList(cmdBytes));
        _log('Serial TX: Sent $bytesWritten bytes.');
        _isOn = false;
        _statusController.add(false);
        return true;
      } catch (e) {
        _log('ERROR Serial Write: $e');
        return false;
      }
    }

    return false;
  }

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isOn => _isOn;

  @override
  Stream<bool> get statusStream => _statusController.stream;

  @override
  Stream<String> get logStream => _logController.stream;

  void dispose() {
    _serialPortSubscription?.cancel();
    _serialPortReader?.close();
    if (_serialPort != null) {
      try {
        _serialPort!.close();
        _serialPort!.dispose();
      } catch (_) {}
      _serialPort = null;
    }
    _tcpSocket?.close();
    _statusController.close();
    _logController.close();
    _isConnected = false;
    _isOn = false;
  }
}
