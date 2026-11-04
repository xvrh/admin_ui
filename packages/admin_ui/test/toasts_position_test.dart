import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A [size] app whose scope stacks at [position] in [direction], and the
/// scope's state.
Future<ToastScopeState> _pumpScope(
  WidgetTester tester, {
  required Size size,
  ToastPosition position = ToastPosition.topEnd,
  TextDirection direction = TextDirection.ltr,
  int maxVisible = 3,
  EdgeInsets safeArea = EdgeInsets.zero,
  EdgeInsetsGeometry margin = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(
    left: safeArea.left,
    top: safeArea.top,
    right: safeArea.right,
    bottom: safeArea.bottom,
  );
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey((size, position, direction)),
      theme: buildAppTheme(defaultTokens),
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: ToastScope(
          position: position,
          maxVisible: maxVisible,
          margin: margin,
          child: navigator!,
        ),
      ),
      home: const SizedBox.expand(),
    ),
  );
  return tester.state<ToastScopeState>(find.byType(ToastScope));
}

Rect _card(WidgetTester tester, String text) => tester.getRect(
  find.ancestor(of: find.text(text), matching: find.byType(Material)).first,
);

void main() {
  for (final width in [320.0, 1280.0]) {
    final size = Size(width, 800);
    final toastWidth = width == 320 ? 320.0 - 2 * 16 : 356.0;
    for (final direction in TextDirection.values) {
      final rtl = direction == TextDirection.rtl;
      for (final position in ToastPosition.values) {
        testWidgets('$position, ${direction.name}, ${width.toInt()} wide', (
          tester,
        ) async {
          final toasts = await _pumpScope(
            tester,
            size: size,
            position: position,
            direction: direction,
          );
          toasts.show(const Toast('Saved.', duration: null));
          await tester.pumpAndSettle();

          final card = _card(tester, 'Saved.');
          expect(card.width, toastWidth);
          final top = position.name.startsWith('top');
          if (top) {
            expect(card.top, 16);
          } else {
            expect(card.bottom, 800 - 16);
          }
          final left = switch (position) {
            ToastPosition.topStart ||
            ToastPosition.bottomStart => rtl ? width - 16 - toastWidth : 16.0,
            ToastPosition.topEnd ||
            ToastPosition.bottomEnd => rtl ? 16.0 : width - 16 - toastWidth,
            ToastPosition.topCenter ||
            ToastPosition.bottomCenter => (width - toastWidth) / 2,
          };
          expect(card.left, left);
          toasts.dismissAll();
          await tester.pumpAndSettle();
        });
      }
    }
  }

  testWidgets('the stack keeps inside the safe area', (tester) async {
    for (final position in [ToastPosition.topEnd, ToastPosition.bottomStart]) {
      final toasts = await _pumpScope(
        tester,
        size: const Size(400, 800),
        position: position,
        safeArea: const EdgeInsets.fromLTRB(10, 40, 20, 30),
      );
      toasts.show(const Toast('Saved.', duration: null));
      await tester.pumpAndSettle();
      final card = _card(tester, 'Saved.');
      expect(card.width, 400 - 10 - 20 - 32);
      if (position == ToastPosition.topEnd) {
        expect(card.topRight, const Offset(400 - 20 - 16, 40 + 16));
      } else {
        expect(card.bottomLeft, const Offset(10 + 16, 800 - 30 - 16));
      }
      toasts.dismissAll();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a margin keeps the stack clear of an app bar', (tester) async {
    for (final direction in TextDirection.values) {
      final toasts = await _pumpScope(
        tester,
        size: const Size(1280, 800),
        direction: direction,
        safeArea: const EdgeInsets.only(top: 20),
        margin: const EdgeInsetsDirectional.only(top: 56, end: 8),
      );
      toasts.show(const Toast('Saved.', duration: null));
      await tester.pumpAndSettle();
      final card = _card(tester, 'Saved.');
      expect(card.top, 20 + 56 + 16);
      expect(card.width, 356);
      if (direction == TextDirection.ltr) {
        expect(card.right, 1280 - 8 - 16);
      } else {
        expect(card.left, 8 + 16);
      }
      toasts.dismissAll();
      await tester.pumpAndSettle();
    }
  });

  group('the newest sits nearest the edge', () {
    for (final position in [ToastPosition.topEnd, ToastPosition.bottomEnd]) {
      testWidgets('$position', (tester) async {
        final toasts = await _pumpScope(
          tester,
          size: const Size(1280, 800),
          position: position,
        );
        for (final text in ['First.', 'Second.', 'Third.']) {
          toasts.show(Toast(text, duration: null));
          await tester.pumpAndSettle();
        }
        final first = _card(tester, 'First.');
        final second = _card(tester, 'Second.');
        final third = _card(tester, 'Third.');
        if (position == ToastPosition.topEnd) {
          expect(third.top, 16);
          expect(second.top, third.bottom + AdminSpacing.md);
          expect(first.top, second.bottom + AdminSpacing.md);
        } else {
          expect(third.bottom, 800 - 16);
          expect(second.bottom, third.top - AdminSpacing.md);
          expect(first.bottom, second.top - AdminSpacing.md);
        }
        toasts.dismissAll();
        await tester.pumpAndSettle();
      });
    }

    testWidgets('and the others close up when one leaves', (tester) async {
      final toasts = await _pumpScope(tester, size: const Size(1280, 800));
      final handles = [
        for (final text in ['First.', 'Second.', 'Third.'])
          toasts.show(Toast(text, duration: null)),
      ];
      await tester.pumpAndSettle();
      final first = _card(tester, 'First.');

      handles[1].dismiss();
      await tester.pump();
      await tester.pump(defaultTokens.motion.slow ~/ 2);
      final moving = _card(tester, 'First.');
      expect(moving.top, lessThan(first.top));
      expect(moving.top, greaterThan(_card(tester, 'Third.').bottom));

      await tester.pumpAndSettle();
      expect(
        _card(tester, 'First.').top,
        _card(tester, 'Third.').bottom + AdminSpacing.md,
      );
      toasts.dismissAll();
      await tester.pumpAndSettle();
    });
  });

  group('maxVisible', () {
    for (final position in [ToastPosition.topStart, ToastPosition.bottomEnd]) {
      testWidgets('shows the newest; the oldest waiting comes up at the far '
          'end ($position)', (tester) async {
        final toasts = await _pumpScope(
          tester,
          size: const Size(1280, 800),
          position: position,
          maxVisible: 2,
        );
        final handles = [
          for (var i = 1; i <= 4; i++)
            toasts.show(Toast('Toast $i.', duration: null)),
        ];
        await tester.pumpAndSettle();
        expect(find.textContaining('Toast '), findsNWidgets(2));
        expect(find.text('Toast 3.'), findsOneWidget);
        expect(find.text('Toast 4.'), findsOneWidget);

        handles[3].dismiss();
        await tester.pumpAndSettle();
        expect(find.text('Toast 2.'), findsOneWidget);
        final newer = _card(tester, 'Toast 3.');
        final older = _card(tester, 'Toast 2.');
        if (position == ToastPosition.topStart) {
          expect(newer.top, 16);
          expect(older.top, greaterThan(newer.bottom));
        } else {
          expect(newer.bottom, 800 - 16);
          expect(older.bottom, lessThan(newer.top));
        }
        toasts.dismissAll();
        await tester.pumpAndSettle();
      });
    }
  });

  group('entry', () {
    for (final (position, direction, from) in const [
      (ToastPosition.topEnd, TextDirection.ltr, 'right'),
      (ToastPosition.topEnd, TextDirection.rtl, 'left'),
      (ToastPosition.bottomStart, TextDirection.ltr, 'left'),
      (ToastPosition.bottomStart, TextDirection.rtl, 'right'),
      (ToastPosition.topCenter, TextDirection.ltr, 'top'),
      (ToastPosition.bottomCenter, TextDirection.ltr, 'bottom'),
    ]) {
      testWidgets('$position, ${direction.name}: slides in from the $from', (
        tester,
      ) async {
        final toasts = await _pumpScope(
          tester,
          size: const Size(1280, 800),
          position: position,
          direction: direction,
        );
        toasts.show(const Toast('Saved.', duration: null));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final entering = _card(tester, 'Saved.');
        await tester.pumpAndSettle();
        final settled = _card(tester, 'Saved.');
        switch (from) {
          case 'right':
            expect(entering.left, greaterThan(settled.left));
            expect(entering.top, settled.top);
          case 'left':
            expect(entering.left, lessThan(settled.left));
            expect(entering.top, settled.top);
          case 'top':
            expect(entering.top, lessThan(settled.top));
            expect(entering.left, settled.left);
          case 'bottom':
            expect(entering.bottom, greaterThan(settled.bottom));
            expect(entering.left, settled.left);
        }
        toasts.dismissAll();
        await tester.pumpAndSettle();
      });
    }
  });
}
