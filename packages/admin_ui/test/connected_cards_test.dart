import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Item {
  final int id;
  final String name;
  _Item(this.id, this.name);
}

List<_Item> _items(int n) => [for (var i = 0; i < n; i++) _Item(i, 'Item $i')];

Widget _host(Widget child, {double width = 800, double height = 400}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

/// The selection-aware cards over [rows], selection held here.
class _Selectable extends StatefulWidget {
  final List<_Item> rows;
  final ValueChanged<_Item>? onOpen;
  const _Selectable({required this.rows, this.onOpen});

  @override
  State<_Selectable> createState() => _SelectableState();
}

class _SelectableState extends State<_Selectable> {
  Set<_Item> selected = {};

  void select(Set<_Item> rows) => setState(() => selected = rows);

  @override
  Widget build(BuildContext context) => CollectionCards<_Item>(
    rows: widget.rows,
    rowKey: (r) => r.id,
    cardBuilder: (_, r) => SizedBox(height: 80, child: Text(r.name)),
    onCardTap: widget.onOpen,
    selected: selected,
    onSelectionChanged: (s) => setState(() => selected = s),
  );
}

Set<int> _selectedIds(WidgetTester tester) => tester
    .state<_SelectableState>(find.byType(_Selectable))
    .selected
    .map((r) => r.id)
    .toSet();

/// The opacity the checkbox of the card showing [text] is drawn at.
double _checkOpacity(WidgetTester tester, String text) {
  final card = find.ancestor(of: find.text(text), matching: find.byType(Stack));
  return tester
      .widget<Opacity>(
        find.descendant(of: card.first, matching: find.byType(Opacity)),
      )
      .opacity;
}

void main() {
  testWidgets('only the tiles in view are built', (tester) async {
    await tester.pumpWidget(
      _host(
        CollectionCards<_Item>(
          rows: _items(300),
          cardBuilder: (_, r) => SizedBox(height: 100, child: Text(r.name)),
        ),
      ),
    );
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 299'), findsNothing);
    expect(find.textContaining('Item '), findsAtLeastNWidgets(3));
    expect(
      tester.widgetList(find.textContaining('Item ')).length,
      lessThan(40),
    );
  });

  testWidgets('a fixed tileHeight builds a grid of that extent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CollectionCards<_Item>(
          rows: _items(300),
          tileHeight: 120,
          cardBuilder: (_, r) => Text(r.name),
        ),
      ),
    );
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Item 299'), findsNothing);
    final a = find.ancestor(
      of: find.text('Item 0'),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(a).height, 120);
  });

  testWidgets('each row of cards stretches to its tallest card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CollectionCards<_Item>(
          rows: _items(3),
          cardBuilder: (_, r) =>
              SizedBox(height: r.id == 1 ? 140 : 60, child: Text(r.name)),
        ),
      ),
    );
    double heightOf(String text) => tester
        .getSize(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .height;
    expect(heightOf('Item 0'), heightOf('Item 1'));
    expect(heightOf('Item 2'), heightOf('Item 1'));
    expect(heightOf('Item 1'), 142); // 140 + the 1px border each side
  });

  testWidgets('a card that grows after layout stretches its row again', (
    tester,
  ) async {
    final grown = ValueNotifier<double>(60);
    addTearDown(grown.dispose);
    await tester.pumpWidget(
      _host(
        CollectionCards<_Item>(
          rows: _items(3),
          cardBuilder: (_, r) => r.id == 1
              ? ValueListenableBuilder(
                  valueListenable: grown,
                  builder: (_, height, _) =>
                      SizedBox(height: height, child: Text(r.name)),
                )
              : SizedBox(height: 60, child: Text(r.name)),
        ),
      ),
    );
    double heightOf(String text) => tester
        .getSize(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .height;
    expect(heightOf('Item 1'), 62);

    grown.value = 140;
    await tester.pump();
    expect(heightOf('Item 1'), 142);
    expect(heightOf('Item 0'), 142);
    expect(heightOf('Item 2'), 142);
  });

  testWidgets(
    'long-press selects; Space on a focused card toggles, Enter opens',
    (tester) async {
      final opened = <int>[];
      await tester.pumpWidget(
        _host(_Selectable(rows: _items(4), onOpen: (r) => opened.add(r.id))),
      );
      await tester.longPress(find.text('Item 2'));
      await tester.pump();
      expect(_selectedIds(tester), {2});

      // Tab: card 0, its checkbox, card 1.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(_selectedIds(tester), {1, 2});
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(_selectedIds(tester), {2});
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, [1]);
    },
  );

  testWidgets(
    'selection by key: fresh objects of a selected row stay selected',
    (tester) async {
      final rows = _items(3);
      Set<_Item> selected = {rows[1]};
      Widget cards(List<_Item> rows) => CollectionCards<_Item>(
        rows: rows,
        rowKey: (r) => r.id,
        cardBuilder: (_, r) => Text(r.name),
        selected: selected,
        onSelectionChanged: (s) => selected = s,
      );
      await tester.pumpWidget(_host(cards(rows)));
      final refetched = _items(3);
      await tester.pumpWidget(_host(cards(refetched)));
      expect(
        tester
            .widget<Tappable>(
              find
                  .ancestor(
                    of: find.text('Item 1'),
                    matching: find.byType(Tappable),
                  )
                  .last,
            )
            .selected,
        isTrue,
      );
      // Toggling the fresh copy off removes the old one.
      await tester.longPress(find.text('Item 1'));
      expect(selected, isEmpty);
    },
  );

  testWidgets('the selected ring never moves the content', (tester) async {
    await tester.pumpWidget(_host(_Selectable(rows: _items(2))));
    final before = tester.getRect(find.text('Item 0'));
    final boxBefore = tester.getRect(
      find.ancestor(
        of: find.text('Item 0'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    await tester.longPress(find.text('Item 0'));
    await tester.pumpAndSettle();
    expect(_selectedIds(tester), {0});
    expect(tester.getRect(find.text('Item 0')), before);
    final container = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Item 0'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final border = (container.decoration! as BoxDecoration).border! as Border;
    expect(border.top.width, 1);
    final ring =
        (container.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(ring.top.width, 2);
    expect(
      tester.getRect(
        find.ancestor(
          of: find.text('Item 0'),
          matching: find.byType(AnimatedContainer),
        ),
      ),
      boxBefore,
    );
  });

  group('the corner checkbox', () {
    testWidgets('hides under a mouse until anything is selected', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_Selectable(rows: _items(3))));
      expect(_checkOpacity(tester, 'Item 0'), 0);
      expect(_checkOpacity(tester, 'Item 2'), 0);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.text('Item 0')));
      addTearDown(gesture.removePointer);
      await tester.pump();
      expect(_checkOpacity(tester, 'Item 0'), 1);
      await gesture.moveTo(const Offset(790, 390));
      await tester.pump();

      tester.state<_SelectableState>(find.byType(_Selectable)).select({
        _Item(1, 'x'),
      });
      await tester.pump();
      expect(_checkOpacity(tester, 'Item 0'), 1);
      expect(_checkOpacity(tester, 'Item 2'), 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('always shows on a touch device', (tester) async {
      await tester.pumpWidget(_host(_Selectable(rows: _items(3))));
      expect(_checkOpacity(tester, 'Item 0'), 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('shows after a touch on a desktop', (tester) async {
      await tester.pumpWidget(_host(_Selectable(rows: _items(3))));
      expect(_checkOpacity(tester, 'Item 1'), 0);
      await tester.tapAt(const Offset(790, 390)); // empty grid space
      await tester.pump();
      expect(_checkOpacity(tester, 'Item 1'), 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  group('states', () {
    testWidgets('a reload shows the bar and dims only after 150ms', (
      tester,
    ) async {
      Widget cards(bool loading) => CollectionCards<_Item>(
        rows: _items(3),
        cardBuilder: (_, r) => Text(r.name),
        loading: loading,
      );
      await tester.pumpWidget(_host(cards(false)));
      await tester.pumpWidget(_host(cards(true)));
      expect(find.byType(TopProgressBar), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(TopProgressBar), findsOneWidget);
      await tester.pumpWidget(_host(cards(false)));
      expect(find.byType(TopProgressBar), findsNothing);
    });

    testWidgets('the first load sketches skeleton cards', (tester) async {
      await tester.pumpWidget(
        _host(
          CollectionCards<_Item>(
            rows: const [],
            cardBuilder: (_, r) => Text(r.name),
            loading: true,
          ),
        ),
      );
      expect(find.byType(Skeleton), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('a filtered empty result offers Clear filters', (tester) async {
      var cleared = 0;
      await tester.pumpWidget(
        _host(
          CollectionCards<_Item>(
            rows: const [],
            cardBuilder: (_, r) => Text(r.name),
            empty: const Text('Nothing yet'),
            filtered: true,
            onClearFilters: () => cleared++,
          ),
        ),
      );
      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Nothing yet'), findsNothing);
      await tester.tap(find.text('Clear filters'));
      expect(cleared, 1);
    });
  });
}
