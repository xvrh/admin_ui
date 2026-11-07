import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Contact {
  final String name;
  final String email;
  final bool vip;
  final List<Phone> phones;

  const Contact({
    this.name = '',
    this.email = '',
    this.vip = false,
    this.phones = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      other.name == name &&
      other.email == email &&
      other.vip == vip &&
      _samePhones(other.phones, phones);

  @override
  int get hashCode => Object.hash(name, email, vip, Object.hashAll(phones));

  static bool _samePhones(List<Phone> a, List<Phone> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((s) => s);
}

class Phone {
  final String label;
  final String number;

  const Phone(this.label, this.number);

  @override
  bool operator ==(Object other) =>
      other is Phone && other.label == label && other.number == number;

  @override
  int get hashCode => Object.hash(label, number);
}

extension type ContactFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<bool> get vip => _s.boolean('vip');
  ValueCell<String> get notes => _s.text('notes');
  TranslatedCell<String> get title => _s.translated('title');
  AssetRefCell get photo => _s.assetRef('photo');
  RecordListCell<PhoneFields> get phones =>
      _s.recordList('phones', build: PhoneFields.new);

  Contact read() => Contact(
    name: name.value,
    email: email.value,
    vip: vip.value,
    phones: [
      for (final p in phones.elements) Phone(p.label.value, p.number.value),
    ],
  );

  void write(Contact c) {
    name.set(c.name);
    email.set(c.email);
    vip.set(c.vip);
    while (phones.elements.isNotEmpty) {
      phones.removeAt(0);
    }
    for (final p in c.phones) {
      phones.add();
      phones.elements.last
        ..label.set(p.label)
        ..number.set(p.number);
    }
  }
}

extension type PhoneFields(RecordScope _e) {
  ValueCell<String> get label => _e.text('label');
  ValueCell<String> get number => _e.text('number');
}

const ada = Contact(
  name: 'Ada',
  email: 'ada@example.com',
  vip: true,
  phones: [Phone('Office', '1'), Phone('Home', '2')],
);

ValueFormController<Contact> contactForm({
  Contact? initial = ada,
  Future<void> Function(Contact)? onSubmit,
  Iterable<ValidationRule> Function(FormScope)? rules,
  bool requireChanges = true,
  FormScope? scope,
}) => ValueFormController<Contact>(
  scope: scope,
  read: (s) => ContactFields(s).read(),
  write: (s, c) => ContactFields(s).write(c),
  initial: initial,
  onSubmit: onSubmit,
  rules: rules,
  requireChanges: requireChanges,
);

/// Counts [controller]'s notifications.
int Function() countNotifications(ChangeNotifier controller) {
  var count = 0;
  controller.addListener(() => count++);
  return () => count;
}

void main() {
  group('dirty', () {
    test('an edit makes the form dirty, and editing it back clean', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final fields = ContactFields(form.scope);
      expect(form.status, FormStatus.clean);
      expect(form.isDirty, isFalse);

      fields.name.set('Ada L');
      expect(form.status, FormStatus.dirty);
      expect(form.isDirty, isTrue);
      expect(form.hasUnsavedChanges, isTrue);

      fields.name.set('Ada');
      expect(form.status, FormStatus.clean);
      expect(form.isDirty, isFalse);
    });

    test('a translated lane and an asset part are tracked', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final fields = ContactFields(form.scope);

      fields.title.lane('fr').set('Bonjour');
      expect(form.isDirty, isTrue);
      fields.title.lane('fr').set('');
      expect(form.isDirty, isFalse);

      fields.photo.assetId.set('a1');
      expect(form.isDirty, isTrue);
      fields.photo.assetId.set(null);
      expect(form.isDirty, isFalse);
      fields.photo.alt.lane('en').set('A portrait');
      expect(form.isDirty, isTrue);
    });

    test('adding, removing and reordering rows is dirty', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final phones = ContactFields(form.scope).phones;

      phones.add();
      expect(form.isDirty, isTrue, reason: 'a row added');
      phones.removeAt(2);
      expect(form.isDirty, isFalse, reason: 'the added row removed');

      phones.move(0, 1);
      expect(form.isDirty, isTrue, reason: 'two different rows swapped');
      phones.move(0, 1);
      expect(form.isDirty, isFalse, reason: 'swapped back');

      phones.removeAt(0);
      expect(form.isDirty, isTrue, reason: 'a row removed');
      phones.add();
      phones.move(1, 0);
      phones.elements.first
        ..label.set('Office')
        ..number.set('1');
      expect(
        form.isDirty,
        isFalse,
        reason: 'rows count by position: the same values are clean',
      );
    });

    test('a cell first read after seeding joins the baseline as it is', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final notes = ContactFields(form.scope).notes;
      expect(notes.value, '');
      expect(form.isDirty, isFalse);

      notes.set('Met at the fair');
      expect(form.isDirty, isTrue);
      notes.set('');
      expect(form.isDirty, isFalse);
    });

    test('a cell edited before the form hears of it still counts', () {
      final form = contactForm();
      addTearDown(form.dispose);
      // Handed out and set in one go: its first value is the baseline's.
      ContactFields(form.scope).notes.set('Early');
      expect(form.isDirty, isTrue);
    });

    test('notifies only when something observable changes', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final notifications = countNotifications(form);
      final fields = ContactFields(form.scope);

      fields.name.set('A');
      expect(notifications(), 1, reason: 'clean → dirty');
      fields.name.set('Al');
      fields.name.set('Ali');
      expect(notifications(), 1, reason: 'still dirty, nothing else moved');

      final lane = fields.title.lane('en') as TextCell;
      lane.controller.selection = const TextSelection.collapsed(offset: 0);
      expect(notifications(), 1, reason: 'a caret move is no edit');
    });
  });

  group('rules and scopes', () {
    test('per-row rules follow the rows', () {
      final form = contactForm(
        rules: (s) => [
          for (final p in ContactFields(s).phones.elements)
            FieldRules(p.number, validators: [Validators.required()]),
        ],
      );
      addTearDown(form.dispose);
      final phones = ContactFields(form.scope).phones;
      expect(form.allErrors, isEmpty);

      phones.add();
      final id = phones.elements.last.number.id;
      expect(form.allErrors.keys, [id]);
      expect(form.isRequired(id), isTrue);

      phones.removeAt(2);
      expect(form.allErrors, isEmpty);
      expect(form.isRequired(id), isFalse);
    });

    test('a removed row is no longer the form\'s', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final phones = ContactFields(form.scope).phones;
      final removed = phones.elements.first;
      form.setErrors({removed.number.id: 'Unknown number', 'name': 'Taken'});
      phones.removeAt(0);
      expect(form.errors, {'name': 'Taken'}, reason: 'its messages went too');

      // As a text field flushing while it is torn down would.
      final notifications = countNotifications(form);
      removed.number.set('3');
      expect(notifications(), 0);
      phones.add();
      phones.elements.last
        ..label.set('Office')
        ..number.set('1');
      phones.move(1, 0);
      expect(form.isDirty, isFalse, reason: 'the rows match by position');
    });

    test('a sub-scope and a nested list are tracked', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final seo = form.scope.sub('seo');
      seo.text('title').set('Ada');
      expect(form.isDirty, isTrue);
      seo.text('title').set('');
      expect(form.isDirty, isFalse);

      final phones = ContactFields(form.scope).phones;
      final tags = (phones.elements.first as RecordScope).recordList(
        'tags',
        build: (e) => e,
      );
      tags.add();
      expect(form.isDirty, isTrue);
      tags.removeAt(0);
      expect(form.isDirty, isFalse);
    });
  });

  group('seed and reset', () {
    test('seed writes the value and makes it the baseline', () {
      final form = contactForm(initial: null);
      addTearDown(form.dispose);
      expect(form.value, const Contact());
      final notifications = countNotifications(form);

      form.seed(ada);
      expect(form.value, ada);
      expect(form.status, FormStatus.clean);
      expect(form.isDirty, isFalse);
      expect(notifications(), 0, reason: 'clean before, clean after');
    });

    test('reset restores the values and the rows', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final fields = ContactFields(form.scope);
      fields.name.set('Grace');
      fields.vip.set(false);
      fields.phones.removeAt(0);
      fields.phones.add();
      fields.phones.add();
      fields.phones.elements.last.number.set('9');
      fields.notes.set('Lazily read, then edited');
      expect(form.isDirty, isTrue);

      form.reset();
      expect(form.value, ada);
      expect(fields.notes.value, '', reason: 'restored though write skips it');
      expect(form.status, FormStatus.clean);
      expect(form.isDirty, isFalse);
    });

    test('reset without a seed returns to the empty form', () {
      final form = contactForm(initial: null);
      addTearDown(form.dispose);
      final fields = ContactFields(form.scope);
      fields.name.set('New');
      fields.phones.add();

      form.reset();
      expect(form.value, const Contact());
      expect(form.isDirty, isFalse);
    });

    test('a scope of your own is tracked, and outlives the form', () {
      final scope = LocalScope();
      addTearDown(scope.dispose);
      final form = contactForm(scope: scope);
      expect(scope.text('name').value, 'Ada');

      ContactFields(form.scope).name.set('Grace');
      expect(scope.text('name').value, 'Grace');
      expect(form.isDirty, isTrue);

      form.dispose();
      scope.text('name').set('Ada');
      expect(scope.text('name').value, 'Ada');
    });
  });

  group('submit', () {
    test('submits the value and rebases on success', () async {
      final saved = <Contact>[];
      final form = contactForm(onSubmit: (c) async => saved.add(c));
      addTearDown(form.dispose);
      final fields = ContactFields(form.scope);
      expect(form.canSubmit, isFalse, reason: 'nothing to submit yet');

      fields.name.set('Grace');
      expect(form.canSubmit, isTrue);
      final statuses = <FormStatus>[];
      form.addListener(() => statuses.add(form.status));
      await form.submit();

      expect(saved.single.name, 'Grace');
      expect(statuses, [FormStatus.submitting, FormStatus.submitted]);
      expect(form.isDirty, isFalse);
      expect(form.canSubmit, isFalse);

      fields.name.set('Ada');
      expect(form.status, FormStatus.dirty, reason: 'Grace is the baseline');
      form.reset();
      expect(fields.name.value, 'Grace');
    });

    test('a clean form submits only without requireChanges', () async {
      var calls = 0;
      final form = contactForm(
        initial: null,
        requireChanges: false,
        onSubmit: (_) async => calls++,
      );
      addTearDown(form.dispose);
      expect(form.canSubmit, isTrue);
      await form.submit();
      expect(calls, 1);
      expect(form.status, FormStatus.submitted);

      final strict = contactForm(onSubmit: (_) async => calls++);
      addTearDown(strict.dispose);
      await strict.submit();
      expect(calls, 1);
    });

    test('a FormSubmitException maps its message and field errors', () async {
      final form = contactForm(
        onSubmit: (_) async => throw const FormSubmitException(
          message: 'The server refused',
          fieldErrors: {'email': 'Already used'},
        ),
      );
      addTearDown(form.dispose);
      final fields = ContactFields(form.scope);
      fields.email.set('grace@example.com');
      final reveals = form.revealRequest;

      await form.submit();
      expect(form.status, FormStatus.error);
      expect(form.submitError, 'The server refused');
      expect(form.errors, {'email': 'Already used'});
      expect(form.revealRequest, reveals + 1);
      expect(form.canSubmit, isFalse, reason: 'a message is showing');

      fields.email.set('grace@example.org');
      expect(form.errors, isEmpty, reason: 'the next edit clears it');
      expect(form.status, FormStatus.dirty);
      expect(form.canSubmit, isTrue);
    });

    test('any other exception is kept as the failure, not reported', () async {
      final reported = <FlutterErrorDetails>[];
      final onError = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = onError);
      final offline = Exception('Connection refused');
      final form = contactForm(onSubmit: (_) async => throw offline);
      addTearDown(form.dispose);
      ContactFields(form.scope).name.set('Grace');

      await form.submit();
      expect(form.status, FormStatus.error);
      expect(form.submitError, isNull);
      expect(form.submitFailure, same(offline));
      expect(form.hasUnsavedChanges, isTrue);
      expect(form.isDirty, isTrue);
      expect(reported, isEmpty);

      form.reset();
      expect(form.submitFailure, isNull);
    });

    test('an Error is a bug in the save: kept, and reported', () async {
      final reported = <FlutterErrorDetails>[];
      final onError = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = onError);
      final form = contactForm(onSubmit: (_) async => throw StateError('bug'));
      addTearDown(form.dispose);
      ContactFields(form.scope).name.set('Grace');

      await form.submit();
      expect(form.status, FormStatus.error);
      expect(form.submitFailure, isA<StateError>());
      expect(reported.single.exception, isA<StateError>());
      expect(reported.single.stack, isNotNull);
    });

    test('setErrors shows server messages until their field is edited', () {
      final form = contactForm();
      addTearDown(form.dispose);
      final fields = ContactFields(form.scope);

      form.setErrors({'name': 'Taken', 'vip': 'Not allowed'});
      expect(form.errors, {'name': 'Taken', 'vip': 'Not allowed'});
      fields.name.set('Other');
      expect(form.errors, {'vip': 'Not allowed'});
      form.setErrors({'vip': null});
      expect(form.errors, isEmpty);
    });
  });
}
