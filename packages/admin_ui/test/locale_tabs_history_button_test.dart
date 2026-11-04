// LocaleTabs selects the tab of activeLocale, and the history button compares
// the draft with a baseline under a label the host can set.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Center(child: SizedBox(width: 520, child: child)),
  ),
);

const _locales = [
  LocaleInfo(code: 'en', status: LocaleStatus.source),
  LocaleInfo(code: 'fr', status: LocaleStatus.translated),
  LocaleInfo(code: 'de', status: LocaleStatus.missing),
];

void main() {
  group('LocaleTabs', () {
    testWidgets('activeLocale selects its tab and onActiveLocaleChanged '
        'reports a pick', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          LocaleTabs(
            lanes: _locales,
            activeLocale: 'fr',
            onActiveLocaleChanged: (code) => picked = code,
            modified: const {'de'},
          ),
        ),
      );
      final tabs = tester.widget<Tabs>(find.byType(Tabs));
      expect(tabs.selected, 1);
      expect(tabs.size, ControlSize.small);
      await tester.tap(find.text('EN'));
      expect(picked, 'en');
    });

    testWidgets('a single locale shows no strip', (tester) async {
      await tester.pumpWidget(
        _host(
          LocaleTabs(
            lanes: _locales.take(1).toList(),
            activeLocale: 'en',
            onActiveLocaleChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Tabs), findsNothing);
    });
  });

  group('HistoryButton', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Edited'));
      await tester.pumpAndSettle();
    }

    testWidgets('compares the draft with the baseline, labelled "Live" by '
        'default', (tester) async {
      await tester.pumpWidget(
        _host(const HistoryButton(draft: 'Summer sale', baseline: 'Sale')),
      );
      await open(tester);
      expect(find.text('Sale'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('baselineLabel names the baseline', (tester) async {
      await tester.pumpWidget(
        _host(
          const HistoryButton(
            draft: 'Summer sale',
            baseline: 'Sale',
            baselineLabel: 'Saved',
          ),
        ),
      );
      await open(tester);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Live'), findsNothing);
    });
  });
}
