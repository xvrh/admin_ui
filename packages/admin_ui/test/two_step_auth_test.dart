import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/l10n/ar.dart';
import 'package:admin_ui/l10n/fr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

final _iris = AdminTokens.from(palette: irisPalette);

const _code = ValueKey('code');
const _recoveryCode = ValueKey('recovery-code');
const _remember = ValueKey('remember');
const _submit = ValueKey('submit');
const _back = ValueKey('back');
const _toggle = ValueKey('toggle');

const _secret = 'JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP';
const _uri =
    'otpauth://totp/Acme:admin%40example.com?secret=$_secret&issuer=Acme';

/// Hosts [child] in a column [width] wide, in [locale]'s language and
/// direction, with a button to move focus to.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'en',
  double width = 360,
  AdminTokens? tokens,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? _iris),
      locale: Locale(locale),
      supportedLocales: _kitLanguages.locales,
      localizationsDelegates: _kitLanguages.delegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  TextButton(onPressed: () {}, child: const Text('Elsewhere')),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The [EditableText] inside the input keyed [key].
Finder _input(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

EditableText _editable(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(_input(key));

/// Answers the clipboard, handing [onSetData] the text.
void _clipboard(WidgetTester tester, void Function(String text) onSetData) {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      onSetData((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
}

/// What [OneTimeCodeForm.onSubmit] was called with.
typedef _Submitted = ({String code, bool remember, bool isRecoveryCode});

/// A [OneTimeCodeForm] with every key, recording its submits.
OneTimeCodeForm _form(
  List<_Submitted> submitted, {
  bool submitting = false,
  String? errorText,
  bool autoSubmit = false,
  String? rememberLabel,
  bool initialRemember = false,
  bool allowRecoveryCode = false,
  VoidCallback? onBack,
}) => OneTimeCodeForm(
  onSubmit: (code, {required remember, required isRecoveryCode}) => submitted
      .add((code: code, remember: remember, isRecoveryCode: isRecoveryCode)),
  submitting: submitting,
  errorText: errorText,
  autoSubmit: autoSubmit,
  rememberLabel: rememberLabel,
  initialRemember: initialRemember,
  allowRecoveryCode: allowRecoveryCode,
  onBack: onBack,
  codeKey: _code,
  recoveryCodeKey: _recoveryCode,
  rememberKey: _remember,
  submitKey: _submit,
  backKey: _back,
  recoveryToggleKey: _toggle,
);

void main() {
  group('OneTimeCodeForm', () {
    testWidgets('submits the code from the button and from Enter', (
      tester,
    ) async {
      final submitted = <_Submitted>[];
      await _pump(tester, _form(submitted));

      expect(_editable(tester, _code).focusNode.hasPrimaryFocus, isTrue);
      await tester.enterText(_input(_code), '123456');
      await tester.tap(find.byKey(_submit));
      expect(submitted, [
        (code: '123456', remember: false, isRecoveryCode: false),
      ]);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, hasLength(2));
    });

    testWidgets('takes digits only, up to the length, for one-time code '
        'autofill', (tester) async {
      await _pump(tester, _form([]));

      await tester.enterText(_input(_code), ' 12a3-45 6789');
      expect(_editable(tester, _code).controller.text, '123456');
      final field = _editable(tester, _code);
      expect(field.autofillHints, [AutofillHints.oneTimeCode]);
      expect(field.keyboardType, TextInputType.number);
    });

    testWidgets('an empty or short submit says what is missing, until it '
        'is met', (tester) async {
      final submitted = <_Submitted>[];
      await _pump(tester, _form(submitted));

      await tester.tap(find.byKey(_submit));
      await tester.pump();
      expect(submitted, isEmpty);
      expect(find.text('Verification code is required'), findsOneWidget);

      await tester.enterText(_input(_code), '123');
      await tester.pump();
      expect(find.text('The code has 6 digits.'), findsOneWidget);
      await tester.tap(find.byKey(_submit));
      expect(submitted, isEmpty);

      await tester.enterText(_input(_code), '123456');
      await tester.pump();
      expect(find.text('The code has 6 digits.'), findsNothing);
      await tester.tap(find.byKey(_submit));
      expect(submitted.single.code, '123456');
    });

    testWidgets('autoSubmit submits on the last digit, once', (tester) async {
      final submitted = <_Submitted>[];
      await _pump(tester, _form(submitted, autoSubmit: true));

      await tester.enterText(_input(_code), '12345');
      expect(submitted, isEmpty);
      await tester.enterText(_input(_code), '123456');
      expect(submitted.single.code, '123456');
      // Moving the cursor through the same code does not send it again.
      final controller = _editable(tester, _code).controller;
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      expect(submitted, hasLength(1));
    });

    testWidgets('without autoSubmit the last digit waits for the button', (
      tester,
    ) async {
      final submitted = <_Submitted>[];
      await _pump(tester, _form(submitted));
      await tester.enterText(_input(_code), '123456');
      expect(submitted, isEmpty);
    });

    testWidgets('the remember checkbox shows only with a label, and is '
        'submitted', (tester) async {
      final submitted = <_Submitted>[];
      await _pump(tester, _form(submitted));
      expect(find.byKey(_remember), findsNothing);

      await _pump(
        tester,
        _form(submitted, rememberLabel: 'Remember this browser for 30 days'),
      );
      expect(find.text('Remember this browser for 30 days'), findsOneWidget);
      expect(tester.widget<Check>(find.byKey(_remember)).value, isFalse);

      await tester.tap(find.byKey(_remember));
      await tester.pump();
      expect(tester.widget<Check>(find.byKey(_remember)).value, isTrue);
      await tester.enterText(_input(_code), '123456');
      await tester.tap(find.byKey(_submit));
      expect(submitted.single.remember, isTrue);
    });

    testWidgets('initialRemember starts the checkbox ticked', (tester) async {
      final submitted = <_Submitted>[];
      await _pump(
        tester,
        _form(submitted, rememberLabel: 'Remember me', initialRemember: true),
      );
      await tester.enterText(_input(_code), '123456');
      await tester.tap(find.byKey(_submit));
      expect(submitted.single.remember, isTrue);
    });

    testWidgets('a recovery code swaps in for the code, and back', (
      tester,
    ) async {
      final submitted = <_Submitted>[];
      await _pump(tester, _form([]));
      expect(find.byKey(_toggle), findsNothing);

      await _pump(tester, _form(submitted, allowRecoveryCode: true));
      expect(find.text('Use a recovery code'), findsOneWidget);
      await tester.tap(find.byKey(_toggle));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(_code), findsNothing);
      expect(_label('Recovery code'), findsOneWidget);
      expect(find.text('Use your authenticator app'), findsOneWidget);
      final field = _editable(tester, _recoveryCode);
      expect(field.focusNode.hasPrimaryFocus, isTrue);
      expect(field.autofillHints, anyOf(isNull, isEmpty));

      // Any text, of any length.
      await tester.enterText(_input(_recoveryCode), ' q3vt-8kmd-7hzp ');
      expect(field.controller.text, ' q3vt-8kmd-7hzp ');
      await tester.tap(find.byKey(_submit));
      expect(submitted, [
        (code: 'q3vt-8kmd-7hzp', remember: false, isRecoveryCode: true),
      ]);

      await tester.tap(find.byKey(_toggle));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(_recoveryCode), findsNothing);
      expect(_editable(tester, _code).focusNode.hasPrimaryFocus, isTrue);
    });

    testWidgets('an empty recovery code is required', (tester) async {
      final submitted = <_Submitted>[];
      await _pump(tester, _form(submitted, allowRecoveryCode: true));
      await tester.tap(find.byKey(_toggle));
      await tester.pump();
      await tester.tap(find.byKey(_submit));
      await tester.pump();
      expect(submitted, isEmpty);
      expect(find.text('Recovery code is required'), findsOneWidget);
    });

    testWidgets('the back link shows only with onBack', (tester) async {
      var back = 0;
      await _pump(tester, _form([]));
      expect(find.byKey(_back), findsNothing);

      await _pump(tester, _form([], onBack: () => back++));
      expect(find.text('Back to sign in'), findsOneWidget);
      await tester.tap(find.byKey(_back));
      expect(back, 1);
    });

    testWidgets('a refusal shows under the field for the code it was about, '
        'and comes back with the next one', (tester) async {
      final submitted = <_Submitted>[];
      const refused = 'That code is not valid.';
      Future<void> answer({required bool submitting, String? error}) => _pump(
        tester,
        _form(
          submitted,
          submitting: submitting,
          errorText: error,
          allowRecoveryCode: true,
        ),
      );

      await answer(submitting: false);
      await tester.enterText(_input(_code), '111111');
      await tester.tap(find.byKey(_submit));
      await answer(submitting: true);
      expect(_isEnabled(tester), isFalse);
      await answer(submitting: false, error: refused);
      await tester.pump();
      expect(find.text(refused), findsOneWidget);
      final field = _editable(tester, _code);
      expect(field.focusNode.hasPrimaryFocus, isTrue);
      expect(
        field.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 6),
      );

      // Edited, the message is not about it any more.
      await tester.enterText(_input(_code), '222222');
      await tester.pump();
      expect(find.text(refused), findsNothing);

      // The same message again, for the next code.
      await tester.tap(find.byKey(_submit));
      await answer(submitting: true, error: refused);
      expect(find.text(refused), findsNothing);
      await answer(submitting: false, error: refused);
      expect(find.text(refused), findsOneWidget);

      // Not about the recovery code.
      await tester.tap(find.byKey(_toggle));
      await tester.pump();
      expect(find.text(refused), findsNothing);
    });

    testWidgets('submitting disables the field, the checkbox and the links', (
      tester,
    ) async {
      final submitted = <_Submitted>[];
      await _pump(
        tester,
        _form(
          submitted,
          submitting: true,
          rememberLabel: 'Remember me',
          allowRecoveryCode: true,
          onBack: () {},
        ),
      );
      expect(_isEnabled(tester), isFalse);
      expect(tester.widget<Check>(find.byKey(_remember)).onChanged, isNull);
      expect(tester.widget<Button>(find.byKey(_toggle)).onPressed, isNull);
      expect(tester.widget<Button>(find.byKey(_back)).onPressed, isNull);
      expect(tester.widget<Button>(find.byKey(_submit)).loading, isTrue);
      await tester.tap(find.byKey(_submit), warnIfMissed: false);
      expect(submitted, isEmpty);
    });

    for (final theme in adminThemes) {
      testWidgets('${theme.name}: the code is monospace, at the control '
          'height', (tester) async {
        final source = theme.tokens;
        final tokens = AdminTokens.from(
          palette: source.palette,
          radii: source.radii,
          sizes: source.sizes,
        );
        await _pump(tester, _form([]), tokens: tokens);
        final style = _editable(tester, _code).style;
        expect(style.fontFamily, tokens.typography.spec.monoFontFamily);
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        final decorator = find.descendant(
          of: find.byKey(_code),
          matching: find.byType(InputDecorator),
        );
        expect(tester.getSize(decorator).height, tokens.sizes.medium);
      });
    }

    testWidgets('right to left, the code still reads left to right', (
      tester,
    ) async {
      await _pump(
        tester,
        _form([], rememberLabel: 'تذكرني', allowRecoveryCode: true),
        locale: 'ar',
      );
      expect(_editable(tester, _code).textDirection, TextDirection.ltr);
      expect(_label('رمز التحقق'), findsOneWidget);
      expect(tester.widget<Button>(find.byKey(_submit)).label, 'تحقق');
      expect(
        tester.widget<Button>(find.byKey(_toggle)).label,
        'استخدام رمز استرداد',
      );

      // The label and the checkbox stand at the right.
      final field = tester.getRect(_input(_code));
      final label = tester.getRect(
        find.descendant(of: _label('رمز التحقق'), matching: find.byType(Text)),
      );
      expect(label.right, greaterThan(field.center.dx));
      final remember = tester.getRect(find.text('تذكرني'));
      expect(remember.left, greaterThan(field.center.dx));

      await tester.tap(find.byKey(_submit));
      await tester.pump();
      expect(find.text('حقل ”رمز التحقق“ مطلوب'), findsOneWidget);
      await tester.enterText(_input(_code), '12');
      await tester.pump();
      expect(find.textContaining('يتكون الرمز من'), findsOneWidget);
    });
  });

  group('AuthenticatorSetupView', () {
    const qr = ValueKey('qr');
    const cantScan = ValueKey('cantScan');
    const secret = ValueKey('secret');
    const copy = ValueKey('copy');
    const cancel = ValueKey('cancel');

    AuthenticatorSetupView view(
      List<String> submitted, {
      VoidCallback? onCancel,
      bool submitting = false,
      String? errorText,
      bool showsSecret = false,
    }) => AuthenticatorSetupView(
      uri: _uri,
      secret: _secret,
      onSubmit: submitted.add,
      onCancel: onCancel,
      submitting: submitting,
      errorText: errorText,
      initiallyShowsSecret: showsSecret,
      qrKey: qr,
      cantScanKey: cantScan,
      secretKey: secret,
      copySecretKey: copy,
      codeKey: _code,
      submitKey: _submit,
      cancelKey: cancel,
    );

    testWidgets('shows the URI as a QR code, and the key behind a link', (
      tester,
    ) async {
      await _pump(tester, view([]));
      expect(tester.widget<QrCodeView>(find.byKey(qr)).data, _uri);
      expect(
        tester.widget<Button>(find.byKey(cantScan)).label,
        'Can’t scan the code?',
      );
      expect(find.byKey(secret), findsNothing);

      await tester.tap(find.byKey(cantScan));
      await tester.pump();
      expect(find.byKey(cantScan), findsNothing);
      final key = tester.widget<SelectableText>(find.byKey(secret));
      expect(key.data, 'JBSW Y3DP EHPK 3PXP JBSW Y3DP EHPK 3PXP');
      expect(key.textDirection, TextDirection.ltr);
      expect(find.text('Enter this key in your app instead.'), findsOneWidget);
    });

    testWidgets('with initiallyShowsSecret, shows the key without the link', (
      tester,
    ) async {
      await _pump(tester, view([], showsSecret: true));
      expect(find.byKey(secret), findsOneWidget);
      expect(find.byKey(cantScan), findsNothing);
    });

    testWidgets('copies the key without its spaces', (tester) async {
      String? copied;
      _clipboard(tester, (text) => copied = text);
      await _pump(
        tester,
        AuthenticatorSetupView(
          uri: _uri,
          secret: 'jbsw y3dp ehpk 3pxp',
          onSubmit: (_) {},
          initiallyShowsSecret: true,
          copySecretKey: copy,
          secretKey: secret,
        ),
      );
      expect(
        tester.widget<SelectableText>(find.byKey(secret)).data,
        'jbsw y3dp ehpk 3pxp',
      );
      await tester.tap(find.byKey(copy));
      await tester.pump();
      expect(copied, 'jbswy3dpehpk3pxp');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('submits a whole code, and marks an empty one', (tester) async {
      final submitted = <String>[];
      await _pump(tester, view(submitted));

      await tester.tap(find.byKey(_submit));
      await tester.pump();
      expect(submitted, isEmpty);
      expect(find.text('Verification code is required'), findsOneWidget);

      await tester.enterText(_input(_code), '654321');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, ['654321']);
    });

    testWidgets('a refusal shows under the field', (tester) async {
      await _pump(tester, view([], errorText: 'That code is not valid.'));
      expect(find.text('That code is not valid.'), findsOneWidget);
      await tester.enterText(_input(_code), '1');
      await tester.pump();
      expect(find.text('That code is not valid.'), findsNothing);
    });

    testWidgets('cancel shows only with onCancel, and waits for a submit', (
      tester,
    ) async {
      var cancelled = 0;
      await _pump(tester, view([]));
      expect(find.byKey(cancel), findsNothing);

      await _pump(tester, view([], onCancel: () => cancelled++));
      expect(tester.widget<Button>(find.byKey(cancel)).label, 'Cancel');
      await tester.tap(find.byKey(cancel));
      expect(cancelled, 1);

      await _pump(
        tester,
        view([], onCancel: () => cancelled++, submitting: true),
      );
      expect(tester.widget<Button>(find.byKey(cancel)).onPressed, isNull);
    });

    testWidgets('right to left, the key and the code read left to right', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, view([], showsSecret: true), locale: 'ar');
      expect(
        tester.widget<SelectableText>(find.byKey(secret)).textDirection,
        TextDirection.ltr,
      );
      expect(_editable(tester, _code).textDirection, TextDirection.ltr);
      // The copy button at the end, the left.
      expect(
        tester.getCenter(find.byKey(copy)).dx,
        lessThan(tester.getCenter(find.byKey(secret)).dx),
      );
      expect(find.bySemanticsLabel('رمز QR لتطبيق المصادقة'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('RecoveryCodesView', () {
    const codesKey = ValueKey('codes');
    const copy = ValueKey('copy');
    const saved = ValueKey('saved');
    const done = ValueKey('done');
    const codes = ['q3vt-8kmd', '7hzp-2wce', 'n9rx-4fjb', 'c5ly-6tgh'];

    RecoveryCodesView view(VoidCallback onDone) => RecoveryCodesView(
      codes: codes,
      onDone: onDone,
      description: 'Each code signs you in once.',
      codesKey: codesKey,
      copyKey: copy,
      savedKey: saved,
      doneKey: done,
    );

    testWidgets('shows every code, and copies them one per line', (
      tester,
    ) async {
      String? copied;
      _clipboard(tester, (text) => copied = text);
      await _pump(tester, view(() {}));
      for (final code in codes) {
        expect(find.text(code), findsOneWidget);
      }
      expect(find.text('Each code signs you in once.'), findsOneWidget);
      expect(find.text('Copy all'), findsWidgets);

      await tester.tap(find.byKey(copy));
      await tester.pump();
      expect(copied, 'q3vt-8kmd\n7hzp-2wce\nn9rx-4fjb\nc5ly-6tgh');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('done waits for the codes to be saved', (tester) async {
      var finished = 0;
      await _pump(tester, view(() => finished++));

      expect(tester.widget<Button>(find.byKey(done)).onPressed, isNull);
      expect(tester.widget<Button>(find.byKey(done)).label, 'Continue');
      await tester.tap(find.byKey(done), warnIfMissed: false);
      expect(finished, 0);

      expect(find.text('I have saved these codes'), findsOneWidget);
      await tester.tap(find.byKey(saved));
      await tester.pump();
      await tester.tap(find.byKey(done));
      expect(finished, 1);

      // Unticked, it waits again.
      await tester.tap(find.byKey(saved));
      await tester.pump();
      expect(tester.widget<Button>(find.byKey(done)).onPressed, isNull);
    });

    testWidgets('two codes to a line where wide, one where narrow', (
      tester,
    ) async {
      await _pump(tester, view(() {}));
      final first = tester.getRect(find.text(codes[0]));
      final second = tester.getRect(find.text(codes[1]));
      expect(second.top, first.top);
      expect(second.left, greaterThan(first.right));
      final third = tester.getRect(find.text(codes[2]));
      expect(third.top, greaterThan(first.top));

      await _pump(tester, view(() {}), width: 200);
      final narrowFirst = tester.getRect(find.text(codes[0]));
      final narrowSecond = tester.getRect(find.text(codes[1]));
      expect(narrowSecond.top, greaterThan(narrowFirst.top));
      expect(tester.takeException(), isNull);
    });

    testWidgets('right to left, the first code stands at the right', (
      tester,
    ) async {
      await _pump(tester, view(() {}), locale: 'ar');
      final first = tester.getRect(find.text(codes[0]));
      final second = tester.getRect(find.text(codes[1]));
      expect(first.left, greaterThan(second.right));
      expect(
        tester.widget<Text>(find.text(codes[0])).textDirection,
        TextDirection.ltr,
      );
      expect(find.text('لقد حفظت هذه الرموز'), findsOneWidget);
      expect(tester.widget<Button>(find.byKey(done)).label, 'المتابعة');
    });
  });

  group('in a dialog and on the sign-in card', () {
    final views = <String, Widget>{
      'OneTimeCodeForm': OneTimeCodeForm(
        onSubmit: (_, {required remember, required isRecoveryCode}) {},
        rememberLabel: 'Remember this browser for 30 days',
        allowRecoveryCode: true,
        onBack: () {},
      ),
      'AuthenticatorSetupView': AuthenticatorSetupView(
        uri: _uri,
        secret: _secret,
        onSubmit: (_) {},
        onCancel: () {},
      ),
      'RecoveryCodesView': RecoveryCodesView(
        codes: const ['q3vt-8kmd', '7hzp-2wce', 'n9rx-4fjb'],
        onDone: () {},
      ),
    };

    for (final MapEntry(key: name, value: child) in views.entries) {
      for (final locale in ['en', 'fr', 'ar']) {
        testWidgets('$name sizes itself in a modal ($locale)', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(_iris),
              locale: Locale(locale),
              supportedLocales: _kitLanguages.locales,
              localizationsDelegates: _kitLanguages.delegates,
              home: Scaffold(
                body: Center(
                  child: Modal(
                    title: 'Two-step sign-in',
                    size: ModalSize.small,
                    body: child,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byWidget(child), findsOneWidget);
        });

        testWidgets('$name fits the sign-in card ($locale)', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(_iris),
              locale: Locale(locale),
              supportedLocales: _kitLanguages.locales,
              localizationsDelegates: _kitLanguages.delegates,
              home: AuthScaffold(title: 'Two-step sign-in', child: child),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

/// The labelled field whose label is [label], whatever case the theme
/// draws it in.
Finder _label(String label) =>
    find.byWidgetPredicate((w) => w is LabeledField && w.label == label);

/// Whether the code input takes input.
bool _isEnabled(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(of: find.byKey(_code), matching: find.byType(TextField)),
    )
    .enabled!;
