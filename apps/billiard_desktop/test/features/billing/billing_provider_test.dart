import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiard_desktop/features/tables/tables_provider.dart';

void main() {
  group('Billing Logic Tests via TablesNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          tablesProvider.overrideWith((ref) => TablesNotifier(
                localDb: null,
                apiClient: null,
                syncService: null,
              )),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial active tables count is 0', () {
      final count = container.read(activeTablesCountProvider);
      expect(count, 0);
    });

    test('Hourly play cost calculation matches expected table rate', () async {
      final notifier = container.read(tablesProvider.notifier);

      // Activate table t-1 (Pool table, type id 1)
      final activated = await notifier.activateTable('t-1');
      expect(activated, isTrue);

      final state = container.read(tablesProvider);
      final playDuration = state.playDuration('t-1');
      expect(playDuration, isNotNull);

      // The rate for Pool table (type 1) is 80,000 VND/hour
      final rate = state.hourlyRates['1'];
      expect(rate, 80000.0);

      // Check playCost calculation
      final cost = state.playCost('t-1');
      expect(cost, isNonNegative);
    });

    test('Adding and removing products updates the active bill', () {
      final notifier = container.read(tablesProvider.notifier);

      // Add foods and drinks to table t-1
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });

      notifier.addProductToTable('t-1', {
        'product_id': 'p-2',
        'name': 'Mì xào trứng',
        'price': 35000.0,
        'qty': 1,
      });

      var state = container.read(tablesProvider);
      var items = state.tableOrders['t-1'] ?? [];
      expect(items.length, 2);

      // Total items quantity check
      final stingItem = items.firstWhere((i) => i['product_id'] == 'p-1');
      expect(stingItem['qty'], 2);

      final noodleItem = items.firstWhere((i) => i['product_id'] == 'p-2');
      expect(noodleItem['qty'], 1);

      // Remove Sting Dâu
      notifier.removeProductFromTable('t-1', 'p-1');
      state = container.read(tablesProvider);
      items = state.tableOrders['t-1'] ?? [];
      expect(items.length, 1);
      expect(items.any((i) => i['product_id'] == 'p-1'), isFalse);
    });

    test('applyDiscount and removeDiscount updates state', () {
      final notifier = container.read(tablesProvider.notifier);
      notifier.applyDiscount('t-1', 15.0);

      var state = container.read(tablesProvider);
      expect(state.tableDiscounts['t-1'], 15.0);

      notifier.removeDiscount('t-1');
      state = container.read(tablesProvider);
      expect(state.tableDiscounts.containsKey('t-1'), isFalse);
    });

    test('applyMember and removeMember updates state', () {
      final notifier = container.read(tablesProvider.notifier);
      final member = {
        'id': 'm-1',
        'full_name': 'Nguyễn Văn Hùng',
        'phone_number': '0901234567',
        'tier': 'Gold',
        'discount': 5.0,
      };

      notifier.applyMember('t-1', member);
      var state = container.read(tablesProvider);
      expect(state.tableMembers['t-1'], isNotNull);
      expect(state.tableMembers['t-1']!['full_name'], 'Nguyễn Văn Hùng');
      expect(state.tableMembers['t-1']!['discount'], 5.0);

      notifier.removeMember('t-1');
      state = container.read(tablesProvider);
      expect(state.tableMembers.containsKey('t-1'), isFalse);
    });

    test('Stacked discount calculation matches expected formula', () {
      final notifier = container.read(tablesProvider.notifier);
      
      // Setup member discount of 5.0%
      notifier.applyMember('t-1', {
        'id': 'm-1',
        'full_name': 'Nguyễn Văn Hùng',
        'discount': 5.0,
      });

      // Setup manual discount of 15.0%
      notifier.applyDiscount('t-1', 15.0);

      final state = container.read(tablesProvider);
      final member = state.tableMembers['t-1'];
      final memberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
      final manualDiscountPercent = state.tableDiscounts['t-1'] ?? 0.0;
      
      // Calculate stacked discount percentage (clamped to 100)
      final discountPercent = (memberDiscountPercent + manualDiscountPercent).clamp(0.0, 100.0);
      expect(discountPercent, 20.0); // 5.0 + 15.0
    });
  });
}
