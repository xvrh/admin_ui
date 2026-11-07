import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _en = AdminLocalizationsEn();
const _fr = AdminLocalizationsFr();

extension type SignUp(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get password => _s.text('password');
  ValueCell<String> get confirm => _s.text('confirm');
  ValueCell<bool> get company => _s.boolean('company');
  ValueCell<String> get vat => _s.text('vat');
  ValueCell<int?> get age => _s.numberOrNull('age');
  TranslatedCell<String> get title => _s.translated('title');
}

typedef Values = ({String name, String email});

ValueFormController<Values> signUp({
  required Iterable<ValidationRule> Function(SignUp f) rules,
  ValidationMode mode = ValidationMode.onEdit,
  Future<void> Function(Values)? onSubmit,
  bool requireChanges = false,
}) => ValueFormController<Values>(
  read: (s) => (name: SignUp(s).name.value, email: SignUp(s).email.value),
  write: (s, v) => SignUp(s)
    ..name.set(v.name)
    ..email.set(v.email),
  rules: (s) => rules(SignUp(s)),
  mode: mode,
  onSubmit: onSubmit,
  requireChanges: requireChanges,
);

/// The form engine's strings, read with sample arguments.
final _strings = <String, String Function(FieldsMessages)>{
  'valueRequired': (m) => m.valueRequired,
  'tooShort(1)': (m) => m.tooShort(1),
  'tooShort(12)': (m) => m.tooShort(12),
  'tooLong(1)': (m) => m.tooLong(1),
  'tooLong(12)': (m) => m.tooLong(12),
  'invalidEmail': (m) => m.invalidEmail,
  'invalidUrl': (m) => m.invalidUrl,
  'invalidFormat': (m) => m.invalidFormat,
  'tooSmall': (m) => m.tooSmall('18'),
  'tooLarge': (m) => m.tooLarge('99'),
  'checking': (m) => m.checking,
  'optionalMarker': (m) => m.optionalMarker,
  'validationSummaryTitle(1)': (m) => m.validationSummaryTitle(1),
  'validationSummaryTitle(3)': (m) => m.validationSummaryTitle(3),
  'jumpToField': (m) => m.jumpToField('Email'),
  'wizardNext': (m) => m.wizardNext,
  'wizardBack': (m) => m.wizardBack,
  'wizardStepBlocked(1)': (m) => m.wizardStepBlocked(1),
  'wizardStepBlocked(3)': (m) => m.wizardStepBlocked(3),
};

