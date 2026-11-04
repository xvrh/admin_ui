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
  const SignInDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final params = context.knobs;
    final submitting = params.bool('Submitting', false);
    final error = params.bool('Error', false);
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
        errorText: error ? 'Invalid email or password.' : null,
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
  const ChangePasswordDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final params = context.knobs;
    final submitting = params.bool('Submitting', false);
    final error = params.bool('Error', false);

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
              errorText: error ? 'Current password is incorrect.' : null,
            ),
          ],
        ),
      ],
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
