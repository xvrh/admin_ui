import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// The catalog's Amber brand accent.
const _amber = Color(0xFFD97706);

void main() {
  final themes = {
    for (final MapEntry(:key, :value) in shippedPalettes.entries) ...{
      key: value,
      '$key + Amber': value.branded(_amber),
    },
  };

  for (final MapEntry(key: name, value: palette) in themes.entries) {
    group(name, () {
      Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: palette)),
          home: Scaffold(body: Center(child: child)),
        ),
      );

      /// The fill a control paints, composited over the page when translucent.
      Color opaque(Color fill) => Color.alphaBlend(fill, palette.background);

      void expectContrast(
        Color foreground,
        Color fill,
        double min,
        String what,
      ) {
        final ratio = contrastRatio(foreground, opaque(fill));
        expect(
          ratio,
          greaterThanOrEqualTo(min),
          reason:
              '$what: ${_hex(foreground)} on ${_hex(opaque(fill))} is '
              '${ratio.toStringAsFixed(2)}:1',
        );
      }

      Color textColor(WidgetTester tester, String text) =>
          tester.widget<Text>(find.text(text)).style!.color!;

      Color boxFill(WidgetTester tester, Finder box) =>
          ((tester.widget<Container>(box).decoration!) as BoxDecoration).color!;

      /// The nearest [Container] around [of] that paints a fill.
      Finder filledAround(Finder of) => find
          .ancestor(
            of: of,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).color != null &&
                  (w.decoration! as BoxDecoration).color!.a > 0,
            ),
          )
          .first;

      for (final (label, button) in [
        ('Save', const Button.primary('Save', onPressed: _noop)),
        ('Delete', const Button.danger('Delete', onPressed: _noop)),
      ]) {
        testWidgets('Button "$label" text reads on its fill', (tester) async {
          await pump(tester, button);
          final fill = tester
              .widget<Material>(
                find
                    .ancestor(
                      of: find.text(label),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .color!;
          expectContrast(textColor(tester, label), fill, 4.5, label);
        });
      }

      testWidgets('checked Check tick reads on its fill', (tester) async {
        await pump(tester, Check(value: true, onChanged: (_) {}));
        final icon = find.byIcon(Icons.check_rounded);
        expectContrast(
          tester.widget<Icon>(icon).color!,
          boxFill(tester, filledAround(icon)),
          3,
          'tick',
        );
      });

      for (final on in [true, false]) {
        testWidgets(
          '${on ? 'on' : 'off'} Toggle knob stands out on its track',
          (tester) async {
            await pump(tester, Toggle(value: on, onChanged: (_) {}));
            final track = tester.widget<AnimatedContainer>(
              find.byType(AnimatedContainer),
            );
            final knob = tester.widget<Container>(
              find.descendant(
                of: find.byType(AnimatedAlign),
                matching: find.byType(Container),
              ),
            );
            expectContrast(
              (knob.decoration! as BoxDecoration).color!,
              (track.decoration! as BoxDecoration).color!,
              3,
              'knob',
            );
          },
        );
      }

      testWidgets('solid warning Tag text reads on the warning', (
        tester,
      ) async {
        await pump(
          tester,
          Tag('Held', color: palette.warning, variant: TagVariant.solid),
        );
        final text = find.text('Held');
        expectContrast(
          textColor(tester, 'Held'),
          boxFill(tester, filledAround(text)),
          4.5,
          'solid warning tag',
        );
      });

      testWidgets('soft Tags read on their tint and on the page', (
        tester,
      ) async {
        await pump(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Tag('Info', severity: Severity.info),
              const Tag('Warn', severity: Severity.warning, dot: true),
              Tag('Custom', color: palette.warning),
              Tag('Brand', color: palette.primary),
            ],
          ),
        );
        for (final label in ['Info', 'Warn', 'Custom', 'Brand']) {
          final fg = textColor(tester, label);
          expectContrast(
            fg,
            boxFill(tester, filledAround(find.text(label))),
            4.5,
            'soft "$label" on its tint',
          );
          expectContrast(fg, palette.surface, 4.5, 'soft "$label" on surface');
        }
      });

      testWidgets('warning CountBadge digits read on the warning', (
        tester,
      ) async {
        await pump(tester, CountBadge(count: 7, color: palette.warning));
        final text = find.text('7');
        expectContrast(
          textColor(tester, '7'),
          boxFill(tester, filledAround(text)),
          4.5,
          'warning badge',
        );
      });

      testWidgets('default CountBadge digits read on the danger red', (
        tester,
      ) async {
        await pump(tester, const CountBadge(count: 12));
        expectContrast(
          textColor(tester, '12'),
          boxFill(tester, filledAround(find.text('12'))),
          4.5,
          'danger badge',
        );
      });

      testWidgets('Avatar initials read on every auto colour', (tester) async {
        // Single letters A–N land on every slot of the auto palette.
        final letters = [for (var c = 65; c < 79; c++) String.fromCharCode(c)];
        await pump(
          tester,
          Wrap(children: [for (final l in letters) Avatar(initials: l)]),
        );
        for (final l in letters) {
          final fill = tester
              .widget<ColoredBox>(
                find
                    .ancestor(
                      of: find.text(l),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color;
          expectContrast(textColor(tester, l), fill, 4.5, 'avatar $l');
        }
      });
    });
  }
}

void _noop() {}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
