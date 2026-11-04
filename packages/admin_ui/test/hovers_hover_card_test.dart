import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _body = 'Card body';

Widget _host({
  Widget? trigger,
  VoidCallback? onPressed,
  ValueChanged<bool>? onOpenChanged,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(800, 600),
      disableAnimations: reduceMotion,
    ),
    child: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoverCard(
              onOpenChanged: onOpenChanged,
              content: (context) => const Text(_body),
              child: KeyedSubtree(
                key: const Key('trigger'),
                child:
                    trigger ?? Button('Trigger', onPressed: onPressed ?? () {}),
              ),
            ),
            const SizedBox(height: 200),
            Button('Next', onPressed: () {}),
          ],
        ),
      ),
    ),
  ),
);

Finder get _card => find.text(_body);

Finder get _trigger => find.byKey(const Key('trigger'));

Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  return gesture;
}

/// Whether focus is on the trigger, or inside it.
bool _triggerFocused(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final trigger = tester.element(_trigger);
  var inside = identical(focused, trigger);
  focused.visitAncestorElements((element) {
    inside = inside || identical(element, trigger);
    return !inside;
  });
  return inside;
}

void main() {
  group('pointer', () {
    testWidgets('opens after openDelay, not before', (tester) async {
      await tester.pumpWidget(_host());
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_trigger));
      await tester.pump(const Duration(milliseconds: 690));
      expect(_card, findsNothing);
      await tester.pump(const Duration(milliseconds: 20));
      expect(_card, findsOneWidget);
    });

    testWidgets('leaving before openDelay cancels it', (tester) async {
      await tester.pumpWidget(_host());
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_trigger));
      await tester.pump(const Duration(milliseconds: 500));
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(seconds: 1));
      expect(_card, findsNothing);
    });

    testWidgets('stays open while the pointer crosses onto the card', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_trigger));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      final trigger = tester.getRect(_trigger);
      final card = tester.getRect(
        find.ancestor(of: _card, matching: find.byType(PopoverMenuSurface)),
      );
      expect(card.top, greaterThan(trigger.bottom), reason: 'below, a gap off');

      // Through the gap between them, then onto the card.
      await mouse.moveTo(
        Offset(trigger.center.dx, (trigger.bottom + card.top) / 2),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await mouse.moveTo(card.center);
      await tester.pump(const Duration(seconds: 1));
      expect(_card, findsOneWidget);

      // Back onto the trigger, and it is still open.
      await mouse.moveTo(trigger.center);
      await tester.pump(const Duration(seconds: 1));
      expect(_card, findsOneWidget);
    });

    testWidgets('closes closeDelay after the pointer leaves both', (
      tester,
    ) async {
      final changes = <bool>[];
      await tester.pumpWidget(_host(onOpenChanged: changes.add));
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_trigger));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 290));
      expect(_card, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 20));
      expect(_card, findsNothing);
      expect(changes, [true, false]);
    });

    testWidgets('a tap outside closes it', (tester) async {
      await tester.pumpWidget(_host());
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_trigger));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      expect(_card, findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('focus opens it at once; Escape closes it and focus stays '
        'on the trigger', (tester) async {
      await tester.pumpWidget(_host());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_triggerFocused(tester), isTrue);
      expect(_card, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
      expect(_triggerFocused(tester), isTrue);

      // Focus leaving and coming back opens it again.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_triggerFocused(tester), isFalse);
      expect(_card, findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();
      expect(_triggerFocused(tester), isTrue);
      expect(_card, findsOneWidget);
    });

    testWidgets('Escape after a pointer open moves focus to the trigger '
        'without opening it again', (tester) async {
      await tester.pumpWidget(_host());
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_trigger));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(_card, findsOneWidget);
      expect(_triggerFocused(tester), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_triggerFocused(tester), isTrue);
      expect(_card, findsNothing);
    });

    testWidgets('focus moving on closes it', (tester) async {
      await tester.pumpWidget(_host());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_card, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_card, findsNothing);
    });

    testWidgets('the card never takes focus', (tester) async {
      await tester.pumpWidget(_host());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_card, findsOneWidget);
      expect(_triggerFocused(tester), isTrue);
    });
  });

  group('touch', () {
    testWidgets('a tap never opens it, and still presses the trigger', (
      tester,
    ) async {
      var pressed = 0;
      await tester.pumpWidget(_host(onPressed: () => pressed++));
      await tester.tap(_trigger);
      await tester.pump(const Duration(seconds: 2));
      expect(_card, findsNothing);
      expect(pressed, 1);
    });

    testWidgets('a long press never opens it', (tester) async {
      await tester.pumpWidget(_host());
      await tester.longPress(_trigger);
      await tester.pump(const Duration(seconds: 2));
      expect(_card, findsNothing);
    });

    testWidgets('a click that focuses the trigger waits for openDelay', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          trigger: Focus(
            focusNode: node,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: node.requestFocus,
              child: const SizedBox(width: 80, height: 32),
            ),
          ),
        ),
      );
      await tester.tap(_trigger, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(node.hasFocus, isTrue);
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      expect(_card, findsNothing, reason: 'focus came from the click');
      await tester.pump(const Duration(milliseconds: 700));
      expect(_card, findsOneWidget, reason: 'the pointer rests on it');
    });
  });

  group('motion', () {
    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.ancestor(of: _card, matching: find.byType(Opacity)).first,
        )
        .opacity;

    testWidgets('fades in over motion.fast', (tester) async {
      await tester.pumpWidget(_host());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(opacity(tester), lessThan(1));
      await tester.pump(defaultTokens.motion.fast);
      expect(opacity(tester), 1);
    });

    testWidgets('appears at once under reduced motion', (tester) async {
      await tester.pumpWidget(_host(reduceMotion: true));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(opacity(tester), 1);
    });
  });

  testWidgets('the card is 320 wide by default, on the surface of a menu', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final card = find.ancestor(
      of: _card,
      matching: find.byType(PopoverMenuSurface),
    );
    expect(tester.getSize(card).width, 320);
    expect(
      tester.getCenter(card).dx,
      tester.getCenter(_trigger).dx,
      reason: 'centred below the trigger',
    );
  });
}
