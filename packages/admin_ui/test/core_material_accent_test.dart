import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// Light accents, the ones whose own colour reads faintly on a light page,
/// then dark and saturated ones, then a fixed random spread.
final _seeds = [
  const Color(0xFF48CAE4),
  const Color(0xFFFFD60A),
  const Color(0xFF8BE9A8),
  const Color(0xFF1E3A8A),
  const Color(0xFFE11D48),
  for (final value in _random(30)) Color(0xFF000000 | value),
];

Iterable<int> _random(int count) {
  final random = math.Random(20261106);
  return [for (var i = 0; i < count; i++) random.nextInt(0x1000000)];
}

const _selected = {WidgetState.selected};

void main() {
  group('buildAppTheme draws the accent at its contrast target', () {
    for (final MapEntry(key: name, value: shipped) in shippedPalettes.entries) {
      test('$name × ${_seeds.length} accents', () {
        for (final seed in _seeds) {
          final p = shipped.branded(seed);
          final theme = buildAppTheme(AdminTokens.from(palette: p));
          final why = '$name + ${seed.toARGB32().toRadixString(16)}';

          expect(
            theme.outlinedButtonTheme.style!.foregroundColor!.resolve({}),
            p.primaryText,
            reason: '$why: an outlined button\'s label',
          );
          expect(
            theme.elevatedButtonTheme.style!.foregroundColor!.resolve({}),
            p.primaryText,
            reason: '$why: an elevated button\'s label',
          );
          expect(
            theme.listTileTheme.selectedColor,
            p.primaryText,
            reason: '$why: a selected list tile',
          );
          expect(
            theme.tabBarTheme.indicatorColor,
            p.controlAccent,
            reason: '$why: a tab indicator',
          );
          expect(
            theme.checkboxTheme.fillColor!.resolve(_selected),
            p.controlAccent,
            reason: '$why: a checked checkbox',
          );
          expect(
            theme.checkboxTheme.checkColor!.resolve(_selected),
            p.onControlAccent,
            reason: '$why: its check',
          );
          expect(
            theme.radioTheme.fillColor!.resolve(_selected),
            p.controlAccent,
            reason: '$why: a selected radio',
          );
          expect(
            theme.switchTheme.trackColor!.resolve(_selected),
            p.controlAccent,
            reason: '$why: a switch that is on',
          );
          expect(
            theme.switchTheme.thumbColor!.resolve(_selected),
            p.onControlAccent,
            reason: '$why: its thumb',
          );
        }
      });
    }
  });

  testWidgets('a stock outlined button under a light accent reads at 4.5:1', (
    tester,
  ) async {
    final p = irisPalette.branded(const Color(0xFF48CAE4));
    expect(
      contrastRatio(p.primary, p.surface),
      lessThan(4.5),
      reason: 'the accent alone would not read',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: p)),
        home: Scaffold(
          body: Center(
            child: OutlinedButton(onPressed: () {}, child: const Text('Edit')),
          ),
        ),
      ),
    );
    final label = tester.widget<RichText>(
      find.descendant(
        of: find.byType(OutlinedButton),
        matching: find.byType(RichText),
      ),
    );
    final color = label.text.style!.color!;
    expect(color, p.primaryText);
    expect(contrastRatio(color, p.surface), greaterThanOrEqualTo(4.5));
  });
}
