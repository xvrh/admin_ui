import 'dart:ui' show PointerDeviceKind;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The palette's inverse surface: what a tooltip's chip and a stock snack bar
// are filled with, and what reads on it.

/// Each shipped theme's inverse surface and its content, light then dark,
/// from its reference. Null is the derived pair: the foreground under the
/// surface colour.
const _expected = <String, ((Color, Color)?, (Color, Color)?)>{
  // the kit's own: the foreground, under the card's colour
  'Iris': (null, null),
  // inverseSurface under inverseOnSurface: neutral20 and neutral95, then
  // neutral90 and neutral20
  'Material': (
    (Color(0xFF322F35), Color(0xFFF5EFF7)),
    (Color(0xFFE6E0E9), Color(0xFF322F35)),
  ),
  // bg-foreground text-background
  'shadcn': (null, null),
  // colorBgSpotlight under colorTextLightSolid, dark in both algorithms
  'Ant': (
    (Color(0xFF262626), Color(0xFFFFFFFF)),
    (Color(0xFF424242), Color(0xFFFFFFFF)),
  ),
  // colorNeutralBackgroundStatic under colorNeutralForegroundStaticInverted,
  // dark in both themes
  'Fluent': (
    (Color(0xFF333333), Color(0xFFFFFFFF)),
    (Color(0xFF3D3D3D), Color(0xFFFFFFFF)),
  ),
  // $background-inverse under $text-inverse, in Gray 10 then Gray 100
  'Carbon': (
    (Color(0xFF393939), Color(0xFFFFFFFF)),
    (Color(0xFFF4F4F4), Color(0xFF161616)),
  ),
};

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Scaffold(body: Center(child: child)),
);

/// What a tooltip's chip is filled with: its box, or, where the theme gives
/// a tooltip an arrow, the box and the arrow drawn as one.
Color _fillOf(Decoration chip) => switch (chip) {
  BoxDecoration(:final color?) => color,
  // The arrowed chip keeps its fill beside the box it wraps.
  _ => (chip as dynamic).fill as Color,
};

Future<void> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump();
}

