import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fallback = ['Noto Naskh Arabic'];

/// A style's families after [own]: the test platform's UI family (Android's
/// Material typography names Roboto), then the spec's fallback.
List<String> _after(List<String> own) => [
  ...own,
  if (!own.contains('Roboto')) 'Roboto',
  ..._fallback,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Each font source that names a family, and the fallback its own styles
  // carry before the spec's is appended.
  final sources =
      <String, (AdminTypeSpec Function(List<String>?), List<String>)>{
        'a plain family': (
          (fallback) => AdminTypeSpec(
            fontFamily: 'Segoe UI',
            fontFamilyFallback: fallback,
          ),
          [],
        ),
      };

  for (final MapEntry(key: name, value: (spec, own)) in sources.entries) {
    group(name, () {
      test('without a fallback, styles keep their own', () {
        final plain = spec(null);
        final style = plain.applyFont(const TextStyle());
        expect(style.fontFamilyFallback, own.isEmpty ? isNull : own);
      });

      test('the fallback follows the family and the platform font on '
          'every style', () {
        final withFallback = spec(_fallback);
        final type = AdminTypography.from(
          irisTheme.tokens.palette,
          withFallback,
        );
        for (final style in [
          type.body,
          type.heading,
          type.fieldText,
          type.button,
          type.micro,
        ]) {
          expect(style.fontFamilyFallback, _after(own));
        }
        expect(
          type.weighted(type.body, FontWeight.w700).fontFamilyFallback,
          _after(own),
          reason: 'restyling a style does not repeat the fallback',
        );
      });

      test('the Material text theme carries the fallback', () {
        final withFallback = spec(_fallback);
        final theme = withFallback.applyFontTheme(ThemeData().textTheme);
        for (final style in [
          theme.displayLarge,
          theme.titleMedium,
          theme.bodyMedium,
          theme.labelSmall,
        ]) {
          expect(style!.fontFamilyFallback, _after(own));
        }
      });
    });
  }

  group('the platform font', () {
    const spec = AdminTypeSpec(fontFamilyFallback: _fallback);

    // A fallback on a style with no family would replace the family the
    // style inherits: the engine reads it as the whole family list, so a
    // span in Text.rich would draw in the platform default.
    test('the kit\'s styles name no family and carry no fallback', () {
      final type = AdminTypography.from(irisTheme.tokens.palette, spec);
      for (final style in [
        type.body,
        type.heading,
        type.fieldText,
        type.button,
        type.micro,
        type.weighted(type.body, FontWeight.w700),
      ]) {
        expect(style.fontFamily, isNull);
        expect(style.fontFamilyFallback, isNull);
      }
    });

    test('a style that names a family gets the fallback', () {
      expect(
        spec.applyFont(const TextStyle(fontFamily: 'Georgia')),
        TextStyle(fontFamily: 'Georgia', fontFamilyFallback: _after([])),
      );
    });

    testWidgets('buildAppTheme puts it on the text theme, which Text.rich '
        'spans in a kit style inherit', (tester) async {
      final tokens = AdminTokens.from(
        palette: irisTheme.tokens.palette,
        type: spec,
      );
      final theme = buildAppTheme(tokens);
      final body = theme.textTheme.bodyMedium!;
      expect(body.fontFamily, isNotNull);
      expect(body.fontFamilyFallback, containsAllInOrder(_fallback));

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Material(
            child: Builder(
              builder: (context) => Text.rich(
                TextSpan(
                  text: 'Plain ',
                  children: [
                    TextSpan(text: 'styled', style: context.type.bodyStrong),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final root = tester.widget<RichText>(find.byType(RichText)).text;
      expect(root.style!.fontFamily, body.fontFamily);
      expect(root.style!.fontFamilyFallback, body.fontFamilyFallback);
      final span = (root as TextSpan).children!.single as TextSpan;
      final styled = span.children!.single;
      expect(styled.style!.fontFamily, isNull);
      expect(styled.style!.fontFamilyFallback, isNull);
    });
  });

  // The engine takes a text field's strut from the first family of a
  // style's list it has, and a character from the first family that has
  // it. A script fallback straight after a family the platform lacks (a
  // platform name on the web, Segoe UI off Windows) would set the field's
  // baseline by its own metrics and draw the spaces and digits it covers;
  // behind the platform's UI font, it only draws its script.
  group('a script fallback comes after the platform\'s UI font', () {
    const spec = AdminTypeSpec(
      fontFamily: 'Brand Sans',
      fontFamilyFallback: _fallback,
    );
    final platforms = {
      TargetPlatform.android: ['Roboto'],
      TargetPlatform.fuchsia: ['Roboto'],
      TargetPlatform.iOS: ['CupertinoSystemText'],
      TargetPlatform.macOS: ['.AppleSystemUIFont'],
      TargetPlatform.windows: ['Segoe UI'],
      TargetPlatform.linux: [
        'Roboto',
        'Ubuntu',
        'Adwaita Sans',
        'Cantarell',
        'DejaVu Sans',
        'Liberation Sans',
        'Arial',
      ],
    };
    for (final MapEntry(key: platform, value: families) in platforms.entries) {
      test('on ${platform.name}', () {
        debugDefaultTargetPlatformOverride = platform;
        try {
          final type = AdminTypography.from(irisTheme.tokens.palette, spec);
          for (final style in [type.fieldText, type.body, type.button]) {
            expect(style.fontFamily, 'Brand Sans');
            expect(style.fontFamilyFallback, [...families, ..._fallback]);
          }
          expect(type.mono.fontFamilyFallback, [
            'Menlo',
            'Consolas',
            'Courier New',
            ...families,
            ..._fallback,
          ]);
          // The Material text theme, which a stock TextField edits in. Its
          // styles keep their own fallback first: Linux's names the families
          // after Roboto.
          final body = buildAppTheme(
            AdminTokens.from(palette: irisTheme.tokens.palette, type: spec),
          ).textTheme.bodyLarge!;
          expect(body.fontFamily, 'Brand Sans');
          expect(body.fontFamilyFallback, [
            ...families.skip(1),
            families.first,
            ..._fallback,
          ]);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    test('a theme with no font keeps the platform\'s family first', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final body = buildAppTheme(
          AdminTokens.from(
            palette: irisTheme.tokens.palette,
            type: const AdminTypeSpec(fontFamilyFallback: _fallback),
          ),
        ).textTheme.bodyLarge!;
        expect(body.fontFamily, '.AppleSystemUIFont');
        expect(body.fontFamilyFallback, _fallback);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  test('copyWith replaces only the fields it is given', () {
    const spec = AdminTypeSpec(
      scale: 0.95,
      fontFamily: 'Inter',
      heading: FontWeight.w600,
      tracking: -0.2,
      uppercaseLabels: false,
    );
    expect(spec.copyWith(), spec);
    expect(
      spec.copyWith(fontFamilyFallback: _fallback),
      const AdminTypeSpec(
        scale: 0.95,
        fontFamily: 'Inter',
        fontFamilyFallback: _fallback,
        heading: FontWeight.w600,
        tracking: -0.2,
        uppercaseLabels: false,
      ),
    );
  });

  test('the fallback is part of a spec\'s value', () {
    const a = AdminTypeSpec(fontFamilyFallback: ['A', 'B']);
    final b = AdminTypeSpec(fontFamilyFallback: List.of(['A', 'B']));
    expect(b, a);
    expect(b.hashCode, a.hashCode);
    expect(const AdminTypeSpec(fontFamilyFallback: ['B', 'A']), isNot(a));
    expect(const AdminTypeSpec(), isNot(a));
    expect(const AdminTypeSpec(fontFamilyFallback: []), isNot(a));
  });
}
