import 'dart:math' as math;

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

const _transparent = Color(0x00000000);

/// Fluent's dark colorCompoundBrandBackground.
const _compoundBrand = Color(0xFF479EF5);

/// The list, overlay and navigation roles of every shipped palette, in both
/// modes and under every demo brand, and the role radii of every theme.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final theme in adminThemes) {
    for (final (mode, palette) in [
      ('Light', theme.palette),
      ('Dark', theme.darkPalette!),
    ]) {
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        final p = seed == null ? palette : palette.branded(seed);
        final why = '${theme.name} $mode, brand $brand';

        test('$why: list and overlay roles', () {
          // No fainter than shadcn's --accent (#F4F4F5) on white.
          expect(
            contrastRatio(p.listHighlight, p.surface),
            greaterThanOrEqualTo(1.09),
            reason: 'listHighlight on bg',
          );
          expect(p.listHighlight.a, 1, reason: 'listHighlight is opaque');
          expect(
            contrastRatio(p.separator, p.surface),
            greaterThanOrEqualTo(
              [
                contrastRatio(p.border, p.surface),
                contrastRatio(p.borderSubtle, p.surface),
              ].reduce((a, b) => a < b ? a : b),
            ),
            reason:
                'separator is at least the weaker of border and borderSubtle',
          );
        });

        test('$why: field chrome states', () {
          const rest = <WidgetState>{};
          final side = fieldBorderSide(p, rest, stroke: const AdminStroke());
          final hover = fieldBorderSide(p, {
            WidgetState.hovered,
          }, stroke: const AdminStroke());
          final focus = fieldBorderSide(p, {
            WidgetState.focused,
          }, stroke: const AdminStroke());
          // Hover is a step stronger than rest on the field's own fill, but
          // stays 1px: the 1.5px focus ring still outweighs it.
          expect(
            contrastRatio(hover.color, p.surface),
            greaterThan(contrastRatio(side.color, p.surface)),
            reason: 'hover outline is stronger than rest',
          );
          expect(hover.width, 1);
          expect(focus.width, greaterThan(hover.width));
          expect(
            fieldBorderSide(p, {
              WidgetState.hovered,
              WidgetState.error,
            }, stroke: const AdminStroke()),
            fieldBorderSide(p, {
              WidgetState.error,
            }, stroke: const AdminStroke()),
          );
          // A disabled field is a box of its own. In a dark theme it often
          // sits right on the background, so the fill itself stands off it;
          // in a light one the outline does.
          final disabled = fieldFillColor(p, {WidgetState.disabled});
          final outline = fieldBorderSide(p, {
            WidgetState.disabled,
          }, stroke: const AdminStroke()).color;
          if (p.brightness == Brightness.dark) {
            expect(
              contrastRatio(disabled, p.background),
              greaterThanOrEqualTo(1.2),
              reason: 'disabled fill on the page',
            );
          } else {
            expect(
              contrastRatio(outline, p.background),
              greaterThanOrEqualTo(1.05),
              reason: 'disabled outline on the page',
            );
          }
          expect(
            contrastRatio(disabled, p.surface),
            greaterThanOrEqualTo(1.07),
            reason: 'disabled fill on a card',
          );
          expect(fieldFillColor(p, rest), p.surface);
        });

        test('$why: control accent', () {
          final authored = seed == null && palette == fluentDarkPalette;
          final primaryReaches = [
            p.surface,
            p.background,
          ].every((s) => contrastRatio(p.primary, s) >= 3);
          if (authored) {
            expect(p.controlAccent, _compoundBrand);
          } else if (primaryReaches) {
            expect(
              p.controlAccent,
              p.primary,
              reason: 'a primary at 3:1 already is the accent, unchanged',
            );
          } else {
            expect(
              _hueGap(p.primary, p.controlAccent),
              lessThanOrEqualTo(2),
              reason: 'lifted by lightness alone',
            );
          }
          if (p.controlAccent == p.primary) {
            expect(p.onControlAccent, p.onPrimary);
            expect(p.controlAccentHover, p.primaryHover);
          } else {
            expect(p.onControlAccent, p.foregroundOn(p.controlAccent));
            expect(p.controlAccentHover, isNot(p.controlAccent));
          }
        });

        test('$why: muted text on tints', () {
          final passes = _tints(p)
              .every((t) => contrastRatio(p.foregroundMuted, t) >= 4.5);
          if (passes) {
            expect(p.foregroundMutedOnTint, p.foregroundMuted);
          } else {
            // Deeper in a light theme, lighter in a dark one.
            final dark = p.brightness == Brightness.dark;
            expect(
              relativeLuminance(p.foregroundMutedOnTint),
              dark
                  ? greaterThan(relativeLuminance(p.foregroundMuted))
                  : lessThan(relativeLuminance(p.foregroundMuted)),
            );
          }
        });

        test('$why: navigation roles', () {
          final hover = contrastRatio(p.navHoverFill, p.background);
          final selected = contrastRatio(p.navSelectedFill, p.background);
          expect(hover, greaterThanOrEqualTo(1.08), reason: 'hover shows');
          expect(
            selected,
            greaterThanOrEqualTo(hover - 1e-9),
            reason: 'selected stands at least as far from the rail as hover',
          );
          expect(
            contrastRatio(p.navSelectedText, p.navSelectedFill),
            greaterThanOrEqualTo(4.5),
            reason: 'navSelectedText on navSelectedFill',
          );
          if (p.navIndicator.a > 0) {
            for (final surface in [p.background, p.navSelectedFill]) {
              expect(
                contrastRatio(p.navIndicator, surface),
                greaterThanOrEqualTo(3),
                reason: 'navIndicator is a 3:1 mark',
              );
            }
          }
        });
      }
    }
  }

  group('navigation roles per system', () {
    test(
      'Iris, Carbon and Fluent draw a bar; Material, shadcn and Ant none',
      () {
        for (final theme in adminThemes) {
          for (final p in [theme.palette, theme.darkPalette!]) {
            final bar = p.navIndicator.a > 0;
            expect(
              bar,
              {'Iris', 'Carbon', 'Fluent'}.contains(theme.name),
              reason: theme.name,
            );
            for (final seed in _brands.values.nonNulls) {
              expect(
                p.branded(seed).navIndicator.a > 0,
                bar,
                reason: '${theme.name} keeps its bar choice under a brand',
              );
            }
          }
        }
      },
    );

    test('Carbon Light: \$layer-selected over \$layer-hover, both visible', () {
      expect(carbonPalette.navSelectedFill, const Color(0xFFE0E0E0));
      expect(carbonPalette.navHoverFill, const Color(0xFFE8E8E8));
      expect(
        contrastRatio(carbonPalette.navHoverFill, carbonPalette.background),
        greaterThan(1.08),
      );
    });

    test('shadcn: a hovered row never matches the selected one', () {
      for (final p in [shadcnPalette, shadcnDarkPalette]) {
        expect(
          contrastRatio(p.navSelectedFill, p.background),
          greaterThan(contrastRatio(p.navHoverFill, p.background) + 0.05),
        );
      }
    });

    test('Ant: the selected label reaches AA on its tint', () {
      for (final p in [antPalette, antDarkPalette]) {
        expect(
          contrastRatio(p.navSelectedText, p.navSelectedFill),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });

  group('derived and branded', () {
    const x = Color(0xFF123456);
    final base = irisPalette;

    test('an authored role wins; copyWith keeps it', () {
      final p = base.copyWith(
        listHighlight: x,
        separator: x,
        navSelectedFill: x,
        navHoverFill: x,
        navSelectedText: x,
        navIndicator: x,
      );
      for (final c in [
        p.listHighlight,
        p.separator,
        p.navSelectedFill,
        p.navHoverFill,
        p.navSelectedText,
        p.navIndicator,
      ]) {
        expect(c, x);
      }
      expect(p.copyWith().navSelectedFill, x);
    });

    test('the defaults derive from the base', () {
      expect(
        base.listHighlight,
        Color.alphaBlend(base.foreground.withValues(alpha: 0.06), base.surface),
      );
      expect(base.separator, base.border);
      expect(
        base.navHoverFill,
        Color.alphaBlend(
          base.foreground.withValues(alpha: 0.05),
          base.background,
        ),
      );
      expect(base.navIndicator, base.primary);
    });

    test('a brand re-derives the selection and a bar, keeps the neutrals', () {
      final authored = base.copyWith(
        listHighlight: x,
        separator: x,
        navHoverFill: const Color(0xFFE8E8E8),
        navSelectedFill: x,
        navSelectedText: x,
        navIndicator: x,
      );
      final p = authored.branded(const Color(0xFF0D9488));
      expect(p.listHighlight, x);
      expect(p.separator, x);
      expect(p.navHoverFill, const Color(0xFFE8E8E8));
      expect(p.navSelectedFill, isNot(x));
      expect(p.navSelectedText, isNot(x));
      expect(p.navIndicator, isNot(x));
      expect(
        authored.copyWith(navIndicator: _transparent).branded(x).navIndicator,
        _transparent,
      );
    });

    test('lerp interpolates authored roles and leaves the rest derived', () {
      final a = base.copyWith(navIndicator: _transparent);
      final b = irisDarkPalette;
      expect(AdminPalette.lerp(a, b, 0).navIndicator, _transparent);
      expect(AdminPalette.lerp(a, b, 1).navIndicator, b.navIndicator);
      final mid = AdminPalette.lerp(base, irisDarkPalette, 0.5);
      expect(mid.listHighlight, isNot(base.listHighlight));
      expect(
        mid.navSelectedText,
        mid.readableOn(mid.primaryText, surfaces: [mid.navSelectedFill]),
      );
    });
  });

  group('control accent', () {
    const x = Color(0xFF123456);
    const violet = Color(0xFF7C3AED);

    test('is the primary where the primary reaches 3:1', () {
      for (final p in [irisPalette, materialPalette, fluentPalette]) {
        expect(p.controlAccent, p.primary);
        expect(p.onControlAccent, p.onPrimary);
        expect(p.controlAccentHover, p.primaryHover);
      }
    });

    test('Fluent Dark takes the compound brand', () {
      const p = fluentDarkPalette;
      expect(contrastRatio(p.primary, p.surface), lessThan(3));
      expect(p.controlAccent, _compoundBrand);
      expect(p.onControlAccent, p.foregroundOn(_compoundBrand));
      expect(
        contrastRatio(p.controlAccent, p.surface),
        greaterThanOrEqualTo(3),
      );
    });

    test('a dark theme lifts a Violet brand to 3:1, keeping its hue', () {
      for (final palette in [
        irisDarkPalette,
        materialDarkPalette,
        carbonDarkPalette,
        fluentDarkPalette,
      ]) {
        final p = palette.branded(violet);
        expect(contrastRatio(p.primary, p.surface), lessThan(3));
        for (final surface in [p.surface, p.background]) {
          expect(
            contrastRatio(p.controlAccent, surface),
            greaterThanOrEqualTo(3),
          );
        }
        expect(_hueGap(violet, p.controlAccent), lessThanOrEqualTo(2));
        expect(
          relativeLuminance(p.controlAccent),
          greaterThan(relativeLuminance(p.primary)),
        );
        expect(
          contrastRatio(p.onControlAccent, p.controlAccentHover),
          greaterThanOrEqualTo(3),
        );
      }
    });

    test('an authored accent wins; copyWith, lerp and == keep it', () {
      final authored = irisPalette.copyWith(controlAccent: x);
      expect(authored.controlAccent, x);
      expect(authored.onControlAccent, authored.foregroundOn(x));
      expect(authored.copyWith().controlAccent, x);
      expect(authored.copyWith(), authored);
      expect(authored, isNot(irisPalette));
      expect(AdminPalette.lerp(authored, irisDarkPalette, 0).controlAccent, x);
      expect(
        AdminPalette.lerp(authored, irisDarkPalette, 1).controlAccent,
        irisDarkPalette.controlAccent,
      );
      final mid = AdminPalette.lerp(irisPalette, irisDarkPalette, 0.5);
      expect(
        mid.controlAccent,
        mid.readableOn(
          mid.primary,
          surfaces: [mid.surface, mid.background],
          minContrast: 3,
        ),
      );
    });

    test('a brand drops an authored accent', () {
      const teal = Color(0xFF0D9488);
      final p = irisPalette.copyWith(controlAccent: x).branded(teal);
      expect(p.controlAccent, p.primary);
      final fluent = fluentDarkPalette.branded(teal);
      expect(fluent.controlAccent, isNot(_compoundBrand));
      expect(
        fluent.controlAccent,
        fluent.readableOn(
          fluent.primary,
          surfaces: [fluent.surface, fluent.background],
          minContrast: 3,
        ),
      );
    });
  });

  group('muted text on tints', () {
    test('deepens in Iris, shadcn and Ant Light', () {
      for (final p in [irisPalette, shadcnPalette, antPalette]) {
        expect(p.foregroundMutedOnTint, isNot(p.foregroundMuted));
        expect(
          relativeLuminance(p.foregroundMutedOnTint),
          lessThan(relativeLuminance(p.foregroundMuted)),
        );
        // foregroundMuted sits just under 4.5:1 on the selected-row tints.
        for (final tint in [p.primarySubtle, p.tableRowSelected]) {
          expect(contrastRatio(p.foregroundMuted, tint), lessThan(4.5));
          expect(
            contrastRatio(p.foregroundMutedOnTint, tint),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });

    test('is foregroundMuted where that already reads on every tint', () {
      for (final p in [
        materialPalette,
        materialDarkPalette,
        fluentPalette,
        carbonPalette,
      ]) {
        expect(p.foregroundMutedOnTint, p.foregroundMuted);
      }
    });

    test('leaves the authored foregroundMuted alone', () {
      expect(irisPalette.foregroundMuted, const Color(0xFF6B7280));
      expect(shadcnPalette.foregroundMuted, const Color(0xFF71717A));
      expect(antPalette.foregroundMuted, const Color(0xFF707070));
    });
  });

  group('role radii', () {
    const expected = {
      // theme: (menu, dialog, pill, field, button small / medium / large)
      'Iris': (9.0, 12.0, 999.0, 9.0, (7.0, 9.0, 9.0)),
      // M3: 4dp fields (corner.extraSmall), full-round buttons
      'Material': (4.0, 28.0, 8.0, 4.0, (999.0, 999.0, 999.0)),
      'shadcn': (8.0, 12.0, 999.0, 8.0, (6.0, 8.0, 8.0)),
      // Ant: borderRadius 6, borderRadiusSM 4 on a small button
      'Ant': (8.0, 8.0, 4.0, 6.0, (4.0, 6.0, 6.0)),
      // Fluent: borderRadiusMedium on inputs and every button
      'Fluent': (4.0, 8.0, 4.0, 4.0, (4.0, 4.0, 4.0)),
      // Carbon: square, tags aside
      'Carbon': (0.0, 0.0, 999.0, 0.0, (0.0, 0.0, 0.0)),
    };
    for (final theme in adminThemes) {
      test(theme.name, () {
        final r = theme.tokens.radii;
        final (menu, dialog, pill, field, button) = expected[theme.name]!;
        expect(r.radiusMenu, menu, reason: 'radiusMenu');
        expect(r.radiusDialog, dialog, reason: 'radiusDialog');
        expect(r.radiusPill, pill, reason: 'radiusPill');
        expect(r.radiusField, field, reason: 'radiusField');
        expect((
          r.button(ControlSize.small),
          r.button(ControlSize.medium),
          r.button(ControlSize.large),
        ), button);
        expect(r.radiusCheck, lessThanOrEqualTo(4));
        expect(r.radiusCheck, lessThanOrEqualTo(r.radiusSmall));
      });
    }

    test('roles default from the scale', () {
      const r = AdminRadii(radiusSmall: 6, radius: 10, radiusLarge: 14);
      expect(r.radiusMenu, 10);
      expect(r.radiusDialog, 14);
      expect(r.radiusPill, 999);
      expect(r.radiusCheck, 4);
      expect(r.copyWith(radiusMenu: 2).radiusMenu, 2);
      expect(r.copyWith(radius: 12).radiusMenu, 12);
    });

    test('lerp keeps an unauthored role derived', () {
      const a = AdminRadii(radiusSmall: 0, radius: 2, radiusLarge: 4);
      const b = AdminRadii(
        radiusSmall: 8,
        radius: 12,
        radiusLarge: 16,
        radiusDialog: 28,
      );
      final mid = AdminRadii.lerp(a, b, 0.5);
      expect(mid.radiusMenu, mid.radius);
      expect(mid.radiusDialog, 16);
      expect(AdminRadii.lerp(a, b, 1).radiusDialog, 28);
    });

    testWidgets('Material dialogs and menus take the role radii', (
      tester,
    ) async {
      final theme = buildAppTheme(materialTheme.tokens);
      BorderRadiusGeometry? radiusOf(ShapeBorder? shape) =>
          (shape as RoundedRectangleBorder?)?.borderRadius;
      expect(radiusOf(theme.dialogTheme.shape), BorderRadius.circular(28));
      expect(radiusOf(theme.popupMenuTheme.shape), BorderRadius.circular(4));
      expect(
        radiusOf(theme.menuTheme.style?.shape?.resolve({})),
        BorderRadius.circular(4),
      );
      final input = theme.inputDecorationTheme.border! as OutlineInputBorder;
      expect(input.borderRadius, BorderRadius.circular(4));
      for (final style in [
        theme.elevatedButtonTheme.style,
        theme.filledButtonTheme.style,
        theme.outlinedButtonTheme.style,
        theme.textButtonTheme.style,
        theme.iconButtonTheme.style,
      ]) {
        expect(
          radiusOf(style?.shape?.resolve({}) as ShapeBorder?),
          BorderRadius.circular(999),
        );
      }
    });
  });
}

/// The tinted fills supporting text sits on.
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

/// The distance between the HSL hues of [a] and [b], in degrees.
double _hueGap(Color a, Color b) {
  final gap =
      (HSLColor.fromColor(a).hue - HSLColor.fromColor(b).hue).abs() % 360;
  return math.min(gap, 360 - gap);
}
