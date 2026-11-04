import 'package:admin_ui/src/common/ui/modal_anchor.dart';
import 'package:admin_ui/src/forms/form_controller.dart';
import 'package:admin_ui/src/forms/unsaved_changes_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeForm extends FormController {
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

class _Editor extends StatelessWidget {
  final _FakeForm form;
  final ModalAnchorController modals;

  const _Editor({required this.form, required this.modals});

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      controller: form,
      child: Scaffold(
        body: ModalAnchor(
          controller: modals,
          child: Center(
            child: TextButton(
              onPressed: () =>
                  modals.show<void>(builder: (_) => const Text('sheet')),
              child: const Text('open sheet'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  late _FakeForm form;
  late ModalAnchorController modals;

  Future<NavigatorState> pumpEditorPage(WidgetTester tester) async {
    form = _FakeForm();
    modals = ModalAnchorController();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _Editor(form: form, modals: modals),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return tester.state<NavigatorState>(find.byType(Navigator));
  }

  testWidgets('dirty form blocks the pop and prompts', (tester) async {
    final navigator = await pumpEditorPage(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('open sheet'), findsOneWidget);
  });

  testWidgets('clean form pops without prompting', (tester) async {
    final navigator = await pumpEditorPage(tester);

    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('open sheet'), findsNothing);
  });

  testWidgets('guard stands down while a portal modal is open: back closes '
      'the modal, then guards again', (tester) async {
    final navigator = await pumpEditorPage(tester);
    form.status = FormStatus.dirty;
    await tester.pump();

    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);

    // First back: the modal's LocalHistoryEntry wins — no discard prompt.
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('open sheet'), findsOneWidget);

    // Second back: no modal left, the dirty form guards the page again.
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('open sheet'), findsOneWidget);
  });
}
