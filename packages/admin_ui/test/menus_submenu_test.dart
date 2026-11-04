import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _selected = <String>[];

List<MenuEntry> _entries() => [
  MenuItem('Rename', onSelect: () => _selected.add('Rename')),
  MenuSubmenu(
    'Move to',
    entries: [
      MenuItem('Blog', onSelect: () => _selected.add('Blog')),
      const MenuItem('Archive'),
      MenuItem('Docs', onSelect: () => _selected.add('Docs')),
    ],
  ),
  const MenuSubmenu(
    'Share',
    enabled: false,
    entries: [MenuItem('Link', onSelect: _noop)],
  ),
  MenuItem('Delete', onSelect: () => _selected.add('Delete')),
];

void _noop() {}

/// A submenu longer than the menu it opens from: its last rows run past the
/// menu's bottom edge.
List<MenuEntry> _longEntries() => [
  MenuItem('Rename', onSelect: () => _selected.add('Rename')),
  MenuSubmenu(
    'Move to',
    entries: [
      for (final folder in _folders)
        MenuItem(folder, onSelect: () => _selected.add(folder)),
    ],
  ),
  MenuItem('Delete', onSelect: () => _selected.add('Delete')),
];

const _folders = ['Blog', 'Docs', 'Drafts', 'Help', 'News', 'Archive'];

/// An account menu: a submenu whose own submenus are longer than the menu.
List<MenuEntry> _accountEntries() => [
  const MenuHeader('Signed in'),
  MenuItem(
    'Profile',
    icon: Icons.person_outline,
    onSelect: () => _selected.add('Profile'),
  ),
  MenuSubmenu(
    'Appearance',
    icon: Icons.palette_outlined,
    entries: [
      MenuSubmenu(
        'Theme',
        entries: [
          for (final theme in _themes)
            MenuCheckboxItem(
              theme,
              checked: theme == _themes.first,
              onChanged: (_) => _selected.add(theme),
            ),
        ],
      ),
      MenuSubmenu(
        'Mode',
        entries: [
          for (final mode in const ['System', 'Light', 'Dark'])
            MenuCheckboxItem(
              mode,
              checked: mode == 'System',
              onChanged: (_) => _selected.add(mode),
            ),
        ],
      ),
      const MenuDivider(),
      MenuItem(
        'More settings',
        icon: Icons.tune,
        onSelect: () => _selected.add('More settings'),
      ),
    ],
  ),
  const MenuDivider(),
  MenuItem(
    'Sign out',
    icon: Icons.logout,
    onSelect: () => _selected.add('Sign out'),
  ),
];

const _themes = ['Paper', 'Slate', 'Sand', 'Moss', 'Coral', 'Ink', 'Frost'];

/// [_accountEntries] behind a trigger in the window's top end corner, the
/// menu lined up with the trigger's end edge.
Widget _cornerHost(TextDirection direction) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Align(
        alignment: AlignmentDirectional.topEnd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Menu(
            align: PopoverAlign.end,
            entries: _accountEntries(),
            builder: (context, c) =>
                TextButton(onPressed: c.toggle, child: const Text('Account')),
          ),
        ),
      ),
    ),
  ),
);

Widget _host({
  TextDirection direction = TextDirection.ltr,
  AlignmentGeometry alignment = Alignment.center,
  List<MenuEntry> Function() entries = _entries,
}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Align(
        alignment: alignment,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextButton(onPressed: () {}, child: const Text('Before')),
            Menu(
              entries: entries(),
              builder: (context, c) =>
                  TextButton(onPressed: c.toggle, child: const Text('Actions')),
            ),
            TextButton(onPressed: () {}, child: const Text('After')),
          ],
        ),
      ),
    ),
  ),
);

String? _focused() => FocusManager.instance.primaryFocus?.debugLabel;

bool _hasFocus(WidgetTester tester, String text) =>
    Focus.maybeOf(tester.element(find.text(text)))?.hasPrimaryFocus ?? false;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// Opens the menu from the keyboard and moves down to "Move to".
Future<void> _toSubmenuRow(WidgetTester tester) async {
  await _key(tester, LogicalKeyboardKey.tab);
  await _key(tester, LogicalKeyboardKey.tab);
  await _key(tester, LogicalKeyboardKey.enter);
  expect(_focused(), 'Rename');
  await _key(tester, LogicalKeyboardKey.arrowDown);
  expect(_focused(), 'Move to');
}

