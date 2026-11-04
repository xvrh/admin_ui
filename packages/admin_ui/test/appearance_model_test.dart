import 'dart:convert';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const teal = Color(0xFF0D9488);
  final iris = AdminAppearance(theme: irisTheme);

  group('tokens', () {
    test("are the theme's own set for each brightness", () {
      expect(iris.tokens(Brightness.light), same(irisTheme.tokens));
      expect(iris.tokens(Brightness.dark), same(irisTheme.dark));
    });

    test('a theme with no dark set uses its light one', () {
      final solo = AdminTheme(name: 'Solo', tokens: defaultTokens);
      final appearance = AdminAppearance(theme: solo, mode: ThemeMode.dark);
      expect(appearance.tokens(Brightness.dark), same(defaultTokens));
    });

    test('are branded with the accent, in both brightnesses', () {
      final branded = iris.copyWith(accent: teal);
      final light = branded.tokens(Brightness.light);
      final dark = branded.tokens(Brightness.dark);
      expect(light, irisTheme.tokens.branded(teal));
      expect(dark, irisTheme.dark!.branded(teal));
      expect(light.palette.primary, isNot(irisTheme.tokens.palette.primary));
      expect(light.palette.surface, irisTheme.tokens.palette.surface);
    });

    test('are built once per theme, accent and brightness', () {
      final a = iris.copyWith(accent: teal);
      final b = AdminAppearance(
        theme: irisTheme,
        mode: ThemeMode.dark,
        accent: const Color(0xFF0D9488),
        density: TableDensity.compact,
      );
      expect(a.tokens(Brightness.light), same(b.tokens(Brightness.light)));
      expect(a.tokens(Brightness.dark), same(b.tokens(Brightness.dark)));
      expect(
        a.tokens(Brightness.light),
        isNot(
          same(
            a
                .copyWith(accent: const Color(0xFFE11D48))
                .tokens(Brightness.light),
          ),
        ),
      );
      expect(
        a.tokens(Brightness.light),
        isNot(same(a.copyWith(theme: shadcnTheme).tokens(Brightness.light))),
      );
    });

    test('build the ThemeData once per token set', () {
      final a = iris.copyWith(accent: teal);
      final data = a.themeData(Brightness.light);
      expect(a.copyWith().themeData(Brightness.light), same(data));
      expect(data.extension<AdminTokens>(), a.tokens(Brightness.light));
      expect(a.themeData(Brightness.dark), isNot(same(data)));
      expect(data.brightness, Brightness.light);
      expect(a.themeData(Brightness.dark).brightness, Brightness.dark);
    });
  });

  test('resolves the brightness it shows in', () {
    expect(
      [
        for (final mode in ThemeMode.values)
          for (final platform in Brightness.values)
            iris.copyWith(mode: mode).resolveBrightness(platform),
      ],
      [
        Brightness.dark, Brightness.light, // system follows the device
        Brightness.light, Brightness.light,
        Brightness.dark, Brightness.dark,
      ],
    );
  });

  group('value', () {
    test('compares by theme name, mode, accent and density', () {
      final a = AdminAppearance(theme: irisTheme, accent: teal);
      expect(a, AdminAppearance(theme: irisTheme, accent: teal));
      expect(
        a.hashCode,
        AdminAppearance(theme: irisTheme, accent: teal).hashCode,
      );
      expect(a, isNot(a.copyWith(mode: ThemeMode.dark)));
      expect(a, isNot(a.copyWith(density: TableDensity.comfortable)));
      expect(a, isNot(a.copyWith(theme: antTheme)));
      expect(a, isNot(a.copyWith(accent: const Color(0xFF7C3AED))));
    });

    test('copyWith keeps what it is not given; clearAccent drops the '
        'accent', () {
      final a = AdminAppearance(
        theme: antTheme,
        mode: ThemeMode.dark,
        accent: teal,
        density: TableDensity.compact,
      );
      expect(a.copyWith(), a);
      expect(a.copyWith(clearAccent: true).accent, isNull);
      expect(a.copyWith(clearAccent: true).mode, ThemeMode.dark);
      expect(a.themeName, 'Ant');
    });

    test('defaults to the system mode, no accent and standard rows', () {
      expect(
        (iris.mode, iris.accent, iris.density),
        (ThemeMode.system, null, TableDensity.standard),
      );
    });
  });

  group('JSON', () {
    test('round-trips, through a string', () {
      final a = AdminAppearance(
        theme: fluentTheme,
        mode: ThemeMode.dark,
        accent: teal,
        density: TableDensity.comfortable,
      );
      final json = jsonDecode(jsonEncode(a.toJson())) as Map<String, Object?>;
      expect(json, {
        'theme': 'Fluent',
        'mode': 'dark',
        'accent': 0xFF0D9488,
        'density': 'comfortable',
      });
      expect(AdminAppearance.fromJson(json), a);
      expect(AdminAppearance.fromJson(iris.toJson()), iris);
    });

    test('an unknown theme reads as the first of the list', () {
      final json = {'theme': 'Retired', 'mode': 'light', 'accent': null};
      expect(AdminAppearance.fromJson(json).theme, irisTheme);
      final ours = [antTheme, carbonTheme];
      expect(AdminAppearance.fromJson(json, themes: ours).theme, antTheme);
      expect(
        AdminAppearance.fromJson({'theme': 'Carbon'}, themes: ours).theme,
        same(carbonTheme),
      );
      expect(AdminAppearance.fromJson(json).mode, ThemeMode.light);
    });

    test('what does not read keeps its default', () {
      expect(
        AdminAppearance.fromJson(const {
          'mode': 'dim',
          'accent': '#0D9488',
          'density': 'cosy',
        }),
        AdminAppearance(theme: irisTheme),
      );
      expect(
        AdminAppearance.fromJson(const {}),
        AdminAppearance(theme: irisTheme),
      );
    });
  });

  test('the kit offers four accents', () {
    expect(adminAccents.keys, ['Crimson', 'Violet', 'Teal', 'Amber']);
    expect(adminAccents['Teal'], teal);
  });
}
