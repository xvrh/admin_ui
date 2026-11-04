import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Row {
  final int id;
  const _Row(this.id);
}

const _rows = [_Row(1), _Row(2), _Row(3)];

class _Harness extends StatefulWidget {
  final Set<int> initial;
  const _Harness(this.initial);

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Set<_Row> selected = {
    for (final r in _rows)
      if (widget.initial.contains(r.id)) r,
  };

  Set<int> get ids => {for (final r in selected) r.id};

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 600,
    height: 300,
    child: CollectionTable<_Row>(
      rows: _rows,
      rowKey: (r) => r.id,
      selected: selected,
      onSelectionChanged: (s) => setState(() => selected = s),
      columns: [TableColumn(label: 'Id', cell: (r) => Text('${r.id}'))],
    ),
  );
}

Future<_HarnessState> _pump(WidgetTester tester, Set<int> initial) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: _Harness(initial)),
      ),
    ),
  );
  return tester.state<_HarnessState>(find.byType(_Harness));
}

Finder get _all => find.byWidgetPredicate(
  (w) => w is Check && w.semanticLabel == 'Select all on page',
);

void main() {
  // A mixed select-all box goes from some to all, as Radix's and Material's
  // do, and as Check reports a tap on a mixed box.
  for (final (name, activate)
      in <(String, Future<void> Function(WidgetTester))>[
        ('a tap on the box', (tester) => tester.tap(_all)),
        (
          'Space on the focused box',
          (tester) async {
            final focus = find
                .descendant(of: _all, matching: find.byType(Focus))
                .first;
            tester.widget<Focus>(focus).focusNode?.requestFocus();
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
          },
        ),
      ]) {
    testWidgets('$name: some selected selects all, all selected clears', (
      tester,
    ) async {
      final harness = await _pump(tester, {2});
      expect(tester.widget<Check>(_all).indeterminate, isTrue);

      await activate(tester);
      await tester.pump();
      expect(harness.ids, {1, 2, 3});
      expect(tester.widget<Check>(_all).value, isTrue);

      await activate(tester);
      await tester.pump();
      expect(harness.ids, isEmpty);

      await activate(tester);
      await tester.pump();
      expect(harness.ids, {1, 2, 3});
    });
  }
}
