import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiard_desktop/features/update/update_service.dart';
import 'package:billiard_desktop/features/update/update_dialog.dart';

void main() {
  testWidgets('UpdateDialog renders correct update info and closes on Skip', (WidgetTester tester) async {
    final updateInfo = UpdateInfo(
      hasUpdate: true,
      latestVersion: '1.1.0',
      downloadUrl: 'https://example.com/installer.exe',
      changelog: '- Fix critical printing bugs\n- Add auto-update support',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: UpdateDialog(updateInfo: updateInfo),
          ),
        ),
      ),
    );

    // Verify header text and version
    expect(find.text('CẬP NHẬT PHẦN MỀM'), findsOneWidget);
    expect(find.text('Phiên bản mới: v1.1.0'), findsOneWidget);

    // Verify changelog contents
    expect(find.text('- Fix critical printing bugs\n- Add auto-update support'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Bỏ qua'), findsOneWidget);
    expect(find.text('Cập nhật ngay'), findsOneWidget);
  });
}
