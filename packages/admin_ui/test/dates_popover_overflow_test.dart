import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(DateGranularity g, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: [Locale(locale)],
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: DateBody(
        value: DateTime(2026, 6, 25, 18, 30),
        granularity: g,
        locale: locale,
        onChanged: (_) {},
      ),
    ),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting());

  for (final g in DateGranularity.values) {
    testWidgets('date popover does not overflow — $g', (tester) async {
      await tester.pumpWidget(_host(g));
      await tester.tap(find.byType(DateBody));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'popover overflowed for $g',
      );
    });
  }
}
