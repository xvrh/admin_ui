import 'package:admin_ui/src/forms/insert_picker.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _entries = [
  InsertPickerEntry(
    id: 'hero',
    label: 'Hero',
    description: 'Big banner',
    icon: Icons.image,
    category: 'Marketing',
    preview: (_) => const Text('LIVE-HERO'),
  ),
  const InsertPickerEntry(
    id: 'cta',
    label: 'CTA band',
    description: 'Strip with a button',
    icon: Icons.campaign,
    category: 'Marketing',
  ),
  const InsertPickerEntry(
    id: 'prose',
    label: 'Prose',
    description: 'Rich text',
    icon: Icons.notes,
    category: 'Content',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  ValueChanged<InsertPickerEntry>? onSelect,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: InsertPicker(
              entries: _entries,
              onSelect: onSelect ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

/// The option a screen reader is told is focused.
String? _focusedOption(WidgetTester tester) {
  final focused = [
    for (final title in ['Hero', 'CTA band', 'Prose'])
      if (isSemantics(isFocused: true).matches(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^$title\n'))),
        {},
      ))
        title,
  ];
  return focused.isEmpty ? null : focused.single;
}

void main() {
  group('layout', () {
    testWidgets('with room for both panes, the preview sits beside the list', (
      tester,
    ) async {
      await _pump(tester, width: 700);
      expect(find.text('LIVE-HERO'), findsOneWidget);
      expect(find.byTooltip('Preview'), findsNothing);
      final list = tester.getRect(find.text('Hero'));
      final preview = tester.getRect(find.text('LIVE-HERO'));
      expect(preview.left, greaterThan(list.right));
    });

    testWidgets('narrower than both panes, one pane with preview on demand', (
      tester,
    ) async {
      await _pump(tester, width: 420);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(InsertPicker)).width, 420);
      expect(find.text('LIVE-HERO'), findsNothing);

      final toggle = find.byIcon(Icons.visibility_outlined).first;
      await tester.tap(toggle);
      await tester.pump();
      expect(find.text('LIVE-HERO'), findsOneWidget);
      // Below the list, not beside it.
      final list = tester.getRect(find.text('Prose'));
      final preview = tester.getRect(find.text('LIVE-HERO'));
      expect(preview.top, greaterThan(list.bottom));

      // The preview follows the keyboard.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(find.text('LIVE-HERO'), findsNothing);
      expect(find.text('NO PREVIEW'), findsOneWidget);
    });
  });

  group('listbox', () {
    testWidgets('arrows rove over options, skipping headers and wrapping', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, width: 700);
      expect(_focusedOption(tester), 'Hero');

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedOption(tester), 'CTA band');
      // Past the CONTENT header.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedOption(tester), 'Prose');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedOption(tester), 'Hero', reason: 'wraps to the top');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focusedOption(tester), 'Prose');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focusedOption(tester), 'Hero');
      handle.dispose();
    });

    testWidgets('options announce their place and act on tap', (tester) async {
      final handle = tester.ensureSemantics();
      InsertPickerEntry? picked;
      await _pump(tester, width: 700, onSelect: (e) => picked = e);

      final prose = find.bySemanticsLabel('Prose\nRich text');
      expect(prose, findsOneWidget);
      final node = tester.getSemantics(prose);
      expect(node.hint, '3 of 3');
      expect(node, isSemantics(isButton: true));
      expect(find.bySemanticsLabel('Choices'), findsOneWidget);

      tester.semantics.tap(find.semantics.byLabel('Prose\nRich text'));
      expect(picked?.id, 'prose');
      handle.dispose();
    });

    testWidgets('Enter inserts the highlighted option', (tester) async {
      InsertPickerEntry? picked;
      await _pump(tester, width: 700, onSelect: (e) => picked = e);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked?.id, 'prose');
    });

    testWidgets('the pointer moves the highlight', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, width: 700);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('CTA band')));
      await tester.pump();
      expect(_focusedOption(tester), 'CTA band');
      await gesture.removePointer();
      handle.dispose();
    });
  });
}
