import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type Shop(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<List<String>> get tags => _s.list('tags');
  RecordListCell<Zone> get zones => _s.recordList('zones', build: Zone.new);
}

extension type Zone(RecordScope _e) {
  ValueCell<String> get name => _e.text('name');
}

typedef Values = ({String name, int zones});

ValueFormController<Values> shopForm({
  int zones = 0,
  int minZones = 1,
  int? maxZones,
  String? message,
  ValidationMode mode = ValidationMode.onEdit,
}) => ValueFormController<Values>(
  read: (s) => (name: Shop(s).name.value, zones: Shop(s).zones.elements.length),
  write: (s, v) {
    final f = Shop(s);
    f.name.set(v.name);
    while (f.zones.elements.length > v.zones) {
      f.zones.removeAt(0);
    }
    while (f.zones.elements.length < v.zones) {
      f.zones.add();
    }
  },
  initial: (name: 'Leaf', zones: zones),
  rules: (s) {
    final f = Shop(s);
    return [
      FieldRules(f.name, validators: [Validators.required()]),
      ListRules(
        f.zones,
        minItems: minZones,
        maxItems: maxZones,
        message: message,
      ),
    ];
  },
  mode: mode,
  requireChanges: false,
);

Widget zonesField(Shop f) => RecordListField<Zone>(
  f.zones,
  label: 'Shipping zones',
  addLabel: 'Add zone',
  item: (zone) => Field(zone.name, label: 'Zone name'),
);

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(900, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: locale,
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ListView(padding: const EdgeInsets.all(24), children: [child]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder buttonLabelled(String label) =>
    find.byWidgetPredicate((w) => w is Button && w.label == label);

Finder inField(String label, Finder matching) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FieldShell && w.label == label),
  matching: matching,
);

