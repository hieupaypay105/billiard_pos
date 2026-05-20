import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_list_response.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/repositories/khach_hang_repository.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockKhachHangRepository extends Mock implements KhachHangRepository {}

class FakeKhachHangFilter extends Fake implements KhachHangFilter {}

void main() {
  late MockKhachHangRepository mockRepository;

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

  setUpAll(() {
    registerFallbackValue(FakeKhachHangFilter());
  });

  setUp(() {
    mockRepository = MockKhachHangRepository();

    when(
      () => mockRepository.getItems(filter: any(named: 'filter')),
    ).thenAnswer((_) async => emptyListResponse);
    when(() => mockRepository.getOptions()).thenAnswer(
      (_) async => emptyOptionsResponse,
    );
  });

  group('KhachHangProvider.applyFilter', () {
    test(
      'does not refresh again when the incoming filter is identical',
      () async {
        final provider = KhachHangProvider(repository: mockRepository);
        await Future<void>.delayed(Duration.zero);
        clearInteractions(mockRepository);

        await provider.applyFilter(const KhachHangFilter());

        verifyNever(
          () => mockRepository.getItems(filter: any(named: 'filter')),
        );
      },
    );

    test('refreshes when the keyword changes', () async {
      final provider = KhachHangProvider(repository: mockRepository);
      await Future<void>.delayed(Duration.zero);
      clearInteractions(mockRepository);

      await provider.applyFilter(
        const KhachHangFilter().copyWith(keyword: 'alpha'),
      );

      final captured =
          verify(
                () => mockRepository.getItems(
                  filter: captureAny(named: 'filter'),
                ),
              ).captured.single
              as KhachHangFilter;

      expect(captured.keyword, 'alpha');
      expect(captured.page, 1);
    });

    test('refreshes when a non-keyword filter field changes', () async {
      final provider = KhachHangProvider(repository: mockRepository);
      await Future<void>.delayed(Duration.zero);
      clearInteractions(mockRepository);

      await provider.applyFilter(
        const KhachHangFilter().copyWith(status: const [2]),
      );

      final captured =
          verify(
                () => mockRepository.getItems(
                  filter: captureAny(named: 'filter'),
                ),
              ).captured.single
              as KhachHangFilter;

      expect(captured.status, const [2]);
      expect(captured.keyword, isEmpty);
    });
  });
}
