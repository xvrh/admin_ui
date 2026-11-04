import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type SignUp(FormScope _s) {
  ValueCell<String> get username => _s.text('username');
  ValueCell<bool> get company => _s.boolean('company');
  ValueCell<String> get vat => _s.text('vat');
  ValueCell<String> get name => _s.text('name');
}

typedef Values = ({String username, String name});

ValueFormController<Values> signUpForm({
  AsyncFieldValidator<String>? usernameCheck,
  Future<void> Function(Values)? onSubmit,
}) => ValueFormController<Values>(
  read: (s) => (username: SignUp(s).username.value, name: SignUp(s).name.value),
  write: (s, v) => SignUp(s)
    ..username.set(v.username)
    ..name.set(v.name),
  rules: (s) {
    final f = SignUp(s);
    return [
      FieldRules(
        f.username,
        validators: [Validators.required()],
        asyncValidators: [?usernameCheck],
      ),
      FieldRules(
        f.vat,
        validators: [Validators.required()],
        visibleWhen: () => f.company.value,
      ),
      FieldRules(f.name, validators: [Validators.required()]),
    ];
  },
  onSubmit: onSubmit,
);

/// Account (username, and a VAT number only a company gives), Profile
/// (name) and Review (nothing to check).
List<FormWizardStep> signUpSteps(SignUp f) => [
  FormWizardStep(
    title: 'Account',
    fields: [f.username, f.vat],
    builder: (context) => Column(
      children: [
        Field(f.username, label: 'Username'),
        Field(f.vat, label: 'VAT number'),
      ],
    ),
  ),
  FormWizardStep(
    title: 'Profile',
    fields: [f.name],
    builder: (context) => Field(f.name, label: 'Name'),
  ),
  FormWizardStep(
    title: 'Review',
    fields: const [],
    builder: (context) => const Text('All set'),
  ),
];

