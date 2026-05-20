import 'package:anholding_app/src/core/widgets/an_column_def.dart';
import 'package:anholding_app/src/core/widgets/an_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calls onRowTap with item and index', (tester) async {
    const items = ['row-value'];
    String? tappedItem;
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnDataTable<String>(
            columns: const [
              AnColumnDef<String>(
                key: 'name',
                label: 'Name',
                valueGetter: _valueGetter,
              ),
            ],
            items: items,
            onRowTap: (item, index) {
              tappedItem = item;
              tappedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('row-value'));
    await tester.pump();

    expect(tappedItem, 'row-value');
    expect(tappedIndex, 0);
  });

  testWidgets('does nothing when onRowTap is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnDataTable<String>(
            columns: [
              AnColumnDef<String>(
                key: 'name',
                label: 'Name',
                valueGetter: _valueGetter,
              ),
            ],
            items: ['row-value'],
          ),
        ),
      ),
    );

    await tester.tap(find.text('row-value'));
    await tester.pump();
    expect(find.text('row-value'), findsOneWidget);
  });
}

String _valueGetter(String value) => value;
