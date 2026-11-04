import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type Account(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get nickname => _s.text('nickname');
  ValueCell<bool> get company => _s.boolean('company');
  ValueCell<String> get vat => _s.text('vat');
  RecordListCell<RecordScope> get phones =>
      _s.recordList('phones', build: (r) => r);
}

typedef Values = ({String name, bool company, String vat});

ValueFormController<Values> accountForm() => ValueFormController<Values>(
  read: (s) {
    final f = Account(s);
    return (name: f.name.value, company: f.company.value, vat: f.vat.value);
  },
  write: (s, v) => Account(s)
    ..name.set(v.name)
    ..company.set(v.company)
    ..vat.set(v.vat),
  initial: (name: 'Ada', company: false, vat: ''),
  rules: (s) {
    final f = Account(s);
    return [
      FieldRules(f.name, validators: [Validators.required()]),
      FieldRules(
        f.vat,
        validators: [Validators.required()],
        visibleWhen: () => f.company.value,
        dependsOn: [f.company],
      ),
    ];
  },
);

/// Leaves every cell to the kit, noting what `bind` handed it.
class _Recorder extends FieldBinder {
  final binds = <String>[];
  final required = <String, bool>{};

  @override
  Widget? bind<V>(BuildContext context, Cell<V> cell, FieldBinding<V> binding) {
    binds.add(cell.id);
    required[cell.id] = binding.required;
    return null;
  }
}

