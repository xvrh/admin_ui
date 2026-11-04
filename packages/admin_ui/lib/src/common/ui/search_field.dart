import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import 'clear_button.dart';
import 'input_field.dart';

/// The standard list/toolbar search input: an [InputField] with a leading
/// search glyph and a [ClearButton] at its end once there's text.
///
/// Fires [onChanged] whenever the text changes — each keystroke, and the clear
/// — and never for a caret or selection move. With a [debounce] it waits for
/// the typing to settle instead (see there).
///
/// It takes the [InputField]'s size, state and message set, and its rule for
/// [value]: controlled unless a [controller] is passed, in which case the
/// controller's text is the one source of truth.
class SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// The placeholder; the localized "Search" when null.
  final String? hint;

  /// Fixed width; null stretches to the parent's constraints.
  final double? width;

  /// Validation message under the input; also turns its border red.
  final String? errorText;

  final ControlSize size;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;

  /// The keyboard's action key; a search key by default.
  final TextInputAction textInputAction;

  /// When set, [onChanged] fires once the text has been still for this long,
  /// rather than on every keystroke — for a search that queries a backend.
  /// Submitting and clearing report at once; text typed and taken back
  /// within the window never reports.
  final Duration? debounce;

  const SearchField({
    super.key,
    this.value = '',
    this.onChanged,
    this.onSubmitted,
    this.hint,
    this.width,
    this.errorText,
    this.size = ControlSize.medium,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction = TextInputAction.search,
    this.debounce,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController(text: widget.value));

  FocusNode? _ownFocus;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'SearchField'));

  /// The controller's text as last seen, so a notification that only moves
  /// the caret or the selection is ignored.
  late String _text;

  /// The text [SearchField.onChanged] last reported, or the parent last set.
  late String _reported;

  /// The [SearchField.debounce] wait for the text to settle.
  Timer? _pending;

  @override
  void initState() {
    super.initState();
    _text = _reported = _controller.text;
    _controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      (old.controller ?? _own)?.removeListener(_handleChange);
      _controller.addListener(_handleChange);
      if (widget.controller == null) _seed(widget.value);
      _cancelPending();
      _text = _reported = _controller.text;
    } else if (widget.controller == null && widget.value != old.value) {
      _seed(widget.value);
    }
  }

  /// Replaces the owned controller's text with a [value] the parent set,
  /// without reporting it back.
  void _seed(String value) {
    _cancelPending();
    _reported = value;
    if (value == _controller.text) return;
    _text = value;
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _handleChange() {
    final text = _controller.text;
    if (text == _text) return;
    final toggled = text.isEmpty != _text.isEmpty;
    _text = text;
    final debounce = widget.debounce;
    _cancelPending();
    if (debounce == null || text.isEmpty) {
      _report(text);
    } else if (text != _reported) {
      _pending = Timer(debounce, () => _report(text));
    }
    if (toggled) setState(() {});
  }

  void _report(String text) {
    _cancelPending();
    if (text == _reported) return;
    _reported = text;
    widget.onChanged?.call(text);
  }

  void _cancelPending() {
    _pending?.cancel();
    _pending = null;
  }

  void _submit(String text) {
    _report(text);
    widget.onSubmitted?.call(text);
  }

  void _clear() {
    _controller.clear();
    // The clear button leaves with the text; typing picks up where it was.
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _cancelPending();
    _controller.removeListener(_handleChange);
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = InputField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      size: widget.size,
      hint: widget.hint ?? MaterialLocalizations.of(context).searchFieldLabel,
      errorText: widget.errorText,
      icon: Icons.search_rounded,
      textInputAction: widget.textInputAction,
      onSubmitted: _submit,
      // The slot is kept while empty, so the clear button appearing on the
      // first keystroke doesn't reflow the text; until then it holds nothing
      // a pointer or Tab could land on.
      suffix: _controller.text.isEmpty
          ? const SizedBox.shrink()
          : ClearButton(
              onPressed: _clear,
              label: context.adminL10n.inputs.clearSearch,
            ),
    );
    return widget.width == null
        ? field
        : SizedBox(width: widget.width, child: field);
  }
}
