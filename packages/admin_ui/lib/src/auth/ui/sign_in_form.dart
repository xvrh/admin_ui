import 'package:material_ui/material_ui.dart';

import '../../common/ui/alert.dart';
import '../../common/ui/button.dart';
import '../../common/ui/input_field.dart';
import '../../common/ui/password_field.dart';
import '../../common/ui/severity.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// Called with the trimmed [email] and raw [password] when the user submits.
typedef SignInCallback = void Function(String email, String password);

/// The sign-in form — email + password with submit, plus an optional SSO block.
///
/// View-pure: it owns its text controllers and validates only that fields are
/// non-empty — a submit with one left empty marks each empty field required
/// and focuses the first, and the marks clear as they are filled in. The host
/// maps server errors into [errorText] and flips [submitting]. Generic across
/// auth contexts via three switches:
///
/// * [onSignIn] null → the email/password block is hidden (SSO-only).
/// * [providerButtons] — SSO buttons supplied by the host (e.g. a Google-web
///   button the library can't construct); a divider appears only when both the
///   credential block and providers are present.
/// * [onForgotPassword] null → no "forgot password?" link.
///
/// Each label, when null, reads the kit's own in the app's language.
class SignInForm extends StatefulWidget {
  final SignInCallback? onSignIn;
  final bool submitting;
  final String? errorText;

  final VoidCallback? onForgotPassword;

  /// Externally-built SSO buttons, rendered below the credential block.
  final List<Widget> providerButtons;

  final String initialEmail;
  final String initialPassword;
  final String? emailLabel;
  final String? passwordLabel;
  final String? submitLabel;
  final String? forgotLabel;

  /// Label on the "or" separator between credentials and providers.
  final String? dividerLabel;

  const SignInForm({
    super.key,
    this.onSignIn,
    this.submitting = false,
    this.errorText,
    this.onForgotPassword,
    this.providerButtons = const [],
    this.initialEmail = '',
    this.initialPassword = '',
    this.emailLabel,
    this.passwordLabel,
    this.submitLabel,
    this.forgotLabel,
    this.dividerLabel,
  });

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  late final _email = TextEditingController(text: widget.initialEmail);
  late final _password = TextEditingController(text: widget.initialPassword);
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  /// Set by a submit with a field left empty; from then on an empty field
  /// shows that it is required.
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_revalidate);
    _password.addListener(_revalidate);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _revalidate() {
    if (_attempted) setState(() {});
  }

  void _submit() {
    if (widget.submitting) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _attempted = true);
      (email.isEmpty ? _emailFocus : _passwordFocus).requestFocus();
      return;
    }
    widget.onSignIn?.call(email, password);
  }

  String? _required(String value, String label) => _attempted && value.isEmpty
      ? context.adminL10n.shell.isRequired(label)
      : null;

  @override
  Widget build(BuildContext context) {
    final shell = context.adminL10n.shell;
    final emailLabel = widget.emailLabel ?? shell.email;
    final passwordLabel = widget.passwordLabel ?? shell.password;
    final hasCredentials = widget.onSignIn != null;
    final hasProviders = widget.providerButtons.isNotEmpty;
    final error = widget.errorText;

    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            Alert(error, severity: Severity.danger),
            const Gap(AdminSpacing.lg),
          ],
          if (hasCredentials) ...[
            InputField(
              label: emailLabel,
              controller: _email,
              focusNode: _emailFocus,
              icon: Icons.mail_outline_rounded,
              hint: shell.emailHint,
              errorText: _required(_email.text.trim(), emailLabel),
              enabled: !widget.submitting,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              autofillHints: const [AutofillHints.username],
            ),
            const Gap(AdminSpacing.lg),
            PasswordField(
              label: passwordLabel,
              labelTrailing: widget.onForgotPassword == null
                  ? null
                  : _LinkText(
                      widget.forgotLabel ?? shell.forgotPassword,
                      onTap: widget.submitting ? null : widget.onForgotPassword,
                    ),
              controller: _password,
              focusNode: _passwordFocus,
              errorText: _required(_password.text, passwordLabel),
              enabled: !widget.submitting,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const Gap(AdminSpacing.xl),
            Button.primary(
              widget.submitLabel ?? shell.signIn,
              expand: true,
              loading: widget.submitting,
              onPressed: _submit,
            ),
          ],
          if (hasCredentials && hasProviders) ...[
            const Gap(AdminSpacing.xl),
            _OrDivider(widget.dividerLabel ?? shell.or),
            const Gap(AdminSpacing.xl),
          ],
          if (hasProviders)
            for (var i = 0; i < widget.providerButtons.length; i++) ...[
              if (i > 0) const Gap(AdminSpacing.md),
              widget.providerButtons[i],
            ],
        ],
      ),
    );
  }
}

/// A horizontal rule with a centred label — "or" between credentials and SSO.
class _OrDivider extends StatelessWidget {
  final String label;

  const _OrDivider(this.label);

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(height: context.stroke.hairline));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg),
          child: Text(label, style: context.type.caption),
        ),
        line,
      ],
    );
  }
}

/// A flat text link (the "forgot password?" affordance): a focusable link
/// with a 24px-tall hit area, underlined under the pointer.
class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _LinkText(this.label, {this.onTap});

  /// The link's target height, WCAG 2.5.8's minimum.
  static const _height = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Tappable.states(
      onTap: onTap,
      link: true,
      focusRadius: context.radii.radiusSmall,
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _height),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: type.weighted(
                type.caption.copyWith(
                  color: onTap == null
                      ? colors.foregroundSubtle
                      : colors.primaryText,
                  decoration: hovered && onTap != null
                      ? TextDecoration.underline
                      : null,
                  decorationColor: colors.primaryText,
                ),
                type.spec.strong,
              ),
            ),
          ),
        );
      },
    );
  }
}