void main() {
  test('a record list is a cell of its elements', () {
    final scope = LocalScope();
    addTearDown(scope.dispose);
    final Cell<List<Zone>> zones = Shop(scope).zones;
    expect(zones.id, 'zones');
  });

  group('ListRules on a controller', () {
    test('an empty list fails, is required, and passes once a row is '
        'added', () {
      final form = shopForm();
      addTearDown(form.dispose);
      final f = Shop(form.scope);
      expect(form.allErrors, {f.zones.id: 'Add at least 1 item'});
      expect(form.isRequired(f.zones.id), isTrue);
      expect(form.errors, isEmpty, reason: 'nothing is revealed untouched');

      f.zones.add();
      expect(form.allErrors, isEmpty);
    });

    test('removing the last row reveals the message as an edit', () {
      final form = shopForm(zones: 1);
      addTearDown(form.dispose);
      final f = Shop(form.scope);
      expect(form.allErrors, isEmpty);

      f.zones.removeAt(0);
      expect(form.errors, {f.zones.id: 'Add at least 1 item'});

      f.zones.add();
      expect(form.errors, isEmpty);
    });

    test('maxItems and a message of its own', () {
      final form = shopForm(zones: 3, minZones: 2, maxZones: 2);
      addTearDown(form.dispose);
      final f = Shop(form.scope);
      expect(form.allErrors[f.zones.id], 'Keep at most 2 items');
      f.zones.removeAt(0);
      expect(form.allErrors, isEmpty);
      f.zones.removeAt(0);
      expect(form.allErrors[f.zones.id], 'Add at least 2 items');

      final own = shopForm(message: 'Add a shipping zone.');
      addTearDown(own.dispose);
      expect(own.allErrors[Shop(own.scope).zones.id], 'Add a shipping zone.');
    });

    test('minItems 0 is optional', () {
      final form = shopForm(minZones: 0, maxZones: 1);
      addTearDown(form.dispose);
      expect(form.isRequired(Shop(form.scope).zones.id), isFalse);
      expect(form.allErrors, isEmpty);
    });

    test('a list value counts its items too', () {
      final form = ValueFormController<List<String>>(
        read: (s) => Shop(s).tags.value,
        write: (s, v) => Shop(s).tags.set(v),
        initial: const ['fern'],
        rules: (s) => [ListRules(Shop(s).tags, minItems: 2)],
      );
      addTearDown(form.dispose);
      final tags = Shop(form.scope).tags;
      expect(form.allErrors[tags.id], 'Add at least 2 items');
      tags.set(['fern', 'moss']);
      expect(form.allErrors, isEmpty);
    });

    test('submit is refused while the list is short', () async {
      final form = shopForm();
      addTearDown(form.dispose);
      final reveals = form.revealRequest;
      await form.submit();
      expect(form.revealRequest, reveals + 1);
      expect(form.errors.keys, [Shop(form.scope).zones.id]);
    });
  });

  group('the words', () {
    test('en, fr and ar count in their plural forms', () {
      const en = FieldsMessagesEn();
      const fr = FieldsMessagesFr();
      const ar = FieldsMessagesAr();
      expect(en.addAtLeast(1), 'Add at least 1 item');
      expect(en.addAtLeast(3), 'Add at least 3 items');
      expect(en.keepAtMost(1), 'Keep at most 1 item');
      expect(en.keepAtMost(5), 'Keep at most 5 items');
      expect(fr.addAtLeast(1), 'Ajoutez au moins 1 élément');
      expect(fr.addAtLeast(3), 'Ajoutez au moins 3 éléments');
      expect(fr.keepAtMost(5), 'Gardez au plus 5 éléments');
      expect(ar.addAtLeast(1), 'أضف عنصرًا واحدًا على الأقل');
      expect(ar.addAtLeast(2), 'أضف عنصرين على الأقل');
      expect(ar.addAtLeast(3), 'أضف 3 عناصر على الأقل');
      expect(ar.addAtLeast(11), 'أضف 11 عنصرًا على الأقل');
      expect(ar.addAtLeast(100), 'أضف 100 عنصر على الأقل');
      expect(ar.keepAtMost(1), 'لا تتجاوز عنصرًا واحدًا');
      expect(ar.keepAtMost(2), 'لا تتجاوز عنصرين');
      expect(ar.keepAtMost(5), 'لا تتجاوز 5 عناصر');
    });

    for (final (locale, message) in [
      (const Locale('en'), 'Add at least 1 item'),
      (const Locale('fr'), 'Ajoutez au moins 1 élément'),
      (const Locale('ar'), 'أضف عنصرًا واحدًا على الأقل'),
    ]) {
      testWidgets('the list shows it in ${locale.languageCode}', (
        tester,
      ) async {
        final form = shopForm(mode: ValidationMode.always);
        addTearDown(form.dispose);
        await pumpApp(
          tester,
          ValueForm(controller: form, child: zonesField(Shop(form.scope))),
          locale: locale,
        );
        expect(inField('Shipping zones', find.text(message)), findsOneWidget);
      });
    }
  });

  testWidgets('a message of the app\'s follows the app\'s language', (
    tester,
  ) async {
    var language = 'en';
    const words = {'en': 'Add a zone.', 'fr': 'Ajoutez une zone.'};
    final form = ValueFormController<int>(
      read: (s) => Shop(s).zones.elements.length,
      write: (s, _) {},
      rules: (s) => [ListRules(Shop(s).zones, message: words[language])],
      mode: ValidationMode.always,
    );
    addTearDown(form.dispose);
    final field = ValueForm(
      controller: form,
      child: zonesField(Shop(form.scope)),
    );
    await pumpApp(tester, field);
    expect(find.text('Add a zone.'), findsOneWidget);

    language = 'fr';
    await pumpApp(tester, field, locale: const Locale('fr'));
    expect(find.text('Ajoutez une zone.'), findsOneWidget);
  });

  group('in a wizard', () {
    Widget wizard(ValueFormController<Values> form) {
      final f = Shop(form.scope);
      return FormWizard(
        controller: form,
        summary: const ValidationSummary(),
        steps: [
          FormWizardStep(
            title: 'Shipping',
            fields: [f.zones, for (final zone in f.zones.elements) zone.name],
            builder: (context) => zonesField(f),
          ),
          FormWizardStep(
            title: 'Review',
            fields: const [],
            builder: (context) => const Text('All set'),
          ),
        ],
      );
    }

    testWidgets('Next is refused with no rows; the message is under the '
        'list and in the summary', (tester) async {
      final form = shopForm();
      addTearDown(form.dispose);
      await pumpApp(tester, wizard(form));
      final shell = find.byWidgetPredicate(
        (w) => w is FieldShell && w.label == 'Shipping zones',
      );
      expect(tester.widget<FieldShell>(shell).required, isTrue);

      await tester.tap(buttonLabelled('Next'));
      await tester.pumpAndSettle();

      expect(find.text('All set'), findsNothing);
      expect(tester.widget<Steps>(find.byType(Steps)).errorSteps, contains(0));
      expect(
        inField('Shipping zones', find.text('Add at least 1 item')),
        findsOneWidget,
      );
      final link = find.descendant(
        of: find.byType(ValidationSummary),
        matching: find.byType(TextLink),
      );
      expect(
        tester.widget<TextLink>(link).label,
        'Shipping zones: Add at least 1 item',
      );
      expect(
        _focused(tester, 'Add zone'),
        isTrue,
        reason: 'focus is taken there',
      );

      await tester.tap(buttonLabelled('Add zone'));
      await tester.pumpAndSettle();
      expect(find.text('Add at least 1 item'), findsNothing);
      expect(link, findsNothing);
      await tester.enterText(
        inField('Zone name', find.byType(EditableText)),
        'Home',
      );
      await tester.tap(buttonLabelled('Next'));
      await tester.pumpAndSettle();
      expect(find.text('All set'), findsOneWidget);
    });

    testWidgets('the summary link focuses the add button', (tester) async {
      final form = shopForm();
      addTearDown(form.dispose);
      await pumpApp(tester, wizard(form));
      await tester.tap(buttonLabelled('Next'));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(_focused(tester, 'Add zone'), isFalse);

      await tester.tap(
        find.descendant(
          of: find.byType(ValidationSummary),
          matching: find.byType(TextLink),
        ),
      );
      await tester.pumpAndSettle();
      expect(_focused(tester, 'Add zone'), isTrue);
    });
  });
}

/// Whether focus is inside the button labelled [label].
bool _focused(WidgetTester tester, String label) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final button = tester.element(buttonLabelled(label));
  var inside = false;
  focused.visitAncestorElements((e) {
    if (e == button) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside || focused == button;
}
