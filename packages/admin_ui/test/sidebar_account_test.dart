import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late List<String> chosen;

  SidebarAccount account() => SidebarAccount(
    name: 'Jane Doe',
    detail: 'jane@example.com',
    badge: const Tag('Owner'),
    entries: [
      MenuItem('Profile', onSelect: () => chosen.add('Profile')),
      MenuItem('Sign out', onSelect: () => chosen.add('Sign out')),
    ],
  );

  Future<void> pumpSidebar(WidgetTester tester, {bool collapsed = false}) {
    chosen = [];
    return tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: Scaffold(
          body: Row(
            children: [
              Sidebar(
                collapsed: collapsed,
                entries: const [
                  NavItem('Pages', icon: Icons.description_outlined),
                ],
                footer: account(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The menu's header, the second place the name is written once it opens.
  final header = find.text('Owner');

  testWidgets('expanded, the row names the account and opens its menu', (
    tester,
  ) async {
    await pumpSidebar(tester);

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(header, findsNothing);

    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    expect(header, findsOneWidget);
    expect(find.text('Jane Doe'), findsNWidgets(2));

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(chosen, ['Sign out']);
    expect(header, findsNothing);
  });

  testWidgets('expanded, the menu opens above the row and as wide as it', (
    tester,
  ) async {
    await pumpSidebar(tester);
    final row = tester.getRect(find.byType(Menu));

    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    final menu = tester.getRect(find.byType(PopoverMenuSurface));
    expect(menu.bottom, lessThanOrEqualTo(row.top));
    expect(menu.left, row.left);
    expect(menu.width, row.width);
  });

  testWidgets('in the rail, the avatar alone, and the menu beside it', (
    tester,
  ) async {
    await pumpSidebar(tester, collapsed: true);

    expect(find.text('Jane Doe'), findsNothing);
    expect(find.byType(Avatar), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Tip && w.message == 'Jane Doe'),
      findsOneWidget,
    );

    final rail = tester.getRect(find.byType(Sidebar));
    await tester.tap(find.byType(Avatar));
    await tester.pumpAndSettle();
    expect(header, findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(
      tester.getRect(find.byType(PopoverMenuSurface)).left,
      greaterThanOrEqualTo(rail.right),
    );
  });

  testWidgets('as the rail opens, the row is revealed rather than squeezed', (
    tester,
  ) async {
    await pumpSidebar(tester, collapsed: true);
    await pumpSidebar(tester);
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.takeException(), isNull);
    }
    expect(find.text('jane@example.com'), findsOneWidget);
  });

  testWidgets('the row is one button named for the account, expanded while '
      'its menu is open', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSidebar(tester);

    final button = find.bySemanticsLabel('Jane Doe');
    expect(
      tester.getSemantics(button),
      isSemantics(
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(button.first),
      isSemantics(isButton: true, hasExpandedState: true, isExpanded: true),
    );
    semantics.dispose();
  });

  testWidgets('a long detail is cut on one line, in the row and the header', (
    tester,
  ) async {
    chosen = [];
    const long = 'a.very.long.address.for.someone@example.com';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: Scaffold(
          body: Row(
            children: [
              Sidebar(
                entries: const [],
                footer: SidebarAccount(
                  name: 'Jane Doe',
                  detail: long,
                  entries: [MenuItem('Sign out', onSelect: () {})],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();

    for (final element in find.text(long).evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isTrue);
    }
    expect(find.text(long), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  group('Sidebar.isCollapsed', () {
    Future<bool?> read(
      WidgetTester tester,
      Widget Function(Widget) wrap,
    ) async {
      bool? seen;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              seen = Sidebar.isCollapsed(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return seen;
    }

    Widget sidebar(Widget footer, {required bool collapsed}) => MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            Sidebar(collapsed: collapsed, entries: const [], footer: footer),
          ],
        ),
      ),
    );

    testWidgets('follows the rail', (tester) async {
      expect(
        await read(tester, (child) => sidebar(child, collapsed: true)),
        isTrue,
      );
      expect(
        await read(tester, (child) => sidebar(child, collapsed: false)),
        isFalse,
      );
    });

    testWidgets('is false outside a sidebar', (tester) async {
      expect(await read(tester, (child) => MaterialApp(home: child)), isFalse);
    });

    testWidgets('is false in the navigation drawer, which draws it expanded', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      chosen = [];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: AdminScope(
            child: Shell(
              topBar: const TopBar(title: 'Acme'),
              sidebar: Sidebar(
                collapsed: true,
                entries: const [],
                footer: account(),
              ),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ShellMenuButton));
      await tester.pumpAndSettle();
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });
  });
}
