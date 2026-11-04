import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends FormController {
  FormStatus _status = FormStatus.dirty;

  @override
  FormStatus get status => _status;
  set status(FormStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}

void main() {
  late _Form form;
  late List<String> opened;
  late CommandRegistry commands;
  final page = GlobalKey();

  /// A phone-wide shell whose sidebar opens pages, over an editor page with
  /// unsaved edits.
  Future<void> pumpShell(WidgetTester tester) async {
    form = _Form();
    addTearDown(form.dispose);
    commands = CommandRegistry();
    addTearDown(commands.dispose);
    opened = [];
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: AdminScope(
          commands: commands,
          child: Shell(
            topBar: const TopBar(leading: Text('Acme')),
            sidebar: Sidebar(
              entries: [
                NavItem(
                  'Pages',
                  icon: Icons.description_outlined,
                  selected: true,
                  onTap: () => opened.add('Pages'),
                ),
                NavItem(
                  'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () => opened.add('Settings'),
                ),
                NavItem(
                  'Filters',
                  icon: Icons.filter_list,
                  guarded: false,
                  onTap: () => opened.add('Filters'),
                ),
                NavItem(
                  'Search',
                  icon: Icons.search,
                  guarded: false,
                  onTap: () =>
                      ModalAnchor.of(page.currentContext!)
                          .show<void>(builder: (_) => const Text('search box')),
                ),
              ],
            ),
            child: UnsavedChangesGuard(
              controller: form,
              child: Center(key: page, child: const Text('editor')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ShellMenuButton));
    await tester.pumpAndSettle();
    expect(find.byType(Sidebar), findsOneWidget);
  }

  BuildContext shell(WidgetTester tester) =>
      tester.element(find.text('Acme').first);

  final prompt = find.text('Discard changes?');

  testWidgets('the drawer sees the scopes above the shell', (tester) async {
    await pumpShell(tester);
    final inDrawer = tester.element(find.text('Settings'));
    expect(LeaveGuardScope.maybeOf(inDrawer), isNotNull);
    expect(
      LeaveGuardScope.maybeOf(inDrawer),
      same(LeaveGuardScope.maybeOf(shell(tester))),
    );
    expect(CommandScope.maybeOf(inDrawer), same(commands));
  });

  testWidgets('with unsaved edits, an item asks first: cancel keeps the '
      'drawer open over the page', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(prompt, findsOneWidget);
    expect(opened, isEmpty);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(prompt, findsNothing);
    expect(opened, isEmpty);
    expect(find.byType(Sidebar), findsOneWidget, reason: 'still open');
    expect(find.text('editor'), findsOneWidget);
  });

  testWidgets('discarding closes the drawer, then opens the page', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    // The drawer starts closing in the same turn the item opens its page.
    await tester.pump();
    expect(opened, ['Settings']);
    await tester.pumpAndSettle();
    expect(find.byType(Sidebar), findsNothing);
  });

  testWidgets('a clean page lets an item go at once, closing the drawer', (
    tester,
  ) async {
    await pumpShell(tester);
    form.status = FormStatus.clean;
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(prompt, findsNothing);
    expect(opened, ['Settings']);
    expect(find.byType(Sidebar), findsNothing);
  });

  testWidgets('an unguarded item opens at once and closes the drawer', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(prompt, findsNothing);
    expect(opened, ['Filters']);
    expect(find.byType(Sidebar), findsNothing);
  });

  testWidgets('an item can open a modal on the anchor the drawer is on', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(Sidebar), findsNothing);
    expect(find.text('search box'), findsOneWidget);
  });

  testWidgets('back closes the drawer, not the dirty page', (tester) async {
    await pumpShell(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(prompt, findsNothing, reason: 'the drawer takes the back');
    expect(find.byType(Sidebar), findsNothing);
    expect(find.text('editor'), findsOneWidget);
  });

  testWidgets('showNavigationDrawer opens the same drawer for a frame of '
      'the app\'s own', (tester) async {
    final opened = <String>[];
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: AdminScope(
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: Button(
                  'Menu',
                  onPressed: () => showNavigationDrawer(
                    context,
                    leading: const Text('Acme'),
                    sidebar: Sidebar(
                      entries: [
                        NavItem(
                          'Settings',
                          icon: Icons.settings_outlined,
                          onTap: () => opened.add('Settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Sidebar)).width, Shell.drawerWidth);
    expect(find.text('Acme'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(opened, ['Settings']);
    expect(find.byType(Sidebar), findsNothing);
  });
}
