import 'package:admin_ui/admin_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _teal = Color(0xFF0D9488);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // First, before any token read below has built a theme's typography.
  test('listing, reading palettes and branding resolve no font', () {
    var resolved = 0;
    AdminFonts.resolver = (_, _) {
      resolved++;
      return null;
    };
    addTearDown(() => AdminFonts.resolver = null);
    for (final theme in adminThemes) {
      final branded = theme.branded('${theme.name} Teal', _teal);
      expect([theme.hasDark, branded.hasDark], [true, true]);
      expect(theme.palette.surface, isNotNull);
      expect(branded.darkPalette!.primary, isNot(theme.darkPalette!.primary));
    }
    expect(resolved, 0);
  });

  group('AdminTheme.from', () {
    const radii = AdminRadii(radiusSmall: 3, radius: 5, radiusLarge: 7);
    const type = AdminTypeSpec(
      fontFamily: 'Test Sans',
      heading: FontWeight.w500,
    );
    const focus = AdminFocusSpec(width: 3, offset: 1);
    const elevation = AdminElevation(sm: [], md: [], lg: []);

    test('builds the same tokens AdminTokens.from does, once', () {
      final theme = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        radii: radii,
        type: type,
        focus: focus,
      );
      _expectSameTokens(
        theme.tokens,
        AdminTokens.from(
          palette: irisPalette,
          radii: radii,
          type: type,
          focus: focus,
        ),
      );
      _expectSameTokens(
        theme.dark!,
        AdminTokens.from(
          palette: irisDarkPalette,
          radii: radii,
          type: type,
          focus: focus,
        ),
      );
      expect(theme.tokens.elevation, same(defaultElevation));
      expect(theme.dark!.elevation, same(defaultDarkElevation));
      expect(theme.tokens, same(theme.tokens));
      expect(theme.dark, same(theme.dark));
    });

    test('gives each mode its own elevation', () {
      final theme = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        darkElevation: elevation,
      );
      expect(theme.tokens.elevation, same(defaultElevation));
      expect(theme.dark!.elevation, same(elevation));
      final light = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        elevation: elevation,
      );
      expect(light.tokens.elevation, same(elevation));
      expect(light.dark!.elevation, same(defaultDarkElevation));
    });

    test('a light-only theme has no dark set', () {
      final theme = AdminTheme.from(name: 'Test', palette: irisPalette);
      expect(theme.hasDark, isFalse);
      expect(theme.dark, isNull);
      expect(theme.darkPalette, isNull);
      expect(theme.branded('Brand', _teal).hasDark, isFalse);
    });

    test('branded keeps the name it is given and brands lazily', () {
      final theme = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        radii: radii,
        type: type,
        focus: focus,
      );
      final branded = theme.branded('Acme', _teal);
      expect(branded.name, 'Acme');
      expect(branded, isNot(theme));
      _expectSameTokens(branded.tokens, theme.tokens.branded(_teal));
      _expectSameTokens(branded.dark!, theme.dark!.branded(_teal));
    });

    test('the const constructor still works', () {
      final theme = AdminTheme(name: 'Const', tokens: defaultTokens);
      expect(theme.palette, same(irisPalette));
      expect(theme.darkPalette, isNull);
      expect(theme.hasDark, isFalse);
      expect(theme.branded('Acme', _teal).name, 'Acme');
      expect(theme, AdminTheme.from(name: 'Const', palette: antPalette));
    });
  });

  group('shipped themes', () {
    const palettes = {
      'Iris': (irisPalette, irisDarkPalette),
      'Material': (materialPalette, materialDarkPalette),
      'shadcn': (shadcnPalette, shadcnDarkPalette),
      'Ant': (antPalette, antDarkPalette),
      'Fluent': (fluentPalette, fluentDarkPalette),
      'Carbon': (carbonPalette, carbonDarkPalette),
    };
    const focus = {
      'Iris': AdminFocusSpec(width: 2, offset: 2),
      'Material': AdminFocusSpec(width: 3, offset: 2),
      'shadcn': AdminFocusSpec(width: 3, offset: 0),
      'Ant': AdminFocusSpec(width: 2, offset: 2),
      // colorStrokeFocus2 with 1px of colorStrokeFocus1 inside
      'Fluent': AdminFocusSpec(width: 2, offset: 0, innerWidth: 1),
      'Carbon': AdminFocusSpec(width: 2, offset: -2),
    };
    // A menu's shadow (md), light then dark, each layer as (alpha, dy, blur,
    // spread); null for the kit's defaults.
    const menuShadow = {
      'Iris': null,
      'shadcn': null,
      // M3 level 2, in both modes
      'Material': (
        [(0x4D, 1.0, 2.0, 0.0), (0x26, 2.0, 6.0, 2.0)],
        [(0x4D, 1.0, 2.0, 0.0), (0x26, 2.0, 6.0, 2.0)],
      ),
      // boxShadowSecondary, which the dark algorithm keeps
      'Ant': (
        [
          (0x14, 6.0, 16.0, 0.0),
          (0x1F, 3.0, 6.0, -4.0),
          (0x0D, 9.0, 28.0, 8.0),
        ],
        [
          (0x14, 6.0, 16.0, 0.0),
          (0x1F, 3.0, 6.0, -4.0),
          (0x0D, 9.0, 28.0, 8.0),
        ],
      ),
      // shadow16, deeper in webDarkTheme
      'Fluent': (
        [(0x1F, 0.0, 2.0, 0.0), (0x24, 8.0, 16.0, 0.0)],
        [(0x3D, 0.0, 2.0, 0.0), (0x47, 8.0, 16.0, 0.0)],
      ),
      // 0 2px 6px $shadow: black at 30%, 80% in g100
      'Carbon': ([(0x4D, 2.0, 6.0, 0.0)], [(0xCC, 2.0, 6.0, 0.0)]),
    };
    List<(int, double, double, double)> layers(List<BoxShadow> shadows) => [
      for (final s in shadows)
        ((s.color.a * 255).round(), s.offset.dy, s.blurRadius, s.spreadRadius),
    ];

    test('are the six, uniquely named', () {
      expect(adminThemes.map((t) => t.name), palettes.keys);
    });

    for (final theme in adminThemes) {
      test('${theme.name} resolves its tokens from its own palettes', () {
        final (light, dark) = palettes[theme.name]!;
        final tokens = theme.tokens;
        final darkTokens = theme.dark!;
        expect(theme.palette, same(light));
        expect(theme.darkPalette, same(dark));
        expect(tokens.palette, same(light));
        expect(darkTokens.palette, same(dark));
        if (menuShadow[theme.name] case (final light, final dark)) {
          expect(layers(tokens.elevation.md), light);
          expect(layers(darkTokens.elevation.md), dark);
        } else {
          expect(tokens.elevation, same(defaultElevation));
          expect(darkTokens.elevation, same(defaultDarkElevation));
        }
        expect([
          tokens.focus,
          darkTokens.focus,
        ], everyElement(focus[theme.name]));
        expect(darkTokens.typography.spec, same(tokens.typography.spec));
        expect(tokens.typography.body.color, light.foreground);
        expect(darkTokens.typography.body.color, dark.foreground);
        final font = tokens.typography.spec.fontFamily;
        if (font != null) expect(tokens.typography.body.fontFamily, font);
      });

      test('${theme.name} branded keeps its name and structure', () {
        final branded = theme.branded('${theme.name} Teal', _teal);
        expect(branded.name, '${theme.name} Teal');
        expect(branded.palette.surface, theme.palette.surface);
        expect(branded.darkPalette!.surface, theme.darkPalette!.surface);
        expect(branded.palette.chart, theme.palette.chart);
        final tokens = branded.tokens;
        expect(tokens.focus, focus[theme.name]);
        expect(tokens.radii.radius, theme.tokens.radii.radius);
      });
    }
  });
}

