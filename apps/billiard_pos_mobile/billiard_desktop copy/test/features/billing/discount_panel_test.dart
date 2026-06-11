import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiard_desktop/features/tables/tables_provider.dart';
import 'package:billiard_desktop/features/billing/discount_panel.dart';

void main() {
  testWidgets('DiscountPanel renders title and fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        tablesProvider.overrideWith((ref) => TablesNotifier(
              localDb: null,
              apiClient: null,
              syncService: null,
            )),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiscountPanel(tableId: 't-1'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog title and input fields are rendered
    expect(find.text('Áp dụng khuyến mãi'), findsOneWidget);
    expect(find.text('Chiết khấu tiền giờ chơi (%)'), findsOneWidget);
    expect(find.text('Chiết khấu dịch vụ (%)'), findsOneWidget);
    expect(find.text('Chiết khấu tổng hóa đơn (%)'), findsOneWidget);
    // 4 TextFields: promo code + 3 percent inputs
    expect(find.byType(TextField), findsNWidgets(4));
    // No 'Bỏ chiết khấu' when no discount applied
    expect(find.text('Bỏ chiết khấu'), findsNothing);

    container.dispose();
  });


  testWidgets('DiscountPanel shows Bỏ chiết khấu when discount applied', (WidgetTester tester) async {
    // Increase test window height so DiscountPanel content doesn't overflow
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        tablesProvider.overrideWith((ref) => TablesNotifier(
              localDb: null,
              apiClient: null,
              syncService: null,
            )),
      ],
    );

    // Apply a discount before rendering
    container.read(tablesProvider.notifier).applyDiscount(
      't-1',
      playPercent: 0.0,
      servicePercent: 0.0,
      billPercent: 10.0,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiscountPanel(tableId: 't-1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 'Bỏ chiết khấu' should be visible when discount is active
    expect(find.text('Bỏ chiết khấu'), findsOneWidget);

    container.dispose();
  });

  test('applyDiscount provider state updates correctly for all 3 categories', () {
    final container = ProviderContainer(
      overrides: [
        tablesProvider.overrideWith((ref) => TablesNotifier(
              localDb: null,
              apiClient: null,
              syncService: null,
            )),
      ],
    );

    container.read(tablesProvider.notifier).applyDiscount(
      't-1',
      playPercent: 10.0,
      servicePercent: 15.0,
      billPercent: 20.0,
    );

    final state = container.read(tablesProvider);
    expect(state.tablePlayDiscounts['t-1'], 10.0);
    expect(state.tableServiceDiscounts['t-1'], 15.0);
    expect(state.tableBillDiscounts['t-1'], 20.0);

    // Remove discount
    container.read(tablesProvider.notifier).removeDiscount('t-1');
    final stateAfter = container.read(tablesProvider);
    expect(stateAfter.tablePlayDiscounts.containsKey('t-1'), isFalse);
    expect(stateAfter.tableServiceDiscounts.containsKey('t-1'), isFalse);
    expect(stateAfter.tableBillDiscounts.containsKey('t-1'), isFalse);

    container.dispose();
  });
}
