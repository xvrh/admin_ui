import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/common/ui/tappable.dart';
import 'package:admin_ui/src/common/ui/tip.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class _Row {
  final String name;
  final double price;
  const _Row(this.name, this.price);
}

const _rows = [_Row('Coat', 248), _Row('Boots', 179.5), _Row('Scarf', 18)];

Future<void> _pump(
  WidgetTester tester, {
  TableSort? sort,
  void Function(String, bool)? onSort,
  VoidCallback? onClearSort,
  void Function(String, double)? onColumnResize,
  void Function(String, double)? onColumnResizeEnd,
  Map<String, double>? columnWidths,
  List<TableColumn<_Row>>? columns,
  AdminTokens? tokens,
}) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? defaultTokens),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            height: 400,
            child: CollectionTable<_Row>(
              rows: _rows,
              sort: sort,
              onSort: onSort ?? (_, _) {},
              onClearSort: onClearSort,
              onColumnResize: onColumnResize,
              onColumnResizeEnd: onColumnResizeEnd,
              columnWidths: columnWidths,
              onHideColumn: (_) {},
              columns:
                  columns ??
                  [
                    TableColumn(
                      id: 'name',
                      label: 'Name',
                      sortKey: 'name',
                      cell: (r) => Text(r.name),
                    ),
                    TableColumn(
                      id: 'price',
                      label: 'Price',
                      fixed: 110,
                      numeric: true,
                      sortKey: 'price',
                      cell: (r) => Text('\$${r.price}'),
                    ),
                  ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The ⋮ of the column labelled [label].
Finder _menuButton(String label) => find.byWidgetPredicate(
  (w) => w is Tip && w.message == 'Column options for $label',
);

/// The ⋮ of the column labelled [label], through its opacity.
Opacity _trigger(WidgetTester tester, String label) => tester.widget<Opacity>(
  find.ancestor(of: _menuButton(label), matching: find.byType(Opacity)),
);

final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  testWidgets('a numeric header ends where its values end', (tester) async {
    for (final tokens in [
      defaultTokens,
      // Carbon's: a 16px inset under a 48px label header.
      AdminTokens.from(
        palette: irisPalette,
        table: const AdminTableMetrics(
          rowCompact: 40,
          rowStandard: 48,
          rowComfortable: 64,
          headerHeight: 48,
          cellPaddingX: 16,
          selectionColumnWidth: 48,
        ),
      ),
    ]) {
      await _pump(tester, tokens: tokens);
      final label = tester.getRect(find.text('Price'));
      for (final value in [r'$248.0', r'$179.5', r'$18.0']) {
        expect(
          tester.getRect(find.text(value)).right,
          moreOrLessEquals(label.right, epsilon: 1),
          reason: '$value under Price (${tokens.table})',
        );
      }
      expect(
        tester.getRect(find.text('Name')).left,
        tester.getRect(find.text('Coat')).left,
      );
    }
  }, variant: _desktop);

  testWidgets('the whole header cell is the sort target', (tester) async {
    await _pump(tester);
    final target = find.ancestor(
      of: find.text('Price'),
      matching: find.byType(Tappable),
    );
    final rect = tester.getRect(target.first);
    expect(rect.height, defaultTableMetrics.headerHeight);
    expect(rect.width, 110);
  });

  testWidgets('sorting cycles ascending, descending, then off', (tester) async {
    final calls = <String>[];
    Future<void> tapWith(TableSort? sort, {bool clear = true}) async {
      await _pump(
        tester,
        sort: sort,
        onSort: (k, asc) => calls.add('$k ${asc ? 'asc' : 'desc'}'),
        onClearSort: clear ? () => calls.add('clear') : null,
      );
      await tester.tap(find.text('Price'));
      await tester.pump();
    }

    await tapWith(null);
    await tapWith(const TableSort('price'));
    await tapWith(const TableSort('price', ascending: false));
    await tapWith(const TableSort('price', ascending: false), clear: false);
    expect(calls, ['price asc', 'price desc', 'clear', 'price asc']);
  });

  testWidgets('sort headers announce their state as buttons', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, sort: const TableSort('price', ascending: false));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Price, sorted descending')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('Name, not sorted'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'a label that cannot fit ends in an ellipsis and a tooltip; one that '
    'can keeps its arrow out of the way',
    (tester) async {
      await _pump(
        tester,
        columns: [
          TableColumn(
            label: 'Stock',
            fixed: 90,
            numeric: true,
            sortKey: 'stock',
            cell: (r) => const Text('12'),
          ),
          TableColumn(
            label: 'Fulfilment centre',
            fixed: 90,
            sortKey: 'centre',
            cell: (r) => const Text('North'),
          ),
        ],
      );
      final tips = tester
          .widgetList<Tip>(find.byType(Tip))
          .map((t) => t.message)
          .where((m) => !m.startsWith('Column options'));
      expect(tips, ['Fulfilment centre']);
      final stock = tester.renderObject<RenderParagraph>(find.text('Stock'));
      expect(stock.didExceedMaxLines, isFalse);
    },
    variant: _desktop,
  );

  testWidgets('the ⋮ waits for hover on a desktop', (tester) async {
    await _pump(tester);
    expect(_trigger(tester, 'Price').opacity, 0);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Price')));
    await tester.pump();
    expect(_trigger(tester, 'Price').opacity, 1);
    expect(_trigger(tester, 'Name').opacity, 0);
    await mouse.removePointer();
  }, variant: _desktop);

  testWidgets(
    'the ⋮ shows on touch where it has room, at the trailing edge of every '
    'column',
    (tester) async {
      await _pump(
        tester,
        columns: [
          TableColumn(
            label: 'Name',
            sortKey: 'name',
            cell: (r) => Text(r.name),
          ),
          TableColumn(
            label: 'Price',
            fixed: 140,
            numeric: true,
            sortKey: 'price',
            cell: (r) => Text('\$${r.price}'),
          ),
          TableColumn(
            label: 'Stock',
            fixed: 140,
            numeric: true,
            sortKey: 'stock',
            cell: (r) => const Text('12'),
          ),
        ],
      );
      Rect cell(String label) => tester.getRect(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(TableViewCell),
            )
            .first,
      );
      for (final label in ['Name', 'Price', 'Stock']) {
        expect(_trigger(tester, label).opacity, 1);
        final menu = tester.getRect(_menuButton(label));
        final text = tester.getRect(find.text(label));
        expect(menu.left, greaterThan(text.right), reason: label);
        expect(cell(label).right - menu.right, lessThan(12), reason: label);
      }
      // Touch shows no idle arrow; only a sorted column has one.
      expect(find.byIcon(Icons.unfold_more), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('the menu clears the sort and resets a resized width', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(
      tester,
      sort: const TableSort('price'),
      onClearSort: () => calls.add('clear'),
      onColumnResize: (k, w) => calls.add('resize $k $w'),
      onColumnResizeEnd: (k, w) => calls.add('end $k $w'),
      columnWidths: const {'price': 160},
    );
    await tester.tap(_menuButton('Price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear sort'));
    await tester.pumpAndSettle();
    expect(calls, ['clear']);

    await tester.tap(_menuButton('Price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset width'));
    await tester.pumpAndSettle();
    expect(calls, ['clear', 'resize price 110.0', 'end price 110.0']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('the menu pins and unpins, and opens the column chooser', (
    tester,
  ) async {
    final calls = <String>[];
    Future<void> pump({required bool pinned}) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: CollectionTable<_Row>(
                rows: _rows,
                onPinColumn: (key, pin) => calls.add('pin $key $pin'),
                onManageColumns: () => calls.add('manage'),
                columns: [
                  TableColumn(
                    id: 'name',
                    label: 'Name',
                    pinned: pinned,
                    cell: (r) => Text(r.name),
                  ),
                  TableColumn(
                    id: 'price',
                    label: 'Price',
                    fixed: 110,
                    cell: (r) => Text('${r.price}'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await pump(pinned: false);
    await tester.tap(_menuButton('Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin column'));
    await tester.pumpAndSettle();

    await pump(pinned: true);
    await tester.tap(_menuButton('Name'));
    await tester.pumpAndSettle();
    expect(find.text('Pin column'), findsNothing);
    await tester.tap(find.text('Unpin column'));
    await tester.pumpAndSettle();

    await tester.tap(_menuButton('Price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage columns…'));
    await tester.pumpAndSettle();
    expect(calls, ['pin name true', 'pin name false', 'manage']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a drag reports its end once; a double-click resets', (
    tester,
  ) async {
    final live = <double>[];
    final ends = <double>[];
    await _pump(
      tester,
      onColumnResize: (_, w) => live.add(w),
      onColumnResizeEnd: (_, w) => ends.add(w),
    );
    // Name flexes to 690; Price is 110 at 690..800. Their boundary: 690.
    await tester.timedDragFrom(
      const Offset(692, 22),
      const Offset(-40, 0),
      const Duration(milliseconds: 200),
    );
    await tester.pump(kDoubleTapTimeout);
    expect(live.length, greaterThan(1));
    expect(ends, [650], reason: 'the leading half of Price resizes Name');

    await tester.tapAt(const Offset(649, 22));
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(const Offset(649, 22));
    await tester.pump(kDoubleTapTimeout);
    expect(ends, [650, 690]);
  });

  testWidgets('pinned columns must lead', (tester) async {
    await _pump(
      tester,
      columns: [
        TableColumn(label: 'Name', cell: (r) => Text(r.name)),
        TableColumn(label: 'Pinned', pinned: true, cell: (r) => Text(r.name)),
      ],
    );
    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (e) => '${e.message}',
        'message',
        contains('Pinned columns must lead'),
      ),
    );
  });
}
