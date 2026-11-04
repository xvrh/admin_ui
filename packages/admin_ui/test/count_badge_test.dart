import 'package:admin_ui/src/common/ui/count_badge.dart';
import 'package:admin_ui/src/l10n/admin_ui_localizations.dart';
import 'package:admin_ui/src/l10n/formats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('caps the count at max with a +', (tester) async {
    await tester.pumpWidget(_host(const CountBadge(count: 1500, max: 99)));
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets("the count is written in the app locale's digits", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        supportedLocales: AdminLocalizations.supportedLocales,
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        home: Scaffold(body: CountBadge(count: 1500, max: 9999)),
      ),
    );
    final french = AdminFormats('fr').integer(1500);
    expect(french, isNot('1500'), reason: 'French groups the thousands');
    expect(find.text(french), findsOneWidget);
  });

  testWidgets('the count stays on one line, even squeezed', (tester) async {
    await tester.pumpWidget(_host(const CountBadge(count: 12)));
    final line = tester.getSize(find.text('12')).height;

    // Narrower than the digits: the label must clip, never stack "1" over "2".
    await tester.pumpWidget(
      _host(const SizedBox(width: 12, child: CountBadge(count: 12))),
    );
    expect(tester.getSize(find.text('12')).height, line);
  });

  testWidgets('zero count hides unless showZero', (tester) async {
    await tester.pumpWidget(_host(const CountBadge(count: 0)));
    expect(find.byType(Text), findsNothing);

    await tester.pumpWidget(_host(const CountBadge(count: 0, showZero: true)));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('overlays a child and still shows it when hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const CountBadge(count: 0, child: Icon(Icons.mail))),
    );
    expect(find.byIcon(Icons.mail), findsOneWidget);
    expect(find.byType(Text), findsNothing);

    await tester.pumpWidget(
      _host(const CountBadge(count: 4, child: Icon(Icons.mail))),
    );
    expect(find.byIcon(Icons.mail), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}
