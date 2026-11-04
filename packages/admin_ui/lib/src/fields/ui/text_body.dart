/// @docImport '../../theme/palette.dart';
library;

import 'package:flutter/foundation.dart' show internal;
import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// The bare text control — no label or capability chrome. Like [BooleanBody] and
/// [MediaBody], it's chrome-free so the same body sits inside a [FieldShell] (a
/// real `String`) or one lane of a translatable field (one entry of a
/// `Translated<String>`).
///
/// Two ways to drive it: hand it a [controller] you own (you read the text), or
/// give it a [value] and an [onChanged] and it manages an internal controller —
/// reseeding when the value changes underneath it (e.g. a live-linked inherited
/// lane). In the managed mode a null [onChanged] renders it read-only (an
/// inherited preview) — full contrast, focusable and selectable, see
/// [FieldState]; a caller-owned [controller] stays editable. [enabled] false,
/// or a disabled [FieldStateScope], disables it.
///
/// [maxLines] above 1, or null, makes it a text area that grows with its
/// content from [minLines]; [maxLength] caps and counts the characters.
class TextBody extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final bool enabled;

  /// Line bounds: more than one line, or a null [maxLines], makes a text area
  /// that grows with its content.
  final int? minLines;
  final int? maxLines;

  /// A character limit, counted under the input.
  final int? maxLength;

  /// Defaults to a multi-line keyboard for a text area.
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  /// Fixed text before and after the value — `https://`, `kg`.
  final String? prefix;
  final String? suffix;

  const TextBody({
    super.key,
    this.controller,
    this.focusNode,
    this.value,
    this.onChanged,
    this.hint,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.autofillHints,
    this.prefix,
    this.suffix,
  });

  @override
  State<TextBody> createState() => _TextBodyState();
}

class _TextBodyState extends State<TextBody> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.value ?? ''));
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void didUpdateWidget(covariant TextBody old) {
    super.didUpdateWidget(old);
    // Reseed when the value changes outside the field (revert, live-link).
    // Ordinary typing keeps controller and value in sync, so this no-ops.
    if (widget.controller == null &&
        widget.value != null &&
        widget.value != _controller.text) {
      _controller.text = widget.value!;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: widget.controller == null && widget.onChanged == null,
      builder: (context) => TextField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: FieldStateScope.of(context).readOnly,
        onChanged: widget.onChanged,
        style: fieldTextStyle(context),
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        keyboardType: textKeyboardType(widget.keyboardType, widget.maxLines),
        autofillHints: widget.autofillHints,
        decoration: textInputDecoration(
          context,
          hint: widget.hint,
          prefix: widget.prefix,
          suffix: widget.suffix,
        ),
      ),
    );
  }
}

/// The decoration of a text input body: [fieldInputDecoration] with [hint],
/// the fixed [prefix] and [suffix] in the value's type and the `maxLength`
/// counter in the caption type.
///
/// An affix is [AdminPalette.foregroundSecondary], a step above the hint's
/// placeholder colour, and 4 from the value, so beside an empty input's
/// hint it still reads as fixed text rather than more of the hint. The
/// counter is the ambient [FieldStateScope]'s glyph colour; both turn
/// [AdminPalette.foregroundSubtle] while disabled. [TextBody] and the bound
/// text field share it, so the two draw the same.
@internal
InputDecoration textInputDecoration(
  BuildContext context, {
  String? hint,
  String? prefix,
  String? suffix,
}) {
  final colors = context.colors;
  final state = FieldStateScope.of(context);
  final style = context.type.fieldText.copyWith(
    color: state.enabled ? colors.foregroundSecondary : colors.foregroundSubtle,
  );
  Widget? affix(String? text, EdgeInsetsDirectional padding) => text == null
      ? null
      : Padding(
          padding: padding,
          child: Text(text, style: style),
        );
  return fieldInputDecoration(context, hint: hint).copyWith(
    prefix: affix(
      prefix,
      const EdgeInsetsDirectional.only(end: AdminSpacing.xs),
    ),
    suffix: affix(
      suffix,
      const EdgeInsetsDirectional.only(start: AdminSpacing.xs),
    ),
    counterStyle: context.type.caption.copyWith(color: state.iconColor(colors)),
    // Keeps the affixes in view while the input is empty.
    floatingLabelBehavior: FloatingLabelBehavior.always,
  );
}

/// [keyboardType], or a multi-line keyboard for a text area (any [maxLines]
/// but 1).
@internal
TextInputType? textKeyboardType(TextInputType? keyboardType, int? maxLines) =>
    keyboardType ?? (maxLines == 1 ? null : TextInputType.multiline);
