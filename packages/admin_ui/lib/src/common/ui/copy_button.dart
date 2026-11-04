import 'dart:async';

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/tokens.dart';
import 'button.dart';
import 'icon_action.dart';

/// A compact "copy to clipboard" affordance with built-in feedback — for IDs,
/// slugs, API keys, URLs. Tapping copies [text] and flips to a check +
/// "Copied" for a moment before reverting; a screen reader hears "Copied"
/// too. When the platform refuses the copy (a browser outside a secure
/// context), it shows a danger glyph and [failedLabel] instead, announces
/// that, and does not call [onCopied].
///
/// Icon-only by default: an inline [IconAction], named and tooltipped by
/// [tooltip]. Pass [label] for a small ghost [Button] — its height, padding,
/// hover and focus ring — that keeps the width of the longest of [label],
/// [copiedLabel] and [failedLabel], so the outcome never moves what follows
/// it.
/// [onCopied] fires after the copy so a caller can also raise a toast.
class CopyButton extends StatefulWidget {
  final String text;

  /// Optional visible label; null renders an icon-only button.
  final String? label;

  /// Hover tooltip and accessible name (icon-only mode). The localized
  /// "Copy" when null.
  final String? tooltip;

  /// Confirmation shown and announced after a copy. The localized "Copied"
  /// when null.
  final String? copiedLabel;

  /// Shown and announced when the copy fails. The localized "Copy failed"
  /// when null.
  final String? failedLabel;

  /// The icon-only glyph's size; `context.iconSizes.sm` when null. A
  /// labelled button's glyph is a small [Button]'s.
  final double? iconSize;

  /// How long the confirmation (or the failure) lingers.
  final Duration revertAfter;

  /// Lines a labelled button's glyph up with the content edge it sits under
  /// (see `Button.flush`).
  final bool flush;

  final VoidCallback? onCopied;

  /// Puts the text on the clipboard: [Clipboard.setData] when null. One
  /// given instead completes once the text is there and throws when it
  /// could not put it there — a plugin that writes a richer format, or a
  /// catalog pinning either outcome.
  final Future<void> Function(String text)? write;

  const CopyButton(
    this.text, {
    super.key,
    this.label,
    this.tooltip,
    this.copiedLabel,
    this.failedLabel,
    this.iconSize,
    this.revertAfter = const Duration(milliseconds: 1500),
    this.flush = false,
    this.onCopied,
    this.write,
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

enum _Outcome { none, copied, failed }

class _CopyButtonState extends State<CopyButton> {
  _Outcome _outcome = _Outcome.none;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _copiedLabel =>
      widget.copiedLabel ?? context.adminL10n.inputs.copied;

  String get _failedLabel =>
      widget.failedLabel ?? context.adminL10n.inputs.copyFailed;

  Future<void> _copy() async {
    final copied = await copyText(
      context,
      widget.text,
      write: widget.write,
      copiedLabel: _copiedLabel,
      failedLabel: _failedLabel,
    );
    if (copied) widget.onCopied?.call();
    if (!mounted) return;
    setState(() => _outcome = copied ? _Outcome.copied : _Outcome.failed);
    _timer?.cancel();
    _timer = Timer(widget.revertAfter, () {
      if (mounted) setState(() => _outcome = _Outcome.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, iconColor) = switch (_outcome) {
      _Outcome.none => (Icons.copy_rounded, null),
      _Outcome.copied => (Icons.check_rounded, colors.successText),
      _Outcome.failed => (Icons.error_outline_rounded, colors.dangerText),
    };

    final label = widget.label;
    if (label == null) {
      return IconAction(
        icon,
        label: switch (_outcome) {
          _Outcome.none =>
            widget.tooltip ?? MaterialLocalizations.of(context).copyButtonLabel,
          _Outcome.copied => _copiedLabel,
          _Outcome.failed => _failedLabel,
        },
        onPressed: _copy,
        size: IconActionSize.inline,
        iconSize: widget.iconSize ?? context.iconSizes.sm,
        color: iconColor,
      );
    }

    // The idle, copied and failed labels are all laid out, hidden, so the
    // button is as wide as the longest whichever shows.
    Widget sizer(String text) => Visibility(
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: Button.ghost(text, size: ControlSize.small, icon: icon),
    );
    return IntrinsicWidth(
      child: Stack(
        alignment: Alignment.center,
        children: [
          sizer(label),
          sizer(_copiedLabel),
          sizer(_failedLabel),
          Button.ghost(
            switch (_outcome) {
              _Outcome.none => label,
              _Outcome.copied => _copiedLabel,
              _Outcome.failed => _failedLabel,
            },
            size: ControlSize.small,
            icon: icon,
            iconColor: iconColor,
            expand: true,
            flush: widget.flush,
            onPressed: _copy,
          ),
        ],
      ),
    );
  }
}

/// Puts [text] on the clipboard — through [write] when given, else
/// [Clipboard.setData] — and announces the outcome: [copiedLabel], or
/// [failedLabel] when the platform refuses the copy (a browser outside a
/// secure context); the localized "Copied" and "Copy failed" when null.
/// Completes with whether the text got there, and never throws. Every copy
/// affordance in the kit copies through it, so each reports a failure alike.
@internal
Future<bool> copyText(
  BuildContext context,
  String text, {
  Future<void> Function(String text)? write,
  String? copiedLabel,
  String? failedLabel,
}) async {
  final strings = context.adminL10n.inputs;
  final copied = copiedLabel ?? strings.copied;
  final failed = failedLabel ?? strings.copyFailed;
  final view = View.of(context);
  final direction = Directionality.of(context);
  var ok = true;
  try {
    if (write != null) {
      await write(text);
    } else {
      await Clipboard.setData(ClipboardData(text: text));
    }
  } catch (_) {
    // Whatever the platform threw, nothing reached the clipboard.
    ok = false;
  }
  unawaited(
    SemanticsService.sendAnnouncement(view, ok ? copied : failed, direction),
  );
  return ok;
}
