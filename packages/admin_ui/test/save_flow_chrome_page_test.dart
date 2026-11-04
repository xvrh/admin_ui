import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps [child] in a window [width] × [height].
Future<void> _pumpWindow(
  WidgetTester tester,
  Widget child, {
  required double width,
  double height = 640,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: buildAppTheme(defaultTokens), home: child),
  );
}

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

Rect _button(WidgetTester tester, String label) => _rect(
  tester,
  find.ancestor(of: find.text(label), matching: find.byType(Button)).first,
);

Widget _page({double? maxWidth = 860, double? headerMaxWidth}) => Scaffold(
  body: PageScaffold(
    title: 'Aurora Lamp',
    breadcrumb: const Breadcrumbs([Crumb('Products'), Crumb('Aurora Lamp')]),
    maxWidth: maxWidth,
    headerMaxWidth: headerMaxWidth,
    actions: [
      Button.ghost('Discard', onPressed: () {}),
      Button.primary('Save', onPressed: () {}),
    ],
    body: const SizedBox(
      key: ValueKey('body'),
      width: double.infinity,
      height: 400,
    ),
  ),
);

Widget _shell({String selected = 'Pages', ValueChanged<String>? onNav}) =>
    Shell(
      sidebar: Sidebar(
        entries: [
          const NavSection('Content'),
          for (final (label, icon) in [
            ('Pages', Icons.description_outlined),
            ('Media', Icons.photo_library_outlined),
            ('Settings', Icons.settings_outlined),
          ])
            NavItem(
              label,
              icon: icon,
              badge: label == 'Pages' ? '3' : null,
              selected: label == selected,
              onTap: () => onNav?.call(label),
            ),
        ],
      ),
      topBar: TopBar(
        leading: const Text('Acme Admin'),
        search: CommandTrigger(onTap: () {}),
        onSearch: () {},
        actions: [
          Button.primary('New', icon: Icons.add_rounded, onPressed: () {}),
        ],
      ),
      child: PageScaffold(
        title: 'Pages',
        subtitle: 'Manage your Pages',
        scrollable: false,
        actions: [
          Button('Preview', icon: Icons.visibility_outlined, onPressed: () {}),
          Button.primary('Publish', icon: Icons.send_rounded, onPressed: () {}),
        ],
        body: const SizedBox.expand(),
      ),
    );

