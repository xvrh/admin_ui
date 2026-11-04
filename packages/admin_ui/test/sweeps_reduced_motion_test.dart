import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [child] with the platform asking for less motion, or not.
Widget _host(Widget child, {required bool reduced}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

/// Pumps [child] and a few frames after it, and returns whether it still
/// schedules frames then.
Future<bool> _animates(
  WidgetTester tester,
  Widget child, {
  required bool reduced,
}) async {
  await tester.pumpWidget(_host(child, reduced: reduced));
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return tester.binding.hasScheduledFrame;
}

void main() {
  testWidgets('an indeterminate progress bar holds a still segment', (
    tester,
  ) async {
    const bar = ProgressBar(value: null);
    expect(await _animates(tester, bar, reduced: false), isTrue);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    expect(await _animates(tester, bar, reduced: true), isFalse);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(StillLinearProgress), findsOneWidget);
  });

  testWidgets('a determinate progress bar is drawn as before', (tester) async {
    expect(
      await _animates(tester, const ProgressBar(value: 0.4), reduced: true),
      isFalse,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('the top loading bar holds still and is still announced', (
    tester,
  ) async {
    expect(
      await _animates(tester, const TopProgressBar(), reduced: false),
      isTrue,
    );
    final handle = tester.ensureSemantics();
    expect(
      await _animates(tester, const TopProgressBar(), reduced: true),
      isFalse,
    );
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    handle.dispose();
  });
}
