import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/common/ui/focus_ring.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Item {
  final int id;
  final String name;
  final double price;
  const _Item(this.id, this.name, this.price);
}

final _items = [for (var i = 0; i < 30; i++) _Item(i, 'Item $i', 10.0 + i)];

/// A table between two buttons, 800 × 400: a 44px header over 52px rows.
class _Harness extends StatefulWidget {
  final List<_Item> rows;
  final void Function(_Item row)? onRowTap;
  final void Function(String key, bool ascending)? onSort;
  final void Function(String key, double width)? onColumnResize;
  final void Function(String key, double width)? onColumnResizeEnd;

  const _Harness({
    required this.rows,
    this.onRowTap,
    this.onSort,
    this.onColumnResize,
    this.onColumnResizeEnd,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  Set<_Item> selected = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(onPressed: () {}, child: const Text('Before')),
        SizedBox(
          width: 800,
          height: 400,
          child: CollectionTable<_Item>(
            rows: widget.rows,
            rowKey: (r) => r.id,
            selected: selected,
            onSelectionChanged: (s) => setState(() => selected = s),
            onRowTap: widget.onRowTap,
            onSort: widget.onSort,
            onColumnResize: widget.onColumnResize,
            onColumnResizeEnd: widget.onColumnResizeEnd,
            onHideColumn: (_) {},
            columns: [
              TableColumn(
                id: 'name',
                label: 'Name',
                sortKey: 'name',
                cell: (r) => Text(r.name),
              ),
              TableColumn(
                id: 'price',
                label: 'Price',
                fixed: 120,
                numeric: true,
                sortKey: 'price',
                cell: (r) => Text('\$${r.price}'),
              ),
            ],
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('After')),
      ],
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

Future<void> _chord(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

/// The focused cell's ring.
Finder get _ring => find.byWidgetPredicate((w) => w is FocusRing && w.focused);

/// Whether the focused cell's ring surrounds [target].
bool _ringOn(WidgetTester tester, Finder target) {
  final ring = tester.getRect(_ring);
  return ring.inflate(8).contains(tester.getCenter(target));
}

bool get _gridFocused =>
    FocusManager.instance.primaryFocus?.debugLabel == 'CollectionTable';

/// Tab from the button before the table into it.
Future<void> _tabIn(WidgetTester tester) async {
  await _key(tester, LogicalKeyboardKey.tab);
  expect(_gridFocused, isFalse, reason: 'the button before the table');
  await _key(tester, LogicalKeyboardKey.tab);
  expect(_gridFocused, isTrue);
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('the table is a single Tab stop', (tester) async {
    await _pump(tester, _Harness(rows: _items));
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_gridFocused, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextButton>()
          ?.child,
      isA<Text>().having((t) => t.data, 'label', 'After'),
    );
  });

  testWidgets('focus lands on the first cell and arrows move it', (
    tester,
  ) async {
    await _pump(tester, _Harness(rows: _items));
    await _tabIn(tester);
    expect(_ring, findsOneWidget);
    expect(_ringOn(tester, find.bySemanticsLabel('Select row 1')), isTrue);

    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_ringOn(tester, find.text('Item 0')), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_ringOn(tester, find.text('Item 1')), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_ringOn(tester, find.text('\$11.0')), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(
      _ringOn(tester, find.text('\$11.0')),
      isTrue,
      reason: 'the last column holds',
    );
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_ringOn(tester, find.text('Price')), isTrue, reason: 'the header');
  });

  testWidgets('Home and End reach the ends of the row, Ctrl the grid', (
    tester,
  ) async {
    await _pump(tester, _Harness(rows: _items));
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.end);
    expect(_ringOn(tester, find.text('\$10.0')), isTrue);
    await _key(tester, LogicalKeyboardKey.home);
    expect(_ringOn(tester, find.bySemanticsLabel('Select row 1')), isTrue);

    await _chord(
      tester,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.end,
    );
    expect(_ringOn(tester, find.text('\$39.0')), isTrue, reason: 'scrolled');
    await _chord(
      tester,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.home,
    );
    expect(
      _ringOn(tester, find.bySemanticsLabel('Select all on page')),
      isTrue,
    );
  });

  testWidgets('PageDown moves a screen of rows and scrolls it into view', (
    tester,
  ) async {
    await _pump(tester, _Harness(rows: _items));
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    // (400 - 44) / 52 → 6 rows a page.
    await _key(tester, LogicalKeyboardKey.pageDown);
    expect(_ringOn(tester, find.text('Item 6')), isTrue);
    await _key(tester, LogicalKeyboardKey.pageDown);
    await _key(tester, LogicalKeyboardKey.pageDown);
    expect(_ringOn(tester, find.text('Item 18')), isTrue);
    final ring = tester.getRect(_ring);
    expect(ring.bottom, lessThanOrEqualTo(400 + 48), reason: 'on screen');
    await _key(tester, LogicalKeyboardKey.pageUp);
    expect(_ringOn(tester, find.text('Item 12')), isTrue);
  });

  testWidgets('Enter opens the row and Space selects it', (tester) async {
    final opened = <int>[];
    await _pump(
      tester,
      _Harness(rows: _items, onRowTap: (r) => opened.add(r.id)),
    );
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(opened, [1]);

    final handle = tester.ensureSemantics();
    await _key(tester, LogicalKeyboardKey.space);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Select row 2')),
      isSemantics(isChecked: true),
    );
    await _key(tester, LogicalKeyboardKey.space);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Select row 2')),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    handle.dispose();
  });

