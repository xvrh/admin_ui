import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

const _teal = Color(0xFF0D9488);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('state layer', () {
    test('the kit default keeps the overlays it always drew', () {
      const p = irisPalette;
      expect(p.stateLayer, const AdminStateLayer());
      expect(p.hoverOverlay, p.foreground.withValues(alpha: 0.05));
      expect(p.focusOverlay, p.foreground.withValues(alpha: 0.05));
      expect(p.pressedOverlay, p.foreground.withValues(alpha: 0.10));
      expect(p.draggedOverlay, p.foreground.withValues(alpha: 0.10));
      expect(p.primaryHoverOverlay, p.primary.withValues(alpha: 0.08));
      expect(p.primaryPressedOverlay, p.primary.withValues(alpha: 0.14));
    });

    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      final material = name.startsWith('Material');
      test('$name: ${material ? "M3's" : "the kit's"} opacities', () {
        final layer = palette.stateLayer;
        if (material) {
          expect(layer.hover, 0.08);
          expect(layer.focus, 0.10);
          expect(layer.pressed, 0.10);
          expect(layer.dragged, 0.16);
          expect(layer.tintHover, 0.08);
          expect(layer.tintPressed, 0.10);
        } else {
          expect(layer, const AdminStateLayer());
        }
        expect(
          palette.hoverOverlay,
          palette.foreground.withValues(alpha: layer.hover),
        );
        expect(
          palette.focusOverlay,
          palette.foreground.withValues(alpha: layer.focus),
        );
        expect(
          palette.pressedOverlay,
          palette.foreground.withValues(alpha: layer.pressed),
        );
        expect(
          palette.draggedOverlay,
          palette.foreground.withValues(alpha: layer.dragged),
        );
        expect(
          palette.primaryPressedOverlay,
          palette.primary.withValues(alpha: layer.tintPressed),
        );
      });
    }

    test('the palette carries it through copyWith, lerp, == and branding', () {
      const m3 = AdminStateLayer(hover: 0.08, pressed: 0.10);
      final p = irisPalette.copyWith(stateLayer: m3);
      expect(p, isNot(irisPalette));
      expect(p.hashCode, isNot(irisPalette.hashCode));
      expect(p.copyWith(), p);
      expect(p.branded(_teal).stateLayer, m3);
      expect(
        AdminPalette.lerp(irisPalette, p, 0.5).stateLayer,
        AdminStateLayer.lerp(const AdminStateLayer(), m3, 0.5),
      );
      expect(
        AdminPalette.lerp(irisPalette, p, 0.5).stateLayer.hover,
        closeTo(0.065, 1e-9),
      );
    });

    test('value semantics', () {
      const layer = AdminStateLayer();
      expect(layer.copyWith(), layer);
      expect(layer.copyWith().hashCode, layer.hashCode);
      expect(layer.copyWith(dragged: 0.16), isNot(layer));
      expect(AdminStateLayer.lerp(layer, layer, 0.3), layer);
    });

    testWidgets('a stock text button takes the focus overlay', (tester) async {
      final tokens = AdminTokens.from(palette: materialPalette);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: Scaffold(
            body: TextButton(onPressed: () {}, child: const Text('Go')),
          ),
        ),
      );
      final style = Theme.of(tester.element(find.text('Go')))
          .textButtonTheme
          .style!;
      Color? overlay(Set<WidgetState> states) =>
          style.overlayColor!.resolve(states);
      expect(overlay({WidgetState.hovered}), materialPalette.hoverOverlay);
      expect(overlay({WidgetState.focused}), materialPalette.focusOverlay);
      expect(overlay({WidgetState.pressed}), materialPalette.pressedOverlay);
      expect(overlay({}), isNull);
    });
  });

  group('stroke', () {
    // (fieldFocus, fieldError, fieldFocusHalo) per theme.
    const expected = {
      'Iris': (1.5, 1.5, 0.0),
      'Material': (2.0, 1.0, 0.0),
      'shadcn': (1.0, 1.0, 3.0),
      // Ant: activeShadow's 2px ring
      'Ant': (1.0, 1.0, 2.0),
      // Fluent: the 2px colorCompoundBrandStroke underline
      'Fluent': (2.0, 1.0, 0.0),
      'Carbon': (2.0, 2.0, 0.0),
    };

    for (final theme in adminThemes) {
      test('${theme.name}: field outlines at its widths', () {
        final tokens = theme.tokens;
        final stroke = tokens.stroke;
        expect(theme.dark!.stroke, stroke);
        expect((
          stroke.fieldFocus,
          stroke.fieldError,
          stroke.fieldFocusHalo,
        ), expected[theme.name]);
        expect(stroke.hairline, 1);
        expect(stroke.control, 1);

        final p = tokens.palette;
        BorderSide side(Set<WidgetState> states) =>
            fieldBorderSide(p, states, stroke: stroke);
        expect(side({}), BorderSide(color: p.controlBorder));
        expect(side({WidgetState.hovered}).width, 1);
        expect(side({WidgetState.disabled}).width, 1);
        expect(
          side({WidgetState.focused}),
          BorderSide(color: p.focusRing, width: stroke.fieldFocus),
        );
        expect(
          side({WidgetState.error}),
          BorderSide(color: p.danger, width: stroke.fieldError),
        );
        final focusedError = side({WidgetState.error, WidgetState.focused});
        expect(focusedError.color, p.danger);
        expect(
          focusedError.width,
          stroke.fieldError > stroke.fieldFocus
              ? stroke.fieldError
              : stroke.fieldFocus,
        );
      });

      for (final dark in [false, true]) {
        final mode = dark ? 'Dark' : 'Light';
        test('${theme.name} $mode: focus outweighs rest and hover', () {
          final tokens = dark ? theme.dark! : theme.tokens;
          final p = tokens.palette;
          bool drawn(BorderSide side) => side.style != BorderStyle.none;
          // The edge focus marks, in the theme's anatomy: the outline, or
          // the rule under an underline indicator (either, where the box
          // draws only the other).
          final underline =
              tokens.field.focusIndicator == FieldFocusIndicator.underline;
          BorderSide side(Set<WidgetState> states) {
            final chrome = resolveFieldChrome(tokens, states);
            final (first, second) = underline
                ? (chrome.rule, chrome.outline)
                : (chrome.outline, chrome.rule);
            return drawn(first) ? first : second;
          }

          BorderSide halo(Set<WidgetState> states) =>
              resolveFieldChrome(tokens, states).halo;
          double contrast(BorderSide side) =>
              contrastRatio(side.color, p.fieldFill);
          const focused = {WidgetState.focused};
          final rest = side({}), hover = side({WidgetState.hovered});
          final focus = side(focused);

          // Focus reads without the caret: a wider outline, a halo, or an
          // outline of a clearly other colour.
          final wider = focus.width > rest.width;
          final ringed = halo(focused).width > 0;
          int channel(double a, double b) => ((a - b).abs() * 255).round();
          final recoloured = [
            channel(focus.color.r, rest.color.r),
            channel(focus.color.g, rest.color.g),
            channel(focus.color.b, rest.color.b),
          ].any((d) => d >= 48);
          expect(
            wider || ringed || recoloured,
            isTrue,
            reason: 'a focused field differs from one at rest',
          );
          expect(halo({}), BorderSide.none);
          expect(halo({...focused, WidgetState.disabled}), BorderSide.none);
          // A hovered field never outweighs a focused one: the hover step
          // stays 1px, and where the focus outline is no wider, it stops
          // at the focus ring's contrast.
          expect(hover.width, lessThanOrEqualTo(focus.width));
          if (!wider) {
            expect(
              contrast(hover),
              lessThanOrEqualTo(contrast(focus) + 0.01),
              reason: 'the hover step stops at the focus ring',
            );
          }
          expect(contrast(hover), greaterThanOrEqualTo(contrast(rest)));
        });
      }
    }

    test("AdminStroke's defaults are the kit's own widths", () {
      const p = irisPalette;
      expect(
        fieldBorderSide(p, {WidgetState.focused}, stroke: const AdminStroke()),
        BorderSide(color: p.focusRing, width: 1.5),
      );
      expect(
        fieldBorderSide(p, {WidgetState.error}, stroke: const AdminStroke()),
        BorderSide(color: p.danger, width: 1.5),
      );
      expect(
        fieldBorderSide(p, {}, stroke: const AdminStroke()),
        BorderSide(color: p.controlBorder),
      );
    });

    test('Material: a focused invalid field takes the wider focus stroke', () {
      final tokens = materialTheme.tokens;
      final p = tokens.palette;
      expect(
        fieldBorderSide(p, {
          WidgetState.error,
          WidgetState.focused,
        }, stroke: tokens.stroke),
        BorderSide(color: p.danger, width: 2),
      );
    });

    testWidgets('the input theme and the checkbox theme read it', (
      tester,
    ) async {
      final tokens = AdminTokens.from(
        palette: irisPalette,
        stroke: const AdminStroke(fieldFocus: 3, controlStrong: 2.5),
      );
      final theme = buildAppTheme(tokens);
      final border = theme.inputDecorationTheme.border! as FieldBorder;
      expect(border.chromeOf({WidgetState.focused}).outline.width, 3);
      expect(theme.checkboxTheme.side!.width, 2.5);
    });

    test('value semantics', () {
      const stroke = AdminStroke();
      expect(stroke.copyWith(), stroke);
      expect(stroke.copyWith().hashCode, stroke.hashCode);
      expect(stroke.copyWith(indicator: 3), isNot(stroke));
      expect(
        AdminStroke.lerp(stroke, stroke.copyWith(fieldFocus: 2.5), 0.5),
        stroke.copyWith(fieldFocus: 2),
      );
    });
  });

  group('icon sizes', () {
    test('one default for every shipped theme', () {
      for (final theme in adminThemes) {
        expect(
          theme.tokens.iconSizes,
          const AdminIconSizes(),
          reason: theme.name,
        );
      }
      const sizes = AdminIconSizes();
      expect(
        [sizes.xs, sizes.sm, sizes.md, sizes.lg, sizes.xl],
        [12, 14, 16, 20, 24],
      );
    });

    test('value semantics', () {
      const sizes = AdminIconSizes();
      expect(sizes.copyWith(), sizes);
      expect(sizes.copyWith().hashCode, sizes.hashCode);
      expect(sizes.copyWith(md: 18), isNot(sizes));
      expect(AdminIconSizes.lerp(sizes, sizes.copyWith(xl: 32), 0.5).xl, 28);
    });

    testWidgets('context.iconSizes and context.stroke read the tokens', (
      tester,
    ) async {
      final tokens = AdminTokens.from(
        palette: irisPalette,
        iconSizes: const AdminIconSizes(md: 18),
        stroke: const AdminStroke(indicator: 3),
      );
      late AdminIconSizes iconSizes;
      late AdminStroke stroke;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: Builder(
            builder: (context) {
              iconSizes = context.iconSizes;
              stroke = context.stroke;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(iconSizes.md, 18);
      expect(stroke.indicator, 3);
    });
  });

  test('tokens compare, copy and lerp the new members', () {
    final tokens = AdminTokens.from(palette: irisPalette);
    const stroke = AdminStroke(fieldFocus: 2);
    const icons = AdminIconSizes(md: 18);
    expect(tokens.copyWith(stroke: stroke), isNot(tokens));
    expect(tokens.copyWith(iconSizes: icons), isNot(tokens));
    expect(
      tokens.copyWith(stroke: stroke).copyWith(),
      tokens.copyWith(stroke: stroke),
    );
    final other = tokens.copyWith(stroke: stroke, iconSizes: icons);
    expect(tokens.lerp(other, 1).stroke, stroke);
    expect(tokens.lerp(other, 1).iconSizes, icons);
    expect(tokens.lerp(other, 0.5).stroke.fieldFocus, 1.75);
  });
}
