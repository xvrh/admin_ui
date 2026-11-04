import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(bool loading, {Duration? delay}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: delay == null
        ? DelayedLoading(
            loading: loading,
            builder: (context, show) => Text(show ? 'shown' : 'hidden'),
          )
        : DelayedLoading(
            loading: loading,
            delay: delay,
            builder: (context, show) => Text(show ? 'shown' : 'hidden'),
          ),
  ),
);

void main() {
  group('DelayedLoading', () {
    testWidgets('shows only after 150ms of continuous loading', (tester) async {
      await tester.pumpWidget(_host(true));
      expect(find.text('hidden'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 149));
      expect(find.text('hidden'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('shown'), findsOneWidget);
    });

    testWidgets('hides the moment loading ends', (tester) async {
      await tester.pumpWidget(_host(true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('shown'), findsOneWidget);
      await tester.pumpWidget(_host(false));
      expect(find.text('hidden'), findsOneWidget);
    });

    testWidgets('a load shorter than the delay never shows', (tester) async {
      await tester.pumpWidget(_host(true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_host(false));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('hidden'), findsOneWidget);
    });

    testWidgets('the delay restarts with each load', (tester) async {
      await tester.pumpWidget(_host(true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_host(false));
      await tester.pumpWidget(_host(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('hidden'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('shown'), findsOneWidget);
    });

    testWidgets('a rebuild mid-load keeps the running delay', (tester) async {
      await tester.pumpWidget(_host(true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_host(true));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('shown'), findsOneWidget);
    });

    testWidgets('a custom delay, and zero shows at once', (tester) async {
      await tester.pumpWidget(
        _host(true, delay: const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 399));
      expect(find.text('hidden'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('shown'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_host(true, delay: Duration.zero));
      expect(find.text('shown'), findsOneWidget);
    });

    testWidgets('disposed while waiting, it leaves no timer', (tester) async {
      await tester.pumpWidget(_host(true));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      // A pending timer at the end of a test fails it.
    });
  });

  group('TopProgressBar', () {
    testWidgets('a 2px primary bar on a clear track', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: const Scaffold(body: TopProgressBar()),
        ),
      );
      expect(tester.getSize(find.byType(TopProgressBar)).height, 2);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.color, defaultTokens.palette.primary);
      expect(bar.backgroundColor, Colors.transparent);
      expect(bar.minHeight, 2);
      expect(bar.semanticsLabel, 'Loading');
    });
  });
}
