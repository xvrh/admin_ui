import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/collection/ui/table_edit_session.dart';
import 'package:admin_ui/src/common/ui/menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Item {
  final int id;
  String name;
  num price;
  _Item(this.id, this.name, this.price);
}

/// An editable table: Name and Price edit, ID doesn't. [descending] flips
/// the row order, as a sort would.
class _Harness extends StatefulWidget {
  final List<_Item> items;
  final void Function(_Item row)? onRowTap;

  const _Harness({required this.items, this.onRowTap});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool descending = false;
  bool dropFirst = false;

  void resort() => setState(() => descending = !descending);
  void dropRow() => setState(() => dropFirst = true);

  @override
  Widget build(BuildContext context) {
    var rows = [...widget.items];
    if (dropFirst) rows = rows.skip(1).toList();
    if (descending) rows = rows.reversed.toList();
    return Column(
      children: [
        TextButton(onPressed: () {}, child: const Text('Outside')),
        SizedBox(
          width: 800,
          height: 400,
          child: CollectionTable<_Item>(
            rows: rows,
            rowKey: (r) => r.id,
            onRowTap: widget.onRowTap,
            columns: [
              TableColumn(
                id: 'name',
                label: 'Name',
                cell: (r) => Text(r.name),
                editBuilder: (r, session) => TableTextEditor(
                  session: session,
                  value: r.name,
                  onCommit: (v) => setState(() => r.name = v),
                ),
              ),
              TableColumn(
                id: 'price',
                label: 'Price',
                fixed: 140,
                numeric: true,
                cell: (r) => Text('${r.price}'),
                editBuilder: (r, session) => TableTextEditor.number(
                  session: session,
                  value: r.price,
                  onCommit: (v) => setState(() => r.price = v),
                ),
              ),
              TableColumn(
                id: 'id',
                label: 'ID',
                fixed: 80,
                cell: (r) => Text('#${r.id}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<_Item> _items() => [
  _Item(1, 'Alpha', 10),
  _Item(2, 'Bravo', 20),
  _Item(3, 'Cherry', 30),
  _Item(4, 'Delta', 40),
];

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
  await tester.pump();
}

/// Clicks [text]'s cell, which becomes the focused cell.
Future<void> _focusCell(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  // Past the double-tap window: this is one tap.
  await tester.pump(kDoubleTapTimeout);
}

EditableText _editor(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

bool get _gridFocused =>
    FocusManager.instance.primaryFocus?.debugLabel == 'CollectionTable';

void main() {
  testWidgets('F2 opens the editor, focused, with its text selected', (
    tester,
  ) async {
    await _pump(tester, _Harness(items: _items()));
    await _focusCell(tester, 'Bravo');
    await _key(tester, LogicalKeyboardKey.f2);
    final editor = _editor(tester);
    expect(editor.controller.text, 'Bravo');
    expect(editor.focusNode.hasPrimaryFocus, isTrue);
    expect(
      editor.controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
  });

  testWidgets('Escape closes the editor and keeps the old value', (
    tester,
  ) async {
    final items = _items();
    await _pump(tester, _Harness(items: items));
    await _focusCell(tester, 'Bravo');
    await _key(tester, LogicalKeyboardKey.f2);
    await tester.enterText(find.byType(TextField), 'Changed');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.byType(TextField), findsNothing);
    expect(items[1].name, 'Bravo');
    expect(find.text('Bravo'), findsOneWidget);
    expect(_gridFocused, isTrue, reason: 'focus returns to the cell');
  });

  testWidgets('Enter commits', (tester) async {
    final items = _items();
    await _pump(tester, _Harness(items: items));
    await _focusCell(tester, 'Bravo');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.byType(TextField), findsOneWidget, reason: 'Enter edits too');
    await tester.enterText(find.byType(TextField), 'Renamed');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.byType(TextField), findsNothing);
    expect(items[1].name, 'Renamed');
    expect(_gridFocused, isTrue);
  });

  testWidgets('a tap outside commits', (tester) async {
    final items = _items();
    await _pump(tester, _Harness(items: items));
    await _focusCell(tester, 'Cherry');
    await _key(tester, LogicalKeyboardKey.f2);
    await tester.enterText(find.byType(TextField), 'Clicked away');
    await tester.tap(find.text('Outside'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(items[2].name, 'Clicked away');
  });

  testWidgets('Tab commits and edits the next editable cell', (tester) async {
    final items = _items();
    await _pump(tester, _Harness(items: items));
    await _focusCell(tester, 'Alpha');
    await _key(tester, LogicalKeyboardKey.f2);
    await tester.enterText(find.byType(TextField), 'A');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(items[0].name, 'A');
    expect(_editor(tester).controller.text, '10', reason: 'Price, same row');

    await _key(tester, LogicalKeyboardKey.tab);
    expect(
      _editor(tester).controller.text,
      'Bravo',
      reason: 'ID is read-only: on to the next row',
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await _key(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(_editor(tester).controller.text, '10', reason: 'Shift+Tab: back');
  });

  testWidgets('an invalid number keeps the editor open', (tester) async {
    final items = _items();
    await _pump(tester, _Harness(items: items));
    await _focusCell(tester, '20');
    await _key(tester, LogicalKeyboardKey.f2);
    await tester.enterText(find.byType(TextField), 'twenty');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.byType(TextField), findsOneWidget);
    expect(items[1].price, 20);

    await tester.enterText(find.byType(TextField), '25.5');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.byType(TextField), findsNothing);
    expect(items[1].price, 25.5);
  });

  testWidgets('the editor follows its record across a sort', (tester) async {
    final items = _items();
    await _pump(tester, _Harness(items: items));
    await _focusCell(tester, 'Bravo');
    await _key(tester, LogicalKeyboardKey.f2);
    await tester.enterText(find.byType(TextField), 'Bravo draft');
    final before = tester.getRect(find.byType(TextField));

    tester.state<_HarnessState>(find.byType(_Harness)).resort();
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(_editor(tester).controller.text, 'Bravo draft');
    // Row 2 of 4 is row 3 of 4 once reversed: one row (52px) lower.
    expect(tester.getRect(find.byType(TextField)).top, before.top + 52);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(items[1].name, 'Bravo draft');
    expect(items[2].name, 'Cherry');
  });

  testWidgets('the editor closes when its record leaves the page', (
    tester,
  ) async {
    final items = _items();
    await _pump(tester, _Harness(items: items));
    await _focusCell(tester, 'Alpha');
    await _key(tester, LogicalKeyboardKey.f2);
    await tester.enterText(find.byType(TextField), 'Gone');

    tester.state<_HarnessState>(find.byType(_Harness)).dropRow();
    await tester.pump();
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(items[0].name, 'Alpha');
  });

  testWidgets('with a row tap, a double tap never waits: it opens the row', (
    tester,
  ) async {
    final opened = <int>[];
    await _pump(
      tester,
      _Harness(items: _items(), onRowTap: (r) => opened.add(r.id)),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Alpha')));
    await mouse.down(tester.getCenter(find.text('Alpha')));
    await mouse.up();
    await tester.pump();
    expect(opened, [1], reason: 'fired on the first tap');
    expect(find.byType(TextField), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('a pick in a menu the editor opened lands, then commits', (
    tester,
  ) async {
    var status = 'Draft';
    final ends = <bool>[];
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 800,
          height: 400,
          child: CollectionTable<_Item>(
            rows: [_Item(1, 'Alpha', 10)],
            rowKey: (r) => r.id,
            columns: [
              TableColumn(
                label: 'Status',
                cell: (_) => Text(status),
                editBuilder: (r, session) {
                  final onEnd = session.onCancel;
                  session.onCancel = () {
                    onEnd?.call();
                    ends.add(false);
                  };
                  return Menu(
                    entries: [
                      for (final option in ['Draft', 'Live'])
                        MenuItem(
                          option,
                          onSelect: () {
                            session.onCommit = () {
                              setState(() => status = option);
                              ends.add(true);
                              return true;
                            };
                            session.commit();
                          },
                        ),
                    ],
                    builder: (context, menu) => TextButton(
                      onPressed: menu.toggle,
                      child: Text('Pick $status'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await _focusCell(tester, 'Draft');
    await _key(tester, LogicalKeyboardKey.f2);
    await tester.tap(find.text('Pick Draft'));
    await tester.pumpAndSettle();
    expect(find.text('Live'), findsOneWidget);

    await tester.tap(find.text('Live'));
    await tester.pumpAndSettle();
    expect(ends, [true], reason: 'the pick committed, and nothing else did');
    expect(status, 'Live');
    expect(find.text('Pick Live'), findsNothing, reason: 'the editor closed');
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('a table torn down mid-edit cancels the edit', (tester) async {
    EditSession? open;
    var cancelled = 0;
    await _pump(
      tester,
      SizedBox(
        width: 800,
        height: 400,
        child: CollectionTable<_Item>(
          rows: [_Item(1, 'Alpha', 10)],
          rowKey: (r) => r.id,
          columns: [
            TableColumn(
              label: 'Name',
              cell: (r) => Text(r.name),
              editBuilder: (r, session) {
                open = session..onCancel = () => cancelled++;
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
    await _focusCell(tester, 'Alpha');
    await _key(tester, LogicalKeyboardKey.f2);
    expect(open?.isActive, isTrue);

    await _pump(tester, const SizedBox());
    expect(cancelled, 1);
    expect(open!.isActive, isFalse);
  });

  test('a session ends once', () {
    final ends = <bool>[];
    final session = EditSession(label: 'Name', onEnd: ends.add)
      ..onCommit = () => false;
    expect(session.commit(), isFalse);
    expect(session.isActive, isTrue);
    session.onCommit = () => true;
    expect(session.commit(), isTrue);
    session.cancel();
    expect(ends, [true]);
    expect(session.isActive, isFalse);
  });
}
