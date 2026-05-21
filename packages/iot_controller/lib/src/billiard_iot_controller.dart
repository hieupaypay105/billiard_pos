import 'package:core_shared/core_shared.dart';

abstract class BilliardIoTController {
  /// Connects to the relay device using the configuration provided.
  Future<bool> connect(IotConfigModel config);

  /// Disconnects from the relay device.
  Future<bool> disconnect();

  /// Sends the Hex command to turn the relay ON.
  Future<bool> turnOn();

  /// Sends the Hex command to turn the relay OFF.
  Future<bool> turnOff();

  /// Whether the controller is currently connected to the hardware/simulated socket.
  bool get isConnected;

  /// Whether the relay light is currently turned on.
  bool get isOn;

  /// Stream notifying subscribers about the light status changes (true = ON, false = OFF).
  Stream<bool> get statusStream;

  /// Stream emitting diagnostic and HEX communication log events for display on consoles.
  Stream<String> get logStream;
}
