import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui_example/src/utils/test_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness/harness.dart';

/// Lays out [child] [width] wide in [config]'s theme and text scale, in the
/// fonts the catalog and its sweeps draw with, and returns whether it fits:
/// whether it laid out without an overflow.
Future<bool> _fits(
  WidgetTester tester,
  RenderConfig config,
  double width,
  Widget child,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 900);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    TestApp(
      theme: buildAppTheme(
        withTestFontFallback(config.tokens, fallback: catalogFontFallback),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          // A new subtree each time: a flex reports its overflow once.
          child: SizedBox(key: UniqueKey(), width: width, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.takeException() == null;
}

/// A card with every part, loaded with a short delta, or loading.
StatCard _card({required bool loading}) => StatCard(
  label: 'Revenue',
  value: r'$48.2k',
  icon: Icons.payments_rounded,
  delta: StatDelta(loading ? '' : '12%'),
  caption: loading ? '' : 'vs last month',
  loading: loading,
);

/// A loading [StatCard] in the catalog's fonts rather than the kit's test
/// font, which is narrower than every theme's: in it the kit's own tests
/// cannot see a placeholder outgrow its card.
void main() {
  for (final combo in allCombos) {
    for (final scale in [1.0, 2.0]) {
      final config = combo.copyWith(textScale: scale);
      testWidgets('a loading StatGrid tile fits wherever the card it becomes '
          'does: $config', (tester) async {
        // Half pixels: a grid splits its width evenly, so a tile can be
        // 165.5 wide.
        for (var width = 100.0; width <= 200; width += 0.5) {
          final loaded = await _fits(
            tester,
            config,
            width,
            StatGrid(children: [_card(loading: false)]),
          );
          if (!loaded) continue;
          expect(
            await _fits(
              tester,
              config,
              width,
              StatGrid(children: [_card(loading: true)]),
            ),
            isTrue,
            reason: 'The loaded card fits $width wide; the loading one not',
          );
        }
      });
    }
  }

  testWidgets('four loading tiles fit two across a phone, at twice the text '
      'size in Ant', (tester) async {
    // A 375 phone with a 16 margin each side: tiles 165.5 wide.
    expect(
      await _fits(
        tester,
        RenderConfig.of('Ant', ThemeMode.light).copyWith(textScale: 2),
        343,
        StatGrid(
          minTileWidth: 140,
          children: [for (var i = 0; i < 4; i++) _card(loading: true)],
        ),
      ),
      isTrue,
    );
    expect(tester.getSize(find.byType(StatCard).first).width, 165.5);
  });
}
