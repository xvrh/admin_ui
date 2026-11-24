import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A board's padding and the space between its columns are its caller's to
// give. And told to fit, its columns share its width: all of them where
// they fit, as many whole ones as fit where they do not, so that the
// board's edge falls after a column and not through one.

const _height = 600.0;

List<KanbanColumn<String>> _columns(int count) => [
  for (var i = 0; i < count; i++)
    KanbanColumn(id: 'c$i', title: 'Column $i', items: ['c$i']),
];

Widget _card(BuildContext context, String item) => Container(
  key: ValueKey('card $item'),
  height: 60,
  padding: KanbanBoard.cardPadding,
  decoration: BoxDecoration(border: Border.all()),
  // Fills its column, as a card does.
  child: Align(alignment: AlignmentDirectional.centerStart, child: Text(item)),
);

KanbanBoard<String> _board(
  int columns, {
  double columnWidth = 240,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  double columnSpacing = 12,
  bool fitColumns = false,
  void Function(String item, String from, String to)? onMove,
}) => KanbanBoard<String>(
  columns: _columns(columns),
  itemKey: (item) => item,
  cardBuilder: _card,
  columnWidth: columnWidth,
  padding: padding,
  columnSpacing: columnSpacing,
  fitColumns: fitColumns,
  onMove: onMove,
);

/// Lays [board] out in a page [width] wide, in a slot of that size: the
/// board is given its width, as in an `Expanded`.
Future<void> _pump(
  WidgetTester tester,
  double width,
  Widget board, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, _height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(body: SizedBox.expand(child: board)),
    ),
  );
}

/// Where column [index] is, its border included.
Rect _column(WidgetTester tester, int index) => tester.getRect(
  find
      .ancestor(
        of: find.text('Column $index'),
        matching: find.byType(AnimatedContainer),
      )
      .first,
);

/// The board's own scroll, across its columns.
ScrollPosition _scroll(WidgetTester tester) => tester
    .stateList<ScrollableState>(find.byType(Scrollable))
    .firstWhere((s) => axisDirectionToAxis(s.axisDirection) == Axis.horizontal)
    .position;

Matcher _near(double value) => moreOrLessEquals(value, epsilon: 0.01);

