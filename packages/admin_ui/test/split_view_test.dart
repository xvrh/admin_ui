import 'package:admin_ui/src/common/ui/split_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
);

double _width(WidgetTester tester, Key key) =>
    tester.getSize(find.byKey(key)).width;

void main() {
  testWidgets('renders both panes', (tester) async {
    await tester.pumpWidget(
      _host(SplitView.two(first: const Text('A'), second: const Text('B'))),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('initial weight sizes the first pane', (tester) async {
    await tester.pumpWidget(
      _host(
        SplitView.two(
          initialWeight: 0.25,
          first: Container(key: const Key('a')),
          second: Container(key: const Key('b')),
        ),
      ),
    );
    // 400 - 10 divider = 390 pane extent; 25% ≈ 97.5
    expect(_width(tester, const Key('a')), closeTo(97.5, 0.6));
  });

  testWidgets('dragging the divider grows the first pane and fires callback', (
    tester,
  ) async {
    List<double>? changed;
    await tester.pumpWidget(
      _host(
        SplitView.two(
          first: Container(key: const Key('a')),
          second: Container(key: const Key('b')),
          onWeightsChanged: (w) => changed = w,
        ),
      ),
    );
    final before = _width(tester, const Key('a'));
    await tester.drag(
      find.byType(SplitView).hitTestable(),
      const Offset(60, 0),
    );
    await tester.pump();

    expect(_width(tester, const Key('a')), greaterThan(before + 40));
    expect(changed, isNotNull);
    expect(changed!.reduce((a, b) => a + b), closeTo(1.0, 0.001));
  });

  testWidgets('min sizes clamp the drag', (tester) async {
    await tester.pumpWidget(
      _host(
        SplitView.two(
          initialWeight: 0.5,
          minFirst: 100,
          first: Container(key: const Key('a')),
          second: Container(key: const Key('b')),
        ),
      ),
    );
    await tester.drag(
      find.byType(SplitView).hitTestable(),
      const Offset(-300, 0),
    );
    await tester.pump();
    expect(_width(tester, const Key('a')), greaterThanOrEqualTo(99.0));
  });
}
