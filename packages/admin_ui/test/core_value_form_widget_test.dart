import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type Profile(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<bool> get company => _s.boolean('company');
  ValueCell<String> get vat => _s.text('vat');
}

typedef Values = ({String name, String email});

ValueFormController<Values> profileForm({
  ValidationMode mode = ValidationMode.onEdit,
  Future<void> Function(Values)? onSubmit,
}) => ValueFormController<Values>(
  read: (s) => (name: Profile(s).name.value, email: Profile(s).email.value),
  write: (s, v) => Profile(s)
    ..name.set(v.name)
    ..email.set(v.email),
  initial: (name: 'Ada', email: ''),
  rules: (s) {
    final f = Profile(s);
    return [
      FieldRules(f.name, validators: [Validators.required()]),
      FieldRules(
        f.email,
        validators: [Validators.required(), Validators.email()],
      ),
      FieldRules(
        f.vat,
        validators: [Validators.required()],
        visibleWhen: () => f.company.value,
      ),
    ];
  },
  mode: mode,
  onSubmit: onSubmit,
  requireChanges: false,
);

Future<void> pumpForm(
  WidgetTester tester,
  ValueFormController<Values> controller, {
  bool readOnly = false,
  Locale locale = const Locale('en'),
  Widget Function(Profile f)? extra,
}) async {
  final f = Profile(controller.scope);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: locale,
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ValueForm(
          controller: controller,
          readOnly: readOnly,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Field(f.name, label: 'Name'),
              Field(f.email, label: 'Email'),
              ?extra?.call(f),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder shellOf(String label) =>
    find.byWidgetPredicate((w) => w is FieldShell && w.label == label);

Finder textFieldOf(String label) =>
    find.descendant(of: shellOf(label), matching: find.byType(EditableText));

void main() {
  testWidgets('a message reaches its FieldShell through ValueForm', (
    tester,
  ) async {
    final form = profileForm();
    addTearDown(form.dispose);
    await pumpForm(tester, form);
    expect(find.text('Required'), findsNothing, reason: 'nothing touched');

    await tester.enterText(textFieldOf('Name'), '');
    await tester.pump();
    expect(tester.widget<FieldShell>(shellOf('Name')).errorText, 'Required');
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('the messages are in the app’s language', (tester) async {
    final form = profileForm(mode: ValidationMode.always);
    addTearDown(form.dispose);
    await pumpForm(tester, form, locale: const Locale('fr'));
    expect(form.localizations, isA<AdminLocalizationsFr>());
    expect(find.text('Obligatoire'), findsOneWidget);
  });

  testWidgets('a refused submit focuses the first invalid field', (
    tester,
  ) async {
    var calls = 0;
    final form = profileForm(onSubmit: (_) async => calls++);
    addTearDown(form.dispose);
    await pumpForm(tester, form);

    await form.submit();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Required'), findsOneWidget);
    final email = tester.widget<EditableText>(textFieldOf('Email'));
    expect(email.focusNode.hasFocus, isTrue);
  });

  testWidgets('a read-only form makes its fields read-only', (tester) async {
    final form = profileForm();
    addTearDown(form.dispose);
    await pumpForm(tester, form, readOnly: true);
    for (final label in ['Name', 'Email']) {
      expect(tester.widget<EditableText>(textFieldOf(label)).readOnly, isTrue);
    }
  });

  testWidgets('ValueFormScope rebuilds only the field whose state moved', (
    tester,
  ) async {
    final form = profileForm();
    addTearDown(form.dispose);
    final builds = <String, int>{};
    Widget probe(String id) => Builder(
      builder: (context) {
        builds[id] = (builds[id] ?? 0) + 1;
        final visible = ValueFormScope.isVisible(context, id);
        final required = ValueFormScope.isRequired(context, id);
        return Text('$id visible=$visible required=$required');
      },
    );
    await pumpForm(
      tester,
      form,
      extra: (f) => Column(children: [probe('vat'), probe('name')]),
    );
    expect(find.text('vat visible=false required=false'), findsOneWidget);
    expect(find.text('name visible=true required=true'), findsOneWidget);
    final before = Map.of(builds);

    Profile(form.scope).company.set(true);
    await tester.pump();
    expect(find.text('vat visible=true required=true'), findsOneWidget);
    expect(builds['vat'], before['vat']! + 1);
    expect(builds['name'], before['name'], reason: 'its state did not move');
  });

  testWidgets('FieldFeedbackScope carries the pending checks', (tester) async {
    final form = ValueFormController<String>(
      read: (s) => s.text('email').value,
      write: (s, v) => s.text('email').set(v),
      rules: (s) => [
        FieldRules(s.text('email'), asyncValidators: [(_) async => null]),
      ],
    );
    addTearDown(form.dispose);
    final seen = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ValueForm(
          controller: form,
          child: Builder(
            builder: (context) {
              seen.add(FieldFeedbackScope.isPending(context, 'email'));
              return Text(
                'reserve=${FieldFeedbackScope.reserveErrorLineOf(context)} '
                'optional=${FieldFeedbackScope.markOptionalOf(context)}',
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('reserve=true optional=true'), findsOneWidget);
    form.scope.text('email').set('a@x.io');
    await tester.pump();
    expect(seen.last, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(seen.last, isFalse);
  });

  testWidgets('every field keeps a message line, named by a rule or not', (
    tester,
  ) async {
    final controller = profileForm();
    addTearDown(controller.dispose);
    await pumpForm(
      tester,
      controller,
      extra: (f) => Field(controller.scope.text('nickname'), label: 'Nickname'),
    );
    expect(controller.ruleFields, {'name', 'email', 'vat'});
    final height = tester.getSize(shellOf('Name')).height;
    expect(tester.getSize(shellOf('Nickname')).height, height);

    await tester.enterText(textFieldOf('Name'), '');
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(tester.getSize(shellOf('Name')).height, height);

    // A server's message on a field no rule names takes its line too.
    controller.setErrors({'nickname': 'Taken'});
    await tester.pump();
    expect(find.text('Taken'), findsOneWidget);
    expect(tester.getSize(shellOf('Nickname')).height, height);
  });

  testWidgets('a FieldGroup under the form takes the 8 above each message '
      'line out of its gap', (tester) async {
    final controller = profileForm();
    addTearDown(controller.dispose);
    final f = Profile(controller.scope);
    Future<List<double>> gaps({required bool reserve}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(irisTheme.tokens),
          home: Scaffold(
            body: ValueForm(
              controller: controller,
              reserveErrorLine: reserve,
              child: FieldGroup(
                children: [
                  Field(f.name, label: 'Name'),
                  BooleanField(f.company, label: 'Company'),
                  Field(f.email, label: 'Email'),
                ],
              ),
            ),
          ),
        ),
      );
      final shells = [
        for (final label in ['Name', 'Company', 'Email'])
          tester.getRect(shellOf(label)),
      ];
      return [
        for (var i = 1; i < shells.length; i++)
          shells[i].top - shells[i - 1].bottom,
      ];
    }

    expect(await gaps(reserve: true), [AdminSpacing.lg, AdminSpacing.lg]);
    expect(await gaps(reserve: false), [AdminSpacing.xl, AdminSpacing.xl]);
  });

  testWidgets('FieldFeedbackScope marks optional only the validated ids', (
    tester,
  ) async {
    final seen = <String, bool>{};
    Widget probe(String id) => Builder(
      builder: (context) {
        seen[id] = FieldFeedbackScope.validates(context, id);
        return const SizedBox();
      },
    );
    final probes = Column(children: [probe('a'), probe('b')]);
    Widget scope(Set<String>? validated) => Directionality(
      textDirection: TextDirection.ltr,
      child: FieldFeedbackScope(validated: validated, child: probes),
    );
    await tester.pumpWidget(scope(null));
    expect(seen, {'a': true, 'b': true});
    await tester.pumpWidget(scope(const {'a'}));
    expect(seen, {'a': true, 'b': false});
    await tester.pumpWidget(scope(const {'a', 'b'}));
    expect(seen, {'a': true, 'b': true});
    await tester.pumpWidget(probes);
    expect(seen, {'a': false, 'b': false}, reason: 'outside any form');
  });

  testWidgets('the fields keep their state as its registry changes', (
    tester,
  ) async {
    final form = profileForm();
    addTearDown(form.dispose);
    final above = FormFieldRegistry();
    final given = FormFieldRegistry();
    final field = Field(Profile(form.scope).name, label: 'Name');
    Widget app(FormFieldRegistry? fields) => MaterialApp(
      home: Scaffold(
        body: FormFieldScope(
          registry: above,
          child: ValueForm(controller: form, fields: fields, child: field),
        ),
      ),
    );

    await tester.pumpWidget(app(null));
    final editable = tester.state(textFieldOf('Name'));
    expect(above.entries, hasLength(1));
    await tester.pumpWidget(app(given));
    expect(tester.state(textFieldOf('Name')), same(editable));
    expect(given.entries, hasLength(1));
    await tester.pumpWidget(app(null));
    expect(tester.state(textFieldOf('Name')), same(editable));
  });

  testWidgets('FieldFeedbackScope rebuilds only the field whose check moved', (
    tester,
  ) async {
    final builds = <String, int>{};
    Widget probe(String id) => Builder(
      builder: (context) {
        builds[id] = (builds[id] ?? 0) + 1;
        return Text('$id ${FieldFeedbackScope.isPending(context, id)}');
      },
    );
    // One child for both pumps, so only the scope's notification rebuilds.
    final probes = Column(children: [probe('a'), probe('b')]);
    Widget scope(Set<String> pending) => Directionality(
      textDirection: TextDirection.ltr,
      child: FieldFeedbackScope(pending: pending, child: probes),
    );
    await tester.pumpWidget(scope(const {}));
    await tester.pumpWidget(scope(const {'a'}));
    expect(find.text('a true'), findsOneWidget);
    expect(builds, {'a': 2, 'b': 1});
  });
}
