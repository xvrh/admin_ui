import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// The three ways the kit dims the page: a route dialog, a route side sheet
/// and a portal modal on a [ModalAnchor]. Each opens a plain box and passes
/// the override colour through when one is given.
typedef _Opener = void Function(
  BuildContext context,
  ModalAnchorController anchor,
  Color? barrierColor,
);

final _openers = <String, _Opener>{
  'showModal': (context, _, color) => showModal<void>(
    context,
    barrierColor: color,
    builder: (_) => const SizedBox(width: 200, height: 100),
  ),
  'showSideSheet': (context, _, color) => showSideSheet<void>(
    context,
    barrierColor: color,
    builder: (_) => const SideSheet(child: SizedBox()),
  ),
  'ModalAnchorController.show': (_, anchor, color) => anchor.show<void>(
    barrierColor: color,
    builder: (_) => const SizedBox(width: 200, height: 100),
  ),
};

/// Opens [open] from a page themed with [palette] and returns the colour of
/// the barrier it put up.
Future<Color> _barrierColor(
  WidgetTester tester,
  AdminPalette palette,
  _Opener open, {
  Color? override,
}) async {
  final anchor = ModalAnchorController();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(AdminTokens.from(palette: palette)),
      home: Scaffold(
        body: ModalAnchor(
          controller: anchor,
          child: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => open(context, anchor, override),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  // Every route has a barrier; the page route's is uncoloured.
  final colored = tester
      .widgetList<ModalBarrier>(find.byType(ModalBarrier))
      .map((b) => b.color)
      .whereType<Color>()
      .where((c) => c.a > 0)
      .toList();
  expect(colored, hasLength(1));
  return colored.single;
}

void main() {
  for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
    group(name, () {
      for (final MapEntry(key: how, value: open) in _openers.entries) {
        testWidgets('$how dims the page with the palette scrim', (
          tester,
        ) async {
          final barrier = await _barrierColor(tester, palette, open);
          expect(barrier, palette.scrim);

          // The page is `background` and the cards on it are `surface`: the
          // scrim must darken both, never wash them lighter.
          // A pure-black page (Ant's dark layout) can only stay black.
          for (final surface in [palette.background, palette.surface]) {
            final before = relativeLuminance(surface);
            final after = relativeLuminance(Color.alphaBlend(barrier, surface));
            expect(
              after,
              before == 0 ? 0 : lessThan(before),
              reason: 'scrim over $surface',
            );
          }
        });
      }
    });
  }

  for (final MapEntry(key: how, value: open) in _openers.entries) {
    testWidgets('$how takes a barrierColor override', (tester) async {
      const override = Color(0x33102030);
      final barrier = await _barrierColor(
        tester,
        irisDarkPalette,
        open,
        override: override,
      );
      expect(barrier, override);
    });
  }
}
