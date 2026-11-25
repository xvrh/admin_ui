import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// A stand-in brand mark for the auth card header.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
      ),
      child: Icon(Icons.bolt_rounded, color: colors.onPrimary, size: 26),
    );
  }
}

/// A mock SSO button — in a real app this is supplied by the host (e.g. the
/// Google-web button the library can't construct).
Widget _googleButton(VoidCallback onTap) => Button(
  'Continue with Google',
  icon: Icons.g_mobiledata_rounded,
  expand: true,
  onPressed: onTap,
);

class SignInDemo extends StatelessWidget {
  @Preview(name: 'Sign in', wrapper: adminUiPreview)
  const SignInDemo({super.key}) : refused = false;

  /// The form as a server left it, refusing the password: the message
  /// under its field.
  @Preview(name: 'Sign in / refused', wrapper: adminUiPreview)
  const SignInDemo.refused({super.key}) : refused = true;

  /// Whether the password's refusal starts on.
  final bool refused;

  @override
  Widget build(BuildContext context) {
    final params = context.knobs;
    final submitting = params.bool('Submitting', false);
    final error = params.bool('Error', false);
    final email = params.bool('Email refused', false);
    final password = params.bool('Password refused', refused);
    final google = params.bool('Google SSO', true);
    final ssoOnly = params.bool('SSO only', false);
    final forgot = params.bool('Forgot link', true);
    final alignStart = params.bool('Header aligned to start', false);

    void snack(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    return AuthScaffold(
      logo: const _Brand(),
      align: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      title: 'Sign in to Acme Admin',
      subtitle: 'Use your admin account to continue.',
      footer: const Text('Trouble signing in? Ask a developer for access.'),
      child: SignInForm(
        onSignIn: ssoOnly
            ? null
            : (email, password) => snack('Sign in: $email'),
        submitting: submitting,
        errorText: error ? 'Could not reach the server.' : null,
        emailErrorText: email ? 'This account is locked.' : null,
        passwordErrorText: password ? 'Wrong password.' : null,
        onForgotPassword: forgot ? () => snack('Forgot password') : null,
        providerButtons: google
            ? [_googleButton(() => snack('Google'))]
            : const [],
      ),
    );
  }
}

class SetPasswordDemo extends StatelessWidget {
  @Preview(name: 'Set password', wrapper: adminUiPreview)
  const SetPasswordDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final params = context.knobs;
    final submitting = params.bool('Submitting', false);
    final error = params.bool('Error', false);
    final strength = params.bool('Strength meter', true);

    void snack(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    return AuthScaffold(
      logo: const _Brand(),
      title: 'Choose a password',
      subtitle: 'Set a password for admin@acme.com to finish setup.',
      footer: const Text('This link expires in 24 hours.'),
      child: SetPasswordForm(
        onSubmit: (password) =>
            snack('Set password (${password.length} chars)'),
        submitting: submitting,
        showStrength: strength,
        errorText: error ? 'This reset link has expired.' : null,
      ),
    );
  }
}

class ChangePasswordDemo extends StatelessWidget {
  @Preview(name: 'Change password', wrapper: adminUiPreview)
  const ChangePasswordDemo({super.key}) : refused = false;

  /// The form as a server left it, refusing both passwords: each message
  /// under its field.
  @Preview(name: 'Change password / refused', wrapper: adminUiPreview)
  const ChangePasswordDemo.refused({super.key}) : refused = true;

  /// Whether the two field refusals start on.
  final bool refused;

