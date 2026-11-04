import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

extension type Contact(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get notes => _s.text('notes');
  ValueCell<bool> get hasEmail => _s.boolean('hasEmail');
}

ValueFormController<String> contactForm() => ValueFormController<String>(
  read: (s) => Contact(s).name.value,
  write: (s, v) => Contact(s).name.set(v),
  initial: 'Ada',
  rules: (s) => [
    FieldRules(Contact(s).email, visibleWhen: () => Contact(s).hasEmail.value),
  ],
);

/// [group] in a window [width] wide, with no padding around it.
Future<void> pumpGroup(
  WidgetTester tester,
  double width,
  ValueFormController<String> form,
  Widget group,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      home: Scaffold(
        body: ValueForm(
          controller: form,
          child: ListView(children: [group]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect shellRect(WidgetTester tester, String label) => tester.getRect(
  find.byWidgetPredicate((w) => w is FieldShell && w.label == label),
);

void main() {
  late ValueFormController<String> form;
  setUp(() {
    form = contactForm();
    Contact(form.scope).hasEmail.set(true);
  });
  tearDown(() => form.dispose());

  Widget twoColumns() {
    final f = Contact(form.scope);
    return FieldGroup(
      title: 'Contact',
      columns: const FormColumns(compact: 1, medium: 2),
      children: [
        Field(f.name, label: 'Name'),
        Field(f.email, label: 'Email'),
        FormGridItem(
          fullWidth: true,
          child: Field(f.notes, label: 'Notes', minLines: 3, maxLines: 6),
        ),
      ],
    );
  }

  testWidgets('720 wide, two fields sit side by side', (tester) async {
    await pumpGroup(tester, 720, form, twoColumns());
    final name = shellRect(tester, 'Name');
    final email = shellRect(tester, 'Email');
    final notes = shellRect(tester, 'Notes');
    expect(name.top, email.top);
    expect(name.left, 0);
    expect(name.width, (720 - AdminSpacing.xl) / 2);
    expect(email.left, name.right + AdminSpacing.xl);
    expect(email.right, 720);
    expect(notes.left, 0);
    expect(notes.width, 720);
    // Every field under the form keeps its message line, whether a rule
    // names it or not, and the grid's gap gives up the 8 above that line.
    expect(email.height, name.height);
    expect(notes.top, email.bottom + AdminSpacing.lg);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390 wide, they stack', (tester) async {
    await pumpGroup(tester, 390, form, twoColumns());
    final name = shellRect(tester, 'Name');
    final email = shellRect(tester, 'Email');
    expect(name.width, 390);
    expect(email.left, name.left);
    expect(email.width, 390);
    expect(email.top, name.bottom + AdminSpacing.lg);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boxed, the grid follows the card’s inner width', (tester) async {
    final f = Contact(form.scope);
    // 616 wide, less the card's border and padding: 582, a compact grid.
    await pumpGroup(
      tester,
      616,
      form,
      FieldGroup(
        boxed: true,
        columns: const FormColumns(compact: 1, medium: 2),
        children: [
          Field(f.name, label: 'Name'),
          Field(f.email, label: 'Email'),
        ],
      ),
    );
    expect(shellRect(tester, 'Email').left, shellRect(tester, 'Name').left);
  });

  testWidgets('without columns, a child laid out zero tall takes no gap', (
    tester,
  ) async {
    final f = Contact(form.scope);
    await pumpGroup(
      tester,
      390,
      form,
      FieldGroup(
        spacing: 20,
        children: [
          Field(f.name, label: 'Name'),
          const SizedBox.shrink(),
          Field(f.email, label: 'Email'),
        ],
      ),
    );
    expect(
      shellRect(tester, 'Email').top,
      shellRect(tester, 'Name').bottom + 20,
    );
  });

  testWidgets('a field its rules hide gives up its column', (tester) async {
    final f = Contact(form.scope);
    await pumpGroup(
      tester,
      720,
      form,
      FieldGroup(
        columns: const FormColumns(compact: 1, medium: 2),
        children: [
          Field(f.name, label: 'Name'),
          Field(f.email, label: 'Email'),
          Field(f.notes, label: 'Notes'),
        ],
      ),
    );
    final name = shellRect(tester, 'Name');
    expect(shellRect(tester, 'Notes').top, greaterThan(name.bottom));

    f.hasEmail.set(false);
    await tester.pumpAndSettle();
    expect(find.text('Email'), findsNothing);
    final notes = shellRect(tester, 'Notes');
    expect(notes.top, name.top);
    expect(notes.left, name.right + AdminSpacing.xl);
  });
}
