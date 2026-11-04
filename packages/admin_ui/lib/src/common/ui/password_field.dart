import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import 'field_chrome.dart';
import 'icon_action.dart';
import 'input_field.dart';

/// A password input with a reveal toggle: an [InputField] whose text is hidden
/// until the eye at its end — an inline [IconAction], the localized "Show
/// password" or "Hide password" — shows it.
///
/// It takes the [InputField]'s label, message, size and state set, and its
/// rule for [value]: controlled unless a [controller] is passed. Reused by
/// every auth form and by the settings change-password flow, so the reveal
/// affordance and autofill wiring live in one place.
class PasswordField extends StatefulWidget {
  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Label above the input; null renders the bare control.
  final String? label;

  /// Shown at the far end of the label row — a "forgot password?" link.
  final Widget? labelTrailing;

  /// Muted line between the label and the input — the password rules.
  final String? description;

  /// Placeholder; none by default, since a placeholder that repeats the label
  /// only adds noise.
  final String? hint;

  /// Validation message under the input; also turns its border red.
  final String? errorText;

  /// Leading glyph; defaults to a lock. Pass null to drop it.
  final IconData? icon;

  final ControlSize size;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;

  /// Autofill hints — pass [AutofillHints.password] for sign-in and
  /// [AutofillHints.newPassword] for set / change so password managers behave.
  final Iterable<String>? autofillHints;

  final TextInputAction? textInputAction;

  const PasswordField({
    super.key,
    this.value = '',
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.labelTrailing,
    this.description,
    this.hint,
    this.errorText,
    this.icon = Icons.lock_outline_rounded,
    this.size = ControlSize.medium,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofillHints,
    this.textInputAction,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return InputField(
      value: widget.value,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      label: widget.label,
      labelTrailing: widget.labelTrailing,
      description: widget.description,
      hint: widget.hint,
      errorText: widget.errorText,
      icon: widget.icon,
      size: widget.size,
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      obscureText: _obscured,
      suffix: Builder(
        // Under the field's state, so a disabled field disables it too.
        builder: (context) => IconAction(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          label: _obscured
              ? context.adminL10n.inputs.showPassword
              : context.adminL10n.inputs.hidePassword,
          size: IconActionSize.inline,
          onPressed: FieldStateScope.of(context).enabled
              ? () => setState(() => _obscured = !_obscured)
              : null,
        ),
      ),
    );
  }
}
