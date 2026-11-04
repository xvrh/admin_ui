import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/media_tile.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

List<Asset> _assets(int count) => [
  for (var i = 0; i < count; i++) Asset(id: 'a$i', name: 'asset_$i.jpg'),
];

/// 620px wide: four columns of the library's grid.
Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 620, height: 600, child: child),
          ),
        ),
      ),
    );

/// The title of the tile holding focus, or null.
String? _focused() {
  final context = FocusManager.instance.primaryFocus?.context;
  final tile = context?.findAncestorWidgetOfExactType<MediaTile>();
  final row = context?.findAncestorWidgetOfExactType<MediaListTile>();
  return tile?.title ?? row?.title;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

/// Tabs from the toolbar into the collection.
Future<void> _tabIn(WidgetTester tester) async {
  for (var i = 0; i < 12 && _focused() == null; i++) {
    await _key(tester, LogicalKeyboardKey.tab);
  }
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('the arrows move across a four-column grid', (tester) async {
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets(10), onOpen: (_) {})),
    );
    final first = tester.getRect(find.text('asset_0.jpg'));
    final fourth = tester.getRect(find.text('asset_3.jpg'));
    final fifth = tester.getRect(find.text('asset_4.jpg'));
    expect(fourth.top, first.top, reason: 'four tiles to a row');
    expect(fifth.top, greaterThan(first.top));

    await _tabIn(tester);
    expect(_focused(), 'asset_0.jpg');

    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'asset_1.jpg');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'asset_5.jpg');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(), 'asset_4.jpg');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_focused(), 'asset_0.jpg');

    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(), 'asset_0.jpg', reason: 'the edges hold');

    await _key(tester, LogicalKeyboardKey.end);
    expect(_focused(), 'asset_9.jpg');
    await _key(tester, LogicalKeyboardKey.home);
    expect(_focused(), 'asset_0.jpg');

    // Down from a column the short last row does not reach: its last tile.
    for (var i = 0; i < 3; i++) {
      await _key(tester, LogicalKeyboardKey.arrowRight);
    }
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'asset_7.jpg');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'asset_9.jpg');
  });

  testWidgets('the grid is one Tab stop, which remembers the last tile', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets(10), onOpen: (_) {})),
    );
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'asset_5.jpg');

    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(), isNull, reason: 'Tab leaves the grid');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await _key(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();
    expect(_focused(), 'asset_5.jpg');
  });

  testWidgets('Space toggles the focused tile and Enter confirms', (
    tester,
  ) async {
    final toggled = <String>[];
    var confirmed = 0;
    await tester.pumpWidget(
      _host(
        AssetLibrary(
          assets: _assets(10),
          selectionMode: AssetSelectionMode.multiple,
          onToggle: toggled.add,
          onConfirm: () => confirmed++,
        ),
      ),
    );
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.space);
    expect(toggled, ['a1']);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(toggled, ['a1', 'a2']);
    expect(confirmed, 1);
  });

  testWidgets('End reaches a tile far past what is built', (tester) async {
    await tester.pumpWidget(
      _host(AssetLibrary(assets: _assets(300), onOpen: (_) {})),
    );
    expect(find.text('asset_299.jpg'), findsNothing);
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.end);
    await tester.pump();
    expect(_focused(), 'asset_299.jpg');
    await _key(tester, LogicalKeyboardKey.home);
    await tester.pump();
    expect(_focused(), 'asset_0.jpg');
  });

  testWidgets('right-to-left, → moves back', (tester) async {
    await tester.pumpWidget(
      _host(
        AssetLibrary(assets: _assets(10), onOpen: (_) {}),
        direction: TextDirection.rtl,
      ),
    );
    await _tabIn(tester);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(), 'asset_1.jpg');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'asset_0.jpg');
  });

  testWidgets('in the list, ↑ and ↓ move a row at a time', (tester) async {
    await tester.pumpWidget(
      _host(
        AssetLibrary(assets: _assets(10), view: AssetView.list, onOpen: (_) {}),
      ),
    );
    await _tabIn(tester);
    expect(_focused(), 'asset_0.jpg');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'asset_2.jpg');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'asset_2.jpg');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_focused(), 'asset_1.jpg');
    await _key(tester, LogicalKeyboardKey.end);
    expect(_focused(), 'asset_9.jpg');
  });
}
