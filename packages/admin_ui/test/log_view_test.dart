import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 400, height: 200, child: child),
          ),
        ),
      ),
    );

/// [count] lines of a build log, numbered from [from], each with its
/// elapsed time.
List<LogLine> _lines(int count, {int from = 0}) => [
  for (var i = from; i < from + count; i++)
    LogLine('step $i done', prefix: '${i ~/ 10}.${i % 10} s'),
];

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

/// Whether [text] is built and wholly inside the log's box.
bool _inView(WidgetTester tester, String text) {
  final found = find.text(text);
  if (found.evaluate().isEmpty) return false;
  final view = tester.getRect(find.byType(LogView));
  final line = tester.getRect(found);
  return line.top >= view.top && line.bottom <= view.bottom;
}

void _expectAtEnd(WidgetTester tester, String last) {
  final position = _position(tester);
  expect(position.maxScrollExtent, greaterThan(0));
  expect(position.pixels, position.maxScrollExtent);
  expect(_inView(tester, last), isTrue, reason: '"$last" in view');
}

/// Everything written to the clipboard while the test runs.
List<String> _clipboard(WidgetTester tester) {
  final written = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      written.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return written;
}

void main() {
  testWidgets('a long log opens on its last line', (tester) async {
    await tester.pumpWidget(_host(LogView(lines: _lines(2000))));

    _expectAtEnd(tester, 'step 1999 done');
    expect(find.text('step 0 done'), findsNothing);
    // Only the lines around the end are built.
    expect(find.byType(Text).evaluate().length, lessThan(100));
  });

  testWidgets('it follows lines that arrive while the reader is at the end, '
      'a burst of them in one frame too', (tester) async {
    final lines = _lines(100);
    await tester.pumpWidget(_host(LogView(lines: lines)));

    lines.add(const LogLine('step 100 done'));
    await tester.pumpWidget(_host(LogView(lines: lines)));
    _expectAtEnd(tester, 'step 100 done');

    // Lines that wrap are taller than the rest: the end still lands.
    const long =
        'Uploading build/web/assets/fonts/MaterialIcons-Regular.otf to the '
        'release bucket, 1.6 MB, attempt 1 of 3';
    final burst = [
      ...lines,
      for (var i = 0; i < 500; i++) LogLine(i.isEven ? long : 'chunk $i'),
      const LogLine('deployed'),
    ];
    await tester.pumpWidget(_host(LogView(lines: burst)));
    _expectAtEnd(tester, 'deployed');
  });

  testWidgets('a reader up the log stays there while lines arrive, and is '
      'followed again once back at the end', (tester) async {
    var lines = _lines(200);
    await tester.pumpWidget(_host(LogView(lines: lines)));

    await tester.drag(find.byType(LogView), const Offset(0, 300));
    await tester.pumpAndSettle();
    final reading = _position(tester).pixels;
    expect(reading, lessThan(_position(tester).maxScrollExtent));
    const anchor = 'step 185 done';
    expect(_inView(tester, anchor), isTrue);
    final top = tester.getRect(find.text(anchor)).top;

    lines = [...lines, ..._lines(50, from: 200)];
    await tester.pumpWidget(_host(LogView(lines: lines)));
    expect(_position(tester).pixels, reading);
    expect(tester.getRect(find.text(anchor)).top, top);
    expect(find.text('step 249 done'), findsNothing);

    await tester.drag(find.byType(LogView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    _expectAtEnd(tester, 'step 249 done');

    lines = [...lines, const LogLine('deployed')];
    await tester.pumpWidget(_host(LogView(lines: lines)));
    _expectAtEnd(tester, 'deployed');
  });

  testWidgets('it stays on the end through a new theme and a new width', (
    tester,
  ) async {
    // A new theme replaces the list's scroll position, and new type metrics
    // and a narrower box move every line below.
    final lines = [
      for (var i = 0; i < 300; i++)
        LogLine(
          i.isEven ? 'step $i done' : 'step $i wrote ${'x' * (i % 60)} bytes',
          prefix: '$i s',
        ),
    ];
    await tester.pumpWidget(_host(LogView(lines: lines)));
    final before = _position(tester);
    _expectAtEnd(tester, 'step 299 wrote ${'x' * 59} bytes');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(carbonTheme.tokens),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 200,
              child: LogView(lines: lines),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_position(tester), isNot(same(before)));
    _expectAtEnd(tester, 'step 299 wrote ${'x' * 59} bytes');
  });

  testWidgets('without follow it opens on the first line and never moves', (
    tester,
  ) async {
    var lines = _lines(200);
    await tester.pumpWidget(_host(LogView(lines: lines, follow: false)));
    expect(_position(tester).pixels, 0);
    expect(_inView(tester, 'step 0 done'), isTrue);

    lines = [...lines, ..._lines(20, from: 200)];
    await tester.pumpWidget(_host(LogView(lines: lines, follow: false)));
    expect(_position(tester).pixels, 0);

    // Not even from the end.
    await tester.drag(find.byType(LogView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    final end = _position(tester).pixels;
    expect(end, _position(tester).maxScrollExtent);
    lines = [...lines, const LogLine('deployed')];
    await tester.pumpWidget(_host(LogView(lines: lines, follow: false)));
    expect(_position(tester).pixels, end);
    expect(_position(tester).maxScrollExtent, greaterThan(end));
    expect(_inView(tester, 'deployed'), isFalse);
  });

  testWidgets('a log with no lines says so', (tester) async {
    await tester.pumpWidget(_host(const LogView(lines: [])));
    expect(find.text('No output yet'), findsOneWidget);

    await tester.pumpWidget(
      _host(const LogView(lines: [], emptyText: 'Waiting for a runner')),
    );
    expect(find.text('Waiting for a runner'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('a danger line takes the danger text colour, a warning the '
      'warning one, and the rest stay plain', (tester) async {
    await tester.pumpWidget(
      _host(
        const LogView(
          lines: [
            LogLine('Resolving dependencies', prefix: '0.4 s'),
            LogLine('Cache miss', severity: Severity.info),
            LogLine('3 packages are deprecated', severity: Severity.warning),
            LogLine('Build failed', severity: Severity.danger),
          ],
        ),
      ),
    );
    final palette = defaultTokens.palette;
    Color? colorOf(String text) {
      final found = find.text(text);
      final style = tester.widget<Text>(found).style;
      return DefaultTextStyle.of(tester.element(found)).style
          .merge(style)
          .color;
    }

    expect(colorOf('Build failed'), palette.dangerText);
    expect(colorOf('3 packages are deprecated'), palette.warningText);
    expect(colorOf('Cache miss'), palette.foreground);
    expect(colorOf('Resolving dependencies'), palette.foreground);
    expect(colorOf('0.4 s'), palette.foregroundMuted);
  });

  testWidgets('a copy across lines keeps one line per line', (tester) async {
    final clipboard = _clipboard(tester);
    await tester.pumpWidget(
      _host(
        const LogView(
          lines: [
            LogLine('Compiling', prefix: '0.1 s'),
            LogLine(''),
            LogLine('Done', prefix: '12.4 s'),
          ],
        ),
      ),
    );

    // The selection takes in the lines a frame after they are built.
    await tester.pump();
    final line = tester.element(find.text('Compiling'));
    Actions.invoke(
      line,
      const SelectAllTextIntent(SelectionChangedCause.keyboard),
    );
    Actions.invoke(line, CopySelectionTextIntent.copy);
    await tester.pump();

    expect(clipboard, ['0.1 s\tCompiling\n\n12.4 s\tDone']);
  });

  testWidgets('right to left the prefix column leads on the right, and a '
      'line keeps the direction it was written in', (tester) async {
    await tester.pumpWidget(
      _host(
        const LogView(
          lines: [
            LogLine('npm ci --omit=dev', prefix: '1.2 s'),
            LogLine('تم النشر', prefix: '9.8 s'),
          ],
        ),
        direction: TextDirection.rtl,
      ),
    );

    final prefix = tester.getRect(find.text('1.2 s'));
    final command = tester.getRect(find.text('npm ci --omit=dev'));
    expect(prefix.left, greaterThan(command.right));
    expect(
      tester.widget<Text>(find.text('npm ci --omit=dev')).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester.widget<Text>(find.text('تم النشر')).textDirection,
      TextDirection.rtl,
    );
  });
}