void main() {
  group('a board as it was', () {
    testWidgets('pads itself 16 and spaces its columns 12, 300 wide', (
      tester,
    ) async {
      final board = KanbanBoard<String>(
        columns: _columns(3),
        itemKey: (item) => item,
        cardBuilder: _card,
      );
      expect(board.padding, const EdgeInsets.all(AdminSpacing.xl));
      expect(board.columnSpacing, AdminSpacing.lg);
      expect(board.columnWidth, 300);
      expect(board.fitColumns, isFalse);

      await _pump(tester, 1000, board);
      expect(_column(tester, 0), const Rect.fromLTRB(16, 16, 316, 584));
      expect(_column(tester, 1).left, 328);
      expect(_column(tester, 2).left, 640);
      expect(_scroll(tester).maxScrollExtent, 0);

      // In less than its columns need, the board scrolls and they stay.
      await _pump(tester, 700, board);
      expect(_column(tester, 2), const Rect.fromLTRB(640, 16, 940, 584));
      expect(_scroll(tester).maxScrollExtent, 16 + 900 + 24 + 16 - 700);
    });

    testWidgets('its columns are as wide as told, whatever its own width', (
      tester,
    ) async {
      for (final width in [700.0, 1000.0, 1900.0]) {
        await _pump(tester, width, _board(3, columnWidth: 260));
        for (var i = 0; i < 3; i++) {
          expect(_column(tester, i).width, 260, reason: '$width, column $i');
        }
      }
    });
  });

  group('padding', () {
    testWidgets('is the space around the columns', (tester) async {
      await _pump(
        tester,
        1000,
        _board(2, padding: const EdgeInsets.fromLTRB(24, 8, 40, 4)),
      );
      final first = _column(tester, 0);
      expect(first.left, 24);
      expect(first.top, 8);
      expect(first.bottom, _height - 4);
    });

    testWidgets('none puts the first column on the page\'s edge', (
      tester,
    ) async {
      await _pump(tester, 1000, _board(2, padding: EdgeInsets.zero));
      expect(_column(tester, 0), const Rect.fromLTRB(0, 0, 240, _height));
    });

    testWidgets('scrolls with the columns: its far side shows at the end', (
      tester,
    ) async {
      await _pump(
        tester,
        600,
        _board(4, padding: const EdgeInsets.fromLTRB(24, 8, 40, 4)),
      );
      final scroll = _scroll(tester);
      expect(scroll.maxScrollExtent, 24 + 4 * 240 + 3 * 12 + 40 - 600);
      // At rest the board's edge is over the columns, not over padding.
      expect(_column(tester, 3).right, greaterThan(600));

      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pump();
      expect(_column(tester, 3).right, 600 - 40);
    });

    testWidgets('follows the reading direction', (tester) async {
      await _pump(
        tester,
        1000,
        _board(2, padding: const EdgeInsetsDirectional.only(start: 40)),
        direction: TextDirection.rtl,
      );
      expect(_column(tester, 0).right, 1000 - 40);
      expect(_column(tester, 1).right, 1000 - 40 - 240 - 12);
    });
  });

  group('the space between columns', () {
    testWidgets('is the one given', (tester) async {
      await _pump(tester, 1000, _board(3, columnSpacing: 40));
      expect(_column(tester, 1).left - _column(tester, 0).right, 40);
      expect(_column(tester, 2).left - _column(tester, 1).right, 40);
    });

    testWidgets('can be none', (tester) async {
      await _pump(tester, 1000, _board(3, columnSpacing: 0));
      expect(_column(tester, 1).left, _column(tester, 0).right);
      expect(_scroll(tester).maxScrollExtent, 0);
    });
  });

  group('told to fit', () {
    testWidgets('columns that all fit fill the board, and nothing scrolls', (
      tester,
    ) async {
      await _pump(tester, 1000, _board(3, fitColumns: true));
      const each = (1000 - 32 - 24) / 3;
      expect(_column(tester, 0).left, 16);
      for (var i = 0; i < 3; i++) {
        expect(_column(tester, i).width, _near(each), reason: 'column $i');
      }
      expect(_column(tester, 2).right, _near(1000 - 16));
      expect(_scroll(tester).maxScrollExtent, _near(0));
    });

    testWidgets('columns that do not all fit: whole ones share the width, '
        'and the edge falls in the space after the last', (tester) async {
      await _pump(tester, 1000, _board(5, fitColumns: true));
      for (var i = 0; i < 5; i++) {
        expect(_column(tester, i).width, _near(316), reason: 'column $i');
      }
      // Three whole columns, the space after the third, then the edge.
      expect(_column(tester, 2).right, _near(1000 - 12));
      expect(_column(tester, 3).left, _near(1000));
      expect(_scroll(tester).maxScrollExtent, greaterThan(0));
    });

    testWidgets('a board a few pixels short of fitting them all shows '
        'whole columns, not all of them and a scroll of a sliver', (
      tester,
    ) async {
      // Four columns of 240 need 1028 with the padding; 1025 has room for
      // four and their spaces after the leading padding, but not for the
      // trailing one.
      await _pump(tester, 1025, _board(4, fitColumns: true));
      const each = (1025 - 16) / 3 - 12;
      for (var i = 0; i < 4; i++) {
        expect(_column(tester, i).width, _near(each), reason: 'column $i');
      }
      expect(_column(tester, 2).right, _near(1025 - 12));
      expect(_column(tester, 3).left, _near(1025));
    });

    testWidgets('a column is never narrower than told', (tester) async {
      await _pump(tester, 200, _board(3, fitColumns: true));
      for (var i = 0; i < 3; i++) {
        expect(_column(tester, i).width, 240, reason: 'column $i');
      }
    });

    testWidgets('one column fills the board, or keeps its width', (
      tester,
    ) async {
      await _pump(tester, 800, _board(1, fitColumns: true));
      expect(_column(tester, 0), const Rect.fromLTRB(16, 16, 784, 584));
      expect(_scroll(tester).maxScrollExtent, 0);

      // 16 + 240 + 16 does not fit in 270.
      await _pump(tester, 270, _board(1, fitColumns: true));
      expect(_column(tester, 0).width, 240);
    });

    testWidgets('shares what the padding and the spacing given leave', (
      tester,
    ) async {
      await _pump(
        tester,
        1000,
        _board(
          3,
          fitColumns: true,
          padding: EdgeInsets.zero,
          columnSpacing: 20,
        ),
      );
      expect(_column(tester, 0).left, 0);
      expect(_column(tester, 0).width, _near(320));
      expect(_column(tester, 2).right, _near(1000));

      // Scrolling: the room is the width less the padding the board
      // starts on, and each column brings the space given.
      await _pump(
        tester,
        1000,
        _board(
          6,
          fitColumns: true,
          padding: const EdgeInsets.only(left: 40, right: 8),
          columnSpacing: 20,
        ),
      );
      expect(_column(tester, 0).left, 40);
      expect(_column(tester, 0).width, _near(300));
      expect(_column(tester, 2).right, _near(1000 - 20));
      expect(_column(tester, 3).left, _near(1000));
    });

    testWidgets('right to left, the room is from the side the board starts '
        'on', (tester) async {
      await _pump(
        tester,
        1000,
        _board(
          6,
          fitColumns: true,
          padding: const EdgeInsetsDirectional.only(start: 40, end: 8),
          columnSpacing: 20,
        ),
        direction: TextDirection.rtl,
      );
      expect(_column(tester, 0).right, 1000 - 40);
      expect(_column(tester, 0).width, _near(300));
      // Three whole columns, the space after the third, then the edge.
      expect(_column(tester, 2).left, _near(20));
      expect(_column(tester, 3).right, _near(0));
    });

    testWidgets('follows the board as it is resized', (tester) async {
      await _pump(tester, 1000, _board(5, fitColumns: true));
      expect(_column(tester, 0).width, _near(316));

      // Wide enough for all five now.
      await _pump(tester, 1300, _board(5, fitColumns: true));
      expect(_column(tester, 0).width, _near((1300 - 32 - 48) / 5));
      expect(_column(tester, 4).right, _near(1300 - 16));
      expect(_scroll(tester).maxScrollExtent, _near(0));
    });

    testWidgets('a card is as wide as its column allows', (tester) async {
      await _pump(tester, 1000, _board(5, fitColumns: true));
      final card = tester.getRect(find.byKey(const ValueKey('card c0')));
      final column = _column(tester, 0);
      // Inside the column's 1px border and its inset.
      expect(card.left, column.left + 1 + AdminSpacing.md);
      expect(card.right, _near(column.right - 1 - AdminSpacing.md));
    });

    testWidgets('a card in flight is as wide as the column it left', (
      tester,
    ) async {
      await _pump(
        tester,
        1000,
        _board(5, fitColumns: true, onMove: (_, _, _) {}),
      );
      final card = find.byKey(const ValueKey('card c0'));
      final column = _column(tester, 0).width;
      expect(column, _near(316));
      final lying = tester.getSize(card).width;

      final drag = await tester.startGesture(tester.getCenter(card));
      await drag.moveBy(const Offset(20, 0));
      await tester.pump();
      // The card where it lay, dimmed, and the one under the pointer: the
      // column's width less its inset, not the narrowest a column gets.
      expect(card, findsNWidgets(2));
      expect(tester.getSize(card.first).width, _near(lying));
      expect(
        tester.getSize(card.last).width,
        _near(column - 2 * AdminSpacing.md),
      );
      await drag.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a board with no column lays out', (tester) async {
      await _pump(tester, 1000, _board(0, fitColumns: true));
      expect(tester.takeException(), isNull);
      expect(find.byType(KanbanBoard<String>), findsOneWidget);
    });

    testWidgets('at any width, the columns fill the board or its edge falls '
        'after a whole one', (tester) async {
      for (var count = 1; count <= 6; count++) {
        for (var width = 300.0; width <= 2200; width += 47) {
          final at = '$count columns in $width';
          await _pump(tester, width, _board(count, fitColumns: true));
          final each = _column(tester, 0).width;
          expect(each, greaterThanOrEqualTo(240), reason: at);
          for (var i = 1; i < count; i++) {
            expect(_column(tester, i).width, _near(each), reason: at);
          }
          expect(_column(tester, 0).left, 16, reason: at);

          if (_scroll(tester).maxScrollExtent < 0.01) {
            // They all fit, and fill the board to its padding.
            expect(
              _column(tester, count - 1).right,
              _near(width - 16),
              reason: at,
            );
            continue;
          }
          if (count == 1 || width < 16 + 240 + 12) {
            // No room for a whole column and the space after it, or the
            // only column does not fit: it keeps its width.
            expect(each, 240, reason: at);
            continue;
          }
          // The last column that ends before the edge, and the one after.
          final whole = [
            for (var i = 0; i < count; i++)
              if (_column(tester, i).right <= width + 0.01) i,
          ].last;
          expect(whole, lessThan(count - 1), reason: at);
          expect(
            _column(tester, whole + 1).left,
            greaterThanOrEqualTo(width - 0.01),
            reason: at,
          );
        }
      }
    });
  });
}
