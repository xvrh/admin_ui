// AssetLibrary's tile size: two columns while the library is narrower than
// the theme's medium breakpoint (a phone's two-up grid), columns of at most
// 150 from there, and the host's own maxTileExtent when it gives one.

import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/assets/ui/media_tile.dart';
import 'package:admin_ui/src/theme/breakpoints.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _assets = [
  for (var i = 0; i < 12; i++)
    Asset(id: '$i', name: 'photo_$i.jpg', width: 800, height: 600),
];

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double? maxTileExtent,
  AdminTokens? tokens,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? defaultTokens),
      home: Scaffold(
        body: AssetLibrary(assets: _assets, maxTileExtent: maxTileExtent),
      ),
    ),
  );
}

/// The columns of the first row, and the width of a tile.
(int, double) _grid(WidgetTester tester) {
  final tiles = find.byType(MediaTile);
  final top = tester.getRect(tiles.first).top;
  final row = [
    for (final e in tiles.evaluate())
      if (tester.getRect(find.byWidget(e.widget)).top == top) e,
  ];
  return (row.length, tester.getSize(tiles.first).width);
}

void main() {
  testWidgets('a phone-wide library is two-up', (tester) async {
    for (final width in [320.0, 360.0, 393.0, 599.0]) {
      await _pump(tester, width: width);
      final (columns, tile) = _grid(tester);
      expect(columns, 2, reason: '$width');
      // The grid's 16px padding each side and one 12px gap.
      expect(tile, (width - 2 * MediaGrid.padding - MediaGrid.gap) / 2);
    }
  });

  testWidgets('from the medium breakpoint, columns are at most 150', (
    tester,
  ) async {
    for (final (width, expected) in [(600.0, 4), (1000.0, 7), (1200.0, 8)]) {
      await _pump(tester, width: width);
      final (columns, tile) = _grid(tester);
      expect(columns, expected, reason: '$width');
      expect(tile, lessThanOrEqualTo(150));
    }
  });

  testWidgets('the theme sets the breakpoint', (tester) async {
    final tokens = defaultTokens.copyWith(
      breakpoints: const AdminBreakpoints(medium: 400),
    );
    await _pump(tester, width: 480, tokens: tokens);
    expect(_grid(tester).$1, 3);
    await _pump(tester, width: 380, tokens: tokens);
    expect(_grid(tester).$1, 2);
  });

  testWidgets("the host's maxTileExtent wins, at any width", (tester) async {
    await _pump(tester, width: 360, maxTileExtent: 110);
    expect(_grid(tester).$1, 3);
    await _pump(tester, width: 1000, maxTileExtent: 300);
    expect(_grid(tester).$1, 4);
  });

  testWidgets('right to left, the two-up grid mirrors', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: AssetLibrary(assets: _assets)),
        ),
      ),
    );
    final first = tester.getRect(find.byType(MediaTile).at(0));
    final second = tester.getRect(find.byType(MediaTile).at(1));
    expect(first.right, 360 - MediaGrid.padding);
    expect(second.left, MediaGrid.padding);
  });
}
