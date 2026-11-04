import 'package:admin_ui/src/fields/ui/language_pill.dart';
import 'package:admin_ui/src/i18n/locale_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _locales = [
  LocaleInfo(code: 'EN', native: 'English', status: LocaleStatus.source),
  LocaleInfo(code: 'ES', native: 'Español', status: LocaleStatus.translated),
  LocaleInfo(code: 'FR', native: 'Français', status: LocaleStatus.review),
];

Widget _host({
  required Set<String> visible,
  String active = 'ES',
  ValueChanged<Set<String>>? onChanged,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: LanguagePill(
        value: visible,
        activeLocale: active,
        locales: _locales,
        sourceLocale: 'EN',
        onChanged: onChanged ?? (_) {},
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('language-pill')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'checking a second locale goes side-by-side and brings the source',
    (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        _host(visible: {'ES'}, onChanged: (s) => emitted = s),
      );
      await _open(tester);

      await tester.tap(find.byKey(const ValueKey('lang-check-FR')));
      await tester.pumpAndSettle();

      expect(emitted, {'EN', 'ES', 'FR'}); // source auto-added
    },
  );

  testWidgets('the last visible locale cannot be unchecked', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(visible: {'ES'}, onChanged: (_) => calls++));
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('lang-check-ES')));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('unchecking one of several drops just that lane', (tester) async {
    Set<String>? emitted;
    await tester.pumpWidget(
      _host(visible: {'EN', 'ES', 'FR'}, onChanged: (s) => emitted = s),
    );
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('lang-check-FR')));
    await tester.pumpAndSettle();

    expect(emitted, {'EN', 'ES'});
  });

  testWidgets('tapping a row switches to that locale alone', (tester) async {
    Set<String>? emitted;
    await tester.pumpWidget(
      _host(visible: {'EN', 'ES', 'FR'}, onChanged: (s) => emitted = s),
    );
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('lang-switch-FR')));
    await tester.pumpAndSettle();

    expect(emitted, {'FR'});
  });
}
