import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/l10n/ar.dart';
import 'package:admin_ui/l10n/de.dart';
import 'package:admin_ui/l10n/es.dart';
import 'package:admin_ui/l10n/fr.dart';
import 'package:admin_ui/l10n/it.dart';
import 'package:admin_ui/l10n/ja.dart';
import 'package:admin_ui/l10n/ko.dart';
import 'package:admin_ui/l10n/nl.dart';
import 'package:admin_ui/l10n/pl.dart';
import 'package:admin_ui/l10n/pt.dart';
import 'package:admin_ui/l10n/tr.dart';
import 'package:admin_ui/l10n/zh.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_time_patterns.dart';
import 'package:material_ui/material_ui.dart';

/// Every language of the kit. One added under lib/src/l10n/languages is
/// added here too, or the first test fails.
const _all = [
  adminEn,
  adminFr,
  adminAr,
  adminEs,
  adminDe,
  adminIt,
  adminPt,
  adminNl,
  adminPl,
  adminJa,
  adminZh,
  adminKo,
  adminTr,
];

const _languages = AdminLanguages(_all);

/// The language codes under lib/src/l10n/languages.
List<String> _codes() => [
  for (final dir in Directory(
    'lib/src/l10n/languages',
  ).listSync().whereType<Directory>())
    dir.uri.pathSegments.where((s) => s.isNotEmpty).last,
]..sort();

/// Every import and export of the Dart files under lib, as (from, to): both
/// paths relative to lib, or `to` a package uri of another package.
List<(String, String)> _imports() {
  final directive = RegExp(
    r"^\s*(?:import|export)\s+'([^']+)'",
    multiLine: true,
  );
  final lib = Directory('lib').absolute.uri;
  return [
    for (final file in Directory('lib').listSync(recursive: true))
      if (file is File && file.path.endsWith('.dart'))
        for (final match in directive.allMatches(file.readAsStringSync()))
          (
            file.absolute.uri.path.substring(lib.path.length),
            switch (match[1]!) {
              final uri when uri.startsWith('package:admin_ui/') =>
                uri.substring('package:admin_ui/'.length),
              final uri
                  when uri.startsWith('package:') || uri.startsWith('dart:') =>
                uri,
              final uri =>
                file.absolute.uri.resolve(uri).path.substring(lib.path.length),
            },
          ),
  ];
}

/// The language a path under lib belongs to, or null.
String? _languageOf(String path) =>
    RegExp(r'^src/l10n/languages/([^/]+)/').firstMatch(path)?[1] ??
    RegExp(r'^l10n/([^/]+)\.dart$').firstMatch(path)?[1];

void main() {
  test(
    'every language under lib/src/l10n/languages is listed, with a barrel',
    () {
      expect([for (final l in _all) l.locale.languageCode]..sort(), _codes());
      for (final code in _codes()) {
        if (code == 'en') continue;
        expect(File('lib/l10n/$code.dart').existsSync(), isTrue, reason: code);
      }
    },
  );

  test("each language's date data is intl's", () {
    final symbols = dateTimeSymbolMap();
    final patterns = dateTimePatternMap();
    for (final language in _all) {
      final data = language.dateSymbols();
      final reason =
          '${language.locale}: run `fvm dart run tool/gen_date_data.dart`';
      expect(
        data.serializeToMap(),
        symbols[data.NAME]!.serializeToMap(),
        reason: reason,
      );
      expect(language.datePatterns, patterns[data.NAME], reason: reason);
    }
  });

  group('a language reaches a build only through its own library', () {
    // An app ships the languages it lists in AdminLanguages and no others:
    // nothing else in the kit names one, so dart2js drops those it does not
    // list. tool/check_tree_shaking.dart checks a web build of an app.
    test('no kit library imports a language but its own', () {
      final offenders = [
        for (final (from, to) in _imports())
          if (_languageOf(to) case final language?)
            if (_languageOf(from) != language &&
                !switch (from) {
                  // English is the kit's base: intl falls back to its dates.
                  'src/l10n/admin_language.dart' =>
                    to == 'src/l10n/languages/en/date_data.dart',
                  'l10n.dart' => language == 'en',
                  _ => false,
                })
              '$from -> $to',
      ];
      expect(offenders, isEmpty);
    });

    test('common_locale_data comes one locale at a time, each from its own '
        'language', () {
      final locale = RegExp(r'^package:common_locale_data/(\w+)\.dart$');
      final offenders = [
        for (final (from, to) in _imports())
          if (locale.firstMatch(to)?[1] case final name?)
            if (name != 'common_locale_data' && _languageOf(from) != name)
              '$from -> $to',
      ];
      expect(offenders, isEmpty);
    });
  });

  group("the kit's widgets without Material's delegates", () {
    Future<BuildContext> pumpCalendar(
      WidgetTester tester,
      Locale locale,
      List<LocalizationsDelegate<Object?>> delegates,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          locale: locale,
          supportedLocales: _languages.locales,
          localizationsDelegates: delegates,
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return Calendar(value: DateTime(2026, 1, 5), onChanged: (_) {});
              },
            ),
          ),
        ),
      );
      return context;
    }

    testWidgets('no delegate draws English', (tester) async {
      // Before any delegate loads intl's date data.
      await pumpCalendar(tester, const Locale('en'), const []);
      expect(tester.takeException(), isNull);
      expect(find.text('January 2026'), findsOne);
    });

    for (final (locale, month, direction) in [
      (const Locale('en'), 'January 2026', TextDirection.ltr),
      (const Locale('fr'), 'janvier 2026', TextDirection.ltr),
      (const Locale('ar'), 'يناير 2026', TextDirection.rtl),
    ]) {
      testWidgets('AdminLanguages alone writes $locale, in its direction', (
        tester,
      ) async {
        final context = await pumpCalendar(
          tester,
          locale,
          _languages.delegates,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(month), findsOne);
        expect(Directionality.of(context), direction);
        expect(
          MaterialLocalizations.of(context).cancelButtonLabel,
          _languages.resolve(locale)!.strings.cancel,
        );
      });
    }
  });
}
