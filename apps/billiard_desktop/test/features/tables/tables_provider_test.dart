import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiard_desktop/features/tables/tables_provider.dart';

void main() {
  group('TablesNotifier', () {
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

    test('initializes with 4 mock tables', () {
      final state = container.read(tablesProvider);
      expect(state.tables.length, 4);
    });

    test('all tables start as idle', () {
      final state = container.read(tablesProvider);
      final allIdle = state.tables.every((t) => t.status == 'idle');
      expect(allIdle, isTrue);
    });

    test('selectTable updates selectedTableId', () {
      container.read(tablesProvider.notifier).selectTable('t-3');
      final state = container.read(tablesProvider);
      expect(state.selectedTableId, 't-3');
    });

    test('toggleSimulator updates useSimulator flag', () {
      container.read(tablesProvider.notifier).toggleSimulator(false);
      expect(container.read(tablesProvider).useSimulator, isFalse);

      container.read(tablesProvider.notifier).toggleSimulator(true);
      expect(container.read(tablesProvider).useSimulator, isTrue);
    });

    test('addProductToTable adds item', () {
      // First activate a table with mock
      final notifier = container.read(tablesProvider.notifier);
      // Manually set table orders via adding product
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });

      final orders = container.read(tablesProvider).tableOrders['t-1'] ?? [];
      expect(orders.length, 1);
      expect(orders.first['qty'], 2);
    });

    test('addProductToTable accumulates qty for same product', () {
      final notifier = container.read(tablesProvider.notifier);
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 1,
      });

      final orders = container.read(tablesProvider).tableOrders['t-1'] ?? [];
      expect(orders.length, 1);
      expect(orders.first['qty'], 3); // 2 + 1
    });

    test('removeProductFromTable removes item', () {
      final notifier = container.read(tablesProvider.notifier);
      notifier.addProductToTable('t-2', {
        'product_id': 'p-5',
        'name': 'Red Bull',
        'price': 25000.0,
        'qty': 1,
      });
      expect(
          (container.read(tablesProvider).tableOrders['t-2'] ?? []).length, 1);

      notifier.removeProductFromTable('t-2', 'p-5');
      expect(
          (container.read(tablesProvider).tableOrders['t-2'] ?? []).length, 0);
    });

    test('setTableMaintenance updates status', () {
      container.read(tablesProvider.notifier).setTableMaintenance('t-3', true);
      final table =
          container.read(tablesProvider).tables.firstWhere((t) => t.id == 't-3');
      expect(table.status, 'maintenance');

      container.read(tablesProvider.notifier).setTableMaintenance('t-3', false);
      final restored =
          container.read(tablesProvider).tables.firstWhere((t) => t.id == 't-3');
      expect(restored.status, 'idle');
    });

    test('playDuration returns zero for idle table', () {
      final state = container.read(tablesProvider);
      expect(state.playDuration('t-1'), Duration.zero);
    });

    test('activeTablesCountProvider returns 0 initially', () {
      final count = container.read(activeTablesCountProvider);
      expect(count, 0);
    });

    test('activateTable in simulator mode changes status to active', () async {
      await container
          .read(tablesProvider.notifier)
          .activateTable('t-1');

      final state = container.read(tablesProvider);
      final table = state.tables.firstWhere((t) => t.id == 't-1');
      expect(table.status, 'active');
      expect(state.tableStartTimes.containsKey('t-1'), isTrue);
      expect(container.read(activeTablesCountProvider), 1);
    });

    test('activateTable returns false if real IoT connection fails', () async {
      final localContainer = ProviderContainer(
        overrides: [
          tablesProvider.overrideWith((ref) => TablesNotifier(
                localDb: null,
                apiClient: null,
                syncService: null,
              )),
        ],
      );
      localContainer.read(tablesProvider.notifier).toggleSimulator(false);

      final ok = await localContainer
          .read(tablesProvider.notifier)
          .activateTable('t-1');
      expect(ok, isFalse);
      
      final state = localContainer.read(tablesProvider);
      final table = state.tables.firstWhere((t) => t.id == 't-1');
      expect(table.status, 'idle');
      localContainer.dispose();
    });

    test('activateTable with ignoreIotError=true succeeds even if real IoT connection fails', () async {
      final localContainer = ProviderContainer(
        overrides: [
          tablesProvider.overrideWith((ref) => TablesNotifier(
                localDb: null,
                apiClient: null,
                syncService: null,
              )),
        ],
      );
      localContainer.read(tablesProvider.notifier).toggleSimulator(false);

      final ok = await localContainer
          .read(tablesProvider.notifier)
          .activateTable('t-1', ignoreIotError: true);
      expect(ok, isTrue);

      final state = localContainer.read(tablesProvider);
      final table = state.tables.firstWhere((t) => t.id == 't-1');
      expect(table.status, 'active');
      localContainer.dispose();
    });

    test('deactivateTable resets table to idle', () async {
      final notifier = container.read(tablesProvider.notifier);
      await notifier.activateTable('t-2');
      expect(container.read(tablesProvider).tables
          .firstWhere((t) => t.id == 't-2').status, 'active');

      await notifier.deactivateTable('t-2');
      final table = container.read(tablesProvider).tables
          .firstWhere((t) => t.id == 't-2');
      expect(table.status, 'idle');
      expect(table.currentOrderId, isNull);
    });

    test('transferTable transfers time, orders, discount and member', () async {
      final notifier = container.read(tablesProvider.notifier);
      
      // Activate source table t-1
      await notifier.activateTable('t-1');
      
      // Add orders, discounts, member to t-1
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });
      notifier.applyDiscount('t-1', 10.0);
      notifier.applyMember('t-1', {
        'id': 'm-1',
        'full_name': 'Nguyễn Văn Hùng',
        'discount': 5.0,
      });
      
      final stateBefore = container.read(tablesProvider);
      final t1StartTime = stateBefore.tableStartTimes['t-1'];
      expect(t1StartTime, isNotNull);
      expect(stateBefore.tableOrders['t-1']!.length, 1);
      expect(stateBefore.tableDiscounts['t-1'], 10.0);
      expect(stateBefore.tableMembers['t-1']!['full_name'], 'Nguyễn Văn Hùng');
      
      // Transfer t-1 to t-2
      final success = await notifier.transferTable('t-1', 't-2');
      expect(success, isTrue);
      
      final stateAfter = container.read(tablesProvider);
      expect(stateAfter.tables.firstWhere((t) => t.id == 't-1').status, 'idle');
      expect(stateAfter.tables.firstWhere((t) => t.id == 't-2').status, 'active');
      
      expect(stateAfter.tableStartTimes.containsKey('t-1'), isFalse);
      expect(stateAfter.tableStartTimes['t-2'], t1StartTime);
      
      expect(stateAfter.tableOrders.containsKey('t-1'), isFalse);
      expect(stateAfter.tableOrders['t-2']!.length, 1);
      expect(stateAfter.tableOrders['t-2']!.first['product_id'], 'p-1');
      
      expect(stateAfter.tableDiscounts.containsKey('t-1'), isFalse);
      expect(stateAfter.tableDiscounts['t-2'], 10.0);
      
      expect(stateAfter.tableMembers.containsKey('t-1'), isFalse);
      expect(stateAfter.tableMembers['t-2']!['full_name'], 'Nguyễn Văn Hùng');
    });

    test('mergeTable calculates play cost and merges orders', () async {
      final notifier = container.read(tablesProvider.notifier);
      
      // Activate source t-1 and target t-2
      await notifier.activateTable('t-1');
      await notifier.activateTable('t-2');
      
      // Set start time of t-1 to 1 hour ago so play cost > 0 without needing Future.delayed
      final stateBefore = container.read(tablesProvider);
      final updatedStartTimes = Map<String, DateTime>.from(stateBefore.tableStartTimes);
      updatedStartTimes['t-1'] = DateTime.now().subtract(const Duration(hours: 1));
      notifier.state = stateBefore.copyWith(tableStartTimes: updatedStartTimes);
      
      // Add items to t-1
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });
      // Add items to t-2
      notifier.addProductToTable('t-2', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 1,
      });
      notifier.addProductToTable('t-2', {
        'product_id': 'p-2',
        'name': 'Bánh mì',
        'price': 20000.0,
        'qty': 1,
      });
      
      // Merge t-1 into t-2
      final success = await notifier.mergeTable('t-1', 't-2');
      expect(success, isTrue);
      
      final state = container.read(tablesProvider);
      expect(state.tables.firstWhere((t) => t.id == 't-1').status, 'idle');
      expect(state.tables.firstWhere((t) => t.id == 't-2').status, 'active');
      
      final targetOrders = state.tableOrders['t-2']!;
      expect(targetOrders.length, 2);
      
      final stingDau = targetOrders.firstWhere((item) => item['product_id'] == 'p-1');
      expect(stingDau['qty'], 3);
      
      final banhMi = targetOrders.firstWhere((item) => item['product_id'] == 'p-2');
      expect(banhMi['qty'], 1);
      
      expect(state.tableExtraPlayAmounts['t-2'], greaterThan(0.0));
      expect(state.tableNotes['t-2'], contains('Gộp từ Bàn 01 (Pool)'));
    });

    test('deactivateTableAndFreezeInvoice freezes table session into unpaidInvoices', () async {
      final notifier = container.read(tablesProvider.notifier);
      await notifier.activateTable('t-1');
      
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });
      notifier.applyDiscount('t-1', 10.0);
      notifier.applyMember('t-1', {
        'id': 'm-1',
        'full_name': 'Nguyễn Văn Hùng',
        'discount': 5.0,
      });

      final success = await notifier.deactivateTableAndFreezeInvoice('t-1');
      expect(success, isTrue);

      final state = container.read(tablesProvider);
      expect(state.tables.firstWhere((t) => t.id == 't-1').status, 'idle');
      expect(state.unpaidInvoices.length, 1);
      
      final inv = state.unpaidInvoices.first;
      expect(inv.tableId, 't-1');
      expect(inv.products.length, 1);
      expect(inv.products.first['product_id'], 'p-1');
      expect(inv.manualDiscountPercent, 10.0);
      expect(inv.member?['full_name'], 'Nguyễn Văn Hùng');
    });

    test('transferUnpaidInvoiceToTable reactivates idle table with unpaid invoice state', () async {
      final notifier = container.read(tablesProvider.notifier);
      
      // Setup unpaid invoice
      await notifier.activateTable('t-1');
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });
      notifier.applyDiscount('t-1', 10.0);
      await notifier.deactivateTableAndFreezeInvoice('t-1');

      final stateBefore = container.read(tablesProvider);
      expect(stateBefore.unpaidInvoices.length, 1);
      final invoiceId = stateBefore.unpaidInvoices.first.id;

      // Transfer unpaid invoice to t-2
      final success = await notifier.transferUnpaidInvoiceToTable(invoiceId, 't-2');
      expect(success, isTrue);

      final stateAfter = container.read(tablesProvider);
      expect(stateAfter.unpaidInvoices.isEmpty, isTrue);
      expect(stateAfter.tables.firstWhere((t) => t.id == 't-2').status, 'active');
      expect(stateAfter.tableOrders['t-2']!.length, 1);
      expect(stateAfter.tableOrders['t-2']!.first['product_id'], 'p-1');
      expect(stateAfter.tableDiscounts['t-2'], 10.0);
    });

    test('mergeUnpaidInvoiceToTable merges unpaid invoice orders into active table', () async {
      final notifier = container.read(tablesProvider.notifier);
      
      // Setup unpaid invoice
      await notifier.activateTable('t-1');
      notifier.addProductToTable('t-1', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 2,
      });
      await notifier.deactivateTableAndFreezeInvoice('t-1');

      final stateBefore = container.read(tablesProvider);
      expect(stateBefore.unpaidInvoices.length, 1);
      final invoiceId = stateBefore.unpaidInvoices.first.id;

      // Setup active target table t-2
      await notifier.activateTable('t-2');
      notifier.addProductToTable('t-2', {
        'product_id': 'p-1',
        'name': 'Sting Dâu',
        'price': 15000.0,
        'qty': 1,
      });

      // Merge unpaid invoice into t-2
      final success = await notifier.mergeUnpaidInvoiceToTable(invoiceId, 't-2');
      expect(success, isTrue);

      final stateAfter = container.read(tablesProvider);
      expect(stateAfter.unpaidInvoices.isEmpty, isTrue);
      expect(stateAfter.tables.firstWhere((t) => t.id == 't-2').status, 'active');
      
      final targetOrders = stateAfter.tableOrders['t-2']!;
      final stingDau = targetOrders.firstWhere((item) => item['product_id'] == 'p-1');
      expect(stingDau['qty'], 3); // 2 from unpaid + 1 from active t-2
      
      expect(stateAfter.tableExtraPlayAmounts['t-2'], greaterThan(0.0));
      expect(stateAfter.tableNotes['t-2'], contains('Gộp từ Bàn 01 (Pool)'));
    });
  });
}
