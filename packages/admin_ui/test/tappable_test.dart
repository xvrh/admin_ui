import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {Map<ShortcutActivator, Intent>? shortcuts}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      shortcuts: shortcuts,
      home: Scaffold(body: Center(child: child)),
    );

const _box = SizedBox(width: 50, height: 50);

/// The focus ring's outline: a uniform border in the palette's ring colour.
Finder _ring() => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  return d is BoxDecoration &&
      d.border is Border &&
      (d.border! as Border).top.color == defaultTokens.palette.focusRing;
});

MouseCursor _cursorAt(WidgetTester tester, Offset point) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(
    result,
    point,
    View.of(tester.element(find.byType(Tappable))).viewId,
  );
  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderMouseRegion) return target.cursor;
  }
  return MouseCursor.defer;
}

void main() {
  testWidgets('fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(Tappable(onTap: () => taps++, child: const Text('hit'))),
    );
    await tester.tap(find.text('hit'));
    expect(taps, 1);
  });

  testWidgets('click cursor when enabled, basic when disabled', (tester) async {
    await tester.pumpWidget(
      _host(
        Tappable(onTap: () {}, child: const SizedBox(width: 50, height: 50)),
      ),
    );
    final center = tester.getCenter(find.byType(Tappable));
    expect(_cursorAt(tester, center), SystemMouseCursors.click);

    await tester.pumpWidget(
      _host(
        const Tappable(onTap: null, child: SizedBox(width: 50, height: 50)),
      ),
    );
    expect(_cursorAt(tester, center), SystemMouseCursors.basic);
  });

  testWidgets('disabledCursor override', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tappable(
          onTap: null,
          disabledCursor: SystemMouseCursors.forbidden,
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );
    expect(
      _cursorAt(tester, tester.getCenter(find.byType(Tappable))),
      SystemMouseCursors.forbidden,
    );
  });

  testWidgets('builder receives hover; onHover bubbles', (tester) async {
    final hovers = <bool>[];
    await tester.pumpWidget(
      _host(
        Tappable.builder(
          onTap: () {},
          onHover: hovers.add,
          builder: (context, hovered) => SizedBox(
            width: 50,
            height: 50,
            child: Text(hovered ? 'on' : 'off'),
          ),
        ),
      ),
    );
    expect(find.text('off'), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(Tappable)));
    await tester.pump();

    expect(find.text('on'), findsOneWidget);
    expect(hovers.last, isTrue);
  });

  group('keyboard', () {
    testWidgets('Tab reaches it; Enter and Space activate it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(Tappable(onTap: () => taps++, child: _box)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<Tappable>(),
        isNotNull,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 2);
    });

    testWidgets('Space bound to ActivateIntent alone and Enter to '
        'ButtonActivateIntent both activate it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Tappable(onTap: () => taps++, child: _box),
          shortcuts: {
            ...WidgetsApp.defaultShortcuts,
            const SingleActivator(LogicalKeyboardKey.space):
                const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.enter):
                const ButtonActivateIntent(),
          },
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 2);
    });

    testWidgets('draws the focus ring on keyboard focus only', (tester) async {
      await tester.pumpWidget(
        _host(Tappable(onTap: () {}, focusRadius: 6, child: _box)),
      );
      expect(_ring(), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(), findsOneWidget);
      final spec = defaultTokens.focus;
      expect(
        tester.getRect(_ring()),
        tester.getRect(find.byWidget(_box)).inflate(spec.offset + spec.width),
      );

      // A pointer press switches to touch highlighting: the ring goes.
      await tester.tap(find.byType(Tappable));
      await tester.pump();
      expect(_ring(), findsNothing);
    });

    testWidgets('showFocusRing: false draws none', (tester) async {
      await tester.pumpWidget(
        _host(Tappable(onTap: () {}, showFocusRing: false, child: _box)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(), findsNothing);
    });

    testWidgets('focusable: false and a null onTap both skip traversal', (
      tester,
    ) async {
      final after = FocusNode(debugLabel: 'after');
      addTearDown(after.dispose);
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tappable(onTap: () {}, focusable: false, child: _box),
              const Tappable(onTap: null, child: _box),
              Focus(focusNode: after, child: _box),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);
    });

    testWidgets(
      'a focusable child of a focusable: false target keeps its stop',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _host(
            Tappable(
              onTap: () {},
              focusable: false,
              child: Button('Inner', onPressed: () => taps++),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(taps, 1);
      },
    );

    testWidgets('a skipTraversal focusNode leaves Tab but takes focus and '
        'keys, for roving focus', (tester) async {
      final roving = FocusNode(skipTraversal: true);
      final after = FocusNode();
      addTearDown(roving.dispose);
      addTearDown(after.dispose);
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tappable(onTap: () => taps++, focusNode: roving, child: _box),
              Focus(focusNode: after, child: _box),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);

      roving.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 1);
    });

    testWidgets('autofocus, a given focusNode and onFocusChange', (
      tester,
    ) async {
      final node = FocusNode(debugLabel: 'given');
      addTearDown(node.dispose);
      final changes = <bool>[];
      await tester.pumpWidget(
        _host(
          Tappable(
            onTap: () {},
            focusNode: node,
            autofocus: true,
            onFocusChange: changes.add,
            child: _box,
          ),
        ),
      );
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      node.unfocus();
      await tester.pump();
      expect(changes, [true, false]);
    });

    testWidgets('a given focusNode releases the one it made', (tester) async {
      await tester.pumpWidget(_host(Tappable(onTap: () {}, child: _box)));
      final own = Focus.of(tester.element(find.byWidget(_box)));
      expect(own.debugLabel, 'Tappable');

      final given = FocusNode(debugLabel: 'given');
      addTearDown(given.dispose);
      await tester.pumpWidget(
        _host(Tappable(onTap: () {}, focusNode: given, child: _box)),
      );
      expect(Focus.of(tester.element(find.byWidget(_box))), given);
      expect(
        () => ChangeNotifier.debugAssertNotDisposed(own),
        throwsFlutterError,
      );
    });
  });

  group('states', () {
    testWidgets('reports hovered, pressed and keyboard focus', (tester) async {
      late Set<WidgetState> states;
      await tester.pumpWidget(
        _host(
          Tappable.states(
            onTap: () {},
            builder: (context, s) {
              states = {...s};
              return _box;
            },
          ),
        ),
      );
      expect(states, isEmpty);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(Tappable)));
      await tester.pump();
      expect(states, {WidgetState.hovered});

      await mouse.down(tester.getCenter(find.byType(Tappable)));
      await tester.pump(kPressTimeout);
      expect(states, {WidgetState.hovered, WidgetState.pressed});
      await mouse.up();
      await tester.pump();
      expect(states, {WidgetState.hovered});

      await mouse.moveTo(Offset.zero);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(states, {WidgetState.focused});
    });

    testWidgets('focused only while the keyboard highlight shows', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      late Set<WidgetState> states;
      await tester.pumpWidget(
        _host(
          Tappable.states(
            onTap: () {},
            focusNode: node,
            builder: (context, s) {
              states = {...s};
              return _box;
            },
          ),
        ),
      );
      // Touch highlighting: focus without a ring.
      await tester.tap(find.byType(Tappable));
      node.requestFocus();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      expect(states, isNot(contains(WidgetState.focused)));
    });

    testWidgets('focused only while the target itself holds focus', (
      tester,
    ) async {
      late Set<WidgetState> states;
      await tester.pumpWidget(
        _host(
          Tappable.states(
            onTap: () {},
            builder: (context, s) {
              states = {...s};
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _box,
                  IconAction(Icons.close, label: 'Remove', onPressed: () {}),
                ],
              );
            },
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(states, {WidgetState.focused});
      expect(_ring(), findsOneWidget);

      // Focus moves on to the action inside: its ring, not the target's.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(states, isNot(contains(WidgetState.focused)));
      expect(_ring(), findsOneWidget);
      expect(
        find.descendant(of: find.byType(IconAction), matching: _ring()),
        findsOneWidget,
      );
    });

    testWidgets('reports disabled and selected', (tester) async {
      late Set<WidgetState> states;
      Widget build({VoidCallback? onTap, bool? selected}) => _host(
        Tappable.states(
          onTap: onTap,
          selected: selected,
          builder: (context, s) {
            states = {...s};
            return _box;
          },
        ),
      );
      await tester.pumpWidget(build());
      expect(states, {WidgetState.disabled});
      await tester.pumpWidget(build(onTap: () {}, selected: true));
      expect(states, {WidgetState.selected});
      await tester.pumpWidget(build(onTap: () {}, selected: false));
      expect(states, isEmpty);
    });

    testWidgets(
      'a statesController seeds a pinned state and reports live ones',
      (tester) async {
        final pinned = WidgetStatesController({WidgetState.pressed});
        addTearDown(pinned.dispose);
        late Set<WidgetState> states;
        await tester.pumpWidget(
          _host(
            Tappable.states(
              onTap: () {},
              statesController: pinned,
              builder: (context, s) {
                states = {...s};
                return _box;
              },
            ),
          ),
        );
        expect(states, {WidgetState.pressed});

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(pinned.value, {WidgetState.pressed, WidgetState.focused});
        expect(states, pinned.value);
      },
    );

    testWidgets('a pinned focused state draws the ring under the keyboard '
        'highlight', (tester) async {
      final pinned = WidgetStatesController({WidgetState.focused});
      addTearDown(pinned.dispose);
      final previous = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      await tester.pumpWidget(
        _host(Tappable(onTap: () {}, statesController: pinned, child: _box)),
      );
      expect(_ring(), findsOneWidget);
    });
  });

  group('readOnly', () {
    testWidgets('a Tab stop announced read-only, never disabled or hovered', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final states = WidgetStatesController();
      addTearDown(states.dispose);
      await tester.pumpWidget(
        _host(
          Tappable(
            onTap: null,
            readOnly: true,
            toggled: true,
            semanticLabel: 'Notify',
            statesController: states,
            child: _box,
          ),
        ),
      );
      expect(states.value, isNot(contains(WidgetState.disabled)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(), findsOneWidget);
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.byType(Tappable),
            matching: find.byType(GestureDetector),
          ),
        ),
        isSemantics(
          label: 'Notify',
          isReadOnly: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          isFocused: true,
          hasToggledState: true,
          isToggled: true,
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.byType(Tappable)));
      await tester.pump();
      expect(states.value, isNot(contains(WidgetState.hovered)));
      expect(
        _cursorAt(tester, tester.getCenter(find.byType(Tappable))),
        SystemMouseCursors.basic,
      );
      handle.dispose();
    });
  });
}
