import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Each shipped theme's slider, from its reference: the track's height, the
/// thumb and its size, the rail's colour, and what the rest is drawn in.
const _expected = {
  // a 4px track under an 18px disc
  'Iris': AdminSliderStyle(),
  // a 16dp track parted by a 4×44dp handle, secondaryContainer past it
  'Material': AdminSliderStyle(
    trackHeight: 16,
    thumb: SliderThumb.bar,
    thumbSize: 44,
    rail: SliderRail.soft,
  ),
  // h-1.5 under a size-4 thumb, bg-white in a 1px border-primary
  'shadcn': AdminSliderStyle(
    trackHeight: 6,
    thumb: SliderThumb.ringed,
    thumbSize: 16,
    thumbRing: 1,
  ),
  // railSize 4 under a 10px handle ringed 2: 14 across
  'Ant': AdminSliderStyle(
    thumb: SliderThumb.ringed,
    thumbSize: 14,
    thumbRing: 2,
  ),
  // a 4px colorNeutralStrokeAccessible rail under a 20px thumb, the brand
  // inside a band a fifth of it wide
  'Fluent': AdminSliderStyle(
    thumb: SliderThumb.inset,
    thumbSize: 20,
    thumbRing: 4,
    rail: SliderRail.control,
  ),
  // a 2px track under a 14px thumb, in $layer-selected-inverse
  'Carbon': AdminSliderStyle(
    trackHeight: 2,
    thumbSize: 14,
    ink: SelectionInk.foreground,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("the defaults are the kit's own: a 4px track under an 18px disc", () {
    const style = AdminSliderStyle();
    expect(style.trackHeight, 4);
    expect((style.thumb, style.thumbSize), (SliderThumb.disc, 18));
    expect(style.rail, SliderRail.border);
    expect(style.ink, SelectionInk.accent);
  });

  test('a ring that leaves no thumb, or no track, is refused', () {
    expect(
      () => AdminSliderStyle(thumbSize: 16, thumbRing: 8),
      throwsAssertionError,
    );
    expect(() => AdminSliderStyle(thumbRing: -1), throwsAssertionError);
    expect(() => AdminSliderStyle(trackHeight: 0), throwsAssertionError);
    expect(() => AdminSliderStyle(thumbSize: 0), throwsAssertionError);
  });

  test('copyWith, lerp, == and toString', () {
    const style = AdminSliderStyle();
    final material = _expected['Material']!;
    final fluent = _expected['Fluent']!;
    expect(style.copyWith(), style);
    expect(style.copyWith().hashCode, style.hashCode);
    expect(
      style.copyWith(
        trackHeight: 16,
        thumb: SliderThumb.bar,
        thumbSize: 44,
        rail: SliderRail.soft,
      ),
      material,
    );
    expect(
      style.copyWith(
        thumb: SliderThumb.inset,
        thumbSize: 20,
        thumbRing: 4,
        rail: SliderRail.control,
      ),
      fluent,
    );
    expect(style.copyWith(ink: SelectionInk.foreground), isNot(style));
    expect(material, isNot(style));
    expect(material.hashCode, isNot(style.hashCode));

    expect(AdminSliderStyle.lerp(style, material, 0), style);
    expect(AdminSliderStyle.lerp(style, material, 1), material);
    final mid = AdminSliderStyle.lerp(style, material, 0.5);
    expect((mid.trackHeight, mid.thumbSize), (10, 31));
    expect(mid.thumb, SliderThumb.bar);
    expect(AdminSliderStyle.lerp(style, material, 0.4).thumb, SliderThumb.disc);
    expect(AdminSliderStyle.lerp(style, fluent, 0.5).thumbRing, 3);
    expect(AdminSliderStyle.lerp(style, fluent, 0.6).rail, SliderRail.control);

    expect('$style', isNot(contains('ring')));
    expect('$material', allOf(contains('bar 44.0'), contains('soft rail')));
    expect(
      '$fluent',
      allOf(contains('inset 20.0 ring 4.0'), contains('accent')),
    );
  });

  test('AdminTokens carry it through from, copyWith, lerp and ==', () {
    final fluent = _expected['Fluent']!;
    final plain = AdminTokens.from(palette: irisPalette);
    final tokens = AdminTokens.from(palette: irisPalette, slider: fluent);
    expect(plain.slider, const AdminSliderStyle());
    expect(tokens.slider, fluent);
    expect(plain.copyWith(slider: fluent), tokens);
    expect(tokens, isNot(plain));
    expect(tokens.hashCode, plain.copyWith(slider: fluent).hashCode);
    expect(tokens.branded(const Color(0xFF0D9488)).slider, fluent);
    expect(plain.lerp(tokens, 0.5).slider.thumbSize, 19);
  });

  test('AdminTheme.from gives both modes the slider anatomy', () {
    final style = _expected['Carbon']!;
    final theme = AdminTheme.from(
      name: 'Test',
      palette: irisPalette,
      dark: irisDarkPalette,
      slider: style,
    );
    expect(theme.tokens.slider, style);
    expect(theme.dark!.slider, style);
    expect(
      theme.branded('Test Teal', const Color(0xFF0D9488)).dark!.slider,
      style,
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system', () {
        final expected = _expected[theme.name];
        expect(expected, isNotNull, reason: 'a theme with no expectation');
        expect(theme.tokens.slider, expected);
        expect(theme.dark!.slider, expected);
      });
    }
  });

  testWidgets('context.sliderStyle reads the active theme’s', (tester) async {
    const style = AdminSliderStyle(trackHeight: 6);
    late AdminSliderStyle read;
    await tester.pumpWidget(
      Theme(
        data: buildAppTheme(
          AdminTokens.from(palette: irisPalette, slider: style),
        ),
        child: Builder(
          builder: (context) {
            read = context.sliderStyle;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, style);
  });

  test('what it is drawn in', () {
    final p = carbonPalette;
    const accent = AdminSliderStyle();
    expect(accent.inkOf(p), p.controlAccent);
    expect(accent.onInkOf(p), p.onControlAccent);
    expect(accent.railOf(p), p.border);

    const neutral = AdminSliderStyle(ink: SelectionInk.foreground);
    for (final palette in [p, p.branded(const Color(0xFFD97706))]) {
      expect(neutral.inkOf(palette), palette.foreground);
      expect(neutral.onInkOf(palette), const Color(0xFFFFFFFF));
    }
    expect(
      const AdminSliderStyle(rail: SliderRail.control).railOf(p),
      p.controlBorder,
    );
    expect(const AdminSliderStyle(rail: SliderRail.soft).railOf(p), p.softFill);
  });

  group('each theme marks its slider at 3:1', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          test('${theme.name} $mode $brand', () {
            final t = seed == null ? tokens : tokens.branded(seed);
            final p = t.palette;
            final style = t.slider;
            final ink = style.inkOf(p);
            for (final (name, ground) in [
              ('surface', p.surface),
              ('background', p.background),
            ]) {
              expect(
                contrastRatio(ink, ground),
                greaterThanOrEqualTo(3),
                reason: 'the track and thumb on the $name',
              );
            }
            expect(
              contrastRatio(style.onInkOf(p), ink),
              greaterThanOrEqualTo(3),
              reason: 'a tick mark on the track',
            );
            // A ringed thumb is the surface colour inside the ink; an inset
            // one is the ink inside the surface colour.
            expect(
              contrastRatio(ink, p.surface),
              greaterThanOrEqualTo(3),
              reason: 'the thumb’s ink against its surface-coloured part',
            );
          });
        }
      }
    }
  });
}
