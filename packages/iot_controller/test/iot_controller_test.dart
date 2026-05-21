import 'package:flutter_test/flutter_test.dart';
import 'package:core_shared/core_shared.dart';
import 'package:iot_controller/iot_controller.dart';

void main() {
  group('SimulatedBilliardIoTController Tests', () {
    late SimulatedBilliardIoTController controller;
    late IotConfigModel mockConfig;

    setUp(() {
      controller = SimulatedBilliardIoTController();
      mockConfig = const IotConfigModel(
        id: 1,
        tableId: 't-1',
        connectionType: 'serial',
        port: 'COM1',
        relayChannel: 1,
        commandOn: '01050000FF008C3A',
        commandOff: '010500000000CDCA',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial State is Disconnected and Off', () {
      expect(controller.isConnected, isFalse);
      expect(controller.isOn, isFalse);
    });

    test('Connect establishes connection successfully', () async {
      final success = await controller.connect(mockConfig);
      expect(success, isTrue);
      expect(controller.isConnected, isTrue);
    });

    test('TurnOn fails if not connected', () async {
      final success = await controller.turnOn();
      expect(success, isFalse);
      expect(controller.isOn, isFalse);
    });

    test('TurnOn and TurnOff updates state and emits stream events when connected', () async {
      await controller.connect(mockConfig);

      // Verify TurnOn
      final statusList = <bool>[];
      final statusSub = controller.statusStream.listen((status) {
        statusList.add(status);
      });

      final turnOnSuccess = await controller.turnOn();
      expect(turnOnSuccess, isTrue);
      expect(controller.isOn, isTrue);

      // Verify TurnOff
      final turnOffSuccess = await controller.turnOff();
      expect(turnOffSuccess, isTrue);
      expect(controller.isOn, isFalse);

      await Future.delayed(const Duration(milliseconds: 10)); // allow microtasks to finish
      expect(statusList, [true, false]);
      await statusSub.cancel();
    });

    test('Disconnect resets connection and turns off', () async {
      await controller.connect(mockConfig);
      await controller.turnOn();
      expect(controller.isOn, isTrue);

      await controller.disconnect();
      expect(controller.isConnected, isFalse);
      expect(controller.isOn, isFalse);
    });
  });
}
