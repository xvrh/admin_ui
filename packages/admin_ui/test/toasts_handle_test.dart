import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An app with the scope in MaterialApp.builder, and its state.
Future<ToastScopeState> _pumpScope(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      builder: (context, navigator) => ToastScope(child: navigator!),
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );
  return tester.state<ToastScopeState>(find.byType(ToastScope));
}

/// Lets a toast finish entering or leaving: a loading toast's spinner
/// never settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

/// The card showing [text].
Finder _card(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Material)).first;

/// The close button of the card showing [text].
Finder _close(String text) =>
    find.descendant(of: _card(text), matching: find.byType(IconAction));

void main() {
  group('handle', () {
    testWidgets('update swaps the content in the same card, and restarts '
        'the countdown', (tester) async {
      final toasts = await _pumpScope(tester);
      final handle = toasts.show(
        const Toast('Saving…', duration: Duration(seconds: 4)),
      );
      await tester.pumpAndSettle();
      final card = tester.renderObject(_card('Saving…'));
      await tester.pump(const Duration(seconds: 3));

      handle.update(
        const Toast(
          'Saved.',
          severity: Severity.success,
          duration: Duration(seconds: 4),
        ),
      );
      await tester.pump();
      expect(find.text('Saving…'), findsNothing);
      expect(find.text('Saved.'), findsOneWidget);
      expect(tester.renderObject(_card('Saved.')), same(card));
      // No exit or entry: fully shown in the frame of the update.
      expect(tester.binding.transientCallbackCount, 0);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Saved.'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);

      // Four fresh seconds, not the one left before the update.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Saved.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.text('Saved.'), findsNothing);
      expect(await handle.dismissed, ToastDismissReason.timeout);
    });

    testWidgets('update of a toast waiting its turn shows once it is up', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester);
      final waiting = toasts.show(const Toast('Old.', duration: null));
      final shown = [
        for (var i = 0; i < 3; i++)
          toasts.show(Toast('Toast $i.', duration: null)),
      ];
      await tester.pumpAndSettle();
      expect(find.text('Old.'), findsNothing);

      waiting.update(const Toast('Updated.', duration: null));
      shown.last.dismiss();
      await tester.pumpAndSettle();
      expect(find.text('Updated.'), findsOneWidget);
      toasts.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('dismiss takes it down and resolves dismissed', (tester) async {
      final toasts = await _pumpScope(tester);
      final handle = toasts.show(const Toast('Saved.', duration: null));
      await tester.pumpAndSettle();
      expect(handle.isActive, isTrue);

      handle.dismiss();
      expect(handle.isActive, isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Saved.'), findsNothing);
      expect(await handle.dismissed, ToastDismissReason.dismissed);

      // Once gone, the handle does nothing.
      handle
        ..update(const Toast('Again.'))
        ..dismiss();
      await tester.pumpAndSettle();
      expect(find.text('Again.'), findsNothing);
    });

    testWidgets('a dismissed toast waiting its turn never shows', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester);
      final waiting = toasts.show(const Toast('Waiting.', duration: null));
      final shown = [
        for (var i = 0; i < 3; i++)
          toasts.show(Toast('Toast $i.', duration: null)),
      ];
      await tester.pumpAndSettle();

      waiting.dismiss();
      expect(await waiting.dismissed, ToastDismissReason.dismissed);
      shown.first.dismiss();
      await tester.pumpAndSettle();
      expect(find.text('Waiting.'), findsNothing);
      expect(find.textContaining('Toast '), findsNWidgets(2));
      toasts.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('a toast shown during an exit lets it finish, and the one '
        'closed stays gone', (tester) async {
      final toasts = await _pumpScope(tester);
      final a = toasts.show(const Toast('A.', duration: null));
      final b = toasts.show(const Toast('B.', duration: null));
      final c = toasts.show(const Toast('C.', duration: null));
      await tester.pumpAndSettle();

      a.dismiss();
      await tester.pump(const Duration(milliseconds: 50));
      final d = toasts.show(const Toast('D.', duration: null));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('A.'), findsOneWidget, reason: 'still on its way out');
      final exit = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('A.'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(exit.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(find.text('A.'), findsNothing);

      b.dismiss();
      c.dismiss();
      await tester.pumpAndSettle();
      expect(find.text('A.'), findsNothing);
      expect(find.text('D.'), findsOneWidget);
      expect(await a.dismissed, ToastDismissReason.dismissed);
      d.dismiss();
      await tester.pumpAndSettle();
      expect(find.byType(IconAction), findsNothing);
    });

    testWidgets('dismissAll takes down the shown and the waiting', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester);
      final handles = [
        for (var i = 0; i < 5; i++)
          toasts.show(Toast('Toast $i.', duration: null)),
      ];
      await tester.pumpAndSettle();

      toasts.dismissAll();
      await tester.pumpAndSettle();
      expect(find.textContaining('Toast '), findsNothing);
      for (final handle in handles) {
        expect(await handle.dismissed, ToastDismissReason.dismissed);
      }
    });

    testWidgets('the scope going away dismisses what it held', (tester) async {
      final toasts = await _pumpScope(tester);
      final reasons = <ToastDismissReason>[];
      final handle = toasts.show(
        Toast('Saved.', duration: null, onDismiss: reasons.add),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      expect(await handle.dismissed, ToastDismissReason.dismissed);
      await tester.pump();
      expect(reasons, [ToastDismissReason.dismissed]);
    });
  });

  group('onDismiss and dismissed report why it left', () {
    Future<(ToastHandle, List<ToastDismissReason>)> raise(
      WidgetTester tester, {
      Duration? duration,
    }) async {
      final toasts = await _pumpScope(tester);
      final reasons = <ToastDismissReason>[];
      final handle = toasts.show(
        Toast(
          'Deleted.',
          actionLabel: 'Undo',
          onAction: () {},
          duration: duration,
          onDismiss: reasons.add,
        ),
      );
      await tester.pumpAndSettle();
      return (handle, reasons);
    }

    testWidgets('timeout', (tester) async {
      final (handle, reasons) = await raise(
        tester,
        duration: const Duration(seconds: 2),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(reasons, [ToastDismissReason.timeout]);
      expect(await handle.dismissed, ToastDismissReason.timeout);
    });

    testWidgets('closed, by the close button', (tester) async {
      final (handle, reasons) = await raise(tester);
      await tester.tap(_close('Deleted.'));
      await tester.pumpAndSettle();
      expect(reasons, [ToastDismissReason.closed]);
      expect(await handle.dismissed, ToastDismissReason.closed);
    });

    testWidgets('closed, by Escape on the focused toast', (tester) async {
      final (handle, reasons) = await raise(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Deleted.'), findsNothing);
      expect(reasons, [ToastDismissReason.closed]);
      expect(await handle.dismissed, ToastDismissReason.closed);
    });

    testWidgets('action', (tester) async {
      final (handle, reasons) = await raise(tester);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(reasons, [ToastDismissReason.action]);
      expect(await handle.dismissed, ToastDismissReason.action);
    });

    testWidgets('dismissed, once only', (tester) async {
      final (handle, reasons) = await raise(tester);
      handle.dismiss();
      handle.dismiss();
      await tester.pumpAndSettle();
      expect(reasons, [ToastDismissReason.dismissed]);
    });
  });

  group('promise', () {
    testWidgets('shows loading, then updates to success with the value', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester);
      final work = Completer<int>();
      final result = toasts.promise(
        work.future,
        loading: const Toast.loading('Publishing…'),
        success: (count) =>
            Toast('Published $count pages.', severity: Severity.success),
        error: (error) => Toast('$error', severity: Severity.danger),
      );
      await _settle(tester);
      final card = tester.renderObject(_card('Publishing…'));
      expect(
        find.descendant(
          of: _card('Publishing…'),
          matching: find.byType(Spinner),
        ),
        findsOneWidget,
      );

      work.complete(3);
      expect(await result, 3);
      await tester.pump();
      expect(find.text('Publishing…'), findsNothing);
      expect(tester.renderObject(_card('Published 3 pages.')), same(card));
      expect(find.byType(Spinner), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Published 3 pages.'), findsNothing);
    });

    testWidgets('updates to error and fails with the error', (tester) async {
      final toasts = await _pumpScope(tester);
      final work = Completer<int>();
      final result = toasts.promise(
        work.future,
        loading: const Toast.loading('Publishing…'),
        success: (count) => Toast('Published $count pages.'),
        error: (error) =>
            Toast('Could not publish: $error', severity: Severity.danger),
      );
      await _settle(tester);

      work.completeError(StateError('offline'));
      await expectLater(result, throwsA(isA<StateError>()));
      await tester.pump();
      expect(find.text('Publishing…'), findsNothing);
      expect(
        find.text('Could not publish: Bad state: offline'),
        findsOneWidget,
      );
      toasts.dismissAll();
      await _settle(tester);
    });

    testWidgets('raises the outcome anew when loading was closed', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester);
      final work = Completer<void>();
      final result = toasts.promise(
        work.future,
        loading: const Toast.loading('Uploading…'),
        success: (_) => const Toast('Uploaded.', duration: null),
        error: (error) => Toast('$error'),
      );
      await _settle(tester);
      await tester.tap(_close('Uploading…'));
      await _settle(tester);
      expect(find.text('Uploading…'), findsNothing);

      work.complete();
      await result;
      await tester.pumpAndSettle();
      expect(find.text('Uploaded.'), findsOneWidget);
      toasts.dismissAll();
      await tester.pumpAndSettle();
    });
  });

  group('undoable', () {
    Future<(Future<bool>, List<String>)> raise(
      WidgetTester tester, {
      Toast toast = const Toast('Page deleted.'),
    }) async {
      final toasts = await _pumpScope(tester);
      final log = <String>[];
      final result = toasts.undoable(
        toast,
        commit: () async => log.add('commit'),
        onUndo: () => log.add('undo'),
      );
      await tester.pumpAndSettle();
      return (result, log);
    }

    testWidgets('gets a localized Undo action when it has none', (
      tester,
    ) async {
      await raise(tester);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('keeps an action label it was given', (tester) async {
      await raise(
        tester,
        toast: const Toast('Page moved.', actionLabel: 'Put back'),
      );
      expect(find.text('Put back'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('commits when its time runs out', (tester) async {
      final (result, log) = await raise(tester);
      // An action toast: 10s.
      await tester.pump(const Duration(seconds: 9));
      expect(log, isEmpty);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(log, ['commit']);
    });

    testWidgets('commits when closed', (tester) async {
      final (result, log) = await raise(tester);
      await tester.tap(_close('Page deleted.'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(log, ['commit']);
    });

    testWidgets('commits when the app takes it down', (tester) async {
      final (result, log) = await raise(tester);
      tester.state<ToastScopeState>(find.byType(ToastScope)).dismissAll();
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(log, ['commit']);
    });

    testWidgets('the action undoes, and never commits', (tester) async {
      final (result, log) = await raise(tester);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
      expect(log, ['undo']);
      await tester.pump(const Duration(minutes: 1));
      expect(log, ['undo']);
    });
  });

  group('loading', () {
    testWidgets('a spinner in place of the glyph; kept, and closable', (
      tester,
    ) async {
      final toasts = await _pumpScope(tester);
      final handle = toasts.show(const Toast.loading('Uploading 3 files…'));
      await _settle(tester);
      expect(const Toast.loading('x').duration, isNull);

      final spinner = find.byType(Spinner);
      expect(spinner, findsOneWidget);
      final context = tester.element(spinner);
      final glyph = context.iconSizes.lg;
      // The glyph's drawn circle, centred in the glyph's box.
      expect(tester.getSize(spinner), Size.square(glyph * 20 / 24));
      final box = tester.getRect(
        find.ancestor(of: spinner, matching: find.byType(SizedBox)).first,
      );
      expect(box.size, Size.square(glyph));
      expect(tester.getCenter(spinner), box.center);
      expect(
        tester.widget<Spinner>(spinner).color,
        severityStyleOf(context, Severity.info).foreground,
      );
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);

      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Uploading 3 files…'), findsOneWidget);
      expect(_close('Uploading 3 files…'), findsOneWidget);

      await tester.tap(_close('Uploading 3 files…'));
      await _settle(tester);
      expect(find.text('Uploading 3 files…'), findsNothing);
      expect(await handle.dismissed, ToastDismissReason.closed);
    });
  });

  group('title', () {
    testWidgets('a bold line above the message, which reads as its '
        'description', (tester) async {
      final toasts = await _pumpScope(tester);
      toasts.show(
        const Toast(
          'Your changes are live.',
          title: 'Page published',
          severity: Severity.success,
          duration: null,
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Page published'));
      final title = tester.widget<Text>(find.text('Page published'));
      final message = tester.widget<Text>(find.text('Your changes are live.'));
      expect(title.style, context.type.bodyStrong);
      expect(message.style!.color, context.colors.foregroundSecondary);
      final titleRect = tester.getRect(find.text('Page published'));
      final messageRect = tester.getRect(find.text('Your changes are live.'));
      expect(messageRect.top, titleRect.bottom + AdminSpacing.xxs);
      expect(messageRect.left, titleRect.left);

      // The glyph and the close centre on the title's line.
      final glyph = tester.getCenter(
        find.byIcon(Icons.check_circle_outline_rounded),
      );
      final close = tester.getCenter(_close('Your changes are live.'));
      expect(glyph.dy, closeTo(titleRect.center.dy, 0.5));
      expect(close.dy, closeTo(titleRect.center.dy, 0.5));
    });

    testWidgets('without one the message keeps the body style', (tester) async {
      final toasts = await _pumpScope(tester);
      toasts.show(const Toast('Saved.', duration: null));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Saved.'));
      expect(tester.widget<Text>(find.text('Saved.')).style, context.type.body);
    });
  });

  group('announcements', () {
    testWidgets('new words change the live region; the same words in a new '
        'severity are said again', (tester) async {
      final handle = tester.ensureSemantics();
      final said = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final data = (message! as Map)['data'] as Map;
            if (data['message'] case final String text) said.add(text);
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler(SystemChannels.accessibility, null),
      );

      final toasts = await _pumpScope(tester);
      final toast = toasts.show(const Toast.loading('Publishing…'));
      await _settle(tester);
      expect(
        tester.getSemantics(find.text('Publishing…')),
        isSemantics(isLiveRegion: true, label: 'Publishing…'),
      );

      toast.update(const Toast('Published.', duration: null));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Published.')),
        isSemantics(isLiveRegion: true, label: 'Published.'),
      );
      expect(said, isEmpty, reason: 'the live region reads new words');

      toast.update(
        const Toast('Published.', severity: Severity.success, duration: null),
      );
      await tester.pump();
      expect(said, ['Published.']);

      toasts.dismissAll();
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });
}