void main() {
  test('every string of the engine is in English, French and Arabic', () {
    const ar = AdminLocalizationsAr();
    for (final MapEntry(key: name, value: read) in _strings.entries) {
      final [en, fr, arabic] = [
        for (final l in [_en, _fr, ar]) read(l.fields),
      ];
      for (final text in [en, fr, arabic]) {
        expect(text.trim(), isNotEmpty, reason: name);
      }
      expect(fr, isNot(en), reason: '$name is not translated to French');
      expect(arabic, isNot(en), reason: '$name is not translated to Arabic');
    }
    expect(_en.fields.tooSmall('18'), _en.fields.numberAtLeast('18'));
    expect(_en.fields.validationSummaryTitle(3), '3 fields need fixing');
    expect(_en.fields.optionalMarker, '(optional)');
    expect(_en.fields.fieldMessage('Email', 'Required'), 'Email: Required');
    expect(
      _fr.fields.fieldMessage('E-mail', 'Obligatoire'),
      'E-mail\u00A0: Obligatoire',
    );
  });

  group('Validators', () {
    String? run<V>(
      FieldValidator<V> v,
      V value, [
      AdminLocalizations l = _en,
    ]) => v(value, l);

    test('required fails what is empty, and only that', () {
      final required = Validators.required<Object?>();
      for (final empty in [null, '', '   ', <String>[], <String, int>{}]) {
        expect(run(required, empty), 'Required', reason: '$empty');
      }
      for (final value in [
        'a',
        0,
        false,
        const ['x'],
      ]) {
        expect(run(required, value), isNull, reason: '$value');
      }
      expect(run(required, null, _fr), 'Obligatoire');
      expect(
        run(Validators.required<String>(message: 'Name it'), ''),
        'Name it',
      );
    });

    test('lengths count characters as the user sees them', () {
      expect(
        run(Validators.minLength<String>(3), 'ab'),
        'Enter at least 3 characters',
      );
      expect(
        run(Validators.minLength<String>(1), ''),
        isNull,
        reason: 'empty passes',
      );
      expect(
        run(Validators.minLength<String>(2), '👍🏽'),
        'Enter at least 2 characters',
      );
      expect(run(Validators.maxLength<String>(1), '👍🏽'), isNull);
      expect(
        run(Validators.maxLength<String>(2), 'abc'),
        'Enter at most 2 characters',
      );
      expect(
        run(Validators.maxLength<String>(1), 'ab', _fr),
        'Saisissez au plus 1 caractère',
      );
      expect(run(Validators.maxLength<String?>(1), null), isNull);
    });

    test('pattern, email and url', () {
      final code = Validators.pattern<String>(RegExp(r'^[A-Z]{3}$'));
      expect(run(code, 'ABC'), isNull);
      expect(run(code, 'AB'), 'Enter a value in the expected format');
      expect(run(code, ''), isNull);

      final email = Validators.email<String>();
      expect(run(email, 'ada@example.com'), isNull);
      for (final bad in ['ada', 'ada@example', 'a da@example.com']) {
        expect(run(email, bad), 'Enter a valid email address', reason: bad);
      }
      expect(run(email, 'ada', _fr), 'Saisissez une adresse e-mail valide');

      final url = Validators.url<String?>();
      expect(run(url, 'https://example.com/a'), isNull);
      expect(run(url, null), isNull);
      for (final bad in ['example.com', 'ftp://example.com', 'https://']) {
        expect(run(url, bad), 'Enter a valid web address', reason: bad);
      }
    });

    test('min and max word the bound in the locale', () {
      expect(run(Validators.min<int>(18), 17), 'Enter 18 or more');
      expect(run(Validators.min<int?>(18), null), isNull);
      expect(
        run(Validators.max<double>(1500.5), 2000.0),
        'Enter 1,500.5 or less',
      );
      expect(
        run(Validators.max<double>(1500.5), 2000.0, _fr),
        'Saisissez 1 500,5 ou moins',
      );
      expect(run(Validators.min<int>(0, message: 'No debt'), -1), 'No debt');
    });
  });

  group('modes', () {
    Iterable<ValidationRule> rules(SignUp f) => [
      FieldRules(f.name, validators: [Validators.required()]),
      FieldRules(
        f.email,
        validators: [Validators.required(), Validators.email()],
      ),
    ];

    test('onEdit shows a message once its field is edited', () async {
      final form = signUp(rules: rules);
      addTearDown(form.dispose);
      final f = SignUp(form.scope);
      expect(form.allErrors, {'name': 'Required', 'email': 'Required'});
      expect(form.errors, isEmpty, reason: 'nothing touched yet');
      expect(form.isValid, isTrue);

      f.email.set('ada');
      expect(form.errors, {'email': 'Enter a valid email address'});
      f.email.set('');
      expect(form.errors, {'email': 'Required'}, reason: 'stays shown');

      await form.submit();
      expect(form.errors, {'name': 'Required', 'email': 'Required'});
      expect(form.submitAttempted, isTrue);
      expect(form.firstInvalidField, 'name');
    });

    test('onSubmit shows nothing before a submit attempt', () async {
      final form = signUp(rules: rules, mode: ValidationMode.onSubmit);
      addTearDown(form.dispose);
      final f = SignUp(form.scope);
      f.email.set('ada');
      expect(form.errors, isEmpty);

      await form.submit();
      expect(form.errors, {
        'name': 'Required',
        'email': 'Enter a valid email address',
      });
      f.name.set('Ada');
      expect(form.errors, {
        'email': 'Enter a valid email address',
      }, reason: 'live');
    });

    test('always shows every message at once', () {
      final form = signUp(rules: rules, mode: ValidationMode.always);
      addTearDown(form.dispose);
      expect(form.errors, {'name': 'Required', 'email': 'Required'});
      expect(form.canSubmit, isFalse);
    });

    test('a refused submit calls nothing and asks for a reveal', () async {
      var calls = 0;
      final form = signUp(rules: rules, onSubmit: (_) async => calls++);
      addTearDown(form.dispose);
      final reveals = form.revealRequest;
      await form.submit();
      expect(calls, 0);
      expect(form.status, FormStatus.clean);
      expect(form.revealRequest, reveals + 1);
    });

    test('validate reveals the fields asked for', () async {
      final form = signUp(rules: rules);
      addTearDown(form.dispose);
      expect(await form.validate(fields: ['name']), isFalse);
      expect(form.errors, {'name': 'Required'});
      SignUp(form.scope).name.set('Ada');
      expect(await form.validate(fields: ['name']), isTrue);
      expect(await form.validate(), isFalse);
      expect(form.errors, {'email': 'Required'});
    });

    test('requiredFields follow the rules', () {
      final form = signUp(rules: rules);
      addTearDown(form.dispose);
      expect(form.requiredFields, {'name', 'email'});
      expect(form.isRequired('name'), isTrue);
      expect(form.isRequired('password'), isFalse);
    });

    test('a translated field is checked lane by lane', () {
      final form = signUp(
        rules: (f) => [
          FieldRules(
            f.title,
            validators: [Validators.required()],
            lanes: const ['en', 'fr'],
          ),
        ],
        mode: ValidationMode.always,
      );
      addTearDown(form.dispose);
      final title = SignUp(form.scope).title;
      title.lane('en').set('Hello');
      expect(form.errors, {'title': 'Required'});
      title.lane('fr').set('Bonjour');
      expect(form.errors, isEmpty);
    });

    test('localizations reword the messages, and notify after the build '
        'that set them', () async {
      final form = signUp(rules: rules, mode: ValidationMode.always);
      addTearDown(form.dispose);
      var notified = 0;
      form.addListener(() => notified++);
      form.localizations = _fr;
      expect(form.errors, {'name': 'Obligatoire', 'email': 'Obligatoire'});
      expect(notified, 0);
      await null;
      expect(notified, 1, reason: 'a save bar beside the form rewords too');
      form.localizations = _fr;
      await null;
      expect(notified, 1);
    });
  });

  group('async checks', () {
    late Map<String, Completer<String?>> checks;
    late List<String> asked;

    Future<String?> taken(String email) {
      asked.add(email);
      return (checks[email] = Completer<String?>()).future;
    }

    setUp(() {
      checks = {};
      asked = [];
    });

    ValueFormController<Values> form({
      Future<void> Function(Values)? onSubmit,
    }) => signUp(
      rules: (f) => [
        FieldRules(
          f.email,
          validators: [Validators.email()],
          asyncValidators: [taken],
        ),
      ],
      onSubmit: onSubmit,
    );

    testWidgets('wait for the debounce, and are pending meanwhile', (
      tester,
    ) async {
      final c = form();
      addTearDown(c.dispose);
      final email = SignUp(c.scope).email;

      email.set('a@x.io');
      expect(c.pendingFields, {'email'});
      expect(c.isValidating, isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      email.set('ab@x.io');
      await tester.pump(const Duration(milliseconds: 200));
      expect(asked, isEmpty, reason: 'each edit restarts the debounce');
      await tester.pump(const Duration(milliseconds: 100));
      expect(asked, ['ab@x.io']);
      expect(c.errors, isEmpty, reason: 'no message while pending');

      checks['ab@x.io']!.complete('Already used');
      await tester.pump();
      expect(c.pendingFields, isEmpty);
      expect(c.errors, {'email': 'Already used'});
    });

    testWidgets('a sync failure skips the check', (tester) async {
      final c = form();
      addTearDown(c.dispose);
      SignUp(c.scope).email.set('nope');
      expect(c.pendingFields, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(asked, isEmpty);
      expect(c.errors, {'email': 'Enter a valid email address'});
    });

    testWidgets('an older answer arriving last is dropped', (tester) async {
      final c = form();
      addTearDown(c.dispose);
      final email = SignUp(c.scope).email;

      email.set('old@x.io');
      await tester.pump(const Duration(milliseconds: 300));
      email.set('new@x.io');
      await tester.pump(const Duration(milliseconds: 300));
      expect(asked, ['old@x.io', 'new@x.io']);

      checks['new@x.io']!.complete(null);
      await tester.pump();
      expect(c.pendingFields, isEmpty);
      checks['old@x.io']!.complete('Already used');
      await tester.pump();
      expect(c.errors, isEmpty);
      expect(c.allErrors, isEmpty);
    });

    testWidgets('submit runs a waiting check at once and awaits it', (
      tester,
    ) async {
      final saved = <Values>[];
      final c = form(onSubmit: (v) async => saved.add(v));
      addTearDown(c.dispose);
      SignUp(c.scope).email.set('ada@x.io');

      final submitting = c.submit();
      await tester.pump();
      expect(asked, ['ada@x.io'], reason: 'not after the debounce: now');
      expect(c.status, FormStatus.dirty);
      expect(c.isValidating, isTrue);
      expect(saved, isEmpty);

      checks['ada@x.io']!.complete(null);
      await tester.pump();
      await submitting;
      expect(saved.single.email, 'ada@x.io');
      expect(c.status, FormStatus.submitted);
    });

    testWidgets('an edit made while submitting is checked, and compared '
        'to what was sent', (tester) async {
      final saving = Completer<void>();
      final c = form(onSubmit: (_) => saving.future);
      addTearDown(c.dispose);
      final email = SignUp(c.scope).email;
      email.set('ada@x.io');
      final submitting = c.submit();
      await tester.pump();
      checks['ada@x.io']!.complete(null);
      await tester.pump();
      expect(c.status, FormStatus.submitting);

      email.set('grace@x.io');
      saving.complete();
      await submitting;
      expect(c.status, FormStatus.dirty);
      expect(c.pendingFields, {'email'}, reason: 'its check still runs');
      await tester.pump(const Duration(milliseconds: 300));
      expect(asked, ['ada@x.io', 'grace@x.io']);
      checks['grace@x.io']!.complete('Already used');
      await tester.pump();
      expect(c.errors, {'email': 'Already used'}, reason: 'it was edited');
      expect(c.canSubmit, isFalse);

      email.set('ada@x.io');
      expect(c.status, FormStatus.clean, reason: 'as sent');
      expect(c.pendingFields, isEmpty, reason: 'what was sent was checked');
      expect(c.errors, isEmpty);
    });

    testWidgets('a check that throws passes; only an Error is reported', (
      tester,
    ) async {
      final reported = <Object>[];
      final onError = FlutterError.onError;
      FlutterError.onError = (details) => reported.add(details.exception);
      addTearDown(() => FlutterError.onError = onError);
      final c = signUp(
        rules: (f) => [
          FieldRules(
            f.email,
            asyncValidators: [
              (_) async => throw Exception('Connection refused'),
              (_) async => throw StateError('bug'),
            ],
          ),
        ],
      );
      addTearDown(c.dispose);
      SignUp(c.scope).email.set('ada@x.io');
      expect(await c.validate(), isTrue);
      expect(reported, [isA<StateError>()]);
    });

    testWidgets('submit is refused when the awaited check fails', (
      tester,
    ) async {
      var calls = 0;
      final c = form(onSubmit: (_) async => calls++);
      addTearDown(c.dispose);
      SignUp(c.scope).email.set('ada@x.io');
      final reveals = c.revealRequest;

      final submitting = c.submit();
      await tester.pump();
      checks['ada@x.io']!.complete('Already used');
      await tester.pump();
      await submitting;
      expect(calls, 0);
      expect(c.errors, {'email': 'Already used'});
      expect(c.revealRequest, reveals + 1);
    });

    testWidgets('the seeded value counts as checked', (tester) async {
      final c = form();
      addTearDown(c.dispose);
      c.seed((name: 'Ada', email: 'ada@x.io'));
      await c.submit();
      expect(asked, isEmpty);
      final email = SignUp(c.scope).email;
      email.set('other@x.io');
      email.set('ada@x.io');
      expect(c.pendingFields, isEmpty);
    });

    testWidgets('dispose cancels the waiting checks', (tester) async {
      final c = form();
      SignUp(c.scope).email.set('ada@x.io');
      c.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(asked, isEmpty);
    });
  });

  group('form rules', () {
    test('a cross-field check files its message under its target', () {
      late SignUp f;
      final form = signUp(
        rules: (fields) {
          f = fields;
          return [
            FieldRules(f.password, validators: [Validators.minLength(8)]),
            FormRule(
              watch: [f.password, f.confirm],
              target: f.confirm,
              check: (l10n) =>
                  f.password.value == f.confirm.value ? null : 'No match',
            ),
          ];
        },
      );
      addTearDown(form.dispose);

      f.password.set('correct horse');
      expect(form.allErrors, {'confirm': 'No match'});
      expect(form.errors, isEmpty, reason: 'confirm is not touched yet');
      f.confirm.set('correct');
      expect(form.errors, {'confirm': 'No match'});
      f.confirm.set('correct horse');
      expect(form.errors, isEmpty);
      f.password.set('correct horse battery');
      expect(form.errors, {'confirm': 'No match'}, reason: 'checked again');
    });
  });

  group('visibleWhen', () {
    test('a hidden field is neither validated nor required', () {
      late SignUp f;
      final form = signUp(
        rules: (fields) {
          f = fields;
          return [
            FieldRules(
              f.vat,
              validators: [Validators.required()],
              visibleWhen: () => f.company.value,
            ),
          ];
        },
        mode: ValidationMode.always,
      );
      addTearDown(form.dispose);
      expect(form.isVisible('vat'), isFalse);
      expect(form.isRequired('vat'), isFalse);
      expect(form.allErrors, isEmpty);
      expect(form.hiddenFields, {'vat'});

      f.company.set(true);
      expect(form.isVisible('vat'), isTrue);
      expect(form.isRequired('vat'), isTrue);
      expect(form.errors, {'vat': 'Required'});
    });

    test('with dependsOn, it is asked again only when they change', () {
      final permission = ValueNotifier(false);
      addTearDown(permission.dispose);
      var asked = 0;
      final form = signUp(
        rules: (f) => [
          FieldRules(
            f.age,
            validators: [Validators.min(18)],
            visibleWhen: () {
              asked++;
              return permission.value;
            },
            dependsOn: [permission],
          ),
        ],
      );
      addTearDown(form.dispose);
      final before = asked;
      SignUp(form.scope).name.set('Ada');
      expect(asked, before, reason: 'an unrelated edit');
      expect(form.isVisible('age'), isFalse);

      var notified = 0;
      form.addListener(() => notified++);
      permission.value = true;
      expect(asked, before + 1);
      expect(form.isVisible('age'), isTrue);
      expect(notified, 1);
    });
  });
}
