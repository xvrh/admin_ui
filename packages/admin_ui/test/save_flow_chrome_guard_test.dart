import 'package:admin_ui/src/forms/form_controller.dart';
import 'package:admin_ui/src/forms/unsaved_changes_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends FormController {
  FormStatus _status = FormStatus.clean;
  var resets = 0;

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
  void reset() => resets++;
}

void main() {
  late _Form form;
  Object? popped;

  /// Pushes a guarded editor page over a home page and returns its navigator.
  Future<NavigatorState> pumpEditor(WidgetTester tester) async {
    form = _Form();
    addTearDown(form.dispose);
    popped = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(
                  builder: (_) => UnsavedChangesGuard(
                    controller: form,
                    child: const Scaffold(body: Text('editor')),
                  ),
                ),
              );
            },
            child: const Text('home'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    return tester.state<NavigatorState>(find.byType(Navigator));
  }

  testWidgets('confirming Discard leaves the page, once', (tester) async {
    final navigator = await pumpEditor(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await navigator.maybePop('back');
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('editor'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing, reason: 'no re-prompt');
    expect(find.text('home'), findsOneWidget);
    expect(popped, 'back', reason: 'the pop result is passed through');
  });

  testWidgets('cancelling keeps the page and its edits', (tester) async {
    final navigator = await pumpEditor(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await navigator.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('editor'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
    expect(form.status, FormStatus.dirty);
    expect(form.resets, 0);

    // And it still guards the next back.
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('a save in flight blocks the pop with its own prompt', (
    tester,
  ) async {
    final navigator = await pumpEditor(tester);
    form.status = FormStatus.submitting;
    await tester.pump();
    expect(form.hasUnsavedChanges, isFalse);
    expect(form.blocksNavigation, isTrue);

    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsOneWidget);
    expect(find.text('Saving in progress — leave anyway?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsOneWidget);

    await navigator.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
  });

  testWidgets('a saved form pops without a prompt', (tester) async {
    final navigator = await pumpEditor(tester);
    form.status = FormStatus.submitted;
    await tester.pump();

    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
  });

  testWidgets('disabled, it never prompts', (tester) async {
    final form = _Form()..status = FormStatus.dirty;
    addTearDown(form.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => UnsavedChangesGuard(
                  controller: form,
                  enabled: false,
                  child: const Scaffold(body: Text('editor')),
                ),
              ),
            ),
            child: const Text('home'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
  });
}
