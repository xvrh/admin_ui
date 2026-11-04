// AdminFonts.resolver: the family a theme names is set as it is, unless an
// app hands the kit a resolver, which then builds the theme's text styles,
// though never its monospace ones.

import 'package:admin_ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _spec = AdminTypeSpec(
  fontFamily: 'Inter',
  fontFamilyFallback: ['Noto Naskh Arabic'],
);

void main() {
  tearDown(() => AdminFonts.resolver = null);

  test('without a resolver the family is set as it is', () {
    final style = _spec.applyFont(const TextStyle(fontSize: 13));
    expect(style.fontFamily, 'Inter');
    expect(style.fontSize, 13);
  });

  test('a resolver builds the style, and the fallback goes after its own', () {
    final asked = <String>[];
    AdminFonts.resolver = (family, style) {
      asked.add(family);
      return style.copyWith(
        fontFamily: '${family}_resolved',
        fontFamilyFallback: [family],
      );
    };
    final style = _spec.applyFont(const TextStyle(fontSize: 13));
    expect(asked, ['Inter']);
    expect(style.fontFamily, 'Inter_resolved');
    expect(style.fontFamilyFallback?.first, 'Inter');
    expect(style.fontFamilyFallback?.last, 'Noto Naskh Arabic');
  });

  test('a resolver that returns null leaves the family as it is', () {
    AdminFonts.resolver = (_, _) => null;
    expect(_spec.applyFont(const TextStyle()).fontFamily, 'Inter');
  });

  test('the monospace family never goes through the resolver', () {
    final asked = <String>[];
    AdminFonts.resolver = (family, style) {
      asked.add(family);
      return null;
    };
    final style = _spec.applyMonoFont(const TextStyle());
    expect(asked, isEmpty);
    expect(style.fontFamily, 'monospace');
  });

  test('the Material text theme goes through the resolver too', () {
    AdminFonts.resolver = (family, style) =>
        style.copyWith(fontFamily: '${family}_resolved');
    final theme = _spec.applyFontTheme(Typography.material2021().black);
    expect(theme.bodyMedium?.fontFamily, 'Inter_resolved');
    expect(theme.titleLarge?.fontFamily, 'Inter_resolved');
  });
}
