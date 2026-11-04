// A TreeEditor row is a Tab stop, and so is each of its actions: they are
// siblings in the focus tree, so the row's Tappable wraps no Tab stop of its
// own, and Tab walks the row, then its actions, then the next row.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _entries = [
  TreeEditorEntry(id: 'home', title: 'Home'),
  TreeEditorEntry(id: 'about', title: 'About'),
];

Future<void> _pump(WidgetTester tester, {TextDirection? direction}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Directionality(
        textDirection: direction ?? TextDirection.ltr,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 560,
              child: TreeEditor(
                maxDepth: 2,
                entries: _entries,
                onMove: (_, _, _) {},
                onSelect: (_) {},
                onToggleVisible: (_) {},
                onAddChild: (_) {},
                onDelete: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// What holds focus: a row's title, or an action's accessible name.
String _focused(WidgetTester tester) {
  final node = FocusManager.instance.primaryFocus!;
  if (node.debugLabel == 'tree entry') {
    final title = find.descendant(
      of: find.byWidget(node.context!.widget),
      matching: find.byType(Text),
    );
    return 'row ${tester.widget<Text>(title.first).data}';
  }
  final semantics = tester.getSemantics(find.byWidget(node.context!.widget));
  return semantics.label;
}

Future<List<String>> _walk(
  WidgetTester tester, {
  required int steps,
  bool back = false,
}) async {
  final seen = <String>[_focused(tester)];
  for (var i = 0; i < steps; i++) {
    if (back) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (back) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    seen.add(_focused(tester));
  }
  return seen;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('Tab walks a row, then its actions ($direction)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, direction: direction);
      Focus.of(tester.element(find.text('Home'))).requestFocus();
      await tester.pump();

      const forward = [
        'row Home',
        'Add child',
        'Delete',
        'Hide',
        'More actions',
        'row About',
      ];
      expect(await _walk(tester, steps: 5), forward);
      expect(
        await _walk(tester, steps: 5, back: true),
        forward.reversed.toList(),
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }
}
