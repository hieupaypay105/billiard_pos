import 'dart:convert';

import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/repositories/khach_hang_repository.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/screens/khach_hang_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockKhachHangRepository extends Mock implements KhachHangRepository {}

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

  const optionsWithRegion = KhachHangOptionResponse(
    status: [],
    source: {},
    project: {},
    sale: {},
    attribute: {},
    financialRange: {},
    createdAt: {},
    filterSaved: [],
    region: {
      508: 'Hà Nội',
      514: 'Thành phố Hồ Chí Minh',
    },
  );

  setUp(() {
    khachHangRepository = MockKhachHangRepository();
    when(
      () => khachHangRepository.getOptions(),
    ).thenAnswer((_) async => optionsWithRegion);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final provider = KhachHangProvider(repository: khachHangRepository);

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<KhachHangProvider>.value(value: provider),
          ],
          child: const MaterialApp(
            home: KhachHangAddScreen(),
          ),
        ),
      ),
    );
    // Allow initState to load options
    await tester.pumpAndSettle();
  }

  group('KhachHangAddScreen widget tests', () {
    testWidgets('renders region dropdown and updates form value', (
      tester,
    ) async {
      // Arrange
      await pumpScreen(tester);

      // Act: Find the dropdown for Tỉnh/Thành phố by its field name
      final dropdownFinder = find.byWidgetPredicate(
        (widget) =>
            widget is FormBuilderDropdown<int> && widget.name == 'region_id',
      );

      // Assert: Dropdown should be present and active
      expect(dropdownFinder, findsOneWidget);

      final dropdown = tester.widget<FormBuilderDropdown<int>>(dropdownFinder);
      expect(dropdown.items.length, 2); // Hà Nội and HCM

      // FormBuilder stores state via GlobalKey, let's tap and select 'Hà Nội'
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Select Hà Nội
      final optionFinder = find.text('Hà Nội').last;
      expect(optionFinder, findsOneWidget);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Assert that form contains the correct state
      final formState = tester.state<FormBuilderState>(
        find.byType(FormBuilder),
      );
      final formValues = formState.value;

      expect(formValues['region_id'], 508);
    });
  });
}
