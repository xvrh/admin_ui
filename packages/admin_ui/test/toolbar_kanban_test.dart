import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Card {
  final String id;
  final String column;
  const _Card(this.id, this.column);
}

Future<void> _pump(
  WidgetTester tester,
  List<KanbanColumn<_Card>> columns, {
  void Function(_Card item, String from, String to)? onMove,
  void Function(_Card item)? onCardTap,
}) async {
  tester.view.physicalSize = const Size(1600, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: KanbanBoard<_Card>(
          columns: columns,
          itemKey: (c) => c.id,
          onMove: onMove,
          onCardTap: onCardTap,
          cardBuilder: (_, c) => Container(
            height: 60,
            padding: KanbanBoard.cardPadding,
            decoration: BoxDecoration(border: Border.all()),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('card ${c.id}'),
            ),
          ),
        ),
      ),
    ),
  );
}

KanbanColumn<_Card> _column(
  String id, {
  List<String> cards = const ['1'],
  String? subtitle,
  Widget? trailing,
}) => KanbanColumn(
  id: id,
  title: 'Column $id',
  subtitle: subtitle,
  trailing: trailing,
  items: [for (final c in cards) _Card('$id$c', id)],
);

/// The column's own box: its resting border and its drop highlight.
AnimatedContainer _box(WidgetTester tester, String id) =>
    tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Column $id'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

void main() {
  testWidgets('first cards line up, whatever each header carries', (
    tester,
  ) async {
    await _pump(tester, [
      _column('a'),
      _column('b', subtitle: 'With a subtitle'),
      _column(
        'c',
        trailing: IconAction(
          Icons.add,
          label: 'Add',
          size: IconActionSize.small,
          onPressed: () {},
        ),
      ),
      _column('d', subtitle: 'Both', trailing: const SizedBox(width: 28)),
    ]);
    final tops = {
      for (final id in ['a', 'b', 'c', 'd'])
        tester.getTopLeft(find.text('card ${id}1')).dy,
    };
    expect(tops, hasLength(1));

    // Dot, title and count share the title row's centre line.
    final title = tester.getCenter(find.text('Column b')).dy;
    expect(tester.getCenter(find.text('1').at(1)).dy, closeTo(title, 0.5));
    expect(
      tester.getTopLeft(find.text('With a subtitle')).dy,
      greaterThan(tester.getBottomLeft(find.text('Column b')).dy),
    );

    // The header starts where the cards' content does, and ends where it
    // ends.
    final card = tester.getRect(find.text('card a1'));
    final dot = tester.getTopLeft(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('Column a'),
              matching: find.byType(Row),
            ),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(dot.dx, card.left);
    final cardBox = tester.getRect(
      find
          .ancestor(of: find.text('card a1'), matching: find.byType(Container))
          .first,
    );
    expect(
      tester.getTopRight(find.text('1').first).dx,
      closeTo(cardBox.right - 1 - KanbanBoard.cardPadding.right - 8, 0.5),
      reason: 'the count pill ends at the content edge, less its own padding',
    );
  });

  testWidgets('a drop target highlights without a wider border', (
    tester,
  ) async {
    final moves = <String>[];
    await _pump(tester, [
      _column('a'),
      _column('b', cards: const []),
    ], onMove: (item, from, to) => moves.add('${item.id} $from→$to'));
    BoxDecoration resting(String id) =>
        _box(tester, id).decoration! as BoxDecoration;
    BoxDecoration highlight(String id) =>
        _box(tester, id).foregroundDecoration! as BoxDecoration;
    final cardTop = tester.getTopLeft(find.text('card a1'));
    expect(resting('b').border!.top.width, 1);
    expect(highlight('b').border!.top.color.a, 0);
    expect(find.text('No items'), findsOneWidget);

    final drag = await tester.startGesture(
      tester.getCenter(find.text('card a1')),
    );
    await drag.moveBy(const Offset(20, 0));
    await tester.pump();
    // While a card is in flight, the empty column invites it.
    expect(find.text('Drop here'), findsOneWidget);
    await drag.moveTo(tester.getCenter(find.text('Column b')));
    await tester.pump();
    expect(resting('b').border!.top.width, 1);
    expect(highlight('b').border!.top.color.a, 1);
    expect(tester.getTopLeft(find.text('card a1').first), cardTop);

    await drag.up();
    await tester.pumpAndSettle();
    expect(moves, ['a1 a→b']);
    expect(find.text('Drop here'), findsNothing);
  });

  testWidgets('a read-only board has no drag, and says "No items"', (
    tester,
  ) async {
    await _pump(tester, [_column('a'), _column('b', cards: const [])]);
    expect(find.byType(Draggable<Object>), findsNothing);
    expect(find.text('No items'), findsOneWidget);
    expect(find.text('Drop here'), findsNothing);
  });

  testWidgets('Alt+→ / Alt+← move a focused card; screen readers get '
      '"Move to …"', (tester) async {
    final handle = tester.ensureSemantics();
    final moves = <String>[];
    await _pump(
      tester,
      [_column('a'), _column('b'), _column('c')],
      onMove: (item, from, to) => moves.add('${item.id} $from→$to'),
      onCardTap: (_) {},
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    // The first column has nothing to its left.
    expect(moves, ['a1 a→b']);

    final node = find.semantics.byLabel('card a1').evaluate().single;
    final actions = [
      for (final id in node.getSemanticsData().customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label,
    ];
    expect(actions, unorderedEquals(['Move to Column b', 'Move to Column c']));
    handle.dispose();
  });
}
