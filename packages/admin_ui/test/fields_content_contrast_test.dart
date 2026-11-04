import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/fields/ui/color_body.dart' show parseHexColor;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// The catalog's Brand accents: dark mode plus a brand is where the soft
/// selection tints are most at risk of washing out.
const _brands = {
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

/// One token of every kind the JSON highlighter colours.
const _json = '{"key": "text", "n": 14.5, "on": true, "off": null}';

void main() {
  for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
    group(name, () {
      Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: palette)),
          home: Scaffold(
            body: Center(child: SizedBox(width: 480, child: child)),
          ),
        ),
      );

      testWidgets('status pill labels read on their tint', (tester) async {
        await pump(
          tester,
          Builder(
            builder: (context) => Wrap(
              children: [
                for (final meta in localeStatusMeta(context).values)
                  StatusPill(meta),
                for (final tone in Severity.values)
                  StatusPill(
                    StatusMeta(
                      tone.name,
                      severityStyleOf(context, tone).accent,
                      text: severityStyleOf(context, tone).foreground,
                    ),
                  ),
                StatusPill(StatusMeta('Custom', context.colors.warning)),
              ],
            ),
          ),
        );
        final pills = find.byType(StatusPill);
        expect(pills, findsNWidgets(10));
        for (final pill in pills.evaluate()) {
          final meta = (pill.widget as StatusPill).meta;
          final box = find.descendant(
            of: find.byWidget(pill.widget),
            matching: find.byType(Container),
          );
          final fill =
              ((tester.widget<Container>(box.first).decoration!
                      as BoxDecoration)
                  .color)!;
          final label = tester.widget<Text>(
            find.descendant(
              of: find.byWidget(pill.widget),
              matching: find.text(meta.label),
            ),
          );
          expect(
            contrastRatio(label.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: meta.label,
          );
        }
      });

      for (final swatch in const ['#FFFFFF', '#000000']) {
        testWidgets('the selected-swatch check reads on $swatch', (
          tester,
        ) async {
          await pump(
            tester,
            ColorBody(
              value: swatch,
              palette: const ['#FFFFFF', '#000000'],
              onChanged: (_) {},
            ),
          );
          await tester.tap(find.text(swatch));
          await tester.pumpAndSettle();

          final check = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
          expect(
            contrastRatio(check.color!, parseHexColor(swatch)!),
            greaterThanOrEqualTo(3),
          );
        });
      }

      testWidgets('a field error caption reads on the page and a card', (
        tester,
      ) async {
        await pump(tester, const FieldErrorText('Required'));
        final color = tester.widget<Text>(find.text('Required')).style!.color!;
        expect(
          contrastRatio(color, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(color, palette.background),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('field labels read on the page and a card', (tester) async {
        await pump(
          tester,
          const FieldShell(label: 'Title', child: SizedBox(height: 20)),
        );
        final color = tester.widget<Text>(find.text('TITLE')).style!.color!;
        expect(
          contrastRatio(color, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(color, palette.background),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('an inherited preview recedes but still reads', (
        tester,
      ) async {
        await pump(
          tester,
          const InheritedBody(
            inheriting: true,
            preview: TextBody(value: 'Source text'),
            custom: SizedBox(),
          ),
        );
        expect(find.byType(Opacity), findsNothing);
        final field = tester.widget<TextField>(find.byType(TextField));
        final text = field.style!.color!;
        expect(text, isNot(palette.foreground), reason: 'quieter than an edit');
        for (final surface in [
          palette.surface,
          palette.background,
          if (field.decoration!.filled ?? false) field.decoration!.fillColor!,
        ]) {
          expect(contrastRatio(text, surface), greaterThanOrEqualTo(4.5));
        }

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(InheritedBody),
            matching: find.byWidgetPredicate(
              (w) => w is EditableText && w.focusNode.hasFocus,
            ),
          ),
          findsNothing,
          reason: 'the preview is inert',
        );
      });

      testWidgets('code syntax colours read on the editor surface', (
        tester,
      ) async {
        await pump(tester, const CodeBody(value: _json));
        final surface =
            (tester
                        .widget<Container>(
                          find
                              .descendant(
                                of: find.byType(CodeBody),
                                matching: find.byType(Container),
                              )
                              .first,
                        )
                        .decoration!
                    as BoxDecoration)
                .color!;
        expect(surface, palette.background);

        final field = tester.widget<TextField>(find.byType(TextField));
        final span = field.controller!.buildTextSpan(
          context: tester.element(find.byType(TextField)),
          withComposing: false,
        );
        final colors = <Color>{
          for (final child in span.children!) ?(child as TextSpan).style?.color,
        };
        // key, string, number, literal, punctuation
        expect(colors.length, greaterThanOrEqualTo(5));
        for (final c in colors) {
          expect(contrastRatio(c, surface), greaterThanOrEqualTo(4.5));
        }
      });

      testWidgets('the comment count reads on what it sits on', (tester) async {
        await pump(tester, const CommentsButton(count: 3));
        final box = tester.widget<Container>(
          find
              .ancestor(of: find.text('3'), matching: find.byType(Container))
              .first,
        );
        // At rest the count sits straight on the label row's surface.
        final fill =
            (box.decoration as BoxDecoration?)?.color ?? palette.surface;
        final text = tester.widget<Text>(find.text('3')).style!.color!;
        expect(contrastRatio(text, fill), greaterThanOrEqualTo(4.5));
      });
    });
  }

  group('selected surfaces under a brand', () {
    for (final MapEntry(key: name, value: base) in shippedPalettes.entries) {
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        final c = base.branded(seed);
        test(
          '$name + $brand: primary text and foreground on the soft tints',
          () {
            // Selected option rows, the open language pill, the fill chip.
            expect(
              contrastRatio(c.primaryText, c.primaryFaint),
              greaterThanOrEqualTo(4.5),
              reason: 'primaryText on primaryFaint',
            );
            // The work bar's target tag.
            expect(
              contrastRatio(c.primaryText, c.primarySubtle),
              greaterThanOrEqualTo(4.5),
              reason: 'primaryText on primarySubtle',
            );
            expect(
              contrastRatio(c.foreground, c.primarySubtle),
              greaterThanOrEqualTo(4.5),
              reason: 'foreground on primarySubtle',
            );
          },
        );

        testWidgets('$name + $brand: the selected block reads', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(AdminTokens.from(palette: c)),
              home: Scaffold(
                body: Center(
                  child: InsertPicker(
                    entries: const [
                      InsertPickerEntry(
                        id: 'hero',
                        label: 'Hero',
                        description: 'Big banner',
                        icon: Icons.image,
                      ),
                    ],
                    onSelect: (_) {},
                  ),
                ),
              ),
            ),
          );
          final row = tester.widget<Container>(
            find
                .ancestor(
                  of: find.text('Hero'),
                  matching: find.byType(Container),
                )
                .first,
          );
          final fill = (row.decoration! as BoxDecoration).color!;
          expect(fill, c.primarySubtle);
          for (final text in ['Hero', 'Big banner']) {
            final style = tester.widget<Text>(find.text(text)).style!;
            final color =
                style.color ??
                DefaultTextStyle.of(tester.element(find.text(text)))
                    .style
                    .color!;
            expect(
              contrastRatio(color, fill),
              greaterThanOrEqualTo(4.5),
              reason: text,
            );
          }
        });
      }
    }
  });
}
