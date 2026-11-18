import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Each shipped theme's switch, checkbox and radio, from its reference: the
/// track and the knob, how the off track is drawn and what fills the on one,
/// the box, the radio's size and mark, and what they are drawn in.
const _expected = {
  // a 36×20 switch, an 18px box, an 18px disc around an 8px dot
  'Iris': AdminSelectionStyle(),
  // Switch: 52×32, a 16dp handle that grows to 24, outlined over
  // surfaceContainerHighest; an onSurfaceVariant outline; a 20dp radio
  // button, a ring around a 10dp dot
  'Material': AdminSelectionStyle(
    toggleWidth: 52,
    toggleHeight: 32,
    toggleKnob: 16,
    toggleKnobOn: 24,
    toggleOff: ToggleOffStyle.tonal,
    radioSize: 20,
    radioMark: RadioMark.dot,
    radioDot: 10,
    outline: SelectionOutline.secondary,
  ),
  // Switch h-[1.15rem] w-8 with a size-4 thumb; size-4 checkbox and radio
  'shadcn': AdminSelectionStyle(
    toggleWidth: 32,
    toggleHeight: 18,
    toggleKnob: 16,
    checkSize: 16,
    radioSize: 16,
    radioDot: 8,
  ),
  // Switch 44×22 with an 18px handle; a 16px Checkbox; a 16px Radio around
  // a 6px dot
  'Ant': AdminSelectionStyle(
    toggleWidth: 44,
    toggleHeight: 22,
    toggleKnob: 18,
    checkSize: 16,
    radioSize: 16,
    radioDot: 6,
  ),
  // Switch 40×20, outlined while off, a 14px thumb; 16px Checkbox and Radio,
  // a ring around a 10px dot
  'Fluent': AdminSelectionStyle(
    toggleWidth: 40,
    toggleHeight: 20,
    toggleKnob: 14,
    toggleOff: ToggleOffStyle.outlined,
    checkSize: 16,
    radioSize: 16,
    radioMark: RadioMark.dot,
    radioDot: 10,
  ),
  // Toggle 48×24, $support-success while on, an 18px knob; a 16px checkbox
  // and an 18px radio button in $icon-primary, a ring around an 8px dot
  'Carbon': AdminSelectionStyle(
    toggleWidth: 48,
    toggleHeight: 24,
    toggleKnob: 18,
    toggleOn: ToggleOnColor.success,
    checkSize: 16,
    radioMark: RadioMark.dot,
    radioDot: 8,
    ink: SelectionInk.foreground,
    outline: SelectionOutline.foreground,
  ),
};