  testWidgets('Enter or Space on a header sorts', (tester) async {
    final sorts = <(String, bool)>[];
    await _pump(
      tester,
      _Harness(rows: _items, onSort: (k, a) => sorts.add((k, a))),
    );
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_ringOn(tester, find.text('Name')), isTrue);
    await _key(tester, LogicalKeyboardKey.enter);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.space);
    expect(sorts, [('name', true), ('price', true)]);
  });

  testWidgets('Alt+←/→ on a header resizes by 16, 8 with Shift', (
    tester,
  ) async {
    final live = <double>[];
    final ends = <double>[];
    await _pump(
      tester,
      _Harness(
        rows: _items,
        onColumnResize: (_, w) => live.add(w),
        onColumnResizeEnd: (_, w) => ends.add(w),
      ),
    );
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.end);
    await _chord(
      tester,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.arrowRight,
    );
    expect(live, [136]);
    expect(ends, [136]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await _chord(
      tester,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.arrowLeft,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(ends, [136, 128]);
    expect(tester.getSize(find.text('Price').hitTestable()), isNotNull);
  });

  testWidgets('Alt+↓ opens the column menu; Escape returns to the header', (
    tester,
  ) async {
    await _pump(tester, _Harness(rows: _items, onSort: (_, _) {}));
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.end);
    await _chord(
      tester,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.arrowDown,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sort ascending'), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Sort ascending',
      reason: 'a keyboard open focuses the first item',
    );

    await _key(tester, LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Sort ascending'), findsNothing);
    expect(_gridFocused, isTrue);
    expect(_ringOn(tester, find.text('Price')), isTrue);
  });

  testWidgets('Shift+F10 opens the column menu too', (tester) async {
    await _pump(tester, _Harness(rows: _items, onSort: (_, _) {}));
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _chord(tester, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.f10);
    await tester.pumpAndSettle();
    expect(find.text('Hide column'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('a click moves the focused cell without a ring', (tester) async {
    await _pump(tester, _Harness(rows: _items));
    await tester.tap(find.text('Item 2'));
    await tester.pump();
    expect(_gridFocused, isTrue);
    expect(_ring, findsNothing);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_ringOn(tester, find.text('Item 3')), isTrue);
  });

  testWidgets('a control in a cell keeps its arrows; Escape or F2 leaves it', (
    tester,
  ) async {
    final notes = {
      for (final item in _items.take(3))
        item.id: TextEditingController(text: 'note ${item.id}'),
    };
    addTearDown(() {
      for (final c in notes.values) {
        c.dispose();
      }
    });
    await _pump(
      tester,
      Column(
        children: [
          TextButton(onPressed: () {}, child: const Text('Before')),
          SizedBox(
            width: 800,
            height: 400,
            child: CollectionTable<_Item>(
              rows: _items.take(3).toList(),
              rowKey: (r) => r.id,
              columns: [
                TableColumn(label: 'Name', cell: (r) => Text(r.name)),
                TableColumn(
                  label: 'Note',
                  cell: (r) => TextField(controller: notes[r.id]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_gridFocused, isFalse);
    final note = notes[0]!;
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextField>()
          ?.controller,
      note,
    );

    note.selection = const TextSelection.collapsed(offset: 4);
    for (final key in [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.home,
    ]) {
      await _key(tester, key);
      expect(_gridFocused, isFalse, reason: '$key stays in the field');
    }
    expect(note.selection.baseOffset, 0, reason: 'the field moved its caret');

    await _key(tester, LogicalKeyboardKey.escape);
    expect(_gridFocused, isTrue);
    expect(_ringOn(tester, find.byType(TextField).first), isTrue);

    await _key(tester, LogicalKeyboardKey.enter);
    expect(_gridFocused, isFalse);
    await _key(tester, LogicalKeyboardKey.f2);
    expect(_gridFocused, isTrue);
  });
}
