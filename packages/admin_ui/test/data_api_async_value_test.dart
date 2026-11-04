import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 400, height: 300, child: child),
    ),
  ),
);

/// A fetcher whose answers the test hands out, one call at a time.
class _Source {
  final calls = <Completer<String?>>[];

  Future<String?> call() {
    final call = Completer<String?>();
    calls.add(call);
    return call.future;
  }
}

void main() {
  group('AsyncValueController', () {
    test('loads as it is made, and refreshes keeping the value', () async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      addTearDown(c.dispose);
      expect(c.loading, isTrue);
      expect(c.hasValue, isFalse);

      source.calls.single.complete('first');
      await pumpEventQueue();
      expect((c.loading, c.hasValue, c.value), (false, true, 'first'));

      unawaited(c.refresh());
      expect(c.loading, isTrue);
      expect(c.value, 'first', reason: 'kept until the new one lands');
      source.calls.last.complete(null);
      await pumpEventQueue();
      expect((c.loading, c.hasValue, c.value), (false, true, null));
    });

    test('the latest request wins', () async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      addTearDown(c.dispose);
      unawaited(c.refresh());
      source.calls[1].complete('new');
      await pumpEventQueue();
      source.calls[0].complete('old');
      await pumpEventQueue();
      expect(c.value, 'new');
      expect(c.loading, isFalse);
    });

    test('a failure is the error, which the next load clears', () async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      addTearDown(c.dispose);
      source.calls.single.complete('kept');
      await pumpEventQueue();

      unawaited(c.refresh());
      source.calls.last.completeError(StateError('down'));
      await pumpEventQueue();
      expect(c.error, isA<StateError>());
      expect(c.value, 'kept');

      unawaited(c.refresh());
      expect(c.error, isNull);
      source.calls.last.complete('back');
      await pumpEventQueue();
      expect((c.error, c.value), (null, 'back'));
    });

    test('an answer after dispose is dropped, and notifies no one', () async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      var notified = 0;
      c.addListener(() => notified++);
      c.dispose();
      source.calls.single.complete('late');
      await pumpEventQueue();
      expect(notified, 0);
      expect(c.hasValue, isFalse);
      await c.refresh();
      expect(source.calls, hasLength(1));
    });

    test('a fetcher that throws before returning is the error', () async {
      final c = AsyncValueController<int>(fetcher: () => throw StateError('x'));
      addTearDown(c.dispose);
      await pumpEventQueue();
      expect(c.error, isA<StateError>());
      expect(c.loading, isFalse);
    });
  });

  group('AsyncValueBuilder', () {
    testWidgets('a placeholder past 150ms, then the value', (tester) async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _host(
          AsyncValueBuilder<String?>(
            controller: c,
            builder: (context, value) => Text('value: $value'),
          ),
        ),
      );
      expect(find.byType(LoadingPanel), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(LoadingPanel), findsOneWidget);

      source.calls.single.complete(null);
      await tester.pump();
      expect(find.text('value: null'), findsOneWidget);
      expect(find.byType(LoadingPanel), findsNothing);
    });

    testWidgets('a placeholder of the app\'s own shows from the start', (
      tester,
    ) async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _host(
          AsyncValueBuilder<String?>(
            controller: c,
            placeholder: const Text('sketch'),
            builder: (context, value) => Text('value: $value'),
          ),
        ),
      );
      expect(find.text('sketch'), findsOneWidget);
      source.calls.single.complete('in');
      await tester.pump();
      expect(find.text('sketch'), findsNothing);
      expect(find.text('value: in'), findsOneWidget);
    });

    testWidgets('a refresh keeps the value, under a progress bar', (
      tester,
    ) async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      addTearDown(c.dispose);
      source.calls.single.complete('first');
      await tester.pumpWidget(
        _host(
          AsyncValueBuilder<String?>(
            controller: c,
            builder: (context, value) => _Counter(value!),
          ),
        ),
      );
      await tester.pump();
      final state = tester.state(find.byType(_Counter));

      unawaited(c.refresh());
      await tester.pump();
      expect(find.byType(TopProgressBar), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('first'), findsOneWidget);
      expect(find.byType(TopProgressBar), findsOneWidget);
      expect(tester.state(find.byType(_Counter)), same(state));

      source.calls.last.complete('second');
      await tester.pump();
      expect(find.text('second'), findsOneWidget);
      expect(find.byType(TopProgressBar), findsNothing);
      expect(tester.state(find.byType(_Counter)), same(state));
    });

    testWidgets('a failed refresh shows the error in words, with Retry', (
      tester,
    ) async {
      final source = _Source();
      final c = AsyncValueController<String?>(fetcher: source.call);
      addTearDown(c.dispose);
      source.calls.single.complete('stale');
      await tester.pumpWidget(
        _host(
          AsyncValueBuilder<String?>(
            controller: c,
            builder: (context, value) => Text('$value'),
          ),
        ),
      );
      await tester.pump();

      unawaited(c.refresh());
      source.calls.last.completeError(
        Exception('SocketException: Connection refused'),
      );
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('stale'), findsNothing);
      expect(
        find.text(
          'Can’t reach the server. Check your connection and try again.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));
      source.calls.last.complete('fresh');
      await tester.pump();
      expect(find.text('fresh'), findsOneWidget);
    });

    testWidgets('errorBuilder words a failure its own way', (tester) async {
      final c = AsyncValueController<int>(
        fetcher: () async => throw StateError('gone'),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _host(
          AsyncValueBuilder<int>(
            controller: c,
            builder: (context, value) => Text('$value'),
            errorBuilder: (error, retry) =>
                Text('Custom: ${error.runtimeType}'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Custom: StateError'), findsOneWidget);
    });

    testWidgets('a refresh made in setState that fails at once is caught', (
      tester,
    ) async {
      // The FutureBuilder trap: a future made in setState is listened to at
      // the next frame, so one that fails first is reported as uncaught.
      var fail = false;
      final c = AsyncValueController<int>(
        fetcher: () =>
            fail ? Future.error(StateError('down')) : Future.value(1),
      );
      addTearDown(c.dispose);
      late StateSetter setState;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, set) {
              setState = set;
              return AsyncValueBuilder<int>(
                controller: c,
                builder: (context, value) => Text('$value'),
              );
            },
          ),
        ),
      );
      await tester.pump();
      setState(() {
        fail = true;
        c.refresh();
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}

/// Text with state of its own, to tell a rebuild from a remount.
class _Counter extends StatefulWidget {
  final String text;
  const _Counter(this.text);

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) => Text(widget.text);
}
