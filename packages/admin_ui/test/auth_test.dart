import 'package:admin_ui/src/auth/ui/change_password_form.dart';
import 'package:admin_ui/src/auth/ui/password_strength.dart';
import 'package:admin_ui/src/auth/ui/set_password_form.dart';
import 'package:admin_ui/src/auth/ui/sign_in_form.dart';
import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/password_field.dart';
import 'package:admin_ui/src/common/ui/tappable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, child: child)),
  ),
);

void main() {
  group('PasswordField', () {
    testWidgets('starts obscured and the eye toggles reveal', (tester) async {
      await tester.pumpWidget(_host(const PasswordField(value: 'secret')));

      EditableText field() =>
          tester.widget<EditableText>(find.byType(EditableText));
      expect(field().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });
  });

  group('SignInForm', () {
    testWidgets('submits the trimmed email and password', (tester) async {
      String? gotEmail;
      String? gotPassword;
      await tester.pumpWidget(
        _host(
          SignInForm(
            onSignIn: (e, p) {
              gotEmail = e;
              gotPassword = p;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, '  me@acme.com  ');
      await tester.enterText(find.byType(PasswordField), 'hunter2');
      await tester.tap(find.text('Sign in'));
      expect(gotEmail, 'me@acme.com');
      expect(gotPassword, 'hunter2');
    });

    testWidgets('does not submit when a field is empty', (tester) async {
      var fired = false;
      await tester.pumpWidget(
        _host(SignInForm(onSignIn: (_, _) => fired = true)),
      );

      await tester.enterText(find.byType(TextField).first, 'me@acme.com');
      await tester.tap(find.text('Sign in'));
      expect(fired, isFalse);
    });

    testWidgets('SSO-only (null onSignIn) hides the credential block', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SignInForm(
            providerButtons: [Button('Continue with Google', onPressed: () {})],
          ),
        ),
      );

      expect(find.byType(PasswordField), findsNothing);
      expect(find.text('Sign in'), findsNothing);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('forgot link fires only when provided', (tester) async {
      var forgot = false;
      await tester.pumpWidget(
        _host(
          SignInForm(
            onSignIn: (_, _) {},
            onForgotPassword: () => forgot = true,
          ),
        ),
      );

      await tester.tap(find.text('Forgot password?'));
      expect(forgot, isTrue);
    });

    testWidgets('forgot link is a focusable link with a 24px target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var forgot = 0;
      await tester.pumpWidget(
        _host(
          SignInForm(onSignIn: (_, _) {}, onForgotPassword: () => forgot++),
        ),
      );
      final link = find.ancestor(
        of: find.text('Forgot password?'),
        matching: find.byType(Tappable),
      );
      expect(tester.getSize(link).height, greaterThanOrEqualTo(24));
      expect(
        tester.getSemantics(
          find.descendant(of: link, matching: find.byType(GestureDetector)),
        ),
        isSemantics(
          label: 'Forgot password?',
          isLink: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );

      final node = Focus.of(
        tester.element(
          find.descendant(of: link, matching: find.byType(GestureDetector)),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(forgot, 1);
      handle.dispose();
    });

    testWidgets('a submitting form disables the forgot link', (tester) async {
      await tester.pumpWidget(
        _host(
          SignInForm(
            onSignIn: (_, _) {},
            submitting: true,
            onForgotPassword: () {},
          ),
        ),
      );
      final link = tester.widget<Tappable>(
        find.ancestor(
          of: find.text('Forgot password?'),
          matching: find.byType(Tappable),
        ),
      );
      expect(link.onTap, isNull);
    });
  });

  group('SetPasswordForm', () {
    testWidgets('submit is gated until long enough and matching', (
      tester,
    ) async {
      String? got;
      await tester.pumpWidget(
        _host(SetPasswordForm(onSubmit: (p) => got = p, minLength: 8)),
      );

      final fields = find.byType(PasswordField);
      // Too short.
      await tester.enterText(fields.at(0), 'abc');
      await tester.enterText(fields.at(1), 'abc');
      await tester.pump();
      await tester.tap(find.text('Set password'), warnIfMissed: false);
      expect(got, isNull);

      // Long but mismatched.
      await tester.enterText(fields.at(0), 'longenough1');
      await tester.enterText(fields.at(1), 'different99');
      await tester.pump();
      await tester.tap(find.text('Set password'), warnIfMissed: false);
      expect(got, isNull);

      // Valid.
      await tester.enterText(fields.at(1), 'longenough1');
      await tester.pump();
      await tester.tap(find.text('Set password'));
      expect(got, 'longenough1');
    });
  });

  group('ChangePasswordForm', () {
    testWidgets('passes current and new password on a valid submit', (
      tester,
    ) async {
      String? current;
      String? next;
      await tester.pumpWidget(
        _host(
          ChangePasswordForm(
            onSubmit: (c, n) {
              current = c;
              next = n;
            },
          ),
        ),
      );

      final fields = find.byType(PasswordField);
      await tester.enterText(fields.at(0), 'oldpass00');
      await tester.enterText(fields.at(1), 'newpass11');
      await tester.enterText(fields.at(2), 'newpass11');
      await tester.pump();
      await tester.tap(find.text('Change password'));
      expect(current, 'oldpass00');
      expect(next, 'newpass11');
    });
  });

  group('passwordStrength', () {
    test('below min length is always weak', () {
      expect(passwordStrength('aB3', minLength: 8), PasswordStrength.weak);
    });

    test('variety and length climb the scale', () {
      expect(passwordStrength('abcdefgh'), PasswordStrength.weak);
      expect(passwordStrength('abcdEfgh'), PasswordStrength.fair);
      expect(passwordStrength('abcdEf12'), PasswordStrength.good);
      expect(passwordStrength(r'abcdEf12!xyz'), PasswordStrength.strong);
    });
  });
}
