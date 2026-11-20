import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

// The stock scheme's secondary container is the palette's soft fill, so a
// stock tonal button, a selected chip or a navigation bar's indicator is
// drawn as the kit's own soft button is.

Widget _app(AdminPalette palette, Widget child) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette)),
  home: Scaffold(body: Center(child: child)),
);

/// The fill a stock tonal button paints, and the colour of its label.
Future<(Color?, Color?)> _tonal(
  WidgetTester tester,
  AdminPalette palette,
) async {
  await tester.pumpWidget(
    _app(
      palette,
      FilledButton.tonal(onPressed: () {}, child: const Text('Save')),
    ),
  );
  // A change of theme is animated: wait for the new one.
  await tester.pumpAndSettle();
  final fill = tester
      .widget<Material>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        ),
      )
      .color;
  final label = tester
      .widget<RichText>(
        find.descendant(of: find.text('Save'), matching: find.byType(RichText)),
      )
      .text
      .style
      ?.color;
  return (fill, label);
}

void main() {
  for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
    test('$name: the secondary container is the soft fill', () {
      final scheme = palette.colorScheme;
      expect(scheme.secondaryContainer, palette.softFill);
      expect(scheme.onSecondaryContainer, palette.onSoft);
      // The primary container stays the selection tint.
      expect(scheme.primaryContainer, palette.primarySubtle);
      expect(scheme.onPrimaryContainer, palette.primaryText);
    });
  }

  test('Material takes M3\'s own secondary container', () {
    final light = materialPalette.colorScheme;
    expect(light.secondaryContainer, const Color(0xFFE8DEF8));
    expect(light.onSecondaryContainer, const Color(0xFF1D192B));
    final dark = materialDarkPalette.colorScheme;
    expect(dark.secondaryContainer, const Color(0xFF4A4458));
    expect(dark.onSecondaryContainer, const Color(0xFFE8DEF8));
  });

  test('a palette that authors no soft fill keeps what it had', () {
    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      if (name.startsWith('Material')) continue;
      final scheme = palette.colorScheme;
      expect(scheme.secondaryContainer, palette.primarySubtle, reason: name);
      expect(scheme.onSecondaryContainer, palette.primaryText, reason: name);
    }
  });

  testWidgets('a stock tonal button is drawn as the soft fill', (tester) async {
    for (final palette in [
      irisPalette,
      materialPalette,
      materialDarkPalette,
      // A palette of an app's own, with a soft fill no shipped one has.
      irisPalette.copyWith(
        softFill: const Color(0xFFDFF5E6),
        onSoft: const Color(0xFF0B3D1E),
      ),
    ]) {
      final (fill, label) = await _tonal(tester, palette);
      expect(fill, palette.softFill);
      expect(label, palette.onSoft);
    }
    // Material's is no longer its selection tint.
    final (fill, label) = await _tonal(tester, materialPalette);
    expect(fill, isNot(materialPalette.primarySubtle));
    expect(label, isNot(materialPalette.primaryText));
  });
}
