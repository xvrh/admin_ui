import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _selected = <String>[];

List<MenuEntry> _entries() => [
  const MenuHeader('Page'),
  MenuItem('Edit', shortcut: '⌘E', onSelect: () => _selected.add('Edit')),
  MenuItem('Duplicate', onSelect: () => _selected.add('Duplicate')),
  const MenuItem('Archive'),
  const MenuDivider(),
  MenuItem('Delete', danger: true, onSelect: () => _selected.add('Delete')),
];

Widget _host({Widget? trigger, List<MenuEntry>? entries}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: () {}, child: const Text('Before')),
          trigger ??
              Menu(
                entries: entries ?? _entries(),
                builder: (context, c) => TextButton(
                  onPressed: c.toggle,
                  child: const Text('Actions'),
                ),
              ),
          TextButton(onPressed: () {}, child: const Text('After')),
        ],
      ),
    ),
  ),
);

String? _focused() => FocusManager.instance.primaryFocus?.debugLabel;

bool _hasFocus(WidgetTester tester, String text) {
  final node = Focus.maybeOf(tester.element(find.text(text)));
  return node?.hasPrimaryFocus ?? false;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// Tabs onto the trigger and opens the menu with Enter.
Future<void> _openFromKeyboard(WidgetTester tester) async {
  await _key(tester, LogicalKeyboardKey.tab); // Before
  await _key(tester, LogicalKeyboardKey.tab); // Actions
  expect(_hasFocus(tester, 'Actions'), isTrue);
  await _key(tester, LogicalKeyboardKey.enter);
}

void main() {
  setUp(_selected.clear);

  testWidgets('a keyboard open focuses the first enabled item', (tester) async {
    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(_focused(), 'Edit');
  });

  testWidgets('↓ on the closed trigger opens on the first item, ↑ on the '
      'last', (tester) async {
    await tester.pumpWidget(_host());
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Edit');

    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('Duplicate'), findsNothing);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_focused(), 'Delete');
  });

  testWidgets('a pointer open focuses the menu, not an item', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(_focused(), 'Menu');

    // The keys work from there.
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Edit');
  });

  testWidgets('arrows wrap and skip the disabled item; Home and End jump', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);

    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Duplicate');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Delete', reason: 'Archive is disabled');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Edit', reason: 'wraps to the top');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_focused(), 'Delete', reason: 'wraps to the bottom');

    await _key(tester, LogicalKeyboardKey.home);
    expect(_focused(), 'Edit');
    await _key(tester, LogicalKeyboardKey.end);
    expect(_focused(), 'Delete');
  });

  testWidgets('typeahead finds an item by its first letters', (tester) async {
    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);

    await _key(tester, LogicalKeyboardKey.keyD);
    expect(_focused(), 'Duplicate');
    await _key(tester, LogicalKeyboardKey.keyD);
    expect(_focused(), 'Delete', reason: 'a repeated letter cycles');
    await _key(tester, LogicalKeyboardKey.keyD);
    expect(_focused(), 'Duplicate');

    await tester.pump(const Duration(seconds: 2));
    await _key(tester, LogicalKeyboardKey.keyD);
    await _key(tester, LogicalKeyboardKey.keyE);
    expect(_focused(), 'Delete', reason: '"de" matches Delete only');

    await tester.pump(const Duration(seconds: 2));
    await _key(tester, LogicalKeyboardKey.keyA);
    expect(_focused(), 'Delete', reason: 'the disabled Archive is skipped');
  });

  testWidgets('Enter runs the item, closes and returns focus to the trigger', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.enter);

    expect(_selected, ['Duplicate']);
    expect(find.text('Duplicate'), findsNothing);
    expect(_hasFocus(tester, 'Actions'), isTrue);
  });

  testWidgets('Tab and Shift+Tab close the menu and move on from the trigger', (
    tester,
  ) async {
    Future<void> shiftTab() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(find.text('Duplicate'), findsNothing);
    expect(_hasFocus(tester, 'After'), isTrue);

    await shiftTab();
    expect(_hasFocus(tester, 'Actions'), isTrue);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_focused(), 'Edit');
    await shiftTab();
    expect(find.text('Duplicate'), findsNothing);
    expect(_hasFocus(tester, 'Before'), isTrue);
  });

  testWidgets('← and → stay in the menu rather than move focus out of it', (
    tester,
  ) async {
    // A control beside the menu, which directional focus would move to.
    await tester.pumpWidget(
      _host(
        trigger: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: TextButton(onPressed: () {}, child: const Text('Aside')),
            ),
            Menu(
              entries: _entries(),
              builder: (context, c) =>
                  TextButton(onPressed: c.toggle, child: const Text('Actions')),
            ),
          ],
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab); // Before
    await _key(tester, LogicalKeyboardKey.tab); // Aside
    await _key(tester, LogicalKeyboardKey.tab); // Actions
    await _key(tester, LogicalKeyboardKey.enter);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Duplicate');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(_focused(), 'Duplicate');
  });

  testWidgets('Escape after a pointer open closes and focuses the trigger', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(find.text('Duplicate'), findsOneWidget);

    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('Duplicate'), findsNothing);
    expect(_hasFocus(tester, 'Actions'), isTrue);
  });

  testWidgets('Escape closes even when focus has left the menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        trigger: Menu(
          closeOnFocusOut: false,
          entries: _entries(),
          builder: (context, c) =>
              TextButton(onPressed: c.toggle, child: const Text('Actions')),
        ),
      ),
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('After'))).requestFocus();
    await tester.pump();
    expect(find.text('Duplicate'), findsOneWidget);

    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('Duplicate'), findsNothing);
    expect(_hasFocus(tester, 'Actions'), isTrue);
  });

  testWidgets('focus moving elsewhere closes the menu', (tester) async {
    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);
    Focus.of(tester.element(find.text('After'))).requestFocus();
    await tester.pumpAndSettle();
    expect(find.text('Duplicate'), findsNothing);
    expect(_hasFocus(tester, 'After'), isTrue);
  });

  testWidgets('moving the pointer onto an item highlights it; the arrows go '
      'on from there', (tester) async {
    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Duplicate')));
    await mouse.moveBy(const Offset(4, 0));
    await tester.pumpAndSettle();
    expect(_focused(), 'Duplicate');

    // Over the disabled row nothing is highlighted.
    await mouse.moveTo(tester.getCenter(find.text('Archive')));
    await tester.pumpAndSettle();
    expect(_focused(), 'Menu');

    await mouse.moveTo(tester.getCenter(find.text('Duplicate')));
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Delete');
  });

  testWidgets('the highlight survives the host rebuilding the open menu', (
    tester,
  ) async {
    late StateSetter rebuild;
    var ticks = 0;
    await tester.pumpWidget(
      _host(
        trigger: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Menu(
              // A fresh list every build, as call sites write it inline.
              entries: [
                ..._entries(),
                MenuItem('Tick $ticks', onSelect: () {}),
              ],
              builder: (context, c) =>
                  TextButton(onPressed: c.toggle, child: const Text('Actions')),
            );
          },
        ),
      ),
    );
    await _openFromKeyboard(tester);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Duplicate');

    rebuild(() => ticks++);
    await tester.pumpAndSettle();
    expect(find.text('Tick 1'), findsOneWidget);
    expect(_focused(), 'Duplicate');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Delete');
  });

  testWidgets('the menu and its items carry their roles and states', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    await _openFromKeyboard(tester);

    SemanticsNode node(String text) => tester.getSemantics(find.text(text));
    final edit = node('Edit');
    expect(edit.getSemanticsData().role, SemanticsRole.menuItem);
    expect(
      edit,
      isSemantics(
        label: 'Edit\n⌘E',
        isEnabled: true,
        isFocusable: true,
        isFocused: true,
        hasTapAction: true,
      ),
    );
    final archive = node('Archive');
    expect(archive.getSemanticsData().role, SemanticsRole.menuItem);
    expect(archive, isSemantics(label: 'Archive', isEnabled: false));

    SemanticsNode? menu = edit.parent;
    while (menu != null && menu.getSemanticsData().role != SemanticsRole.menu) {
      menu = menu.parent;
    }
    expect(menu, isNotNull, reason: 'the items sit in a menu');
    semantics.dispose();
  });

  testWidgets('checked items are menu radios; the chosen one shows a check', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        entries: [
          MenuItem('All', checked: false, onSelect: () {}),
          MenuItem('Images', checked: true, onSelect: () {}),
          MenuItem('Plain', onSelect: () {}),
        ],
      ),
    );
    await _openFromKeyboard(tester);

    SemanticsNode node(String text) => tester.getSemantics(find.text(text));
    expect(node('All').getSemanticsData().role, SemanticsRole.menuItemRadio);
    expect(
      node('All'),
      isSemantics(
        label: 'All',
        hasCheckedState: true,
        isChecked: false,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      node('Images'),
      isSemantics(
        label: 'Images',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(node('Plain').getSemanticsData().role, SemanticsRole.menuItem);

    // One check, on the chosen row; the other checkable row keeps its room
    // so the labels stay aligned.
    final check = find.byIcon(Icons.check_rounded);
    expect(check, findsOneWidget);
    expect(
      tester.getCenter(check).dy,
      closeTo(tester.getCenter(find.text('Images')).dy, 1),
    );
    semantics.dispose();
  });

  testWidgets(
    'MenuButton is a labelled Tab stop that opens from the keyboard',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          trigger: MenuButton(icon: Icons.more_horiz, entries: _entries()),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab); // Before
      await _key(tester, LogicalKeyboardKey.tab);
      final trigger = find.descendant(
        of: find.byType(MenuButton),
        matching: find.byType(GestureDetector),
      );
      expect(
        tester.getSemantics(trigger.first),
        isSemantics(
          label: 'More',
          isButton: true,
          isFocused: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );

      await _key(tester, LogicalKeyboardKey.enter);
      expect(_focused(), 'Edit');
      expect(
        tester.getSemantics(trigger.first),
        isSemantics(label: 'More', hasExpandedState: true, isExpanded: true),
      );
      semantics.dispose();
    },
  );

  testWidgets('Menu.entry outside a menu is a plain button', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                for (final e in _entries()) Menu.entry(context, e, _Noop()),
              ],
            ),
          ),
        ),
      ),
    );
    final edit = tester.getSemantics(find.text('Edit'));
    expect(edit.getSemanticsData().role, SemanticsRole.none);
    expect(edit, isSemantics(label: 'Edit\n⌘E', isButton: true));
    semantics.dispose();
  });
}

class _Noop implements PopoverController {
  @override
  bool get isOpen => true;

  @override
  double? get anchorWidth => null;

  @override
  void open() {}

  @override
  void close() {}

  @override
  void toggle() {}
}
