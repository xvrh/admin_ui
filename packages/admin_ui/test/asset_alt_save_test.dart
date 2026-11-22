// What AssetDetailView.onSaveAlt is handed: the whole alt text, with a
// language the person cleared left out, so the app stores it in place of
// the old.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _locales = [
  LocaleInfo(code: 'en', status: LocaleStatus.source),
  LocaleInfo(code: 'fr', status: LocaleStatus.translated),
  LocaleInfo(code: 'ar', status: LocaleStatus.translated),
];

Asset _asset(Map<String, String> alt) =>
    Asset(id: '35', name: 'gloves.jpg', width: 1200, height: 800, alt: alt);

/// Pumps the detail of an asset whose alt text is [alt], and returns the
/// list every save's map is added to: [into], when the same detail is pumped
/// again with other languages in view.
Future<List<Map<String, String>>> _pump(
  WidgetTester tester,
  Map<String, String> alt, {
  Set<String> visible = const {'en', 'fr', 'ar'},
  bool fails = false,
  List<Map<String, String>>? into,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final saves = into ?? <Map<String, String>>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: LangScope(
          locales: _locales,
          visibleLocales: visible,
          sourceLocale: 'en',
          activeLocale: 'en',
          onVisibleLocalesChanged: (_) {},
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 460,
              child: AssetDetailView(
                asset: _asset(alt),
                onSaveAlt: (alt) async {
                  saves.add(alt);
                  return fails ? null : _asset(alt);
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return saves;
}

/// Types [text] in the lane at [index] among the lanes in view.
Future<void> _type(WidgetTester tester, int index, String text) async {
  await tester.enterText(find.byType(EditableText).at(index), text);
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save alt text'));
  await tester.pumpAndSettle();
}

bool _canSave(WidgetTester tester) =>
    tester
        .widget<Button>(find.widgetWithText(Button, 'Save alt text'))
        .onPressed !=
    null;

void main() {
  testWidgets('one language typed: the map holds the others too', (
    tester,
  ) async {
    final saves = await _pump(tester, {'en': 'Gloves', 'fr': 'Gants'});
    await _type(tester, 2, 'قفازات');
    await _save(tester);
    expect(saves, [
      {'en': 'Gloves', 'fr': 'Gants', 'ar': 'قفازات'},
    ]);
  });

  testWidgets('a language cleared is left out, not sent empty', (tester) async {
    final saves = await _pump(tester, {'en': 'Gloves', 'fr': 'Gants'});
    await _type(tester, 1, '');
    await _save(tester);
    // Merged into what was there, French would come back: the map is the
    // whole alt text, to store in its place.
    expect(saves, [
      {'en': 'Gloves'},
    ]);
  });

  testWidgets('a language of spaces alone is left out too', (tester) async {
    final saves = await _pump(tester, {'en': 'Gloves', 'fr': 'Gants'});
    await _type(tester, 1, '   ');
    await _save(tester);
    expect(saves, [
      {'en': 'Gloves'},
    ]);
  });

  testWidgets('every language cleared: the map is empty', (tester) async {
    final saves = await _pump(tester, {'en': 'Gloves', 'fr': 'Gants'});
    await _type(tester, 0, '');
    await _type(tester, 1, '');
    await _save(tester);
    expect(saves, [<String, String>{}]);
  });

  testWidgets('text is trimmed', (tester) async {
    final saves = await _pump(tester, {'en': 'Gloves'});
    await _type(tester, 1, '  Gants  ');
    await _save(tester);
    expect(saves, [
      {'en': 'Gloves', 'fr': 'Gants'},
    ]);
  });

  testWidgets('a hidden language keeps its text in the map', (tester) async {
    final saves = await _pump(
      tester,
      {'en': 'Gloves', 'fr': 'Gants'},
      visible: const {'en'},
    );
    expect(find.byType(EditableText), findsOneWidget);
    await _type(tester, 0, 'Leather gloves');
    await _save(tester);
    expect(saves, [
      {'en': 'Leather gloves', 'fr': 'Gants'},
    ]);
  });

  testWidgets('a language typed, then hidden, is in the map', (tester) async {
    const alt = {'en': 'Gloves'};
    final saves = await _pump(tester, alt);
    await _type(tester, 1, 'Gants');
    await _pump(tester, alt, visible: const {'en'}, into: saves);
    expect(find.byType(EditableText), findsOneWidget);
    await _save(tester);
    expect(saves, [
      {'en': 'Gloves', 'fr': 'Gants'},
    ]);
  });

  testWidgets('a language the page no longer lists keeps its text in the '
      'map', (tester) async {
    final saves = await _pump(tester, {'en': 'Gloves', 'de': 'Handschuhe'});
    await _type(tester, 0, 'Leather gloves');
    await _save(tester);
    expect(saves, [
      {'en': 'Leather gloves', 'de': 'Handschuhe'},
    ]);
  });

  testWidgets('a save that fails is offered again, with the whole map '
      'again', (tester) async {
    final saves = await _pump(tester, {
      'en': 'Gloves',
      'fr': 'Gants',
    }, fails: true);
    expect(_canSave(tester), isFalse);
    await _type(tester, 1, '');
    expect(_canSave(tester), isTrue);
    await _save(tester);
    expect(_canSave(tester), isTrue);
    await _save(tester);
    expect(saves, [
      {'en': 'Gloves'},
      {'en': 'Gloves'},
    ]);
  });
}
