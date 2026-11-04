import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _columns = <TableColumn<int>>[
  TableColumn(
    id: 'name',
    label: 'Name',
    hideable: false,
    cell: (_) => const Text(''),
  ),
  TableColumn(id: 'status', label: 'Status', cell: (_) => const Text('')),
  TableColumn(label: 'Updated', cell: (_) => const Text('')),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 320, height: 600, child: child),
        ),
      ),
    ),
  );
}

/// A chooser over [choices] that keeps the layout it reports.
Widget _chooser(
  List<ColumnChoice> choices,
  ColumnLayout initial,
  void Function(ColumnLayout) onChanged,
) {
  var layout = initial;
  return StatefulBuilder(
    builder: (context, setState) => ColumnChooser(
      columns: choices,
      layout: layout,
      onChanged: (next) {
        onChanged(next);
        setState(() => layout = next);
      },
    ),
  );
}

Finder _row(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Tappable)).first;

FocusNode? get _focus => FocusManager.instance.primaryFocus;

void main() {
  test('fromColumns takes key, label and lock from the table', () {
    final choices = ColumnChoice.fromColumns(_columns);
    expect([for (final c in choices) c.key], ['name', 'status', 'Updated']);
    expect([for (final c in choices) c.label], ['Name', 'Status', 'Updated']);
    expect([for (final c in choices) c.locked], [true, false, false]);
  });

  testWidgets('Alt+↓ / Alt+↑ move the focused row, which keeps focus', (
    tester,
  ) async {
    final choices = ColumnChoice.fromColumns(_columns);
    var layout = ColumnLayout.of(_columns);
    await _pump(tester, _chooser(choices, layout, (l) => layout = l));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final first = _focus;
    expect(
      find.descendant(
        of: _row('Name'),
        matching: find.byWidget(first!.context!.widget),
      ),
      findsOneWidget,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(layout.order, ['status', 'name', 'Updated']);
    expect(_focus, same(first));

    // To the end, where ↓ does nothing, and back up one.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    for (final key in [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    expect(layout.order, ['status', 'name', 'Updated']);
    expect(_focus, same(first));
  });

  testWidgets('a row is one checkbox Tab stop with move actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final choices = ColumnChoice.fromColumns(_columns);
    var layout = ColumnLayout.of(_columns);
    await _pump(tester, _chooser(choices, layout, (l) => layout = l));

    final status = find.semantics.byLabel('Status').evaluate().single;
    final data = status.getSemanticsData();
    expect(status, isSemantics(hasCheckedState: true, isChecked: true));
    final actions = [
      for (final id in data.customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label,
    ];
    expect(actions, unorderedEquals(['Move up', 'Move down']));

    // Space toggles the focused row.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(layout.isVisible('status'), isFalse);

    // The locked row stays on.
    await tester.tap(find.text('Name'));
    await tester.pump();
    expect(layout.isVisible('name'), isTrue);
    handle.dispose();
  });

  testWidgets('past eight columns, search and show / hide all', (tester) async {
    final choices = [
      for (var i = 0; i < 10; i++) ColumnChoice(key: 'c$i', label: 'Column $i'),
    ];
    var layout = ColumnLayout(order: [for (final c in choices) c.key]);
    await _pump(tester, _chooser(choices, layout, (l) => layout = l));

    expect(find.byType(SearchField), findsOneWidget);
    await tester.tap(find.text('Hide all'));
    await tester.pump();
    expect(layout.hidden, {for (final c in choices) c.key});
    await tester.tap(find.text('Show all'));
    await tester.pump();
    expect(layout.hidden, isEmpty);

    await tester.enterText(find.byType(TextField), 'n 1');
    await tester.pump();
    expect(find.text('Column 1'), findsOneWidget);
    expect(find.text('Column 2'), findsNothing);
    await tester.tap(find.text('Hide all'));
    await tester.pump();
    expect(layout.hidden, {'c1'});

    // Few columns: no search.
    await _pump(
      tester,
      _chooser(choices.take(8).toList(), layout, (l) => layout = l),
    );
    expect(find.byType(SearchField), findsNothing);
  });

  testWidgets('the header count is readable muted text', (tester) async {
    await _pump(
      tester,
      _chooser(
        ColumnChoice.fromColumns(_columns),
        const ColumnLayout(hidden: {'status'}),
        (_) {},
      ),
    );
    final count = tester.widget<Text>(find.text('2 of 3'));
    final context = tester.element(find.text('2 of 3'));
    expect(
      contrastRatio(count.style!.color!, context.colors.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  group('trigger', () {
    const hidden = ColumnLayout(hidden: {'status', 'Updated'});

    testWidgets('full: names the hidden count and keeps its chevron', (
      tester,
    ) async {
      await _pump(
        tester,
        Center(
          child: ColumnChooserButton(
            columns: ColumnChoice.fromColumns(_columns),
            layout: hidden,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Columns (2 hidden)'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      await _pump(
        tester,
        Center(
          child: ColumnChooserButton(
            columns: ColumnChoice.fromColumns(_columns),
            layout: const ColumnLayout(),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Columns'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('small: a kit IconAction named with the count, and a dot', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        Center(
          child: ColumnChooserButton(
            columns: ColumnChoice.fromColumns(_columns),
            layout: hidden,
            onChanged: (_) {},
            size: ControlSize.small,
          ),
        ),
      );
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(IconAction), findsOneWidget);
      expect(find.semantics.byLabel('Columns (2 hidden)'), findsOne);

      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      expect(find.byType(ColumnChooser), findsOneWidget);
      handle.dispose();
    });
  });
}
