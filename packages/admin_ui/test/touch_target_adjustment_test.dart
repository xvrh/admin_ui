import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Under a TouchTargetAdjustment a finger's near miss presses the control it
// was meant for, and nothing is laid out larger. What is under the finger
// keeps its claim, and a mouse presses what it points at.

final _taps = <String>[];

/// A 24px control named [name].
Widget _target(String name, {double size = 24, bool enabled = true}) =>
    Tappable(
      key: Key(name),
      onTap: enabled ? () => _taps.add(name) : null,
      child: SizedBox.square(dimension: size),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool adjust = true,
  double minSize = 48,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: TouchTargetAdjustment(
          enabled: adjust,
          minSize: minSize,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(padding: const EdgeInsets.all(60), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, String name) =>
    tester.getRect(find.byKey(Key(name)));

Future<void> _touch(WidgetTester tester, Offset at) async {
  await tester.tapAt(at);
  await tester.pump();
}

Future<void> _click(WidgetTester tester, Offset at) async {
  await tester.tapAt(at, kind: PointerDeviceKind.mouse);
  await tester.pump();
}

void main() {
  setUp(_taps.clear);

  group('a finger near a control', () {
    testWidgets('presses it from above, below and beside', (tester) async {
      await _pump(tester, _target('a'));
      final a = _rect(tester, 'a');
      for (final at in [
        a.topCenter + const Offset(0, -8),
        a.bottomCenter + const Offset(0, 10),
        a.centerLeft + const Offset(-11, 0),
        a.centerRight + const Offset(11, 0),
        a.topLeft + const Offset(-8, -8),
      ]) {
        _taps.clear();
        await _touch(tester, at);
        expect(_taps, ['a'], reason: 'at $at');
      }
    });

    testWidgets('does not press it from past its grown area', (tester) async {
      await _pump(tester, _target('a'));
      final a = _rect(tester, 'a');
      // 24 grows to 48: 12 on each side.
      await _touch(tester, a.topCenter + const Offset(0, -14));
      await _touch(tester, a.centerRight + const Offset(14, 0));
      expect(_taps, isEmpty);
    });

    testWidgets('grows a control to the minimum and no further', (
      tester,
    ) async {
      await _pump(tester, _target('a', size: 40));
      final a = _rect(tester, 'a');
      // 40 grows to 48: 4 on each side.
      await _touch(tester, a.centerRight + const Offset(3, 0));
      expect(_taps, ['a']);
      await _touch(tester, a.centerRight + const Offset(6, 0));
      expect(_taps, ['a']);

      _taps.clear();
      await _pump(tester, _target('a', size: 40), minSize: 64);
      await _touch(
        tester,
        _rect(tester, 'a').centerRight + const Offset(10, 0),
      );
      expect(_taps, ['a']);
    });

    testWidgets('on the control itself presses it once', (tester) async {
      await _pump(tester, _target('a'));
      await _touch(tester, _rect(tester, 'a').center);
      expect(_taps, ['a']);
    });

    testWidgets('nothing is laid out larger', (tester) async {
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [_target('a'), _target('b')],
        ),
      );
      expect(_rect(tester, 'a').size, const Size(24, 24));
      expect(_rect(tester, 'b').left, _rect(tester, 'a').right);
    });
  });

  group('between two controls', () {
    testWidgets('the nearer one takes it', (tester) async {
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [_target('a'), const SizedBox(width: 10), _target('b')],
        ),
      );
      final a = _rect(tester, 'a');
      final b = _rect(tester, 'b');
      await _touch(tester, Offset(a.right + 3, a.center.dy));
      await _touch(tester, Offset(b.left - 3, b.center.dy));
      expect(_taps, ['a', 'b']);
    });

    testWidgets('the nearer one, though the search meets the other first', (
      tester,
    ) async {
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [_target('a'), const SizedBox(width: 9), _target('b')],
        ),
      );
      // 3 from a and 6 from b, on the side the search looks at first.
      final a = _rect(tester, 'a');
      await _touch(tester, Offset(a.right + 3, a.center.dy));
      expect(_taps, ['a']);
    });

    testWidgets('a finger on one presses that one, however near the other', (
      tester,
    ) async {
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [_target('a'), _target('b')],
        ),
      );
      final b = _rect(tester, 'b');
      await _touch(tester, b.centerLeft + const Offset(1, 0));
      expect(_taps, ['b']);
    });
  });

  group('what is under the finger keeps its claim', () {
    testWidgets('a row that opens takes the tap, not the button in it', (
      tester,
    ) async {
      await _pump(
        tester,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _taps.add('row'),
          child: SizedBox(
            width: 300,
            height: 60,
            child: Center(child: _target('a')),
          ),
        ),
      );
      final a = _rect(tester, 'a');
      await _touch(tester, a.centerRight + const Offset(6, 0));
      expect(_taps, ['row']);
      _taps.clear();
      await _touch(tester, a.center);
      expect(_taps, ['a']);
    });

    testWidgets('a text field takes the tap, not the button beside it', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: Row(
            children: [
              Expanded(child: TextField(focusNode: focus)),
              _target('a'),
            ],
          ),
        ),
      );
      final a = _rect(tester, 'a');
      await _touch(tester, a.centerLeft + const Offset(-6, 0));
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(_taps, isEmpty);
    });

    testWidgets('a finger that moves scrolls the list, and presses nothing', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _pump(
        tester,
        SizedBox(
          width: 300,
          height: 300,
          child: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 40),
              Align(alignment: Alignment.centerLeft, child: _target('a')),
              const SizedBox(height: 900),
            ],
          ),
        ),
      );
      final a = _rect(tester, 'a');
      final from = a.bottomCenter + const Offset(0, 8);
      await tester.dragFrom(from, const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(50));
      expect(_taps, isEmpty);

      // A tap at the same distance presses it.
      scroll.jumpTo(0);
      await tester.pump();
      await _touch(
        tester,
        _rect(tester, 'a').bottomCenter + const Offset(0, 8),
      );
      expect(_taps, ['a']);
    });
  });

  group('no control is pressed', () {
    testWidgets('by a mouse beside it', (tester) async {
      await _pump(tester, _target('a'));
      final a = _rect(tester, 'a');
      await _click(tester, a.centerRight + const Offset(6, 0));
      expect(_taps, isEmpty);
      await _click(tester, a.center);
      expect(_taps, ['a']);
    });

    testWidgets('that is disabled', (tester) async {
      await _pump(tester, _target('a', enabled: false));
      await _touch(tester, _rect(tester, 'a').centerRight + const Offset(6, 0));
      expect(_taps, isEmpty);
    });

    testWidgets('instead of the enabled one beside a disabled one', (
      tester,
    ) async {
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _target('off', enabled: false),
            const SizedBox(width: 16),
            _target('on'),
          ],
        ),
      );
      // Nearer the disabled control, and still within reach of the other.
      final off = _rect(tester, 'off');
      await _touch(tester, off.centerRight + const Offset(6, 0));
      expect(_taps, ['on']);
    });

    testWidgets('that something covers', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 200,
          height: 60,
          child: Stack(
            children: [
              Positioned(left: 40, top: 18, child: _target('a')),
              // A veil over the control, short of where the finger lands.
              const Positioned(
                left: 30,
                top: 0,
                width: 44,
                height: 60,
                child: ColoredBox(color: Color(0x44000000)),
              ),
            ],
          ),
        ),
      );
      final a = _rect(tester, 'a');
      await _touch(tester, a.centerRight + const Offset(11, 0));
      expect(_taps, isEmpty);
    });

    testWidgets('where the adjustment is off', (tester) async {
      await _pump(tester, _target('a'), adjust: false);
      await _touch(tester, _rect(tester, 'a').centerRight + const Offset(6, 0));
      expect(_taps, isEmpty);
    });
  });

  testWidgets('a control shows it is pressed while the finger is down', (
    tester,
  ) async {
    var pressed = false;
    await _pump(
      tester,
      Tappable.states(
        key: const Key('a'),
        onTap: () {},
        builder: (context, states) {
          pressed = states.contains(WidgetState.pressed);
          return const SizedBox.square(dimension: 24);
        },
      ),
    );
    final gesture = await tester.startGesture(
      _rect(tester, 'a').centerRight + const Offset(6, 0),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(pressed, isTrue);
    await gesture.up();
    await tester.pump();
    expect(pressed, isFalse);
  });

  testWidgets('a tap target of the app\'s own joins with TouchTarget', (
    tester,
  ) async {
    Widget own({required bool marked}) {
      final Widget detector = GestureDetector(
        key: const Key('own'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _taps.add('own'),
        child: const SizedBox.square(dimension: 24),
      );
      return marked ? TouchTarget(child: detector) : detector;
    }

    await _pump(tester, own(marked: false));
    await _touch(tester, _rect(tester, 'own').centerRight + const Offset(6, 0));
    expect(_taps, isEmpty);

    await _pump(tester, own(marked: true));
    await _touch(tester, _rect(tester, 'own').centerRight + const Offset(6, 0));
    expect(_taps, ['own']);
  });

  group('an AdminScope', () {
    Future<void> pumpScope(
      WidgetTester tester,
      Widget child, {
      bool adjust = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: AdminScope(
            adjustTouchTargets: adjust,
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: Padding(padding: const EdgeInsets.all(60), child: child),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('helps the controls of its page, unless told not to', (
      tester,
    ) async {
      await pumpScope(tester, _target('a'));
      await _touch(tester, _rect(tester, 'a').centerRight + const Offset(6, 0));
      expect(_taps, ['a']);

      _taps.clear();
      await pumpScope(tester, _target('a'), adjust: false);
      await _touch(tester, _rect(tester, 'a').centerRight + const Offset(6, 0));
      expect(_taps, isEmpty);
    });

    Widget popover() => Popover(
      anchor: (context, controller) =>
          TextButton(onPressed: controller.toggle, child: const Text('Open')),
      content: (context, controller) => PopoverMenuSurface(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Align(alignment: Alignment.topLeft, child: _target('p')),
        ),
      ),
    );

    testWidgets('helps the controls of a popover opened on its page', (
      tester,
    ) async {
      await pumpScope(tester, popover());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await _touch(tester, _rect(tester, 'p').centerRight + const Offset(6, 0));
      expect(_taps, ['p']);
    });

    testWidgets('told not to, leaves a popover\'s controls alone too', (
      tester,
    ) async {
      await pumpScope(tester, popover(), adjust: false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await _touch(tester, _rect(tester, 'p').centerRight + const Offset(6, 0));
      expect(_taps, isEmpty);
    });

    Widget sheetButton() => Builder(
      builder: (context) => TextButton(
        onPressed: () => showSideSheet<void>(
          context,
          builder: (context) => Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: _target('s'),
            ),
          ),
        ),
        child: const Text('Open'),
      ),
    );

    testWidgets('helps the controls of a side sheet, unless told not to', (
      tester,
    ) async {
      await pumpScope(tester, sheetButton());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await _touch(tester, _rect(tester, 's').centerRight + const Offset(6, 0));
      expect(_taps, ['s']);

      _taps.clear();
      await tester.pumpWidget(const SizedBox());
      await pumpScope(tester, sheetButton(), adjust: false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await _touch(tester, _rect(tester, 's').centerRight + const Offset(6, 0));
      expect(_taps, isEmpty);
    });

    testWidgets('helps the controls of a modal opened on it', (tester) async {
      await pumpScope(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModal<void>(
              context,
              builder: (context) => Center(
                child: Material(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: _target('m')),
                  ),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await _touch(tester, _rect(tester, 'm').centerRight + const Offset(6, 0));
      expect(_taps, ['m']);
    });
  });

  testWidgets('one adjustment inside another presses the control once', (
    tester,
  ) async {
    await _pump(tester, TouchTargetAdjustment(child: _target('a')));
    await _touch(tester, _rect(tester, 'a').centerRight + const Offset(6, 0));
    expect(_taps, ['a']);
  });
}
