import 'package:flutter_test/flutter_test.dart';
import 'package:core_shared/core_shared.dart';

void main() {
  group('OrderModel', () {
    test('fromJson creates correct model', () {
      final json = {
        'id': 'order-123',
        'table_id': 'table-1',
        'member_id': null,
        'shift_id': 'shift-1',
        'status': 'active',
        'start_time': '2026-05-22T08:30:00.000',
        'end_time': null,
        'total_play_time_minutes': 0,
        'total_play_time_amount': 0.0,
        'total_product_amount': 0.0,
        'discount_amount': 0.0,
        'tax_amount': 0.0,
        'total_amount': 0.0,
        'payment_method': null,
        'created_by': 'user-1',
        'closed_by': null,
        'created_at': '2026-05-22T08:30:00.000',
        'updated_at': null,
        'note': 'Khách nợ',
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 'order-123');
      expect(order.tableId, 'table-1');
      expect(order.status, 'active');
      expect(order.memberId, isNull);
      expect(order.totalAmount, 0.0);
      expect(order.note, 'Khách nợ');
    });

    test('toJson produces correct map', () {
      final order = OrderModel(
        id: 'order-456',
        tableId: 'table-2',
        shiftId: 'shift-2',
        startTime: DateTime(2026, 5, 22, 9, 0, 0),
        createdBy: 'user-1',
        status: 'paid',
        totalAmount: 250000.0,
        paymentMethod: 'cash',
      );

      final json = order.toJson();

      expect(json['id'], 'order-456');
      expect(json['status'], 'paid');
      expect(json['total_amount'], 250000.0);
      expect(json['payment_method'], 'cash');
    });

    test('copyWith updates fields correctly', () {
      final original = OrderModel(
        id: 'order-789',
        tableId: 'table-3',
        shiftId: 'shift-3',
        startTime: DateTime(2026, 5, 22, 10, 0),
        createdBy: 'user-2',
      );

      final updated = original.copyWith(
        status: 'paid',
        totalAmount: 500000.0,
        paymentMethod: 'transfer',
        endTime: DateTime(2026, 5, 22, 12, 0),
      );

      expect(updated.id, 'order-789'); // unchanged
      expect(updated.status, 'paid');
      expect(updated.totalAmount, 500000.0);
      expect(updated.paymentMethod, 'transfer');
      expect(updated.endTime, isNotNull);
    });

    test('default values are correct', () {
      final order = OrderModel(
        id: 'order-default',
        tableId: 'table-default',
        shiftId: 'shift-default',
        startTime: DateTime.now(),
        createdBy: 'user-1',
      );

      expect(order.status, 'active');
      expect(order.totalAmount, 0.0);
      expect(order.discountAmount, 0.0);
      expect(order.taxAmount, 0.0);
      expect(order.paymentMethod, isNull);
      expect(order.memberId, isNull);
    });

    test('Equatable props comparison works', () {
      final t = DateTime(2026, 5, 22);
      final o1 = OrderModel(
          id: 'same', tableId: 't1', shiftId: 's1',
          startTime: t, createdBy: 'u1');
      final o2 = OrderModel(
          id: 'same', tableId: 't1', shiftId: 's1',
          startTime: t, createdBy: 'u1');
      expect(o1, equals(o2));
    });
  });

  group('UserModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'user-1',
        'username': 'cashier01',
        'password_hash': 'hashed',
        'display_name': 'Nguyễn Thu Ngân',
        'role': 'cashier',
        'phone_number': '0901234567',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00',
        'updated_at': null,
      };

      final user = UserModel.fromJson(json);
      expect(user.username, 'cashier01');
      expect(user.role, 'cashier');
      expect(user.isActive, true);
      expect(user.displayName, 'Nguyễn Thu Ngân');
    });
  });

  group('TableModel', () {
    test('default status is idle', () {
      const table = TableModel(
          id: 't-1', tableName: 'Bàn 01', areaId: 1, tableTypeId: 1);
      expect(table.status, 'idle');
    });

    test('copyWith status update', () {
      const table = TableModel(
          id: 't-1', tableName: 'Bàn 01', areaId: 1, tableTypeId: 1);
      final active = table.copyWith(status: 'active', currentOrderId: 'ord-1');
      expect(active.status, 'active');
      expect(active.currentOrderId, 'ord-1');
      expect(active.tableName, 'Bàn 01'); // unchanged
    });
  });
}
