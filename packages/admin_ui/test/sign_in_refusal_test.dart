// A server's refusal of a sign-in shows under the field it is about: the
// email's under the email, the password's under the password, and only
// what is no field's in the alert above. A field's message is about what
// the field held when it came.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _locked = 'This account is locked';
const _wrong = 'Wrong password';

/// The form, with what its host knows of the last submit.
class _Host extends StatefulWidget {
  final String? email;
  final String? password;

  const _Host({super.key, this.email, this.password});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool submitting = false;
  String? error;
  late String? email = widget.email;
  late String? password = widget.password;
  final submitted = <(String, String)>[];

  /// A submit starts, as a host shows it.
  void submit() => setState(() => submitting = true);

  /// The submit ends, with what the server said.
  void answer({String? error, String? email, String? password}) => setState(() {
    submitting = false;
    this.error = error;
    this.email = email;
    this.password = password;
  });

  @override
  Widget build(BuildContext context) => SignInForm(
    onSignIn: (e, p) => submitted.add((e, p)),
    submitting: submitting,
    errorText: error,
    emailErrorText: email,
    passwordErrorText: password,
  );
}

/// The email's input: the password field is built on an [InputField] too.
Finder get _email => find.byType(InputField).first;
Finder get _password => find.byType(PasswordField);

Future<_HostState> _pump(
  WidgetTester tester, {
  String? email,
  String? password,
  bool fill = true,
}) async {
  final key = GlobalKey<_HostState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 380,
            child: _Host(key: key, email: email, password: password),
          ),
        ),
      ),
    ),
  );
  if (fill) {
    await tester.enterText(_email, 'ada@example.com');
    await tester.enterText(_password, 'hunter22');
    await tester.pump();
  }
  return key.currentState!;
}

/// [text] under [field].
Finder _under(Finder field, String text) =>
    find.descendant(of: field, matching: find.text(text));

bool _focused(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

/// A submit that the server answers with [email] and [password].
Future<void> _refuse(
  WidgetTester tester,
  _HostState host, {
  String? error,
  String? email,
  String? password,
}) async {
  host.submit();
  await tester.pump();
  host.answer(error: error, email: email, password: password);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('a refusal of the password shows under it, and nowhere '
      'else', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, password: _wrong);
    expect(_under(_password, _wrong), findsOneWidget);
    expect(find.text(_wrong), findsOneWidget);
    expect(find.byType(Alert), findsNothing);
  });

  testWidgets('a refusal of the email shows under it', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, email: _locked);
    expect(_under(_email, _locked), findsOneWidget);
    expect(find.text(_locked), findsOneWidget);
    expect(find.byType(Alert), findsNothing);
  });

  testWidgets('what is no field\'s is still an alert above the form', (
    tester,
  ) async {
    final host = await _pump(tester);
    await _refuse(tester, host, error: 'Try again later', password: _wrong);
    expect(
      find.descendant(
        of: find.byType(Alert),
        matching: find.text('Try again later'),
      ),
      findsOneWidget,
    );
    expect(_under(_password, _wrong), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(Alert)).dy,
      lessThan(tester.getTopLeft(_email).dy),
    );
  });

  testWidgets('each field\'s message goes when that field is edited, and '
      'the other\'s stays', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, email: _locked, password: _wrong);
    expect(_under(_email, _locked), findsOneWidget);
    expect(_under(_password, _wrong), findsOneWidget);

    await tester.enterText(_password, 'hunter23');
    await tester.pump();
    expect(find.text(_wrong), findsNothing);
    expect(_under(_email, _locked), findsOneWidget);

    await tester.enterText(_email, 'grace@example.com');
    await tester.pump();
    expect(find.text(_locked), findsNothing);
  });

  testWidgets('what it refused, typed again, shows it again', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, password: _wrong);
    await tester.enterText(_password, 'other');
    await tester.pump();
    expect(find.text(_wrong), findsNothing);
    await tester.enterText(_password, 'hunter22');
    await tester.pump();
    expect(_under(_password, _wrong), findsOneWidget);
  });

  testWidgets('focus alone does not take a message away', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, email: _locked, password: _wrong);
    await tester.tap(_password);
    await tester.pump();
    await tester.tap(_email);
    await tester.pump();
    expect(_under(_email, _locked), findsOneWidget);
    expect(_under(_password, _wrong), findsOneWidget);
  });

  testWidgets('the next submit to end with the same message shows it for '
      'what the field holds then', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, email: _locked, password: _wrong);
    await tester.enterText(_email, 'grace@example.com');
    await tester.enterText(_password, 'hunter23');
    await tester.pump();
    expect(find.text(_locked), findsNothing);
    expect(find.text(_wrong), findsNothing);

    await _refuse(tester, host, email: _locked, password: _wrong);
    expect(_under(_email, _locked), findsOneWidget);
    expect(_under(_password, _wrong), findsOneWidget);
  });

  testWidgets('a submit that ends with none takes them away', (tester) async {
    final host = await _pump(tester);
    await _refuse(tester, host, email: _locked, password: _wrong);
    await _refuse(tester, host);
    expect(find.text(_locked), findsNothing);
    expect(find.text(_wrong), findsNothing);
  });

  testWidgets('the form\'s own message shows in a refusal\'s place', (
    tester,
  ) async {
    final host = await _pump(tester, fill: false);
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await _refuse(tester, host, email: _locked, password: _wrong);
    expect(_under(_email, 'Email is required'), findsOneWidget);
    expect(_under(_password, 'Password is required'), findsOneWidget);
    expect(find.text(_locked), findsNothing);
    expect(find.text(_wrong), findsNothing);
    expect(host.submitted, isEmpty);
  });

  testWidgets('the submit that brings a refusal takes focus to its field, '
      'the email\'s first', (tester) async {
    for (final (email, password, onEmail) in [
      (null, _wrong, false),
      (_locked, null, true),
      (_locked, _wrong, true),
    ]) {
      final host = await _pump(tester);
      await _refuse(tester, host, email: email, password: password);
      expect(_focused(tester, _email), onEmail, reason: '$email / $password');
      expect(_focused(tester, _password), !onEmail);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a submit that ends with no refusal leaves focus where it '
      'was', (tester) async {
    final host = await _pump(tester);
    await tester.tap(_password);
    await tester.pump();
    await _refuse(tester, host, error: 'Try again later');
    expect(_focused(tester, _email), isFalse);
  });

  testWidgets('a message given from the start shows', (tester) async {
    await _pump(tester, email: _locked, password: _wrong, fill: false);
    expect(_under(_email, _locked), findsOneWidget);
    expect(_under(_password, _wrong), findsOneWidget);
  });

  testWidgets('a form given none draws no message', (tester) async {
    await _pump(tester);
    expect(find.byType(FieldErrorText), findsNothing);
  });
}
