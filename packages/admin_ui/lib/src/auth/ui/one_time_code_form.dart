import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/checkbox.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import 'code_input.dart';

/// Called with the trimmed [code] when the user submits a
/// [OneTimeCodeForm]: whether to [remember] the device, and whether the
/// code [isRecoveryCode] rather than one of the form's digits.
typedef OneTimeCodeCallback = void Function(
  String code, {
  required bool remember,
  required bool isRecoveryCode,
});

/// The one-time code form: the step after a password that asks for the
/// code an authenticator app shows, or for one sent by email.
///
/// One field of [length] digits, digits only, which takes the platform's
/// one-time code autofill and reads left to right in the theme's monospace
/// font. Enter submits, as the button does, and with [autoSubmit] the last
/// digit does too. Three switches make it fit each flow:
///
/// * [rememberLabel] null → no checkbox; given, a checkbox with that text
///   ("Remember this browser for 30 days"), off unless [initialRemember].
/// * [allowRecoveryCode] → a link under the button swaps the field for a
///   recovery code, of any length, and another link swaps it back.
/// * [onBack] null → no link back to the step before.
///
/// View-pure: it owns its text and checks only that the code is whole — a
/// submit with the field empty marks it required, one short of [length]
/// digits says how many a code has, and the mark clears as it is met. The
/// host maps the server's answer into [errorText] and flips [submitting].
/// [errorText] shows under the field, about the code as it stood when it
/// came: it goes while the code is edited, while a submit runs, and when
/// the field is swapped. The submit that ends with it, the same message
/// again included, takes focus back to the field with the code selected.
///
/// Each label, when null, reads the kit's own in the app's language.
class OneTimeCodeForm extends StatefulWidget {
  final OneTimeCodeCallback onSubmit;
  final bool submitting;

  /// The refusal of the code, under the field.
  final String? errorText;

  /// The digits of a code.
  final int length;

  /// Submits once [length] digits are in, typed or pasted, without the
  /// button. Off by default: with a [rememberLabel], someone still to tick
  /// the box would be signed in before reaching it.
  final bool autoSubmit;

  /// A line between the code's label and its field, saying where the code
  /// comes from: "Enter the code from your authenticator app", "We emailed
  /// a code to you@example.com". Shown for the code, not the recovery code.
  final String? description;

  /// [description] for the recovery code.
  final String? recoveryDescription;

  /// The text of a checkbox for remembering the device; null shows none.
  final String? rememberLabel;

  /// Whether the remember checkbox starts ticked.
  final bool initialRemember;

  /// Offers a recovery code in place of the code.
  final bool allowRecoveryCode;

  /// Opens on the recovery code; needs [allowRecoveryCode].
  final bool initialRecovery;

  /// Goes back to the step before; null shows no link.
  final VoidCallback? onBack;

  /// The code's label; "Verification code" in the app's language when null.
  final String? codeLabel;

  /// The recovery code's label; "Recovery code" in the app's language when
  /// null.
  final String? recoveryCodeLabel;

  /// The submit's label; "Verify" in the app's language when null.
  final String? submitLabel;

  /// The back link's label; "Back to sign in" in the app's language when
  /// null.
  final String? backLabel;

  /// The link to the recovery code; "Use a recovery code" in the app's
  /// language when null.
  final String? useRecoveryCodeLabel;

  /// The link back to the code; "Use your authenticator app" in the app's
  /// language when null.
  final String? useCodeLabel;

  /// The key of the code input, to find it by in a test.
  final Key? codeKey;

  /// The key of the recovery code input, to find it by in a test.
  final Key? recoveryCodeKey;

  /// The key of the remember checkbox, to find it by in a test.
  final Key? rememberKey;

  /// The key of the submit button, to find it by in a test.
  final Key? submitKey;

  /// The key of the back link, to find it by in a test.
  final Key? backKey;

  /// The key of the link that swaps the code for a recovery code and back,
  /// to find it by in a test.
  final Key? recoveryToggleKey;

