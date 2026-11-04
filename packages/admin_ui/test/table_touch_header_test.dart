import 'dart:io';

import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/common/ui/tip.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class _Row {
  final String name;
  final int stock;
  const _Row(this.name, this.stock);
}

const _rows = [_Row('Coat', 12), _Row('Boots', 410), _Row('Scarf', 0)];

const _menuAction = CustomSemanticsAction(label: 'Column options');

final _touch = TargetPlatformVariant.only(TargetPlatform.android);
final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

/// A wide Name column, then [label] — numeric, sortable — [width] wide.
Future<void> _pump(
  WidgetTester tester, {
  String label = 'Stock',
  double width = 90,
  TableSort? sort,
  List<String>? calls,
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
              onSort: (key, asc) => calls?.add('sort $key'),
              onHideColumn: (key) => calls?.add('hide $key'),
              columns: [
                TableColumn(
                  id: 'name',
                  label: 'Name',
                  sortKey: 'name',
                  cell: (r) => Text(r.name),
                ),
                TableColumn(
                  id: 'stock',
                  label: label,
                  fixed: width,
                  numeric: true,
                  sortKey: 'stock',
                  cell: (r) => Text('${r.stock}'),
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

/// Whether the ⋮ of the column labelled [label] shows.
bool _menuShows(WidgetTester tester, String label) =>
    tester
        .widget<Opacity>(
          find.ancestor(of: _menuButton(label), matching: find.byType(Opacity)),
        )
        .opacity ==
    1;

RenderParagraph _paragraph(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label));

Rect _cell(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(of: find.text(label), matching: find.byType(TableViewCell))
      .first,
);

/// What a header cell needs across for [label], a sort arrow and the ⋮'s
/// slot beside it.
double _roomForMenu(WidgetTester tester, String label) {
  const m = defaultTableMetrics;
  const size = IconActionSize.inline;
  final painter = TextPainter(
    text: _paragraph(tester, label).text,
    textDirection: TextDirection.ltr,
  )..layout();
  final natural = painter.width;
  painter.dispose();
  final slot = (size.box + size.glyph) / 2 + m.sortIconGap;
  return 2 * m.cellPaddingX + natural + m.sortIconGap + m.sortIconSize + slot;
}

void main() {
  testWidgets(
    'a narrow header keeps its whole label on touch, and no idle arrow',
    (tester) async {
      await _pump(tester);
      final stock = _paragraph(tester, 'Stock');
      expect(stock.didExceedMaxLines, isFalse);
      expect(
        stock.size.width,
        moreOrLessEquals(stock.getMaxIntrinsicWidth(double.infinity)),
      );
      expect(
        find.byWidgetPredicate((w) => w is Tip && w.message == 'Stock'),
        findsNothing,
        reason: 'no truncation tooltip',
      );
      expect(find.byIcon(Icons.unfold_more), findsNothing);
      // The ⋮ gave way, so the label ends where its values end.
      expect(_menuShows(tester, 'Stock'), isFalse);
      expect(
        tester.getRect(find.text('Stock')).right,
        moreOrLessEquals(tester.getRect(find.text('410')).right, epsilon: 1),
      );
      // The wide column keeps its ⋮.
      expect(_menuShows(tester, 'Name'), isTrue);
    },
    variant: _touch,
  );

  testWidgets('the ⋮ shows on touch once the label, an arrow and it all fit', (
    tester,
  ) async {
    await _pump(tester);
    final needed = _roomForMenu(tester, 'Stock');
    expect(needed, greaterThan(90));

    await _pump(tester, width: needed.floorToDouble() - 1);
    expect(_menuShows(tester, 'Stock'), isFalse);
    expect(_paragraph(tester, 'Stock').didExceedMaxLines, isFalse);

    await _pump(tester, width: needed.ceilToDouble());
    expect(_menuShows(tester, 'Stock'), isTrue);
    expect(_paragraph(tester, 'Stock').didExceedMaxLines, isFalse);
    final menu = tester.getRect(_menuButton('Stock'));
    expect(menu.left, greaterThan(tester.getRect(find.text('Stock')).right));
    expect(_cell(tester, 'Stock').right - menu.right, lessThan(12));
  }, variant: _touch);

  testWidgets('a font that loads late measures the label again', (
    tester,
  ) async {
    // Measured first in the fallback font, which leaves no room for the ⋮;
    // the font that arrives does.
    const family = 'TableHeaderLateFont';
    const width = 120.0;
    await _pump(
      tester,
      width: width,
      tokens: AdminTokens.from(
        palette: irisPalette,
        type: const AdminTypeSpec(fontFamily: family),
      ),
    );
    expect(_roomForMenu(tester, 'Stock'), greaterThan(width));
    expect(_menuShows(tester, 'Stock'), isFalse);

    final font = File('example/assets/fonts/IBMPlexSans-SemiBold.ttf')
        .readAsBytesSync();
    await tester.runAsync(
      () => (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(font)))).load(),
    );
    await tester.pump();
    await tester.pump();
    expect(_roomForMenu(tester, 'Stock'), lessThanOrEqualTo(width));
    expect(_menuShows(tester, 'Stock'), isTrue);
  }, variant: _touch);

  testWidgets('a long press opens the menu of a header whose ⋮ gave way', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(tester, calls: calls);
    expect(_menuShows(tester, 'Stock'), isFalse);

    await tester.longPress(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Hide column'), findsOneWidget);
    expect(_menuShows(tester, 'Stock'), isTrue, reason: 'shown while open');
    expect(calls, isEmpty, reason: 'a long press does not sort');

    await tester.tap(find.text('Hide column'));
    await tester.pumpAndSettle();
    expect(calls, ['hide stock']);
    expect(_menuShows(tester, 'Stock'), isFalse);

    // A tap still sorts.
    await tester.tap(find.text('Stock'));
    await tester.pump();
    expect(calls, ['hide stock', 'sort stock']);
  }, variant: _touch);

  testWidgets(
    'a sorted narrow column keeps its arrow; a label that cannot fit beside '
    'it keeps what it can',
    (tester) async {
      await _pump(tester, label: 'Qty', sort: const TableSort('stock'));
      final arrow = find.byIcon(Icons.arrow_upward);
      expect(arrow, findsOneWidget);
      expect(_paragraph(tester, 'Qty').didExceedMaxLines, isFalse);
      expect(_menuShows(tester, 'Qty'), isFalse);
      // A numeric label: the arrow leads, the label ends on its values.
      final label = tester.getRect(find.text('Qty'));
      expect(tester.getRect(arrow).right, lessThanOrEqualTo(label.left));
      expect(
        label.right,
        moreOrLessEquals(tester.getRect(find.text('410')).right, epsilon: 1),
      );

      await _pump(tester, sort: const TableSort('stock', ascending: false));
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      final stock = _paragraph(tester, 'Stock');
      const m = defaultTableMetrics;
      final arrowWidth = m.sortIconGap + m.sortIconSize;
      final room = 90 - 2 * m.cellPaddingX;
      expect(
        stock.getMaxIntrinsicWidth(double.infinity) + arrowWidth,
        greaterThan(room),
      );
      expect(stock.didExceedMaxLines, isTrue);
      // All the room the arrow leaves, none of it held for the ⋮.
      expect(stock.constraints.maxWidth, room - arrowWidth);
    },
    variant: _touch,
  );

  testWidgets(
    'a long press on a cut-off label opens its menu, which names it in full',
    (tester) async {
      final calls = <String>[];
      await _pump(
        tester,
        calls: calls,
        sort: const TableSort('stock', ascending: false),
      );
      expect(_paragraph(tester, 'Stock').didExceedMaxLines, isTrue);
      // A tooltip would take the long press from the menu.
      expect(
        find.byWidgetPredicate((w) => w is Tip && w.message == 'Stock'),
        findsNothing,
      );

      await tester.longPress(find.text('Stock'));
      await tester.pumpAndSettle();
      expect(find.text('Hide column'), findsOneWidget);
      expect(find.text('STOCK'), findsOneWidget);
      expect(calls, isEmpty);
    },
    variant: _touch,
  );

  testWidgets('a mouse reads a cut-off label in a tooltip', (tester) async {
    await _pump(tester, sort: const TableSort('stock', ascending: false));
    expect(_paragraph(tester, 'Stock').didExceedMaxLines, isTrue);
    expect(
      find.byWidgetPredicate((w) => w is Tip && w.message == 'Stock'),
      findsOneWidget,
    );
  }, variant: _desktop);

  testWidgets('a header whose ⋮ gave way offers its menu as a custom action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Stock, not sorted')),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        customActions: [_menuAction],
      ),
    );
    expect(find.bySemanticsLabel('Column options for Stock'), findsNothing);
    // Where the ⋮ shows, it is its own button.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Name, not sorted')),
      isSemantics(isButton: true, hasTapAction: true, customActions: []),
    );
    expect(find.bySemanticsLabel('Column options for Name'), findsOneWidget);

    tester.semantics.customAction(
      find.semantics.byLabel('Stock, not sorted'),
      _menuAction,
    );
    await tester.pumpAndSettle();
    expect(find.text('Hide column'), findsOneWidget);
    handle.dispose();
  }, variant: _touch);

  testWidgets('Alt+↓ opens it, and keyboard focus reveals the ⋮', (
    tester,
  ) async {
    await _pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(_menuShows(tester, 'Stock'), isTrue, reason: 'the focused header');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('Hide column'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Hide column'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_menuShows(tester, 'Stock'), isFalse);
  }, variant: _touch);

  testWidgets(
    'a mouse keeps the floating ⋮ and the idle arrow; its long press is '
    'no menu',
    (tester) async {
      await _pump(tester, width: 200);
      expect(_menuShows(tester, 'Stock'), isFalse);
      expect(_menuShows(tester, 'Name'), isFalse);
      expect(find.byIcon(Icons.unfold_more), findsNWidgets(2));
      // No slot held for the ⋮: the label ends on its values.
      expect(
        tester.getRect(find.text('Stock')).right,
        moreOrLessEquals(tester.getRect(find.text('410')).right, epsilon: 1),
      );

      final mouse = await tester.startGesture(
        tester.getCenter(find.text('Stock')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.text('Hide column'), findsNothing);
    },
    variant: _desktop,
  );

  testWidgets('on a desktop, a finger switches to the touch header', (
    tester,
  ) async {
    await _pump(tester, width: 200);
    expect(find.byIcon(Icons.unfold_more), findsNWidgets(2));

    await tester.longPress(find.text('Stock'), kind: PointerDeviceKind.touch);
    await tester.pumpAndSettle();
    expect(find.text('Hide column'), findsOneWidget);
    expect(find.byIcon(Icons.unfold_more), findsNothing);
    expect(_menuShows(tester, 'Name'), isTrue);
  }, variant: _desktop);
}
