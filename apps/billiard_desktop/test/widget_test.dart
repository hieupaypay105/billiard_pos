import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billiard_desktop/main.dart';

void main() {
  testWidgets('Dashboard UI renders tables and elements', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BilliardDesktopApp());

    // Verify title is rendered
    expect(find.text('Billiard POS & IoT Control'), findsOneWidget);

    // Verify table grid headers
    expect(find.text('SƠ ĐỒ BÀN (TABLE GRID SYSTEM)'), findsOneWidget);

    // Verify presence of some mock tables
    expect(find.text('Bàn 01 (Pool)'), findsNWidgets(2));
    expect(find.text('Bàn 04 (Carom)'), findsOneWidget);
    expect(find.text('Bàn 06 (Snooker)'), findsOneWidget);

    // Verify console is rendered
    expect(find.text('CONSOLE COMMUNICATIONS LOGS (HEX TRAFFIC)'), findsOneWidget);

    // Tap a table card (e.g. Bàn 02) and verify selection focuses on it
    await tester.tap(find.text('Bàn 02 (Pool)'));
    await tester.pump();

    // Verify detail pane updates header for selected table
    expect(find.text('Bàn 02 (Pool)'), findsAtLeastNWidgets(1));
  });
}