void main() {
  group('AdminPalette', () {
    test('derives the pair from the foreground and the surface', () {
      for (final p in [irisPalette, irisDarkPalette]) {
        expect(p.inverseSurface, p.foreground);
        expect(p.onInverseSurface, p.surface);
      }
    });

    test('an authored surface alone takes white or near-black', () {
      final dark = irisPalette.copyWith(
        inverseSurface: const Color(0xFF333333),
      );
      expect(dark.inverseSurface, const Color(0xFF333333));
      expect(dark.onInverseSurface, dark.foregroundOn(dark.inverseSurface));
      expect(dark.onInverseSurface, const Color(0xFFFFFFFF));
      final light = irisDarkPalette.copyWith(
        inverseSurface: const Color(0xFFF4F4F4),
      );
      expect(light.onInverseSurface, light.foregroundOn(light.inverseSurface));
      expect(
        contrastRatio(light.onInverseSurface, light.inverseSurface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('an authored pair is kept as it is', () {
      final p = irisPalette.copyWith(
        inverseSurface: const Color(0xFF322F35),
        onInverseSurface: const Color(0xFFF5EFF7),
      );
      expect(p.inverseSurface, const Color(0xFF322F35));
      expect(p.onInverseSurface, const Color(0xFFF5EFF7));
      // Content authored alone sits on the derived surface.
      final content = irisPalette.copyWith(
        onInverseSurface: const Color(0xFFF5EFF7),
      );
      expect(content.inverseSurface, irisPalette.foreground);
      expect(content.onInverseSurface, const Color(0xFFF5EFF7));
    });

    test('copies, compares and interpolates the pair', () {
      final p = irisPalette.copyWith(
        inverseSurface: const Color(0xFF333333),
        onInverseSurface: const Color(0xFFFFFFFF),
      );
      expect(p, isNot(irisPalette));
      expect(p.hashCode, isNot(irisPalette.hashCode));
      expect(p.copyWith(), p);
      expect(p.copyWith().hashCode, p.hashCode);
      expect(
        p.copyWith(primary: const Color(0xFF0D9488)).inverseSurface,
        const Color(0xFF333333),
      );
      expect(
        irisPalette.copyWith(inverseSurface: const Color(0xFF333333)),
        isNot(irisPalette.copyWith(inverseSurface: const Color(0xFF393939))),
      );

      // Two palettes that derive it still derive it between them.
      final between = AdminPalette.lerp(irisPalette, irisDarkPalette, 0.5);
      expect(between.inverseSurface, between.foreground);
      expect(between.onInverseSurface, between.surface);
      // From a derived pair to an authored one, by way of what each draws.
      final half = AdminPalette.lerp(irisPalette, p, 0.5);
      expect(
        half.inverseSurface,
        Color.lerp(irisPalette.foreground, const Color(0xFF333333), 0.5),
      );
      expect(
        half.onInverseSurface,
        Color.lerp(irisPalette.surface, const Color(0xFFFFFFFF), 0.5),
      );
      expect(
        AdminPalette.lerp(irisPalette, p, 1).inverseSurface,
        p.inverseSurface,
      );
    });

    test('a brand keeps it', () {
      const seed = Color(0xFF0D9488);
      final derived = irisPalette.branded(seed);
      expect(derived.inverseSurface, derived.foreground);
      final authored = irisPalette
          .copyWith(
            inverseSurface: const Color(0xFF333333),
            onInverseSurface: const Color(0xFFFFFFFF),
          )
          .branded(seed);
      expect(authored.inverseSurface, const Color(0xFF333333));
      expect(authored.onInverseSurface, const Color(0xFFFFFFFF));
    });

    test('gives the stock colour scheme its inverse roles', () {
      for (final p in [
        irisPalette,
        irisDarkPalette,
        materialTheme.tokens.palette,
        materialTheme.dark!.palette,
        antTheme.dark!.palette,
      ]) {
        final scheme = p.colorScheme;
        expect(scheme.inverseSurface, p.inverseSurface);
        expect(scheme.onInverseSurface, p.onInverseSurface);
        // A snack bar's action reads on it.
        expect(
          contrastRatio(scheme.inversePrimary, p.inverseSurface),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });

  group('each shipped theme', () {
    test('has an expectation', () {
      expect(_expected.keys.toSet(), {for (final t in adminThemes) t.name});
    });

    for (final theme in adminThemes) {
      test('${theme.name} takes its reference inverse surface', () {
        final (light, dark) = _expected[theme.name]!;
        for (final (want, tokens) in [
          (light, theme.tokens),
          (dark, theme.dark!),
        ]) {
          final p = tokens.palette;
          expect(
            (p.inverseSurface, p.onInverseSurface),
            want ?? (p.foreground, p.surface),
            reason: '${p.brightness}',
          );
        }
      });

      test('${theme.name}: a brand keeps the inverse surface', () {
        final branded = theme.branded('Test Teal', const Color(0xFF0D9488));
        for (final (tokens, source) in [
          (branded.tokens, theme.tokens),
          (branded.dark!, theme.dark!),
        ]) {
          final (p, s) = (tokens.palette, source.palette);
          // A derived surface follows the foreground, which a brand leaves.
          expect(p.inverseSurface, s.inverseSurface);
          expect(p.onInverseSurface, s.onInverseSurface);
        }
      });
    }

    test('Ant\'s dark sider shows the page\'s tooltip', () {
      expect(antSiderPalette.inverseSurface, antPalette.inverseSurface);
      expect(antSiderPalette.onInverseSurface, antPalette.onInverseSurface);
    });

    test(
      'text reads on the inverse surface in every theme, mode and brand',
      () {
        for (final theme in adminThemes) {
          for (final (mode, tokens) in [
            ('light', theme.tokens),
            ('dark', theme.dark!),
          ]) {
            for (final MapEntry(key: brand, value: seed) in _brands.entries) {
              final p = (seed == null ? tokens : tokens.branded(seed)).palette;
              final reason = '${theme.name} $mode $brand';
              expect(
                contrastRatio(p.onInverseSurface, p.inverseSurface),
                greaterThanOrEqualTo(4.5),
                reason: reason,
              );
              expect(
                contrastRatio(p.colorScheme.inversePrimary, p.inverseSurface),
                greaterThanOrEqualTo(4.5),
                reason: '$reason: a snack bar\'s action',
              );
            }
          }
        }
      },
    );
  });

  group('widgets', () {
    for (final theme in adminThemes) {
      testWidgets('${theme.name}: a Tip is drawn on the inverse surface', (
        tester,
      ) async {
        for (final tokens in [theme.tokens, theme.dark!]) {
          final p = tokens.palette;
          final delay =
              tokens.overlay.tooltipDelay + const Duration(milliseconds: 20);

          await tester.pumpWidget(
            _host(tokens, const Tip(message: 'Archive', child: Text('target'))),
          );
          await tester.pumpAndSettle();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(tester.getCenter(find.text('target')));
          await tester.pump(delay);
          await tester.pumpAndSettle();

          final message = find.text('Archive');
          expect(message, findsOneWidget, reason: '${p.brightness}');
          expect(
            tester.renderObject<RenderParagraph>(message).text.style!.color,
            p.onInverseSurface,
          );
          final chip = tester.widget<Container>(
            find.ancestor(of: message, matching: find.byType(Container)).first,
          );
          expect(_fillOf(chip.decoration!), p.inverseSurface);

          // Off the target and back onto one with a shortcut, which is
          // quieter than the message and still reads on the chip.
          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle();
          await tester.pumpWidget(
            _host(
              tokens,
              const Tip(
                message: 'Archive',
                shortcut: 'E',
                child: Text('target'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await mouse.moveTo(tester.getCenter(find.text('target')));
          await tester.pump(delay);
          await tester.pumpAndSettle();
          final keys = tester
              .renderObject<RenderParagraph>(find.text('E'))
              .text
              .style!
              .color!;
          expect(
            contrastRatio(keys, p.inverseSurface),
            greaterThanOrEqualTo(4.5),
            reason: '${p.brightness}',
          );

          await mouse.removePointer();
          await tester.pumpWidget(_host(tokens, const SizedBox()));
          await tester.pumpAndSettle();
        }
      });

      test('${theme.name}: stock tooltips and snack bars take it', () {
        for (final tokens in [theme.tokens, theme.dark!]) {
          final p = tokens.palette;
          final data = buildAppTheme(tokens);
          final chip = data.tooltipTheme.decoration! as BoxDecoration;
          expect(chip.color, p.inverseSurface);
          expect(data.tooltipTheme.textStyle!.color, p.onInverseSurface);
          expect(data.snackBarTheme.backgroundColor, p.inverseSurface);
          expect(
            data.snackBarTheme.contentTextStyle!.color,
            p.onInverseSurface,
          );
          expect(data.snackBarTheme.closeIconColor, p.onInverseSurface);
          expect(
            contrastRatio(
              data.snackBarTheme.actionTextColor!,
              p.inverseSurface,
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    }

    testWidgets('a tip inside a chrome palette takes that palette\'s', (
      tester,
    ) async {
      // Ant's sider is drawn in a palette of its own.
      final tokens = antTheme.tokens;
      final sider = tokens.shell.sidebarPalette!;
      await tester.pumpWidget(
        _host(
          tokens,
          Theme(
            data: buildAppTheme(tokens.copyWith(palette: sider)),
            child: const Tip(message: 'Orders', child: Text('target')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _hover(tester, find.text('target'));
      await tester.pump(
        tokens.overlay.tooltipDelay + const Duration(milliseconds: 20),
      );
      await tester.pumpAndSettle();
      final chip = tester.widget<Container>(
        find
            .ancestor(of: find.text('Orders'), matching: find.byType(Container))
            .first,
      );
      expect(_fillOf(chip.decoration!), sider.inverseSurface);
      expect(sider.inverseSurface, const Color(0xFF262626));
    });
  });
}
