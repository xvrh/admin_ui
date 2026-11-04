import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Each shipped theme's tooltip and arrow, from its reference: whether a
/// tooltip points at its target, the width it wraps at, and the arrow's
/// base and height.
const _expected = {
  'Iris': (false, 280.0, 12.0, 6.0),
  'Material': (false, 200.0, 12.0, 6.0), // PlainTooltipMaxWidth, no arrow
  'shadcn': (true, 280.0, 10.0, 5.0), // Radix's 10×5 Arrow
  'Ant': (true, 250.0, 16.0, 8.0), // maxWidth 250, sizePopupArrow 16
  'Fluent': (true, 240.0, 12.0, 6.0), // maxWidth 240px, arrowHeight 6
  'Carbon': (true, 288.0, 12.0, 6.0), // 18rem, the 0.75rem × 0.375rem caret
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("the defaults are the kit's own: a plain chip at 280, a 12×6 arrow", () {
    const style = AdminOverlayStyle();
    expect(
      (
        style.tooltipArrow,
        style.tooltipMaxWidth,
        style.arrowWidth,
        style.arrowHeight,
      ),
      (false, 280.0, 12.0, 6.0),
    );
  });

  test('value semantics', () {
    const style = AdminOverlayStyle();
    const ant = AdminOverlayStyle(
      tooltipArrow: true,
      tooltipMaxWidth: 250,
      arrowWidth: 16,
      arrowHeight: 8,
    );
    expect(style.copyWith(), style);
    expect(style.copyWith().hashCode, style.hashCode);
    expect(style.copyWith(tooltipArrow: true), isNot(style));
    expect(
      style.copyWith(
        tooltipArrow: true,
        tooltipMaxWidth: 250,
        arrowWidth: 16,
        arrowHeight: 8,
      ),
      ant,
    );
    final mid = AdminOverlayStyle.lerp(style, ant, 0.5);
    expect(
      (mid.tooltipMaxWidth, mid.arrowWidth, mid.arrowHeight),
      (265.0, 14.0, 7.0),
    );
    expect(mid.tooltipArrow, isTrue, reason: 'the nearer side at 0.5');
    expect(AdminOverlayStyle.lerp(style, ant, 0.4).tooltipArrow, isFalse);
    expect('$ant', contains('16.0×8.0'));
  });

  test('AdminTokens carry it through from, copyWith, lerp and ==', () {
    const ant = AdminOverlayStyle(tooltipArrow: true, tooltipMaxWidth: 250);
    final plain = AdminTokens.from(palette: irisPalette);
    final tokens = AdminTokens.from(palette: irisPalette, overlay: ant);
    expect(plain.overlay, const AdminOverlayStyle());
    expect(tokens.overlay, ant);
    expect(plain.copyWith(overlay: ant), tokens);
    expect(tokens, isNot(plain));
    expect(tokens.hashCode, plain.copyWith(overlay: ant).hashCode);
    expect(tokens.branded(const Color(0xFF0D9488)).overlay, ant);
    expect(plain.lerp(tokens, 0.5).overlay.tooltipMaxWidth, 265);
  });

  test('AdminTheme.from gives both modes the overlay', () {
    const style = AdminOverlayStyle(arrowWidth: 20);
    final theme = AdminTheme.from(
      name: 'Test',
      palette: irisPalette,
      dark: irisDarkPalette,
      overlay: style,
    );
    expect(theme.tokens.overlay, style);
    expect(theme.dark!.overlay, style);
    expect(
      theme.branded('Test Teal', const Color(0xFF0D9488)).dark!.overlay,
      style,
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system', () {
        final expected = _expected[theme.name];
        expect(expected, isNotNull, reason: 'a theme with no expectation');
        for (final tokens in [theme.tokens, theme.dark!]) {
          final style = tokens.overlay;
          expect((
            style.tooltipArrow,
            style.tooltipMaxWidth,
            style.arrowWidth,
            style.arrowHeight,
          ), expected);
        }
      });
    }

    test('the tooltip wraps at the theme’s width', () {
      for (final theme in adminThemes) {
        final tokens = theme.tokens;
        final data = buildAppTheme(tokens);
        expect(
          data.tooltipTheme.constraints,
          BoxConstraints(maxWidth: _expected[theme.name]!.$2),
          reason: theme.name,
        );
      }
    });
  });

  testWidgets('context.overlayStyle reads the active theme’s', (tester) async {
    const style = AdminOverlayStyle(tooltipArrow: true, arrowHeight: 9);
    late AdminOverlayStyle read;
    await tester.pumpWidget(
      Theme(
        data: buildAppTheme(
          AdminTokens.from(palette: irisPalette, overlay: style),
        ),
        child: Builder(
          builder: (context) {
            read = context.overlayStyle;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, style);
  });
}
