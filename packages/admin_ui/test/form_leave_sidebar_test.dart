import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends FormController {
  FormStatus _status = FormStatus.clean;

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

  /// A shell whose sidebar opens pages, over a guarded editor page.
  Future<void> pumpShell(WidgetTester tester) async {
    form = _Form();
    addTearDown(form.dispose);
    opened = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: AdminScope(
          child: Shell(
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
              ],
            ),
            child: UnsavedChangesGuard(
              controller: form,
              child: const Center(child: Text('editor')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The focus node of the sidebar item [label].
  FocusNode nodeOf(WidgetTester tester, String label) => Focus.of(
    tester.element(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == label,
        ),
        matching: find.byType(Icon),
      ),
    ),
  );

  testWidgets('a clean page opens the item at once', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(opened, ['Settings']);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('with unsaved edits, an item asks first: cancel keeps the '
      'page', (tester) async {
    await pumpShell(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(opened, isEmpty);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(opened, isEmpty, reason: 'onTap is not called on a cancel');
    expect(find.text('editor'), findsOneWidget);
  });

  testWidgets('confirming the prompt opens the item', (tester) async {
    await pumpShell(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(opened, ['Settings']);
  });

  testWidgets('a save in flight asks in its own words', (tester) async {
    await pumpShell(tester);
    form.status = FormStatus.submitting;
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Saving in progress — leave anyway?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(opened, ['Settings']);
  });

  testWidgets('an unguarded item opens without asking', (tester) async {
    await pumpShell(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await tester.tap(find.text('Filters'));
    await tester.pump();
    expect(opened, ['Filters']);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('a second tap while the prompt is open adds no prompt', (
    tester,
  ) async {
    await pumpShell(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    // The prompt's scrim takes the pointer; a key or a router can still ask.
    final registry = LeaveGuardScope.maybeOf(
      tester.element(find.text('editor')),
    );
    final again = registry!.confirmLeave(tester.element(find.text('editor')));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await again, isTrue);
    expect(opened, ['Settings']);
  });

  testWidgets('Enter asks the same, and a cancel keeps focus on the item', (
    tester,
  ) async {
    await pumpShell(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    final settings = nodeOf(tester, 'Settings');
    settings.requestFocus();
    await tester.pump();
    expect(settings.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(settings.hasPrimaryFocus, isFalse, reason: 'the prompt has focus');

    // Cancel holds the prompt's initial focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(opened, isEmpty);
    expect(settings.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(opened, ['Settings']);
  });

  testWidgets('Enter on a clean page opens the item at once', (tester) async {
    await pumpShell(tester);
    final settings = nodeOf(tester, 'Settings');
    settings.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['Settings']);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('without a leave-guard scope, items open as before', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: Scaffold(
          body: Row(
            children: [
              Sidebar(
                entries: [
                  NavItem('Pages', icon: Icons.home, onTap: () => tapped++),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pages'));
    await tester.pump();
    expect(tapped, 1);
  });
}
