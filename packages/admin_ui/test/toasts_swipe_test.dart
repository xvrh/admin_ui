import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A 1280×800 app whose scope stacks at [position] in [direction], with
/// animations disabled when [reduced], and the scope's state.
Future<ToastScopeState> _pumpScope(
  WidgetTester tester, {
  ToastPosition position = ToastPosition.topEnd,
  TextDirection direction = TextDirection.ltr,
  bool reduced = false,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Directionality(
          textDirection: direction,
          child: ToastScope(position: position, child: navigator!),
        ),
      ),
      home: const SizedBox.expand(),
    ),
  );
  return tester.state<ToastScopeState>(find.byType(ToastScope));
}

Finder _card(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Material)).first;

/// A slow drag of the card by [dx]: no fling.
Future<void> _drag(WidgetTester tester, String text, double dx) => tester
    .timedDrag(find.text(text), Offset(dx, 0), const Duration(seconds: 1));

void main() {
  const width = 356.0;

  testWidgets('a swipe past 40% of the width dismisses, as swiped', (
    tester,
  ) async {
    final toasts = await _pumpScope(tester);
    final handle = toasts.show(const Toast('Saved.', duration: null));
    await tester.pumpAndSettle();

    await _drag(tester, 'Saved.', width * 0.5);
    expect(handle.isActive, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsNothing);
    expect(await handle.dismissed, ToastDismissReason.swiped);
  });

  testWidgets('it follows the finger and fades as it goes', (tester) async {
    final toasts = await _pumpScope(tester);
    toasts.show(const Toast('Saved.', duration: null));
    await tester.pumpAndSettle();
    final rest = tester.getRect(_card('Saved.'));

    final gesture = await tester.startGesture(
      tester.getCenter(_card('Saved.')),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    final moved = tester.getRect(_card('Saved.'));
    expect(moved.left, greaterThan(rest.left + 40));
    expect(moved.top, rest.top);
    final opacity = tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text('Saved.'), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    expect(opacity, lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    toasts.dismissAll();
    await tester.pumpAndSettle();
  });

  testWidgets('a short swipe springs back', (tester) async {
    final toasts = await _pumpScope(tester);
    final handle = toasts.show(const Toast('Saved.', duration: null));
    await tester.pumpAndSettle();
    final rest = tester.getRect(_card('Saved.'));

    await _drag(tester, 'Saved.', width * 0.3);
    expect(handle.isActive, isTrue);
    await tester.pump(defaultTokens.motion.medium ~/ 2);
    expect(tester.getRect(_card('Saved.')).left, greaterThan(rest.left));
    await tester.pumpAndSettle();
    expect(tester.getRect(_card('Saved.')), rest);
    toasts.dismissAll();
    await tester.pumpAndSettle();
  });

  testWidgets('a fling toward the edge dismisses, however short', (
    tester,
  ) async {
    final toasts = await _pumpScope(tester);
    final handle = toasts.show(const Toast('Saved.', duration: null));
    await tester.pumpAndSettle();

    await tester.fling(find.text('Saved.'), const Offset(60, 0), 1500);
    await tester.pumpAndSettle();
    expect(await handle.dismissed, ToastDismissReason.swiped);
  });

  testWidgets('a swipe away from the edge does not move it', (tester) async {
    final toasts = await _pumpScope(tester);
    final handle = toasts.show(const Toast('Saved.', duration: null));
    await tester.pumpAndSettle();
    final rest = tester.getRect(_card('Saved.'));

    final gesture = await tester.startGesture(
      tester.getCenter(_card('Saved.')),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    expect(tester.getRect(_card('Saved.')), rest);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.fling(find.text('Saved.'), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
    expect(handle.isActive, isTrue);
    toasts.dismissAll();
    await tester.pumpAndSettle();
  });

  group('direction', () {
    for (final (position, direction, dx) in const [
      // The end edge is the left in right-to-left.
      (ToastPosition.topEnd, TextDirection.rtl, -1.0),
      (ToastPosition.bottomStart, TextDirection.ltr, -1.0),
      (ToastPosition.bottomStart, TextDirection.rtl, 1.0),
    ]) {
      testWidgets('$position, ${direction.name}: toward the '
          '${dx < 0 ? 'left' : 'right'}, not away', (tester) async {
        final toasts = await _pumpScope(
          tester,
          position: position,
          direction: direction,
        );
        final handle = toasts.show(const Toast('Saved.', duration: null));
        await tester.pumpAndSettle();

        await _drag(tester, 'Saved.', -dx * width * 0.6);
        await tester.pumpAndSettle();
        expect(handle.isActive, isTrue);

        await _drag(tester, 'Saved.', dx * width * 0.6);
        await tester.pumpAndSettle();
        expect(await handle.dismissed, ToastDismissReason.swiped);
      });
    }

    for (final dx in [-1.0, 1.0]) {
      testWidgets('centred: either way (${dx < 0 ? 'left' : 'right'})', (
        tester,
      ) async {
        final toasts = await _pumpScope(
          tester,
          position: ToastPosition.bottomCenter,
        );
        final handle = toasts.show(const Toast('Saved.', duration: null));
        await tester.pumpAndSettle();

        await _drag(tester, 'Saved.', dx * width * 0.6);
        await tester.pumpAndSettle();
        expect(await handle.dismissed, ToastDismissReason.swiped);
      });
    }
  });

  testWidgets('the countdown pauses while the card is held', (tester) async {
    final toasts = await _pumpScope(tester);
    toasts.show(const Toast('Saved.', duration: Duration(seconds: 3)));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(_card('Saved.')),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Saved.'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Saved.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsNothing);
  });

  group('reduced motion', () {
    testWidgets('a swipe past the threshold is gone in the next frame', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester, reduced: true);
      final handle = toasts.show(const Toast('Saved.', duration: null));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(_card('Saved.')),
      );
      await gesture.moveBy(const Offset(40, 0));
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text('Saved.'), findsNothing);
      expect(await handle.dismissed, ToastDismissReason.swiped);
    });

    testWidgets('a short swipe is back at rest in the next frame', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester, reduced: true);
      toasts.show(const Toast('Saved.', duration: null));
      await tester.pump();
      final rest = tester.getRect(_card('Saved.'));

      final gesture = await tester.startGesture(
        tester.getCenter(_card('Saved.')),
      );
      await gesture.moveBy(const Offset(40, 0));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.getRect(_card('Saved.')), rest);
      toasts.dismissAll();
      await tester.pump();
    });
  });
}