Future<void> pumpForm(
  WidgetTester tester,
  ValueFormController<Values> controller, {
  FormFieldRegistry? fields,
  FieldBinder? binder,
  bool readOnly = false,
  bool reduceMotion = false,
  List<Widget> Function(Account f)? children,
}) async {
  final f = Account(controller.scope);
  Widget form = ValueForm(
    controller: controller,
    fields: fields,
    readOnly: readOnly,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children:
          children?.call(f) ??
          [
            Field(f.name, label: 'Name'),
            BooleanField(f.company, label: 'Company'),
            Field(f.vat, label: 'VAT number'),
            Field(f.nickname, label: 'Nickname'),
          ],
    ),
  );
  if (binder != null) form = FieldBinderScope(binder: binder, child: form);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: MediaQuery.fromView(
        view: tester.view,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: Scaffold(body: form),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder shellOf(String label) =>
    find.byWidgetPredicate((w) => w is FieldShell && w.label == label);

Iterable<String> registered(FormFieldRegistry registry) =>
    registry.entries.map((e) => e.label);

void main() {
  group('visibleWhen', () {
    testWidgets('folds the field away, then takes it and its registry entry '
        'out of the tree; shown again it unfolds', (tester) async {
      final form = accountForm();
      addTearDown(form.dispose);
      final registry = FormFieldRegistry();
      await pumpForm(tester, form, fields: registry);
      final f = Account(form.scope);

      expect(shellOf('VAT number'), findsNothing);
      expect(registered(registry), isNot(contains('VAT number')));
      final nicknameAt = tester.getTopLeft(shellOf('Nickname')).dy;

      f.company.set(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(shellOf('VAT number'), findsOneWidget);
      final opening = tester.getTopLeft(shellOf('Nickname')).dy - nicknameAt;
      await tester.pumpAndSettle();
      final open = tester.getTopLeft(shellOf('Nickname')).dy - nicknameAt;
      expect(opening, greaterThan(0));
      expect(opening, lessThan(open), reason: 'still unfolding');
      expect(
        open,
        greaterThanOrEqualTo(tester.getSize(shellOf('VAT number')).height),
      );
      expect(registered(registry), contains('VAT number'));

      f.company.set(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(shellOf('VAT number'), findsOneWidget, reason: 'still folding');
      final closing = tester.getTopLeft(shellOf('Nickname')).dy - nicknameAt;
      expect(closing, inExclusiveRange(0, open));
      await tester.pumpAndSettle();
      expect(shellOf('VAT number'), findsNothing);
      expect(registered(registry), isNot(contains('VAT number')));
      expect(tester.getTopLeft(shellOf('Nickname')).dy, nicknameAt);
    });

    testWidgets('under reduced motion the field goes and comes at once', (
      tester,
    ) async {
      final form = accountForm();
      addTearDown(form.dispose);
      await pumpForm(tester, form, reduceMotion: true);
      final f = Account(form.scope);

      f.company.set(true);
      await tester.pump();
      expect(shellOf('VAT number'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);

      f.company.set(false);
      await tester.pump();
      expect(shellOf('VAT number'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a field hidden while it has focus gives it up at once', (
      tester,
    ) async {
      final form = accountForm();
      addTearDown(form.dispose);
      await pumpForm(tester, form);
      final f = Account(form.scope)..company.set(true);
      await tester.pumpAndSettle();

      final vat = find.descendant(
        of: shellOf('VAT number'),
        matching: find.byType(EditableText),
      );
      await tester.tap(vat);
      await tester.pump();
      expect(tester.widget<EditableText>(vat).focusNode.hasFocus, isTrue);

      f.company.set(false);
      await tester.pump();
      expect(shellOf('VAT number'), findsOneWidget, reason: 'still folding');
      expect(tester.widget<EditableText>(vat).focusNode.hasFocus, isFalse);
      await tester.pumpAndSettle();
    });

    testWidgets('only the field whose visibility moved is bound again', (
      tester,
    ) async {
      final form = accountForm();
      addTearDown(form.dispose);
      final recorder = _Recorder();
      await pumpForm(tester, form, binder: recorder);
      recorder.binds.clear();

      Account(form.scope).company.set(true);
      await tester.pumpAndSettle();
      expect(recorder.binds.toSet(), {'vat'});
    });
  });

  group('required from the rules', () {
    testWidgets('marks the field without a required flag at the call site', (
      tester,
    ) async {
      final form = accountForm();
      addTearDown(form.dispose);
      final recorder = _Recorder();
      await pumpForm(tester, form, binder: recorder);

      expect(tester.widget<FieldShell>(shellOf('Name')).required, isTrue);
      expect(tester.widget<FieldShell>(shellOf('Nickname')).required, isFalse);
      expect(recorder.required['name'], isTrue);
      expect(recorder.required['nickname'], isFalse);
      bool marked(String label) => tester
          .widgetList<FieldRequiredMarker>(
            find.descendant(
              of: shellOf(label),
              matching: find.byType(FieldRequiredMarker),
            ),
          )
          .any((marker) => marker.required);
      expect(marked('Name'), isTrue);
      expect(marked('Nickname'), isFalse);
    });

    testWidgets('a hidden field is not required; shown, it is', (tester) async {
      final form = accountForm();
      addTearDown(form.dispose);
      final recorder = _Recorder();
      await pumpForm(tester, form, binder: recorder);
      expect(recorder.required['vat'], isFalse);

      Account(form.scope).company.set(true);
      await tester.pumpAndSettle();
      expect(recorder.required['vat'], isTrue);
      expect(tester.widget<FieldShell>(shellOf('VAT number')).required, isTrue);
    });
  });

  group('a read-only form', () {
    List<Widget> phones(Account f) => [
      RecordListField<RecordScope>(
        f.phones,
        label: 'Phones',
        item: (r) => Field(r.text('number'), label: 'Number'),
      ),
    ];

    Future<ValueFormController<Values>> withPhones(
      WidgetTester tester, {
      required bool readOnly,
    }) async {
      final form = accountForm();
      addTearDown(form.dispose);
      Account(form.scope).phones
        ..add()
        ..add();
      await pumpForm(tester, form, readOnly: readOnly, children: phones);
      return form;
    }

    testWidgets('an editable one offers add and remove', (tester) async {
      await withPhones(tester, readOnly: false);
      expect(find.byType(AddRowButton), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));
    });

    testWidgets('hides a record list’s add and remove', (tester) async {
      await withPhones(tester, readOnly: true);
      expect(find.byType(AddRowButton), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      for (final number in tester.widgetList<EditableText>(
        find.descendant(
          of: shellOf('Phones'),
          matching: find.byType(EditableText),
        ),
      )) {
        expect(number.readOnly, isTrue);
      }
    });

    for (final (name, state) in [
      ('read-only', const FieldStateScope(readOnly: true, child: _Rows())),
      ('disabled', const FieldStateScope(enabled: false, child: _Rows())),
    ]) {
      testWidgets('a Repeater under a $name scope offers no add, remove or '
          'reorder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(irisTheme.tokens),
            supportedLocales: AdminLocalizations.supportedLocales,
            localizationsDelegates: AdminLocalizations.localizationsDelegates,
            home: Scaffold(body: state),
          ),
        );
        expect(find.text('Row 1'), findsOneWidget);
        expect(find.byType(AddRowButton), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
        expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
      });
    }
  });
}

class _Rows extends StatelessWidget {
  const _Rows();

  @override
  Widget build(BuildContext context) => Repeater(
    itemCount: 2,
    itemBuilder: (_, i) => Text('Row ${i + 1}'),
    onAdd: () {},
    onRemove: (_) {},
    onReorder: (_, _) {},
  );
}
