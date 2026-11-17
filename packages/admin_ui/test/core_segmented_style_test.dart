import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Each shipped theme's segmented control, from its reference: the variant,
/// the knob's inset, whether the track and knob are ringed, Fluent's pill,
/// M3's check, Carbon's inverse fill and corner, and the label weight.
const _expected = {
  // a track, its knob ringed 3 in
  'Iris': AdminSegmentedStyle(),
  // the segmented button: outlined, checked, labelLarge
  'Material': AdminSegmentedStyle(
    variant: SegmentedVariant.joined,
    checkmark: true,
  ),
  // the tabs list: p-[3px], a knob lifted by shadow-sm
  'shadcn': AdminSegmentedStyle(knobOutline: false),
  // Segmented: trackPadding 2, a thumb lifted by boxShadowTertiary
  'Ant': AdminSegmentedStyle(
    inset: 2,
    knobOutline: false,
    labelWeight: FontWeight.w400,
  ),
  // Segmented: an outlined track, a raised item over an accent pill
  'Fluent': AdminSegmentedStyle(
    inset: 2,
    trackOutline: true,
    indicator: true,
    labelWeight: FontWeight.w400,
  ),
  // the high-contrast content switcher, rounded 4
  'Carbon': AdminSegmentedStyle(
    variant: SegmentedVariant.joined,
    inverse: true,
    radius: 4,
    labelWeight: FontWeight.w400,
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("the defaults are the kit's own: a track, its knob ringed 3 in", () {
    const style = AdminSegmentedStyle();
    expect(style.variant, SegmentedVariant.track);
    expect(style.inset, 3);
    expect(style.knobOutline, isTrue);
    expect(
      (
        style.trackOutline,
        style.indicator,
        style.checkmark,
        style.inverse,
        style.radius,
      ),
      (false, false, false, false, null),
    );
    expect(style.labelWeight, FontWeight.w500);
  });

  test('value semantics', () {
    const style = AdminSegmentedStyle();
    const carbon = AdminSegmentedStyle(
      variant: SegmentedVariant.joined,
      inset: 0,
      inverse: true,
      radius: 4,
    );
    expect(style.copyWith(), style);
    expect(style.copyWith().hashCode, style.hashCode);
    expect(style.copyWith(indicator: true), isNot(style));
    expect(
      style.copyWith(
        variant: SegmentedVariant.joined,
        inset: 0,
        inverse: true,
        radius: 4,
      ),
      carbon,
    );
    final mid = AdminSegmentedStyle.lerp(style, carbon, 0.5);
    expect(mid.inset, 1.5);
    expect(mid.variant, SegmentedVariant.joined, reason: 'nearer at 0.5');
    expect(mid.radius, 4, reason: 'a missing corner is not lerped from');
    expect(
      AdminSegmentedStyle.lerp(style, carbon, 0.4).variant,
      SegmentedVariant.track,
    );
    expect(
      AdminSegmentedStyle.lerp(carbon, carbon.copyWith(radius: 8), 0.5).radius,
      6,
    );
    expect('$carbon', allOf(contains('joined'), contains('inverse')));
  });

  test('AdminTokens carry it through from, copyWith, lerp and ==', () {
    const fluent = AdminSegmentedStyle(inset: 2, indicator: true);
    final plain = AdminTokens.from(palette: irisPalette);
    final tokens = AdminTokens.from(palette: irisPalette, segmented: fluent);
    expect(plain.segmented, const AdminSegmentedStyle());
    expect(tokens.segmented, fluent);
    expect(plain.copyWith(segmented: fluent), tokens);
    expect(tokens, isNot(plain));
    expect(tokens.hashCode, plain.copyWith(segmented: fluent).hashCode);
    expect(tokens.branded(const Color(0xFF0D9488)).segmented, fluent);
    expect(plain.lerp(tokens, 0.5).segmented.inset, 2.5);
  });

  test('AdminTheme.from gives both modes the segmented anatomy', () {
    const style = AdminSegmentedStyle(variant: SegmentedVariant.joined);
    final theme = AdminTheme.from(
      name: 'Test',
      palette: irisPalette,
      dark: irisDarkPalette,
      segmented: style,
    );
    expect(theme.tokens.segmented, style);
    expect(theme.dark!.segmented, style);
    expect(
      theme.branded('Test Teal', const Color(0xFF0D9488)).dark!.segmented,
      style,
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system', () {
        final expected = _expected[theme.name];
        expect(expected, isNotNull, reason: 'a theme with no expectation');
        expect(theme.tokens.segmented, expected);
        expect(theme.dark!.segmented, expected);
      });
    }
  });

  testWidgets('context.segmentedStyle reads the active theme’s', (
    tester,
  ) async {
    const style = AdminSegmentedStyle(checkmark: true);
    late AdminSegmentedStyle read;
    await tester.pumpWidget(
      Theme(
        data: buildAppTheme(
          AdminTokens.from(palette: irisPalette, segmented: style),
        ),
        child: Builder(
          builder: (context) {
            read = context.segmentedStyle;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, style);
  });
}
