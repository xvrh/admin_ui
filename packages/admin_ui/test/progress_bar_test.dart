import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 240, child: child)),
  ),
);

LinearProgressIndicator _bar(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));

/// The colour the bar fills with.
Color _fill(WidgetTester tester) =>
    (_bar(tester).valueColor! as AlwaysStoppedAnimation<Color?>).value!;

void main() {
  testWidgets('determinate bar reflects value', (tester) async {
    await tester.pumpWidget(_host(const ProgressBar(value: 0.42)));
    expect(_bar(tester).value, 0.42);
  });

  testWidgets('value is clamped to 0..1', (tester) async {
    await tester.pumpWidget(_host(const ProgressBar(value: 1.8)));
    expect(_bar(tester).value, 1.0);
  });

  testWidgets('null value renders an indeterminate bar', (tester) async {
    await tester.pumpWidget(_host(const ProgressBar(value: null)));
    expect(_bar(tester).value, isNull);
  });

  testWidgets('showPercent renders a rounded readout', (tester) async {
    await tester.pumpWidget(
      _host(const ProgressBar(value: 0.617, showPercent: true)),
    );
    expect(find.text('62%'), findsOneWidget);
  });

  testWidgets('percent is hidden when indeterminate', (tester) async {
    await tester.pumpWidget(
      _host(const ProgressBar(value: null, showPercent: true)),
    );
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('label is rendered above the bar', (tester) async {
    await tester.pumpWidget(
      _host(const ProgressBar(value: 0.3, label: 'cover.jpg')),
    );
    expect(find.text('cover.jpg'), findsOneWidget);
  });

  testWidgets('takes the theme small radius: square in Carbon', (tester) async {
    for (final tokens in [irisTheme.tokens, carbonTheme.tokens]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: const Scaffold(
            body: SizedBox(width: 240, child: ProgressBar(value: 0.5)),
          ),
        ),
      );
      // Past the theme change's cross-fade.
      await tester.pump(const Duration(seconds: 1));
      final clip = tester.widget<ClipRRect>(
        find.ancestor(
          of: find.byType(LinearProgressIndicator),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(
        clip.borderRadius,
        BorderRadius.circular(tokens.radii.radiusSmall),
      );
    }
    expect(carbonTheme.tokens.radii.radiusSmall, 0);
  });

  // Every fill — the primary and each severity — in every shipped theme and
  // mode and under every catalog brand stands 3:1 off the track and the page
  // (WCAG 1.4.11), and keeps its colour where that already does. Only the
  // palette matters, so each is drawn in Iris's type, which needs no font
  // download.
  group('fill', () {
    for (final theme in adminThemes) {
      for (final (mode, base) in [
        ('Light', theme.palette),
        ('Dark', theme.darkPalette!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          final p = seed == null ? base : base.branded(seed);
          testWidgets('${theme.name} $mode $brand: each fill reaches 3:1', (
            tester,
          ) async {
            final theme = buildAppTheme(defaultTokens.copyWith(palette: p));
            final against = [
              ('track', p.border),
              ('surface', p.surface),
              ('background', p.background),
            ];
            bool holds(Color c) =>
                against.every((a) => contrastRatio(c, a.$2) >= 3);
            for (final severity in [null, ...Severity.values]) {
              await tester.pumpWidget(
                MaterialApp(
                  theme: theme,
                  home: Scaffold(
                    body: ProgressBar(value: 0.9, severity: severity),
                  ),
                ),
              );
              final accent = switch (severity) {
                null => p.primary,
                Severity.info => p.info,
                Severity.success => p.success,
                Severity.warning => p.warning,
                Severity.danger => p.danger,
              };
              final fill = _fill(tester);
              final name = severity?.name ?? 'primary';
              for (final (surface, color) in against) {
                expect(
                  contrastRatio(fill, color),
                  greaterThanOrEqualTo(3),
                  reason: '$name on the $surface',
                );
              }
              if (holds(accent)) {
                expect(fill, accent, reason: '$name already reads');
              }
            }
          });
        }
      }
    }
  });
}