void _expectSameTokens(AdminTokens actual, AdminTokens expected) {
  expect(actual.palette.primary, expected.palette.primary);
  expect(actual.palette.surface, expected.palette.surface);
  expect(actual.palette.primarySubtle, expected.palette.primarySubtle);
  expect(
    [actual.radii.radiusSmall, actual.radii.radius, actual.radii.radiusLarge],
    [
      expected.radii.radiusSmall,
      expected.radii.radius,
      expected.radii.radiusLarge,
    ],
  );
  final a = actual.typography, b = expected.typography;
  expect(
    [
      a.fieldLabel,
      a.pageTitle,
      a.heading,
      a.sectionLabel,
      a.body,
      a.bodyStrong,
      a.bodyMuted,
      a.bodySmall,
      a.caption,
      a.micro,
      a.button,
    ],
    [
      b.fieldLabel,
      b.pageTitle,
      b.heading,
      b.sectionLabel,
      b.body,
      b.bodyStrong,
      b.bodyMuted,
      b.bodySmall,
      b.caption,
      b.micro,
      b.button,
    ],
  );
  expect(a.spec, same(b.spec));
  for (final (x, y) in [
    (actual.elevation.sm, expected.elevation.sm),
    (actual.elevation.md, expected.elevation.md),
    (actual.elevation.lg, expected.elevation.lg),
  ]) {
    expect(const ListEquality<BoxShadow>().equals(x, y), isTrue);
  }
  expect(actual.focus, expected.focus);
}
