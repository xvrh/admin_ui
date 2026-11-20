import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A table with a rowMenu opens a row's context menu from a right-click or a
// long press anywhere on the row, and from the keyboard under its focused
// cell, and draws the row as a selected one while the menu is open.

class _Row {
  final int id;
  final String name;
  const _Row(this.id, this.name);
}

const _rows = [_Row(1, 'Fern'), _Row(2, 'Ivy'), _Row(3, 'Moss')];

final _columns = [
  TableColumn<_Row>(label: 'Name', flex: 1, cell: (r) => Text(r.name)),
  TableColumn<_Row>(label: 'Id', fixed: 120, cell: (r) => Text('#${r.id}')),
];

/// What the menus under test were asked to do.
final _chosen = <String>[];

List<MenuEntry> _menuOf(_Row row) => [
  MenuItem('Open ${row.name}', onSelect: () => _chosen.add('open ${row.id}')),
  MenuItem('Archive', onSelect: () => _chosen.add('archive ${row.id}')),
];

const _origin = Offset(40, 30);
const _size = Size(600, 400);

Widget _host(Widget table, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: _origin.dx,
                top: _origin.dy,
                width: _size.width,
                height: _size.height,
                child: table,
              ),
            ],
          ),
        ),
      ),
    );

CollectionTable<_Row> _table({
  List<_Row> rows = _rows,
  List<MenuEntry> Function(_Row row)? rowMenu = _menuOf,
  bool loading = false,
  void Function(String key)? onHideColumn,
}) => CollectionTable<_Row>(
  rows: rows,
  columns: _columns,
  rowKey: (r) => r.id,
  rowMenu: rowMenu,
  loading: loading,
  onHideColumn: onHideColumn,
);

final _menu = find.byType(PopoverMenuSurface);

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(CollectionTable<_Row>));

/// The boxes that tint a row as selected, wherever they are.
Finder _tint(WidgetTester tester) {
  final color = _context(tester).colors.tableRowSelected;
  return find.byWidgetPredicate((w) => w is ColoredBox && w.color == color);
}

/// The vertical centre of the row showing [name].
double _rowY(WidgetTester tester, String name) =>
    tester.getCenter(find.text(name)).dy;

