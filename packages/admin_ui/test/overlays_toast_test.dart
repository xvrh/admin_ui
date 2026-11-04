import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An app with the scope mounted where the docs say: in MaterialApp.builder,
/// above the Navigator. [onTap] runs from a page button.
Widget _app(void Function(BuildContext) onTap, {int maxVisible = 3}) =>
    MaterialApp(
      builder: (context, navigator) =>
          ToastScope(maxVisible: maxVisible, child: navigator!),
      home: Scaffold(
        body: Builder(
          builder: (context) => Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () => onTap(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

void _viewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('layering', () {
    testWidgets('of() resolves from a dialog when mounted in the builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          (context) => showModal<void>(
            context,
            builder: (dialog) => Modal(
              title: 'Delete?',
              actions: [
                Button.danger(
                  'Delete',
                  onPressed: () =>
                      ToastScope.of(dialog).show(const Toast('Deleted.')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(find.text('Deleted.'), findsOneWidget);
    });

    testWidgets('a toast raised under an open dialog stays clickable', (
      tester,
    ) async {
      var undone = false;
      late BuildContext page;
      await tester.pumpWidget(
        _app((context) {
          page = context;
          showModal<void>(
            context,
            builder: (_) => const Modal(title: 'Busy', message: 'Working…'),
          );
        }),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      ToastScope.of(page).show(
        Toast('Deleted.', actionLabel: 'Undo', onAction: () => undone = true),
      );
      await tester.pumpAndSettle();

      // The hit test lands on the toast's button, not the dialog's barrier.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
      expect(find.text('Busy'), findsOneWidget);
    });

    testWidgets('taps beside the cards reach the page', (tester) async {
      _viewSize(tester, const Size(800, 600));
      var tapped = 0;
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, navigator) => ToastScope(child: navigator!),
          home: Builder(
            builder: (context) {
              page = context;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => tapped++,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      ToastScope.of(page).show(const Toast('Saved.', duration: null));
      await tester.pumpAndSettle();
      expect(find.text('Saved.'), findsOneWidget);

      // In the stack's column, below its only card.
      await tester.tapAt(const Offset(800 - 100, 400));
      expect(tapped, 1);
    });
  });

  group('keyboard', () {
    Future<FocusNode> openWithFocusedTrigger(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          (c) => ToastScope.of(c)
              .show(Toast('Deleted.', actionLabel: 'Undo', onAction: () {})),
        ),
      );
      final trigger = Focus.of(tester.element(find.text('go')));
      trigger.requestFocus();
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(trigger.hasPrimaryFocus, isTrue);
      return trigger;
    }

    testWidgets('F8 reaches the toasts; Escape closes the focused one and '
        'goes back', (tester) async {
      final trigger = await openWithFocusedTrigger(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.f8);
      await tester.pump();
      final undo = Focus.of(tester.element(find.text('Undo')));
      expect(undo.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(trigger.hasPrimaryFocus, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Deleted.'), findsNothing);
      expect(trigger.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes only the toast holding focus', (tester) async {
      late BuildContext page;
      await tester.pumpWidget(
        _app((context) {
          page = context;
          ToastScope.of(context)
            ..show(const Toast('Saved.', duration: null))
            ..show(Toast('Deleted.', actionLabel: 'Undo', onAction: () {}));
        }),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      Focus.of(tester.element(find.text('Undo'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Deleted.'), findsNothing);
      expect(find.text('Saved.'), findsOneWidget);
      ToastScope.of(page).dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('closing the focused toast hands focus back', (tester) async {
      final trigger = await openWithFocusedTrigger(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.f8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Deleted.'), findsNothing);
      expect(trigger.hasPrimaryFocus, isTrue);
    });
  });

  group('semantics', () {
    testWidgets('each toast is a live region; close reads "Dismiss"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app((c) => ToastScope.of(c).show(const Toast('Draft saved.'))),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Draft saved.')),
        isSemantics(isLiveRegion: true),
      );
      expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
      final close = tester.getRect(find.byType(IconAction));
      expect(close.width, greaterThanOrEqualTo(24));
      expect(close.height, greaterThanOrEqualTo(24));
      handle.dispose();
    });
  });

  group('timing', () {
    testWidgets('an info toast leaves after 4s', (tester) async {
      await tester.pumpWidget(
        _app((c) => ToastScope.of(c).show(const Toast('Saved.'))),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3800));
      expect(find.text('Saved.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Saved.'), findsNothing);
    });

    testWidgets('action and danger toasts default to 10s', (tester) async {
      expect(const Toast('x').duration, const Duration(seconds: 4));
      expect(
        Toast('x', actionLabel: 'Undo', onAction: () {}).duration,
        const Duration(seconds: 10),
      );
      expect(
        const Toast('x', severity: Severity.danger).duration,
        const Duration(seconds: 10),
      );
      expect(
        const Toast('x', duration: Duration(seconds: 2)).duration,
        const Duration(seconds: 2),
      );
      expect(const Toast('x', duration: null).duration, isNull);
    });

    testWidgets('a null duration is sticky', (tester) async {
      await tester.pumpWidget(
        _app(
          (c) => ToastScope.of(c).show(const Toast('Stays.', duration: null)),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Stays.'), findsOneWidget);
    });

    testWidgets('focus pauses the timer; blur resumes with what was left', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          (c) => ToastScope.of(c).show(
            Toast(
              'Deleted.',
              actionLabel: 'Undo',
              onAction: () {},
              duration: const Duration(seconds: 4),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      final undo = Focus.of(tester.element(find.text('Undo')));
      undo.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Deleted.'), findsOneWidget);

      undo.unfocus();
      await tester.pump();
      // About a second was left: still there at 0.8s, gone after 1.2s.
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Deleted.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Deleted.'), findsNothing);
    });

    testWidgets('hover pauses the timer too', (tester) async {
      await tester.pumpWidget(
        _app((c) => ToastScope.of(c).show(const Toast('Saved.'))),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.text('Saved.')));
      addTearDown(mouse.removePointer);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Saved.'), findsOneWidget);

      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Saved.'), findsNothing);
    });

    testWidgets('actions and dangers stay while assistive tech drives', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        _app((c) {
          ToastScope.of(c)
            ..show(const Toast('Failed.', severity: Severity.danger))
            ..show(Toast('Deleted.', actionLabel: 'Undo', onAction: () {}))
            ..show(const Toast('Saved.'));
        }),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Failed.'), findsOneWidget);
      expect(find.text('Deleted.'), findsOneWidget);
      expect(find.text('Saved.'), findsNothing);
    });
  });

  group('stack', () {
    testWidgets('fits a 320px screen', (tester) async {
      _viewSize(tester, const Size(320, 640));
      await tester.pumpWidget(
        _app(
          (c) => ToastScope.of(c).show(
            Toast(
              'Item deleted from the collection.',
              actionLabel: 'Undo',
              onAction: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final card = tester.getRect(
        find
            .ancestor(
              of: find.text('Item deleted from the collection.'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(card.left, 16);
      expect(card.right, 320 - 16);
    });

    testWidgets('is 356 wide on a wide screen, docked to the end', (
      tester,
    ) async {
      _viewSize(tester, const Size(1200, 800));
      for (final direction in TextDirection.values) {
        late BuildContext page;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(direction),
            builder: (context, navigator) => Directionality(
              textDirection: direction,
              child: ToastScope(child: navigator!),
            ),
            home: Builder(
              builder: (context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        );
        ToastScope.of(page).show(const Toast('Saved.'));
        await tester.pumpAndSettle();
        final card = tester.getRect(
          find
              .ancestor(
                of: find.text('Saved.'),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(card.width, 356, reason: '$direction');
        expect(card.top, 16, reason: '$direction');
        if (direction == TextDirection.ltr) {
          expect(card.right, 1200 - 16);
        } else {
          expect(card.left, 16);
        }
      }
    });

    testWidgets('shows the newest maxVisible; older ones wait', (tester) async {
      await tester.pumpWidget(
        _app((c) {
          for (var i = 1; i <= 5; i++) {
            ToastScope.of(c).show(Toast('Toast $i.', duration: null));
          }
        }),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Toast '), findsNWidgets(3));
      for (final i in [3, 4, 5]) {
        expect(find.text('Toast $i.'), findsOneWidget);
      }

      await tester.tap(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Toast 5.'),
                matching: find.byType(Material),
              )
              .first,
          matching: find.byType(IconAction),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Toast '), findsNWidgets(3));
      expect(find.text('Toast 2.'), findsOneWidget);
      expect(find.text('Toast 5.'), findsNothing);
    });
  });

  testWidgets('a scope mounted inside a page still works', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ToastScope(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    ToastScope.of(context).show(const Toast('Saved.')),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsOneWidget);
  });
}
