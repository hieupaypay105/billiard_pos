import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billiard_desktop/app.dart';

void main() {
  testWidgets('App start: redirects to Login screen when not authenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: BilliardDesktopApp()),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('App start: renders Tables screen when authenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake-token-123',
      'current_user':
          '{"id": "1", "username": "admin", "display_name": "Test Cashier", "role": "admin", "is_active": true}',
    });

    await tester.pumpWidget(
      const ProviderScope(child: BilliardDesktopApp()),
    );

    // Pump đủ frame cho routing + async providers
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    // Kiểm tra Tables Screen đã render (header luôn hiển thị)
    expect(find.text('Sơ đồ bàn'), findsOneWidget);
    // Ghi chú: dữ liệu bàn sẽ từ SQLite sau sync,
    // không assert tên bàn cố định vì đó là implementation detail.
  });
}
