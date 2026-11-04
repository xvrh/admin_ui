/// The shape of an outside project's edit screen, end to end over the public
/// API only: a DTO with a record list, loaded, edited, discarded, refused and
/// saved through a [ValueFormController] and a [ValueForm].
library;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class Invoice {
  final String customer;
  final String email;
  final List<Line> lines;

  const Invoice({
    required this.customer,
    required this.email,
    required this.lines,
  });
}

class Line {
  final String item;
  final String amount;

  const Line(this.item, this.amount);
}

extension type InvoiceFields(FormScope _s) {
  ValueCell<String> get customer => _s.text('customer');
  ValueCell<String> get email => _s.text('email');
  RecordListCell<LineFields> get lines =>
      _s.recordList('lines', build: LineFields.new);

  Invoice read() => Invoice(
    customer: customer.value,
    email: email.value,
    lines: [for (final l in lines.elements) Line(l.item.value, l.amount.value)],
  );

  void write(Invoice invoice) {
    customer.set(invoice.customer);
    email.set(invoice.email);
    while (lines.elements.length > invoice.lines.length) {
      lines.removeAt(lines.elements.length - 1);
    }
    while (lines.elements.length < invoice.lines.length) {
      lines.add();
    }
    for (final (i, line) in invoice.lines.indexed) {
      lines.elements[i]
        ..item.set(line.item)
        ..amount.set(line.amount);
    }
  }
}

extension type LineFields(RecordScope _e) {
  ValueCell<String> get item => _e.text('item');
  ValueCell<String> get amount => _e.text('amount');
}

const loaded = Invoice(
  customer: 'Harbor Bakery',
  email: 'billing@harbor.test',
  lines: [Line('Hosting', '120'), Line('Support', '80')],
);

/// The form over a fresh scope; each submitted value lands in [submitted],
/// and [refuse], while set, is what the server throws instead.
class Harness {
  final submitted = <Invoice>[];
  Object? refuse;

  late final form = ValueFormController<Invoice>(
    read: (s) => InvoiceFields(s).read(),
    write: (s, invoice) => InvoiceFields(s).write(invoice),
    rules: (s) {
      final f = InvoiceFields(s);
      return [
        FieldRules(f.customer, validators: [Validators.required()]),
        FieldRules(
          f.email,
          validators: [Validators.required(), Validators.email()],
        ),
        for (final line in f.lines.elements)
          FieldRules(line.item, validators: [Validators.required()]),
      ];
    },
    onSubmit: (invoice) async {
      if (refuse case final error?) {
        refuse = null;
        throw error;
      }
      submitted.add(invoice);
    },
  );

  InvoiceFields get fields => InvoiceFields(form.scope);
}