  @override
  Widget build(BuildContext context) {
    final params = context.knobs;
    final submitting = params.bool('Submitting', false);
    final error = params.bool('Error', false);
    final current = params.bool('Current password refused', refused);
    final next = params.bool('New password refused', refused);

    void snack(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    // Settings context: the form sits inside a section panel, not the card.
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Security'),
        FieldGroup(
          title: 'Password',
          description: 'Changing your password signs out your other sessions.',
          boxed: true,
          children: [
            ChangePasswordForm(
              onSubmit: (current, next) => snack('Change password'),
              submitting: submitting,
              errorText: error ? 'Could not reach the server.' : null,
              currentErrorText: current
                  ? 'That is not your current password.'
                  : null,
              newErrorText: next
                  ? 'Too easy to guess. Try a longer one.'
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// The step of a sign-in that asks for a one-time code.
enum _CodeStep { authenticator, submitting, refused, recovery, emailed }

class OneTimeCodeDemo extends StatelessWidget {
  /// After a password, for an authenticator app: remember this browser, a
  /// recovery code, back to the sign-in.
  @Preview(name: 'One-time code', wrapper: adminUiPreview)
  const OneTimeCodeDemo({super.key}) : _step = _CodeStep.authenticator;

  /// The code on its way to the server.
  @Preview(name: 'One-time code / submitting', wrapper: adminUiPreview)
  const OneTimeCodeDemo.submitting({super.key}) : _step = _CodeStep.submitting;

  /// The code as a server left it, refusing it: the message under the field.
  @Preview(name: 'One-time code / refused', wrapper: adminUiPreview)
  const OneTimeCodeDemo.refused({super.key}) : _step = _CodeStep.refused;

  /// Swapped for a recovery code, of any length.
  @Preview(name: 'One-time code / recovery code', wrapper: adminUiPreview)
  const OneTimeCodeDemo.recovery({super.key}) : _step = _CodeStep.recovery;

  /// A code sent by email: no checkbox and no recovery code.
  @Preview(name: 'One-time code / emailed', wrapper: adminUiPreview)
  const OneTimeCodeDemo.emailed({super.key}) : _step = _CodeStep.emailed;

  final _CodeStep _step;

  @override
  Widget build(BuildContext context) {
    final emailed = _step == _CodeStep.emailed;
    final params = context.knobs;
    final submitting = params.bool('Submitting', _step == _CodeStep.submitting);
    final error = params.bool('Refused', _step == _CodeStep.refused);
    final remember = params.bool('Remember checkbox', !emailed);
    final recovery = params.bool('Recovery code', !emailed);
    final back = params.bool('Back link', true);
    final autoSubmit = params.bool('Submit on the last digit', false);

    void snack(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    return AuthScaffold(
      logo: const _Brand(),
      title: emailed ? 'Check your email' : 'Two-step sign-in',
      subtitle: emailed
          ? 'We sent a code to admin@example.com.'
          : 'Open your authenticator app to get a code.',
      child: OneTimeCodeForm(
        onSubmit: (code, {required remember, required isRecoveryCode}) => snack(
          '${isRecoveryCode ? 'Recovery code' : 'Code'} $code'
          '${remember ? ', remembered' : ''}',
        ),
        submitting: submitting,
        errorText: error ? 'That code is not valid. Try the next one.' : null,
        autoSubmit: autoSubmit,
        description: emailed
            ? 'The code expires in 10 minutes.'
            : 'Enter the 6-digit code your app shows.',
        recoveryDescription: 'Each recovery code works once.',
        rememberLabel: remember ? 'Remember this browser for 30 days' : null,
        allowRecoveryCode: recovery,
        initialRecovery: recovery && _step == _CodeStep.recovery,
        onBack: back ? () => snack('Back to sign in') : null,
      ),
    );
  }
}

/// A sample setup, as a server would make it: the issuer, the account and
/// a 160-bit base32 key.
const _secret = 'JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP';
const _otpauth =
    'otpauth://totp/Acme%20Admin:admin%40example.com'
    '?secret=$_secret&issuer=Acme%20Admin&algorithm=SHA1&digits=6&period=30';

/// Where a demo of the two-step setup sits.
enum _Frame { card, refused, dialog }

class AuthenticatorSetupDemo extends StatelessWidget {
  /// On the sign-in card, the step a first sign-in takes.
  @Preview(name: 'Authenticator setup', wrapper: adminUiPreview)
  const AuthenticatorSetupDemo({super.key}) : _frame = _Frame.card;

  /// The confirming code refused: the message under the field.
  @Preview(name: 'Authenticator setup / refused', wrapper: adminUiPreview)
  const AuthenticatorSetupDemo.refused({super.key}) : _frame = _Frame.refused;

  /// In a modal of an account's settings, with a cancel button.
  @Preview(name: 'Authenticator setup / in a dialog', wrapper: adminUiPreview)
  const AuthenticatorSetupDemo.dialog({super.key}) : _frame = _Frame.dialog;

  final _Frame _frame;

  @override
  Widget build(BuildContext context) {
    final dialog = _frame == _Frame.dialog;
    final params = context.knobs;
    final submitting = params.bool('Submitting', false);
    final error = params.bool('Refused', _frame == _Frame.refused);
    final cancel = params.bool('Cancel button', dialog);
    final keyShown = params.bool('Key shown', false);

    void snack(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    final view = AuthenticatorSetupView(
      key: ValueKey(keyShown),
      uri: _otpauth,
      secret: _secret,
      initiallyShowsSecret: keyShown,
      onSubmit: (code) => snack('Confirm $code'),
      onCancel: cancel ? () => snack('Cancel') : null,
      submitting: submitting,
      errorText: error ? 'That code is not valid. Try the next one.' : null,
      description: dialog
          ? 'Scan the code with your authenticator app, then enter the code '
                'it shows.'
          : null,
    );

    if (dialog) {
      return DemoPage(
        maxWidth: 520,
        children: [
          Center(
            child: Modal(
              title: 'Turn on two-step sign-in',
              size: ModalSize.small,
              onDismiss: () => snack('Close'),
              body: view,
            ),
          ),
        ],
      );
    }
    return AuthScaffold(
      logo: const _Brand(),
      title: 'Set up two-step sign-in',
      subtitle:
          'Scan the code with your authenticator app, then enter the code '
          'it shows.',
      child: view,
    );
  }
}

/// Ten recovery codes, as a server would hand them out.
const _recoveryCodes = [
  'q3vt-8kmd',
  '7hzp-2wce',
  'n9rx-4fjb',
  'c5ly-6tgh',
  'w2ks-9pqa',
  'm8db-3xvn',
  'e6jr-5yzu',
  'u4gf-7nlc',
  'b1hw-8rte',
  'p7cq-2mso',
];

class RecoveryCodesDemo extends StatelessWidget {
  /// On the sign-in card, after the first setup.
  @Preview(name: 'Recovery codes', wrapper: adminUiPreview)
  const RecoveryCodesDemo({super.key}) : dialog = false;

  /// In a modal of an account's settings.
  @Preview(name: 'Recovery codes / in a dialog', wrapper: adminUiPreview)
  const RecoveryCodesDemo.dialog({super.key}) : dialog = true;

  /// Whether the view sits in a modal rather than on the card.
  final bool dialog;

  @override
  Widget build(BuildContext context) {
    void snack(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    final view = RecoveryCodesView(
      codes: _recoveryCodes,
      onDone: () => snack('Done'),
      description:
          'Each code signs you in once if you lose your phone. Keep them '
          'somewhere safe: they are not shown again.',
    );

    if (dialog) {
      return DemoPage(
        maxWidth: 560,
        children: [
          Center(
            child: Modal(title: 'Save your recovery codes', body: view),
          ),
        ],
      );
    }
    return AuthScaffold(
      logo: const _Brand(),
      title: 'Save your recovery codes',
      child: view,
    );
  }
}

class PasswordStrengthDemo extends StatelessWidget {
  @Preview(name: 'Password strength', wrapper: adminUiPreview)
  const PasswordStrengthDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPage(
      maxWidth: 420,
      children: [
        DemoVariant(
          'Weak — below the minimum, or one kind of character',
          PasswordStrengthMeter(password: 'abcdefgh'),
        ),
        DemoVariant(
          'Fair — two kinds',
          PasswordStrengthMeter(password: 'abcdEfgh'),
        ),
        DemoVariant(
          'Good — three kinds; a fixed step, never the brand colour',
          PasswordStrengthMeter(password: 'abcdEf12'),
        ),
        DemoVariant(
          'Strong — every kind and some length',
          PasswordStrengthMeter(password: r'abcdEf12!xyz'),
        ),
      ],
    );
  }
}