Future<void> pumpWizard(
  WidgetTester tester,
  ValueFormController<Values> form, {
  double width = 800,
  ValueChanged<int>? onStepChanged,
  bool reduceMotion = false,
  int initialStep = 0,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FormWizard(
              controller: form,
              steps: signUpSteps(SignUp(form.scope)),
              initialStep: initialStep,
              onStepChanged: onStepChanged,
              finishLabel: 'Create account',
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Steps steps(WidgetTester tester) => tester.widget<Steps>(find.byType(Steps));

Finder shellOf(String label, {bool skipOffstage = true}) =>
    find.byWidgetPredicate(
      (w) => w is FieldShell && w.label == label,
      skipOffstage: skipOffstage,
    );

/// The input of the field [label], on a step shown or not.
Finder inputOf(String label) => find.descendant(
  of: shellOf(label, skipOffstage: false),
  matching: find.byType(EditableText, skipOffstage: false),
  skipOffstage: false,
);

Finder buttonLabelled(String label) =>
    find.byWidgetPredicate((w) => w is Button && w.label == label);

Future<void> press(WidgetTester tester, String label) async {
  await tester.tap(buttonLabelled(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Next is refused while a required field is empty', (
    tester,
  ) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    await pumpWizard(tester, form);

    await press(tester, 'Next');
    expect(steps(tester).current, 0);
    expect(steps(tester).errorSteps, {0});
    expect(find.text('Required'), findsOneWidget);
    final username = tester.widget<EditableText>(inputOf('Username'));
    expect(username.focusNode.hasFocus, isTrue);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains('Fix 1 field to continue'),
    );
    expect(
      find.text('Required', skipOffstage: false),
      findsOneWidget,
      reason: 'the next step’s fields are not checked',
    );
  });

  testWidgets('the error mark clears as the step passes, and Next advances', (
    tester,
  ) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    final moves = <int>[];
    await pumpWizard(tester, form, onStepChanged: moves.add);
    await press(tester, 'Next');
    expect(steps(tester).errorSteps, {0});

    await tester.enterText(inputOf('Username'), 'ada');
    await tester.pump();
    expect(steps(tester).errorSteps, isEmpty);
    expect(steps(tester).current, 0, reason: 'fixing does not move on');

    await press(tester, 'Next');
    expect(steps(tester).current, 1);
    expect(moves, [1]);
    expect(find.text('Required'), findsNothing, reason: 'Profile unchecked');
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains('Step 2 of 3: Profile'),
    );
  });

  testWidgets('Back keeps the values and never validates', (tester) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    final f = SignUp(form.scope);
    await pumpWizard(tester, form);
    await tester.enterText(inputOf('Username'), 'ada');
    await press(tester, 'Next');
    expect(steps(tester).current, 1);

    await press(tester, 'Back');
    expect(steps(tester).current, 0);
    expect(steps(tester).errorSteps, isEmpty, reason: 'Profile left empty');
    expect(f.username.value, 'ada');
    expect(
      tester.widget<EditableText>(inputOf('Username')).controller.text,
      'ada',
    );
    expect(buttonLabelled('Back'), findsNothing);
  });

  testWidgets('a field its rule hides does not block the step', (tester) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    final f = SignUp(form.scope);
    await pumpWizard(tester, form);
    await tester.enterText(inputOf('Username'), 'ada');
    await press(tester, 'Next');
    expect(steps(tester).current, 1, reason: 'the VAT number is hidden');

    await press(tester, 'Back');
    f.company.set(true);
    await tester.pump();
    await press(tester, 'Next');
    expect(steps(tester).current, 0, reason: 'a company gives its VAT');
    expect(steps(tester).errorSteps, {0});
    final vat = tester.widget<EditableText>(inputOf('VAT number'));
    expect(vat.focusNode.hasFocus, isTrue);
  });

  testWidgets('Finish submits, spinning while the submit is in flight', (
    tester,
  ) async {
    final saving = Completer<void>();
    Values? saved;
    final form = signUpForm(
      onSubmit: (v) {
        saved = v;
        return saving.future;
      },
    );
    addTearDown(form.dispose);
    final f = SignUp(form.scope);
    f.username.set('ada');
    f.name.set('Ada Lovelace');
    await pumpWizard(tester, form, initialStep: 2);
    expect(buttonLabelled('Next'), findsNothing);

    await tester.tap(buttonLabelled('Create account'));
    await tester.pump();
    expect(saved, (username: 'ada', name: 'Ada Lovelace'));
    expect(form.status, FormStatus.submitting);
    expect(
      tester.widget<Button>(buttonLabelled('Create account')).loading,
      isTrue,
    );
    expect(tester.widget<Button>(buttonLabelled('Back')).onPressed, isNull);

    saving.complete();
    await tester.pumpAndSettle();
    expect(form.status, FormStatus.submitted);
    expect(
      tester.widget<Button>(buttonLabelled('Create account')).loading,
      isFalse,
    );
  });

  testWidgets('Finish reads the save label when given none', (tester) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormWizard(
              controller: form,
              initialStep: 2,
              steps: signUpSteps(SignUp(form.scope)),
            ),
          ),
        ),
      ),
    );
    expect(buttonLabelled('Save'), findsOneWidget);
    expect(
      tester.widget<Button>(buttonLabelled('Save')).onPressed,
      isNull,
      reason: 'nothing edited to submit',
    );
  });

  testWidgets('a refused submit takes the user back to the field', (
    tester,
  ) async {
    final form = signUpForm(
      onSubmit: (_) async => throw const FormSubmitException(
        fieldErrors: {'username': 'That username is taken'},
      ),
    );
    addTearDown(form.dispose);
    final f = SignUp(form.scope);
    f.username.set('ada');
    f.name.set('Ada Lovelace');
    await pumpWizard(tester, form, initialStep: 2);

    await press(tester, 'Create account');
    expect(steps(tester).current, 0);
    expect(steps(tester).errorSteps, contains(0));
    expect(find.text('That username is taken'), findsOneWidget);
    final username = tester.widget<EditableText>(inputOf('Username'));
    expect(username.focusNode.hasFocus, isTrue);
  });

  testWidgets('Next waits for a pending async check, then advances', (
    tester,
  ) async {
    final form = signUpForm(
      usernameCheck: (v) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return v == 'admin' ? 'That username is taken' : null;
      },
    );
    addTearDown(form.dispose);
    await pumpWizard(tester, form);

    await tester.enterText(inputOf('Username'), 'ada');
    await tester.pump();
    expect(form.pendingFields, {'username'});
    await tester.tap(buttonLabelled('Next'));
    await tester.pump();
    expect(steps(tester).current, 0, reason: 'the check is still running');
    expect(tester.widget<Button>(buttonLabelled('Next')).loading, isTrue);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(steps(tester).current, 1);
    expect(tester.widget<Button>(buttonLabelled('Next')).loading, isFalse);
  });

  testWidgets('an async check that fails keeps the step', (tester) async {
    final form = signUpForm(
      usernameCheck: (v) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return v == 'admin' ? 'That username is taken' : null;
      },
    );
    addTearDown(form.dispose);
    await pumpWizard(tester, form);

    await tester.enterText(inputOf('Username'), 'admin');
    await tester.tap(buttonLabelled('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(steps(tester).current, 0);
    expect(steps(tester).errorSteps, {0});
    expect(find.text('That username is taken'), findsOneWidget);
  });

  testWidgets('the indicator jumps back, never forward', (tester) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    final f = SignUp(form.scope);
    f.username.set('ada');
    f.name.set('Ada');
    await pumpWizard(tester, form, initialStep: 2);

    // A step ahead is not a button; the first one is.
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(steps(tester).current, 0);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(steps(tester).current, 0);
  });

  testWidgets('steps not shown are out of focus traversal and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final form = signUpForm();
    addTearDown(form.dispose);
    await pumpWizard(tester, form);

    expect(find.bySemanticsLabel('Username'), findsOneWidget);
    expect(find.bySemanticsLabel('Name'), findsNothing);
    final name = tester.widget<EditableText>(inputOf('Name'));
    name.focusNode.requestFocus();
    await tester.pump();
    expect(name.focusNode.hasFocus, isFalse);
    expect(inputOf('Name').hitTestable(), findsNothing);
    semantics.dispose();
  });

  testWidgets('the incoming step fades in, at once under reduced motion', (
    tester,
  ) async {
    Future<double> opacityAfterMove({required bool reduceMotion}) async {
      final form = signUpForm();
      addTearDown(form.dispose);
      SignUp(form.scope).username.set('ada');
      await pumpWizard(tester, form, reduceMotion: reduceMotion);
      await tester.tap(buttonLabelled('Next'));
      await tester.pump();
      await tester.pump();
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: shellOf('Name'), matching: find.byType(Opacity)),
      );
      await tester.pumpAndSettle();
      return opacity.opacity;
    }

    expect(await opacityAfterMove(reduceMotion: false), lessThan(1));
    expect(await opacityAfterMove(reduceMotion: true), 1);
  });

  testWidgets('the footer ends the row, its buttons a control apart', (
    tester,
  ) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    SignUp(form.scope).username.set('ada');
    await pumpWizard(tester, form);
    await press(tester, 'Next');

    final wizard = tester.getRect(find.byType(FormWizard));
    final back = tester.getRect(buttonLabelled('Back'));
    final next = tester.getRect(buttonLabelled('Next'));
    expect(next.right, wizard.right);
    expect(next.left - back.right, AdminSpacing.md);
    expect(back.top, next.top);
    final height = irisTheme.tokens.sizes.medium;
    expect(back.height, height);
    expect(next.height, height);
  });

  testWidgets('inside the controller’s ValueForm it mounts no other', (
    tester,
  ) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    final fields = FormFieldRegistry();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ValueForm(
            controller: form,
            fields: fields,
            child: SingleChildScrollView(
              child: FormWizard(
                controller: form,
                steps: signUpSteps(SignUp(form.scope)),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ValueForm), findsOneWidget);
    expect(fields.entries.map((e) => e.id), containsAll(['username', 'name']));

    await press(tester, 'Next');
    final username = tester.widget<EditableText>(inputOf('Username'));
    expect(username.focusNode.hasFocus, isTrue);
  });

  testWidgets('Back leaving with the first step hands focus to Next', (
    tester,
  ) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    SignUp(form.scope).username.set('ada');
    await pumpWizard(tester, form, initialStep: 1);

    final back = tester.widget<Button>(buttonLabelled('Back'));
    back.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(steps(tester).current, 0);
    expect(buttonLabelled('Back'), findsNothing);
    final next = tester.widget<Button>(buttonLabelled('Next'));
    expect(next.focusNode!.hasFocus, isTrue);
  });

  testWidgets('the indicator is vertical under the compact width', (
    tester,
  ) async {
    final form = signUpForm();
    addTearDown(form.dispose);
    await pumpWizard(tester, form, width: 390, initialStep: 1);
    expect(steps(tester).direction, Axis.vertical);
    expect(tester.takeException(), isNull, reason: 'Back and Next fit');
    expect(
      tester.getRect(buttonLabelled('Next')).right,
      tester.getRect(find.byType(FormWizard)).right,
    );

    await pumpWizard(tester, form, width: 800);
    expect(steps(tester).direction, Axis.horizontal);
  });
}
