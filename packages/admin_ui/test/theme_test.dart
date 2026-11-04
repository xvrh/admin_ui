import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);
const _nearBlack = Color(0xFF18181B);

/// The client accents the catalog's Brand control offers.
const _demoSeeds = [
  Color(0xFFE11D48),
  Color(0xFF7C3AED),
  Color(0xFF0D9488),
  Color(0xFFD97706),
];

void main() {
  final palettes = shippedPalettes;
  final themed = {
    for (final (i, MapEntry(:key, :value)) in palettes.entries.indexed)
      key: AdminTokens.from(
        palette: value,
        radii: AdminRadii(radiusSmall: i / 2, radius: i + 2.0, radiusLarge: 12),
      ),
  };
  final random = math.Random(20260927);
  final seeds = [
    ..._demoSeeds,
    for (var i = 0; i < 50; i++) Color(0xFF000000 | random.nextInt(0x1000000)),
  ];

  testWidgets('weighted re-applies a resolved font for the new weight', (
    tester,
  ) async {
    // A resolver that names a family per weight, as Google Fonts does.
    AdminFonts.resolver = (family, style) => style.copyWith(
      fontFamily: '${family}_${style.fontWeight?.value ?? 400}',
    );
    addTearDown(() => AdminFonts.resolver = null);
    final type = AdminTypography.from(
      irisPalette,
      const AdminTypeSpec(fontFamily: 'Roboto'),
    );
    expect(type.fieldMessage.fontFamily, isNot(type.caption.fontFamily));
    final message = type.weighted(type.fieldMessage, type.caption.fontWeight!);
    expect(message.fontFamily, type.caption.fontFamily);
    expect(message.fontWeight, type.caption.fontWeight);
    expect(message.fontSize, type.fieldMessage.fontSize);
    expect(message.height, type.fieldMessage.height);
    final copied = type.fieldMessage.copyWith(
      fontWeight: type.caption.fontWeight,
    );
    expect(copied.fontFamily, type.fieldMessage.fontFamily);
  });

  test(
    'FieldOutlineBorder equality follows its states, not the resting side',
    () {
      const p = irisPalette;
      FieldOutlineBorder border({bool invalid = false, Color? ring}) =>
          FieldOutlineBorder(
            side: (states) => fieldBorderSide(
              ring == null ? p : p.copyWith(focusRing: ring),
              {...states, if (invalid) WidgetState.error},
              stroke: const AdminStroke(),
            ),
          );
      expect(border(), border());
      expect(border().hashCode, border().hashCode);
      expect(border(), isNot(border(invalid: true)));
      // Same resting outline, another focus ring.
      final accent = border(ring: const Color(0xFF0D9488));
      expect(accent.borderSide, border().borderSide);
      expect(accent, isNot(border()));
    },
  );

  group('contrastRatio', () {
    for (final (fg, bg, ratio) in const [
      (_black, _white, 21.0),
      (_white, _white, 1.0),
      (Color(0xFF767676), _white, 4.54),
      (Color(0xFF777777), _white, 4.48),
      (Color(0xFF595959), _white, 7.0),
      (Color(0xFFFF0000), _white, 4.0),
      (Color(0xFF0000FF), _white, 8.59),
      (Color(0xFFFFFF00), _black, 19.56),
    ]) {
      test('${_hex(fg)} on ${_hex(bg)} is $ratio', () {
        expect(contrastRatio(fg, bg), closeTo(ratio, 0.01));
        expect(contrastRatio(bg, fg), contrastRatio(fg, bg));
      });
    }

    test('composites a translucent foreground over the background', () {
      final veil = _black.withValues(alpha: 0.5);
      expect(
        contrastRatio(veil, _white),
        contrastRatio(Color.alphaBlend(veil, _white), _white),
      );
      expect(contrastRatio(_white.withValues(alpha: 0), _black), 1);
    });

    test('takes the background as opaque', () {
      expect(contrastRatio(_black, _white.withValues(alpha: 0)), 21);
    });

    test('relativeLuminance follows WCAG 2.x', () {
      expect(relativeLuminance(_black), 0);
      expect(relativeLuminance(_white), 1);
      expect(relativeLuminance(const Color(0xFF808080)), closeTo(0.2159, 1e-4));
    });
  });

  group('foregroundOn', () {
    final palette = palettes.values.first;
    for (final (fill, expected) in const [
      (_white, _nearBlack),
      (_black, _white),
      (Color(0xFFFAFAFA), _nearBlack),
      (Color(0xFF8B8BF0), _nearBlack),
      (Color(0xFF5B5BD6), _white),
      (Color(0xFFD97706), _nearBlack),
      (Color(0xFFE11D48), _white),
    ]) {
      test('on ${_hex(fill)} is ${_hex(expected)}', () {
        expect(palette.foregroundOn(fill), expected);
      });
    }

    test('picks whichever candidate has the higher ratio', () {
      for (final fill in seeds) {
        final chosen = palette.foregroundOn(fill);
        final other = chosen == _white ? _nearBlack : _white;
        expect(
          contrastRatio(chosen, fill),
          greaterThanOrEqualTo(contrastRatio(other, fill)),
          reason: _hex(fill),
        );
      }
    });
  });

  group('readableOn', () {
    test('returns an accent that already passes unchanged', () {
      final iris = palettes['Iris Light']!;
      expect(iris.readableOn(iris.primary), iris.primary);
    });

    test('reaches the target on every surface, keeping the hue', () {
      for (final MapEntry(key: name, value: p) in palettes.entries) {
        for (final accent in seeds) {
          for (final min in const [3.0, 4.5]) {
            final surfaces = [p.surface, p.background];
            final readable = p.readableOn(accent, minContrast: min);
            for (final surface in surfaces) {
              expect(
                contrastRatio(readable, surface),
                greaterThanOrEqualTo(min),
                reason: '$name ${_hex(accent)} → ${_hex(readable)}',
              );
            }
            final from = HSLColor.fromColor(accent);
            final to = HSLColor.fromColor(readable);
            if (from.saturation > 0.1 &&
                to.lightness > 0.15 &&
                to.lightness < 0.9) {
              expect(
                _hueGap(from.hue, to.hue),
                lessThan(3),
                reason: '$name ${_hex(accent)} → ${_hex(readable)}',
              );
            }
          }
        }
      }
    });

    test('caches its answers, for explicit surfaces too', () {
      final p = palettes['Iris Light']!;
      const accent = Color(0xFFB0B0F0);
      final surfaces = [p.surface, p.statusFill(p.danger)];
      final first = p.readableOn(accent, surfaces: surfaces);
      expect(first, isNot(accent));
      expect(
        identical(p.readableOn(accent, surfaces: [...surfaces]), first),
        isTrue,
      );
      surfaces.add(_black);
      expect(
        p.readableOn(accent, surfaces: [p.surface, p.statusFill(p.danger)]),
        first,
        reason: 'mutating the caller\'s list does not touch the cache',
      );
    });

    test('moves toward whichever extreme contrasts with the surfaces', () {
      final p = palettes['Iris Light']!;
      const accent = Color(0xFF9090F0);
      final onLight = p.readableOn(accent, surfaces: const [_white]);
      final onDark = p.readableOn(accent, surfaces: const [Color(0xFF7070A0)]);
      expect(relativeLuminance(onLight), lessThan(relativeLuminance(accent)));
      expect(relativeLuminance(onDark), greaterThan(relativeLuminance(accent)));
    });
  });

  group('derived roles', () {
    for (final MapEntry(key: name, value: shipped) in palettes.entries) {
      // Only the base colours, so every optional role takes its derived value.
      final p = _baseOf(shipped);

      test('$name: on-fill colours are the higher-contrast candidate', () {
        expect(p.onPrimary, p.foregroundOn(p.primary));
        expect(p.onDanger, p.foregroundOn(p.danger));
        expect(p.onSuccess, p.foregroundOn(p.success));
        expect(p.onWarning, p.foregroundOn(p.warning));
        expect(p.onInfo, p.foregroundOn(p.info));
      });

      test('$name: text-safe accents reach 4.5:1 on their surfaces', () {
        _expectAtLeast(p.primaryText, [
          p.surface,
          p.background,
          p.primarySubtle,
        ], 4.5);
        for (final (accent, text) in [
          (p.danger, p.dangerText),
          (p.success, p.successText),
          (p.info, p.infoText),
        ]) {
          _expectAtLeast(text, [
            p.surface,
            p.background,
            p.statusFill(accent),
          ], 4.5);
        }
      });

      test('$name: control chrome reaches its WCAG target', () {
        expect(p.focusRing.a, 1);
        _expectAtLeast(p.focusRing, [p.surface, p.background], 3);
        _expectAtLeast(p.controlBorder, [p.surface, p.background], 3);
        _expectAtLeast(p.controlAccent, [p.surface, p.background], 3);
        _expectAtLeast(p.onControlAccent, [
          p.controlAccent,
          p.controlAccentHover,
        ], 3);
        _expectAtLeast(p.placeholder, [p.surface], 4.5);
        _expectAtLeast(p.foregroundMutedOnTint, _tints(p), 4.5);
      });

      test('$name: fill states keep their content legible', () {
        for (final (fill, on, states) in [
          (p.primary, p.onPrimary, [p.primaryHover, p.primaryActive]),
          (p.danger, p.onDanger, [p.dangerHover, p.dangerActive]),
        ]) {
          final floor = math.min(4.5, contrastRatio(on, fill));
          for (final state in states) {
            expect(state, isNot(fill));
            expect(
              contrastRatio(on, state),
              greaterThanOrEqualTo(floor - 0.01),
              reason: '${_hex(on)} on ${_hex(state)}',
            );
          }
        }
      });

      test('$name: hover and pressed step a fill one way, gently under dark '
          'content', () {
        double lum(Color c) => relativeLuminance(c);
        for (final (fill, on, hover, active) in [
          (p.primary, p.onPrimary, p.primaryHover, p.primaryActive),
          (p.danger, p.onDanger, p.dangerHover, p.dangerActive),
        ]) {
          final why = '${_hex(fill)}: ${_hex(hover)}, ${_hex(active)}';
          final toHover = lum(hover) - lum(fill);
          final toActive = lum(active) - lum(fill);
          expect(toHover.sign, toActive.sign, reason: why);
          expect(toActive.abs(), greaterThan(toHover.abs()), reason: why);
          if (lum(on) < lum(fill)) {
            // A state layer, not a new colour.
            expect(contrastRatio(active, fill), lessThan(1.4), reason: why);
          }
        }
      });

      test(
        '$name: scrim, shadow and image roles are black- or white-based',
        () {
          final dark = p.brightness == Brightness.dark;
          expect(p.scrim.withValues(alpha: 1), _black);
          expect(p.scrim.a, closeTo(dark ? 0.6 : 0.45, 0.01));
          expect(p.shadow, _black);
          expect(p.onImage, _white);
          expect(p.imageScrim, _black.withValues(alpha: 0.6));
        },
      );

      test('$name: chart is 8+ categorical colours at 3:1', () {
        expect(p.chart.length, greaterThanOrEqualTo(8));
        expect(p.chart.toSet().length, p.chart.length);
        for (final c in p.chart) {
          _expectAtLeast(c, [p.surface, p.background], 3);
        }
        expect(p.branded(_demoSeeds.first).chart, p.chart);
      });

      test('$name: syntax colours are text-safe on surface and background', () {
        final s = p.syntax;
        for (final c in [
          s.key,
          s.string,
          s.number,
          s.literal,
          s.punctuation,
          s.comment,
        ]) {
          _expectAtLeast(c, [p.surface, p.background], 4.5);
        }
      });
    }

    test('an authored role wins over the derived one', () {
      final p = _baseOf(palettes.values.first);
      const x = Color(0xFF123456);
      const chart = [x, _white];
      final authored = p.copyWith(
        onPrimary: x,
        onDanger: x,
        onSuccess: x,
        onWarning: x,
        onInfo: x,
        primaryText: x,
        dangerText: x,
        successText: x,
        infoText: x,
        primaryHover: x,
        primaryActive: x,
        dangerHover: x,
        dangerActive: x,
        focusRing: x,
        controlBorder: x,
        controlAccent: x,
        placeholder: x,
        scrim: x,
        shadow: x,
        chart: chart,
        listHighlight: x,
        separator: x,
        navSelectedFill: x,
        navHoverFill: x,
        navSelectedText: x,
        navIndicator: x,
        fieldFill: x,
        fieldFillHover: x,
        fieldRule: x,
        softFill: x,
        onSoft: x,
        neutralFill: x,
        neutralFillHover: x,
        neutralFillActive: x,
        onNeutralFill: x,
      );
      for (final MapEntry(key: role, value: read) in _authoredRoles.entries) {
        expect(read(authored), role == 'chart' ? chart : x, reason: role);
        expect(read(p), isNot(read(authored)), reason: role);
      }
    });
  });

  group('branded', () {
    for (final MapEntry(key: name, value: palette) in palettes.entries) {
      test('$name × ${seeds.length} seeds keeps every pairing legible', () {
        final dark = palette.brightness == Brightness.dark;
        for (final seed in seeds) {
          final p = palette.branded(seed);
          final why = '$name + ${_hex(seed)}';
          _expectAtLeast(p.onPrimary, [p.primary], 4.5, why);
          _expectAtLeast(
            p.foreground,
            [p.primarySubtle, p.primaryFaint],
            4.5,
            why,
          );
          _expectAtLeast(
            p.primaryText,
            [p.surface, p.background, p.primarySubtle],
            4.5,
            why,
          );
          _expectAtLeast(p.focusRing, [p.surface, p.fieldFill], 3, why);
          _expectAtLeast(
            p.controlAccent,
            [p.surface, p.background, p.fieldFill],
            3,
            why,
          );
          _expectAtLeast(p.onSoft, [p.softFill], 4.5, why);
          _expectAtLeast(
            p.onControlAccent,
            [p.controlAccent, p.controlAccentHover],
            3,
            why,
          );
          _expectAtLeast(p.foregroundMutedOnTint, _tints(p), 4.5, why);
          expect(
            (relativeLuminance(p.primaryHover) - relativeLuminance(p.primary))
                .sign,
            (relativeLuminance(p.primaryActive) - relativeLuminance(p.primary))
                .sign,
            reason: '$why: hover and pressed step the same way',
          );
          expect(
            _distance(p.primaryFaint, p.surface),
            lessThan(_distance(p.primarySubtle, p.surface)),
            reason: why,
          );
          if (dark) {
            expect(
              relativeLuminance(p.primarySubtle),
              lessThan(0.2),
              reason: why,
            );
            expect(
              relativeLuminance(p.primaryFaint),
              lessThan(0.2),
              reason: why,
            );
          }
        }
      });
    }

    test('keeps a seed that already carries AA text', () {
      const violet = Color(0xFF7C3AED);
      expect(palettes.values.first.branded(violet).primary, violet);
    });

    test('re-derives the authored primary roles from the seed', () {
      const x = Color(0xFF123456);
      final authored = palettes.values.first.copyWith(
        onPrimary: x,
        primaryText: x,
        primaryHover: x,
        primaryActive: x,
        focusRing: x,
        controlAccent: x,
        onDanger: x,
      );
      final p = authored.branded(const Color(0xFF0D9488));
      expect(p.onPrimary, p.foregroundOn(p.primary));
      expect(p.primaryText, isNot(x));
      expect(p.primaryHover, isNot(x));
      expect(p.primaryActive, isNot(x));
      expect(p.focusRing, isNot(x));
      expect(p.controlAccent, p.primary);
      expect(p.onDanger, x);
    });
  });

  final light = _baseOf(palettes['Iris Light']!);

  group('copyWith and lerp', () {
    final dark = palettes['Iris Dark']!.copyWith(
      onPrimary: const Color(0xFF101010),
      focusRing: const Color(0xFFABCDEF),
      controlAccent: const Color(0xFFC4B5FD),
      chart: const [Color(0xFF111111), Color(0xFF222222), Color(0xFF333333)],
    );

    for (final MapEntry(key: name, value: p) in {
      ...palettes,
      'authored': dark,
    }.entries) {
      test('$name: copyWith() keeps every field', () {
        _expectSameFields(p.copyWith(), p);
      });
    }

    test('lerp returns the endpoints at t=0 and t=1', () {
      for (final (a, b) in [(light, dark), (dark, light)]) {
        _expectSameFields(AdminPalette.lerp(a, b, 0), a);
        _expectSameFields(AdminPalette.lerp(a, b, 1), b);
      }
    });

    test('a role neither side authored stays derived', () {
      final mid = AdminPalette.lerp(light, _baseOf(dark), 0.5);
      expect(mid.onPrimary, mid.foregroundOn(mid.primary));
      expect(
        mid.primaryText,
        mid.readableOn(
          mid.primary,
          surfaces: [mid.surface, mid.background, mid.primarySubtle],
        ),
      );
    });
  });

  group('tokens', () {
    test('elevation defaults by brightness, focus to 2/2', () {
      for (final MapEntry(key: name, value: p) in palettes.entries) {
        final tokens = AdminTokens.from(palette: p);
        expect(
          tokens.elevation,
          p.brightness == Brightness.dark
              ? defaultDarkElevation
              : defaultElevation,
          reason: name,
        );
        expect(tokens.focus, const AdminFocusSpec(width: 2, offset: 2));
      }
      const custom = AdminFocusSpec(width: 3, offset: 1);
      expect(AdminTokens.from(palette: light, focus: custom).focus, custom);
    });

    test('focus lerps with the tokens', () {
      final a = AdminTokens.from(palette: light);
      final b = a.copyWith(focus: const AdminFocusSpec(width: 4, offset: 0));
      expect(a.lerp(b, 0.5).focus, const AdminFocusSpec(width: 3, offset: 1));
    });

    testWidgets('context.focus reads the active tokens', (tester) async {
      const focus = AdminFocusSpec(width: 3, offset: 1);
      final tokens = AdminTokens.from(palette: light, focus: focus);
      late AdminFocusSpec read;
      await tester.pumpWidget(
        Theme(
          data: buildAppTheme(tokens),
          child: Builder(
            builder: (context) {
              read = context.focus;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(read, focus);
    });
  });

  group('buildAppTheme', () {
    for (final MapEntry(key: name, value: tokens) in themed.entries) {
      test('$name maps the full scheme from the palette', () {
        final p = tokens.palette;
        final theme = buildAppTheme(tokens);
        final scheme = theme.colorScheme;
        expect(scheme.brightness, p.brightness);
        expect(scheme.primary, p.primary);
        expect(scheme.onPrimary, p.onPrimary);
        expect(scheme.surface, p.surface);
        expect(scheme.onSurface, p.foreground);
        expect(scheme.onSurfaceVariant, p.foregroundMuted);
        expect(scheme.outline, p.controlBorder);
        expect(scheme.outlineVariant, p.border);
        expect(scheme.inverseSurface, p.foreground);
        expect(scheme.onInverseSurface, p.surface);
        expect(scheme.error, p.danger);
        expect(scheme.onError, p.onDanger);
        expect(scheme.primaryContainer, p.primarySubtle);
        expect(scheme.onPrimaryContainer, p.primaryText);
        expect(scheme.scrim, p.scrim);
        expect(scheme.shadow, p.shadow);
        expect(
          {
            scheme.surfaceContainerLowest,
            scheme.surfaceContainer,
            scheme.surfaceContainerHighest,
          },
          {p.surface, p.background, p.surfaceMuted},
        );
        expect(theme.textTheme.bodyMedium!.color, p.foreground);
        expect(theme.textTheme.displayLarge!.color, p.foreground);
        expect(theme.dividerTheme.color, p.border);
        expect(theme.cardTheme.color, p.surface);
        expect(theme.cardTheme.elevation, 0);
        expect(theme.snackBarTheme.backgroundColor, p.foreground);
        expect(theme.visualDensity, VisualDensity.standard);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
        expect(theme.extension<AdminTokens>(), same(tokens));
      });
    }

    for (final MapEntry(key: name, value: tokens) in themed.entries) {
      testWidgets('$name: the input theme and fieldInputDecoration agree', (
        tester,
      ) async {
        final theme = buildAppTheme(tokens);
        final spec = theme.inputDecorationTheme;
        late InputDecoration plain, invalid, chromeless;
        await tester.pumpWidget(
          Theme(
            data: theme,
            child: Builder(
              builder: (context) {
                plain = fieldInputDecoration(context, hint: 'Hint');
                invalid = fieldInputDecoration(context, invalid: true);
                return ChromelessFieldScope(
                  child: Builder(
                    builder: (context) {
                      chromeless = fieldInputDecoration(context);
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        );

        final p = tokens.palette;
        final radius = tokens.radii.radius;
        InputBorder? themed(Set<WidgetState> states) =>
            WidgetStateProperty.resolveAs(spec.border, states);
        InputBorder? field(InputDecoration d, Set<WidgetState> states) =>
            WidgetStateProperty.resolveAs(d.border, states);
        const hovered = {WidgetState.hovered};
        const focused = {WidgetState.focused};
        const disabled = {WidgetState.disabled};
        const error = {WidgetState.error};
        const focusedError = {WidgetState.error, WidgetState.focused};

        expect(themed({}), _outline(p.controlBorder, 1, radius));
        expect(
          themed(hovered),
          _outline(
            Color.alphaBlend(
              p.foreground.withValues(alpha: 0.3),
              p.controlBorder,
            ),
            1,
            radius,
          ),
        );
        expect(themed(focused), _outline(p.focusRing, 1.5, radius));
        expect(
          themed(disabled),
          _outline(Color.lerp(p.border, p.controlBorder, 0.5)!, 1, radius),
        );
        expect(themed(error), _outline(p.danger, 1.5, radius));
        expect(themed(focusedError), _outline(p.danger, 1.5, radius));

        // One stateful border, so the theme's hover reaches kit fields; no
        // per-state border that would pin a state's look.
        for (final states in [
          <WidgetState>{},
          hovered,
          focused,
          disabled,
          error,
          focusedError,
        ]) {
          expect(field(plain, states), themed(states), reason: '$states');
        }
        for (final d in [plain, invalid]) {
          expect(d.enabledBorder, isNull);
          expect(d.focusedBorder, isNull);
          expect(d.disabledBorder, isNull);
          expect(d.errorBorder, isNull);
          expect(d.focusedErrorBorder, isNull);
        }
        expect(field(invalid, {}), themed(error));
        expect(field(invalid, hovered), themed(error));
        expect(field(invalid, focused), themed(focusedError));

        expect(plain.contentPadding, spec.contentPadding);
        expect(
          plain.contentPadding,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
        Color? fill(InputDecoration d, Set<WidgetState> states) =>
            WidgetStateProperty.resolveAs(d.fillColor, states);
        expect(fill(plain, {}), p.fieldFill);
        expect(fill(plain, disabled), fieldFillColor(p, disabled));
        expect(WidgetStateProperty.resolveAs(spec.fillColor, {}), p.fieldFill);
        expect(plain.filled, spec.filled);
        expect(plain.isDense, spec.isDense);
        expect(plain.hintStyle!.color, spec.hintStyle!.color);
        expect(plain.hintStyle!.color, p.placeholder);
        expect(plain.hintStyle!.fontSize, tokens.typography.fieldText.fontSize);

        for (final border in [
          chromeless.border,
          chromeless.enabledBorder,
          chromeless.focusedBorder,
          chromeless.disabledBorder,
          chromeless.errorBorder,
          chromeless.focusedErrorBorder,
        ]) {
          expect(border, InputBorder.none);
        }
        expect(chromeless.filled, isFalse);
      });
    }

    testWidgets("a field's own border is not overridden by the theme", (
      tester,
    ) async {
      final tokens = themed['Iris Light']!;
      final own = OutlineInputBorder(borderRadius: BorderRadius.circular(3));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: Material(
            child: Column(
              children: [
                const TextField(
                  autofocus: true,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
                TextField(decoration: InputDecoration(border: own)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final decorations = [
        for (final d in tester.widgetList<InputDecorator>(
          find.byType(InputDecorator),
        ))
          d.decoration,
      ];
      expect(decorations[0].border, InputBorder.none);
      expect(decorations[0].focusedBorder, isNull);
      expect(decorations[0].enabledBorder, isNull);
      expect(decorations[1].border, own);
      expect(decorations[1].focusedBorder, isNull);
      expect(decorations[1].enabledBorder, isNull);
    });
  });

  testWidgets('severityStyleOf fills the text-safe and on-accent roles', (
    tester,
  ) async {
    final tokens = themed['Iris Light']!;
    final p = tokens.palette;
    final styles = <Severity, SeverityStyle>{};
    await tester.pumpWidget(
      Theme(
        data: buildAppTheme(tokens),
        child: Builder(
          builder: (context) {
            for (final s in Severity.values) {
              styles[s] = severityStyleOf(context, s);
            }
            return const SizedBox();
          },
        ),
      ),
    );
    for (final (severity, accent, foreground, onAccent) in [
      (Severity.info, p.info, p.infoText, p.onInfo),
      (Severity.success, p.success, p.successText, p.onSuccess),
      (Severity.warning, p.warning, p.warningText, p.onWarning),
      (Severity.danger, p.danger, p.dangerText, p.onDanger),
    ]) {
      final style = styles[severity]!;
      expect(style.accent, accent);
      expect(style.surface, p.statusFill(accent));
      expect(style.border, p.statusBorder(accent));
      expect(style.foreground, foreground);
      expect(style.onAccent, onAccent);
    }
  });
}

/// Every optional role, read through its resolving getter.
final _authoredRoles = <String, Object Function(AdminPalette)>{
  'onPrimary': (p) => p.onPrimary,
  'onDanger': (p) => p.onDanger,
  'onSuccess': (p) => p.onSuccess,
  'onWarning': (p) => p.onWarning,
  'onInfo': (p) => p.onInfo,
  'primaryText': (p) => p.primaryText,
  'dangerText': (p) => p.dangerText,
  'successText': (p) => p.successText,
  'infoText': (p) => p.infoText,
  'primaryHover': (p) => p.primaryHover,
  'primaryActive': (p) => p.primaryActive,
  'dangerHover': (p) => p.dangerHover,
  'dangerActive': (p) => p.dangerActive,
  'focusRing': (p) => p.focusRing,
  'controlBorder': (p) => p.controlBorder,
  'controlAccent': (p) => p.controlAccent,
  'placeholder': (p) => p.placeholder,
  'scrim': (p) => p.scrim,
  'shadow': (p) => p.shadow,
  'chart': (p) => p.chart,
  'listHighlight': (p) => p.listHighlight,
  'separator': (p) => p.separator,
  'navSelectedFill': (p) => p.navSelectedFill,
  'navHoverFill': (p) => p.navHoverFill,
  'navSelectedText': (p) => p.navSelectedText,
  'navIndicator': (p) => p.navIndicator,
  'fieldFill': (p) => p.fieldFill,
  'fieldFillHover': (p) => p.fieldFillHover,
  'fieldRule': (p) => p.fieldRule,
  'softFill': (p) => p.softFill,
  'onSoft': (p) => p.onSoft,
  'neutralFill': (p) => p.neutralFill,
  'neutralFillHover': (p) => p.neutralFillHover,
  'neutralFillActive': (p) => p.neutralFillActive,
  'onNeutralFill': (p) => p.onNeutralFill,
};

/// Every colour a palette exposes: the base fields, then the optional roles.
final _fields = <String, Object Function(AdminPalette)>{
  'primary': (p) => p.primary,
  'primaryStrong': (p) => p.primaryStrong,
  'primarySubtle': (p) => p.primarySubtle,
  'primaryFaint': (p) => p.primaryFaint,
  'surface': (p) => p.surface,
  'background': (p) => p.background,
  'surfaceMuted': (p) => p.surfaceMuted,
  'foreground': (p) => p.foreground,
  'foregroundSecondary': (p) => p.foregroundSecondary,
  'foregroundMuted': (p) => p.foregroundMuted,
  'foregroundSubtle': (p) => p.foregroundSubtle,
  'foregroundFaint': (p) => p.foregroundFaint,
  'border': (p) => p.border,
  'borderSubtle': (p) => p.borderSubtle,
  'success': (p) => p.success,
  'warning': (p) => p.warning,
  'danger': (p) => p.danger,
  'warningText': (p) => p.warningText,
  'info': (p) => p.info,
  'highlight': (p) => p.highlight,
  'modifiedFill': (p) => p.modifiedFill,
  'tabDivider': (p) => p.tabDivider,
  ..._authoredRoles,
  'onControlAccent': (p) => p.onControlAccent,
  'controlAccentHover': (p) => p.controlAccentHover,
  'foregroundMutedOnTint': (p) => p.foregroundMutedOnTint,
  'syntax': (p) => p.syntax,
};

/// The tinted fills supporting text sits on: [AdminPalette.foregroundMutedOnTint]
/// reaches 4.5:1 on each.
List<Color> _tints(AdminPalette p) => [
  p.surface,
  p.background,
  p.surfaceMuted,
  p.primarySubtle,
  p.primaryFaint,
  p.listHighlight,
  p.tableRowSelected,
  p.tableRowSelectedHover,
  Color.alphaBlend(p.hoverOverlay, p.surface),
];

void _expectSameFields(AdminPalette actual, AdminPalette expected) {
  for (final MapEntry(key: name, value: read) in _fields.entries) {
    expect(read(actual), read(expected), reason: name);
  }
}

/// [p]'s base colours alone, with every optional role left to derive.
AdminPalette _baseOf(AdminPalette p) => AdminPalette(
  primary: p.primary,
  primaryStrong: p.primaryStrong,
  primarySubtle: p.primarySubtle,
  primaryFaint: p.primaryFaint,
  surface: p.surface,
  background: p.background,
  surfaceMuted: p.surfaceMuted,
  foreground: p.foreground,
  foregroundSecondary: p.foregroundSecondary,
  foregroundMuted: p.foregroundMuted,
  foregroundSubtle: p.foregroundSubtle,
  foregroundFaint: p.foregroundFaint,
  border: p.border,
  borderSubtle: p.borderSubtle,
  success: p.success,
  warning: p.warning,
  danger: p.danger,
  warningText: p.warningText,
  info: p.info,
  highlight: p.highlight,
  modifiedFill: p.modifiedFill,
  tabDivider: p.tabDivider,
);

void _expectAtLeast(
  Color color,
  List<Color> surfaces,
  double min, [
  String why = '',
]) {
  for (final surface in surfaces) {
    expect(
      contrastRatio(color, surface),
      greaterThanOrEqualTo(min),
      reason: '$why ${_hex(color)} on ${_hex(surface)}',
    );
  }
}

OutlineInputBorder _outline(Color color, double width, double radius) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
      gapPadding: 0,
    );

double _distance(Color a, Color b) => math.sqrt(
  math.pow(a.r - b.r, 2) + math.pow(a.g - b.g, 2) + math.pow(a.b - b.b, 2),
);

double _hueGap(double a, double b) {
  final gap = (a - b).abs() % 360;
  return math.min(gap, 360 - gap);
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
