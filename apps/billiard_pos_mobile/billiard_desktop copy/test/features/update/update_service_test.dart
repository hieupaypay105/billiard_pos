import 'package:flutter_test/flutter_test.dart';
import 'package:billiard_desktop/features/update/update_service.dart';

void main() {
  group('UpdateService Version Comparison Tests', () {
    late UpdateService updateService;

    setUp(() {
      updateService = UpdateService();
    });

    test('isNewerVersion returns true when latest version is newer', () {
      expect(updateService.isNewerVersion('1.0.0', '1.0.1'), isTrue);
      expect(updateService.isNewerVersion('1.0.0', '1.1.0'), isTrue);
      expect(updateService.isNewerVersion('1.0.0', '2.0.0'), isTrue);
      expect(updateService.isNewerVersion('1.0.0', '1.0.0.1'), isTrue);
    });

    test('isNewerVersion returns false when latest version is older or same', () {
      expect(updateService.isNewerVersion('1.0.1', '1.0.0'), isFalse);
      expect(updateService.isNewerVersion('1.1.0', '1.0.0'), isFalse);
      expect(updateService.isNewerVersion('2.0.0', '1.0.0'), isFalse);
      expect(updateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(updateService.isNewerVersion('1.0.0.1', '1.0.0'), isFalse);
    });

    test('isNewerVersion handles invalid inputs gracefully', () {
      expect(updateService.isNewerVersion('1.0.0', 'abc'), isFalse);
      expect(updateService.isNewerVersion('abc', '1.0.0'), isFalse);
      expect(updateService.isNewerVersion('', ''), isFalse);
    });
  });
}