Future<Harness> pumpScreen(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(900, 1000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final h = Harness();
  addTearDown(h.form.dispose);
  final f = h.fields;
  await t.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ValueForm(
          controller: h.form,
          child: Column(
            children: [
              FormSaveBar(controller: h.form, showDiscard: true),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Field(f.customer, label: 'Customer'),
                    Field(f.email, label: 'Email'),
                    RecordListField(
                      f.lines,
                      label: 'Lines',
                      addLabel: 'Add line',
                      item: (LineFields l) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Field(l.item, label: 'Item')),
                          Expanded(child: Field(l.amount, label: 'Amount')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  // As a screen does once its record has loaded.
  h.form.seed(loaded);
  await t.pumpAndSettle();
  return h;
}

AdminLocalizations l10nOf(WidgetTester t) =>
    t.element(find.byType(ValueForm)).adminL10n;

Finder shellOf(String label) =>
    find.byWidgetPredicate((w) => w is FieldShell && w.label == label);

Finder inputOf(String label) =>
    find.descendant(of: shellOf(label), matching: find.byType(EditableText));

bool hasFocus(WidgetTester t, Finder input) =>
    t.widget<EditableText>(input).focusNode.hasFocus;

List<(String, String)> linesOf(Invoice invoice) => [
  for (final l in invoice.lines) (l.item, l.amount),
];

void main() {
  testWidgets('edits and rows make it dirty, and Discard restores them', (
    t,
  ) async {
    final h = await pumpScreen(t);
    final l10n = l10nOf(t);
    expect(h.form.status, FormStatus.clean);
    expect(find.text('Hosting'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);

    await t.enterText(inputOf('Customer'), 'Harbor Bakery Ltd');
    await t.pump();
    expect(find.text(l10n.unsavedChanges), findsOneWidget);

    // A row removed, and another added in its place.
    h.fields.lines.removeAt(1);
    await t.pumpAndSettle();
    await t.tap(find.text('Add line'));
    await t.pumpAndSettle();
    await t.enterText(inputOf('Item').last, 'Training');
    await t.pump();
    expect(linesOf(h.form.value), [('Hosting', '120'), ('Training', '')]);

    await t.tap(find.text(l10n.shell.discard));
    await t.pumpAndSettle();
    expect(h.form.status, FormStatus.clean);
    expect(h.form.value.customer, 'Harbor Bakery');
    expect(linesOf(h.form.value), [('Hosting', '120'), ('Support', '80')]);
    expect(find.text('Harbor Bakery'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('Training'), findsNothing);
    expect(find.text(l10n.unsavedChanges), findsNothing);
  });

  testWidgets('a refused save reveals and focuses; the server’s errors map '
      'onto the fields; a save rebases', (t) async {
    final h = await pumpScreen(t);
    final l10n = l10nOf(t);

    // Invalid: the message shows at once, and the shortcut takes focus to
    // the field instead of saving.
    await t.enterText(inputOf('Customer'), '');
    await t.tap(inputOf('Email'));
    await t.pump();
    expect(find.text(l10n.fields.valueRequired), findsOneWidget);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyS);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(hasFocus(t, inputOf('Customer')), isTrue);
    expect(h.submitted, isEmpty);

    // A row added blank has its own rule: the refusal focuses it.
    await t.enterText(inputOf('Customer'), 'Harbor Bakery Ltd');
    await t.tap(find.text('Add line'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(h.submitted, isEmpty);
    expect(hasFocus(t, inputOf('Item').last), isTrue);
    expect(find.text(l10n.fields.valueRequired), findsOneWidget);
    await t.enterText(inputOf('Item').last, 'Training');
    await t.pump();

    // The server refuses the email: its message in place and focused, the
    // bar counting it, the reason kept as the submit error.
    h.refuse = FormSubmitException(
      message: 'Rejected by billing',
      fieldErrors: {h.fields.email.id: 'Unknown billing address'},
    );
    await h.form.submit();
    await t.pumpAndSettle();
    expect(h.form.status, FormStatus.error);
    expect(h.form.submitError, 'Rejected by billing');
    expect(find.text('Unknown billing address'), findsOneWidget);
    expect(find.text(l10n.shell.fieldsNeedAttention(1)), findsOneWidget);
    expect(hasFocus(t, inputOf('Email')), isTrue);

    // Editing the field clears the server's word on it.
    await t.enterText(inputOf('Email'), 'accounts@harbor.test');
    await t.pump();
    expect(find.text('Unknown billing address'), findsNothing);

    await h.form.submit();
    await t.pumpAndSettle();
    expect(h.form.status, FormStatus.submitted);
    expect(h.submitted.single.customer, 'Harbor Bakery Ltd');
    expect(h.submitted.single.email, 'accounts@harbor.test');
    expect(linesOf(h.submitted.single), [
      ('Hosting', '120'),
      ('Support', '80'),
      ('Training', ''),
    ]);

    // The saved value is the new baseline.
    await t.enterText(inputOf('Customer'), 'Someone else');
    h.fields.lines.removeAt(2);
    await t.pumpAndSettle();
    h.form.reset();
    await t.pumpAndSettle();
    expect(h.form.status, FormStatus.clean);
    expect(find.text('Harbor Bakery Ltd'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
  });
}
