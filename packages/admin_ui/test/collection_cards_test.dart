import 'package:admin_ui/src/collection/ui/collection_cards.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

  testWidgets('a card canOpen leaves out is content, not a control', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final opened = <String>[];
    await tester.pumpWidget(
      _host(
        CollectionCards<String>(
          rows: _rows,
          cardBuilder: (_, r) => SizedBox(height: 80, child: Text(r)),
          onCardTap: opened.add,
          canOpen: (r) => r != 'Bravo',
        ),
      ),
    );

    await tester.tap(find.text('Bravo'));
    await tester.tap(find.text('Cherry'));
    expect(opened, ['Cherry']);

    // Tab goes from Alpha to Cherry.
    opened.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['Cherry']);

    bool taps(String row) => tester
        .getSemantics(find.text(row))
        .getSemanticsData()
        .hasAction(SemanticsAction.tap);
    expect((taps('Alpha'), taps('Bravo')), (true, false));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    Future<(MouseCursor, bool)> under(String row) async {
      await mouse.moveTo(tester.getCenter(find.text(row)));
      await tester.pumpAndSettle();
      final card = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(row),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1)!,
        (card.decoration! as BoxDecoration).boxShadow != null,
      );
    }

    expect(await under('Alpha'), (SystemMouseCursors.click, true));
    expect(await under('Bravo'), (SystemMouseCursors.basic, false));
    handle.dispose();
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
