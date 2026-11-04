import 'package:admin_ui/src/common/ui/checkbox.dart';
import 'package:admin_ui/src/common/ui/choice.dart';
import 'package:admin_ui/src/common/ui/segmented.dart';
import 'package:admin_ui/src/common/ui/tag.dart';
import 'package:admin_ui/src/common/ui/toggle.dart';
import 'package:admin_ui/src/theme/contrast.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/iris.dart';
import 'package:admin_ui/src/theme/themes/shadcn.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('Toggle and Check flip their value; read-only never fires', (
    tester,
  ) async {
    var toggle = false;
    var check = false;
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Toggle(value: toggle, onChanged: (v) => toggle = v, label: 'T'),
            Check(value: check, onChanged: (v) => check = v, label: 'C'),
            const Toggle(value: false), // read-only
          ],
        ),
      ),
    );

    await tester.tap(find.text('T'));
    await tester.tap(find.text('C'));
    expect(toggle, isTrue);
    expect(check, isTrue);
  });

  testWidgets('Segmented selects on tap, ignores the active segment', (
    tester,
  ) async {
    var value = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Segmented<String>(
            value: value,
            onChanged: (v) => setState(() => value = v),
            segments: const [SegmentOption('a', 'A'), SegmentOption('b', 'B')],
          ),
        ),
      ),
    );

    await tester.tap(find.text('B'));
    await tester.pump();
    expect(value, 'b');
  });

  testWidgets('Tag onRemove fires the ×', (tester) async {
    var removed = false;
    await tester.pumpWidget(_host(Tag('chip', onRemove: () => removed = true)));

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(removed, isTrue);
  });

  testWidgets('hovering an off Toggle darkens its track', (tester) async {
    await tester.pumpWidget(
      _host(Toggle(value: false, onChanged: (_) {}, label: 'T')),
    );
    Color track() =>
        (tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration!
                as BoxDecoration)
            .color!;
    final rest = track();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('T')));
    await tester.pump();
    expect(track(), isNot(rest));
  });

  testWidgets('disabled, a Toggle greys as a Check does; read-only neither', (
    tester,
  ) async {
    final p = defaultTokens.palette;
    Color track() =>
        (tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration!
                as BoxDecoration)
            .color!;
    Color box() =>
        (tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byType(Check),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration)
            .color!;
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Toggle(value: true, label: 'T'),
            Check(value: true, label: 'C'),
          ],
        ),
      ),
    );
    expect(track(), p.foregroundSubtle);
    expect(box(), p.foregroundSubtle);
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Toggle(value: true, readOnly: true, label: 'T'),
            Check(value: true, readOnly: true, label: 'C'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(track(), p.controlAccent);
    expect(box(), p.controlAccent);
  });

  testWidgets('a pinned hover tints an unselected segment', (tester) async {
    final hovered = WidgetStatesController({WidgetState.hovered});
    addTearDown(hovered.dispose);
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'a',
          onChanged: (_) {},
          segments: [
            const SegmentOption('a', 'A'),
            SegmentOption('b', 'B', statesController: hovered),
          ],
        ),
      ),
    );
    Color fill(String label) => tester
        .widget<ColoredBox>(
          find
              .ancestor(of: find.text(label), matching: find.byType(ColoredBox))
              .first,
        )
        .color;
    final colors = AdminTokens.from(palette: irisPalette).palette;
    expect(fill('B'), isNot(fill('A')));
    expect(fill('B'), isNot(colors.surface));
  });

  group('palette roles', () {
    for (final palette in [irisPalette, shadcnDarkPalette]) {
      final mode = palette.brightness.name;
      Widget themed(Widget child) => MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: palette)),
        home: Scaffold(body: Center(child: child)),
      );
      BoxDecoration box(WidgetTester tester, Finder f) =>
          tester.widget<Container>(f).decoration! as BoxDecoration;
      Color borderOf(BoxDecoration d) => (d.border! as Border).top.color;

      testWidgets(
        'Check outlines in controlBorder, the accent on hover ($mode)',
        (tester) async {
          await tester.pumpWidget(
            themed(Check(value: false, onChanged: (_) {}, label: 'Notify')),
          );
          Finder square() => find.byWidgetPredicate(
            (w) => w is Container && w.constraints?.maxWidth == 18,
          );
          expect(borderOf(box(tester, square())), palette.controlBorder);

          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(find.text('Notify')));
          await tester.pump();
          // The accent stands out more than the resting border here.
          expect(borderOf(box(tester, square())), palette.controlAccent);
        },
      );

      testWidgets('checked Check draws an onControlAccent tick ($mode)', (
        tester,
      ) async {
        await tester.pumpWidget(themed(Check(value: true, onChanged: (_) {})));
        expect(
          tester.widget<Icon>(find.byIcon(Icons.check_rounded)).color,
          palette.onControlAccent,
        );
      });

      testWidgets(
        'off Toggle track is controlBorder, knob stands out ($mode)',
        (tester) async {
          await tester.pumpWidget(
            themed(Toggle(value: false, onChanged: (_) {})),
          );
          final track =
              tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as BoxDecoration;
          final knob = box(
            tester,
            find.descendant(
              of: find.byType(AnimatedAlign),
              matching: find.byType(Container),
            ),
          );
          expect(track.color, palette.controlBorder);
          if (palette.brightness == Brightness.light) {
            expect(knob.color, palette.surface);
          } else {
            expect(knob.color, anyOf(palette.surface, palette.foreground));
            expect(
              contrastRatio(knob.color!, track.color!),
              greaterThanOrEqualTo(3),
            );
          }
        },
      );

      testWidgets('radio ring is controlBorder, the accent on hover ($mode)', (
        tester,
      ) async {
        await tester.pumpWidget(
          themed(
            Choice<String>(
              value: 'a',
              onChanged: (_) {},
              options: const [
                ChoiceOption('a', 'Alpha'),
                ChoiceOption('b', 'Beta'),
              ],
            ),
          ),
        );
        Finder ring(String label) => find.descendant(
          of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        expect(borderOf(box(tester, ring('Beta'))), palette.controlBorder);
        expect(borderOf(box(tester, ring('Alpha'))), palette.controlAccent);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Beta')));
        await tester.pump();
        expect(borderOf(box(tester, ring('Beta'))), palette.controlAccent);
      });

      testWidgets('selected segment is primaryText on primarySubtle ($mode)', (
        tester,
      ) async {
        await tester.pumpWidget(
          themed(
            Segmented<String>(
              value: 'a',
              onChanged: (_) {},
              segments: const [
                SegmentOption('a', 'List'),
                SegmentOption('b', 'Grid'),
              ],
            ),
          ),
        );
        expect(
          tester.widget<Text>(find.text('List')).style!.color,
          palette.primaryText,
        );
        final chip = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.text('List'),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(chip.color, palette.primarySubtle);
      });
    }
  });
}