void main() {
  group('PageScaffold lines its header up with the body', () {
    for (final width in [1100.0, 1600.0]) {
      testWidgets('at $width', (tester) async {
        await _pumpWindow(tester, _page(), width: width);
        expect(tester.takeException(), isNull);
        final body = _rect(tester, find.byKey(const ValueKey('body')));
        expect(body.width, 860);
        expect(body.left, (width - 860) / 2);

        final title = _rect(tester, find.text('Aurora Lamp').last);
        final crumb = _rect(tester, find.text('Products'));
        expect(title.left, body.left);
        expect(crumb.left, body.left);
        expect(_button(tester, 'Save').right, body.right);
      });
    }

    testWidgets('narrower than the column, both keep the gutter', (
      tester,
    ) async {
      await _pumpWindow(tester, _page(), width: 700);
      final body = _rect(tester, find.byKey(const ValueKey('body')));
      expect(body.left, 24);
      expect(body.right, 700 - 24);
      expect(_rect(tester, find.text('Aurora Lamp').last).left, 24);
      expect(_button(tester, 'Save').right, 700 - 24);
    });

    testWidgets('a full-bleed header opts out', (tester) async {
      await _pumpWindow(
        tester,
        _page(headerMaxWidth: double.infinity),
        width: 1100,
      );
      expect(_rect(tester, find.text('Aurora Lamp').last).left, 24);
      expect(_button(tester, 'Save').right, 1100 - 24);
      expect(_rect(tester, find.byKey(const ValueKey('body'))).left, 120);
    });

    testWidgets('without a maxWidth, both span the page', (tester) async {
      await _pumpWindow(tester, _page(maxWidth: null), width: 1100);
      final body = _rect(tester, find.byKey(const ValueKey('body')));
      expect(body.left, 24);
      expect(_rect(tester, find.text('Aurora Lamp').last).left, 24);
      expect(_button(tester, 'Save').right, body.right);
    });
  });

  group('PageHeader title', () {
    testWidgets('is the page heading', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpWindow(tester, _page(), width: 1100);
      final node = tester.getSemantics(find.text('Aurora Lamp').last);
      expect(node.getSemanticsData().flagsCollection.isHeader, isTrue);
      expect(node.label, 'Aurora Lamp');
      semantics.dispose();
    });

    testWidgets('runs to two lines at most, with or without a trailing '
        'widget', (tester) async {
      for (final trailing in [null, const Tag('Draft')]) {
        await _pumpWindow(
          tester,
          Scaffold(
            body: PageHeader(
              'A remarkably long page title that would otherwise run on '
              'and on across several lines of a narrow header',
              titleTrailing: trailing,
            ),
          ),
          width: 360,
        );
        final title = tester.widget<Text>(
          find.textContaining('A remarkably long page title'),
        );
        expect(title.maxLines, 2);
        expect(title.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('sits 4 above its subtitle', (tester) async {
      await _pumpWindow(
        tester,
        const Scaffold(body: PageHeader('Pages', subtitle: 'Manage')),
        width: 900,
      );
      final title = _rect(tester, find.text('Pages'));
      final subtitle = _rect(tester, find.text('Manage'));
      expect(subtitle.top - title.bottom, 4);
    });
  });

  group('Shell insets', () {
    testWidgets('the top bar ends on the page gutter and starts over the '
        'sidebar icons', (tester) async {
      await _pumpWindow(tester, _shell(), width: 900);
      expect(tester.takeException(), isNull);
      expect(_button(tester, 'New').right, _button(tester, 'Publish').right);
      expect(_button(tester, 'New').right, 900 - 24);
      final brand = _rect(tester, find.text('Acme Admin'));
      final icon = _rect(tester, find.byIcon(Icons.description_outlined));
      expect(brand.left, Shell.inset);
      expect(icon.left, Shell.inset);
      expect(_rect(tester, find.text('CONTENT')).left, Shell.inset);
    });

    testWidgets('a narrow window narrows both gutters to 16', (tester) async {
      await _pumpWindow(tester, _shell(), width: 560);
      expect(tester.takeException(), isNull);
      expect(_button(tester, 'New').right, 560 - 16);
    });

    testWidgets('the search trigger is the control height', (tester) async {
      await _pumpWindow(tester, _shell(), width: 1024);
      expect(
        _rect(tester, find.byType(CommandTrigger)).height,
        defaultTokens.sizes.medium,
      );
      expect(_button(tester, 'New').height, defaultTokens.sizes.medium);
    });

    testWidgets('a SaveBar under a page header lines up with it', (
      tester,
    ) async {
      await _pumpWindow(
        tester,
        Scaffold(
          body: Column(
            children: [
              PageHeader(
                'Aurora Lamp',
                actions: [Button('Preview', onPressed: () {})],
              ),
              SaveBar(
                state: SaveState.unsaved,
                leading: const Text('Edit'),
                onSave: () {},
              ),
            ],
          ),
        ),
        width: 1000,
      );
      expect(
        _rect(tester, find.text('Edit')).left,
        _rect(tester, find.text('Aurora Lamp')).left,
      );
      expect(_button(tester, 'Save').right, _button(tester, 'Preview').right);
    });
  });

  group('Shell overflow sweep', () {
    // A phone-wide window leaves no room for the expanded rail beside a page;
    // a screen collapses it there.
    for (final (width, collapsed) in [
      (360.0, true),
      (600.0, false),
      (600.0, true),
      (1024.0, false),
      (1024.0, true),
    ]) {
      testWidgets('at $width${collapsed ? ', rail collapsed' : ''}', (
        tester,
      ) async {
        await _pumpWindow(
          tester,
          Shell(
            sidebar: Sidebar(
              collapsed: collapsed,
              entries: [
                NavItem(
                  'Pages',
                  icon: Icons.description_outlined,
                  badge: '12',
                  selected: true,
                  onTap: () {},
                ),
                NavItem(
                  'A navigation item with a long label',
                  icon: Icons.photo_library_outlined,
                  onTap: () {},
                ),
              ],
            ),
            topBar: TopBar(
              leading: const Text('Acme Admin'),
              title: 'A long top bar title for the frame',
              search: CommandTrigger(onTap: () {}),
              onSearch: () {},
              actions: [
                Button.primary(
                  'New',
                  icon: Icons.add_rounded,
                  onPressed: () {},
                ),
              ],
            ),
            child: PageScaffold(
              title: 'A long page title that has to fit somewhere',
              subtitle: 'And a subtitle under it',
              breadcrumb: const Breadcrumbs([
                Crumb('Products'),
                Crumb('Aurora Lamp'),
              ]),
              maxWidth: 860,
              actions: [
                Button('Preview', onPressed: () {}),
                Button.primary('Publish', onPressed: () {}),
              ],
              body: const SizedBox(height: 200),
              bottomBar: SaveBar(
                state: SaveState.unsaved,
                placement: SaveBarPlacement.bottom,
                leading: const Text('Edit page'),
                onDiscard: () {},
                onCommit: () {},
                commitLabel: 'Save',
              ),
            ),
          ),
          width: width,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final topBarTitle = find.text('A long top bar title for the frame');
        if (topBarTitle.evaluate().isNotEmpty) {
          final text = tester.widget<Text>(topBarTitle);
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
        }
      });
    }
  });

  testWidgets('Tab reaches the sidebar items and Enter opens one', (
    tester,
  ) async {
    final opened = <String>[];
    await _pumpWindow(tester, _shell(onNav: opened.add), width: 1024);

    /// Tabs until focus is on the item showing [label]; whether it got there.
    Future<bool> tabTo(String label) async {
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused == null) continue;
        final holds = find.descendant(
          of: find.byElementPredicate((e) => identical(e, focused)),
          matching: find.text(label),
        );
        if (holds.evaluate().isNotEmpty) return true;
      }
      return false;
    }

    expect(await tabTo('Media'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['Media']);

    expect(await tabTo('Settings'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(opened, ['Media', 'Settings']);
  });
}
