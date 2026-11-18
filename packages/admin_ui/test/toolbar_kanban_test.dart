import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
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
  bool Function(_Card item)? canOpen,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(1600, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(
        body: KanbanBoard<_Card>(
          columns: columns,
          itemKey: (c) => c.id,
          onMove: onMove,
          onCardTap: onCardTap,
          canOpen: canOpen,
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

/// The card [id], under the key the board gives it: its `itemKey`, an
/// Object.
Finder _card(String id) => find.byKey(ValueKey<Object>(id));

/// The ⋯ menu of the card [id].
Finder _menuOf(String id) => find.descendant(
  of: _card(id),
  matching: find.byIcon(Icons.more_horiz_rounded),
);

/// How visible the card's ⋯ is: 0 hidden, 1 shown.
double _menuOpacity(WidgetTester tester, String id) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(of: _menuOf(id), matching: find.byType(AnimatedOpacity)),
    )
    .opacity;

Future<void> _alt(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pump();
}

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

  testWidgets('a card canOpen leaves out is no Tab stop and opens on no tap', (
    tester,
  ) async {
    final opened = <String>[];
    await _pump(
      tester,
      [
        _column('a', cards: const ['1', '2']),
      ],
      onCardTap: (item) => opened.add(item.id),
      canOpen: (item) => item.id != 'a1',
    );

    await tester.tap(find.text('card a1'));
    await tester.pump();
    expect(opened, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['a2']);
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

  testWidgets('with onMove, a card that does not open is still a Tab stop, '
      'to move from', (tester) async {
    final handle = tester.ensureSemantics();
    final moves = <String>[];
    final opened = <String>[];
    await _pump(
      tester,
      [
        _column('a', cards: const ['1', '2']),
        _column('b', cards: const []),
      ],
      onMove: (item, from, to) => moves.add('${item.id} $from→$to'),
      onCardTap: (item) => opened.add(item.id),
      canOpen: (item) => item.id != 'a1',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('card a1')),
      isSemantics(
        label: 'card a1',
        isFocusable: true,
        isFocused: true,
        hasFocusAction: true,
        customActions: [const CustomSemanticsAction(label: 'Move to Column b')],
      ),
    );
    // The ring is the one a card that opens draws.
    final ring = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          ((w.decoration as BoxDecoration).border! as Border).top.color ==
              defaultTokens.palette.focusRing,
    );
    expect(ring, findsOneWidget);

    // Enter opens nothing; Alt+→ moves it.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, isEmpty);
    await _alt(tester, LogicalKeyboardKey.arrowRight);
    expect(moves, ['a1 a→b']);
    handle.dispose();
  });

  testWidgets('each card has a menu that moves it to any other column', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final moves = <String>[];
    final opened = <String>[];
    await _pump(
      tester,
      [_column('a'), _column('b'), _column('c')],
      onMove: (item, from, to) => moves.add('${item.id} $from→$to'),
      onCardTap: (item) => opened.add(item.id),
    );
    expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(3));
    expect(
      tester.getSemantics(_menuOf('b1')),
      isSemantics(
        label: 'Move to…',
        isButton: true,
        hasExpandedState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    // A mouse over the card shows it; a click on it opens the menu, not
    // the card.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('card b1')));
    await tester.pumpAndSettle();
    await mouse.down(tester.getCenter(_menuOf('b1')));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(find.text('Move to Column a'), findsOneWidget);
    expect(find.text('Move to Column b'), findsNothing);

    await tester.tap(find.text('Move to Column c'));
    await tester.pumpAndSettle();
    expect(moves, ['b1 b→c']);
    handle.dispose();
  });

  testWidgets('the menu shows under the pointer and on focus, and is the '
      'Tab stop after its card', (tester) async {
    final moves = <String>[];
    await _pump(
      tester,
      [
        _column('a', cards: const ['1', '2']),
        _column('b', cards: const []),
      ],
      onMove: (item, from, to) => moves.add('${item.id} $from→$to'),
      onCardTap: (_) {},
    );
    // A mouse has landed, and is elsewhere: the menus wait for it.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.down(const Offset(5, 5));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 0);
    // Hidden, it takes no click: the card under it does.
    expect(_menuOf('a1').hitTestable(), findsNothing);

    await mouse.moveTo(tester.getCenter(find.text('card a1')));
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 1);
    expect(_menuOpacity(tester, 'a2'), 0);
    await mouse.moveTo(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 0);

    // Tab: the card, which shows its menu, then the menu itself.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 1);
    expect(_menuOpacity(tester, 'a2'), 0);

    // Enter opens it on its first item, and Enter again moves the card.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Move to Column b'), findsOneWidget);
    expect(_menuOpacity(tester, 'a1'), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(moves, ['a1 a→b']);

    // And Alt+arrows move the card from its menu too.
    await _alt(tester, LogicalKeyboardKey.arrowRight);
    expect(moves, ['a1 a→b', 'a1 a→b']);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 0);
    expect(_menuOpacity(tester, 'a2'), 1);
  });

  testWidgets('hidden, the menu is not read to a screen reader, which '
      'moves the card by the card\'s own actions', (tester) async {
    final handle = tester.ensureSemantics();
    final moves = <String>[];
    await _pump(
      tester,
      [_column('a'), _column('b', cards: const [])],
      onMove: (item, from, to) => moves.add('${item.id} $from→$to'),
      onCardTap: (_) {},
    );
    // A mouse has landed, elsewhere: the menu waits for it, hidden.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.down(const Offset(5, 5));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 0);
    expect(find.semantics.byLabel('Move to…'), findsNothing);

    // The card carries the move itself.
    tester.semantics.customAction(
      find.semantics.byLabel('card a1'),
      const CustomSemanticsAction(label: 'Move to Column b'),
    );
    expect(moves, ['a1 a→b']);

    // Shown, the menu is a button that opens.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 1);
    expect(
      find.semantics.byLabel('Move to…').evaluate().single,
      isSemantics(label: 'Move to…', isButton: true, hasTapAction: true),
    );
    tester.semantics.tap(find.semantics.byLabel('Move to…'));
    await tester.pumpAndSettle();
    expect(find.text('Move to Column b'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('under a finger, which has no hover, the menus stay up', (
    tester,
  ) async {
    final moves = <String>[];
    await _pump(tester, [
      _column('a'),
      _column('b'),
    ], onMove: (item, from, to) => moves.add('${item.id} $from→$to'));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(_menuOpacity(tester, 'a1'), 1);
    expect(_menuOpacity(tester, 'b1'), 1);

    await tester.tap(_menuOf('a1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Column b'));
    await tester.pumpAndSettle();
    expect(moves, ['a1 a→b']);
  });

  testWidgets('right to left, Alt+← still moves a card left, a column on', (
    tester,
  ) async {
    final moves = <String>[];
    await _pump(
      tester,
      [_column('a'), _column('b')],
      onMove: (item, from, to) => moves.add('${item.id} $from→$to'),
      direction: TextDirection.rtl,
    );
    expect(
      tester.getCenter(find.text('Column a')).dx,
      greaterThan(tester.getCenter(find.text('Column b')).dx),
    );
    // The ⋯ sits in the top end corner, on the left.
    expect(
      tester.getCenter(_menuOf('a1')).dx,
      lessThan(tester.getCenter(_card('a1')).dx),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await _alt(tester, LogicalKeyboardKey.arrowRight);
    expect(moves, isEmpty);
    await _alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(moves, ['a1 a→b']);
  });

  testWidgets('a read-only board has no menus', (tester) async {
    await _pump(tester, [_column('a'), _column('b')], onCardTap: (_) {});
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });
}
