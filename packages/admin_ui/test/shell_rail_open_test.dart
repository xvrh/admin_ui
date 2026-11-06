import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late List<String> opened;
  late List<String> chosen;
  final page = GlobalKey();
  const dashboardKey = ValueKey('dashboard');

  /// A tablet-wide shell beside a collapsed rail, with an account at its
  /// foot.
  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(900, 700),
    TextDirection direction = TextDirection.ltr,
  }) async {
    opened = [];
    chosen = [];
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        builder: (context, child) =>
            Directionality(textDirection: direction, child: child!),
        home: AdminScope(
          child: Builder(
            builder: (context) => Shell(
              topBar: const TopBar(leading: Text('Acme')),
              sidebar: Sidebar(
                collapsed: AdminBreakpoint.of(context).isMedium,
                footer: SidebarAccount(
                  name: 'Jane Doe',
                  entries: [
                    MenuItem('Sign out', onSelect: () => chosen.add('out')),
                  ],
                ),
                entries: [
                  const NavSection('Content'),
                  NavItem(
                    'Dashboard',
                    key: dashboardKey,
                    icon: Icons.dashboard_outlined,
                    selected: true,
                    onTap: () => opened.add('Dashboard'),
                  ),
                  NavItem(
                    'Pages',
                    icon: Icons.description_outlined,
                    onTap: () => opened.add('Pages'),
                  ),
                ],
              ),
              child: SizedBox.expand(key: page),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A mouse, resting nowhere yet.
  Future<TestGesture> mouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(800, 600));
    addTearDown(gesture.removePointer);
    return gesture;
  }

  Offset icon(WidgetTester tester) =>
      tester.getCenter(find.byIcon(Icons.description_outlined));

  /// Whether the sidebar draws expanded: only then does it show its section
  /// label (a rail item's tooltip would also show the item's name).
  bool isOpen(WidgetTester tester) =>
      find.text('CONTENT').evaluate().isNotEmpty;

  /// The column's width, wherever it is drawn.
  double columnWidth(WidgetTester tester) => tester
      .getSize(
        find
            .descendant(
              of: find.byType(Sidebar),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      )
      .width;

  double pageStart(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(page)).dx;

  group('the pointer', () {
    testWidgets('resting on the rail opens it over the page, which stays put', (
      tester,
    ) async {
      await pumpShell(tester);
      final before = pageStart(tester);
      final pointer = await mouse(tester);

      await pointer.moveTo(icon(tester));
      await tester.pump(Sidebar.railOpenDelay ~/ 2);
      expect(isOpen(tester), isFalse, reason: 'not yet');

      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue);
      expect(pageStart(tester), before);
      expect(
        columnWidth(tester),
        Sidebar.widthOf(tester.element(find.byKey(page))),
        reason: 'as wide as the expanded sidebar',
      );
      expect(find.byKey(dashboardKey), findsOneWidget, reason: 'one column');
    });

    testWidgets('crossing the rail leaves it shut', (tester) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(icon(tester));
      await tester.pump(Sidebar.railOpenDelay ~/ 2);
      await pointer.moveTo(const Offset(500, 300));
      await tester.pump(Sidebar.railOpenDelay * 2);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse);
    });

    testWidgets('leaving the open rail folds it back into its place', (
      tester,
    ) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(icon(tester));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue);

      await pointer.moveTo(const Offset(500, 300));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse);
      expect(columnWidth(tester), Sidebar.collapsedWidth);
    });

    testWidgets('an item opens and the rail closes, shut under the pointer '
        'until it leaves', (tester) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(icon(tester));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();

      await pointer.down(icon(tester));
      await pointer.up();
      await tester.pumpAndSettle();
      expect(opened, ['Pages']);
      expect(isOpen(tester), isFalse);

      await tester.pump(Sidebar.railOpenDelay * 2);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse, reason: 'the pointer has not left');

      await pointer.moveTo(const Offset(500, 300));
      await pointer.moveTo(icon(tester));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue, reason: 'it left and came back');
    });

    testWidgets('a click on the shut rail opens the item and keeps it shut', (
      tester,
    ) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(icon(tester));
      await pointer.down(icon(tester));
      await pointer.up();
      await tester.pump(Sidebar.railOpenDelay * 2);
      await tester.pumpAndSettle();
      expect(opened, ['Pages']);
      expect(isOpen(tester), isFalse);
    });

    testWidgets('a menu opened from the rail holds it open', (tester) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.moveTo(tester.getCenter(find.byType(Avatar)));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue);

      await pointer.down(tester.getCenter(find.text('Jane Doe')));
      await pointer.up();
      await tester.pumpAndSettle();
      final signOut = find.text('Sign out');
      expect(signOut, findsOneWidget);

      await pointer.moveTo(tester.getCenter(signOut));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue, reason: 'the menu holds focus');

      await pointer.down(tester.getCenter(signOut));
      await pointer.up();
      await tester.pumpAndSettle();
      expect(chosen, ['out']);

      await pointer.moveTo(const Offset(500, 300));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse, reason: 'the menu has let it go');
    });

    testWidgets('right to left, it opens from the right edge', (tester) async {
      await pumpShell(tester, direction: TextDirection.rtl);
      final pointer = await mouse(tester);
      await pointer.moveTo(icon(tester));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue);
      final column = find
          .descendant(
            of: find.byType(Sidebar),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(tester.getTopRight(column).dx, 900);
      expect(tester.getSize(column).width, greaterThan(Sidebar.collapsedWidth));
    });
  });

  group('the keyboard', () {
    bool focused(WidgetTester tester, IconData icon) =>
        Focus.of(tester.element(find.byIcon(icon))).hasFocus;

    testWidgets('Tab into the rail opens it; Escape folds it and keeps focus; '
        'Tab out closes it', (tester) async {
      await pumpShell(tester);
      for (
        var i = 0;
        i < 5 && !focused(tester, Icons.dashboard_outlined);
        i++
      ) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(focused(tester, Icons.dashboard_outlined), isTrue);
      expect(isOpen(tester), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue, reason: 'moving within it');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse);
      expect(focused(tester, Icons.description_outlined), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue, reason: 'a key in it opens it again');

      for (var i = 0; i < 5 && isOpen(tester); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(isOpen(tester), isFalse, reason: 'focus left it');
    });

    testWidgets('focus a click leaves in it does not open it', (tester) async {
      await pumpShell(tester);
      final pointer = await mouse(tester);
      await pointer.down(const Offset(500, 300));
      await pointer.up();
      Focus.of(tester.element(find.byIcon(Icons.dashboard_outlined)))
          .requestFocus();
      await tester.pumpAndSettle();
      expect(isOpen(tester), isFalse);
    });
  });

  group('the shell', () {
    testWidgets('beside the rail, the top bar opens the drawer', (
      tester,
    ) async {
      await pumpShell(tester);
      expect(find.byType(ShellMenuButton), findsOneWidget);
      await tester.tap(find.byType(ShellMenuButton));
      await tester.pumpAndSettle();
      expect(isOpen(tester), isTrue, reason: 'the drawer');

      tester.view.physicalSize = const Size(1300, 700);
      await tester.pumpAndSettle();
      expect(find.byType(ShellMenuButton), findsNothing);
      expect(find.byType(Sidebar), findsOneWidget, reason: 'drawer closed');
    });

    testWidgets('beside a whole sidebar, the top bar has no menu button', (
      tester,
    ) async {
      await pumpShell(tester, size: const Size(1300, 700));
      expect(find.byType(ShellMenuButton), findsNothing);
      expect(Shell.hasDrawer(tester.element(find.byKey(page))), isFalse);
    });
  });
}
