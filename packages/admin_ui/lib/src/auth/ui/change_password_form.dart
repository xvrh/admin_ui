import 'package:material_ui/material_ui.dart';

import '../../common/ui/alert.dart';
import '../../common/ui/button.dart';
import '../../common/ui/password_field.dart';
import '../../common/ui/severity.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import 'new_password_fields.dart';

/// Called with the [current] and chosen [next] password on a valid submit.
typedef ChangePasswordCallback = void Function(String current, String next);

/// The logged-in change-password form: current password, then a new password and
/// confirmation. Lives on a settings screen and wires to the authenticated
/// `setPassword` endpoint.
///
/// View-pure — the new/confirm block and its length/match validation are shared
/// with [SetPasswordForm] via [NewPasswordFields]; this adds the current-password
/// field on top. Submit stays enabled: pressing it shows what is missing and
/// focuses the first field that fails.
///
/// A server's refusal goes where it belongs: [currentErrorText] under the
/// current password ("That is not your current password"),
/// [newErrorText] under the new one ("Too easy to guess"), and
/// [errorText], for anything that is no one field's, in an alert above the
/// form. A field's message is about what the field held when it came: it
/// shows while that is unchanged, and the next submit to end with it still
/// given shows it again. The submit that brings one takes focus to its
/// field, the current password's first.
class ChangePasswordForm extends StatefulWidget {
  final ChangePasswordCallback onSubmit;
  final bool submitting;

  /// A refusal that is no one field's, in an alert above the form.
  final String? errorText;

  /// A refusal of the current password, under its field. The form's own
  /// "is required" shows in its place while the field is empty.
  final String? currentErrorText;

  /// A refusal of the new password, under its field. The form's own length
  /// rule shows in its place while the password is too short.
  final String? newErrorText;

  final int minLength;
  final bool showStrength;

  /// The submit's label; "Change password" in the app's language when null.
  final String? submitLabel;

  /// The current password's label; "Current password" in the app's language
  /// when null.
  final String? currentLabel;

  /// See [NewPasswordFields.newLabel].
  final String? newLabel;

  /// The confirmation's label; "Confirm new password" in the app's language
  /// when null.
  final String? confirmLabel;

  /// The key of the current-password input, to find it by in a test.
  final Key? currentKey;

  /// The key of the new-password input, to find it by in a test.
  final Key? newKey;

  /// The key of the confirmation input, to find it by in a test.
  final Key? confirmKey;

  /// The key of the submit button, to find it by in a test.
  final Key? submitKey;

  const ChangePasswordForm({
    super.key,
    required this.onSubmit,
    this.submitting = false,
    this.errorText,
    this.currentErrorText,
    this.newErrorText,
    this.minLength = 8,
    this.showStrength = true,
    this.submitLabel,
    this.currentLabel,
    this.newLabel,
    this.confirmLabel,
    this.currentKey,
    this.newKey,
    this.confirmKey,
    this.submitKey,
  });

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _current = TextEditingController();
  final _currentFocus = FocusNode(debugLabel: 'Current password');
  final _newFocus = FocusNode(debugLabel: 'New password');
  final _fields = GlobalKey<NewPasswordFieldsState>();
  String? _password;

  /// Set by a submit attempt; from then on an empty current password shows
  /// that it is required.
  bool _attempted = false;

  /// The current password [ChangePasswordForm.currentErrorText] is about:
  /// what the field held when the message came.
  late String? _refusedCurrent = widget.currentErrorText == null ? null : '';

  @override
  void initState() {
    super.initState();
    _current.addListener(() {
      if (_attempted || _refusedCurrent != null) setState(() {});
    });
  }

  @override
  void didUpdateWidget(ChangePasswordForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A submit that ends brings its refusals with it, the same ones as
    // last time included.
    final answered = oldWidget.submitting && !widget.submitting;
    final current = widget.currentErrorText;
    if (answered || current != oldWidget.currentErrorText) {
      _refusedCurrent = current == null ? null : _current.text;
    }
    if (!answered) return;
    final refused = current != null
        ? _currentFocus
        : (widget.newErrorText != null ? _newFocus : null);
    // Once the fields are enabled again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refused?.requestFocus();
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.submitting) return;
    setState(() => _attempted = true);
    final hasCurrent = _current.text.isNotEmpty;
    if (!hasCurrent) _currentFocus.requestFocus();
    final valid = _fields.currentState?.validate(focus: hasCurrent) ?? false;
    final password = _password;
    if (!hasCurrent || !valid || password == null) return;
    widget.onSubmit(_current.text, password);
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.adminL10n.shell;
    final currentLabel = widget.currentLabel ?? shell.currentPassword;
    final error = widget.errorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          Alert(error, severity: Severity.danger),
          const Gap(AdminSpacing.lg),
        ],
        PasswordField(
          key: widget.currentKey,
          label: currentLabel,
          controller: _current,
          focusNode: _currentFocus,
          errorText: _attempted && _current.text.isEmpty
              ? shell.isRequired(currentLabel)
              : (_current.text == _refusedCurrent
                    ? widget.currentErrorText
                    : null),
          enabled: !widget.submitting,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _newFocus.requestFocus(),
        ),
        const Gap(AdminSpacing.lg),
        NewPasswordFields(
          key: _fields,
          focusNode: _newFocus,
          enabled: !widget.submitting,
          minLength: widget.minLength,
          showStrength: widget.showStrength,
          newLabel: widget.newLabel,
          confirmLabel: widget.confirmLabel ?? shell.confirmNewPassword,
          // None while a submit runs, so that the one it ends with is new
          // to the fields even when it is the last one again.
          errorText: widget.submitting ? null : widget.newErrorText,
          newKey: widget.newKey,
          confirmKey: widget.confirmKey,
          onChanged: (value) => setState(() => _password = value),
          onSubmit: _submit,
        ),
        const Gap(AdminSpacing.xl),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Button.primary(
            widget.submitLabel ?? shell.changePassword,
            key: widget.submitKey,
            loading: widget.submitting,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