Future<void> _rightClick(WidgetTester tester, Offset at) async {
  final mouse = await tester.startGesture(
    at,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await mouse.up();
  await tester.pumpAndSettle();
}

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

bool _hasFocus(WidgetTester tester, String text) =>
    Focus.maybeOf(tester.element(find.text(text)))?.hasPrimaryFocus ?? false;

String? _focused() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  setUp(_chosen.clear);

  group('a pointer', () {
    testWidgets('right-clicking a row opens its menu at the pointer', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table()));
      final at = tester.getCenter(find.text('Ivy'));
      await _rightClick(tester, at);

      expect(find.text('Open Ivy'), findsOneWidget);
      expect(tester.getRect(_menu).topLeft, at + const Offset(0, 2));
    });

    testWidgets('anywhere on the row, its padding included', (tester) async {
      await tester.pumpWidget(_host(_table()));
      // The far end of the first column, where no text is.
      final at = Offset(_origin.dx + 440, _rowY(tester, 'Moss'));
      await _rightClick(tester, at);
      expect(find.text('Open Moss'), findsOneWidget);
    });

    testWidgets('a choice acts on that row and closes the menu', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table()));
      await _rightClick(tester, tester.getCenter(find.text('Ivy')));
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(_chosen, ['archive 2']);
      expect(_menu, findsNothing);
    });

    testWidgets('a finger\'s long press opens it too, a mouse\'s does not', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table()));
      final at = tester.getCenter(find.text('Fern'));
      await tester.longPressAt(at, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_menu, findsNothing);

      await tester.longPressAt(at);
      await tester.pumpAndSettle();
      expect(find.text('Open Fern'), findsOneWidget);
    });

    testWidgets('the header opens no row menu', (tester) async {
      await tester.pumpWidget(_host(_table()));
      await _rightClick(tester, tester.getCenter(find.text('Name')));
      expect(_menu, findsNothing);
    });
  });

  group('while its menu is open', () {
    testWidgets('the row is drawn as a selected one, and no other', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table()));
      expect(_tint(tester), findsNothing);

      await _rightClick(tester, tester.getCenter(find.text('Ivy')));
      // One box a cell, on that row.
      expect(_tint(tester), findsNWidgets(_columns.length));
      for (final box in tester.widgetList(_tint(tester))) {
        expect(
          tester.getCenter(find.byWidget(box)).dy,
          closeTo(_rowY(tester, 'Ivy'), 1),
        );
      }

      await _press(tester, LogicalKeyboardKey.escape);
      expect(_menu, findsNothing);
      expect(_tint(tester), findsNothing);
    });

    testWidgets('the tint follows its record as the rows are sorted', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table()));
      await _rightClick(tester, tester.getCenter(find.text('Fern')));
      await tester.pumpWidget(_host(_table(rows: _rows.reversed.toList())));
      await tester.pumpAndSettle();

      expect(find.text('Open Fern'), findsOneWidget);
      expect(_tint(tester), findsNWidgets(_columns.length));
      expect(
        tester.getCenter(_tint(tester).first).dy,
        closeTo(_rowY(tester, 'Fern'), 1),
      );
    });

    testWidgets('a record that leaves the page takes its menu with it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table()));
      await _rightClick(tester, tester.getCenter(find.text('Fern')));
      await tester.pumpWidget(_host(_table(rows: _rows.sublist(1))));
      await tester.pumpAndSettle();

      expect(_menu, findsNothing);
      expect(_tint(tester), findsNothing);
    });
  });

  group('the keyboard', () {
    /// Focus on the first cell of the second row.
    Future<void> focusIvy(WidgetTester tester) async {
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.arrowDown);
    }

    /// The rect of the first cell of the row showing [name].
    Rect firstCell(WidgetTester tester, String name) {
      final metrics = _context(tester).tableMetrics;
      final height = metrics.rowHeight(TableDensity.standard);
      final y = _rowY(tester, name);
      return Rect.fromLTWH(
        _origin.dx,
        y - height / 2,
        _size.width - 120,
        height,
      );
    }

    testWidgets('Shift+F10 opens it under the focused cell, on its first '
        'item', (tester) async {
      await tester.pumpWidget(_host(_table()));
      await focusIvy(tester);
      await _press(tester, LogicalKeyboardKey.f10, shift: true);

      expect(find.text('Open Ivy'), findsOneWidget);
      final cell = firstCell(tester, 'Ivy');
      final menu = tester.getRect(_menu);
      expect(menu.left, cell.left);
      expect(menu.top, closeTo(cell.bottom + 2, 1));
      expect(_hasFocus(tester, 'Open Ivy'), isTrue);
      expect(_tint(tester), findsNWidgets(_columns.length));
    });

    testWidgets('the context-menu key opens it too', (tester) async {
      await tester.pumpWidget(_host(_table()));
      await focusIvy(tester);
      await _press(tester, LogicalKeyboardKey.contextMenu);
      expect(find.text('Open Ivy'), findsOneWidget);
    });

    testWidgets('right to left it opens from the cell\'s right corner', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table(), direction: TextDirection.rtl));
      await focusIvy(tester);
      await _press(tester, LogicalKeyboardKey.f10, shift: true);

      // The first column is on the right, and the menu starts there.
      expect(tester.getRect(_menu).right, _origin.dx + _size.width);
    });

    testWidgets('Escape closes it and the table has focus again', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table()));
      await focusIvy(tester);
      await _press(tester, LogicalKeyboardKey.f10, shift: true);
      await _press(tester, LogicalKeyboardKey.escape);

      expect(_menu, findsNothing);
      expect(_focused(), 'CollectionTable');
      // The focused cell is where it was: the menu opens on Ivy again.
      await _press(tester, LogicalKeyboardKey.f10, shift: true);
      expect(find.text('Open Ivy'), findsOneWidget);
    });

    testWidgets('Enter chooses, and the table has focus again', (tester) async {
      await tester.pumpWidget(_host(_table()));
      await focusIvy(tester);
      await _press(tester, LogicalKeyboardKey.f10, shift: true);
      await _press(tester, LogicalKeyboardKey.enter);

      expect(_chosen, ['open 2']);
      expect(_menu, findsNothing);
      expect(_focused(), 'CollectionTable');
    });

    testWidgets('on a header, Shift+F10 is still the column menu', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_table(onHideColumn: (_) {})));
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await _press(tester, LogicalKeyboardKey.f10, shift: true);

      expect(_menu, findsOneWidget);
      expect(find.text('Open Fern'), findsNothing);
      expect(_tint(tester), findsNothing);
    });
  });

  group('no menu opens', () {
    testWidgets('for a table with no rowMenu', (tester) async {
      await tester.pumpWidget(_host(_table(rowMenu: null)));
      await _rightClick(tester, tester.getCenter(find.text('Ivy')));
      expect(_menu, findsNothing);

      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.f10, shift: true);
      expect(_menu, findsNothing);
    });

    testWidgets('for a row it gives no entry', (tester) async {
      await tester.pumpWidget(
        _host(_table(rowMenu: (row) => row.id == 2 ? const [] : _menuOf(row))),
      );
      await _rightClick(tester, tester.getCenter(find.text('Ivy')));
      expect(_menu, findsNothing);
      expect(_tint(tester), findsNothing);

      await _rightClick(tester, tester.getCenter(find.text('Moss')));
      expect(find.text('Open Moss'), findsOneWidget);
    });

    testWidgets('for rows dimmed under a reload', (tester) async {
      await tester.pumpWidget(_host(_table(loading: true)));
      // Past the delay after which a reload shows. Its progress bar never
      // settles, so the frames are pumped one at a time.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_focused(), 'CollectionTable');
      expect(_menu, findsNothing);
    });
  });

  testWidgets('the table still sees the pointers that land on its rows', (
    tester,
  ) async {
    // On a desktop the header draws for a mouse until a finger lands: its
    // sort hints show, and go once one does. The table learns that from a
    // pointer listener above the rows, which the row menu must not hide.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        _host(
          CollectionTable<_Row>(
            rows: _rows,
            rowKey: (r) => r.id,
            rowMenu: _menuOf,
            onSort: (_, _) {},
            columns: [
              TableColumn<_Row>(
                label: 'Name',
                flex: 1,
                sortKey: 'name',
                cell: (r) => Text(r.name),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.unfold_more), findsOneWidget);

      await tester.tap(find.text('Ivy'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.unfold_more), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a Collection hands its rowMenu to its table', (tester) async {
    final controller = CollectionController<_Row>(
      rowKey: (r) => r.id,
      fetcher: (q) async => const CollectionPage(items: _rows, total: 3),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        Collection<_Row>(
          controller: controller,
          columns: _columns,
          rowMenu: _menuOf,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _rightClick(tester, tester.getCenter(find.text('Moss')));
    expect(find.text('Open Moss'), findsOneWidget);
  });
}
