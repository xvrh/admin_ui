import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/collection/ui/table_edit_session.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 800, height: 400, child: child)),
);

const _rows = ['Alpha', 'Bravo', 'Cherry'];

List<TableColumn<String>> _cols({String? sortKey}) => [
  TableColumn(label: 'Name', sortKey: sortKey, cell: (r) => Text(r)),
];

void main() {
  testWidgets('renders rows and fires onSort from a sortable header', (
    tester,
  ) async {
    Object? key;
    bool? ascending;
    await tester.pumpWidget(
      _host(
        CollectionTable<String>(
          rows: _rows,
          columns: _cols(sortKey: 'name'),
          onSort: (k, a) {
            key = k;
            ascending = a;
          },
        ),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Cherry'), findsOneWidget);

    await tester.tap(find.text('Name'));
    await tester.pump();
    expect(key, 'name');
    expect(ascending, isTrue);
  });

  testWidgets('checkbox column toggles a row and select-all toggles the page', (
    tester,
  ) async {
    var selected = <String>{};
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => CollectionTable<String>(
            rows: _rows,
            rowKey: (r) => r,
            columns: _cols(),
            selected: selected,
            onSelectionChanged: (s) => setState(() => selected = s),
          ),
        ),
      ),
    );

    // Iris: a 44px checkbox column, a 44px header and 52px rows.
    await tester.tapAt(const Offset(22, 22)); // select-all in the header
    await tester.pump();
    expect(selected, _rows.toSet());

    await tester.tapAt(const Offset(22, 70)); // first row → deselect
    await tester.pump();
    expect(selected, {'Bravo', 'Cherry'});
  });

  testWidgets('dragging a header edge resizes the column', (tester) async {
    final widths = <double>[];
    await tester.pumpWidget(
      _host(
        CollectionTable<String>(
          rows: _rows,
          columns: [
            TableColumn(label: 'Name', fixed: 200, cell: (r) => Text(r)),
          ],
          onColumnResize: (_, w) => widths.add(w),
        ),
      ),
    );

    // Handle sits at the cell's trailing edge (column is 200px wide).
    await tester.dragFrom(const Offset(197, 22), const Offset(80, 0));
    await tester.pump(kDoubleTapTimeout);
    expect(widths.last, closeTo(280, 1));
  });

  testWidgets('resize clamps to the column minWidth', (tester) async {
    double? last;
    await tester.pumpWidget(
      _host(
        CollectionTable<String>(
          rows: _rows,
          columns: [
            TableColumn(
              label: 'Name',
              fixed: 200,
              minWidth: 120,
              cell: (r) => Text(r),
            ),
          ],
          onColumnResize: (_, w) => last = w,
        ),
      ),
    );

    await tester.dragFrom(const Offset(197, 22), const Offset(-150, 0));
    await tester.pump(kDoubleTapTimeout);
    expect(last, 120);
  });

  testWidgets('double-tap enters inline edit; Enter commits and closes', (
    tester,
  ) async {
    final names = ['Alpha', 'Bravo', 'Cherry'];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => CollectionTable<int>(
            rows: List.generate(names.length, (i) => i),
            rowKey: (i) => i,
            columns: [
              TableColumn<int>(
                label: 'Name',
                cell: (i) => Text(names[i]),
                editBuilder: (i, session) => TableTextEditor(
                  session: session,
                  value: names[i],
                  onCommit: (v) => setState(() => names[i] = v),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Alpha'));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Renamed'), findsOneWidget);
    await tester.pump(kDoubleTapTimeout);
  });

  testWidgets('Escape leaves inline edit with the value unchanged', (
    tester,
  ) async {
    var name = 'Alpha';
    await tester.pumpWidget(
      _host(
        CollectionTable<int>(
          rows: const [0],
          rowKey: (i) => i,
          columns: [
            TableColumn<int>(
              label: 'Name',
              cell: (_) => Text(name),
              editBuilder: (_, session) => TableTextEditor(
                session: session,
                value: name,
                onCommit: (v) => name = v,
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Alpha'));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Changed');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(name, 'Alpha');
    await tester.pump(kDoubleTapTimeout);
  });

  testWidgets('empty slot shows when there are no rows', (tester) async {
    await tester.pumpWidget(
      _host(
        CollectionTable<String>(
          rows: const [],
          columns: _cols(),
          empty: const Text('Nothing here'),
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('error slot takes precedence over rows', (tester) async {
    await tester.pumpWidget(
      _host(
        CollectionTable<String>(
          rows: _rows,
          columns: _cols(),
          error: const Text('Boom'),
        ),
      ),
    );
    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('hover washes a striped row instead of replacing its stripe', (
    tester,
  ) async {
    const colors = irisDarkPalette;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: colors)),
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 400,
            child: CollectionTable<String>(
              rows: _rows,
              columns: _cols(),
              striped: true,
            ),
          ),
        ),
      ),
    );
    Color fill(int row) {
      final table = tester.widget<TwoDimensionalScrollView>(
        find.byWidgetPredicate((w) => w is TwoDimensionalScrollView),
      );
      final delegate = table.delegate as TableCellBuilderDelegate;
      return delegate.buildRow(row + 1)!.backgroundDecoration!.color!;
    }

    Iterable<Color> washes() => tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((b) => b.color)
        .where((c) => c == colors.tableRowHover);

    expect(fill(0), colors.surface);
    expect(fill(1), colors.tableRowStripe);
    expect(washes(), isEmpty);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Bravo')));
    await tester.pump();
    expect(fill(1), colors.tableRowStripe, reason: 'the stripe stays');
    expect(washes(), hasLength(1), reason: 'one wash, over the hovered row');
    await mouse.removePointer();
  });

  testWidgets('rows are plain unless striped', (tester) async {
    await tester.pumpWidget(
      _host(CollectionTable<String>(rows: _rows, columns: _cols())),
    );
    final table = tester.widget<TwoDimensionalScrollView>(
      find.byWidgetPredicate((w) => w is TwoDimensionalScrollView),
    );
    final delegate = table.delegate as TableCellBuilderDelegate;
    for (var i = 0; i < _rows.length; i++) {
      expect(
        delegate.buildRow(i + 1)!.backgroundDecoration!.color,
        irisPalette.surface,
      );
    }
  });

  for (final base in [irisPalette, irisDarkPalette]) {
    testWidgets('stripes stay neutral under a brand '
        '(${base.brightness.name})', (tester) async {
      final colors = base.branded(const Color(0xFFD97706));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: colors)),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: CollectionTable<String>(
                rows: _rows,
                rowKey: (r) => r,
                columns: _cols(),
                striped: true,
                selected: {_rows[2]},
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      final table = tester.widget<TwoDimensionalScrollView>(
        find.byWidgetPredicate((w) => w is TwoDimensionalScrollView),
      );
      final delegate = table.delegate as TableCellBuilderDelegate;
      Color fill(int row) =>
          delegate.buildRow(row + 1)!.backgroundDecoration!.color!;

      expect(
        fill(1),
        base.tableRowStripe,
        reason: 'the stripe ignores the brand',
      );
      expect(fill(2), colors.tableRowSelected);
    });
  }
}
