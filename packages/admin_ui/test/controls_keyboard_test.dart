import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

/// The widget of type [T] that holds the primary focus.
Finder _focused<T>() => find.byWidgetPredicate((w) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null || w is! T) return false;
  var found = false;
  context.visitAncestorElements((e) {
    if (e.widget == w) found = true;
    return !found;
  });
  return found;
});

/// The label of the option or segment under the primary focus.
String? _focusedLabel(WidgetTester tester) {
  if (_primaryNode() == null) return null;
  final texts = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is Tappable && identical(w.focusNode, _primaryNode()),
    ),
    matching: find.byType(Text),
  );
  final labels = [
    for (final t in tester.widgetList<Text>(texts))
      if ((t.data ?? '').isNotEmpty) t.data!,
  ];
  return labels.isEmpty ? null : labels.first;
}

FocusNode? _primaryNode() => FocusManager.instance.primaryFocus;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  testWidgets('Tab reaches each control once, in order', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Toggle(value: false, onChanged: (_) {}, label: 'Toggle'),
            Check(value: false, onChanged: (_) {}, label: 'Check'),
            Choice<String>(
              value: 'b',
              onChanged: (_) {},
              options: const [
                ChoiceOption('a', 'Alpha'),
                ChoiceOption('b', 'Beta'),
                ChoiceOption('c', 'Gamma'),
              ],
            ),
            Segmented<String>(
              value: 'y',
              onChanged: (_) {},
              segments: const [
                SegmentOption('x', 'Ex'),
                SegmentOption('y', 'Why'),
                SegmentOption('z', 'Zed'),
              ],
            ),
            const Button('After', onPressed: _noop),
          ],
        ),
      ),
    );

    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<Toggle>(), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<Check>(), findsOneWidget);
    // One stop per group: the selected option, then the selected segment.
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focusedLabel(tester), 'Beta');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focusedLabel(tester), 'Why');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<Button>(), findsOneWidget);
  });

  testWidgets('read-only controls are not Tab stops', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Toggle(value: true, label: 'Toggle'),
            Check(value: true, label: 'Check'),
            Choice<String>(
              value: 'a',
              onChanged: null,
              options: [ChoiceOption('a', 'Alpha')],
            ),
            Segmented<String>(
              value: 'x',
              segments: [SegmentOption('x', 'Ex'), SegmentOption('y', 'Why')],
            ),
            Button('After', onPressed: _noop),
          ],
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<Button>(), findsOneWidget);
  });

  for (final key in [LogicalKeyboardKey.space, LogicalKeyboardKey.enter]) {
    testWidgets('${key.keyLabel} flips a focused Toggle and Check', (
      tester,
    ) async {
      var toggle = false;
      var check = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Toggle(
                  value: toggle,
                  onChanged: (v) => setState(() => toggle = v),
                  label: 'Toggle',
                ),
                Check(
                  value: check,
                  onChanged: (v) => setState(() => check = v),
                  label: 'Check',
                ),
              ],
            ),
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, key);
      expect(toggle, isTrue);
      await _key(tester, key);
      expect(toggle, isFalse);

      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, key);
      expect(check, isTrue);
    });
  }

  testWidgets('Space on an indeterminate Check checks it', (tester) async {
    bool? reported;
    await tester.pumpWidget(
      _host(
        Check(
          value: false,
          indeterminate: true,
          onChanged: (v) => reported = v,
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.space);
    expect(reported, isTrue);
  });

  group('Choice', () {
    Future<List<String>> pumpChoice(
      WidgetTester tester, {
      String initial = 'a',
      Axis direction = Axis.vertical,
    }) async {
      final picked = <String>[];
      var value = initial;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Choice<String>(
              value: value,
              direction: direction,
              onChanged: (v) => setState(() {
                value = v;
                picked.add(v);
              }),
              options: const [
                ChoiceOption('a', 'Alpha'),
                ChoiceOption('b', 'Beta', enabled: false),
                ChoiceOption('c', 'Gamma'),
                ChoiceOption('d', 'Delta'),
              ],
            ),
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      return picked;
    }

    testWidgets('arrows move and select, skipping disabled options', (
      tester,
    ) async {
      final picked = await pumpChoice(tester);
      expect(_focusedLabel(tester), 'Alpha');

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedLabel(tester), 'Gamma');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(tester), 'Delta');
      // Wraps from the last to the first.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedLabel(tester), 'Alpha');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusedLabel(tester), 'Delta');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedLabel(tester), 'Gamma');
      expect(picked, ['c', 'd', 'a', 'd', 'c']);
    });

    testWidgets('Home and End jump to the first and last enabled', (
      tester,
    ) async {
      final picked = await pumpChoice(tester, initial: 'c');
      expect(_focusedLabel(tester), 'Gamma');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focusedLabel(tester), 'Delta');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focusedLabel(tester), 'Alpha');
      expect(picked, ['d', 'a']);
    });

    testWidgets('the Tab stop follows the selection', (tester) async {
      await pumpChoice(tester, initial: 'd');
      expect(_focusedLabel(tester), 'Delta');
    });

    testWidgets('Tab leaves the group after one stop', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Choice<String>(
                value: 'a',
                onChanged: (_) {},
                options: const [
                  ChoiceOption('a', 'Alpha'),
                  ChoiceOption('b', 'Beta'),
                ],
              ),
              const Button('After', onPressed: _noop),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused<Button>(), findsOneWidget);
    });
  });

  group('Segmented', () {
    testWidgets('arrows move and select; Home and End jump', (tester) async {
      var value = 'a';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Segmented<String>(
              value: value,
              onChanged: (v) => setState(() => value = v),
              segments: const [
                SegmentOption('a', 'One'),
                SegmentOption('b', 'Two'),
                SegmentOption('c', 'Three'),
              ],
            ),
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedLabel(tester), 'One');

      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect((_focusedLabel(tester), value), ('Two', 'b'));
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect((_focusedLabel(tester), value), ('One', 'a'), reason: 'wraps');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect((_focusedLabel(tester), value), ('Three', 'c'));
      await _key(tester, LogicalKeyboardKey.home);
      expect((_focusedLabel(tester), value), ('One', 'a'));
      await _key(tester, LogicalKeyboardKey.end);
      expect((_focusedLabel(tester), value), ('Three', 'c'));
    });

    testWidgets('right-to-left, the right arrow moves back', (tester) async {
      var value = 'b';
      await tester.pumpWidget(
        _host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setState) => Segmented<String>(
                value: value,
                onChanged: (v) => setState(() => value = v),
                segments: const [
                  SegmentOption('a', 'One'),
                  SegmentOption('b', 'Two'),
                  SegmentOption('c', 'Three'),
                ],
              ),
            ),
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(value, 'a');
    });

    testWidgets('Space on the focused segment keeps the value', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(
          Segmented<String>(
            value: 'a',
            onChanged: changes.add,
            segments: const [
              SegmentOption('a', 'One'),
              SegmentOption('b', 'Two'),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.space);
      expect(changes, isEmpty);
    });
  });

  testWidgets('LoadingOverlay keeps focus and taps out while loading', (
    tester,
  ) async {
    var taps = 0;
    Widget overlay(bool loading) => _host(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingOverlay(
            loading: loading,
            child: Button('Inside', onPressed: () => taps++),
          ),
          const Button('After', onPressed: _noop),
        ],
      ),
    );

    await tester.pumpWidget(overlay(true));
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<LoadingOverlay>(), findsNothing);
    expect(_primaryNode()?.context?.widget, isNot(isA<LoadingOverlay>()));
    await tester.tap(find.text('Inside'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pumpWidget(overlay(false));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<LoadingOverlay>(), findsOneWidget);
    await tester.tap(find.text('Inside'));
    expect(taps, 1);
  });
}

void _noop() {}
