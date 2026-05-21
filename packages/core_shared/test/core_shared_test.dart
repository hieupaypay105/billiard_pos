import 'package:flutter_test/flutter_test.dart';
import 'package:core_shared/core_shared.dart';

void main() {
  group('Database Models Tests', () {
    test('UserModel JSON Serialization & Equality', () {
      final user = UserModel(
        id: 'u-123',
        username: 'test_cashier',
        passwordHash: 'hashed_pw',
        displayName: 'Test Cashier',
        role: 'cashier',
        phoneNumber: '0987654321',
        isActive: true,
        createdAt: DateTime.parse('2026-05-21T12:00:00Z'),
      );

      final json = user.toJson();
      expect(json['id'], 'u-123');
      expect(json['username'], 'test_cashier');
      expect(json['role'], 'cashier');

      final parsedUser = UserModel.fromJson(json);
      expect(parsedUser, user);
      expect(parsedUser.displayName, 'Test Cashier');
    });

    test('TableModel JSON Serialization & Equality', () {
      final table = TableModel(
        id: 't-1',
        tableName: 'Bàn 01 (Pool)',
        areaId: 1,
        tableTypeId: 2,
        status: 'active',
        currentOrderId: 'ord-999',
      );

      final json = table.toJson();
      expect(json['id'], 't-1');
      expect(json['table_name'], 'Bàn 01 (Pool)');
      expect(json['status'], 'active');

      final parsedTable = TableModel.fromJson(json);
      expect(parsedTable, table);
    });

    test('TablePriceModel JSON parsing with days_of_week array and string', () {
      final jsonWithArray = {
        'id': 5,
        'table_type_id': 2,
        'price_per_hour': 90000.0,
        'start_hour': '08:00:00',
        'end_hour': '17:00:00',
        'days_of_week': [1, 2, 3, 4, 5],
        'is_active': true,
        'priority': 1,
      };

      final price1 = TablePriceModel.fromJson(jsonWithArray);
      expect(price1.pricePerHour, 90000.0);
      expect(price1.daysOfWeek, [1, 2, 3, 4, 5]);

      final jsonWithString = {
        'id': 5,
        'table_type_id': 2,
        'price_per_hour': 90000.0,
        'start_hour': '08:00:00',
        'end_hour': '17:00:00',
        'days_of_week': '[6,7]',
        'is_active': true,
        'priority': 1,
      };

      final price2 = TablePriceModel.fromJson(jsonWithString);
      expect(price2.daysOfWeek, [6, 7]);
    });
  });
}
