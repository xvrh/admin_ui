import 'package:material_ui/material_ui.dart';

import '../../common/ui/alert.dart';
import '../../common/ui/button.dart';
import '../../common/ui/severity.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import 'new_password_fields.dart';

/// Choose-a-password form: a new password plus a confirmation, with a length
/// rule and an optional strength meter. Serves both first-time invite acceptance
/// and password reset — the host decides which by how it wires [onSubmit].
///
/// View-pure: validation (length, match) is presentational, delegated to
/// [NewPasswordFields], and waits for the user — a field's message shows once
/// it has been left, and every message on a submit attempt, which then
/// focuses the first field that fails. The authoritative rule is the server's;
/// pass [minLength] to mirror it.
class SetPasswordForm extends StatefulWidget {
  /// Called with the chosen password once both fields are valid and matching.
  final ValueChanged<String> onSubmit;
  final bool submitting;
  final String? errorText;

  final int minLength;
  final bool showStrength;

  /// The submit's label; "Set password" in the app's language when null.
  final String? submitLabel;

  /// See [NewPasswordFields.newLabel].
  final String? newLabel;

  /// See [NewPasswordFields.confirmLabel].
  final String? confirmLabel;

  const SetPasswordForm({
    super.key,
    required this.onSubmit,
    this.submitting = false,
    this.errorText,
    this.minLength = 8,
    this.showStrength = true,
    this.submitLabel,
    this.newLabel,
    this.confirmLabel,
  });

  @override
  State<SetPasswordForm> createState() => _SetPasswordFormState();
}

class _SetPasswordFormState extends State<SetPasswordForm> {
  final _fields = GlobalKey<NewPasswordFieldsState>();
  String? _password;

  void _submit() {
    if (widget.submitting) return;
    final valid = _fields.currentState?.validate() ?? false;
    final password = _password;
    if (!valid || password == null) return;
    widget.onSubmit(password);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          Alert(error, severity: Severity.danger),
          const Gap(AdminSpacing.lg),
        ],
        NewPasswordFields(
          key: _fields,
          enabled: !widget.submitting,
          minLength: widget.minLength,
          showStrength: widget.showStrength,
          newLabel: widget.newLabel,
          confirmLabel: widget.confirmLabel,
          onChanged: (value) => setState(() => _password = value),
          onSubmit: _submit,
        ),
        const Gap(AdminSpacing.xl),
        Button.primary(
          widget.submitLabel ?? context.adminL10n.shell.setPassword,
          expand: true,
          loading: widget.submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
