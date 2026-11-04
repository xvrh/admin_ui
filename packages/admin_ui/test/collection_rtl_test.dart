import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Item {
  final int id;
  final String name;
  final double price;
  const _Item(this.id, this.name, this.price);
}

final _items = [for (var i = 0; i < 12; i++) _Item(i, 'Item $i', 10.0 + i)];

/// Fills its cell, less the cell padding, so its rect places the column.
Widget _fill(String key, String text) =>
    SizedBox.expand(key: ValueKey(key), child: Text(text));

/// An 800 × 400 table: a pinned 200px Name, a numeric 120px Price and two
/// 300px columns, which overflow the width and scroll.
Widget _table({
  void Function(String key, double width)? onColumnResize,
  Map<String, double>? widths,
}) => SizedBox(
  width: 800,
  height: 400,
  child: CollectionTable<_Item>(
    rows: _items,
    rowKey: (r) => r.id,
    onSort: (_, _) {},
    onColumnResize: onColumnResize,
    columnWidths: widths,
    columns: [
      TableColumn(
        id: 'name',
        label: 'Name',
        fixed: 200,
        pinned: true,
        sortKey: 'name',
        cell: (r) => _fill('name ${r.id}', r.name),
      ),
      TableColumn(
        id: 'price',
        label: 'Price',
        fixed: 120,
        numeric: true,
        sortKey: 'price',
        cell: (r) => Text(r.price.toStringAsFixed(2)),
      ),
      TableColumn(
        id: 'sku',
        label: 'SKU',
        fixed: 300,
        cell: (r) => _fill('sku ${r.id}', 'SKU-${r.id}'),
      ),
      TableColumn(
        id: 'notes',
        label: 'Notes',
        fixed: 300,
        cell: (r) => _fill('notes ${r.id}', 'Notes ${r.id}'),
      ),
    ],
  ),
);

/// [child] in an Arabic app — right to left — at the top of its start edge,
/// or in English with [rtl] false.
Future<void> _pump(WidgetTester tester, Widget child, {bool rtl = true}) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(alignment: AlignmentDirectional.topStart, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

Future<void> _altKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pump();
}

/// Whether the focused cell's ring surrounds [target].
bool _ringOn(WidgetTester tester, Finder target) {
  final ring = tester.getRect(
    find.byWidgetPredicate((w) => w is FocusRing && w.focused),
  );
  return ring.inflate(8).contains(tester.getCenter(target));
}

/// Focuses the grid on its header row, first column.
Future<void> _focusHeader(WidgetTester tester) async {
  await tester.tap(find.text('Item 0'));
  await tester.pump(kDoubleTapTimeout);
  await _key(tester, LogicalKeyboardKey.arrowUp);
}

double _cellPaddingX(WidgetTester tester) => tester
    .element(find.byType(CollectionTable<_Item>))
    .tableMetrics
    .cellPaddingX;

/// Column [key]'s cell on the first row: its filling content, widened by
/// the cell padding. Price, whose number keeps its own width, is the room
/// between its neighbours.
Rect _column(WidgetTester tester, String key) {
  if (key == 'price') {
    final name = _column(tester, 'name');
    final sku = _column(tester, 'sku');
    final ltr = name.left < sku.left;
    return Rect.fromLTRB(
      ltr ? name.right : sku.right,
      name.top,
      ltr ? sku.left : name.left,
      name.bottom,
    );
  }
  final padX = _cellPaddingX(tester);
  final r = tester.getRect(find.byKey(ValueKey('$key 0')));
  return Rect.fromLTRB(r.left - padX, r.top, r.right + padX, r.bottom);
}

