import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(
  Widget child, {
  double width = 400,
  double height = 300,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  ),
);

/// Two weighted panes keyed a and b, in 400: 390 to share, half each.
SplitView _two({
  SplitAxis axis = SplitAxis.horizontal,
  double minFirst = 80,
  double minSecond = 80,
  ValueChanged<List<double>>? onWeightsChanged,
}) => SplitView.two(
  axis: axis,
  minFirst: minFirst,
  minSecond: minSecond,
  onWeightsChanged: onWeightsChanged,
  first: Container(key: const Key('a')),
  second: Container(key: const Key('b')),
);

void _noop() {}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

/// Right-clicks [divider], which opens its menu.
Future<void> _rightClick(WidgetTester tester, Finder divider) async {
  final mouse = await tester.startGesture(
    tester.getCenter(divider),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await mouse.up();
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String item) async {
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

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

  group('a divider, from the keyboard', () {
    testWidgets('is a Tab stop, a slider that says the share its pane takes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_two()));
      await _press(tester, LogicalKeyboardKey.tab);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Resize panes')),
        isSemantics(
          label: 'Resize panes',
          value: '50%',
          // 16 of the 390 the two panes share.
          increasedValue: '54%',
          decreasedValue: '46%',
          isSlider: true,
          isFocusable: true,
          isFocused: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
          customActions: [const CustomSemanticsAction(label: 'Collapse')],
        ),
      );
      handle.dispose();
    });

    testWidgets('moves the way the arrow points, 16 pixels a press, and '
        'reports each move', (tester) async {
      final reported = <List<double>>[];
      await tester.pumpWidget(_host(_two(onWeightsChanged: reported.add)));
      await _press(tester, LogicalKeyboardKey.tab);

      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(_width(tester, const Key('a')), closeTo(211, 0.01));
      expect(_width(tester, const Key('b')), closeTo(179, 0.01));
      expect(reported, hasLength(1));

      await _press(tester, LogicalKeyboardKey.arrowLeft);
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(_width(tester, const Key('a')), closeTo(179, 0.01));
      expect(reported, hasLength(3));
      expect(reported.last.first, closeTo(179 / 390, 0.0001));

      // The arrows across the divider are not its keys.
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_width(tester, const Key('a')), closeTo(179, 0.01));
      expect(reported, hasLength(3));
    });

    testWidgets('right to left, → still moves the divider right: the start '
        'pane, on the right, gives way', (tester) async {
      await tester.pumpWidget(_host(_two(), direction: TextDirection.rtl));
      expect(
        tester.getTopLeft(find.byKey(const Key('a'))).dx,
        greaterThan(tester.getTopLeft(find.byKey(const Key('b'))).dx),
      );
      await _press(tester, LogicalKeyboardKey.tab);
      final before = tester.getCenter(_dividers).dx;

      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(tester.getCenter(_dividers).dx, closeTo(before + 16, 0.01));
      expect(_width(tester, const Key('a')), closeTo(179, 0.01));

      await _press(tester, LogicalKeyboardKey.arrowLeft);
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(_width(tester, const Key('a')), closeTo(211, 0.01));
    });

    testWidgets('between stacked panes, ↑ and ↓ move it', (tester) async {
      await tester.pumpWidget(
        _host(_two(axis: SplitAxis.vertical), height: 400),
      );
      double height(String key) => tester.getSize(find.byKey(Key(key))).height;
      await _press(tester, LogicalKeyboardKey.tab);

      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(height('a'), closeTo(211, 0.01));
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(height('a'), closeTo(179, 0.01));

      await _press(tester, LogicalKeyboardKey.arrowRight);
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(height('a'), closeTo(179, 0.01));
    });

    testWidgets('Home and End take its pane to its smallest and its largest, '
        'where the arrows stop', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_two(minFirst: 100, minSecond: 120)));
      await _press(tester, LogicalKeyboardKey.tab);

      await _press(tester, LogicalKeyboardKey.home);
      expect(_width(tester, const Key('a')), closeTo(100, 0.01));
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(_width(tester, const Key('a')), closeTo(100, 0.01));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Resize panes')),
        isSemantics(
          label: 'Resize panes',
          value: '26%',
          increasedValue: '30%',
          decreasedValue: '26%',
          isSlider: true,
          isFocusable: true,
          isFocused: true,
          hasIncreaseAction: true,
          hasFocusAction: true,
        ),
      );

      await _press(tester, LogicalKeyboardKey.end);
      expect(_width(tester, const Key('a')), closeTo(270, 0.01));
      expect(_width(tester, const Key('b')), closeTo(120, 0.01));
      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(_width(tester, const Key('b')), closeTo(120, 0.01));
      handle.dispose();
    });

    testWidgets('at a limit an arrow stays the divider\'s key: focus does '
        'not leave for a neighbour', (tester) async {
      await tester.pumpWidget(
        _host(
          SplitView.two(
            first: const Center(child: Button('Left', onPressed: _noop)),
            second: const Center(child: Button('Right', onPressed: _noop)),
          ),
        ),
      );
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.tab);
      String? focused() => FocusManager.instance.primaryFocus?.debugLabel;
      expect(focused(), 'split view divider');

      await _press(tester, LogicalKeyboardKey.home);
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(focused(), 'split view divider');
      await _press(tester, LogicalKeyboardKey.end);
      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(focused(), 'split view divider');
    });

    testWidgets('Enter collapses its pane to its min size, and restores the '
        'size it had', (tester) async {
      final reported = <List<double>>[];
      await tester.pumpWidget(
        _host(_two(minFirst: 100, onWeightsChanged: reported.add)),
      );
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.arrowRight);

      await _press(tester, LogicalKeyboardKey.enter);
      expect(_width(tester, const Key('a')), closeTo(100, 0.01));
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_width(tester, const Key('a')), closeTo(211, 0.01));
      expect(reported, hasLength(3));

      // Moved after it collapsed, it has no size to go back to: Enter
      // collapses it again.
      await _press(tester, LogicalKeyboardKey.enter);
      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(_width(tester, const Key('a')), closeTo(116, 0.01));
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_width(tester, const Key('a')), closeTo(100, 0.01));

      // At its min size by another way, there is nothing to restore.
      await _press(tester, LogicalKeyboardKey.arrowRight);
      await _press(tester, LogicalKeyboardKey.home);
      final count = reported.length;
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_width(tester, const Key('a')), closeTo(100, 0.01));
      expect(reported, hasLength(count));
    });

    testWidgets('a collapsed pane resized by its other divider is no longer '
        'collapsed: Enter collapses it again, and the menu says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      // Three weighted panes of 200: the second is the pane of the second
      // divider, and the first divider resizes it too.
      await tester.pumpWidget(
        _host(
          SplitView(
            children: [
              Container(key: const Key('a')),
              Container(key: const Key('b')),
              Container(key: const Key('c')),
            ],
          ),
          width: 620,
        ),
      );
      List<String?> actions(Finder divider) => [
        for (final id
            in tester
                    .getSemantics(divider)
                    .getSemanticsData()
                    .customSemanticsActionIds ??
                const <int>[])
          CustomSemanticsAction.getAction(id)!.label,
      ];
      final second = find.bySemanticsLabel('Resize panes').last;
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_widths(tester)[1], closeTo(80, 0.01));
      expect(actions(second), ['Expand']);

      // The first divider gives the pane 16 more.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _press(tester, LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(_widths(tester)[0], closeTo(184, 0.01));
      expect(_widths(tester)[1], closeTo(96, 0.01));
      expect(actions(second), ['Collapse']);

      await _rightClick(tester, _dividers.last);
      expect(find.text('Collapse'), findsOneWidget);
      expect(find.text('Expand'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Enter on its own divider collapses it, and does not jump to the
      // 200 it had before.
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_widths(tester)[1], closeTo(80, 0.01));
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_widths(tester)[1], closeTo(96, 0.01));
      handle.dispose();
    });

    testWidgets('a collapsed pane dragged by its other divider is no longer '
        'collapsed', (tester) async {
      await tester.pumpWidget(
        _host(
          SplitView(
            children: [
              Container(key: const Key('a')),
              Container(key: const Key('b')),
              Container(key: const Key('c')),
            ],
          ),
          width: 620,
        ),
      );
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_widths(tester)[1], closeTo(80, 0.01));

      await tester.drag(_dividers.first, const Offset(-40, 0));
      await tester.pumpAndSettle();
      expect(_widths(tester)[1], closeTo(120, 0.01));
      await _rightClick(tester, _dividers.last);
      expect(find.text('Collapse'), findsOneWidget);
      expect(find.text('Expand'), findsNothing);
    });

    testWidgets('beside the free pane, resizes the sized pane: an '
        'inspector collapses, not the content', (tester) async {
      List<double?>? changed;
      await tester.pumpWidget(
        _host(
          _sized(
            sizes: const [100, null, 120],
            onSizesChanged: (s) => changed = s,
          ),
          width: 600,
        ),
      );
      expect(_widths(tester), [100, 360, 120]);
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.tab);

      // → takes the divider toward the end, where its pane is.
      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(_widths(tester), [100, 376, 104]);
      expect(changed, [100, null, 104]);

      await _press(tester, LogicalKeyboardKey.enter);
      expect(_widths(tester), [100, 400, 80]);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_widths(tester), [100, 376, 104]);

      await _press(tester, LogicalKeyboardKey.end);
      expect(_widths(tester), [100, 80, 400]);
      await _press(tester, LogicalKeyboardKey.home);
      expect(_widths(tester), [100, 400, 80]);
      expect(changed, [100, null, 80]);
    });

    testWidgets('shows the focus ring, inside the view, on keyboard focus '
        'only', (tester) async {
      Finder ring() => find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border is Border &&
            ((w.decoration as BoxDecoration).border! as Border).top.color ==
                defaultTokens.palette.focusRing,
      );
      await tester.pumpWidget(_host(_two()));
      expect(ring(), findsNothing);

      await _press(tester, LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final view = tester.getRect(find.byType(SplitView));
      expect(ring(), findsOneWidget);
      expect(tester.getRect(ring()).top, view.top);
      expect(tester.getRect(ring()).bottom, view.bottom);

      // A drag takes the focus without the ring, and the keys follow it.
      await tester.drag(_dividers, const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(ring(), findsNothing);
      final dragged = _width(tester, const Key('a'));
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(_width(tester, const Key('a')), closeTo(dragged - 16, 0.01));
    });
  });

  group('a divider, without a drag', () {
    testWidgets('a screen reader grows and shrinks its pane, and collapses '
        'it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_two()));
      final divider = find.semantics.byLabel('Resize panes');

      tester.semantics.increase(divider);
      await tester.pump();
      expect(_width(tester, const Key('a')), closeTo(211, 0.01));
      tester.semantics.decrease(divider);
      tester.semantics.decrease(divider);
      await tester.pump();
      expect(_width(tester, const Key('a')), closeTo(179, 0.01));

      tester.semantics.customAction(
        divider,
        const CustomSemanticsAction(label: 'Collapse'),
      );
      await tester.pump();
      expect(_width(tester, const Key('a')), closeTo(80, 0.01));
      tester.semantics.customAction(
        divider,
        const CustomSemanticsAction(label: 'Expand'),
      );
      await tester.pump();
      expect(_width(tester, const Key('a')), closeTo(179, 0.01));
      handle.dispose();
    });

    testWidgets('a right-click opens a menu of the same moves, each beside '
        'its key', (tester) async {
      await tester.pumpWidget(_host(_two(minFirst: 100)));
      await _rightClick(tester, _dividers);
      expect(find.text('Move left'), findsOneWidget);
      expect(find.text('←'), findsOneWidget);
      expect(find.text('Move right'), findsOneWidget);
      expect(find.text('→'), findsOneWidget);
      expect(find.text('Collapse'), findsOneWidget);

      await _choose(tester, 'Move right');
      expect(_width(tester, const Key('a')), closeTo(211, 0.01));

      await _rightClick(tester, _dividers);
      await _choose(tester, 'Collapse');
      expect(_width(tester, const Key('a')), closeTo(100, 0.01));

      // Collapsed, the pane has no further to go left, and expands back.
      await _rightClick(tester, _dividers);
      expect(find.text('Collapse'), findsNothing);
      await _choose(tester, 'Move left');
      expect(_width(tester, const Key('a')), closeTo(100, 0.01));
      await _choose(tester, 'Expand');
      expect(_width(tester, const Key('a')), closeTo(211, 0.01));
    });

    testWidgets('between stacked panes the menu moves it up and down', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_two(axis: SplitAxis.vertical), height: 400),
      );
      await _rightClick(tester, _dividers);
      expect(find.text('Move left'), findsNothing);
      await _choose(tester, 'Move down');
      expect(
        tester.getSize(find.byKey(const Key('a'))).height,
        closeTo(211, 0.01),
      );
      await _rightClick(tester, _dividers);
      await _choose(tester, 'Move up');
      expect(
        tester.getSize(find.byKey(const Key('a'))).height,
        closeTo(195, 0.01),
      );
    });

    testWidgets('a long press with a finger opens the menu, and a drag '
        'still follows the finger from where it landed', (tester) async {
      await tester.pumpWidget(_host(_two()));
      await tester.longPress(_dividers);
      await tester.pumpAndSettle();
      expect(find.text('Move right'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Move right'), findsNothing);

      await tester.drag(_dividers, const Offset(60, 0));
      await tester.pump();
      expect(_width(tester, const Key('a')), closeTo(255, 0.01));
    });
  });
}
