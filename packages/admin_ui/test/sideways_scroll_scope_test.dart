import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

const _header = Offset(400, 30);
const _rows = Offset(400, 300);

void main() {
  group('over a wide table', () {
    testWidgets('the browser gets no event, and the table still scrolls', (
      tester,
    ) async {
      final table = await _pumpWideTable(tester, width: 3000);

      expect(await _wheel(tester, _rows, const Offset(400, 0)), [false]);
      expect(table.sideways.offset, 400);
      // A swipe that starts a little off its axis, with the rows at their
      // top, or over the header that does not scroll up and down.
      expect(await _wheel(tester, _rows, const Offset(0, -2)), [false]);
      expect(await _wheel(tester, _header, const Offset(0, 3)), [false]);
      expect(await _wheel(tester, _rows, const Offset(0, 90)), [false]);
      expect(table.rows.offset, 90);

      // Back to the start, and on past it.
      await _wheel(tester, _rows, const Offset(-5000, 0));
      expect(table.sideways.offset, 0);
      expect(await _wheel(tester, _rows, const Offset(-5, 0)), [false]);
    });

    testWidgets('that fits, the browser gets what nothing uses', (
      tester,
    ) async {
      await _pumpWideTable(tester, width: 700);
      expect(await _wheel(tester, _rows, const Offset(-5, 0)), [true]);
    });

    testWidgets('a page around it still scrolls up and down over it', (
      tester,
    ) async {
      final page = ScrollController();
      addTearDown(page.dispose);
      await _pump(
        tester,
        ListView(
          controller: page,
          children: [
            const SizedBox(height: 100),
            const SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: 3000, height: 300),
              ),
            ),
            const SizedBox(height: 1000),
          ],
        ),
      );

      expect(await _wheel(tester, _rows, const Offset(0, 50)), [false]);
      expect(page.offset, 50);
      await _wheel(tester, _rows, const Offset(0, -500));
      expect(page.offset, 0);
      expect(await _wheel(tester, _rows, const Offset(-5, -2)), [false]);
    });
  });

  testWidgets('over a page that does not scroll sideways, the browser '
      'keeps its back swipe', (tester) async {
    await _pump(
      tester,
      ListView(children: [for (var i = 0; i < 100; i++) Text('row $i')]),
    );
    expect(await _wheel(tester, _rows, const Offset(-5, 0)), [true]);
    expect(await _wheel(tester, _rows, const Offset(0, -2)), [true]);
  });

  testWidgets('a TableView, whose chrome has no scrollbar, is covered', (
    tester,
  ) async {
    await _pump(
      tester,
      TableView.builder(
        columnCount: 20,
        rowCount: 50,
        columnBuilder: (_) =>
            const TableSpan(extent: FixedTableSpanExtent(200)),
        rowBuilder: (_) => const TableSpan(extent: FixedTableSpanExtent(40)),
        cellBuilder: (context, vicinity) =>
            TableViewCell(child: Text('${vicinity.row}:${vicinity.column}')),
      ),
    );
    expect(await _wheel(tester, _rows, const Offset(-5, 0)), [false]);
    expect(await _wheel(tester, _rows, const Offset(0, -2)), [false]);
  });
}

Future<void> _pump(WidgetTester tester, Widget page) => tester.pumpWidget(
  MaterialApp(
    theme: buildAppTheme(defaultTokens),
    home: AdminScope(child: page),
  ),
);

/// A header over a list of rows, in a view that scrolls sideways.
Future<({ScrollController sideways, ScrollController rows})> _pumpWideTable(
  WidgetTester tester, {
  required double width,
}) async {
  final sideways = ScrollController();
  final rows = ScrollController();
  addTearDown(sideways.dispose);
  addTearDown(rows.dispose);
  await _pump(
    tester,
    SingleChildScrollView(
      controller: sideways,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: ListView.builder(
                controller: rows,
                itemCount: 200,
                itemExtent: 30,
                itemBuilder: (context, i) => Text('row $i'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return (sideways: sideways, rows: rows);
}

/// What the app answered the browser for one trackpad scroll: `true` lets the
/// browser act on it, which for a sideways swipe on a Mac is "back".
Future<List<bool>> _wheel(WidgetTester tester, Offset at, Offset delta) async {
  final answers = <bool>[];
  await tester.sendEventToBinding(
    PointerScrollEvent(
      kind: PointerDeviceKind.trackpad,
      position: at,
      scrollDelta: delta,
      onRespond: ({required allowPlatformDefault}) =>
          answers.add(allowPlatformDefault),
    ),
  );
  await tester.pump();
  return answers;
}
