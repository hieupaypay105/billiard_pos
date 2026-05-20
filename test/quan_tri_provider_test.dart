import 'package:anholding_app/src/features/quan_tri/data/models/quan_tri_item_model.dart';
import 'package:anholding_app/src/features/quan_tri/data/models/quan_tri_list_response.dart';
import 'package:anholding_app/src/features/quan_tri/domain/repositories/quan_tri_repository.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQuanTriRepository extends Mock implements QuanTriRepository {}

class FakeQuanTriFilter extends Fake implements QuanTriFilter {}

void main() {
  late MockQuanTriRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeQuanTriFilter());
  });

  setUp(() {
    mockRepository = MockQuanTriRepository();
  });

  QuanTriItemModel createMockItem(String id) {
    return QuanTriItemModel(
      id: id,
      username: 'user_$id',
      fullname: 'User $id',
      mobile: '0123456789',
      email: 'user$id@example.com',
      status: '1',
      statusLabel: 'Hoạt động',
      roleName: 'Role',
      employeeCode: 'emp$id',
      createdAt: '2023-01-01',
      updatedAt: '2023-01-01',
    );
  }

  group('QuanTriProvider Lazy Scroll Logging & Unit Tests', () {
    test(
      'refresh() loads initial page and correctly sets hasMore = true',
      () async {
        final mockItems = List.generate(
          50,
          (i) => createMockItem(i.toString()),
        );
        final response = QuanTriListResponse(
          items: mockItems,
          pagination: const QuanTriPagination(
            total: 100,
            perPage: 50,
            currentPage: 1,
            lastPage: 2,
          ),
        );

        when(
          () => mockRepository.getItems(filter: any(named: 'filter')),
        ).thenAnswer((_) async => response);

        final provider = QuanTriProvider(repository: mockRepository);

        // Since refresh() is called in the constructor, wait for the event loop
        await Future.delayed(Duration.zero);

        expect(provider.items.length, 50);
        expect(provider.hasMore, true);
        expect(provider.isLoading, false);
        expect(provider.total, 100);

        verify(
          () => mockRepository.getItems(filter: any(named: 'filter')),
        ).called(1);
      },
    );

    test(
      'loadMore() fetch next items and properly sets hasMore = false when total reached',
      () async {
        // Mock page 1 (50 items)
        final mockItems1 = List.generate(50, (i) => createMockItem('p1_$i'));
        final response1 = QuanTriListResponse(
          items: mockItems1,
          pagination: const QuanTriPagination(
            total: 80,
            perPage: 50,
            currentPage: 1,
            lastPage: 2,
          ),
        );

        // Mock page 2 (30 items)
        final mockItems2 = List.generate(30, (i) => createMockItem('p2_$i'));
        final response2 = QuanTriListResponse(
          items: mockItems2,
          pagination: const QuanTriPagination(
            total: 80,
            perPage: 50,
            currentPage: 2,
            lastPage: 2,
          ),
        );

        var isSecondCall = false;
        when(
          () => mockRepository.getItems(filter: any(named: 'filter')),
        ).thenAnswer((_) async {
          if (!isSecondCall) {
            isSecondCall = true;
            return response1;
          }
          return response2;
        });

        final provider = QuanTriProvider(repository: mockRepository);
        await Future.delayed(Duration.zero); // Wait for constructor's refresh()

        expect(provider.items.length, 50);
        expect(provider.hasMore, true);

        // Trigger loadMore
        await provider.loadMore();

        expect(provider.items.length, 80);
        expect(
          provider.hasMore,
          false,
          reason: 'hasMore should be false since total is reached',
        );

        verify(
          () => mockRepository.getItems(filter: any(named: 'filter')),
        ).called(2);
      },
    );

    test('loadMore() avoids calling API if already loadingMore', () async {
      final mockItems = List.generate(50, (i) => createMockItem(i.toString()));
      final response = QuanTriListResponse(
        items: mockItems,
        pagination: const QuanTriPagination(
          total: 100,
          perPage: 50,
          currentPage: 1,
          lastPage: 2,
        ),
      );

      // Artificial delay to trap loading state
      when(
        () => mockRepository.getItems(filter: any(named: 'filter')),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return response;
      });

      final provider = QuanTriProvider(repository: mockRepository);

      // Await initial refresh from constructor
      await Future.delayed(const Duration(milliseconds: 150));
      verify(
        () => mockRepository.getItems(filter: any(named: 'filter')),
      ).called(1);

      // Attempt to fire multiple loadMores while the first is pending
      final feature1 = provider.loadMore();
      final feature2 = provider.loadMore();
      final feature3 = provider.loadMore();

      await Future.wait([feature1, feature2, feature3]);

      // Only one loadMore call should hit the repo since tracking guards block it
      verify(
        () => mockRepository.getItems(filter: any(named: 'filter')),
      ).called(1);
    });
  });
}
