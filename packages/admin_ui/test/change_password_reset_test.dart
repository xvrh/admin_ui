// A change-password form is emptied by its host once the password is
// changed: neither password stays on screen, and nothing a submit showed
// stays under the fields.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _wrong = 'That is not your current password';
const _weak = 'Too easy to guess';

Finder _field(int index) => find.byType(PasswordField).at(index);

String _text(WidgetTester tester, int index) => tester
    .widget<EditableText>(
      find.descendant(of: _field(index), matching: find.byType(EditableText)),
    )
    .controller
    .text;

List<String> _texts(WidgetTester tester) => [
  for (var i = 0; i < 3; i++) _text(tester, i),
];

Future<void> _fill(WidgetTester tester, [String next = 'newpass11']) async {
  await tester.enterText(_field(0), 'oldpass00');
  await tester.enterText(_field(1), next);
  await tester.enterText(_field(2), next);
  await tester.pump();
}

Future<
  ({GlobalKey<ChangePasswordFormState> form, List<(String, String)> submitted})
>
_pump(WidgetTester tester, {String? current, String? next}) async {
  final form = GlobalKey<ChangePasswordFormState>();
  final submitted = <(String, String)>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: ChangePasswordForm(
              key: form,
              onSubmit: (c, n) => submitted.add((c, n)),
              currentErrorText: current,
              newErrorText: next,
            ),
          ),
        ),
      ),
    ),
  );
  return (form: form, submitted: submitted);
}

void main() {
  testWidgets('reset empties the three fields', (tester) async {
    final (:form, submitted: _) = await _pump(tester);
    await _fill(tester);
    expect(_texts(tester), ['oldpass00', 'newpass11', 'newpass11']);
    expect(find.byType(PasswordStrengthMeter), findsOneWidget);

    form.currentState!.reset();
    await tester.pump();
    expect(_texts(tester), ['', '', '']);
    expect(find.byType(PasswordStrengthMeter), findsNothing);
  });

  testWidgets('it forgets a submit attempt: no field says what it lacks', (
    tester,
  ) async {
    final (:form, :submitted) = await _pump(tester);
    await tester.enterText(_field(1), 'short');
    await tester.enterText(_field(2), 'other');
    await tester.tap(find.text('Change password'));
    await tester.pump();
    expect(find.text('Current password is required'), findsOneWidget);
    expect(find.textContaining('at least 8'), findsOneWidget);
    expect(find.text("Passwords don't match."), findsOneWidget);

    form.currentState!.reset();
    await tester.pump();
    expect(find.text('Current password is required'), findsNothing);
    expect(find.textContaining('at least 8'), findsNothing);
    expect(find.text("Passwords don't match."), findsNothing);
    expect(submitted, isEmpty);
  });

  testWidgets('it forgets a refusal the host still gives', (tester) async {
    final (:form, submitted: _) = await _pump(
      tester,
      current: _wrong,
      next: _weak,
    );
    expect(find.text(_wrong), findsOneWidget);
    expect(find.text(_weak), findsOneWidget);

    form.currentState!.reset();
    await tester.pump();
    expect(find.text(_wrong), findsNothing);
    expect(find.text(_weak), findsNothing);
  });

  testWidgets('an emptied form does not submit what it held', (tester) async {
    final (:form, :submitted) = await _pump(tester);
    await _fill(tester);
    form.currentState!.reset();
    await tester.pump();

    await tester.tap(find.text('Change password'));
    await tester.pump();
    expect(submitted, isEmpty);
    expect(find.text('Current password is required'), findsOneWidget);
  });

  testWidgets('and is filled and submitted again', (tester) async {
    final (:form, :submitted) = await _pump(tester);
    await _fill(tester);
    await tester.tap(find.text('Change password'));
    form.currentState!.reset();
    await tester.pump();

    await _fill(tester, 'newpass22');
    await tester.tap(find.text('Change password'));
    expect(submitted, [('oldpass00', 'newpass11'), ('oldpass00', 'newpass22')]);
  });

  testWidgets('after it the rules wait for the user again', (tester) async {
    final (:form, submitted: _) = await _pump(tester);
    await _fill(tester);
    // Each field left with something in it, which lets its rule show.
    await tester.tap(_field(0));
    await tester.pump();
    form.currentState!.reset();
    await tester.pump();

    await tester.enterText(_field(1), 'short');
    await tester.pump();
    expect(find.textContaining('at least 8'), findsNothing);
    expect(find.text("Passwords don't match."), findsNothing);
  });

  testWidgets('focus stays where it was', (tester) async {
    final (:form, submitted: _) = await _pump(tester);
    await _fill(tester);
    await tester.tap(_field(1));
    await tester.pump();
    form.currentState!.reset();
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: _field(1), matching: find.byType(EditableText)),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('NewPasswordFields.reset empties both fields, reports none, '
      'and forgets what showed', (tester) async {
    final fields = GlobalKey<NewPasswordFieldsState>();
    final reported = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: Scaffold(
          body: NewPasswordFields(
            key: fields,
            onChanged: reported.add,
            errorText: _weak,
          ),
        ),
      ),
    );
    expect(find.text(_weak), findsOneWidget);
    await tester.enterText(_field(0), 'short');
    await tester.enterText(_field(1), 'other');
    fields.currentState!.validate();
    await tester.pump();
    expect(find.textContaining('at least 8'), findsOneWidget);
    expect(find.text("Passwords don't match."), findsOneWidget);

    await tester.enterText(_field(0), 'newpass11');
    await tester.enterText(_field(1), 'newpass11');
    expect(reported.last, 'newpass11');

    fields.currentState!.reset();
    await tester.pump();
    expect(reported.last, isNull);
    expect([_text(tester, 0), _text(tester, 1)], ['', '']);
    expect(find.textContaining('at least 8'), findsNothing);
    expect(find.text("Passwords don't match."), findsNothing);
    expect(find.text(_weak), findsNothing);
  });
}