/// The rounded highlight of the row labelled [text]: its hit area, inset
/// in the menu.
Rect _row(WidgetTester tester, String text) => tester.getRect(
  find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first,
);

/// The surface of the menu holding [text].
Rect _surface(WidgetTester tester, String text) => tester.getRect(
  find
      .ancestor(of: find.text(text), matching: find.byType(PopoverMenuSurface))
      .first,
);

void _window(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  return mouse;
}

/// A click as a hand makes one: the pointer moves onto [text], and frames
/// go by between the press and the release.
Future<void> _click(WidgetTester tester, TestGesture mouse, String text) async {
  final at = tester.getCenter(find.text(text));
  await mouse.moveTo(at);
  await tester.pump();
  await mouse.down(at);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 40));
  await mouse.up();
  await tester.pumpAndSettle();
}

bool _shown(String text) => find.text(text).evaluate().isNotEmpty;

void main() {
  setUp(_selected.clear);

  testWidgets('→ opens the submenu on its first item and ← closes it back '
      'to its row', (tester) async {
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);

    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'Blog');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Docs', reason: 'the disabled Archive is skipped');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Blog', reason: 'the arrows wrap within the level');
    await _key(tester, LogicalKeyboardKey.end);
    expect(_focused(), 'Docs');
    await _key(tester, LogicalKeyboardKey.keyB);
    expect(_focused(), 'Blog', reason: 'typeahead within the level');

    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text('Blog'), findsNothing);
    expect(find.text('Rename'), findsOneWidget, reason: 'the menu stays');
    expect(_focused(), 'Move to');
  });

  testWidgets('in a right-to-left app ← opens it, on the row\'s left, and '
      '→ closes it', (tester) async {
    await tester.pumpWidget(_host(direction: TextDirection.rtl));
    await _toSubmenuRow(tester);

    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('Blog'), findsNothing, reason: '→ points away from it');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(), 'Blog');
    expect(
      _surface(tester, 'Blog').right,
      closeTo(_row(tester, 'Move to').left, 0.5),
    );

    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('Blog'), findsNothing);
    expect(_focused(), 'Move to');
  });

  testWidgets('Enter and Space open the submenu on its first item', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_focused(), 'Blog');
    expect(_selected, isEmpty);

    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.space);
    expect(_focused(), 'Blog');
  });

  testWidgets('Escape closes the submenu alone, then the menu', (tester) async {
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);

    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('Blog'), findsNothing);
    expect(_focused(), 'Move to');

    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('Rename'), findsNothing);
    expect(_hasFocus(tester, 'Actions'), isTrue);
  });

  testWidgets('Tab in the submenu closes every level and moves on from the '
      'trigger', (tester) async {
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);

    await _key(tester, LogicalKeyboardKey.tab);
    expect(find.text('Blog'), findsNothing);
    expect(find.text('Rename'), findsNothing);
    expect(_hasFocus(tester, 'After'), isTrue);
  });

  testWidgets('choosing an item in the submenu closes every level, then '
      'runs it', (tester) async {
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.enter);

    expect(_selected, ['Docs']);
    expect(find.text('Docs'), findsNothing);
    expect(find.text('Rename'), findsNothing);
    expect(_hasFocus(tester, 'Actions'), isTrue);

    // And by the pointer.
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blog'));
    await tester.pumpAndSettle();
    expect(_selected, ['Docs', 'Blog']);
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('the arrows move on past a submenu row, closing its open '
      'submenu, and skip a disabled one', (tester) async {
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);
    // Opened by a click, the submenu leaves focus on its row.
    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsOneWidget);
    expect(_focused(), 'Move to');

    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Delete', reason: 'Share is disabled');
    expect(find.text('Blog'), findsNothing);
  });

  testWidgets('a click opens the submenu and a second closes it; one the '
      'pointer opened stays open on a click', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsOneWidget);
    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Rename')));
    await mouse.moveTo(tester.getCenter(find.text('Move to')));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsOneWidget);
    await mouse.down(tester.getCenter(find.text('Move to')));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsOneWidget, reason: 'hover opened it');
  });

  testWidgets('resting the pointer opens the submenu; moving to another row '
      'closes it after a grace, and moving into it keeps it', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Rename')));
    await mouse.moveTo(tester.getCenter(find.text('Move to')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Blog'), findsNothing, reason: 'not yet');
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(find.text('Blog'), findsOneWidget);
    expect(
      _focused(),
      'Move to',
      reason: 'the pointer leaves focus on the row',
    );

    await mouse.moveTo(tester.getCenter(find.text('Delete')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Blog'), findsOneWidget, reason: 'within the grace');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsNothing);
    expect(_focused(), 'Delete');

    // Back on the row, then into the submenu across a sibling row's corner.
    await mouse.moveTo(tester.getCenter(find.text('Move to')));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsOneWidget);
    await mouse.moveTo(tester.getCenter(find.text('Docs')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsOneWidget);
    expect(_focused(), 'Docs');
  });

  testWidgets('crossing other rows on the way into the submenu keeps it '
      'and the highlight; moving straight down highlights the next row', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    final row = _row(tester, 'Move to');
    final from = row.centerLeft + const Offset(24, 0);
    await mouse.addPointer(location: from - const Offset(0, 4));
    await mouse.moveTo(from);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(find.text('Blog'), findsOneWidget);

    // A diagonal toward "Docs", over "Share" and "Delete", in small steps
    // as a real pointer moves.
    final to = tester.getCenter(find.text('Docs'));
    const steps = 12;
    for (var i = 1; i <= steps; i++) {
      await mouse.moveTo(Offset.lerp(from, to, i / steps)!);
      await tester.pump(const Duration(milliseconds: 8));
      if (i == steps ~/ 2) {
        expect(_focused(), 'Move to', reason: 'on the way: the row keeps it');
      }
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsOneWidget);
    expect(_focused(), 'Docs');

    // Back to the row, then straight down onto the next one.
    await mouse.moveTo(from);
    await tester.pump();
    final below = tester.getCenter(find.text('Delete'));
    for (var i = 1; i <= 8; i++) {
      await mouse.moveTo(Offset.lerp(from, Offset(from.dx, below.dy), i / 8)!);
      await tester.pump(const Duration(milliseconds: 8));
    }
    expect(_focused(), 'Delete', reason: 'not toward the submenu');
    expect(find.text('Blog'), findsOneWidget, reason: 'within the grace');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Blog'), findsNothing);
  });

  testWidgets('the submenu opens on the row\'s end, its first row level '
      'with it, and flips to the start at the window\'s end edge', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    final row = _row(tester, 'Move to');
    expect(_surface(tester, 'Blog').left, closeTo(row.right, 0.5));
    expect(_row(tester, 'Blog').top, closeTo(row.top, 0.5));
    expect(_row(tester, 'Blog').height, 32);
    expect(row.height, 32);

    await tester.pumpWidget(_host(alignment: Alignment.centerRight));
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.escape);
    await _key(tester, LogicalKeyboardKey.escape);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    final flipped = _row(tester, 'Move to');
    final submenu = _surface(tester, 'Blog');
    expect(submenu.right, closeTo(flipped.left, 0.5));
    expect(submenu.left, greaterThanOrEqualTo(8));
    expect(_row(tester, 'Blog').top, closeTo(flipped.top, 0.5));
  });

  for (final direction in TextDirection.values) {
    testWidgets('on a phone, with no room beside the menu, the submenu keeps '
        'its width and covers the menu instead (${direction.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(direction: direction));
      await _toSubmenuRow(tester);
      await _key(
        tester,
        direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft,
      );

      final menu = _surface(tester, 'Rename');
      final submenu = _surface(tester, 'Blog');
      expect(submenu.width, 180, reason: 'the menu\'s minWidth, uncrushed');
      expect(submenu.left, greaterThanOrEqualTo(8));
      expect(submenu.right, lessThanOrEqualTo(360 - 8));
      expect(
        submenu.overlaps(menu),
        isTrue,
        reason: 'neither side has 180 to spare',
      );
      expect(
        _row(tester, 'Blog').top,
        closeTo(_row(tester, 'Move to').top, 0.5),
      );
    });
  }

  for (final direction in TextDirection.values) {
    for (final (window, beside) in [
      (const Size(800, 600), true),
      (const Size(360, 640), false),
    ]) {
      final where = beside ? 'beside its menu' : 'past the menu it lies over';
      testWidgets('a click on an item of a submenu $where chooses it and '
          'closes every level (${direction.name})', (tester) async {
        _window(tester, window);
        await tester.pumpWidget(
          _host(direction: direction, entries: _longEntries),
        );
        final mouse = await _mouse(tester);
        await _click(tester, mouse, 'Actions');
        await _click(tester, mouse, 'Move to');

        final menu = _surface(tester, 'Rename');
        final submenu = _surface(tester, 'Blog');
        final inset = _row(tester, 'Move to').left - menu.left;
        final over = submenu.intersect(menu).width;
        if (beside) {
          expect(over, closeTo(inset, 0.5), reason: 'on the row\'s edge');
        } else {
          expect(over, greaterThan(inset));
        }
        final news = tester.getCenter(find.text('News'));
        expect(menu.contains(news), isFalse);

        await _click(tester, mouse, 'News');
        expect(_selected, ['News']);
        expect(_shown('Blog'), isFalse);
        expect(_shown('Rename'), isFalse);
      });
    }

    testWidgets('a submenu nested in one that opened toward the start lies '
        'over the menu, and a click on its row chooses it, past the menu\'s '
        'edge or over it (${direction.name})', (tester) async {
      _window(tester, const Size(800, 600));
      await tester.pumpWidget(_cornerHost(direction));
      final mouse = await _mouse(tester);
      Future<void> openTheme() async {
        await _click(tester, mouse, 'Account');
        await _click(tester, mouse, 'Appearance');
        await _click(tester, mouse, 'Theme');
      }

      await openTheme();
      final menu = _surface(tester, 'Profile');
      final appearance = _surface(tester, 'Mode');
      final theme = _surface(tester, 'Paper');
      final ltr = direction == TextDirection.ltr;
      expect(
        ltr ? appearance.left < menu.left : appearance.right > menu.right,
        isTrue,
        reason: 'no room toward the end',
      );
      expect(theme.intersect(menu).width, theme.width);
      expect(theme.bottom, greaterThan(menu.bottom));

      final frost = tester.getCenter(find.text('Frost'));
      expect(menu.contains(frost), isFalse);
      await _click(tester, mouse, 'Frost');
      expect(_selected, ['Frost']);
      expect(_shown('Paper'), isFalse);
      expect(_shown('Theme'), isFalse);
      expect(_shown('Profile'), isFalse);

      await openTheme();
      final slate = tester.getCenter(find.text('Slate'));
      expect(menu.contains(slate), isTrue);
      await _click(tester, mouse, 'Slate');
      expect(_selected, ['Frost', 'Slate'], reason: 'not the row under it');
      expect(_shown('Profile'), isFalse);
    });

    testWidgets('resting the pointer on a row of a submenu that lies over '
        'the menu keeps every level open: the menu\'s rows under it do not '
        'take the pointer (${direction.name})', (tester) async {
      _window(tester, const Size(800, 600));
      await tester.pumpWidget(_cornerHost(direction));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, 'Account');
      await _click(tester, mouse, 'Appearance');
      await _click(tester, mouse, 'Theme');
      expect(
        _row(tester, 'Sign out').contains(tester.getCenter(find.text('Slate'))),
        isTrue,
        reason: 'a row of the menu under it',
      );

      await mouse.moveTo(tester.getCenter(find.text('Slate')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(_shown('Slate'), isTrue);
      expect(_shown('Mode'), isTrue);
      expect(_focused(), 'Slate');
    });

    testWidgets('resting a mouse on a submenu\'s row opens it with no click, '
        'at every level (${direction.name})', (tester) async {
      _window(tester, const Size(800, 600));
      await tester.pumpWidget(_cornerHost(direction));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, 'Account');

      await mouse.moveTo(tester.getCenter(find.text('Appearance')));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_shown('Theme'), isFalse, reason: 'not yet');
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(_shown('Theme'), isTrue);

      await mouse.moveTo(tester.getCenter(find.text('Theme')));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump();
      expect(_shown('Paper'), isTrue);
      expect(_focused(), 'Theme');
    });
  }

  testWidgets('the row is a menu item with an expanded state; the submenu is '
      'a menu', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    await _toSubmenuRow(tester);

    SemanticsNode node(String text) => tester.getSemantics(find.text(text));
    expect(node('Move to').getSemanticsData().role, SemanticsRole.menuItem);
    expect(
      node('Move to'),
      isSemantics(
        label: 'Move to',
        isEnabled: true,
        isFocused: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );
    expect(
      node('Share'),
      isSemantics(label: 'Share', isEnabled: false, hasExpandedState: true),
    );

    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(
      node('Move to'),
      isSemantics(label: 'Move to', hasExpandedState: true, isExpanded: true),
    );
    SemanticsNode? menu = node('Blog').parent;
    while (menu != null && menu.getSemanticsData().role != SemanticsRole.menu) {
      menu = menu.parent;
    }
    expect(menu, isNotNull, reason: 'the submenu is a menu');
    expect(node('Blog').getSemanticsData().role, SemanticsRole.menuItem);
    semantics.dispose();
  });
}
