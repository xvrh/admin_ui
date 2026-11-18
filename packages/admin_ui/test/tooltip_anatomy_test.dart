import 'dart:ui' show PointerDeviceKind;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A tooltip's corner, padding, text and delay, from the theme's
// AdminOverlayStyle: the stock tooltip theme that a Tip and a Tooltip both
// read.

/// Each shipped theme's tooltip, from its reference: its corner (null is the
/// theme's small radius), its padding across and down, its text and its
/// delay in milliseconds.
const _expected = {
  // the small radius, 8×4 around caption text, after 400ms
  'Iris': (null, 8.0, 4.0, TooltipText.caption, 400),
  // Flutter's M3 tooltip: a 4dp corner
  'Material': (4.0, 8.0, 4.0, TooltipText.caption, 400),
  // rounded-md px-3 py-1.5 text-xs, delayDuration 0
  'shadcn': (8.0, 12.0, 6.0, TooltipText.caption, 0),
  // borderRadius 6, `6px 8px`, the body's 14/22
  'Ant': (6.0, 8.0, 6.0, TooltipText.body, 400),
  // borderRadiusMedium, `5px 12px 7px 12px`, caption1
  'Fluent': (4.0, 12.0, 6.0, TooltipText.caption, 400),
  // 2px, $spacing-05 all round, body-01
  'Carbon': (2.0, 16.0, 16.0, TooltipText.body, 400),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("the defaults are the kit's own", () {
    const style = AdminOverlayStyle();
    expect(style.tooltipRadius, isNull);
    expect((style.tooltipPaddingX, style.tooltipPaddingY), (8, 4));
    expect(style.tooltipText, TooltipText.caption);
    expect(style.tooltipDelay, const Duration(milliseconds: 400));
  });

  test('a negative corner or padding is refused', () {
    expect(() => AdminOverlayStyle(tooltipRadius: -1), throwsAssertionError);
    expect(() => AdminOverlayStyle(tooltipPaddingX: -1), throwsAssertionError);
    expect(() => AdminOverlayStyle(tooltipPaddingY: -1), throwsAssertionError);
  });

  test('copyWith, lerp, == and toString carry the tooltip', () {
    const style = AdminOverlayStyle();
    const carbon = AdminOverlayStyle(
      tooltipRadius: 2,
      tooltipPaddingX: 16,
      tooltipPaddingY: 16,
      tooltipText: TooltipText.body,
      tooltipDelay: Duration.zero,
    );
    expect(
      style.copyWith(
        tooltipRadius: 2,
        tooltipPaddingX: 16,
        tooltipPaddingY: 16,
        tooltipText: TooltipText.body,
        tooltipDelay: Duration.zero,
      ),
      carbon,
    );
    expect(carbon, isNot(style));
    expect(carbon.hashCode, isNot(style.hashCode));
    for (final one in [
      style.copyWith(tooltipRadius: 4),
      style.copyWith(tooltipPaddingX: 12),
      style.copyWith(tooltipPaddingY: 6),
      style.copyWith(tooltipText: TooltipText.body),
      style.copyWith(tooltipDelay: Duration.zero),
    ]) {
      expect(one, isNot(style));
    }

    final mid = AdminOverlayStyle.lerp(style, carbon, 0.5);
    expect((mid.tooltipPaddingX, mid.tooltipPaddingY), (12, 10));
    // one side derives its corner: the nearer side's, not a blend
    expect(mid.tooltipRadius, 2);
    expect(AdminOverlayStyle.lerp(style, carbon, 0.4).tooltipRadius, isNull);
    expect(
      AdminOverlayStyle.lerp(
        carbon,
        carbon.copyWith(tooltipRadius: 6),
        0.5,
      ).tooltipRadius,
      4,
    );
    expect(mid.tooltipText, TooltipText.body);
    expect(mid.tooltipDelay, Duration.zero);
    expect(
      AdminOverlayStyle.lerp(style, carbon, 0.4).tooltipDelay,
      const Duration(milliseconds: 400),
    );

    expect(
      '$style',
      allOf(
        contains('the small radius'),
        contains('caption text'),
        contains('400ms'),
      ),
    );
    expect(
      '$carbon',
      allOf(
        contains('radius 2.0'),
        contains('16.0×16.0'),
        contains('body text'),
      ),
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system’s tooltip', () {
        final expected = _expected[theme.name];
        expect(expected, isNotNull, reason: 'a theme with no expectation');
        for (final tokens in [theme.tokens, theme.dark!]) {
          final style = tokens.overlay;
          expect((
            style.tooltipRadius,
            style.tooltipPaddingX,
            style.tooltipPaddingY,
            style.tooltipText,
            style.tooltipDelay.inMilliseconds,
          ), expected);
        }
      });

      test('${theme.name}: the stock tooltip theme draws it', () {
        final (radius, padX, padY, text, delay) = _expected[theme.name]!;
        for (final tokens in [theme.tokens, theme.dark!]) {
          final data = buildAppTheme(tokens).tooltipTheme;
          final chip = data.decoration! as BoxDecoration;
          expect(
            chip.borderRadius,
            BorderRadius.circular(radius ?? tokens.radii.radiusSmall),
          );
          expect(
            data.padding,
            EdgeInsets.symmetric(horizontal: padX, vertical: padY),
          );
          expect(data.waitDuration, Duration(milliseconds: delay));
          final type = tokens.typography;
          final style = switch (text) {
            TooltipText.caption => type.caption,
            TooltipText.body => type.body,
          };
          expect(data.textStyle!.fontSize, style.fontSize);
          expect(data.textStyle!.height, style.height);
          // the inverse chip: the surface colour on the foreground
          expect(data.textStyle!.color, tokens.palette.surface);
          expect(chip.color, tokens.palette.foreground);
          expect(
            contrastRatio(data.textStyle!.color!, chip.color!),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    }

    test('a corner of its own leaves the small radius to menu items', () {
      // The corner was the small radius, which each theme sets for other
      // parts: 8, 6, 4, 2 and 0 where the references round 4, 8, 6, 4 and 2.
      expect(materialTheme.tokens.radii.radiusSmall, 8);
      expect(materialTheme.tokens.overlay.tooltipRadius, 4);
      expect(carbonTheme.tokens.radii.radiusSmall, 0);
      expect(carbonTheme.tokens.overlay.tooltipRadius, 2);
    });
  });

  group('a Tip', () {
    Widget host(AdminOverlayStyle style) => MaterialApp(
      theme: buildAppTheme(
        AdminTokens.from(palette: irisPalette, overlay: style),
      ),
      home: const Scaffold(
        body: Center(
          child: Tip(message: 'Archive', child: Text('target')),
        ),
      ),
    );

    Future<void> hover(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('target')));
      await tester.pump();
    }

    testWidgets('shows after the theme’s delay', (tester) async {
      await tester.pumpWidget(host(const AdminOverlayStyle()));
      await hover(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Archive'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('shows at once where the theme has no delay', (tester) async {
      await tester.pumpWidget(
        host(const AdminOverlayStyle(tooltipDelay: Duration.zero)),
      );
      await hover(tester);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('its own waitDuration still wins', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(
            AdminTokens.from(
              palette: irisPalette,
              overlay: const AdminOverlayStyle(tooltipDelay: Duration.zero),
            ),
          ),
          home: const Scaffold(
            body: Center(
              child: Tip(
                message: 'Archive',
                waitDuration: Duration(milliseconds: 600),
                child: Text('target'),
              ),
            ),
          ),
        ),
      );
      await hover(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Archive'), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('draws the theme’s corner, padding and text', (tester) async {
      const style = AdminOverlayStyle(
        tooltipRadius: 2,
        tooltipPaddingX: 16,
        tooltipPaddingY: 16,
        tooltipText: TooltipText.body,
        tooltipDelay: Duration.zero,
      );
      await tester.pumpWidget(host(style));
      await hover(tester);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      final message = find.text('Archive');
      final type = defaultTokens.typography;
      expect(
        tester.renderObject<RenderParagraph>(message).text.style!.fontSize,
        type.body.fontSize,
      );
      // The chip is its text and the padding around it.
      final chip = tester.getRect(
        find.ancestor(of: message, matching: find.byType(Container)).first,
      );
      final text = tester.getRect(message);
      expect(text.left - chip.left, 16);
      expect(text.top - chip.top, 16);
    });
  });
}
