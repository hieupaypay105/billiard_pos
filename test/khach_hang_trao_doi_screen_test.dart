import 'package:anholding_app/src/core/storage/user_storage.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/dashboard_notification_provider.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_list_response.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/contact_item.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:anholding_app/src/features/khach_hang/domain/repositories/khach_hang_repository.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_trao_doi_screen.dart';
import 'package:anholding_app/src/features/notification/data/models/notification_list_response.dart';
import 'package:anholding_app/src/features/notification/domain/entities/notification_filter.dart';
import 'package:anholding_app/src/features/notification/domain/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockKhachHangRepository extends Mock implements KhachHangRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeNotificationFilter extends Fake implements NotificationFilter {}

class FakeKhachHangFilter extends Fake implements KhachHangFilter {}

void main() {
  late MockKhachHangRepository khachHangRepository;
  late MockNotificationRepository notificationRepository;
  late MockAuthRepository authRepository;

  const dummyKhachHang = KhachHangItem(
    id: '1',
    sourceId: '2',
    name: 'TEST CUSTOMER',
    status: '1',
    createdAt: '2023-01-01',
    financialRangeLabel: '10 Tỷ',
    lastContact: '2025-01-01 10:00',
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

  setUpAll(() {
    registerFallbackValue(FakeNotificationFilter());
    registerFallbackValue(FakeKhachHangFilter());
  });

  setUp(() {
    khachHangRepository = MockKhachHangRepository();
    notificationRepository = MockNotificationRepository();
    authRepository = MockAuthRepository();

    when(
      () => khachHangRepository.getOptions(),
    ).thenAnswer((_) async => emptyOptionsResponse);

    when(
      () => khachHangRepository.getListContact(
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => khachHangRepository.getItems(filter: any(named: 'filter')),
    ).thenAnswer(
      (_) async => const KhachHangListResponse(
        items: [],
        pagination: KhachHangPagination(
          total: 0,
          perPage: 15,
          currentPage: 1,
          lastPage: 1,
        ),
      ),
    );

    when(
      () => notificationRepository.getItems(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        recipientType: any(named: 'recipientType'),
      ),
    ).thenAnswer(
      (_) async => const NotificationListResponse(
        items: [],
        pagination: NotificationPagination(
          total: 0,
          perPage: 5,
          currentPage: 1,
          lastPage: 1,
        ),
        unreadCount: NotificationUnreadCount(),
      ),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final provider = KhachHangProvider(repository: khachHangRepository);
    final dashboardProvider = DashboardNotificationProvider(
      repository: notificationRepository,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<KhachHangProvider>.value(value: provider),
          ChangeNotifierProvider<DashboardNotificationProvider>.value(
            value: dashboardProvider,
          ),
          ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(
              userStorage: MockUserStorage(),
              authRepository: authRepository,
            ),
          ),
        ],
        child: const MaterialApp(
          home: KhachHangTraoDoiScreen(item: dummyKhachHang),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('KhachHangTraoDoiScreen unit tests', () {
    testWidgets('renders title, stats, and empty contacts correctly', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('TEST CUSTOMER'), findsOneWidget);
      expect(find.text('LIÊN HỆ LẦN CUỐI'), findsOneWidget);
      expect(find.text('10 Tỷ'), findsOneWidget);
      expect(find.text('Chưa có trao đổi nào'), findsOneWidget);
      expect(find.text('GỬI'), findsOneWidget);
      expect(find.text('XONG'), findsOneWidget);
    });

    testWidgets('displays contact list correctly', (tester) async {
      when(
        () => khachHangRepository.getListContact(customerId: '1'),
      ).thenAnswer(
        (_) async => [
          const ContactItem(
            id: 'c1',
            customerId: '1',
            userId: 'u1',
            name: 'Sale A',
            comment: 'Gọi điện thoại, khách hẹn cuối tuần.',
            createdAt: '2025-02-15 09:30:00',
            updatedAt: '2025-02-15 09:30:00',
          ),
          const ContactItem(
            id: 'c2',
            customerId: '1',
            userId: 'u2',
            name: 'Sale B',
            comment: 'Góp ý thiết kế.',
            createdAt: '2025-02-16 10:15:00',
            updatedAt: '2025-02-16 10:15:00',
          ),
        ],
      );

      await pumpScreen(tester);

      expect(find.text('SALE A'), findsOneWidget);
      expect(find.text('SALE B'), findsOneWidget);
      expect(find.text('Gọi điện thoại, khách hẹn cuối tuần.'), findsOneWidget);
      expect(find.text('Góp ý thiết kế.'), findsOneWidget);
    });
  });
}

class MockUserStorage extends Mock implements UserStorage {}
