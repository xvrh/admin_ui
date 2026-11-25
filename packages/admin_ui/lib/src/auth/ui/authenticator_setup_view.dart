/// @docImport 'auth_scaffold.dart';
/// @docImport 'one_time_code_form.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/copy_button.dart';
import '../../common/ui/panel.dart';
import '../../common/ui/qr_code.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'code_input.dart';

/// Links an authenticator app: a QR code of [uri] to scan, the [secret] for
/// whoever cannot scan it, and the code the app then shows, which proves the
/// link took.
///
/// [uri] is the `otpauth://totp/…` URI the host's server made, and [secret]
/// the base32 key inside it. The key waits behind a "Can't scan the code?"
/// link under the QR code, so the screen asks one thing at a time; with
/// [initiallyShowsSecret] it shows from the start. Shown, it reads in groups
/// of four, in the theme's monospace font, selectable, with a button that
/// copies it without the spaces.
///
/// The code field is [OneTimeCodeForm]'s: [length] digits, digits only,
/// with the platform's one-time code autofill; Enter submits, as the button
/// does, and with [autoSubmit] the last digit does too. A submit with the
/// field empty marks it required, and one short of [length] digits says how
/// many a code has.
///
/// View-pure: the host maps the server's answer into [errorText] and flips
/// [submitting]. [errorText] shows under the field, about the code as it
/// stood when it came; the submit that ends with it takes focus back to the
/// field with the code selected. [onCancel] null shows no cancel button.
///
/// It sizes itself to its content, so it sits in an [AuthScaffold]'s card
/// or in a modal's body alike.
///
/// Each label, when null, reads the kit's own in the app's language.
class AuthenticatorSetupView extends StatefulWidget {
  /// The `otpauth://` URI the QR code holds.
  final String uri;

  /// The base32 key of [uri], to type into an app that cannot scan.
  final String secret;

  /// Called with the trimmed code once it is whole.
  final ValueChanged<String> onSubmit;

  /// Abandons the setup; null shows no cancel button.
  final VoidCallback? onCancel;

  final bool submitting;

  /// The refusal of the code, under the field.
  final String? errorText;

  /// The digits of a code.
  final int length;

  /// Submits once [length] digits are in, typed or pasted, without the
  /// button.
  final bool autoSubmit;

  /// A line above the QR code: what to do with it ("Scan the code with
  /// your authenticator app, then enter the code it shows"). Null shows
  /// none, for a host that says it in the page's own subtitle.
  final String? description;

  /// The QR code's side, quiet zone included.
  final double qrSize;

  /// What a screen reader hears for the QR code; "QR code for your
  /// authenticator app" in the app's language when null.
  final String? qrLabel;

  /// Shows the key from the start, without the link.
  final bool initiallyShowsSecret;

  /// The link that shows the key; "Can't scan the code?" in the app's
  /// language when null.
  final String? cantScanLabel;

  /// The line above the key once shown; "Enter this key in your app
  /// instead." in the app's language when null.
  final String? secretLabel;

  /// The accessible name of the key's copy button; "Copy key" in the app's
  /// language when null.
  final String? copySecretLabel;

  /// The code's label; "Verification code" in the app's language when null.
  final String? codeLabel;

  /// The submit's label; "Verify" in the app's language when null.
  final String? submitLabel;

  /// The cancel button's label; Material's "Cancel" in the app's language
  /// when null.
  final String? cancelLabel;

  /// The key of the QR code, to find it by in a test.
  final Key? qrKey;

  /// The key of the link that shows the key, to find it by in a test.
  final Key? cantScanKey;

  /// The key of the text of the key, to find it by in a test.
  final Key? secretKey;

  /// The key of the key's copy button, to find it by in a test.
  final Key? copySecretKey;

  /// The key of the code input, to find it by in a test.
  final Key? codeKey;

  /// The key of the submit button, to find it by in a test.
  final Key? submitKey;

  /// The key of the cancel button, to find it by in a test.
  final Key? cancelKey;

