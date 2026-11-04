import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A DTO with identity equality, as a JSON decoder returns: two fetches of
/// one record are never `==`.
class _Dto {
  final int id;
  final String name;
  _Dto(this.id, this.name);
}

List<_Dto> _fetch() => [_Dto(1, 'Alpha'), _Dto(2, 'Bravo'), _Dto(3, 'Cherry')];

class _Harness extends StatefulWidget {
  final Set<_Dto> initial;
  const _Harness(this.initial);

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Set<_Dto> selected = widget.initial;
  List<_Dto> rows = _fetch();

  void refetch() => setState(() => rows = _fetch());

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 800,
    height: 400,
    child: CollectionTable<_Dto>(
      rows: rows,
      rowKey: (r) => r.id,
      selected: selected,
      onSelectionChanged: (s) => setState(() => selected = s),
      columns: [TableColumn(label: 'Name', cell: (r) => Text(r.name))],
    ),
  );
}

Future<_HarnessState> _pump(WidgetTester tester, Set<_Dto> initial) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: _Harness(initial)),
      ),
    ),
  );
  return tester.state<_HarnessState>(find.byType(_Harness));
}

Matcher get _checked => isSemantics(hasCheckedState: true, isChecked: true);
Matcher get _unchecked => isSemantics(hasCheckedState: true, isChecked: false);

void main() {
  testWidgets('selection made from another fetch shows checked', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, {_fetch()[1]});
    expect(
      tester.getSemantics(find.bySemanticsLabel('Select row 1')),
      _unchecked,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Select row 2')),
      _checked,
    );
    handle.dispose();
  });

  testWidgets('fresh DTOs from a refetch stay selected', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await _pump(tester, {});
    await tester.tap(find.bySemanticsLabel('Select row 3'));
    await tester.pump();
    harness.refetch();
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Select row 3')),
      _checked,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Select all on page')),
      isSemantics(hasCheckedState: true, isCheckStateMixed: true),
    );

    // Unchecking a fresh row drops the stale object it replaced.
    await tester.tap(find.bySemanticsLabel('Select row 3'));
    await tester.pump();
    expect(harness.selected, isEmpty);
    handle.dispose();
  });

  testWidgets('select-all compares by key and keeps other pages', (
    tester,
  ) async {
    final elsewhere = _Dto(99, 'On another page');
    final harness = await _pump(tester, {elsewhere, _fetch()[0]});
    await tester.tap(find.bySemanticsLabel('Select all on page'));
    await tester.pump();
    expect(harness.selected.map((d) => d.id).toSet(), {99, 1, 2, 3});
    expect(harness.selected, hasLength(4), reason: 'no duplicate of row 1');

    harness.refetch();
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Select all on page'));
    await tester.pump();
    expect(harness.selected.map((d) => d.id), [99]);
  });

  testWidgets('selection without a rowKey is caught in debug', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CollectionTable<_Dto>(
          rows: _fetch(),
          selected: const {},
          onSelectionChanged: (_) {},
          columns: [TableColumn(label: 'Name', cell: (r) => Text(r.name))],
        ),
      ),
    );
    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (e) => '${e.message}',
        'message',
        contains('need a rowKey'),
      ),
    );
  });
}