/// The outline of an unchecked box and an unselected radio, per theme: the
/// reference's own width.
const _outlineWidths = {
  'Iris': 1.5,
  'Material': 2.0,
  'shadcn': 1.0,
  'Ant': 1.0,
  'Fluent': 1.0,
  'Carbon': 1.0,
};

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("the defaults are the kit's own", () {
    const style = AdminSelectionStyle();
    expect(
      (style.toggleWidth, style.toggleHeight, style.toggleKnob),
      (36, 20, 16),
    );
    expect(style.toggleKnobOn, isNull);
    expect(style.toggleKnobSlot, 16);
    expect(style.toggleOff, ToggleOffStyle.filled);
    expect(style.toggleOn, ToggleOnColor.accent);
    expect(style.checkSize, 18);
    expect(
      (style.radioSize, style.radioMark, style.radioDot),
      (18, RadioMark.disc, 8),
    );
    expect(style.ink, SelectionInk.accent);
    expect(style.outline, SelectionOutline.control);
  });

  test('the knob travels in the larger of its two sizes', () {
    expect(
      const AdminSelectionStyle(
        toggleKnob: 12,
        toggleKnobOn: 18,
      ).toggleKnobSlot,
      18,
    );
    expect(
      const AdminSelectionStyle(
        toggleKnob: 16,
        toggleKnobOn: 12,
      ).toggleKnobSlot,
      16,
    );
  });

  test('a knob taller than its track, or a dot as wide as its radio, is '
      'refused', () {
    expect(
      () => AdminSelectionStyle(toggleHeight: 20, toggleKnob: 22),
      throwsAssertionError,
    );
    expect(
      () => AdminSelectionStyle(toggleHeight: 20, toggleKnobOn: 22),
      throwsAssertionError,
    );
    expect(
      () => AdminSelectionStyle(toggleWidth: 16, toggleHeight: 20),
      throwsAssertionError,
    );
    expect(
      () => AdminSelectionStyle(radioSize: 16, radioDot: 16),
      throwsAssertionError,
    );
  });

  test('copyWith, lerp, == and toString', () {
    const style = AdminSelectionStyle();
    final material = _expected['Material']!;
    final carbon = _expected['Carbon']!;
    expect(style.copyWith(), style);
    expect(style.copyWith().hashCode, style.hashCode);
    expect(
      style.copyWith(
        toggleWidth: 52,
        toggleHeight: 32,
        toggleKnob: 16,
        toggleKnobOn: 24,
        toggleOff: ToggleOffStyle.tonal,
        radioSize: 20,
        radioMark: RadioMark.dot,
        radioDot: 10,
        outline: SelectionOutline.secondary,
      ),
      material,
    );
    expect(
      style.copyWith(
        toggleWidth: 48,
        toggleHeight: 24,
        toggleKnob: 18,
        toggleOn: ToggleOnColor.success,
        checkSize: 16,
        radioMark: RadioMark.dot,
        ink: SelectionInk.foreground,
        outline: SelectionOutline.foreground,
      ),
      carbon,
    );
    expect(material, isNot(style));
    expect(material.hashCode, isNot(style.hashCode));

    expect(AdminSelectionStyle.lerp(style, material, 0), style);
    expect(AdminSelectionStyle.lerp(style, material, 1), material);
    final mid = AdminSelectionStyle.lerp(style, material, 0.5);
    expect((mid.toggleWidth, mid.toggleHeight, mid.toggleKnob), (44, 26, 16));
    // the side without a grown knob counts as its knob: 16 to 24
    expect(mid.toggleKnobOn, 20);
    expect((mid.checkSize, mid.radioSize, mid.radioDot), (18, 19, 9));
    expect(mid.toggleOff, ToggleOffStyle.tonal);
    expect(
      AdminSelectionStyle.lerp(style, material, 0.4).radioMark,
      RadioMark.disc,
    );
    expect(
      AdminSelectionStyle.lerp(style, carbon, 0.5).toggleKnobOn,
      isNull,
      reason: 'neither side grows its knob',
    );
    expect(AdminSelectionStyle.lerp(style, carbon, 0.6).ink, carbon.ink);

    expect(
      '$material',
      allOf(
        contains('52.0×32.0'),
        contains('16.0/24.0'),
        contains('tonal'),
        contains('dot'),
      ),
    );
    expect('$carbon', allOf(contains('success'), contains('foreground')));
  });

  test('AdminTokens carry it through from, copyWith, lerp and ==', () {
    final fluent = _expected['Fluent']!;
    final plain = AdminTokens.from(palette: irisPalette);
    final tokens = AdminTokens.from(palette: irisPalette, selection: fluent);
    expect(plain.selection, const AdminSelectionStyle());
    expect(tokens.selection, fluent);
    expect(plain.copyWith(selection: fluent), tokens);
    expect(tokens, isNot(plain));
    expect(tokens.hashCode, plain.copyWith(selection: fluent).hashCode);
    expect(tokens.branded(const Color(0xFF0D9488)).selection, fluent);
    expect(plain.lerp(tokens, 0.5).selection.toggleWidth, 38);
  });

  test('AdminTheme.from gives both modes the selection anatomy', () {
    final style = _expected['Carbon']!;
    final theme = AdminTheme.from(
      name: 'Test',
      palette: irisPalette,
      dark: irisDarkPalette,
      selection: style,
    );
    expect(theme.tokens.selection, style);
    expect(theme.dark!.selection, style);
    expect(
      theme.branded('Test Teal', const Color(0xFF0D9488)).dark!.selection,
      style,
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system', () {
        final expected = _expected[theme.name];
        expect(expected, isNotNull, reason: 'a theme with no expectation');
        expect(theme.tokens.selection, expected);
        expect(theme.dark!.selection, expected);
        final width = _outlineWidths[theme.name];
        expect(theme.tokens.stroke.controlStrong, width);
        expect(theme.dark!.stroke.controlStrong, width);
      });
    }
  });

  testWidgets('context.selectionStyle reads the active theme’s', (
    tester,
  ) async {
    const style = AdminSelectionStyle(checkSize: 16);
    late AdminSelectionStyle read;
    await tester.pumpWidget(
      Theme(
        data: buildAppTheme(
          AdminTokens.from(palette: irisPalette, selection: style),
        ),
        child: Builder(
          builder: (context) {
            read = context.selectionStyle;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, style);
  });

  group('what the controls are drawn in', () {
    const accent = AdminSelectionStyle();
    const neutral = AdminSelectionStyle(
      ink: SelectionInk.foreground,
      outline: SelectionOutline.foreground,
      toggleOn: ToggleOnColor.success,
    );
    final p = carbonPalette;

    test('the accent, by default', () {
      expect(accent.inkOf(p), p.controlAccent);
      expect(accent.inkOf(p, hovered: true), p.controlAccentHover);
      expect(accent.onInkOf(p), p.onControlAccent);
      expect(accent.outlineOf(p), p.controlBorder);
      expect(accent.toggleOnOf(p), p.controlAccent);
      expect(accent.toggleOnOf(p, hovered: true), p.controlAccentHover);
      expect(accent.toggleKnobOnOf(p), p.onControlAccent);
    });

    test('the foreground, and the success colour, whatever the brand', () {
      for (final palette in [p, p.branded(const Color(0xFFD97706))]) {
        expect(neutral.inkOf(palette), palette.foreground);
        expect(
          neutral.inkOf(palette, hovered: true),
          isNot(palette.foreground),
        );
        expect(neutral.onInkOf(palette), const Color(0xFFFFFFFF));
        expect(neutral.outlineOf(palette), palette.foreground);
        expect(neutral.toggleOnOf(palette), const Color(0xFF24A148));
        expect(neutral.toggleKnobOnOf(palette), palette.surface);
      }
      expect(
        const AdminSelectionStyle(outline: SelectionOutline.secondary)
            .outlineOf(p),
        p.foregroundSecondary,
      );
    });

    test('a success colour too near the page is moved to 3:1, hue kept', () {
      // a pale green, 1.4:1 on white
      final pale = irisPalette.copyWith(success: const Color(0xFFA7F3D0));
      final track = neutral.toggleOnOf(pale);
      expect(track, isNot(pale.success));
      for (final ground in [pale.surface, pale.background]) {
        expect(contrastRatio(track, ground), greaterThanOrEqualTo(3));
      }
      expect(
        HSLColor.fromColor(track).hue,
        closeTo(HSLColor.fromColor(pale.success).hue, 1),
      );
      expect(
        contrastRatio(neutral.toggleKnobOnOf(pale), track),
        greaterThanOrEqualTo(3),
      );
    });

    test('hovering never makes an outline fainter', () {
      for (final theme in adminThemes) {
        for (final palette in [theme.palette, theme.darkPalette!]) {
          for (final outline in SelectionOutline.values) {
            for (final ink in SelectionInk.values) {
              final style = AdminSelectionStyle(outline: outline, ink: ink);
              expect(
                contrastRatio(style.hoverOutlineOf(palette), palette.surface),
                greaterThanOrEqualTo(
                  contrastRatio(style.outlineOf(palette), palette.surface),
                ),
                reason:
                    '${theme.name} ${palette.brightness.name} '
                    '${outline.name} ${ink.name}',
              );
            }
          }
        }
      }
    });
  });

  group('each theme marks its controls at 3:1', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          test('${theme.name} $mode $brand', () {
            final t = seed == null ? tokens : tokens.branded(seed);
            final p = t.palette;
            final style = t.selection;
            void atLeast(double min, String what, Color color, Color on) {
              final ratio = contrastRatio(color, on);
              expect(
                ratio,
                greaterThanOrEqualTo(min),
                reason:
                    '$what: ${_hex(color)} on ${_hex(on)} is '
                    '${ratio.toStringAsFixed(2)}:1',
              );
            }

            for (final (name, ground) in [
              ('surface', p.surface),
              ('background', p.background),
            ]) {
              atLeast(3, 'outline on the $name', style.outlineOf(p), ground);
              atLeast(3, 'ink on the $name', style.inkOf(p), ground);
              atLeast(3, 'on track on the $name', style.toggleOnOf(p), ground);
              atLeast(
                3,
                'off ring and knob on the $name',
                p.controlBorder,
                ground,
              );
            }
            for (final hovered in [false, true]) {
              final state = hovered ? 'hovered' : 'resting';
              atLeast(
                3,
                'the glyph on the $state ink',
                style.onInkOf(p),
                style.inkOf(p, hovered: hovered),
              );
              atLeast(
                3,
                'the knob on the $state on track',
                style.toggleKnobOnOf(p),
                style.toggleOnOf(p, hovered: hovered),
              );
            }
            if (style.toggleOff == ToggleOffStyle.tonal) {
              atLeast(
                3,
                'the off knob on the tonal track',
                p.controlBorder,
                Color.alphaBlend(p.pressedOverlay, p.surface),
              );
            }
          });
        }
      }
    }
  });

  test('the stock Material controls follow the style', () {
    for (final theme in adminThemes) {
      final tokens = theme.tokens;
      final p = tokens.palette;
      final style = tokens.selection;
      final data = buildAppTheme(tokens);
      const on = {WidgetState.selected};
      const off = <WidgetState>{};
      final name = theme.name;
      expect(
        data.checkboxTheme.fillColor!.resolve(on),
        style.inkOf(p),
        reason: name,
      );
      expect(
        data.checkboxTheme.checkColor!.resolve(on),
        style.onInkOf(p),
        reason: name,
      );
      expect(data.checkboxTheme.side!.color, style.outlineOf(p), reason: name);
      expect(
        data.checkboxTheme.side!.width,
        tokens.stroke.controlStrong,
        reason: name,
      );
      expect(
        data.radioTheme.fillColor!.resolve(on),
        style.inkOf(p),
        reason: name,
      );
      expect(
        data.radioTheme.fillColor!.resolve(off),
        style.outlineOf(p),
        reason: name,
      );
      expect(
        data.switchTheme.trackColor!.resolve(on),
        style.toggleOnOf(p),
        reason: name,
      );
      expect(
        data.switchTheme.thumbColor!.resolve(on),
        style.toggleKnobOnOf(p),
        reason: name,
      );
      expect(data.switchTheme.trackColor!.resolve(off), p.border, reason: name);
    }
  });
}
