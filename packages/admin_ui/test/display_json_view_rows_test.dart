import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {double width = 600}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

const _long =
    'https://cdn.example.com/assets/2026/06/a-very-long-file-name-that-runs-'
    'well-past-the-edge-of-a-narrow-viewer.png?width=1200&format=webp';

const _data = {
  'id': 'ord_1',
  'customer': {'email': 'ada@example.com'},
  'image': _long,
};

/// Everything written to the clipboard while the test runs.
List<String> _clipboard(WidgetTester tester) {
  final written = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        written.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return written;
}

Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump();
  return mouse;
}

Finder _pathAction(String path) => find.byWidgetPredicate(
  (w) => w is IconAction && (w.label?.endsWith(path) ?? false),
);

Finder _copyValue() => find.byType(CopyButton);

void main() {
  testWidgets('a row shows its copy actions only under the pointer', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const JsonView(data: _data)));
    // The toolbar's copy-all is the only one at rest.
    expect(_copyValue(), findsOneWidget);
    expect(_pathAction(r'$.id'), findsNothing);

    final mouse = await _hover(tester, find.textContaining('"id"'));
    expect(_copyValue(), findsNWidgets(2));
    expect(_pathAction(r'$.id'), findsOneWidget);

    await mouse.moveTo(tester.getCenter(find.textContaining('"email"')));
    await tester.pump();
    expect(_pathAction(r'$.id'), findsNothing);
    expect(_pathAction(r'$.customer.email'), findsOneWidget);
  });

  testWidgets('row copy puts the value, then the path, on the clipboard', (
    tester,
  ) async {
    final written = _clipboard(tester);
    await tester.pumpWidget(_host(const JsonView(data: _data)));
    await _hover(tester, find.textContaining('"email"'));

    await tester.tap(_copyValue().last);
    await tester.pump();
    // A string's text, without its quotes.
    expect(written.last, 'ada@example.com');

    await tester.tap(_pathAction(r'$.customer.email'));
    await tester.pump();
    expect(written.last, r'$.customer.email');
    // The path action confirms, then reverts.
    IconData glyph() =>
        tester.widget<IconAction>(_pathAction(r'$.customer.email')).icon;
    expect(glyph(), Icons.check_rounded);
    await tester.pump(const Duration(seconds: 2));
    expect(glyph(), Icons.link_rounded);
  });

  testWidgets('a subtree copies as indented JSON', (tester) async {
    final written = _clipboard(tester);
    await tester.pumpWidget(_host(const JsonView(data: _data)));
    await _hover(tester, find.textContaining('"customer"'));
    await tester.tap(_copyValue().last);
    await tester.pump();
    expect(written.last, '{\n  "email": "ada@example.com"\n}');
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    testWidgets('a focused line copies with the copy shortcut '
        '(${platform.name})', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final written = _clipboard(tester);
      await tester.pumpWidget(
        _host(const JsonView(data: _data, showToolbar: false)),
      );
      final modifier = platform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      Future<void> copyBoth() async {
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(modifier);
        await tester.pump();
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // the root line
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // "id", a short leaf
      await tester.pump();
      // Focus shows the actions too.
      expect(_pathAction(r'$.id'), findsOneWidget);
      await copyBoth();
      expect(written, ['ord_1', r'$.id']);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // "customer"
      await tester.pump();
      expect(_pathAction(r'$.customer'), findsOneWidget);
      await copyBoth();
      expect(written.skip(2), [
        '{\n  "email": "ada@example.com"\n}',
        r'$.customer',
      ]);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('a refused copy shows on the path action and is announced', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.setData'
          ? throw PlatformException(code: 'denied')
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final data = (message! as Map)['data'] as Map;
        announced.add(data['message'] as String);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    await tester.pumpWidget(
      _host(const JsonView(data: _data, showToolbar: false)),
    );
    await _hover(tester, find.textContaining('"email"'));
    await tester.tap(_pathAction(r'$.customer.email'));
    await tester.pump();
    final action = tester.widget<IconAction>(_pathAction(r'$.customer.email'));
    expect(action.icon, Icons.error_outline_rounded);
    expect(action.color, defaultTokens.palette.dangerText);
    expect(announced, ['Copy failed']);
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.widget<IconAction>(_pathAction(r'$.customer.email')).icon,
      Icons.link_rounded,
    );
  });

  testWidgets('a click or Enter on a long leaf shows it whole', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const JsonView(data: _data, showToolbar: false)),
    );
    final leaf = find.textContaining('"image"');
    final shut = tester.getSize(leaf).height;
    expect(tester.widget<Text>(leaf).maxLines, 1);
    expect(
      tester.getSemantics(leaf),
      isSemantics(hasExpandedState: true, isExpanded: false, isButton: true),
    );

    await tester.tap(leaf);
    await tester.pump();
    expect(tester.widget<Text>(leaf).maxLines, isNull);
    final open = tester.getSize(leaf).height;
    expect(open, greaterThan(shut * 2));
    expect(tester.getSemantics(leaf), isSemantics(isExpanded: true));
    // The row grows with it: the next line starts below the wrapped text.
    final closing = find.text('}');
    expect(
      tester.getTopLeft(closing).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(leaf).dy),
    );

    // It is a Tab stop, after the root line, "id", "customer" and "email".
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tester.widget<Text>(leaf).maxLines, 1);
    handle.dispose();
  });

  testWidgets('a leaf that fits is a Tab stop that does not wrap, and a '
      'screen reader copies any line through its actions', (tester) async {
    final handle = tester.ensureSemantics();
    final written = _clipboard(tester);
    await tester.pumpWidget(_host(const JsonView(data: _data)));
    final id = tester.getSemantics(find.textContaining('"id"'));
    expect(id, isNot(isSemantics(hasExpandedState: true)));
    expect(id, isSemantics(isFocusable: true));

    void perform(SemanticsNode node, String label) {
      final action = node
          .getSemanticsData()
          .customSemanticsActionIds!
          .map(CustomSemanticsAction.getAction)
          .firstWhere((a) => a!.label == label)!;
      node.owner!.performAction(
        node.id,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(action),
      );
    }

    perform(id, 'Copy value');
    perform(id, 'Copy path');
    // A foldable line carries the same two.
    perform(
      tester.getSemantics(find.textContaining('"customer"')),
      'Copy path',
    );
    await tester.pump();
    expect(written, ['ord_1', r'$.id', r'$.customer']);
    await tester.pump(const Duration(seconds: 2));
    handle.dispose();
  });

  testWidgets('the toolbar keeps its actions in a narrow view', (tester) async {
    await tester.pumpWidget(_host(const JsonView(data: _data), width: 280));
    expect(tester.takeException(), isNull);
    final search = tester.getSize(find.byType(SearchField)).width;
    expect(search, greaterThanOrEqualTo(120));
    expect(search, lessThan(180));
    final copyAll = tester.getRect(find.byType(CopyButton));
    expect(copyAll.right, lessThanOrEqualTo(280));

    await tester.pumpWidget(_host(const JsonView(data: _data)));
    expect(tester.getSize(find.byType(SearchField)).width, 180);
  });

  testWidgets('the toolbar searches with the kit SearchField', (tester) async {
    await tester.pumpWidget(_host(const JsonView(data: _data)));
    expect(find.byType(SearchField), findsOneWidget);
    expect(
      tester.widget<SearchField>(find.byType(SearchField)).size,
      ControlSize.small,
    );
    await tester.enterText(find.byType(TextField), 'email');
    await tester.pump();
    expect(find.textContaining('"email"'), findsOneWidget);
    expect(find.textContaining('"id"'), findsNothing);
  });

  testWidgets('the lines sit in a SelectionArea', (tester) async {
    await tester.pumpWidget(_host(const JsonView(data: _data)));
    expect(
      find.ancestor(
        of: find.textContaining('"email"'),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );
  });

  testWidgets('lines are in the mono role, rows fit a copy action', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const JsonView(data: _data)));
    final text = tester.widget<Text>(find.textContaining('"email"'));
    final style = text.textSpan!.style!;
    final mono = defaultTokens.typography.mono;
    expect(style.fontSize, mono.fontSize);
    expect(style.height, mono.height);
    expect(style.fontFamily, mono.fontFamily);
    final row = tester.getSize(
      find
          .ancestor(
            of: find.textContaining('"email"'),
            matching: find.byType(Container),
          )
          .last,
    );
    expect(row.height, greaterThanOrEqualTo(IconActionSize.inline.box));
  });

  testWidgets('a source that fails to parse shows its error alone', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const JsonView.source('{"a": }')));
    expect(find.textContaining('Invalid JSON'), findsOneWidget);
    expect(find.byType(SearchField), findsNothing);
    expect(find.byType(CopyButton), findsNothing);
  });
}
