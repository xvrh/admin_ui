// savedLabel on the four save controls: a detail after the status's own
// word, not the word. errorLabel, beside it, is the whole of its message.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Form extends FormController {
  _Form(this._status);

  final FormStatus _status;

  @override
  FormStatus get status => _status;

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}

typedef _Build = Widget Function({
  required bool saved,
  required SaveFlow flow,
  String? savedLabel,
  String? errorLabel,
});

FormController _form(bool saved) {
  final form = _Form(saved ? FormStatus.submitted : FormStatus.error);
  addTearDown(form.dispose);
  return form;
}

final _controls = <(String, _Build)>[
  (
    'SaveBar',
    ({required saved, required flow, savedLabel, errorLabel}) => SaveBar(
      state: saved ? SaveState.saved : SaveState.error,
      flow: flow,
      savedLabel: savedLabel,
      errorLabel: errorLabel,
      onCommit: () {},
    ),
  ),
  (
    'SaveCluster',
    ({required saved, required flow, savedLabel, errorLabel}) => SaveCluster(
      state: saved ? SaveState.saved : SaveState.error,
      flow: flow,
      savedLabel: savedLabel,
      errorLabel: errorLabel,
      onCommit: () {},
    ),
  ),
  (
    'FormSaveBar',
    ({required saved, required flow, savedLabel, errorLabel}) => FormSaveBar(
      controller: _form(saved),
      flow: flow,
      savedLabel: savedLabel,
      errorLabel: errorLabel,
    ),
  ),
  (
    'FormActions',
    ({required saved, required flow, savedLabel, errorLabel}) => FormActions(
      controller: _form(saved),
      flow: flow,
      savedLabel: savedLabel,
      errorLabel: errorLabel,
    ),
  ),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Align(alignment: Alignment.topCenter, child: child),
      ),
    ),
  );
}

void main() {
  for (final (name, build) in _controls) {
    group(name, () {
      for (final (flow, word) in [
        (SaveFlow.save, 'Saved'),
        (SaveFlow.publish, 'Published'),
      ]) {
        testWidgets('${flow.name}: with no savedLabel the status is its own '
            'word', (tester) async {
          await _pump(tester, build(saved: true, flow: flow));
          expect(find.text(word), findsOneWidget);
        });

        testWidgets('${flow.name}: savedLabel comes after the word', (
          tester,
        ) async {
          await _pump(
            tester,
            build(saved: true, flow: flow, savedLabel: '2m ago'),
          );
          expect(find.text('$word · 2m ago'), findsOneWidget);
          expect(find.text(word), findsNothing);
          expect(find.text('2m ago'), findsNothing);
        });
      }

      testWidgets('the word passed as savedLabel is said twice', (
        tester,
      ) async {
        await _pump(
          tester,
          build(saved: true, flow: SaveFlow.save, savedLabel: 'Saved'),
        );
        expect(find.text('Saved · Saved'), findsOneWidget);
      });

      testWidgets('errorLabel is the whole message', (tester) async {
        await _pump(
          tester,
          build(saved: false, flow: SaveFlow.save, errorLabel: 'Offline'),
        );
        expect(find.text('Offline'), findsOneWidget);
        expect(find.textContaining('Couldn’t save'), findsNothing);
      });
    });
  }
}
