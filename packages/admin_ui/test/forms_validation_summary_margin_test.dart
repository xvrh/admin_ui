import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type Venue(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
}

typedef Values = ({String name, String email});

ValueFormController<Values> venueForm() => ValueFormController<Values>(
  read: (s) => (name: Venue(s).name.value, email: Venue(s).email.value),
  write: (s, v) => Venue(s)
    ..name.set(v.name)
    ..email.set(v.email),
  initial: (name: '', email: ''),
  rules: (s) => [
    FieldRules(Venue(s).name, validators: [Validators.required()]),
    FieldRules(Venue(s).email, validators: [Validators.required()]),
  ],
  requireChanges: false,
  onSubmit: (_) async {},
);

Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(900, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: ListView(padding: const EdgeInsets.all(24), children: [child]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get summary => find.byType(ValidationSummary);

/// The alert the summary draws, inside its margin.
Finder get alert => find.descendant(
  of: summary,
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.decoration is BoxDecoration,
  ),
);

Finder shellOf(String label) =>
    find.byWidgetPredicate((w) => w is FieldShell && w.label == label);

void main() {
  const margin = EdgeInsets.only(bottom: AdminSpacing.xl);

  Widget form(ValueFormController<Values> controller, {EdgeInsetsGeometry? m}) {
    final f = Venue(controller.scope);
    return ValueForm(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValidationSummary(margin: m ?? margin),
          Field(f.name, label: 'Name'),
          Field(f.email, label: 'Email'),
        ],
      ),
    );
  }

  testWidgets('hidden, it takes no room and leaves no gap', (tester) async {
    final controller = venueForm();
    addTearDown(controller.dispose);
    await pumpPage(tester, form(controller));

    expect(tester.getSize(summary).height, 0);
    expect(
      tester.getTopLeft(shellOf('Name')).dy,
      tester.getTopLeft(summary).dy,
    );
    expect(alert, findsNothing);
  });

  testWidgets('shown, its margin parts it from the fields', (tester) async {
    final controller = venueForm();
    addTearDown(controller.dispose);
    await pumpPage(tester, form(controller));

    await controller.submit();
    await tester.pumpAndSettle();

    final box = tester.getRect(alert);
    expect(box.height, greaterThan(0));
    expect(tester.getTopLeft(shellOf('Name')).dy, box.bottom + AdminSpacing.xl);
    expect(tester.getRect(summary).height, box.height + AdminSpacing.xl);

    Venue(controller.scope)
      ..name.set('Harbour Hall')
      ..email.set('events@example.com');
    await tester.pumpAndSettle();
    expect(tester.getSize(summary).height, 0, reason: 'fixed, it goes');
  });

  testWidgets('a directional margin follows the reading direction', (
    tester,
  ) async {
    const start = EdgeInsetsDirectional.only(start: AdminSpacing.xl);
    for (final direction in TextDirection.values) {
      final controller = venueForm();
      addTearDown(controller.dispose);
      await pumpPage(tester, form(controller, m: start), direction: direction);
      await controller.submit();
      await tester.pumpAndSettle();
      final outer = tester.getRect(summary);
      final box = tester.getRect(alert);
      if (direction == TextDirection.ltr) {
        expect(box.left - outer.left, AdminSpacing.xl);
        expect(box.right, outer.right);
      } else {
        expect(outer.right - box.right, AdminSpacing.xl);
        expect(box.left, outer.left);
      }
    }
  });

  test(
    'showsFor says whether it shows, and notifies as that changes',
    () async {
      final controller = venueForm();
      addTearDown(controller.dispose);
      final shows = ValidationSummary.showsFor(controller);
      expect(identical(ValidationSummary.showsFor(controller), shows), isTrue);
      expect(shows.value, isFalse);
      final heard = <bool>[];
      void listener() => heard.add(shows.value);
      shows.addListener(listener);
      addTearDown(() => shows.removeListener(listener));

      Venue(controller.scope).name.set('Harbour Hall');
      expect(heard, isEmpty, reason: 'an edit before a submit shows nothing');

      await controller.submit();
      expect(heard, [true]);

      Venue(controller.scope).email.set('events@example.com');
      expect(heard, [true, false]);
      expect(shows.value, isFalse);
    },
  );

  group('FormWizard(summary:)', () {
    Widget wizard(ValueFormController<Values> controller) {
      final f = Venue(controller.scope);
      return FormWizard(
        controller: controller,
        summary: const ValidationSummary(),
        steps: [
          FormWizardStep(
            title: 'Venue',
            fields: [f.name, f.email],
            builder: (context) => Column(
              children: [
                Field(f.name, label: 'Name'),
                Field(f.email, label: 'Email'),
              ],
            ),
          ),
          FormWizardStep(
            title: 'Review',
            fields: const [],
            builder: (context) => const Text('All set'),
          ),
        ],
      );
    }

    testWidgets('hidden, the step keeps its place under the indicator', (
      tester,
    ) async {
      final controller = venueForm();
      addTearDown(controller.dispose);
      await pumpPage(tester, wizard(controller));

      final steps = tester.getRect(find.byType(Steps));
      expect(tester.getSize(summary).height, 0);
      expect(
        tester.getTopLeft(shellOf('Name')).dy,
        steps.bottom + AdminSpacing.xxl,
      );
    });

    testWidgets('a refused step shows it between the indicator and the '
        'step, spaced from both', (tester) async {
      final controller = venueForm();
      addTearDown(controller.dispose);
      await pumpPage(tester, wizard(controller));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final steps = tester.getRect(find.byType(Steps));
      final box = tester.getRect(alert);
      expect(box.top, steps.bottom + AdminSpacing.xxl);
      expect(
        tester.getTopLeft(shellOf('Name')).dy,
        box.bottom + AdminSpacing.xl,
      );
      expect(
        find.descendant(of: summary, matching: find.byType(TextLink)),
        findsNWidgets(2),
      );

      Venue(controller.scope)
        ..name.set('Harbour Hall')
        ..email.set('events@example.com');
      await tester.pumpAndSettle();
      expect(tester.getSize(summary).height, 0);
      expect(
        tester.getTopLeft(shellOf('Name')).dy,
        steps.bottom + AdminSpacing.xxl,
      );
    });

    testWidgets('the indicator turns vertical under the theme breakpoint', (
      tester,
    ) async {
      final controller = venueForm();
      addTearDown(controller.dispose);
      final tokens = irisTheme.tokens.copyWith(
        breakpoints: const AdminBreakpoints(medium: 900),
      );
      tester.view.physicalSize = const Size(860, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          localizationsDelegates: AdminLocalizations.localizationsDelegates,
          home: Scaffold(body: ListView(children: [wizard(controller)])),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Steps>(find.byType(Steps)).direction,
        Axis.vertical,
        reason: '860 is compact where medium starts at 900',
      );
    });
  });
}
