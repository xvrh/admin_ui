import 'dart:ui' show PointerDeviceKind;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A Toggle, a Check and a Choice's radio drawn from the theme's
// AdminSelectionStyle: their sizes, an outlined off track, a knob that grows,
// a radio marked by a dot, and the foreground or the success colour in place
// of the accent.

Widget _host(
  Widget child, {
  AdminSelectionStyle style = const AdminSelectionStyle(),
  AdminPalette? palette,
  AdminStroke? stroke,
  AdminRadii? radii,
}) => MaterialApp(
  theme: buildAppTheme(
    AdminTokens.from(
      palette: palette ?? irisPalette,
      selection: style,
      stroke: stroke,
      radii: radii,
    ),
  ),
  home: Scaffold(body: Center(child: child)),
);

/// The track of the Toggle keyed [key].
Finder _track(Key key) => find.descendant(
  of: find.byKey(key),
  matching: find.byType(AnimatedContainer),
);

BoxDecoration _trackLook(WidgetTester tester, Key key) =>
    tester.widget<AnimatedContainer>(_track(key)).decoration! as BoxDecoration;

/// The knob of the Toggle keyed [key], as it is painted.
Finder _knob(Key key) => find.descendant(
  of: find.descendant(
    of: find.byKey(key),
    matching: find.byType(AnimatedAlign),
  ),
  matching: find.byType(Container),
);

BoxDecoration _knobLook(WidgetTester tester, Key key) =>
    tester.widget<Container>(_knob(key)).decoration! as BoxDecoration;

/// The box of the Check keyed [key].
Finder _box(Key key) => find.descendant(
  of: find.byKey(key),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.decoration is BoxDecoration,
  ),
);

BoxDecoration _boxLook(WidgetTester tester, Key key) =>
    tester.widget<Container>(_box(key)).decoration! as BoxDecoration;

/// Every radio, in the order the options are laid out.
final _radios = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
      (w.decoration! as BoxDecoration).border != null,
);

BoxDecoration _radioLook(WidgetTester tester, int index) =>
    tester.widget<Container>(_radios.at(index)).decoration! as BoxDecoration;

/// The dot inside the radio at [index], where it draws one: a disc with no
/// border, where the ring's own box has one.
Finder _dot(int index) => find.descendant(
  of: _radios.at(index),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration as BoxDecoration).border == null,
  ),
);

BorderSide _edge(BoxDecoration look) => (look.border! as Border).top;

const _clear = Color(0x00000000);

const _material = AdminSelectionStyle(
  toggleWidth: 52,
  toggleHeight: 32,
  toggleKnob: 16,
  toggleKnobOn: 24,
  toggleOff: ToggleOffStyle.tonal,
  radioSize: 20,
  radioMark: RadioMark.dot,
  radioDot: 10,
  outline: SelectionOutline.secondary,
);

const _fluent = AdminSelectionStyle(
  toggleWidth: 40,
  toggleHeight: 20,
  toggleKnob: 14,
  toggleOff: ToggleOffStyle.outlined,
  checkSize: 16,
  radioSize: 16,
  radioMark: RadioMark.dot,
  radioDot: 10,
);

const _carbon = AdminSelectionStyle(
  toggleWidth: 48,
  toggleHeight: 24,
  toggleKnob: 18,
  toggleOn: ToggleOnColor.success,
  checkSize: 16,
  radioMark: RadioMark.dot,
  radioDot: 8,
  ink: SelectionInk.foreground,
  outline: SelectionOutline.foreground,
);

