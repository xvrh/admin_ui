import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// The shipped palettes, by theme and mode, plus the catalog's brand accents
/// over the default light and dark ones.
final _palettes = {
  ...shippedPalettes,
  for (final (name, seed) in const [
    ('Crimson', Color(0xFFE11D48)),
    ('Violet', Color(0xFF7C3AED)),
    ('Teal', Color(0xFF0D9488)),
    ('Amber', Color(0xFFD97706)),
  ]) ...{
    'Iris Light + $name': irisPalette.branded(seed),
    'Iris Dark + $name': irisDarkPalette.branded(seed),
  },
};

Widget _host(AdminPalette palette, Widget child) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette)),
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 800, child: child)),
  ),
);

Color _iconColor(WidgetTester tester, Finder icon) =>
    tester.widget<Icon>(icon).color!;

/// The fills behind [finder], nearest first.
List<Color> _fillsBehind(WidgetTester tester, Finder finder) => [
  for (final container in tester.widgetList<Container>(
    find.ancestor(of: finder, matching: find.byType(Container)),
  ))
    ?(container.decoration as BoxDecoration?)?.color,
];

/// What [finder] actually sits on: its nearest fills composited from the
/// first opaque one up.
Color _backdrop(WidgetTester tester, Finder finder) {
  final fills = _fillsBehind(tester, finder);
  final opaque = fills.indexWhere((c) => c.a == 1);
  var color = fills[opaque];
  for (final fill in fills.take(opaque).toList().reversed) {
    color = Color.alphaBlend(fill, color);
  }
  return color;
}

void main() {
  for (final MapEntry(key: name, value: palette) in _palettes.entries) {
    group(name, () {
      testWidgets('Steps glyphs read on their node fills', (tester) async {
        await tester.pumpWidget(
          _host(
            palette,
            const Steps(
              steps: [StepItem('One'), StepItem('Two'), StepItem('Three')],
              current: 2,
              errorSteps: {1},
            ),
          ),
        );

        for (final (glyph, fill) in [
          (Icons.check_rounded, palette.primary),
          (Icons.priority_high_rounded, palette.danger),
        ]) {
          final icon = find.byIcon(glyph);
          expect(_fillsBehind(tester, icon).first, fill);
          expect(
            contrastRatio(_iconColor(tester, icon), fill),
            greaterThanOrEqualTo(3),
            reason: '$glyph on its node',
          );
        }
        final active = tester.widget<Text>(find.text('3'));
        expect(
          contrastRatio(active.style!.color!, palette.primaryFaint),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('attention tiles and deltas keep their text safe', (
        tester,
      ) async {
        const tones = {
          Severity.info: Icons.info_outline,
          Severity.success: Icons.check,
          Severity.warning: Icons.warning_amber,
          Severity.danger: Icons.error_outline,
        };
        await tester.pumpWidget(
          _host(
            palette,
            Column(
              children: [
                AttentionGrid(
                  items: [
                    for (final MapEntry(key: tone, value: icon)
                        in tones.entries)
                      AttentionItem(
                        label: tone.name,
                        count: 1,
                        icon: icon,
                        tone: tone,
                      ),
                  ],
                ),
                const StatGrid(
                  children: [
                    StatCard(label: 'Up', value: '1', delta: StatDelta('up')),
                    StatCard(
                      label: 'Down',
                      value: '1',
                      delta: StatDelta('down', direction: TrendDirection.down),
                    ),
                    StatCard(
                      label: 'Flat',
                      value: '1',
                      delta: StatDelta('flat', direction: TrendDirection.flat),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        for (final icon in tones.values) {
          final glyph = find.byIcon(icon);
          expect(
            contrastRatio(_iconColor(tester, glyph), _backdrop(tester, glyph)),
            greaterThanOrEqualTo(3),
            reason: '$icon on its tile',
          );
        }
        for (final label in ['up', 'down', 'flat']) {
          final text = find.text(label);
          expect(
            contrastRatio(
              tester.widget<Text>(text).style!.color!,
              _backdrop(tester, text),
            ),
            greaterThanOrEqualTo(4.5),
            reason: '"$label" delta',
          );
        }
      });

      testWidgets('the drag-over upload icon reads on the primary', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(palette, const UploadZone(dragOver: true)),
        );
        final icon = find.byIcon(Icons.cloud_upload_outlined);
        expect(_fillsBehind(tester, icon).first, palette.primary);
        expect(
          contrastRatio(_iconColor(tester, icon), palette.primary),
          greaterThanOrEqualTo(3),
        );
      });

      testWidgets('timeline icons read on their tinted nodes', (tester) async {
        const icons = [
          Icons.publish,
          Icons.check,
          Icons.warning_amber,
          Icons.error_outline,
          Icons.info_outline,
        ];
        await tester.pumpWidget(
          _host(
            palette,
            Timeline(
              entries: [
                for (final (i, accent) in [
                  palette.primary,
                  palette.success,
                  palette.warning,
                  palette.danger,
                  palette.info,
                ].indexed)
                  TimelineEntry(
                    title: 'Entry $i',
                    icon: icons[i],
                    color: accent,
                  ),
              ],
            ),
          ),
        );
        for (final glyph in icons) {
          final icon = find.byIcon(glyph);
          final node = _fillsBehind(tester, icon).first;
          for (final surface in [palette.surface, palette.background]) {
            expect(
              contrastRatio(
                _iconColor(tester, icon),
                Color.alphaBlend(node, surface),
              ),
              greaterThanOrEqualTo(3),
            );
          }
        }
      });
    });
  }
}
