import 'package:admin_ui/src/collection/ui/bulk_action_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the count and fires an action', (tester) async {
    var published = 0;
    await tester.pumpWidget(
      _host(
        BulkActionBar(
          count: 3,
          onClear: () {},
          actions: [BulkAction('Publish', onPressed: () => published++)],
        ),
      ),
    );

    expect(find.text('3 selected'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    expect(published, 1);
  });

  testWidgets('custom selectedLabel overrides the count text', (tester) async {
    await tester.pumpWidget(
      _host(
        BulkActionBar(
          count: 1,
          onClear: () {},
          actions: const [],
          selectedLabel: (n) => '$n product selected',
        ),
      ),
    );
    expect(find.text('1 product selected'), findsOneWidget);
  });

  testWidgets('clear fires', (tester) async {
    var cleared = 0;
    await tester.pumpWidget(
      _host(
        BulkActionBar(count: 2, onClear: () => cleared++, actions: const []),
      ),
    );
    await tester.tap(find.text('Clear'));
    expect(cleared, 1);
  });

  testWidgets('offers select-all-matching and fires it', (tester) async {
    var all = 0;
    await tester.pumpWidget(
      _host(
        BulkActionBar(
          count: 10,
          onClear: () {},
          actions: const [],
          matchingTotal: 137,
          onSelectAllMatching: () => all++,
        ),
      ),
    );
    expect(find.text('Select all 137'), findsOneWidget);
    await tester.tap(find.text('Select all 137'));
    expect(all, 1);
  });

  testWidgets('whole-query mode says all are selected, once, not the link', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        BulkActionBar(
          count: 137,
          onClear: () {},
          actions: const [],
          matchingTotal: 137,
          allMatchingSelected: true,
          onSelectAllMatching: () {},
        ),
      ),
    );
    expect(find.text('All 137 selected'), findsOneWidget);
    expect(find.textContaining('137 selected'), findsOneWidget);
    expect(find.text('Select all 137'), findsNothing);
  });

  testWidgets('whole-query mode reads its own label, or all of the page '
      'label', (tester) async {
    Future<void> pump({String Function(int)? all}) => tester.pumpWidget(
      _host(
        BulkActionBar(
          count: 25,
          onClear: () {},
          actions: const [],
          selectedLabel: (n) => '$n products selected',
          allSelectedLabel: all,
          matchingTotal: 137,
          allMatchingSelected: true,
        ),
      ),
    );
    await pump(all: (n) => 'Every one of the $n products');
    expect(find.text('Every one of the 137 products'), findsOneWidget);
    // Without one, the page label counts the whole query, said of all of
    // it, so it never reads like a page of 137.
    await pump();
    expect(find.text('All 137 products selected'), findsOneWidget);
  });
}
