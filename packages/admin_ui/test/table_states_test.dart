import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/common/ui/delayed_loading.dart';
import 'package:admin_ui/src/common/ui/focus_ring.dart';
import 'package:admin_ui/src/common/ui/skeleton.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Row {
  final int id;
  final String name;
  const _Row(this.id, this.name);
}

const _rows = [_Row(1, 'Alpha'), _Row(2, 'Bravo'), _Row(3, 'Cherry')];

/// Columns 820px wide in all, the first pinned.
List<TableColumn<_Row>> _columns() => [
  TableColumn(
    label: 'Product',
    flex: 2,
    minWidth: 220,
    pinned: true,
    cell: (r) => Text(r.name),
  ),
  TableColumn(label: 'Status', fixed: 140, cell: (_) => const Text('Live')),
  TableColumn(label: 'Category', fixed: 140, cell: (_) => const Text('Home')),
  TableColumn(
    label: 'Price',
    fixed: 100,
    numeric: true,
    cell: (_) => const Text('1'),
  ),
  TableColumn(
    label: 'Stock',
    fixed: 90,
    numeric: true,
    cell: (_) => const Text('2'),
  ),
  TableColumn(label: 'Updated', fixed: 130, cell: (_) => const Text('Today')),
];

Future<void> _pump(
  WidgetTester tester,
  Widget table, {
  double width = 800,
  double height = 400,
}) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, height: height, child: table),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a first load shows skeleton rows under the real header', (
    tester,
  ) async {
    await _pump(
      tester,
      CollectionTable<_Row>(rows: const [], loading: true, columns: _columns()),
    );
    expect(find.byType(Skeleton), findsNothing, reason: 'not before 150ms');
    expect(find.text('Nothing here yet'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Product'), findsOneWidget);
    expect(find.byType(TopProgressBar), findsOneWidget);
    final bars = tester.widgetList<Skeleton>(find.byType(Skeleton));
    expect(bars, isNotEmpty);
    // One bar a row, each centred on a 52px row under the 44px header.
    final first = tester.getRect(find.byType(Skeleton).first);
    expect(first.center.dy, 44 + 26);
  });

  testWidgets('a refetch dims the rows, not the header, and holds taps', (
    tester,
  ) async {
    final taps = <int>[];
    Widget table(bool loading) => CollectionTable<_Row>(
      rows: _rows,
      rowKey: (r) => r.id,
      loading: loading,
      onRowTap: (r) => taps.add(r.id),
      selected: const {},
      onSelectionChanged: (_) {},
      columns: _columns(),
    );
    await _pump(tester, table(true));
    await tester.pump(const Duration(milliseconds: 200));

    final scrims = find.byWidgetPredicate(
      (w) =>
          w is ColoredBox &&
          w.color == defaultTokens.palette.surface.withValues(alpha: 0.45),
    );
    expect(scrims, findsOneWidget);
    expect(tester.getRect(scrims).top, 44, reason: 'starts under the header');
    expect(
      find.byType(Opacity).evaluate().where((e) {
        return (e.widget as Opacity).opacity < 1 &&
            find
                .descendant(
                  of: find.byWidget(e.widget),
                  matching: find.text('Product'),
                )
                .evaluate()
                .isNotEmpty;
      }),
      isEmpty,
      reason: 'nothing fades the header',
    );

    await tester.tap(find.text('Alpha'), warnIfMissed: false);
    await tester.pump();
    expect(taps, isEmpty);

    await _pump(tester, table(false));
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    expect(taps, [1]);
  });

  testWidgets('a refetch holds Enter, Space and F2, not the arrows', (
    tester,
  ) async {
    final taps = <int>[];
    final selections = <Set<_Row>>[];
    final edits = <int>[];
    Widget table(bool loading) => CollectionTable<_Row>(
      rows: _rows,
      rowKey: (r) => r.id,
      loading: loading,
      onRowTap: (r) => taps.add(r.id),
      selected: const {},
      onSelectionChanged: selections.add,
      columns: [
        TableColumn(
          label: 'Product',
          cell: (r) => Text(r.name),
          editBuilder: (r, session) {
            edits.add(r.id);
            return const SizedBox();
          },
        ),
      ],
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await _pump(tester, table(true));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final ring = find.byWidgetPredicate((w) => w is FocusRing && w.focused);
    expect(
      tester.getRect(ring).contains(tester.getCenter(find.text('Bravo'))),
      isTrue,
      reason: 'the arrows still move',
    );
    for (final key in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.f2,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    expect(taps, isEmpty);
    expect(selections, isEmpty);
    expect(edits, isEmpty);

    await _pump(tester, table(false));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(selections, hasLength(1), reason: 'the rows are live again');
  });

  for (final (name, table) in [
    ('empty', CollectionTable<_Row>(rows: const [], columns: _columns())),
    (
      'error',
      CollectionTable<_Row>(
        rows: _rows,
        error: const Text("Couldn't load"),
        columns: _columns(),
      ),
    ),
    (
      'no results',
      CollectionTable<_Row>(
        rows: const [],
        filtered: true,
        onClearFilters: () {},
        columns: _columns(),
      ),
    ),
  ]) {
    testWidgets('the $name body fits a 360px table of 820px of columns', (
      tester,
    ) async {
      await _pump(tester, table, width: 360, height: 300);
      expect(tester.takeException(), isNull);
      // The header scrolls to its last column.
      expect(find.text('Updated'), findsNothing);
      await tester.drag(find.text('Status'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Updated'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the default empty body; a filtered one offers to clear', (
    tester,
  ) async {
    await _pump(
      tester,
      CollectionTable<_Row>(rows: const [], columns: _columns()),
    );
    expect(find.text('Nothing here yet'), findsOneWidget);

    var cleared = 0;
    await _pump(
      tester,
      CollectionTable<_Row>(
        rows: const [],
        filtered: true,
        onClearFilters: () => cleared++,
        empty: const Text('No products yet'),
        columns: _columns(),
      ),
    );
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('No products yet'), findsNothing);
    await tester.tap(find.text('Clear filters'));
    expect(cleared, 1);
  });

  testWidgets('pinning relaxes when the frozen columns crowd the viewport', (
    tester,
  ) async {
    await _pump(
      tester,
      CollectionTable<_Row>(rows: _rows, columns: _columns()),
      width: 360,
    );
    await tester.drag(find.text('Alpha'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Alpha')).right,
      lessThan(0),
      reason: 'Product (220 of 360px) scrolls away',
    );

    await _pump(
      tester,
      CollectionTable<_Row>(rows: _rows, columns: _columns()),
      width: 600,
    );
    await tester.drag(find.text('Alpha'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Alpha')).left, 12, reason: 'stays put');
  });

  testWidgets('the pinned edge shows its rule once content scrolls under it', (
    tester,
  ) async {
    Finder rule() => find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == defaultTokens.palette.border,
    );
    await _pump(
      tester,
      CollectionTable<_Row>(rows: _rows, columns: _columns()),
      width: 600,
    );
    await tester.pump();
    expect(rule(), findsNothing);
    await tester.drag(find.text('Live').first, const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(rule(), findsOneWidget);
    expect(tester.getRect(rule()).left, 219, reason: 'the last pinned px');
  });
}
