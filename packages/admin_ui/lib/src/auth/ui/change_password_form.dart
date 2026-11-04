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
class ChangePasswordForm extends StatefulWidget {
  final ChangePasswordCallback onSubmit;
  final bool submitting;
  final String? errorText;

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

  const ChangePasswordForm({
    super.key,
    required this.onSubmit,
    this.submitting = false,
    this.errorText,
    this.minLength = 8,
    this.showStrength = true,
    this.submitLabel,
    this.currentLabel,
    this.newLabel,
    this.confirmLabel,
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

  @override
  void initState() {
    super.initState();
    _current.addListener(() {
      if (_attempted) setState(() {});
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
          label: currentLabel,
          controller: _current,
          focusNode: _currentFocus,
          errorText: _attempted && _current.text.isEmpty
              ? shell.isRequired(currentLabel)
              : null,
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
          onChanged: (value) => setState(() => _password = value),
          onSubmit: _submit,
        ),
        const Gap(AdminSpacing.xl),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Button.primary(
            widget.submitLabel ?? shell.changePassword,
            loading: widget.submitting,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
