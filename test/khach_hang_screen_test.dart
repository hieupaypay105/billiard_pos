import 'dart:convert';

import 'package:anholding_app/src/core/storage/user_storage.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_notification_provider.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_list_response.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/repositories/khach_hang_repository.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_screen.dart';
import 'package:anholding_app/src/features/notification/data/models/notification_list_response.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_filter.dart';
import 'package:anholding_app/src/features/notification/domain/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockKhachHangRepository extends Mock implements KhachHangRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockUserStorage extends Mock implements UserStorage {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeKhachHangFilter extends Fake implements KhachHangFilter {}

class FakeNotificationFilter extends Fake implements NotificationFilter {}

class _TestAssetBundle extends CachingAssetBundle {
  static final ByteData _svgBytes = ByteData.view(
    Uint8List.fromList(
      utf8.encode(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>',
      ),
    ).buffer,
  );

  @override
  Future<ByteData> load(String key) async => _svgBytes;

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode(_svgBytes.buffer.asUint8List());
}

void main() {
  late MockKhachHangRepository khachHangRepository;
  late MockNotificationRepository notificationRepository;
  late MockUserStorage userStorage;
  late MockAuthRepository authRepository;

  const emptyListResponse = KhachHangListResponse(
    items: [],
    pagination: KhachHangPagination(
      total: 0,
      perPage: 50,
      currentPage: 1,
      lastPage: 1,
    ),
  );

  const emptyOptionsResponse = KhachHangOptionResponse(
    status: [],
    source: {},
    project: {},
    sale: {},
    attribute: {},
    financialRange: {},
    createdAt: {},
    filterSaved: [],
    region: {},
  );

  const emptyNotificationResponse = NotificationListResponse(
    items: [],
    pagination: NotificationPagination(
      total: 0,
      perPage: 5,
      currentPage: 1,
      lastPage: 1,
    ),
    unreadCount: NotificationUnreadCount(),
  );

  setUpAll(() {
    registerFallbackValue(FakeKhachHangFilter());
    registerFallbackValue(FakeNotificationFilter());
  });

  setUp(() {
    khachHangRepository = MockKhachHangRepository();
    notificationRepository = MockNotificationRepository();
    userStorage = MockUserStorage();
    authRepository = MockAuthRepository();

    when(
      () => khachHangRepository.getItems(filter: any(named: 'filter')),
    ).thenAnswer((_) async => emptyListResponse);
    when(() => khachHangRepository.getOptions()).thenAnswer(
      (_) async => emptyOptionsResponse,
    );
    when(
      () => notificationRepository.getItems(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        recipientType: any(named: 'recipientType'),
      ),
    ).thenAnswer((_) async => emptyNotificationResponse);
  });

  Future<KhachHangProvider> pumpScreen(WidgetTester tester) async {
    final provider = KhachHangProvider(repository: khachHangRepository);
    final dashboardProvider = DashboardNotificationProvider(
      repository: notificationRepository,
    );
    final userProvider = UserProvider(
      userStorage: userStorage,
      authRepository: authRepository,
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<KhachHangProvider>.value(value: provider),
            ChangeNotifierProvider<DashboardNotificationProvider>.value(
              value: dashboardProvider,
            ),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            home: KhachHangScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return provider;
  }

  EditableText editableText(WidgetTester tester) {
    return tester.widget<EditableText>(find.byType(EditableText).first);
  }

  group('KhachHangScreen search', () {
    testWidgets(
      'debounces search and skips re-dispatching the same trimmed keyword',
      (
        tester,
      ) async {
        await pumpScreen(tester);
        clearInteractions(khachHangRepository);

        await tester.enterText(find.byType(EditableText).first, '  alpha  ');
        await tester.pump(const Duration(milliseconds: 400));

        verifyNever(
          () => khachHangRepository.getItems(filter: any(named: 'filter')),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final firstCaptured =
            verify(
                  () => khachHangRepository.getItems(
                    filter: captureAny(named: 'filter'),
                  ),
                ).captured.single
                as KhachHangFilter;
        expect(firstCaptured.keyword, 'alpha');
        expect(firstCaptured.page, 1);

        clearInteractions(khachHangRepository);

        await tester.enterText(find.byType(EditableText).first, 'alpha');
        await tester.pump(const Duration(milliseconds: 500));

        verifyNever(
          () => khachHangRepository.getItems(filter: any(named: 'filter')),
        );
      },
    );

    testWidgets(
      'search button reads form state and external provider changes sync the field',
      (
        tester,
      ) async {
        final provider = await pumpScreen(tester);
        clearInteractions(khachHangRepository);

        await tester.enterText(find.byType(EditableText).first, 'beta');
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();

        final searchCaptured =
            verify(
                  () => khachHangRepository.getItems(
                    filter: captureAny(named: 'filter'),
                  ),
                ).captured.single
                as KhachHangFilter;
        expect(searchCaptured.keyword, 'beta');
        expect(searchCaptured.page, 1);

        clearInteractions(khachHangRepository);

        await provider.applyFilter(
          const KhachHangFilter().copyWith(keyword: 'from filter'),
        );
        await tester.pump();

        expect(editableText(tester).controller.text, 'from filter');
      },
    );
  });
}
