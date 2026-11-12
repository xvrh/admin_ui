import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/collection/ui/table_edit_session.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A table whose rows open on a tap can still edit a cell from a pointer,
// with editTrigger: TableEditTrigger.doubleTap.

class _Item {
  final int id;
  String name;
  _Item(this.id, this.name);
}

List<_Item> _items() => [_Item(1, 'Alpha'), _Item(2, 'Bravo')];

/// A table whose Name edits and whose ID doesn't, opening rows into
/// [opened].
Future<List<int>> _pump(
  WidgetTester tester, {
  TableEditTrigger trigger = TableEditTrigger.doubleTap,
  bool rowTap = true,
  bool Function(_Item row)? canOpen,
}) async {
  final opened = <int>[];
  final items = _items();
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            height: 400,
            child: StatefulBuilder(
              builder: (context, setState) => CollectionTable<_Item>(
                rows: items,
                rowKey: (r) => r.id,
                onRowTap: rowTap ? (r) => opened.add(r.id) : null,
                canOpen: canOpen,
                editTrigger: trigger,
                columns: [
                  TableColumn(
                    id: 'id',
                    label: 'ID',
                    fixed: 80,
                    cell: (r) => Text('#${r.id}'),
                  ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return opened;
}

/// Two taps on [finder] [gap] apart, then a pump: a double tap when [gap]
/// is inside the tester's double-tap window.
Future<void> _doubleTap(
  WidgetTester tester,
  Finder finder, {
  Duration gap = const Duration(milliseconds: 60),
}) async {
  await tester.tap(finder);
  await tester.pump(gap);
  await tester.tap(finder);
  await tester.pump();
}

Finder get _editor => find.byType(EditableText);

/// Every node of the semantics tree that offers a tap.
int _tapActions() => find.semantics
    .byPredicate((n) => n.getSemanticsData().hasAction(SemanticsAction.tap))
    .evaluate()
    .length;

void main() {
  testWidgets('a row canOpen leaves out opens on no tap and no Enter, and '
      'edits as in a table with no row tap', (tester) async {
    final handle = tester.ensureSemantics();
    final opened = await _pump(
      tester,
      trigger: TableEditTrigger.auto,
      canOpen: (r) => r.id != 2,
    );
    // Row 1 alone offers its open action.
    expect(_tapActions(), 1);

    await tester.tap(find.text('#2'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, isEmpty);

    await _doubleTap(tester, find.text('Bravo'));
    expect(tester.widget<EditableText>(_editor).controller.text, 'Bravo');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(kDoubleTapTimeout);
    expect(opened, isEmpty);

    await tester.tap(find.text('#1'));
    await tester.pump();
    expect(opened, [1]);
    handle.dispose();
  });

  group('doubleTap, with a row tap', () {
    testWidgets('a single tap on an editable cell opens the row once the '
        'double-tap window has passed', (tester) async {
      final opened = await _pump(tester);
      await tester.tap(find.text('Alpha'));
      await tester.pump(kDoubleTapTimeout - const Duration(milliseconds: 10));
      expect(opened, isEmpty, reason: 'still inside the window');
      await tester.pump(const Duration(milliseconds: 20));
      expect(opened, [1]);
      expect(_editor, findsNothing);
    });

    testWidgets('a double tap on an editable cell edits it and opens nothing', (
      tester,
    ) async {
      final opened = await _pump(tester);
      await _doubleTap(tester, find.text('Alpha'));
      expect(_editor, findsOneWidget);
      expect(tester.widget<EditableText>(_editor).controller.text, 'Alpha');
      await tester.pump(kDoubleTapTimeout * 2);
      expect(opened, isEmpty);
    });

    testWidgets('two taps further apart than the window open the row twice', (
      tester,
    ) async {
      final opened = await _pump(tester);
      await _doubleTap(
        tester,
        find.text('Alpha'),
        gap: kDoubleTapTimeout + const Duration(milliseconds: 50),
      );
      await tester.pump(kDoubleTapTimeout);
      expect(opened, [1, 1]);
      expect(_editor, findsNothing);
    });

    testWidgets('a tap on a cell that does not edit opens its row at once', (
      tester,
    ) async {
      final opened = await _pump(tester);
      await tester.tap(find.text('#2'));
      await tester.pump();
      expect(opened, [2]);
    });

    testWidgets('a double click works too', (tester) async {
      final opened = await _pump(tester);
      final at = tester.getCenter(find.text('Bravo'));
      // A mouse press is a pointer of its own each time, as the engine
      // numbers them.
      for (var i = 0; i < 2; i++) {
        final click = await tester.startGesture(
          at,
          kind: PointerDeviceKind.mouse,
          pointer: 20 + i,
        );
        await click.up();
        await click.removePointer();
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(_editor, findsOneWidget);
      await tester.pump(kDoubleTapTimeout);
      expect(opened, isEmpty);
    });

    testWidgets('Enter opens the row and F2 edits, as before', (tester) async {
      final opened = await _pump(tester);
      // Focus lands on the ID cell of the first row; Enter there opens it.
      await tester.tap(find.text('#1'));
      await tester.pump(kDoubleTapTimeout);
      opened.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, [1]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.pump();
      expect(_editor, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(_editor, findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(_editor, findsOneWidget, reason: 'Enter edits an editable cell');
      expect(opened, [1]);
    });

    testWidgets('the row\'s open action is announced once, and runs at once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, trigger: TableEditTrigger.auto);
      final auto = _tapActions();

      final opened = await _pump(tester);
      expect(_tapActions(), auto);
      expect(
        tester.getSemantics(find.text('#1')),
        isSemantics(hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.text('Alpha')),
        isSemantics(hasTapAction: false),
      );
      tester.semantics.tap(find.semantics.byLabel('#1'));
      await tester.pump();
      expect(opened, [1], reason: 'assistive technology waits for nothing');
      semantics.dispose();
    });
  });

  group('auto', () {
    testWidgets('with a row tap, a tap opens at once and a double tap does '
        'not edit', (tester) async {
      final opened = await _pump(tester, trigger: TableEditTrigger.auto);
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      expect(opened, [1]);
      await _doubleTap(tester, find.text('Alpha'));
      expect(_editor, findsNothing);
    });

    testWidgets('without a row tap, a double tap edits', (tester) async {
      await _pump(tester, trigger: TableEditTrigger.auto, rowTap: false);
      await _doubleTap(tester, find.text('Alpha'));
      expect(_editor, findsOneWidget);
      await tester.pump(kDoubleTapTimeout);
    });
  });

  testWidgets('doubleTap without a row tap edits as auto does', (tester) async {
    await _pump(tester, rowTap: false);
    await _doubleTap(tester, find.text('Bravo'));
    expect(_editor, findsOneWidget);
    await tester.pump(kDoubleTapTimeout);
  });
}
