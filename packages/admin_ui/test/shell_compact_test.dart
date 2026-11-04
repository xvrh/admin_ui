import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fr = Locale('fr');
const _page = ValueKey('page');
const _ar = Locale('ar');

/// A frame: a top bar leading with a logo over a sidebar of two pages, in
/// [tokens] and [locale], its sidebar [collapsed] into the rail.
Widget _app({
  AdminTokens? tokens,
  Locale? locale,
  bool collapsed = false,
  Widget? drawer,
  Widget? drawerLeading,
  Widget topBarLeading = const Text('Acme'),
  List<String>? opened,
}) => MaterialApp(
  theme: buildAppTheme(tokens ?? defaultTokens),
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: AdminScope(
    child: Shell(
      topBar: TopBar(leading: topBarLeading),
      sidebar: Sidebar(
        collapsed: collapsed,
        entries: [
          NavItem(
            'Pages',
            icon: Icons.description_outlined,
            selected: true,
            onTap: () => opened?.add('Pages'),
          ),
          NavItem(
            'Media',
            icon: Icons.photo_library_outlined,
            onTap: () => opened?.add('Media'),
          ),
        ],
      ),
      drawer: drawer,
      drawerLeading: drawerLeading,
      child: const SizedBox.expand(key: _page),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget app, {
  Size size = const Size(360, 700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Finder get _menu => find.byType(ShellMenuButton);

/// The drawer's close button.
Finder get _close => find.widgetWithIcon(IconAction, Icons.close_rounded);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_menu);
  await tester.pumpAndSettle();
}

void main() {
  group('below the medium breakpoint', () {
    testWidgets('the page takes the width and the top bar leads with the '
        'menu button', (tester) async {
      await _pump(tester, _app(), size: const Size(599, 700));
      expect(find.byType(Sidebar), findsNothing);
      expect(_menu, findsOneWidget);
      expect(
        tester.getRect(find.byKey(_page)),
        const Rect.fromLTRB(0, TopBar.height, 599, 700),
      );
      // The menu glyph, not its box, sits at the shell's inset, and the
      // logo after it.
      final glyph = tester.getRect(
        find.descendant(of: _menu, matching: find.byIcon(Icons.menu_rounded)),
      );
      expect(glyph.left, Shell.inset);
      expect(
        tester.getRect(find.text('Acme')).left,
        tester.getRect(_menu).right + TopBar.menuButtonGap,
      );
    });

    testWidgets('at the breakpoint the sidebar is back and the menu gone', (
      tester,
    ) async {
      await _pump(tester, _app(), size: const Size(600, 700));
      expect(find.byType(Sidebar), findsOneWidget);
      expect(_menu, findsNothing);
      expect(
        tester.getRect(find.text('Acme')).left,
        Shell.inset,
        reason: 'the logo over the sidebar',
      );
    });

    testWidgets('the shell measures its own width, not the window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 500,
              child: AdminScope(
                child: Shell(
                  topBar: const TopBar(leading: Text('Acme')),
                  sidebar: Sidebar(
                    entries: [
                      NavItem('Pages', icon: Icons.description, onTap: () {}),
                    ],
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Sidebar), findsNothing);
      expect(_menu, findsOneWidget);
    });

    testWidgets('a theme\'s breakpoints move the fold', (tester) async {
      final tokens = defaultTokens.copyWith(
        breakpoints: const AdminBreakpoints(medium: 800),
      );
      await _pump(tester, _app(tokens: tokens), size: const Size(700, 700));
      expect(find.byType(Sidebar), findsNothing);
      await _pump(tester, _app(tokens: tokens), size: const Size(800, 700));
      expect(find.byType(Sidebar), findsOneWidget);
    });

    testWidgets('Shell.isCompact follows the fold, and is true in the '
        'drawer', (tester) async {
      await _pump(tester, _app(), size: const Size(1000, 700));
      bool compactAt(Finder finder) =>
          Shell.isCompact(tester.element(finder.first));
      expect(compactAt(find.text('Acme')), isFalse);
      await _pump(tester, _app(), size: const Size(360, 700));
      expect(compactAt(find.text('Acme')), isTrue);
      await _open(tester);
      expect(compactAt(find.text('Media')), isTrue);
      expect(Shell.isCompact(tester.element(find.byType(MaterialApp))), false);
    });
  });

  group('the menu button', () {
    for (final (locale, open, close) in [
      (null, 'Open navigation', 'Close navigation'),
      (_fr, 'Ouvrir la navigation', 'Fermer la navigation'),
      (_ar, 'فتح التنقل', 'إغلاق التنقل'),
    ]) {
      testWidgets('is named in ${locale ?? 'en'}, and so is the drawer\'s '
          'close', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(tester, _app(locale: locale));
        expect(find.bySemanticsLabel(open), findsOneWidget);
        await _open(tester);
        expect(find.bySemanticsLabel(close), findsOneWidget);
        semantics.dispose();
      });
    }

    testWidgets('an app\'s own, keyed, takes its place', (tester) async {
      const key = ValueKey('menu');
      await _pump(
        tester,
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: const AdminScope(
            child: Shell(
              topBar: TopBar(menuButton: ShellMenuButton(key: key)),
              sidebar: Sidebar(
                entries: [NavItem('Pages', icon: Icons.description)],
              ),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );
      expect(_menu, findsOneWidget);
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('Pages'), findsOneWidget);
    });
  });

  group('the drawer', () {
    testWidgets('holds the sidebar expanded, as wide as the drawer, under a '
        'head as tall as the top bar', (tester) async {
      await _pump(tester, _app(collapsed: true));
      await _open(tester);
      final sidebar = tester.getRect(find.byType(Sidebar));
      expect(sidebar.left, 0);
      expect(sidebar.width, Shell.drawerWidth);
      expect(sidebar.height, 700);
      expect(find.text('Pages'), findsOneWidget, reason: 'labels show');
      // The close glyph is where the menu glyph was, and the logo where
      // the bar has it.
      expect(
        tester
            .getRect(find.descendant(of: _close, matching: find.byType(Icon)))
            .left,
        Shell.inset,
      );
      final logos = find.text('Acme');
      expect(logos, findsNWidgets(2));
      expect(
        tester.getCenter(logos.last),
        tester.getCenter(logos.first),
        reason: 'the drawer\'s logo over the bar\'s',
      );
      final head = defaultTokens.shell.topBarHeight;
      expect(
        tester.getRect(find.text('Pages')).top,
        greaterThan(head),
        reason: 'the items start under the head',
      );
    });

    testWidgets('narrows to a narrow window', (tester) async {
      await _pump(tester, _app(), size: const Size(300, 600));
      await _open(tester);
      expect(tester.getSize(find.byType(Sidebar)).width, 300);
    });

    testWidgets('closes on its close button, Escape, the scrim and back', (
      tester,
    ) async {
      await _pump(tester, _app());
      Future<void> expectCloses(Future<void> Function() close) async {
        await _open(tester);
        expect(find.byType(Sidebar), findsOneWidget);
        await close();
        await tester.pumpAndSettle();
        expect(find.byType(Sidebar), findsNothing);
      }

      await expectCloses(() => tester.tap(_close));
      await expectCloses(() => tester.sendKeyEvent(LogicalKeyboardKey.escape));
      await expectCloses(() => tester.tapAt(const Offset(350, 350)));
      await expectCloses(() => tester.binding.handlePopRoute());
    });

    testWidgets('an item closes it and then opens its page', (tester) async {
      final opened = <String>[];
      await _pump(tester, _app(opened: opened));
      await _open(tester);
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();
      expect(opened, ['Media']);
      expect(find.byType(Sidebar), findsNothing);
    });

    testWidgets('holds the app\'s own drawer when given one', (tester) async {
      await _pump(
        tester,
        _app(
          drawer: Sidebar(
            entries: [NavItem('Drawer only', icon: Icons.star, onTap: () {})],
          ),
        ),
      );
      await _open(tester);
      expect(find.text('Drawer only'), findsOneWidget);
      expect(find.text('Media'), findsNothing);
    });

    testWidgets('heads with the app\'s own leading when given one, so a '
        'keyed logo is not built twice', (tester) async {
      final logo = GlobalKey();
      await _pump(
        tester,
        _app(
          topBarLeading: Text('Acme', key: logo),
          drawerLeading: const Text('Acme drawer'),
        ),
      );
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Acme drawer'), findsOneWidget);
      expect(find.byKey(logo), findsOneWidget);
    });

    testWidgets('closes as the window widens past the breakpoint', (
      tester,
    ) async {
      await _pump(tester, _app());
      await _open(tester);
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();
      expect(find.byType(Sidebar), findsOneWidget, reason: 'the rail alone');
      expect(_close, findsNothing);
    });

    testWidgets('slides in from the right in a right-to-left layout', (
      tester,
    ) async {
      await _pump(tester, _app(locale: _ar));
      await _open(tester);
      final sidebar = tester.getRect(find.byType(Sidebar));
      expect(sidebar.right, 360);
      expect(sidebar.width, Shell.drawerWidth);
      // Mid-slide it is on its way in from that edge.
      await tester.tap(_close);
      await tester.pumpAndSettle();
      await tester.tap(_menu);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getRect(find.byType(Sidebar)).left, greaterThan(40));
    });

    testWidgets('is a dialog named as a navigation menu, focus trapped '
        'inside', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _app());
      await _open(tester);
      expect(
        find.bySemanticsLabel(
          MaterialLocalizations.of(tester.element(find.byType(Sidebar)))
              .drawerLabel,
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find
            .ancestor(of: find.byWidget(focused.widget), matching: _close)
            .evaluate()
            .isNotEmpty,
        isTrue,
        reason: 'Tab lands on the close button first',
      );
      semantics.dispose();
    });

    testWidgets('Shell.openDrawer does nothing while the shell is wide', (
      tester,
    ) async {
      await _pump(tester, _app(), size: const Size(1000, 700));
      await Shell.openDrawer(tester.element(find.text('Acme')));
      await tester.pumpAndSettle();
      expect(_close, findsNothing);
    });
  });
}
