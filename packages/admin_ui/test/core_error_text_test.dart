import 'dart:async';
import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Stands in for `package:http`'s ClientException, which reads the same.
class ClientException implements Exception {
  final String message;
  final Uri? uri;
  ClientException(this.message, [this.uri]);
  @override
  String toString() => 'ClientException: $message, uri=$uri';
}

/// An app's own API error that names its status in its text.
class _ApiError implements Exception {
  final int status;
  _ApiError(this.status);
  @override
  String toString() => 'ApiError(statusCode: $status, body: {"detail": "x"})';
}

const _unreachable =
    'Can’t reach the server. Check your connection and try again.';
const _slow = 'The server took too long to respond. Try again.';

void main() {
  group('describeError', () {
    final cases = <String, (Object, String)>{
      'SocketException': (
        const SocketException('Failed host lookup: api.example.test'),
        _unreachable,
      ),
      'HttpException': (
        const HttpException('Connection closed while receiving data'),
        _unreachable,
      ),
      'ClientException (web XHR)': (
        ClientException('XMLHttpRequest error.', Uri.parse('https://x.test')),
        _unreachable,
      ),
      'wrapped in Exception()': (
        Exception('SocketException: Connection refused (OS Error: 61)'),
        _unreachable,
      ),
      'TimeoutException': (
        TimeoutException('after 30s', const Duration(seconds: 30)),
        _slow,
      ),
      'FormatException': (
        const FormatException('Unexpected character', '<html>', 0),
        'The server’s response couldn’t be read. Try again.',
      ),
      '401': (
        _ApiError(401),
        'Your session has expired. Sign in and try again.',
      ),
      '403': (_ApiError(403), 'You don’t have permission to do that.'),
      '404': (
        _ApiError(404),
        'It couldn’t be found. It may have been moved or deleted.',
      ),
      '409': (
        _ApiError(409),
        'It was changed somewhere else. Reload and try again.',
      ),
      '413': (
        Exception('Upload failed with status 413'),
        'That’s too large for the server to accept.',
      ),
      '429': (
        Exception('HTTP 429 Too Many Requests'),
        'Too many requests. Wait a moment and try again.',
      ),
      '504': (_ApiError(504), _slow),
      '500': (
        const HttpException('Invalid response, status code: 500'),
        'The server ran into a problem. Try again in a moment.',
      ),
      '402': (
        Exception('HTTP 402 Payment Required'),
        'That needs a paid plan or more credit.',
      ),
      'another 4xx': (
        _ApiError(422),
        'The server couldn’t complete the request.',
      ),
      'a thrown message': ('Upload failed', 'Upload failed'),
      'StateError': (StateError('Bad state: No element'), _fallbackText),
      'ArgumentError': (ArgumentError.value(3, 'id'), _fallbackText),
      'an empty string': ('  ', _fallbackText),
    };
    cases.forEach((name, value) {
      final (error, expected) = value;
      test(name, () => expect(describeError(error), expected));
    });

    test('never shows a class name or the raw text', () {
      for (final (error, _) in cases.values) {
        if (error is String) continue;
        final text = describeError(error);
        expect(text, isNot(contains('Exception')));
        expect(text, isNot(contains('Error')));
        expect(text, isNot(contains('status')));
        expect(text, endsWith('.'));
      }
    });

    test('a success status in the text is no failure', () {
      expect(describeError(Exception('status 200 but empty')), _fallbackText);
    });
  });

  group('ErrorTextScope', () {
    Widget host(Widget child) => MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(body: child),
    );

    Widget reader(Object error) => Builder(
      builder: (context) => Text(ErrorTextScope.describe(context, error)),
    );

    testWidgets('without a scope, describeError words it', (tester) async {
      await tester.pumpWidget(
        host(reader(const SocketException('Connection refused'))),
      );
      expect(find.text(_unreachable), findsOneWidget);
    });

    testWidgets('a scope words it, and can defer to describeError', (
      tester,
    ) async {
      String describe(Object error) => error is _ApiError && error.status == 404
          ? 'That page is gone.'
          : describeError(error);
      await tester.pumpWidget(
        host(
          ErrorTextScope(
            describe: describe,
            child: Column(
              children: [
                reader(_ApiError(404)),
                reader(TimeoutException('slow')),
              ],
            ),
          ),
        ),
      );
      expect(find.text('That page is gone.'), findsOneWidget);
      expect(find.text(_slow), findsOneWidget);
    });

    testWidgets('a new scope rewords what is shown', (tester) async {
      final error = StateError('boom');
      Widget scoped(String text) =>
          host(ErrorTextScope(describe: (_) => text, child: reader(error)));
      await tester.pumpWidget(scoped('First.'));
      expect(find.text('First.'), findsOneWidget);
      await tester.pumpWidget(scoped('Second.'));
      expect(find.text('Second.'), findsOneWidget);
    });

    testWidgets('logs the raw error once, and never shows it', (tester) async {
      final logged = <String>[];
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
      final error = StateError('db connection pool exhausted');
      try {
        await tester.pumpWidget(host(reader(error)));
        await tester.pumpWidget(host(Center(child: reader(error))));
      } finally {
        debugPrint = previous;
      }
      expect(find.text(_fallbackText), findsOneWidget);
      expect(find.textContaining('pool exhausted'), findsNothing);
      expect(logged.where((m) => m.contains('pool exhausted')), hasLength(1));
    });
  });
}

const _fallbackText = 'Something went wrong. Try again.';
