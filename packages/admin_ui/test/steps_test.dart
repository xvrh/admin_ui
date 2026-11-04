import 'package:admin_ui/src/common/ui/steps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _steps = [StepItem('One'), StepItem('Two'), StepItem('Three')];

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 500, child: child)),
  ),
);

void main() {
  testWidgets('renders titles and shows a check on completed steps', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const Steps(steps: _steps, current: 1)));

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    // step 0 is complete → a check; the active and upcoming show numbers.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // active node number
  });

  testWidgets('error step shows the error glyph', (tester) async {
    await tester.pumpWidget(
      _host(const Steps(steps: _steps, current: 2, errorSteps: {1})),
    );
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
  });

  testWidgets('taps a past step but not a future one', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      _host(Steps(steps: _steps, current: 1, onChanged: tapped.add)),
    );

    await tester.tap(find.text('One')); // completed → allowed
    await tester.tap(find.text('Three')); // future → ignored
    expect(tapped, [0]);
  });
}
