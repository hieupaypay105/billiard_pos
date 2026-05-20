import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KhachHangOptionResponse', () {
    test('fromJson parses region map correctly with string keys', () {
      // Arrange
      final json = {
        'status': ['Mới', 'Đang tiếp cận'],
        'source': {'30': 'Facebook'},
        'project': {'2': 'Quỹ Mới Vin 2'},
        'sale': {'39': 'Đậu Thị Thúy'},
        'atrtibute': {'id': 'ID'},
        'financial_range': {'7-8': '7-8 tỷ'},
        'created_at': {'hom-nay': 'Hôm nay'},
        'filter_saved': [],
        'region': {
          '508': 'Hà Nội',
          '514': 'Thành phố Hồ Chí Minh',
          'invalid': 'Lỗi rác', // Edge case: invalid int key should be skipped
        },
      };

      // Act
      final result = KhachHangOptionResponse.fromJson(json);

      // Assert
      expect(result.region, isA<Map<int, String>>());
      expect(result.region.length, 2);
      expect(result.region[508], 'Hà Nội');
      expect(result.region[514], 'Thành phố Hồ Chí Minh');

      // Additional assertions to ensure other fields are untouched
      expect(result.status.length, 2);
      expect(result.attribute['id'], 'ID');
    });

    test('fromJson handles null or missing region gracefully', () {
      // Arrange
      final json = {
        'status': [],
        'source': {},
        'project': {},
        'sale': {},
        'attribute': {},
        'financial_range': {},
        'created_at': {},
        'filter_saved': [],
        // 'region': null or missing
      };

      // Act
      final result = KhachHangOptionResponse.fromJson(json);

      // Assert
      expect(result.region, isEmpty);
      expect(result.region, isA<Map<int, String>>());
    });
  });
}
