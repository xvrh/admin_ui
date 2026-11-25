/// @docImport 'icon_action.dart';
/// @docImport 'password_field.dart';
/// @docImport 'search_field.dart';
library;

import 'dart:async';
import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'browser_menu_hold.dart';
import 'field_chrome.dart';
import 'input_decoration.dart';
import 'labeled_field.dart';

/// A plain text input with the token field border, an optional label row and an
/// inline [errorText] message.
///
/// The counterpart to [PasswordField] and [SearchField] for ordinary text, for
/// a form, a dialog or a settings pane. Without it such forms reach for a bare
/// Material `TextFormField`, whose floating `labelText` chrome doesn't match
/// anything else in the admin.
///
/// [value] is controlled unless a [controller] is passed: the field then owns
/// a controller seeded from [value], and a parent that passes a different
/// [value] replaces the text (a reset, a revert); a [value] that stays the same
/// leaves what the user typed alone. A [controller] is the text's one source
/// of truth, and [value] is ignored.
///
/// One line is exactly the [size]'s control height (`context.sizes`); set
/// [maxLines] above 1 (or null) for a multi-line box. [enabled] false dims the
/// field and takes it out of the Tab order; [readOnly] keeps it at full
/// contrast, focusable and selectable, but not editable (see [FieldState]).
/// An enclosing [FieldStateScope] can disable it or make it read-only too, and
/// a bare one (no [label]) takes its red outline from the scope it sits in.
class InputField extends StatefulWidget {
  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Label above the input. Null renders the bare control, for a caller that
  /// supplies its own [LabeledField] or table-cell chrome.
  final String? label;

  /// Shown at the far end of the label row.
  final Widget? labelTrailing;

  /// Muted line between the label and the input.
  final String? description;

  final String? hint;

  /// Validation message under the input; also turns its border red and marks
  /// it invalid for assistive technology.
  final String? errorText;

  /// Keeps the room of a one-line [errorText] under the input while there is
  /// none, so validating does not move what follows (see
  /// [LabeledField.reserveErrorLine]).
  final bool reserveErrorLine;

  /// Leading glyph inside the input.
  final IconData? icon;

  /// An action at the end of the input — a clear or reveal [IconAction] at
  /// the inline size. It sits in the field's trailing slot and never makes
  /// the field taller.
  final Widget? suffix;

  /// Hides the text, as in a [PasswordField].
  final bool obscureText;

  final ControlSize size;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;

  /// 1 for a single line (the default); a higher number — or null to grow
  /// without bound — for a multi-line box.
  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// Rewrites what is typed or pasted before the field takes it, as a
  /// [TextField]'s do: [FilteringTextInputFormatter.digitsOnly] for a field
  /// of digits, a [LengthLimitingTextInputFormatter] for one that holds so
  /// many characters at most, with no counter under it.
  final List<TextInputFormatter>? inputFormatters;

  /// Sets the value and the [hint] in the theme's monospace font
  /// (`AdminTypeSpec.applyMonoFont`), with tabular figures, at the field's
  /// size and on its line, so the field keeps its height: for a code, a key
  /// or an identifier, read one character at a time.
  final bool monospace;

  /// The direction the text is typed and shown in, when not the ambient
  /// one. Null reads an email or URL [keyboardType] as left to right, since
  /// an address reads so in every language, and follows the ambient
  /// direction otherwise. The label, icon and border stay in the ambient
  /// direction either way.
  final TextDirection? textDirection;

  /// Builds the menu a right-click or a long press opens in the field, in
  /// place of the platform's: items of the app's own above
  /// `editableTextState.contextMenuButtonItems`, such as the spellings to
  /// replace the word under the pointer with. Null: the platform's menu,
  /// which on the web is the browser's.
  ///
  /// On the web the browser's own menu is off while the pointer is over a
  /// field that has one, so this one opens there.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  const InputField({
    super.key,
    this.value = '',
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.labelTrailing,
    this.description,
    this.hint,
    this.errorText,
    this.reserveErrorLine = false,
    this.icon,
    this.suffix,
    this.obscureText = false,
    this.size = ControlSize.medium,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.monospace = false,
    this.textDirection,
    this.contextMenuBuilder,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  final _browserMenu = BrowserMenuHold();

