import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiard_desktop/core/providers/providers.dart';
import 'package:billiard_desktop/core/services/local_db_service.dart';
import 'package:billiard_desktop/features/billing/member_lookup.dart';

class FakeLocalDbService implements LocalDbService {
  @override
  Future<List<Map<String, dynamic>>> searchMembers(String query) async {
    if (query == '090') {
      return [
        {
          'id': 'm-1',
          'full_name': 'Nguyen Van A',
          'phone_number': '0901234567',
          'tier_name': 'Gold',
          'discount_percentage': 5.0,
          'total_points': 100,
        }
      ];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MemberLookupDialog shows suggestions after typing 3 characters', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        localDbServiceProvider.overrideWithValue(FakeLocalDbService()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MemberLookupDialog(tableId: 't-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find TextField for phone number
    final phoneField = find.byType(TextField);
    expect(phoneField, findsOneWidget);

    // Type 2 characters: no suggestions should show
    await tester.enterText(phoneField, '09');
    await tester.pump();
    expect(find.text('Nguyen Van A'), findsNothing);

    // Type 3 characters: suggestion should show
    await tester.enterText(phoneField, '090');
    await tester.pump();
    
    // Allow the post-frame callback and async database query to execute
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nguyen Van A'), findsOneWidget);
    expect(find.text('0901234567'), findsOneWidget);

    // Tap on the suggestion
    await tester.tap(find.text('Nguyen Van A'));
    await tester.pumpAndSettle();

    // Suggestions container should disappear
    expect(find.text('Nguyen Van A'), findsOneWidget); // Found Member Card still shows the name
    expect(find.text('Áp dụng thành viên'), findsOneWidget); // Card CTA should show up
  });
}
