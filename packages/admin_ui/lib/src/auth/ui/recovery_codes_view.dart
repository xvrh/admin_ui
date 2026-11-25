/// @docImport 'auth_scaffold.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/button.dart';
import '../../common/ui/checkbox.dart';
import '../../common/ui/copy_button.dart';
import '../../common/ui/panel.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// The recovery codes, shown once when an authenticator app is linked: each
/// stands in for a code from the app once, for someone who has lost it.
///
/// The [codes] sit in a muted panel in the theme's monospace font, two to a
/// line where there is room for two and one where not, and can be selected.
/// "Copy all" puts them on the clipboard one per line. The button that
/// calls [onDone] is disabled until the box saying they are saved is
/// ticked, since the page does not come back.
///
/// It sizes itself to its content, so it sits in an [AuthScaffold]'s card
/// or in a modal's body alike.
///
/// Each label, when null, reads the kit's own in the app's language.
class RecoveryCodesView extends StatefulWidget {
  /// The codes, in the order the server gave them.
  final List<String> codes;

  /// Leaves the page, once the codes are saved.
  final VoidCallback onDone;

  /// A line above the codes, saying what they are for ("Each code signs
  /// you in once if you lose your phone"). Null shows none.
  final String? description;

  /// The copy button's label; "Copy all" in the app's language when null.
  final String? copyLabel;

  /// The checkbox's text; "I have saved these codes" in the app's language
  /// when null.
  final String? savedLabel;

  /// The done button's label; Material's "Continue" in the app's language
  /// when null.
  final String? doneLabel;

  /// The key of the panel of codes, to find it by in a test.
  final Key? codesKey;

  /// The key of the copy button, to find it by in a test.
  final Key? copyKey;

  /// The key of the checkbox, to find it by in a test.
  final Key? savedKey;

  /// The key of the done button, to find it by in a test.
  final Key? doneKey;

  const RecoveryCodesView({
    super.key,
    required this.codes,
    required this.onDone,
    this.description,
    this.copyLabel,
    this.savedLabel,
    this.doneLabel,
    this.codesKey,
    this.copyKey,
    this.savedKey,
    this.doneKey,
  });

  @override
  State<RecoveryCodesView> createState() => _RecoveryCodesViewState();
}

class _RecoveryCodesViewState extends State<RecoveryCodesView> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final shell = context.adminL10n.shell;
    final description = widget.description;
    final style = context.type.mono;
    final codes = widget.codes;
    final widest = codes.fold(
      0.0,
      (widest, code) => math.max(widest, textWidthOf(context, code, style)),
    );
    const gap = AdminSpacing.xxl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (description != null) ...[
          Text(description, style: context.type.body),
          const Gap(AdminSpacing.lg),
        ],
        Panel(
          key: widget.codesKey,
          color: context.colors.surfaceMuted,
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.md,
          ),
          child: Center(
            // At most two to a line: a wider grid reads as a table.
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 2 * widest + gap),
              child: SelectionArea(
                child: Wrap(
                  spacing: gap,
                  runSpacing: AdminSpacing.xs,
                  children: [
                    for (final code in codes)
                      SizedBox(
                        width: widest,
                        child: Text(
                          code,
                          style: style,
                          // Physical: a code reads left to right.
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Gap(AdminSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CopyButton(
            codes.join('\n'),
            key: widget.copyKey,
            label: widget.copyLabel ?? shell.copyAllCodes,
            flush: true,
          ),
        ),
        const Gap(AdminSpacing.lg),
        Check(
          key: widget.savedKey,
          value: _saved,
          label: widget.savedLabel ?? shell.savedRecoveryCodes,
          onChanged: (value) => setState(() => _saved = value),
        ),
        const Gap(AdminSpacing.xl),
        Button.primary(
          widget.doneLabel ??
              MaterialLocalizations.of(context).continueButtonLabel,
          key: widget.doneKey,
          expand: true,
          onPressed: _saved ? widget.onDone : null,
        ),
      ],
    );
  }
}
