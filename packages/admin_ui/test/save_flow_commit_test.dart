// SaveFlow and the commit slot of the save controls: what SaveFlow.publish
// says, and the commit* parameters that drive the commit.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends FormController {
  _Form(this._status);

  FormStatus _status;
  var submits = 0;

  @override
  FormStatus get status => _status;
  set status(FormStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async => submits++;

  @override
  void reset() {}
}

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(alignment: Alignment.topCenter, child: child),
  ),
);

void _noop() {}

const _schedule = [SaveBarAction(label: 'Schedule…', onPressed: _noop)];

void main() {
  group('SaveFlow.publish', () {
    testWidgets('the words themselves', (tester) async {
      for (final (state, status) in [
        (SaveState.unsaved, 'Edited'),
        (SaveState.saving, 'Publishing…'),
        (SaveState.saved, 'Published'),
        (SaveState.error, 'Couldn’t publish'),
      ]) {
        await tester.pumpWidget(
          _host(SaveBar(state: state, onCommit: _noop, flow: SaveFlow.publish)),
        );
        expect(find.text(status), findsOneWidget);
        expect(find.text('Publish'), findsOneWidget);
      }
      final form = _Form(FormStatus.clean);
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _host(FormSaveBar(controller: form, flow: SaveFlow.publish)),
      );
      expect(find.text('Publish'), findsOneWidget);
      expect(
        tester.widget<Tip>(find.byType(Tip)).message,
        'No changes to publish',
      );
    });
  });

  testWidgets('the commit* parameters drive the commit', (tester) async {
    var commits = 0;
    Widget bar({bool committing = false, bool enabled = true}) => _host(
      SaveBar(
        state: SaveState.unsaved,
        onCommit: () => commits++,
        commitLabel: 'Go live',
        commitMenuLabel: 'More go-live options',
        committing: committing,
        commitEnabled: enabled,
        commitMenu: _schedule,
        commitDisabledHint: 'Nothing to publish',
      ),
    );
    await tester.pumpWidget(bar());
    final split = tester.widget<SplitButton>(find.byType(SplitButton));
    expect(split.label, 'Go live');
    expect(split.menuSemanticLabel, 'More go-live options');
    expect(split.loading, isFalse);
    await tester.tap(find.text('Go live'));
    expect(commits, 1);

    await tester.pumpWidget(bar(committing: true));
    expect(tester.widget<SplitButton>(find.byType(SplitButton)).loading, true);

    await tester.pumpWidget(bar(enabled: false));
    final disabled = tester.widget<SplitButton>(find.byType(SplitButton));
    expect(disabled.onPressed, isNull);
    expect(disabled.disabledHint, 'Nothing to publish');
  });

  testWidgets('the form controls take commitLabel, commitMenu and '
      'commitDisabledHint', (tester) async {
    final form = _Form(FormStatus.clean);
    addTearDown(form.dispose);
    await tester.pumpWidget(
      _host(
        FormActions(
          controller: form,
          commitLabel: 'Go live',
          commitMenu: _schedule,
          commitDisabledHint: 'Nothing new',
          saveShortcut: false,
        ),
      ),
    );
    final split = tester.widget<SplitButton>(find.byType(SplitButton));
    expect(split.label, 'Go live');
    expect(split.disabledHint, 'Nothing new');
  });
}