  /// Whether the field goes without its menu for a frame. Flutter decides
  /// whether a field uses its own menu when the field takes the focus, and
  /// on the web it does not while the browser's menu is on: a field focused
  /// from the keyboard, the pointer elsewhere, would never open its menu.
  /// Without one for a frame, then with it again, it decides anew.
  bool _menuGone = false;
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController(text: widget.value));

  @override
  void didUpdateWidget(InputField old) {
    super.didUpdateWidget(old);
    final value = widget.value;
    if (widget.controller == null &&
        (old.controller != null || value != old.value) &&
        value != _controller.text) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    if (widget.contextMenuBuilder == null) _browserMenu.over = false;
  }

  void _enter() {
    if (widget.contextMenuBuilder == null) return;
    _browserMenu.over = true;
    if (!kIsWeb) return;
    unawaited(
      _browserMenu.off.then((_) {
        if (!mounted || !_browserMenu.over) return;
        setState(() => _menuGone = true);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _menuGone = false);
        });
      }),
    );
  }

  @override
  void dispose() {
    _browserMenu.over = false;
    _own?.dispose();
    super.dispose();
  }

  Widget _input(BuildContext context) {
    final state = FieldStateScope.of(context);
    final direction = inputTextDirection(
      widget.textDirection,
      widget.keyboardType,
    );
    final menu = widget.contextMenuBuilder;
    final decoration = fieldInputDecoration(
      context,
      hint: widget.hint,
      size: widget.size,
      leadingIcon: widget.icon,
      suffix: widget.suffix,
    ).copyWith(counterText: '', hintTextDirection: direction);
    return MouseRegion(
      opaque: false,
      onEnter: (_) => _enter(),
      onExit: (_) => _browserMenu.over = false,
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: state.enabled,
        readOnly: state.readOnly,
        obscureText: widget.obscureText,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        inputFormatters: widget.inputFormatters,
        textDirection: direction,
        style: _mono(context, fieldTextStyle(context, size: widget.size)),
        decoration: widget.monospace
            ? decoration.copyWith(
                hintStyle: _mono(context, decoration.hintStyle!),
              )
            : decoration,
        contextMenuBuilder: _menuGone ? null : menu ?? _platformMenu,
      ),
    );
  }

  /// [style] in the monospace font, when the field is [InputField.monospace].
  TextStyle _mono(BuildContext context, TextStyle style) => widget.monospace
      ? context.type.spec
            .applyMonoFont(style)
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()])
      : style;

  /// [TextField]'s own default: the platform's menu.
  static Widget _platformMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) => AdaptiveTextSelectionToolbar.editableText(
    editableTextState: editableTextState,
  );

  @override
  Widget build(BuildContext context) {
    final input = Builder(builder: _input);
    final label = widget.label;
    if (label != null) {
      return LabeledField(
        label: label,
        trailing: widget.labelTrailing,
        description: widget.description,
        errorText: widget.errorText,
        reserveErrorLine: widget.reserveErrorLine,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        child: input,
      );
    }
    return _BareField(
      error: widget.errorText,
      reserveErrorLine: widget.reserveErrorLine,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      child: input,
    );
  }
}

/// An [InputField] without a label row: [child] under the [FieldStateScope]
/// of [enabled], [readOnly] and the [error] — or the enclosing scope's own
/// invalid state, for a field shell that holds the message — announced as
/// failing validation while invalid. The [error] shows under it as a
/// [FieldMessage]; [child] keeps its place in the tree either way, so a
/// message appearing mid-typing never drops the focus.
class _BareField extends StatelessWidget {
  final String? error;
  final bool reserveErrorLine;
  final bool enabled;
  final bool readOnly;
  final Widget child;

  const _BareField({
    this.error,
    required this.reserveErrorLine,
    required this.enabled,
    required this.readOnly,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final invalid = error != null || FieldStateScope.of(context).invalid;
    return FieldStateScope(
      enabled: enabled,
      readOnly: readOnly,
      invalid: invalid,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            hint: error,
            validationResult: invalid
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: child,
          ),
          if (error != null)
            FieldErrorText(error)
          else if (reserveErrorLine) ...[
            const Gap(AdminSpacing.md),
            SizedBox(height: lineHeightOf(context, context.type.fieldMessage)),
          ],
        ],
      ),
    );
  }
}