void main() {
  const off = Key('off');
  const on = Key('on');

  Widget toggles({bool enabled = true}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Toggle(key: off, value: false, onChanged: enabled ? (_) {} : null),
      Toggle(key: on, value: true, onChanged: enabled ? (_) {} : null),
    ],
  );

  group('a Toggle', () {
    for (final (name, style) in [
      ('the default', const AdminSelectionStyle()),
      ('M3', _material),
      ('Fluent', _fluent),
      ('Carbon', _carbon),
    ]) {
      testWidgets('$name: the track and the knob are the style’s', (
        tester,
      ) async {
        await tester.pumpWidget(_host(toggles(), style: style));
        await tester.pumpAndSettle();
        for (final key in [off, on]) {
          expect(
            tester.getSize(_track(key)),
            Size(style.toggleWidth, style.toggleHeight),
          );
          expect(
            (_trackLook(tester, key).borderRadius! as BorderRadius).topLeft.x,
            style.toggleHeight / 2,
            reason: 'a pill at every height',
          );
        }
        final offKnob = tester.getRect(_knob(off));
        final onKnob = tester.getRect(_knob(on));
        expect(offKnob.size, Size.square(style.toggleKnob));
        expect(
          onKnob.size,
          Size.square(style.toggleKnobOn ?? style.toggleKnob),
        );
        // Both knobs sit on the track's centre line, and travel between the
        // same two margins: the larger knob's.
        final offTrack = tester.getRect(_track(off));
        final onTrack = tester.getRect(_track(on));
        expect(offKnob.center.dy, offTrack.center.dy);
        expect(onKnob.center.dy, onTrack.center.dy);
        final margin = (style.toggleHeight - style.toggleKnobSlot) / 2;
        final slack = (style.toggleKnobSlot - style.toggleKnob) / 2;
        expect(offKnob.left - offTrack.left, margin + slack);
        expect(
          onTrack.right - onKnob.right,
          margin +
              (style.toggleKnobSlot -
                      (style.toggleKnobOn ?? style.toggleKnob)) /
                  2,
        );
      });
    }

    testWidgets('filled: a controlBorder track under a lifted surface knob', (
      tester,
    ) async {
      final p = irisPalette;
      await tester.pumpWidget(_host(toggles()));
      await tester.pumpAndSettle();
      expect(_trackLook(tester, off).color, p.controlBorder);
      expect(_trackLook(tester, off).border, isNull);
      expect(_knobLook(tester, off).color, p.surface);
      expect(_knobLook(tester, off).boxShadow, isNotEmpty);
      expect(_trackLook(tester, on).color, p.controlAccent);
      expect(_knobLook(tester, on).color, p.onControlAccent);
    });

    testWidgets('outlined: a clear track ringed in controlBorder, around a '
        'flat knob in the same colour', (tester) async {
      final p = irisPalette;
      await tester.pumpWidget(
        _host(
          toggles(),
          style: _fluent,
          stroke: const AdminStroke(controlStrong: 1),
        ),
      );
      await tester.pumpAndSettle();
      final track = _trackLook(tester, off);
      expect(track.color, _clear);
      expect(_edge(track).color, p.controlBorder);
      expect(_edge(track).width, 1);
      expect(_knobLook(tester, off).color, p.controlBorder);
      expect(_knobLook(tester, off).boxShadow, isNull);

      // On, the ring keeps its width in the track's own colour, so the knob's
      // margins hold.
      final lit = _trackLook(tester, on);
      expect(lit.color, p.controlAccent);
      expect(_edge(lit).color, p.controlAccent);
      expect(_edge(lit).width, 1);
      expect(_knobLook(tester, on).color, p.onControlAccent);
      expect(_knobLook(tester, on).boxShadow, isNull);
    });

    testWidgets('outlined: the ring is as wide as the strong control stroke', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          toggles(),
          style: _material,
          stroke: const AdminStroke(controlStrong: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(_edge(_trackLook(tester, off)).width, 2);
      // whatever the ring's width, the knob keeps its place
      expect(
        tester.getRect(_knob(off)).left - tester.getRect(_track(off)).left,
        8,
      );
    });

    testWidgets('outlined: a ring wider than the knob’s margin still lays '
        'out', (tester) async {
      // an 18px track around a 16px knob leaves a 1px margin for a 2px ring
      await tester.pumpWidget(
        _host(
          toggles(),
          style: const AdminSelectionStyle(
            toggleWidth: 32,
            toggleHeight: 18,
            toggleKnob: 16,
            toggleOff: ToggleOffStyle.outlined,
          ),
          stroke: const AdminStroke(controlStrong: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_track(off)), const Size(32, 18));
      expect(tester.getRect(_knob(off)).height, lessThanOrEqualTo(14));
    });

    testWidgets('tonal: the outlined track over a wash of the foreground', (
      tester,
    ) async {
      final p = materialPalette;
      await tester.pumpWidget(_host(toggles(), style: _material, palette: p));
      await tester.pumpAndSettle();
      final track = _trackLook(tester, off);
      expect(track.color, Color.alphaBlend(p.pressedOverlay, p.surface));
      expect(_edge(track).color, p.controlBorder);
      expect(_knobLook(tester, off).color, p.controlBorder);
    });

    testWidgets('an outlined off track deepens under the pointer, ring and '
        'knob together', (tester) async {
      final p = irisPalette;
      final hovered = WidgetStatesController({WidgetState.hovered});
      addTearDown(hovered.dispose);
      await tester.pumpWidget(
        _host(
          Toggle(
            key: off,
            value: false,
            onChanged: (_) {},
            statesController: hovered,
          ),
          style: _fluent,
        ),
      );
      await tester.pumpAndSettle();
      final deep = Color.alphaBlend(p.pressedOverlay, p.controlBorder);
      expect(_edge(_trackLook(tester, off)).color, deep);
      expect(_knobLook(tester, off).color, deep);
      expect(_trackLook(tester, off).color, _clear);
    });

    testWidgets('disabled, an outlined track greys: faint off, solid on', (
      tester,
    ) async {
      final p = irisPalette;
      await tester.pumpWidget(_host(toggles(enabled: false), style: _material));
      await tester.pumpAndSettle();
      final track = _trackLook(tester, off);
      expect(track.color, _clear, reason: 'no wash while disabled');
      expect(_edge(track).color, p.foregroundFaint);
      expect(_knobLook(tester, off).color, p.foregroundFaint);
      expect(_trackLook(tester, on).color, p.foregroundSubtle);
      expect(_knobLook(tester, on).color, p.surface);
    });

    testWidgets('success: the on track is the success colour under every '
        'brand, its knob the surface colour', (tester) async {
      for (final palette in [
        carbonPalette,
        carbonPalette.branded(const Color(0xFFD97706)),
      ]) {
        await tester.pumpWidget(
          _host(toggles(), style: _carbon, palette: palette),
        );
        await tester.pumpAndSettle();
        expect(_trackLook(tester, on).color, const Color(0xFF24A148));
        expect(_knobLook(tester, on).color, palette.surface);
        expect(_trackLook(tester, off).color, palette.controlBorder);
      }
    });

    testWidgets('flipping it grows the knob where the style says so', (
      tester,
    ) async {
      var value = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Toggle(
              key: off,
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          style: _material,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(_knob(off)).size, const Size.square(16));
      await tester.tap(find.byKey(off));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(tester.getRect(_knob(off)).size, const Size.square(24));
    });
  });

  group('a Check', () {
    const box = Key('box');

    testWidgets('its box is the style’s size, at the check corner', (
      tester,
    ) async {
      for (final (size, corner) in [(18.0, 4.0), (16.0, 2.0)]) {
        await tester.pumpWidget(
          _host(
            Check(key: box, value: false, onChanged: (_) {}),
            style: AdminSelectionStyle(checkSize: size),
            radii: defaultRadii.copyWith(radiusCheck: corner),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(_box(box)), Size.square(size));
        expect(
          (_boxLook(tester, box).borderRadius! as BorderRadius).topLeft.x,
          corner,
        );
      }
    });

    testWidgets('its glyph keeps a pixel clear of a small box', (tester) async {
      for (final (size, glyph) in [(18.0, 14.0), (16.0, 14.0), (12.0, 10.0)]) {
        await tester.pumpWidget(
          _host(
            Check(key: box, value: true, onChanged: (_) {}),
            style: AdminSelectionStyle(checkSize: size),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Icon>(find.byIcon(Icons.check_rounded)).size,
          glyph,
          reason: 'in a $size box',
        );
      }
    });

    testWidgets('off, it is ringed in the style’s outline, the strong control '
        'stroke wide', (tester) async {
      final p = irisPalette;
      for (final (outline, color) in [
        (SelectionOutline.control, p.controlBorder),
        (SelectionOutline.secondary, p.foregroundSecondary),
        (SelectionOutline.foreground, p.foreground),
      ]) {
        await tester.pumpWidget(
          _host(
            Check(key: box, value: false, onChanged: (_) {}),
            style: AdminSelectionStyle(outline: outline),
            stroke: const AdminStroke(controlStrong: 1),
          ),
        );
        await tester.pumpAndSettle();
        final look = _boxLook(tester, box);
        expect(_edge(look).color, color, reason: outline.name);
        expect(_edge(look).width, 1);
        expect(look.color, _clear);
      }
    });

    testWidgets('under the pointer, an off box takes the style’s hover '
        'outline', (tester) async {
      final p = irisPalette;
      final hovered = WidgetStatesController({WidgetState.hovered});
      addTearDown(hovered.dispose);
      for (final style in [const AdminSelectionStyle(), _material, _carbon]) {
        await tester.pumpWidget(
          _host(
            Check(
              key: box,
              value: false,
              onChanged: (_) {},
              statesController: hovered,
            ),
            style: style,
          ),
        );
        await tester.pumpAndSettle();
        expect(_edge(_boxLook(tester, box)).color, style.hoverOutlineOf(p));
      }
    });

    testWidgets('on, it is filled in the style’s ink under its on-colour', (
      tester,
    ) async {
      final p = carbonPalette;
      await tester.pumpWidget(
        _host(
          Check(key: box, value: true, onChanged: (_) {}),
          style: _carbon,
          palette: p,
        ),
      );
      await tester.pumpAndSettle();
      expect(_boxLook(tester, box).color, p.foreground);
      final glyph = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
      expect(glyph.color, const Color(0xFFFFFFFF));
      expect(contrastRatio(glyph.color!, p.foreground), greaterThan(4.5));

      // the accent is left to the tabs and the slider
      expect(_boxLook(tester, box).color, isNot(p.controlAccent));
    });

    testWidgets('disabled, it greys whatever the ink', (tester) async {
      final p = carbonPalette;
      await tester.pumpWidget(
        _host(
          const Check(key: box, value: true),
          style: _carbon,
          palette: p,
        ),
      );
      await tester.pumpAndSettle();
      expect(_boxLook(tester, box).color, p.foregroundSubtle);
    });
  });

  group('a radio', () {
    Widget choice({String? value = 'a', bool enabled = true}) => Choice<String>(
      value: value,
      onChanged: enabled ? (_) {} : null,
      options: const [ChoiceOption('a', 'Alpha'), ChoiceOption('b', 'Beta')],
    );

    testWidgets('disc: a ring as thick as leaves the dot showing, around the '
        'ink’s on-colour', (tester) async {
      final p = irisPalette;
      for (final (size, dot) in [(18.0, 8.0), (16.0, 6.0), (16.0, 8.0)]) {
        await tester.pumpWidget(
          _host(
            choice(),
            style: AdminSelectionStyle(radioSize: size, radioDot: dot),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(_radios.at(0)), Size.square(size));
        final selected = _radioLook(tester, 0);
        expect(_edge(selected).width, (size - dot) / 2);
        expect(_edge(selected).color, p.controlAccent);
        expect(selected.color, p.onControlAccent);
        expect(_dot(0), findsNothing);

        final rest = _radioLook(tester, 1);
        expect(_edge(rest).width, 1.5);
        expect(_edge(rest).color, p.controlBorder);
        expect(rest.color, p.surface);
      }
    });

    testWidgets('dot: the ring, in the ink, around a dot in the ink', (
      tester,
    ) async {
      final p = irisPalette;
      await tester.pumpWidget(
        _host(
          choice(),
          style: _material,
          stroke: const AdminStroke(controlStrong: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(_radios.at(0)), const Size.square(20));
      final selected = _radioLook(tester, 0);
      expect(_edge(selected).width, 2);
      expect(_edge(selected).color, p.controlAccent);
      expect(selected.color, p.surface);
      expect(tester.getSize(_dot(0)), const Size.square(10));
      expect(
        (tester.widget<DecoratedBox>(_dot(0)).decoration as BoxDecoration)
            .color,
        p.controlAccent,
      );
      expect(
        tester.getCenter(_dot(0)),
        tester.getCenter(_radios.at(0)),
        reason: 'the dot is centred in its ring',
      );

      final rest = _radioLook(tester, 1);
      expect(_edge(rest).width, 2);
      expect(_edge(rest).color, p.foregroundSecondary);
      expect(_dot(1), findsNothing);
    });

    testWidgets('dot, in the foreground: Carbon’s radio button', (
      tester,
    ) async {
      final p = carbonPalette;
      await tester.pumpWidget(
        _host(
          choice(),
          style: _carbon,
          palette: p,
          stroke: const AdminStroke(controlStrong: 1),
        ),
      );
      await tester.pumpAndSettle();
      final selected = _radioLook(tester, 0);
      expect(_edge(selected).color, p.foreground);
      expect(_edge(selected).width, 1);
      expect(tester.getSize(_dot(0)), const Size.square(8));
      expect(
        (tester.widget<DecoratedBox>(_dot(0)).decoration as BoxDecoration)
            .color,
        p.foreground,
      );
      expect(_edge(_radioLook(tester, 1)).color, p.foreground);
    });

    testWidgets('disabled, a selected dot greys with its ring', (tester) async {
      final p = irisPalette;
      await tester.pumpWidget(_host(choice(enabled: false), style: _fluent));
      await tester.pumpAndSettle();
      expect(_edge(_radioLook(tester, 0)).color, p.foregroundSubtle);
      expect(
        (tester.widget<DecoratedBox>(_dot(0)).decoration as BoxDecoration)
            .color,
        p.foregroundSubtle,
      );
      expect(_edge(_radioLook(tester, 1)).color, p.foregroundFaint);
    });

    testWidgets('the pointer over an unselected radio rings it in the hover '
        'outline', (tester) async {
      final p = irisPalette;
      await tester.pumpWidget(_host(choice(), style: _material));
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Beta')));
      await tester.pump();
      expect(_edge(_radioLook(tester, 1)).color, _material.hoverOutlineOf(p));
    });
  });

  group('every shipped theme', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        testWidgets('${theme.name} $mode draws all three at its sizes', (
          tester,
        ) async {
          const box = Key('box');
          final style = tokens.selection;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(tokens),
              home: Scaffold(
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Toggle(key: off, value: false, onChanged: (_) {}),
                    Toggle(key: on, value: true, onChanged: (_) {}),
                    Check(key: box, value: true, onChanged: (_) {}),
                    Choice<String>(
                      value: 'a',
                      onChanged: (_) {},
                      options: const [
                        ChoiceOption('a', 'Alpha'),
                        ChoiceOption('b', 'Beta'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(_track(on)),
            Size(style.toggleWidth, style.toggleHeight),
          );
          expect(tester.getSize(_box(box)), Size.square(style.checkSize));
          expect(tester.getSize(_radios.at(0)), Size.square(style.radioSize));
          expect(
            _trackLook(tester, on).color,
            style.toggleOnOf(tokens.palette),
          );
          expect(_boxLook(tester, box).color, style.inkOf(tokens.palette));
          expect(
            (_boxLook(tester, box).borderRadius! as BorderRadius).topLeft.x,
            tokens.radii.radiusCheck,
          );
        });
      }
    }
  });
}
