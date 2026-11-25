import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// A ChartCard whose own load failed: `error` shows an ErrorState in the
// chart's place, in words, with a Retry where `onRetry` is given.

const _chart = Key('chart');
const _trailing = Key('trailing');
const _en = AdminLocalizationsEn();

Widget _host(
  Widget child, {
  double width = 400,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: irisPalette)),
  locale: locale,
  supportedLocales: _kitLanguages.locales,
  localizationsDelegates: _kitLanguages.delegates,
  home: MediaQuery.withClampedTextScaling(
    minScaleFactor: textScale,
    maxScaleFactor: textScale,
    child: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

Widget _card({
  Object? error,
  VoidCallback? onRetry,
  bool loading = false,
  bool isEmpty = false,
  double bodyHeight = 220,
  VoidCallback? onTrailing,
}) => ChartCard(
  title: 'Revenue',
  subtitle: 'Last 6 months',
  trailing: TextButton(
    key: _trailing,
    onPressed: onTrailing ?? () {},
    child: const Text('6M'),
  ),
  loading: loading,
  error: error,
  onRetry: onRetry,
  isEmpty: isEmpty,
  bodyHeight: bodyHeight,
  chart: SizedBox(key: _chart, height: bodyHeight),
);

void main() {
  testWidgets('with no error it shows its chart', (tester) async {
    await tester.pumpWidget(_host(_card()));
    expect(find.byKey(_chart), findsOneWidget);
    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('an error takes the chart\'s place, in words', (tester) async {
    await tester.pumpWidget(_host(_card(error: TimeoutException('revenue'))));
    expect(find.byKey(_chart), findsNothing);
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text(_en.couldNotLoad), findsOneWidget);
    expect(find.text(_en.display.errorTimeout), findsOneWidget);
    // Never the error's own text.
    expect(find.textContaining('TimeoutException'), findsNothing);
    expect(find.textContaining('revenue'), findsNothing);
    // The header is the card's own, as with a chart.
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Last 6 months'), findsOneWidget);
  });

  testWidgets('Retry is offered where onRetry is given, and calls it', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(_host(_card(error: StateError('offline'))));
    expect(find.text(_en.retry), findsNothing);

    await tester.pumpWidget(
      _host(_card(error: StateError('offline'), onRetry: () => retried++)),
    );
    await tester.tap(find.text(_en.retry));
    expect(retried, 1);
    // An error it has no words for says so, and to try again.
    expect(find.text(_en.somethingWentWrongTryAgain), findsOneWidget);
  });

  testWidgets('the Retry button takes retryKey', (tester) async {
    const retry = Key('revenue.retry');
    var retried = 0;
    await tester.pumpWidget(
      _host(
        ChartCard(
          title: 'Revenue',
          error: StateError('offline'),
          onRetry: () => retried++,
          retryKey: retry,
          chart: const SizedBox(key: _chart, height: 220),
        ),
      ),
    );
    await tester.tap(find.byKey(retry));
    expect(retried, 1);
  });

  testWidgets('onRetry alone shows nothing', (tester) async {
    await tester.pumpWidget(_host(_card(onRetry: () {})));
    expect(find.byKey(_chart), findsOneWidget);
    expect(find.text(_en.retry), findsNothing);
  });

  testWidgets('loading comes first: a retry in flight shows the skeleton', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_card(error: StateError('offline'), onRetry: () {}, loading: true)),
    );
    expect(find.byType(ErrorState), findsNothing);
    expect(find.byKey(_chart), findsNothing);
    expect(find.text(_en.retry), findsNothing);

    // And the error is back when the retry failed too.
    await tester.pumpWidget(
      _host(_card(error: StateError('offline'), onRetry: () {})),
    );
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('an error shows over the empty state', (tester) async {
    await tester.pumpWidget(
      _host(_card(error: StateError('offline'), isEmpty: true)),
    );
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
    expect(find.text(_en.display.chartEmpty), findsNothing);
  });

  testWidgets('the trailing control stays in the header, and usable', (
    tester,
  ) async {
    var picked = 0;
    await tester.pumpWidget(
      _host(
        _card(error: StateError('offline'), onTrailing: () => picked++),
        width: 600,
      ),
    );
    final trailing = tester.getRect(find.byKey(_trailing));
    expect(
      trailing.bottom,
      lessThan(tester.getRect(find.byType(ErrorState)).top),
    );
    await tester.tap(find.byKey(_trailing));
    expect(picked, 1);
  });

  testWidgets('the card is as tall as with its chart, or as its error needs', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_card()));
    final withChart = tester.getSize(find.byType(ChartCard));

    await tester.pumpWidget(
      _host(_card(error: StateError('offline'), onRetry: () {})),
    );
    expect(tester.getSize(find.byType(ErrorState)).height, 220);
    expect(tester.getSize(find.byType(ChartCard)), withChart);

    // A short card grows to hold the message and its button.
    await tester.pumpWidget(
      _host(
        _card(error: StateError('offline'), onRetry: () {}, bodyHeight: 80),
      ),
    );
    expect(tester.getSize(find.byType(ErrorState)).height, greaterThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('it holds at twice the text size in a narrow card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _card(error: TimeoutException('revenue'), onRetry: () {}),
        width: 260,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(_en.display.errorTimeout), findsOneWidget);
    expect(find.text(_en.retry), findsOneWidget);
  });

  testWidgets('an ErrorTextScope rewords it', (tester) async {
    await tester.pumpWidget(
      _host(
        ErrorTextScope(
          describe: (error) => 'The revenue service is down.',
          child: _card(error: StateError('offline')),
        ),
      ),
    );
    expect(find.text('The revenue service is down.'), findsOneWidget);
    expect(find.text(_en.somethingWentWrongTryAgain), findsNothing);
  });

  testWidgets('it follows the locale', (tester) async {
    const fr = AdminLocalizationsFr();
    await tester.pumpWidget(
      _host(
        _card(error: TimeoutException('revenue'), onRetry: () {}),
        locale: const Locale('fr'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(fr.couldNotLoad), findsOneWidget);
    expect(find.text(fr.display.errorTimeout), findsOneWidget);
    expect(find.text(fr.retry), findsOneWidget);
    expect(fr.couldNotLoad, isNot(_en.couldNotLoad));
  });

  testWidgets('a new error replaces the one shown', (tester) async {
    await tester.pumpWidget(_host(_card(error: TimeoutException('revenue'))));
    expect(find.text(_en.display.errorTimeout), findsOneWidget);
    await tester.pumpWidget(
      _host(_card(error: 'The export is still running.')),
    );
    expect(find.text(_en.display.errorTimeout), findsNothing);
    // A string thrown as the error is its own message.
    expect(find.text('The export is still running.'), findsOneWidget);
    // And clearing it brings the chart back.
    await tester.pumpWidget(_host(_card()));
    expect(find.byType(ErrorState), findsNothing);
    expect(find.byKey(_chart), findsOneWidget);
  });
}
