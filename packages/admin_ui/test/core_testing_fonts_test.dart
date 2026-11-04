import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The files `flutter_test_config.dart` serves: the example's.
const _fonts = 'example/assets/fonts';

void main() {
  group('loadAdminFonts', () {
    test('fails on a family with no file, naming the theme and the family', () {
      final theme = AdminTheme.from(
        name: 'Probe',
        palette: irisPalette,
        type: const AdminTypeSpec(fontFamily: 'Lato'),
      );
      expect(
        loadAdminFonts(
          themes: [theme],
          fontDirectory: _fonts,
          standIns: const {},
          fontManifest: false,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'loadAdminFonts: the Probe light theme draws in Lato, and no font '
                'of that family is in $_fonts. Bundle it under `flutter: fonts:` '
                'in pubspec.yaml, or leave the theme out of themes.',
          ),
        ),
      );
    });

    test('registers each stand-in from the files named for its face', () async {
      await loadAdminFonts(
        themes: const [],
        fontDirectory: _fonts,
        standIns: const {'Probe stand-in': 'Roboto'},
        fontManifest: false,
      );
      expect(testFontFamilies, contains('Probe stand-in'));
      expect(
        () => testFontFamilies.add('Probe'),
        throwsUnsupportedError,
        reason: 'the set is read-only',
      );
    });

    test('fails on a stand-in with no file', () {
      expect(
        loadAdminFonts(
          themes: const [],
          fontDirectory: _fonts,
          standIns: const {'Segoe UI': 'Nothing'},
          fontManifest: false,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'loadAdminFonts: no Nothing font in $_fonts to stand in for '
                'Segoe UI.',
          ),
        ),
      );
    });

    test('fails on a directory that is not there', () {
      expect(
        loadAdminFonts(fontDirectory: 'no/such/fonts'),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('loadTestFontFamily registers a family of the app\'s own', () async {
    final bytes = File('$_fonts/Inter-Regular.ttf').readAsBytesSync();
    await loadTestFontFamily('Probe family', [
      Future.value(ByteData.sublistView(bytes)),
    ]);
    expect(testFontFamilies, contains('Probe family'));
  });

  group('withTestFontFallback', () {
    test('gives a theme that names no font the test platform\'s family', () {
      final tokens = withTestFontFallback(defaultTokens);
      expect(tokens.typography.spec.fontFamily, testPlatformFamily);
      expect(tokens.typography.body.fontFamily, testPlatformFamily);
      expect(tokens.typography.spec.fontFamilyFallback, isNull);
      expect(tokens.palette, defaultTokens.palette);
    });

    test("keeps the theme's family and appends the fallback", () {
      final tokens = withTestFontFallback(
        irisTheme.tokens,
        fallback: const ['Probe symbols', 'Probe script'],
      );
      expect(tokens.typography.spec.fontFamily, 'Inter');
      expect(tokens.typography.body.fontFamily, 'Inter');
      expect(
        tokens.typography.body.fontFamilyFallback,
        containsAllInOrder(['Probe symbols', 'Probe script']),
      );
    });
  });

  group('textWithoutFont', () {
    Future<void> pump(WidgetTester tester, List<Widget> children) =>
        tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(children: children),
          ),
        );

    testWidgets('reports a run in the default family, or in none loaded', (
      tester,
    ) async {
      await pump(tester, [
        const Text('Boxes'),
        const Text('Nowhere', style: TextStyle(fontFamily: 'No such family')),
      ]);
      expect(textWithoutFont(), [
        '"Boxes" in the default family',
        '"Nowhere" in No such family',
      ]);
    });

    testWidgets('passes a Google font the tests loaded, and a family of '
        'their own', (tester) async {
      final bytes = File('$_fonts/Roboto-Regular.ttf').readAsBytesSync();
      await tester.runAsync(
        () => loadTestFontFamily('Probe own', [
          Future.value(ByteData.sublistView(bytes)),
        ]),
      );
      await pump(tester, [
        Text('Inter', style: irisTheme.tokens.typography.body),
        const Text('Own', style: TextStyle(fontFamily: 'Probe own')),
        const Text.rich(
          TextSpan(
            text: 'Parent ',
            style: TextStyle(fontFamily: 'Probe own'),
            children: [TextSpan(text: 'inherits')],
          ),
        ),
      ]);
      expect(textWithoutFont(), isEmpty);
    });

    testWidgets('a span with a fallback and no family draws in the default '
        'family, not its parent\'s', (tester) async {
      await pump(tester, [
        Text.rich(
          TextSpan(
            text: 'Parent ',
            style: irisTheme.tokens.typography.body,
            children: const [
              TextSpan(
                text: 'Boxes',
                style: TextStyle(fontFamilyFallback: ['Inter']),
              ),
            ],
          ),
        ),
      ]);
      expect(textWithoutFont(), ['"Boxes" in the default family, Inter']);
    });
  });
}
