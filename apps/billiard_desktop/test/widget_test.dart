import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billiard_desktop/app.dart';

void main() {
  testWidgets('App start: redirects to Login screen when not authenticated', (WidgetTester tester) async {
    // Set desktop window size
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: BilliardDesktopApp(),
      ),
    );

    // Pump để xử lý routing và async providers
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Login Screen headers and fields are rendered
    expect(find.text('Đăng nhập'), findsWidgets); // Both title and button
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('App start: renders Tables screen when authenticated', (WidgetTester tester) async {
    // Set desktop window size
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake-token-123',
      'current_user': '{"id": "1", "username": "admin", "display_name": "Test Cashier", "role": "admin", "is_active": true}'
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: BilliardDesktopApp(),
      ),
    );

    // Pump đủ thời gian để async SQLite read + routing hoàn thành.
    // Không dùng pumpAndSettle vì app có timer liên tục (đồng hồ bàn).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Tables Screen elements are rendered (mock fallback data)
    expect(find.text('Sơ đồ bàn'), findsOneWidget);
    expect(find.text('Bàn 01 (Pool)'), findsOneWidget);
    expect(find.text('Bàn 04 (Carom)'), findsOneWidget);
    expect(find.text('Bàn 06 (Snooker)'), findsOneWidget);
  });
}
