import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

enum _Nav { orders, logs, jobs, webhooks, settings }

const _groupIcon = Icons.terminal_rounded;
const _groupKey = ValueKey('developer');

const _icons = {
  _Nav.orders: Icons.receipt_long_outlined,
  _Nav.logs: Icons.subject_rounded,
  _Nav.jobs: Icons.schedule_rounded,
  _Nav.webhooks: Icons.webhook_rounded,
  _Nav.settings: Icons.settings_outlined,
};

class _Form extends FormController {
  @override
  FormStatus get status => FormStatus.dirty;

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}

void main() {
  late List<_Nav> opened;
  late List<bool> asked;

  NavItem item(_Nav nav, {bool marked = false}) => NavItem(
    nav.name,
    icon: _icons[nav]!,
    value: nav,
    selected: marked,
    onTap: () => opened.add(nav),
  );

  /// Orders, a Developer group of three items, and Settings.
  List<NavEntry> entries({
    bool initiallyExpanded = false,
    bool? expanded,
    _Nav? marked,
    bool before = false,
    bool group = true,
  }) => [
    const NavSection('Shop'),
    if (before) NavItem('Customers', icon: Icons.people_outline, onTap: () {}),
    item(_Nav.orders),
    if (group)
      NavGroup(
        'Developer',
        key: _groupKey,
        icon: _groupIcon,
        initiallyExpanded: initiallyExpanded,
        expanded: expanded,
        onExpandedChanged: asked.add,
        items: [
          for (final nav in [_Nav.logs, _Nav.jobs, _Nav.webhooks])
            item(nav, marked: nav == marked),
        ],
      ),
    item(_Nav.settings),
  ];

  Widget host(Widget sidebar) => MaterialApp(
    theme: buildAppTheme(irisTheme.tokens),
    home: Scaffold(body: Row(children: [sidebar])),
  );

  Future<void> pumpSidebar(
    WidgetTester tester, {
    Object? selected,
    bool collapsed = false,
    bool initiallyExpanded = false,
    bool? expanded,
    _Nav? marked,
    bool before = false,
    bool group = true,
  }) async {
    await tester.pumpWidget(
      host(
        Sidebar(
          selected: selected,
          collapsed: collapsed,
          entries: entries(
            initiallyExpanded: initiallyExpanded,
            expanded: expanded,
            marked: marked,
            before: before,
            group: group,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    opened = [];
    asked = [];
  });

  Finder row(_Nav nav) => find.text(nav.name);

  /// The group's items on the screen.
  List<String> shown(WidgetTester tester) => [
    for (final nav in [_Nav.logs, _Nav.jobs, _Nav.webhooks])
      if (row(nav).evaluate().isNotEmpty) nav.name,
  ];

  bool isOpen(WidgetTester tester) => shown(tester).length == 3;

  /// The focus node of the row drawn with [icon].
  FocusNode nodeOf(WidgetTester tester, IconData icon) =>
      Focus.of(tester.element(find.byIcon(icon)));

  /// The label of the row that holds focus.
  String? focused(WidgetTester tester) {
    if (nodeOf(tester, _groupIcon).hasPrimaryFocus) return 'Developer';
    for (final MapEntry(key: nav, value: icon) in _icons.entries) {
      if (find.byIcon(icon).evaluate().isEmpty) continue;
      if (nodeOf(tester, icon).hasPrimaryFocus) return nav.name;
    }
    return null;
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  group('closed and open', () {
    testWidgets('closed, it is one row with the number of its items and a '
        'chevron; open, they follow it, a step in', (tester) async {
      await pumpSidebar(tester);
      expect(find.text('Developer'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
      expect(shown(tester), isEmpty);

      await tester.tap(find.text('Developer'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['logs', 'jobs', 'webhooks']);
      expect(find.text('3'), findsNothing, reason: 'the items say it');
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      final label = tester.getTopLeft(find.text('Developer')).dx;
      expect(
        tester.getTopLeft(find.byIcon(_icons[_Nav.logs]!)).dx,
        moreOrLessEquals(label),
        reason: 'an item\'s glyph starts under the group\'s label',
      );
      expect(
        tester.getTopLeft(find.byIcon(_icons[_Nav.orders]!)).dx,
        moreOrLessEquals(tester.getTopLeft(find.byIcon(_groupIcon)).dx),
        reason: 'the group\'s own row lines up with the items around it',
      );
      expect(
        tester.getTopLeft(row(_Nav.settings)).dy,
        greaterThan(tester.getBottomLeft(row(_Nav.webhooks)).dy),
      );
    });

    testWidgets('a click toggles it and tells the app, and opens no item', (
      tester,
    ) async {
      await pumpSidebar(tester);
      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue);
      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse);
      expect(asked, [true, false]);
      expect(opened, isEmpty);
    });

    testWidgets('it starts as initiallyExpanded says', (tester) async {
      await pumpSidebar(tester, initiallyExpanded: true);
      expect(isOpen(tester), isTrue);
      expect(asked, isEmpty);
    });

    testWidgets('an item under it opens as any item does', (tester) async {
      await pumpSidebar(tester, initiallyExpanded: true);
      await tester.tap(row(_Nav.jobs));
      await tester.pump();
      expect(opened, [_Nav.jobs]);
      expect(isOpen(tester), isTrue);
    });

    testWidgets('with animations disabled it opens at once', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(Sidebar(entries: entries())),
        ),
      );
      await tester.tap(find.text('Developer'));
      await tester.pump();
      expect(isOpen(tester), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('the current item', () {
    testWidgets('a group that holds it starts open', (tester) async {
      await pumpSidebar(tester, selected: _Nav.jobs);
      expect(isOpen(tester), isTrue);
      expect(asked, isEmpty, reason: 'no click asked for it');
    });

    testWidgets('an item that marks itself current opens it too', (
      tester,
    ) async {
      await pumpSidebar(tester, marked: _Nav.webhooks);
      expect(isOpen(tester), isTrue);
    });

    testWidgets('it opens as the current item becomes one of its items', (
      tester,
    ) async {
      await pumpSidebar(tester, selected: _Nav.orders);
      expect(isOpen(tester), isFalse);
      await pumpSidebar(tester, selected: _Nav.logs);
      expect(isOpen(tester), isTrue);
    });

    testWidgets('closed over the current item, its row stands for it; the '
        'next of its items opens it again', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSidebar(tester, selected: _Nav.logs);
      final colors = irisTheme.tokens.palette;
      expect(
        tester.widget<Icon>(find.byIcon(_groupIcon)).color,
        colors.foregroundSecondary,
        reason: 'open, the item is the current row',
      );

      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse);
      expect(
        tester.widget<Icon>(find.byIcon(_groupIcon)).color,
        colors.navSelectedText,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Developer, 3')),
        isSemantics(isSelected: true, hasSelectedState: true),
      );

      await pumpSidebar(tester, selected: _Nav.logs);
      expect(isOpen(tester), isFalse, reason: 'a rebuild leaves it closed');

      await pumpSidebar(tester, selected: _Nav.jobs);
      expect(isOpen(tester), isTrue);

      await pumpSidebar(tester, selected: _Nav.orders);
      expect(isOpen(tester), isTrue, reason: 'it stays as it was left');
      semantics.dispose();
    });
  });

  group('controlled', () {
    testWidgets('it is open exactly when expanded says, whatever the current '
        'item', (tester) async {
      await pumpSidebar(tester, expanded: false, selected: _Nav.logs);
      expect(isOpen(tester), isFalse);
      await pumpSidebar(tester, expanded: true, selected: _Nav.orders);
      expect(isOpen(tester), isTrue);
      await pumpSidebar(tester, expanded: false, selected: _Nav.orders);
      expect(isOpen(tester), isFalse);
    });

    testWidgets('a click reports what it asks for, and changes nothing until '
        'the app applies it', (tester) async {
      await pumpSidebar(tester, expanded: false);
      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(asked, [true]);
      expect(isOpen(tester), isFalse);

      await pumpSidebar(tester, expanded: true);
      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(asked, [true, false]);
      expect(isOpen(tester), isTrue);
    });
  });

  group('what the sidebar keeps', () {
    testWidgets('a group keeps its state as entries come and go around it', (
      tester,
    ) async {
      await pumpSidebar(tester);
      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      await pumpSidebar(tester, before: true);
      expect(isOpen(tester), isTrue);
    });

    testWidgets('a group that went and came back starts over', (tester) async {
      await pumpSidebar(tester);
      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      await pumpSidebar(tester, group: false);
      expect(find.text('Developer'), findsNothing);
      await pumpSidebar(tester);
      expect(isOpen(tester), isFalse);
    });
  });

  group('keyboard and semantics', () {
    testWidgets('its row is a button announced as collapsed, then expanded', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpSidebar(tester);
      SemanticsNode node() =>
          tester.getSemantics(find.bySemanticsLabel('Developer, 3'));
      expect(
        node(),
        isSemantics(
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(node(), isSemantics(hasExpandedState: true, isExpanded: true));
      semantics.dispose();
    });

    testWidgets('Enter and Space toggle it, and keep focus on it', (
      tester,
    ) async {
      await pumpSidebar(tester);
      nodeOf(tester, _groupIcon).requestFocus();
      await tester.pump();

      await press(tester, LogicalKeyboardKey.enter);
      expect(isOpen(tester), isTrue);
      expect(focused(tester), 'Developer');

      await press(tester, LogicalKeyboardKey.space);
      expect(isOpen(tester), isFalse);
      expect(focused(tester), 'Developer');
      expect(opened, isEmpty);
    });

    testWidgets('the arrows step over the rows on the screen', (tester) async {
      await pumpSidebar(tester);
      nodeOf(tester, _icons[_Nav.orders]!).requestFocus();
      await tester.pump();

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(tester), 'Developer');
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(tester), 'settings', reason: 'its items are folded away');

      await press(tester, LogicalKeyboardKey.arrowUp);
      await press(tester, LogicalKeyboardKey.enter);
      final walked = <String?>[];
      for (var i = 0; i < 4; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
        walked.add(focused(tester));
      }
      expect(walked, ['logs', 'jobs', 'webhooks', 'settings']);

      await press(tester, LogicalKeyboardKey.home);
      expect(focused(tester), 'orders');
      await press(tester, LogicalKeyboardKey.end);
      expect(focused(tester), 'settings');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(focused(tester), 'webhooks');
    });

    testWidgets('Tab stops on its row, and on its items only while it is '
        'open', (tester) async {
      await pumpSidebar(tester);
      nodeOf(tester, _icons[_Nav.orders]!).requestFocus();
      await tester.pump();
      await press(tester, LogicalKeyboardKey.tab);
      expect(focused(tester), 'Developer');
      await press(tester, LogicalKeyboardKey.tab);
      expect(focused(tester), 'settings');

      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      nodeOf(tester, _groupIcon).requestFocus();
      await tester.pump();
      await press(tester, LogicalKeyboardKey.tab);
      expect(focused(tester), 'logs');
    });

    testWidgets('focus on one of its items goes to its row as it closes', (
      tester,
    ) async {
      await pumpSidebar(tester, initiallyExpanded: true);
      nodeOf(tester, _icons[_Nav.jobs]!).requestFocus();
      await tester.pump();
      expect(focused(tester), 'jobs');

      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse);
      expect(focused(tester), 'Developer');
    });

    testWidgets('and as its app closes it', (tester) async {
      await pumpSidebar(tester, expanded: true);
      nodeOf(tester, _icons[_Nav.jobs]!).requestFocus();
      await tester.pump();
      await pumpSidebar(tester, expanded: false);
      expect(focused(tester), 'Developer');
    });
  });

  group('the leave guard', () {
    testWidgets('toggling it asks nothing; its items ask before they open', (
      tester,
    ) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: AdminScope(
            child: Shell(
              sidebar: Sidebar(entries: entries()),
              child: UnsavedChangesGuard(
                controller: form,
                child: const Center(child: Text('editor')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(isOpen(tester), isTrue);

      await tester.tap(row(_Nav.logs));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);

      await tester.tap(row(_Nav.logs));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(opened, [_Nav.logs]);

      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(isOpen(tester), isFalse);
    });
  });

  group('the rail', () {
    final page = GlobalKey();

    /// A tablet-wide shell beside a collapsed rail.
    Future<void> pumpShell(WidgetTester tester, {Object? selected}) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: AdminScope(
            child: Builder(
              builder: (context) => Shell(
                topBar: const TopBar(leading: Text('Acme')),
                sidebar: Sidebar(
                  collapsed: AdminBreakpoint.of(context).isMedium,
                  selected: selected,
                  entries: entries(),
                  // A menu that opens beside the column, outside it.
                  footer: Menu(
                    side: PopoverSide.end,
                    entries: const [MenuItem('Sign out')],
                    builder: (context, menu) =>
                        Tappable(onTap: menu.toggle, child: const Text('Me')),
                  ),
                ),
                child: SizedBox.expand(key: page),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<TestGesture> mouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(800, 600));
      addTearDown(gesture.removePointer);
      return gesture;
    }

    /// Whether the sidebar draws expanded: only then does it show its
    /// section label.
    bool railOpen(WidgetTester tester) =>
        find.text('SHOP').evaluate().isNotEmpty;

    Offset groupIcon(WidgetTester tester) =>
        tester.getCenter(find.byIcon(_groupIcon));

    testWidgets('it is its icon alone, lit while it holds the current item', (
      tester,
    ) async {
      await pumpSidebar(tester, collapsed: true, selected: _Nav.jobs);
      expect(find.byIcon(_groupIcon), findsOneWidget);
      expect(find.text('Developer'), findsNothing);
      expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
      for (final nav in [_Nav.logs, _Nav.jobs, _Nav.webhooks]) {
        expect(find.byIcon(_icons[nav]!), findsNothing);
      }
      expect(
        tester.widget<Icon>(find.byIcon(_groupIcon)).color,
        irisTheme.tokens.palette.navSelectedText,
      );
      expect(
        tester.widget<Icon>(find.byIcon(_icons[_Nav.orders]!)).color,
        irisTheme.tokens.palette.foregroundSecondary,
      );
    });

    testWidgets('it is announced as collapsed there, whatever it keeps', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpSidebar(tester, collapsed: true, initiallyExpanded: true);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Developer, 3')),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      semantics.dispose();
    });

    testWidgets('a click on its icon opens the rail over the page, and the '
        'group', (tester) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(groupIcon(tester));
      await pointer.down(groupIcon(tester));
      await pointer.up();
      await tester.pumpAndSettle();
      expect(railOpen(tester), isTrue);
      expect(isOpen(tester), isTrue);
      expect(asked, [true]);

      await pointer.moveTo(const Offset(500, 300));
      await tester.pumpAndSettle();
      expect(railOpen(tester), isFalse, reason: 'the pointer left it');
      expect(shown(tester), isEmpty);
    });

    testWidgets('a click on its icon never closes a group already open', (
      tester,
    ) async {
      await pumpShell(tester, selected: _Nav.logs);
      final pointer = await mouse(tester);
      await pointer.moveTo(groupIcon(tester));
      await pointer.down(groupIcon(tester));
      await pointer.up();
      await tester.pumpAndSettle();
      expect(railOpen(tester), isTrue);
      expect(isOpen(tester), isTrue);
      expect(asked, isEmpty);
    });

    testWidgets('in the open rail a click on its row toggles it, and the '
        'rail stays open until an item opens', (tester) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(groupIcon(tester));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      expect(railOpen(tester), isTrue);
      expect(isOpen(tester), isFalse);

      await pointer.down(groupIcon(tester));
      await pointer.up();
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue);
      expect(railOpen(tester), isTrue);

      final jobs = tester.getCenter(row(_Nav.jobs));
      await pointer.moveTo(jobs);
      await pointer.down(jobs);
      await pointer.up();
      await tester.pumpAndSettle();
      expect(opened, [_Nav.jobs]);
      expect(railOpen(tester), isFalse);
    });

    testWidgets('a finger opens the rail from its icon, and a press outside '
        'closes it', (tester) async {
      await pumpShell(tester);
      await tester.tap(find.byIcon(_groupIcon));
      await tester.pumpAndSettle();
      expect(railOpen(tester), isTrue);
      expect(isOpen(tester), isTrue);

      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(railOpen(tester), isTrue, reason: 'a press on it keeps it');
      expect(isOpen(tester), isFalse);

      await tester.tapAt(const Offset(600, 400));
      await tester.pumpAndSettle();
      expect(railOpen(tester), isFalse);
    });

    testWidgets('a press in a menu opened from the rail is not one outside '
        'it', (tester) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(tester.getCenter(find.text('Me')));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      await pointer.down(tester.getCenter(find.text('Me')));
      await pointer.up();
      await tester.pumpAndSettle();

      final signOut = tester.getCenter(find.text('Sign out'));
      expect(
        signOut.dx,
        greaterThan(Sidebar.widthOf(tester.element(find.byKey(page)))),
        reason: 'the menu is beside the column',
      );
      await pointer.moveTo(signOut);
      await pointer.down(signOut);
      await tester.pumpAndSettle();
      expect(railOpen(tester), isTrue, reason: 'the menu holds it open');
      await pointer.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Escape on one of its items folds the rail and keeps focus '
        'on its row', (tester) async {
      await pumpShell(tester);
      for (var i = 0; i < 6 && focused(tester) != 'Developer'; i++) {
        await press(tester, LogicalKeyboardKey.tab);
      }
      expect(focused(tester), 'Developer');
      expect(railOpen(tester), isTrue, reason: 'a key brought focus in');

      await press(tester, LogicalKeyboardKey.enter);
      expect(isOpen(tester), isTrue);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(tester), 'logs');

      await press(tester, LogicalKeyboardKey.escape);
      expect(railOpen(tester), isFalse);
      expect(focused(tester), 'Developer');

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(railOpen(tester), isTrue, reason: 'a key in it opens it again');
      expect(focused(tester), 'settings');

      await press(tester, LogicalKeyboardKey.escape);
      expect(railOpen(tester), isFalse);
      expect(focused(tester), 'settings', reason: 'a row after the group');
    });

    testWidgets('Enter on one of its items opens it, and focus goes to the '
        'group\'s icon as the rail folds', (tester) async {
      await pumpShell(tester);
      for (var i = 0; i < 6 && focused(tester) != 'Developer'; i++) {
        await press(tester, LogicalKeyboardKey.tab);
      }
      await press(tester, LogicalKeyboardKey.enter);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(tester), 'jobs');

      await press(tester, LogicalKeyboardKey.enter);
      expect(opened, [_Nav.jobs]);
      expect(railOpen(tester), isFalse);
      expect(focused(tester), 'Developer');
    });

    testWidgets('Enter on its icon in the shut rail opens both', (
      tester,
    ) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.down(const Offset(500, 300));
      await pointer.up();
      nodeOf(tester, _groupIcon).requestFocus();
      await tester.pumpAndSettle();
      expect(railOpen(tester), isFalse, reason: 'no key moved focus');

      await press(tester, LogicalKeyboardKey.enter);
      expect(railOpen(tester), isTrue);
      expect(isOpen(tester), isTrue);
      expect(focused(tester), 'Developer');
    });
  });

  group('the navigation drawer', () {
    testWidgets('it toggles there as in the whole sidebar, and only an item '
        'closes the drawer', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: AdminScope(
            child: Shell(
              topBar: const TopBar(leading: Text('Acme')),
              sidebar: Sidebar(collapsed: true, entries: entries()),
              child: const Center(child: Text('page')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Sidebar), findsNothing);
      await tester.tap(find.byType(ShellMenuButton));
      await tester.pumpAndSettle();
      expect(find.text('Developer'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byKey(_groupKey));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue);
      expect(find.byType(Sidebar), findsOneWidget, reason: 'still open');

      await tester.tap(row(_Nav.webhooks));
      await tester.pumpAndSettle();
      expect(opened, [_Nav.webhooks]);
      expect(find.byType(Sidebar), findsNothing, reason: 'the drawer closed');
    });
  });
}
