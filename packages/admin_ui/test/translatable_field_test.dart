import 'package:admin_ui/src/fields/ui/translatable_field.dart';
import 'package:admin_ui/src/i18n/locale_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _locales = [
  LocaleInfo(code: 'EN', native: 'English', status: LocaleStatus.source),
  LocaleInfo(code: 'ES', native: 'Español', status: LocaleStatus.translated),
  LocaleInfo(code: 'DE', native: 'Deutsch', status: LocaleStatus.outdated),
];

Widget _host({
  required Set<String> visible,
  String active = 'ES',
  void Function(String, String)? onChanged,
  Widget? Function(LocaleInfo)? laneTrailing,
  Widget? headerTrailing,
  Set<String> modified = const {},
}) => MaterialApp(
  home: Scaffold(
    body: TranslatableField(
      label: 'Title',
      locales: _locales,
      visibleLocales: visible,
      sourceLocale: 'EN',
      activeLocale: active,
      values: const {
        'EN': 'English text',
        'ES': 'Texto ES',
        'DE': 'Deutsch alt',
      },
      modifiedLanes: modified,
      onVisibleLocalesChanged: (_) {},
      onChanged: onChanged,
      laneTrailing: laneTrailing,
      headerTrailing: headerTrailing,
    ),
  ),
);

class _LiveHost extends StatefulWidget {
  const _LiveHost();

  @override
  State<_LiveHost> createState() => _LiveHostState();
}

class _LiveHostState extends State<_LiveHost> {
  Set<String> _visible = {'ES'};
  String _active = 'ES';
  final _values = {'EN': 'English text', 'ES': 'Texto ES', 'DE': 'Deutsch alt'};

  @override
  Widget build(BuildContext context) {
    return TranslatableField(
      label: 'Title',
      locales: _locales,
      visibleLocales: _visible,
      sourceLocale: 'EN',
      activeLocale: _active,
      values: _values,
      onVisibleLocalesChanged: (next) => setState(() {
        _visible = next;
        if (!next.contains(_active)) {
          _active = next.contains('EN') ? 'EN' : next.first;
        }
      }),
      onActiveLocaleChanged: (code) => setState(() => _active = code),
      onChanged: (code, value) => _values[code] = value,
    );
  }
}

void main() {
  testWidgets('single locale edits in place', (tester) async {
    final changes = <String, String>{};
    await tester.pumpWidget(
      _host(visible: {'ES'}, onChanged: (c, v) => changes[c] = v),
    );

    expect(find.text('Texto ES'), findsOneWidget);
    expect(find.text('Deutsch alt'), findsNothing); // not in view

    await tester.enterText(find.text('Texto ES'), 'Texto nuevo');
    expect(changes['ES'], 'Texto nuevo');
  });

  testWidgets('several locales stack source-first and flag outdated', (
    tester,
  ) async {
    await tester.pumpWidget(_host(visible: {'EN', 'ES', 'DE'}));

    expect(find.text('EN · ES · DE'), findsOneWidget); // pill lists the set
    expect(find.byTooltip('Source'), findsOneWidget); // EN lane status dot
    expect(
      find.text('DE'),
      findsOneWidget,
    ); // lane code; pill is the joined string
    expect(find.byTooltip('Outdated'), findsOneWidget); // DE lane status dot
  });

  testWidgets('checking a box keeps the picker open and adds the lane', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _LiveHost())),
    );

    await tester.tap(find.byKey(const Key('language-pill')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('lang-check-DE')));
    await tester.pumpAndSettle();

    // Popover did not tear down on the set change...
    expect(
      find.text('Tap to switch · check to compare side by side.'),
      findsOneWidget,
    );
    // ...and the newly-checked lane (plus auto-added source) is now editable.
    expect(find.text('Deutsch alt'), findsOneWidget);
    expect(find.text('English text'), findsOneWidget);
  });

  testWidgets('renders header + per-lane capability slots when stacked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        visible: {'EN', 'ES'},
        headerTrailing: const Text('HEADER-CAP'),
        laneTrailing: (lane) => Text('cap-${lane.code}'),
      ),
    );

    expect(find.text('HEADER-CAP'), findsOneWidget);
    expect(find.byTooltip('Source'), findsOneWidget); // EN lane status dot
    expect(find.text('cap-EN'), findsOneWidget);
    expect(find.text('cap-ES'), findsOneWidget);
  });

  testWidgets('a modified lane surfaces a field-level marker listing it', (
    tester,
  ) async {
    await tester.pumpWidget(_host(visible: {'EN', 'ES'}, modified: {'ES'}));

    expect(find.text('Edited · ES'), findsOneWidget);
  });

  testWidgets('the active lane is marked by weight, not hue alone', (
    tester,
  ) async {
    await tester.pumpWidget(_host(visible: {'EN', 'ES'}));

    FontWeight weight(String code) =>
        tester.widget<Text>(find.text(code)).style!.fontWeight!;
    expect(weight('ES').value, greaterThan(weight('EN').value));
  });
}
