import 'package:material_ui/material_ui.dart';

import '../../common/ui/password_field.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import 'password_strength.dart';

/// The "choose a new password" block shared by [SetPasswordForm] and
/// [ChangePasswordForm]: a new-password field with an optional strength meter,
/// a confirmation field, and inline length / match validation.
///
/// Owns the two controllers and reports the chosen password through
/// [onChanged] — the value when both fields are valid and matching, else null.
/// [onSubmit] fires when the user presses done on the confirm field.
///
/// Validation waits for the user, never firing on the first keystroke: the
/// length rule shows once the new password has been left with something in
/// it, the mismatch once the confirmation has been left or has reached the
/// password's length, and both on a submit attempt. The host makes that
/// attempt through a `GlobalKey` when its submit is pressed, calling
/// [NewPasswordFieldsState.validate]. Once shown, a message follows the
/// typing and clears when met.
class NewPasswordFields extends StatefulWidget {
  /// Emits the valid password, or null when the inputs aren't yet acceptable.
  final ValueChanged<String?> onChanged;
  final VoidCallback? onSubmit;

  final int minLength;
  final bool showStrength;
  final bool enabled;

  /// The new password's label; "New password" in the app's language when
  /// null.
  final String? newLabel;

  /// The confirmation's label; "Confirm password" in the app's language when
  /// null.
  final String? confirmLabel;

  /// The new-password input's focus, for a host that moves focus there — from
  /// a field above it, say.
  final FocusNode? focusNode;

  const NewPasswordFields({
    super.key,
    required this.onChanged,
    this.onSubmit,
    this.minLength = 8,
    this.showStrength = true,
    this.enabled = true,
    this.newLabel,
    this.confirmLabel,
    this.focusNode,
  });

  @override
  State<NewPasswordFields> createState() => NewPasswordFieldsState();
}

/// The state of a [NewPasswordFields]: [validate] runs the submit-time check.
class NewPasswordFieldsState extends State<NewPasswordFields> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _confirmFocus = FocusNode(debugLabel: 'Confirm password');
  FocusNode? _ownFocus;
  FocusNode get _passwordFocus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'New password'));

  /// The new password was left with something in it.
  bool _passwordLeft = false;

  /// The confirmation was left with something in it.
  bool _confirmLeft = false;

  /// A submit was attempted: every rule shows.
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  void _onChanged() {
    widget.onChanged(_valid ? _value : null);
    setState(() {});
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _confirmFocus.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  /// Shows every message a submit would and, when [focus], moves focus to the
  /// first field that fails. Returns whether the password is acceptable.
  bool validate({bool focus = true}) {
    setState(() => _attempted = true);
    if (focus) {
      if (!_longEnough) {
        _passwordFocus.requestFocus();
      } else if (!_matches) {
        _confirmFocus.requestFocus();
      }
    }
    return _valid;
  }

  String get _value => _password.text;
  bool get _longEnough => _value.length >= widget.minLength;
  bool get _matches => _confirm.text == _value;
  bool get _valid => _value.isNotEmpty && _longEnough && _matches;

  String? get _lengthError => !_longEnough && (_attempted || _passwordLeft)
      ? context.adminL10n.shell.passwordTooShort(widget.minLength)
      : null;

  String? get _matchError {
    if (_matches) return null;
    final confirm = _confirm.text;
    final shown =
        _attempted ||
        _confirmLeft ||
        (_value.isNotEmpty && confirm.length >= _value.length);
    return shown ? context.adminL10n.shell.passwordsDontMatch : null;
  }

  /// Notes a field left with text in it, which lets its message show.
  Widget _onLeave(
    TextEditingController controller,
    VoidCallback left,
    Widget child,
  ) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (!focused && controller.text.isNotEmpty) setState(left);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.adminL10n.shell;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _onLeave(
          _password,
          () => _passwordLeft = true,
          PasswordField(
            label: widget.newLabel ?? shell.newPassword,
            controller: _password,
            focusNode: _passwordFocus,
            errorText: _lengthError,
            enabled: widget.enabled,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _confirmFocus.requestFocus(),
          ),
        ),
        if (widget.showStrength && _value.isNotEmpty) ...[
          const Gap(AdminSpacing.md),
          PasswordStrengthMeter(password: _value, minLength: widget.minLength),
        ],
        const Gap(AdminSpacing.lg),
        _onLeave(
          _confirm,
          () => _confirmLeft = true,
          PasswordField(
            label: widget.confirmLabel ?? shell.confirmPassword,
            controller: _confirm,
            focusNode: _confirmFocus,
            errorText: _matchError,
            enabled: widget.enabled,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => widget.onSubmit?.call(),
          ),
        ),
      ],
    );
  }
}