  const AuthenticatorSetupView({
    super.key,
    required this.uri,
    required this.secret,
    required this.onSubmit,
    this.onCancel,
    this.submitting = false,
    this.errorText,
    this.length = 6,
    this.autoSubmit = false,
    this.description,
    this.qrSize = 176,
    this.qrLabel,
    this.initiallyShowsSecret = false,
    this.cantScanLabel,
    this.secretLabel,
    this.copySecretLabel,
    this.codeLabel,
    this.submitLabel,
    this.cancelLabel,
    this.qrKey,
    this.cantScanKey,
    this.secretKey,
    this.copySecretKey,
    this.codeKey,
    this.submitKey,
    this.cancelKey,
  }) : assert(length > 0, 'A code has at least one digit');

  @override
  State<AuthenticatorSetupView> createState() => _AuthenticatorSetupViewState();
}

class _AuthenticatorSetupViewState extends State<AuthenticatorSetupView> {
  final _code = GlobalKey<CodeInputState>();
  late bool _showsSecret = widget.initiallyShowsSecret;

  /// [AuthenticatorSetupView.secret] without its whitespace.
  String get _secret => widget.secret.replaceAll(RegExp(r'\s'), '');

  /// [_secret] in groups of four, as an app's setup screen asks for it.
  String get _grouped {
    final secret = _secret;
    return [
      for (var i = 0; i < secret.length; i += 4)
        secret.substring(i, math.min(i + 4, secret.length)),
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.adminL10n.shell;
    final description = widget.description;
    final onCancel = widget.onCancel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (description != null) ...[
          Text(description, style: context.type.body),
          const Gap(AdminSpacing.lg),
        ],
        Center(
          child: QrCodeView(
            widget.uri,
            key: widget.qrKey,
            size: widget.qrSize,
            semanticLabel: widget.qrLabel ?? shell.authenticatorQrCode,
          ),
        ),
        const Gap(AdminSpacing.md),
        if (_showsSecret) ...[
          Text(
            widget.secretLabel ?? shell.enterSetupKey,
            style: context.type.caption,
          ),
          const Gap(AdminSpacing.sm),
          Panel(
            color: context.colors.surfaceMuted,
            radius: context.radii.radiusField,
            clip: false,
            padding: const EdgeInsetsDirectional.only(
              start: AdminSpacing.md,
              end: AdminSpacing.xs,
              top: AdminSpacing.xs,
              bottom: AdminSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _grouped,
                    key: widget.secretKey,
                    style: context.type.mono,
                    // Physical: a key reads left to right in every language.
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const Gap(AdminSpacing.xs),
                CopyButton(
                  _secret,
                  key: widget.copySecretKey,
                  tooltip: widget.copySecretLabel ?? shell.copySetupKey,
                ),
              ],
            ),
          ),
        ] else
          Center(
            child: Button.link(
              widget.cantScanLabel ?? shell.cantScanQrCode,
              key: widget.cantScanKey,
              size: ControlSize.small,
              onPressed: () => setState(() => _showsSecret = true),
            ),
          ),
        const Gap(AdminSpacing.xl),
        CodeInput(
          key: _code,
          length: widget.length,
          autoSubmit: widget.autoSubmit,
          label: widget.codeLabel ?? shell.verificationCode,
          errorText: widget.errorText,
          submitting: widget.submitting,
          onSubmit: widget.onSubmit,
          fieldKey: widget.codeKey,
        ),
        const Gap(AdminSpacing.xl),
        Button.primary(
          widget.submitLabel ?? shell.verify,
          key: widget.submitKey,
          expand: true,
          loading: widget.submitting,
          onPressed: () => _code.currentState?.submit(),
        ),
        if (onCancel != null) ...[
          const Gap(AdminSpacing.md),
          Button(
            widget.cancelLabel ??
                MaterialLocalizations.of(context).cancelButtonLabel,
            key: widget.cancelKey,
            expand: true,
            onPressed: widget.submitting ? null : onCancel,
          ),
        ],
      ],
    );
  }
}
