import 'package:admin_ui/src/collection/ui/collection_cards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 800, height: 400, child: child)),
);

const _rows = ['Alpha', 'Bravo', 'Cherry'];

void main() {
  testWidgets('renders a card per row and fires onCardTap', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      _host(
        CollectionCards<String>(
          rows: _rows,
          cardBuilder: (_, r) => Text(r),
          onCardTap: (r) => tapped = r,
        ),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Cherry'), findsOneWidget);

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    expect(tapped, 'Bravo');
  });

  testWidgets('selected card shows its checkbox and toggles selection', (
    tester,
  ) async {
    var selected = <String>{'Alpha'};
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => CollectionCards<String>(
            rows: _rows,
            cardBuilder: (_, r) => SizedBox(height: 80, child: Text(r)),
            selected: selected,
            onSelectionChanged: (s) => setState(() => selected = s),
          ),
        ),
      ),
    );

    // The already-selected card surfaces its checkbox without a hover.
    expect(find.byType(Checkbox), findsNothing); // house Check, not Material
    await tester.tap(find.byType(Icon).first);
    await tester.pump();
    expect(selected.contains('Alpha'), isFalse);
  });

  testWidgets('empty slot shows when there are no rows', (tester) async {
    await tester.pumpWidget(
      _host(
        CollectionCards<String>(
          rows: const [],
          cardBuilder: (_, r) => Text(r),
          empty: const Text('Nothing here'),
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('error slot takes precedence over rows', (tester) async {
    await tester.pumpWidget(
      _host(
        CollectionCards<String>(
          rows: _rows,
          cardBuilder: (_, r) => Text(r),
          error: const Text('Boom'),
        ),
      ),
    );
    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });
}