/// The resize grips' hit strips: the halves either side of each boundary.
List<Rect> _grips(WidgetTester tester) => [
  for (final e
      in find
          .byWidgetPredicate(
            (w) =>
                w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn,
          )
          .evaluate())
    tester.getRect(find.byWidget(e.widget)),
];

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('the first, pinned column sits on the right and stays there', (
    tester,
  ) async {
    await _pump(tester, _table());
    final table = tester.getRect(find.byType(CollectionTable<_Item>));
    final name = _column(tester, 'name');
    expect(name.right, table.right);
    expect(name.width, 200);
    // The rest runs leftward from it: Price's 120px, then SKU.
    expect(_column(tester, 'sku').right, name.left - 120);

    // Scrolling brings the far columns in from the left, under the pin.
    final sku = _column(tester, 'sku');
    await tester.drag(
      find.byKey(const ValueKey('sku 0')),
      const Offset(150, 0),
    );
    await tester.pumpAndSettle();
    expect(_column(tester, 'name'), name, reason: 'pinned');
    expect(_column(tester, 'sku').left, greaterThan(sku.left));
  });

  testWidgets('left to right, the pin is on the left', (tester) async {
    await _pump(tester, _table(), rtl: false);
    final table = tester.getRect(find.byType(CollectionTable<_Item>));
    final name = _column(tester, 'name');
    expect(name.left, table.left);
    expect(_column(tester, 'sku').left, name.right + 120);
  });

  testWidgets('a column menu opens from its ⋮, over the column', (
    tester,
  ) async {
    // Clear of the screen's edge, which would push the menu back in.
    await _pump(
      tester,
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 150),
        child: _table(),
      ),
    );
    final trigger = find.byWidgetPredicate(
      (w) => w is Tip && w.message == 'خيارات العمود Name',
    );
    final button = tester.getRect(trigger);
    final name = _column(tester, 'name');
    // Kept for good on touch, at the column's trailing edge: its left.
    expect(button.left - name.left, lessThan(12));
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.text('ترتيب تصاعدي'), findsOneWidget);
    // Aligned to the ⋮'s end — its left — so it opens over the column,
    // toward the table's start.
    final menu = tester.getRect(find.byType(PopoverMenuSurface));
    expect(menu.left, moreOrLessEquals(button.left, epsilon: 0.5));
    expect(menu.right, greaterThan(button.right));
  });

  testWidgets('a column resizes from its left edge', (tester) async {
    final widths = <String, double>{};
    await _pump(
      tester,
      _table(onColumnResize: (key, width) => widths[key] = width),
    );
    final half =
        tester
            .element(find.byType(CollectionTable<_Item>))
            .tableMetrics
            .resizeHandleWidth /
        2;
    final grips = _grips(tester);
    // Each column's trailing grip is the half inside its left edge. Its
    // right edge holds the other half of the previous column's boundary —
    // none for the first column, nor across the pinned edge.
    for (final (key, leading) in [('name', 0), ('price', 0), ('sku', 1)]) {
      final column = _column(tester, key);
      expect(
        grips.where((g) => g.left == column.left && g.width == half),
        hasLength(1),
        reason: '$key: trailing grip',
      );
      expect(
        grips.where((g) => g.right == column.right && g.width == half),
        hasLength(leading),
        reason: '$key: leading grip',
      );
    }

    // Dragging Price's left edge leftward widens it.
    final price = _column(tester, 'price');
    await tester.timedDragFrom(
      Offset(price.left + 1, price.top - 20),
      const Offset(-40, 0),
      const Duration(milliseconds: 200),
    );
    await tester.pump(kDoubleTapTimeout);
    expect(widths['price'], 160);
  });

  testWidgets('← moves to the column on the left, the next one', (
    tester,
  ) async {
    await _pump(tester, _table());
    await _focusHeader(tester);
    expect(_ringOn(tester, find.text('Name')), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_ringOn(tester, find.text('Price')), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_ringOn(tester, find.text('Name')), isTrue);
    // Home and End stay logical: the first column and the last.
    await _key(tester, LogicalKeyboardKey.end);
    expect(_ringOn(tester, find.text('Notes')), isTrue);
    await _key(tester, LogicalKeyboardKey.home);
    expect(_ringOn(tester, find.text('Name')), isTrue);
  });

  testWidgets('Alt+← widens the focused column; Alt+→ narrows it', (
    tester,
  ) async {
    final widths = <double>[];
    await _pump(tester, _table(onColumnResize: (_, w) => widths.add(w)));
    await _focusHeader(tester);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _altKey(tester, LogicalKeyboardKey.arrowLeft);
    expect(widths, [136]);
    await _altKey(tester, LogicalKeyboardKey.arrowRight);
    expect(widths, [136, 120]);
  });

  testWidgets(
    'a number sits flush left, its header on the same edge',
    (tester) async {
      await _pump(tester, _table());
      final padX = _cellPaddingX(tester);
      final price = _column(tester, 'price');
      expect(tester.getRect(find.text('10.00')).left, price.left + padX);
      expect(tester.getRect(find.text('Price')).left, price.left + padX);
    },
    // A mouse: touch would keep a slot for the column menu at that edge.
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('a card checkbox sits in the top right corner', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      SizedBox(
        width: 600,
        height: 400,
        child: CollectionCards<_Item>(
          rows: _items.take(2).toList(),
          rowKey: (r) => r.id,
          selected: {_items.first},
          onSelectionChanged: (_) {},
          minTileWidth: 240,
          tileHeight: 120,
          cardBuilder: (_, r) => Text(r.name),
        ),
      ),
    );
    final card = tester.getRect(
      find
          .ancestor(
            of: find.text('Item 0'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final check = tester.getRect(find.bySemanticsLabel('تحديد البطاقة 1'));
    final grid = tester.getRect(find.byType(CollectionCards<_Item>));
    expect(card.right, grid.right - AdminSpacing.xl, reason: 'the first card');
    // Inset from the inside of the card's 1px border.
    expect(check.right, card.right - 1 - AdminSpacing.md);
    expect(check.top, card.top + 1 + AdminSpacing.md);
    semantics.dispose();
  });
}
