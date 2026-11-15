import 'package:admin_ui/src/common/ui/split_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {double width = 400}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, height: 300, child: child),
    ),
  ),
);

/// Three panes keyed a, b and c: a and c sized, b free.
SplitView _sized({
  List<double?> sizes = const [100, null, 80],
  List<double>? minSizes,
  ValueChanged<List<double?>>? onSizesChanged,
}) => SplitView(
  initialSizes: sizes,
  minSizes: minSizes,
  onSizesChanged: onSizesChanged,
  children: [
    Container(key: const Key('a')),
    Container(key: const Key('b')),
    Container(key: const Key('c')),
  ],
);

List<double> _widths(WidgetTester tester) => [
  for (final key in ['a', 'b', 'c']) _width(tester, Key(key)),
];

Finder get _dividers => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_Divider',
);

/// Drags [divider] by [dx] past the touch slop, which the drag swallows.
Future<void> _drag(WidgetTester tester, Finder divider, double dx) async {
  final gesture = await tester.startGesture(tester.getCenter(divider));
  await gesture.moveBy(Offset(dx.sign * kDragSlopDefault * 2, 0));
  await gesture.moveBy(Offset(dx, 0));
  await gesture.up();
  await tester.pump();
}

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

  group('sized panes', () {
    testWidgets('keep their size as the view resizes, the free pane taking '
        'the rest', (tester) async {
      await tester.pumpWidget(_host(_sized(), width: 600));
      // 600 - 2 dividers of 10.
      expect(_widths(tester), [100, 400, 80]);
      await tester.pumpWidget(_host(_sized(), width: 800));
      expect(_widths(tester), [100, 600, 80]);
    });

    testWidgets('a divider resizes the sized pane beside it, and the drag '
        'reports the sizes', (tester) async {
      List<double?>? changed;
      await tester.pumpWidget(
        _host(_sized(onSizesChanged: (s) => changed = s), width: 600),
      );
      await _drag(tester, _dividers.first, 60);
      expect(_widths(tester), [160, 340, 80]);
      expect(changed, [160, null, 80]);

      await _drag(tester, _dividers.last, -40);
      expect(_widths(tester), [160, 300, 120]);
      expect(changed, [160, null, 120]);
    });

    testWidgets('a drag stops at the min sizes', (tester) async {
      await tester.pumpWidget(
        _host(_sized(minSizes: const [80, 200, 80]), width: 600),
      );
      await _drag(tester, _dividers.first, -60);
      expect(_widths(tester).first, 80);
      await _drag(tester, _dividers.first, 400);
      expect(_widths(tester)[1], 200);
    });

    testWidgets('short of room, the sized panes give way to their min sizes '
        'first, and take their sizes back as the view widens', (tester) async {
      final view = _sized(
        sizes: const [200, null, 200],
        minSizes: const [100, 150, 100],
      );
      await tester.pumpWidget(_host(view));
      // 380 to share: the free pane keeps its 150, the sized ones split the
      // 30 left above their 100 each in proportion to what they had above it.
      expect(_widths(tester), [115, 150, 115]);
      await tester.pumpWidget(_host(view, width: 700));
      expect(_widths(tester), [200, 280, 200]);
    });

    testWidgets('narrower than every min size, the panes share the width by '
        'their min sizes', (tester) async {
      await tester.pumpWidget(
        _host(
          _sized(
            sizes: const [200, null, 200],
            minSizes: const [100, 150, 100],
          ),
          width: 300,
        ),
      );
      expect(_widths(tester), [80, 120, 80]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SplitView.two keeps the second pane at its size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SplitView.two(
            secondSize: 120,
            first: Container(key: const Key('a')),
            second: Container(key: const Key('b')),
          ),
          width: 600,
        ),
      );
      expect(_width(tester, const Key('b')), 120);
      expect(_width(tester, const Key('a')), 470);
    });
  });
}
