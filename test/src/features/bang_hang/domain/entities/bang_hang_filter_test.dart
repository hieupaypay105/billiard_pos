import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BangHangTab', () {
    test('should construct properly', () {
      const tab = BangHangTab(id: 'tab1', label: 'Tab 1', projectId: 10);
      expect(tab.id, 'tab1');
      expect(tab.label, 'Tab 1');
      expect(tab.projectId, 10);
    });
  });

  group('RangeFilter', () {
    test('isEmpty should return true if both min and max are null', () {
      const filter = RangeFilter();
      expect(filter.isEmpty, isTrue);
    });

    test('isEmpty should return false if min or max is not null', () {
      expect(const RangeFilter(min: 10).isEmpty, isFalse);
      expect(const RangeFilter(max: 20).isEmpty, isFalse);
      expect(const RangeFilter(min: 10, max: 20).isEmpty, isFalse);
    });

    test('toJson should exclude null values and convert to int', () {
      const filter = RangeFilter(min: 10.5, max: 20.9);
      expect(filter.toJson(), {'min': 10, 'max': 20});

      const filter2 = RangeFilter(min: 15.0);
      expect(filter2.toJson(), {'min': 15});

      const filter3 = RangeFilter();
      expect(filter3.toJson(), isEmpty);
    });

    test('copyWith should update fields correctly', () {
      const filter = RangeFilter(min: 10, max: 20);
      
      final updated1 = filter.copyWith(min: 15);
      expect(updated1.min, 15);
      expect(updated1.max, 20);

      final updated2 = filter.copyWith(max: 25);
      expect(updated2.min, 10);
      expect(updated2.max, 25);
    });
  });

  group('BangHangFilter', () {
    test('default constructor should have correct default values', () {
      const filter = BangHangFilter();
      
      expect(filter.projectId, 2);
      expect(filter.area, isEmpty);
      expect(filter.type, isEmpty);
      expect(filter.telesale, isEmpty);
      expect(filter.direction, isEmpty);
      expect(filter.handoverStatus, isEmpty);
      expect(filter.code, isNull);
      expect(filter.price.isEmpty, isTrue);
      expect(filter.tts.isEmpty, isTrue);
      expect(filter.acreage.isEmpty, isTrue);
      expect(filter.page, 1);
      expect(filter.perPage, 50);
    });

    test('toPayload should serialize correctly', () {
      const filter = BangHangFilter(
        projectId: 5,
        area: ['Khu A'],
        type: ['LK'],
        code: 'A1',
        price: RangeFilter(min: 10, max: 20),
        page: 2,
        perPage: 30,
      );

      final payload = filter.toPayload();

      expect(payload['project_id'], 5);
      expect(payload['area'], ['Khu A']);
      expect(payload['type'], ['LK']);
      expect(payload['telesale'], isEmpty);
      expect(payload['direction'], isEmpty);
      expect(payload['handover_status'], isEmpty);
      expect(payload['code'], 'A1');
      expect(payload['price'], {'min': 10, 'max': 20});
      expect(payload['tts'], isNull);
      expect(payload['acreage'], isNull);
      expect(payload['page'], '2');
      expect(payload['per_page'], '30');
    });

    test('toPayload should omit empty ranges and null code', () {
      const filter = BangHangFilter(
        projectId: 5,
        code: '', // should be omitted
      );

      final payload = filter.toPayload();
      
      expect(payload.containsKey('code'), isFalse);
      expect(payload.containsKey('price'), isFalse);
      expect(payload.containsKey('tts'), isFalse);
      expect(payload.containsKey('acreage'), isFalse);
    });

    test('copyWith should update fields correctly', () {
      const filter = BangHangFilter();
      
      final updated = filter.copyWith(
        projectId: 10,
        area: ['Khu B'],
        code: 'B1',
        page: 3,
      );

      expect(updated.projectId, 10);
      expect(updated.area, ['Khu B']);
      expect(updated.code, 'B1');
      expect(updated.page, 3);
      expect(updated.perPage, 50); // unchanged
    });

    test('copyWith should properly handle setting code to null', () {
      const filter = BangHangFilter(code: 'A1');
      
      final updated = filter.copyWith(code: null);
      
      expect(updated.code, isNull);
    });
  });
}
