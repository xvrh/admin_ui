import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(
        width: 760,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  ),
);

const _en = LocaleInfo(
  code: 'en',
  native: 'English',
  status: LocaleStatus.source,
);

Widget _field(List<LocaleInfo> locales) => TranslatableField(
  label: 'Title',
  locales: locales,
  visibleLocales: {for (final l in locales) l.code},
  sourceLocale: 'en',
  activeLocale: locales.last.code,
  values: {for (final l in locales) l.code: 'x'},
  onVisibleLocalesChanged: (_) {},
  onChanged: (_, _) {},
);

RenderEditable _render(WidgetTester tester, Finder editor) =>
    tester.state<EditableTextState>(editor).renderEditable;

void main() {
  group('LocaleInfo', () {
    test('takes its direction from its language, in any case', () {
      for (final code in ['ar', 'AR', 'he', 'fa-IR', 'ur_PK']) {
        expect(
          LocaleInfo(
            code: code,
            native: '',
            status: LocaleStatus.missing,
          ).direction,
          TextDirection.rtl,
          reason: code,
        );
      }
      for (final code in ['en', 'FR', 'ja', 'sr-Latn']) {
        expect(
          LocaleInfo(
            code: code,
            native: '',
            status: LocaleStatus.missing,
          ).direction,
          TextDirection.ltr,
          reason: code,
        );
      }
    });

    test('an explicit direction wins, and counts in equality', () {
      const plain = LocaleInfo(
        code: 'xx',
        native: 'X',
        status: LocaleStatus.missing,
      );
      const rtl = LocaleInfo(
        code: 'xx',
        native: 'X',
        status: LocaleStatus.missing,
        textDirection: TextDirection.rtl,
      );
      expect(plain.direction, TextDirection.ltr);
      expect(rtl.direction, TextDirection.rtl);
      expect(plain == rtl, isFalse);
      expect(plain.hashCode == rtl.hashCode, isFalse);
    });

    test('parses its code into a locale', () {
      LocaleInfo info(String code) =>
          LocaleInfo(code: code, native: '', status: LocaleStatus.missing);
      expect(info('PT_br').locale, const Locale('pt', 'BR'));
      expect(
        info('zh-hant').locale,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
      expect(info('ES').locale, const Locale('es'));
    });
  });

  group('languageName', () {
    test('normalises the code', () {
      expect(languageName('ES'), 'Spanish');
      expect(languageName('es_ES'), 'European Spanish');
      expect(languageName('pt-br'), 'Brazilian Portuguese');
      expect(languageName('fr-XX'), 'French');
      expect(languageName('qq'), 'QQ');
    });

    test('names the language in the display locale', () {
      expect(languageName('es', displayLocale: const Locale('fr')), 'espagnol');
      expect(
        languageName('ES', displayLocale: const Locale('ar', 'EG')),
        'الإسبانية',
      );
      expect(languageName('es', displayLocale: const Locale('de')), 'Spanish');
    });

    testWidgets('languageNameOf uses the app locale', (tester) async {
      late String name;
      await tester.pumpWidget(
        _host(
          locale: const Locale('fr'),
          Builder(
            builder: (context) {
              name = languageNameOf(context, 'DE');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(name, 'allemand');
    });
  });

  group('lanes take their language’s direction', () {
    testWidgets('an Arabic lane is right to left in an English admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _field(const [
            _en,
            LocaleInfo(
              code: 'AR',
              native: 'العربية',
              status: LocaleStatus.missing,
            ),
          ]),
        ),
      );
      final arabic = find.byType(EditableText).at(1);
      expect(_render(tester, arabic).textDirection, TextDirection.rtl);
      expect(
        _render(tester, find.byType(EditableText).first).textDirection,
        TextDirection.ltr,
      );
      // The chrome stays in the admin's direction.
      final label = find.byWidgetPredicate(
        (w) => w is Text && w.data?.toLowerCase() == 'title',
      );
      for (final chrome in [find.text('AR'), label]) {
        expect(
          Directionality.of(tester.element(chrome.first)),
          TextDirection.ltr,
        );
      }
      // The lane's text is Arabic; its Material strings stay the app's.
      final context = tester.element(arabic);
      expect(Localizations.localeOf(context), const Locale('ar'));
      expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Cancel');
      expect(AdminLocalizations.of(context).apply, 'Apply');
    });

    testWidgets('a French lane is left to right in an Arabic admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          locale: const Locale('ar'),
          _field(const [
            _en,
            LocaleInfo(
              code: 'fr',
              native: 'Français',
              status: LocaleStatus.missing,
            ),
          ]),
        ),
      );
      final french = find.byType(EditableText).at(1);
      expect(_render(tester, french).textDirection, TextDirection.ltr);
      expect(
        Directionality.of(tester.element(find.text('FR'))),
        TextDirection.rtl,
      );
      // The gutter holding the code sits at the right, the start.
      final lane = tester.getRect(french);
      expect(tester.getRect(find.text('FR')).left, greaterThan(lane.right));
    });

    testWidgets('a lane in a language the app has no strings for keeps them', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _field(const [
            _en,
            LocaleInfo(
              code: 'tlh',
              native: 'tlhIngan',
              status: LocaleStatus.missing,
            ),
          ]),
        ),
      );
      expect(tester.takeException(), isNull);
      final klingon = tester.element(find.byType(EditableText).at(1));
      expect(Localizations.localeOf(klingon), const Locale('tlh'));
      expect(MaterialLocalizations.of(klingon).okButtonLabel, 'OK');
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('the explicit direction of a lane wins', (tester) async {
      await tester.pumpWidget(
        _host(
          _field(const [
            _en,
            LocaleInfo(
              code: 'xx',
              native: 'X',
              status: LocaleStatus.missing,
              textDirection: TextDirection.rtl,
            ),
          ]),
        ),
      );
      expect(
        _render(tester, find.byType(EditableText).at(1)).textDirection,
        TextDirection.rtl,
      );
    });
  });

  testWidgets('LaneLanguage leaves a lane in the app language alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        locale: const Locale('fr'),
        const LaneLanguage(code: 'FR', child: Text('Bonjour')),
      ),
    );
    expect(
      find.ancestor(
        of: find.text('Bonjour'),
        matching: find.byType(Localizations),
      ),
      findsOneWidget,
      reason: 'only the app’s',
    );
  });
}