  const OneTimeCodeForm({
    super.key,
    required this.onSubmit,
    this.submitting = false,
    this.errorText,
    this.length = 6,
    this.autoSubmit = false,
    this.description,
    this.recoveryDescription,
    this.rememberLabel,
    this.initialRemember = false,
    this.allowRecoveryCode = false,
    this.initialRecovery = false,
    this.onBack,
    this.codeLabel,
    this.recoveryCodeLabel,
    this.submitLabel,
    this.backLabel,
    this.useRecoveryCodeLabel,
    this.useCodeLabel,
    this.codeKey,
    this.recoveryCodeKey,
    this.rememberKey,
    this.submitKey,
    this.backKey,
    this.recoveryToggleKey,
  }) : assert(length > 0, 'A code has at least one digit'),
       assert(
         !initialRecovery || allowRecoveryCode,
         'initialRecovery needs allowRecoveryCode',
       );

  @override
  State<OneTimeCodeForm> createState() => _OneTimeCodeFormState();
}

class _OneTimeCodeFormState extends State<OneTimeCodeForm> {
  final _code = GlobalKey<CodeInputState>();
  final _recoveryCode = GlobalKey<CodeInputState>();
  late bool _recovery = widget.initialRecovery;
  late bool _remember = widget.initialRemember;

  /// Whether [OneTimeCodeForm.errorText] is about the field that shows:
  /// swapping the field leaves it behind until the next submit.
  bool _errorShown = true;

  GlobalKey<CodeInputState> get _input => _recovery ? _recoveryCode : _code;

  void _swap() {
    setState(() {
      _recovery = !_recovery;
      _errorShown = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _input.currentState?.focus();
    });
  }

  void _submit(String code) {
    setState(() => _errorShown = true);
    widget.onSubmit(code, remember: _remember, isRecoveryCode: _recovery);
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.adminL10n.shell;
    final rememberLabel = widget.rememberLabel;
    final onBack = widget.onBack;
    final enabled = !widget.submitting;
    final error = _errorShown ? widget.errorText : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_recovery)
          CodeInput(
            key: _recoveryCode,
            length: null,
            label: widget.recoveryCodeLabel ?? shell.recoveryCode,
            description: widget.recoveryDescription,
            errorText: error,
            submitting: widget.submitting,
            autofocus: true,
            onSubmit: _submit,
            fieldKey: widget.recoveryCodeKey,
          )
        else
          CodeInput(
            key: _code,
            length: widget.length,
            autoSubmit: widget.autoSubmit,
            label: widget.codeLabel ?? shell.verificationCode,
            description: widget.description,
            errorText: error,
            submitting: widget.submitting,
            autofocus: true,
            onSubmit: _submit,
            fieldKey: widget.codeKey,
          ),
        if (rememberLabel != null) ...[
          const Gap(AdminSpacing.lg),
          Check(
            key: widget.rememberKey,
            value: _remember,
            label: rememberLabel,
            onChanged: enabled
                ? (value) => setState(() => _remember = value)
                : null,
          ),
        ],
        const Gap(AdminSpacing.xl),
        Button.primary(
          widget.submitLabel ?? shell.verify,
          key: widget.submitKey,
          expand: true,
          loading: widget.submitting,
          onPressed: () => _input.currentState?.submit(),
        ),
        if (widget.allowRecoveryCode || onBack != null) ...[
          const Gap(AdminSpacing.md),
          if (widget.allowRecoveryCode)
            Center(
              child: Button.link(
                _recovery
                    ? widget.useCodeLabel ?? shell.useAuthenticatorApp
                    : widget.useRecoveryCodeLabel ?? shell.useRecoveryCode,
                key: widget.recoveryToggleKey,
                size: ControlSize.small,
                onPressed: enabled ? _swap : null,
              ),
            ),
          if (onBack != null)
            Center(
              child: Button.link(
                widget.backLabel ?? shell.backToSignIn,
                key: widget.backKey,
                size: ControlSize.small,
                onPressed: enabled ? onBack : null,
              ),
            ),
        ],
      ],
    );
  }
}
