import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type Venue(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get website => _s.text('website');
}

typedef Values = ({String name, String email, String website});

ValueFormController<Values> venueForm({
  String name = '',
  String email = '',
  String website = '',
}) => ValueFormController<Values>(
  read: (s) => (
    name: Venue(s).name.value,
    email: Venue(s).email.value,
    website: Venue(s).website.value,
  ),
  write: (s, v) => Venue(s)
    ..name.set(v.name)
    ..email.set(v.email)
    ..website.set(v.website),
  initial: (name: name, email: email, website: website),
  rules: (s) {
    final f = Venue(s);
    return [
      // Out of reading order on purpose: the summary follows the fields.
      FieldRules(f.website, validators: [Validators.url()]),
      FieldRules(
        f.email,
        validators: [Validators.required(), Validators.email()],
      ),
      FieldRules(f.name, validators: [Validators.required()]),
    ];
  },
  requireChanges: false,
  onSubmit: (_) async {},
);

Future<void> pumpSummary(
  WidgetTester tester,
  ValueFormController<Values> form, {
  int? maxItems,
}) async {
  final f = Venue(form.scope);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ValueForm(
          controller: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ValidationSummary(maxItems: maxItems),
              Field(f.name, label: 'Name'),
              Field(f.email, label: 'Email'),
              Field(f.website, label: 'Website'),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get summary => find.byType(ValidationSummary, skipOffstage: false);

Finder rowsIn(Finder summary) =>
    find.descendant(of: summary, matching: find.byType(TextLink));

List<String> rowLabels(WidgetTester tester) => [
  for (final link in tester.widgetList<TextLink>(rowsIn(summary))) link.label,
];

Finder inputOf(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FieldShell && w.label == label),
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('nothing shows before a submit attempt', (tester) async {
    final form = venueForm();
    addTearDown(form.dispose);
    await pumpSummary(tester, form);
    expect(tester.getSize(summary).height, 0);

    await tester.enterText(inputOf('Email'), 'ada@');
    await tester.pump();
    expect(form.errors, isNotEmpty, reason: 'the field shows its message');
    expect(rowsIn(summary), findsNothing);
    expect(tester.getSize(summary).height, 0);
  });

  testWidgets('a refused submit lists the messages in reading order', (
    tester,
  ) async {
    final form = venueForm(email: 'ada@', website: 'harbour-hall');
    addTearDown(form.dispose);
    await pumpSummary(tester, form);

    await form.submit();
    await tester.pumpAndSettle();
    expect(find.text('3 fields need fixing'), findsOneWidget);
    expect(rowLabels(tester), [
      'Name: Required',
      'Email: Enter a valid email address',
      'Website: Enter a valid web address',
    ]);
  });

  testWidgets('tapping a row focuses its field', (tester) async {
    final form = venueForm(email: 'ada@', website: 'harbour-hall');
    addTearDown(form.dispose);
    await pumpSummary(tester, form);
    await form.submit();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Website: Enter a valid web address'));
    await tester.pumpAndSettle();
    final website = tester.widget<EditableText>(inputOf('Website'));
    expect(website.focusNode.hasFocus, isTrue);
  });

  testWidgets('it counts down as fields are fixed and hides when valid', (
    tester,
  ) async {
    final form = venueForm(email: 'ada@');
    addTearDown(form.dispose);
    await pumpSummary(tester, form);
    await form.submit();
    await tester.pumpAndSettle();
    expect(find.text('2 fields need fixing'), findsOneWidget);

    await tester.enterText(inputOf('Name'), 'Harbour Hall');
    await tester.pump();
    expect(find.text('1 field needs fixing'), findsOneWidget);
    expect(rowLabels(tester), ['Email: Enter a valid email address']);

    await tester.enterText(inputOf('Email'), 'events@harbour.test');
    await tester.pump();
    expect(rowsIn(summary), findsNothing);
    expect(find.textContaining('need'), findsNothing);
    expect(tester.getSize(summary).height, 0);
  });

  testWidgets('it is a polite live region titled with the count', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final form = venueForm();
    addTearDown(form.dispose);
    await pumpSummary(tester, form);
    await form.submit();
    await tester.pumpAndSettle();

    final region = tester.getSemantics(find.text('2 fields need fixing'));
    expect(region.flagsCollection.isLiveRegion, isTrue);
    expect(region.label, '2 fields need fixing');
    final row = tester.getSemantics(find.text('Name: Required'));
    expect(row.label, 'Go to Name, Required');
    expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('maxItems folds the rest behind a link', (tester) async {
    final form = venueForm(email: 'ada@', website: 'harbour-hall');
    addTearDown(form.dispose);
    await pumpSummary(tester, form, maxItems: 1);
    await form.submit();
    await tester.pumpAndSettle();
    expect(rowLabels(tester), ['Name: Required', 'Show 2 more']);

    await tester.tap(find.text('Show 2 more'));
    await tester.pump();
    expect(rowLabels(tester), hasLength(3));
  });

  testWidgets('a wizard step refused shows it, until the user moves', (
    tester,
  ) async {
    final form = venueForm();
    addTearDown(form.dispose);
    final f = Venue(form.scope);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ValueForm(
            controller: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const ValidationSummary(),
                FormWizard(
                  controller: form,
                  steps: [
                    FormWizardStep(
                      title: 'Venue',
                      fields: [f.name],
                      builder: (context) => Field(f.name, label: 'Name'),
                    ),
                    FormWizardStep(
                      title: 'Contact',
                      fields: [f.email],
                      builder: (context) => Field(f.email, label: 'Email'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(rowLabels(tester), ['Name: Required']);

    await tester.enterText(inputOf('Name'), 'Harbour Hall');
    await tester.pump();
    expect(rowsIn(summary), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(rowsIn(summary), findsNothing, reason: 'Contact is not checked');
  });
}
