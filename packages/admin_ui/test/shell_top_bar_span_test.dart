import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _page = ValueKey('page');
const _logo = ValueKey('logo');

/// [defaultTokens] with the top bar over [span], the sidebar in Ant's sider
/// palette so its head reads apart from the bar.
AdminTokens _tokens(TopBarSpan span) => defaultTokens.copyWith(
  shell: defaultTokens.shell.copyWith(
    topBarSpan: span,
    sidebarPalette: antSiderPalette,
  ),
);

/// A frame: a top bar leading with a logo and titled, over or beside a
/// sidebar of two pages, [collapsed] into the rail.
Widget _app({
  TopBarSpan span = TopBarSpan.page,
  bool collapsed = false,
  Widget? topBar,
  Widget? leading,
  Widget page = const SizedBox.expand(key: _page),
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: buildAppTheme(_tokens(span)),
  home: Directionality(
    textDirection: direction,
    child: AdminScope(
      child: Shell(
        topBar:
            topBar ??
            TopBar(
              title: 'Workspace',
              leading: leading ?? const Text('Acme', key: _logo),
            ),
        sidebar: Sidebar(
          collapsed: collapsed,
          entries: [
            NavItem('Pages', icon: Icons.description_outlined, onTap: () {}),
            NavItem('Media', icon: Icons.photo_library_outlined, onTap: () {}),
          ],
        ),
        child: page,
      ),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget app, {
  Size size = const Size(1280, 800),
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: padding.top);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Finder _inSidebar(Finder f) =>
    find.descendant(of: find.byType(Sidebar), matching: f);

Finder _inTopBar(Finder f) =>
    find.descendant(of: find.byType(TopBar), matching: f);

void main() {
  test('the style carries the span', () {
    const window = AdminShellStyle();
    final page = window.copyWith(topBarSpan: TopBarSpan.page);
    expect(window.topBarSpan, TopBarSpan.window);
    expect(page, isNot(window));
    expect(page.copyWith(topBarHeight: 48).topBarSpan, TopBarSpan.page);
    expect(
      AdminShellStyle.lerp(window, page, 0.4).topBarSpan,
      window.topBarSpan,
    );
    expect(AdminShellStyle.lerp(window, page, 0.6).topBarSpan, page.topBarSpan);
  });

  group('the top bar over the page', () {
    testWidgets('the sidebar runs the window\'s height, the bar and the page '
        'beside it', (tester) async {
      await _pump(tester, _app());
      final width = Sidebar.widthOf(tester.element(find.byType(Sidebar)));
      expect(
        tester.getRect(find.byType(Sidebar)),
        Rect.fromLTRB(0, 0, width, 800),
      );
      expect(
        tester.getRect(find.byType(TopBar)),
        Rect.fromLTRB(width, 0, 1280, TopBar.height),
      );
      expect(
        tester.getRect(find.byKey(_page)),
        Rect.fromLTRB(width, TopBar.height, 1280, 800),
      );
    });

    testWidgets('the leading heads the sidebar, once, at the shell\'s inset '
        'and the bar\'s height, in the sidebar\'s palette', (tester) async {
      late AdminPalette seen;
      await _pump(
        tester,
        _app(
          leading: Builder(
            builder: (context) {
              seen = context.colors;
              return const Text('Acme', key: _logo);
            },
          ),
        ),
      );
      expect(_inSidebar(find.byKey(_logo)), findsOneWidget);
      expect(_inTopBar(find.byKey(_logo)), findsNothing);
      expect(seen.background, antSiderPalette.background);
      final logo = tester.getRect(find.byKey(_logo));
      expect(logo.left, Shell.inset);
      expect(logo.center.dy, tester.getRect(find.text('Workspace')).center.dy);
    });

    testWidgets('the bar\'s content starts at the page gutter', (tester) async {
      await _pump(tester, _app());
      final context = tester.element(find.byType(TopBar));
      expect(
        tester.getRect(find.text('Workspace')).left,
        Sidebar.widthOf(context) + PageHeader.gutterOf(context),
      );
    });

    testWidgets('under the status bar, the sidebar keeps the inset and its '
        'head lines up with the bar', (tester) async {
      await _pump(tester, _app(), padding: const EdgeInsets.only(top: 24));
      expect(tester.getRect(find.byType(Sidebar)).top, 0);
      expect(
        tester.getRect(find.byKey(_logo)).center.dy,
        tester.getRect(find.text('Workspace')).center.dy,
      );
    });

    testWidgets('the rail is headed too, the leading centred and told it is '
        'in the rail', (tester) async {
      bool? collapsed;
      await _pump(
        tester,
        _app(
          collapsed: true,
          leading: Builder(
            builder: (context) {
              collapsed = Sidebar.isCollapsed(context);
              return const SizedBox.square(dimension: 24, key: _logo);
            },
          ),
        ),
        size: const Size(900, 800),
      );
      expect(collapsed, isTrue);
      expect(_inSidebar(find.byKey(_logo)), findsOneWidget);
      final rail = tester.getRect(find.byType(Sidebar));
      expect(
        tester.getRect(find.byKey(_logo)).center.dx,
        moreOrLessEquals(rail.center.dx, epsilon: 1),
      );
      // The bar beside the rail still opens the drawer.
      expect(find.byType(ShellMenuButton), findsOneWidget);
    });

    testWidgets('a leading with a global key is built once as the rail opens '
        'over the page and as the sidebar folds and unfolds', (tester) async {
      final key = GlobalKey();
      Widget app({required bool collapsed}) => _app(
        collapsed: collapsed,
        leading: Text('Acme', key: key),
      );
      await _pump(tester, app(collapsed: false));
      await tester.pumpWidget(app(collapsed: true));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(Sidebar)));
      await tester.pump(Sidebar.railOpenDelay);
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      await gesture.moveTo(const Offset(1000, 400));
      await tester.pumpAndSettle();

      await tester.pumpWidget(app(collapsed: false));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact, the leading is back in the bar', (tester) async {
      await _pump(tester, _app(), size: const Size(360, 700));
      expect(find.byType(Sidebar), findsNothing);
      expect(_inTopBar(find.byKey(_logo)), findsOneWidget);
      expect(tester.getRect(find.byKey(_logo)).top, greaterThan(0));
    });

    testWidgets('a top bar of the app\'s own leaves the sidebar no head', (
      tester,
    ) async {
      await _pump(
        tester,
        _app(topBar: const SizedBox(height: TopBar.height, width: 1)),
      );
      expect(tester.getRect(find.byType(Sidebar)).top, 0);
      expect(tester.getRect(find.text('Pages')).top, lessThan(TopBar.height));
    });

    testWidgets('right to left, the sidebar runs down the right edge', (
      tester,
    ) async {
      await _pump(tester, _app(direction: TextDirection.rtl));
      final sidebar = tester.getRect(find.byType(Sidebar));
      expect((sidebar.right, sidebar.top), (1280, 0));
      expect(tester.getRect(find.byType(TopBar)).right, sidebar.left);
      expect(tester.getRect(find.byKey(_logo)).right, 1280 - Shell.inset);
    });

    testWidgets('the page keeps its state as a theme moves the bar', (
      tester,
    ) async {
      const page = Center(
        child: SizedBox(width: 200, child: TextField(key: _page)),
      );
      await _pump(tester, _app(span: TopBarSpan.window, page: page));
      await tester.enterText(find.byKey(_page), 'draft');
      await tester.pumpWidget(_app(page: page));
      await tester.pumpAndSettle();
      expect(find.text('draft'), findsOneWidget);
      expect(_inSidebar(find.byKey(_logo)), findsOneWidget);
    });
  });
}
