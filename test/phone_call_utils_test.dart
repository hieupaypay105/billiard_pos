import 'package:anholding_app/src/features/khach_hang/presentation/utils/phone_call_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePhoneNumber', () {
    test('returns null for empty input', () {
      expect(normalizePhoneNumber(null), isNull);
      expect(normalizePhoneNumber('   '), isNull);
    });

    test('keeps digits and a leading plus sign', () {
      expect(normalizePhoneNumber('0904 132 611'), '0904132611');
      expect(normalizePhoneNumber('+84 904-132-611'), '+84904132611');
    });

    test('returns null when no digits exist', () {
      expect(normalizePhoneNumber('(+--)'), isNull);
    });
  });
}
