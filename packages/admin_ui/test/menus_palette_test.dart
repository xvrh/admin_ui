import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

List<PaletteItem> _items(int count) => [
  for (var i = 0; i < count; i++)
    PaletteItem(
      id: 'r$i',
      title: 'Result $i',
      subtitle: '/result-$i',
      icon: Icons.description_outlined,
      group: 'Pages',
      onSelect: () {},
    ),
];

/// A palette showing [count] results for the query "result".
Future<CommandPaletteController> _pump(
  WidgetTester tester, {
  int count = 40,
  double width = 600,
  bool preview = false,
}) async {
  final controller = CommandPaletteController(
    sources: [CommandSource(() => _items(count))],
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: 480,
            child: CommandPalette.controller(
              controller,
              preview: preview,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.enterText(find.byType(TextField), 'result');
  await tester.pumpAndSettle();
  return controller;
}

/// A result title, drawn as rich text with the matched letters emphasised.
Finder _title(String text) => find.text(text, findRichText: true);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('End, Home, PageDown and PageUp move the selection', (
    tester,
  ) async {
    final c = await _pump(tester);
    expect(c.resultCount, 40);

    await _key(tester, LogicalKeyboardKey.end);
    expect(c.selected, 39);
    expect(_title(c.selectedItem!.title).hitTestable(), findsOneWidget);

    await _key(tester, LogicalKeyboardKey.home);
    expect(c.selected, 0);

    await _key(tester, LogicalKeyboardKey.pageDown);
    final page = c.selected;
    expect(page, greaterThan(3), reason: 'about a screenful of rows');
    expect(_title(c.selectedItem!.title).hitTestable(), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.pageDown);
    expect(c.selected, 2 * page);
    await _key(tester, LogicalKeyboardKey.pageUp);
    expect(c.selected, page);
  });

  testWidgets('a still pointer keeps out of the way of the arrow keys', (
    tester,
  ) async {
    final c = await _pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Result 3')));
    await tester.pumpAndSettle();
    expect(c.selected, 0, reason: 'arriving under the pointer is no move');

    await mouse.moveBy(const Offset(4, 0));
    await tester.pumpAndSettle();
    expect(c.selected, 3, reason: 'moving the pointer selects');

    // The list scrolls under the parked pointer as the selection moves down.
    for (var i = 0; i < 15; i++) {
      await _key(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(c.selected, 18);
  });

  testWidgets('a row under the pointer that is not selected is tinted with '
      'the list highlight', (tester) async {
    await _pump(tester, count: 4);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Result 2')));
    await tester.pumpAndSettle();

    BoxDecoration row(String title) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.text(title),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    final colors = tester.element(find.byType(CommandPalette)).colors;
    expect(row('Result 0').color, colors.primarySubtle);
    expect(row('Result 2').color, colors.listHighlight);
    expect(row('Result 1').color, isNull);
  });

  testWidgets('the preview pane is left out below 640px', (tester) async {
    await _pump(tester, count: 3, width: 360, preview: true);
    expect(find.text('Open'), findsNothing);
    expect(find.text('Result 0'), findsOneWidget);
  });

  testWidgets('the preview pane shows from 640px', (tester) async {
    await _pump(tester, count: 3, width: 760, preview: true);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('results are a list of rows that say which is selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, count: 3);
    await _key(tester, LogicalKeyboardKey.arrowDown);

    SemanticsNode node(String title) => tester.getSemantics(
      find.ancestor(of: find.text(title), matching: find.byType(Tappable)),
    );
    expect(
      tester.getSemantics(find.text('Result 1')),
      isSemantics(
        label: 'Result 1, /result-1',
        isSelected: true,
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Result 0')),
      isSemantics(label: 'Result 0, /result-0', isSelected: false),
    );

    SemanticsNode? list = node('Result 0').parent;
    while (list != null && list.getSemanticsData().role != SemanticsRole.list) {
      list = list.parent;
    }
    expect(list, isNotNull);
    semantics.dispose();
  });

  testWidgets('the result count is announced once results settle', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, count: 12);
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains('12 results'),
    );

    await tester.enterText(find.byType(TextField), 'r');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'zz');
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeAnnouncements().map((a) => a.message), ['No results']);
    semantics.dispose();
  });

  testWidgets('CommandTrigger is a labelled Tab stop', (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: CommandTrigger(onTap: () => opened++),
            ),
          ),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    final trigger = find.descendant(
      of: find.byType(CommandTrigger),
      matching: find.byType(GestureDetector),
    );
    expect(
      tester.getSemantics(trigger),
      isSemantics(label: 'Search…', isButton: true, isFocused: true),
    );
    await _key(tester, LogicalKeyboardKey.enter);
    expect(opened, 1);
    semantics.dispose();
  });

  group('list overlays stay readable on their highlights', () {
    const brands = {
      'Default': null,
      'Crimson': Color(0xFFDC2626),
      'Teal': Color(0xFF0D9488),
      'Amber': Color(0xFFD97706),
    };
    for (final MapEntry(key: name, value: base) in shippedPalettes.entries) {
      for (final MapEntry(key: brand, value: seed) in brands.entries) {
        final p = seed == null ? base : base.branded(seed);
        test('$name · $brand', () {
          final danger = Color.alphaBlend(
            p.danger.withValues(alpha: 0.08),
            p.surface,
          );
          expect(
            contrastRatio(p.foreground, p.listHighlight),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(
              p.readableOn(
                p.foregroundMuted,
                surfaces: [p.surface, p.listHighlight],
              ),
              p.listHighlight,
            ),
            greaterThanOrEqualTo(4.5),
            reason: 'a shortcut hint or secondary line under the pointer',
          );
          expect(
            contrastRatio(p.dangerText, danger),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(p.foreground, p.primarySubtle),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(p.primaryText, p.primarySubtle),
            greaterThanOrEqualTo(4.5),
            reason: 'the selected palette row and preset',
          );
        });
      }
    }
  });
}
