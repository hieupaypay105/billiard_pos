import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiard_desktop/features/tables/tables_provider.dart';
import 'package:billiard_desktop/features/billing/discount_panel.dart';

void main() {
  testWidgets('DiscountPanel renders correct elements and allows removing discount', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        tablesProvider.overrideWith((ref) => TablesNotifier(
              localDb: null,
              apiClient: null,
              syncService: null,
            )),
      ],
    );

    // Initial state: no discount applied
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscountPanel(tableId: 't-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog title is rendered
    expect(find.text('Áp dụng khuyến mãi'), findsOneWidget);

    // Since no discount is applied initially, 'Bỏ chiết khấu' button should not exist
    expect(find.text('Bỏ chiết khấu'), findsNothing);

    // Now, apply a discount to 't-1' in state
    container.read(tablesProvider.notifier).applyDiscount('t-1', 10.0);

    // Rebuild the widget with the updated state
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscountPanel(tableId: 't-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Now, 'Bỏ chiết khấu' button should be visible
    expect(find.text('Bỏ chiết khấu'), findsOneWidget);

    // Click 'Bỏ chiết khấu'
    await tester.tap(find.text('Bỏ chiết khấu'));
    await tester.pumpAndSettle();

    // Verify discount is removed from the state
    final discount = container.read(tablesProvider).tableDiscounts['t-1'] ?? 0.0;
    expect(discount, 0.0);
  });

  testWidgets('DiscountPanel allows entering custom manual discount percentage', (WidgetTester tester) async {
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
            body: DiscountPanel(tableId: 't-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify custom percentage text field exists
    expect(find.byType(TextField), findsNWidgets(2)); // Promo code field + Custom percent field
    final customPercentField = find.widgetWithText(TextField, 'Nhập số phần trăm khác...');
    expect(customPercentField, findsOneWidget);

    // Enter '12.5' as custom percentage
    await tester.enterText(customPercentField, '12.5');
    await tester.pumpAndSettle();

    // Tap confirm button 'Xác nhận giảm 12%' (or similar based on int cast in UI)
    await tester.tap(find.text('Xác nhận giảm 12%'));
    await tester.pumpAndSettle();

    // Verify the state has 12.5% applied
    final discount = container.read(tablesProvider).tableDiscounts['t-1'] ?? 0.0;
    expect(discount, 12.5);
  });
}
