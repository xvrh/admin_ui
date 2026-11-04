import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// Common mask templates. A mask is a plain string of tokens and literals — pass
/// your own to [MaskedBody.mask] for anything not here.
abstract final class Masks {
  static const phoneUS = '(###) ###-####';
  static const phoneIntl = '+## ### ### ####';
  static const creditCard = '#### #### #### ####';
  static const expiry = '##/##';
  static const cvc = '###';
  static const date = '##/##/####';
  static const time = '##:##';
  static const ssn = '###-##-####';
  static const ipv4 = '###.###.###.###';
  static const hexColor = r'\#******';
}

/// Reformats a [TextField] live against a [mask] of tokens and literals.
///
/// Tokens — `#` a digit, `A` a letter, `*` a letter or digit. Every other
/// character is a literal that's inserted automatically as you type; prefix a
/// token with `\` to use it as a literal (e.g. `\#` for a hash). Characters that
/// don't fit the next slot are dropped, so pasting a raw `+15551234567` into
/// `(###) ###-####` lands `(155) 512-3456` and the caret follows the edit
/// wherever it happens — middle, paste, or selection-replace.
///
/// [eager] reveals a separator the moment its group is complete — `15` over
/// `##:##` shows `15:` — rather than waiting for the next character. It stays
/// deletable: a separator only auto-appears while typing/pasting, never while
/// deleting, so backspace peels it off instead of resurrecting it.
class MaskFormatter extends TextInputFormatter {
  final String mask;
  final bool eager;
  final List<_Slot> _slots;

  MaskFormatter(this.mask, {this.eager = false}) : _slots = _parse(mask);

  /// The raw payload — the typed characters with literals and separators
  /// stripped, in mask order. `(155) 512-3456` → `1555123456`.
  static String unmask(String mask, String text) =>
      MaskFormatter(mask)._extract(text, text.length).chars.join();

  /// Format a raw string through the mask, as if typed from empty.
  /// `1555123456` over `(###) ###-####` → `(155) 512-3456`.
  static String apply(String mask, String raw, {bool eager = false}) =>
      MaskFormatter(mask, eager: eager).format(raw);

  /// Run [raw] through the mask from an empty start — the seed path.
  String format(String raw) => formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    ),
  ).text;

  ({List<String> chars, int beforeCursor}) _extract(String text, int cursor) {
    final chars = <String>[];
    var beforeCursor = 0;
    var si = 0;
    for (var i = 0; i < text.length; i++) {
      while (si < _slots.length && !_slots[si].placeholder) {
        si++;
      }
      if (si >= _slots.length) break;
      final ch = text[i];
      if (_slots[si].pattern!.hasMatch(ch)) {
        chars.add(ch);
        if (i < cursor) beforeCursor++;
        si++;
      }
    }
    return (chars: chars, beforeCursor: beforeCursor);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.end.clamp(0, text.length);

    // Backspace landing on a literal separator: the separator isn't
    // independently deletable (we'd just re-insert it and trap the caret on it).
    // Eat the data character before it instead, so backspace makes progress.
    if (oldValue.text.length - text.length == 1 &&
        newValue.selection.end < oldValue.selection.end) {
      final removedAt = cursor; // index in oldValue that was deleted
      if (cursor > 0 &&
          removedAt < _slots.length &&
          !_slots[removedAt].placeholder) {
        text = text.substring(0, cursor - 1) + text.substring(cursor);
        cursor -= 1;
      }
    }

    final extracted = _extract(text, cursor);
    final payload = extracted.chars;

    // Empty stays empty — so the field can be cleared and the hint shows,
    // instead of leading literals re-materialising a non-empty value.
    if (payload.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Emit a literal only while payload still follows it: the base pass never
    // leaves a dangling separator, so [eager] off keeps them all deletable.
    final out = StringBuffer();
    var pi = 0;
    var emitted = 0;
    int? cursorOut;
    var stop = _slots.length;
    for (var si = 0; si < _slots.length; si++) {
      if (pi >= payload.length) {
        stop = si;
        break;
      }
      final slot = _slots[si];
      if (slot.placeholder) {
        if (cursorOut == null && emitted == extracted.beforeCursor) {
          cursorOut = out.length;
        }
        out.write(payload[pi]);
        pi++;
        emitted++;
      } else {
        out.write(slot.literal);
      }
    }
    var result = out.toString();
    var caret = cursorOut ?? result.length;

    // Eager: once the payload fills a group, reveal the separator(s) up to the
    // next placeholder — but only while growing the text, so deleting peels the
    // separator off cleanly instead of the caret sticking on it.
    if (eager &&
        pi >= payload.length &&
        newValue.text.length >= oldValue.text.length) {
      final tail = StringBuffer();
      for (var si = stop; si < _slots.length; si++) {
        if (_slots[si].placeholder) break;
        tail.write(_slots[si].literal);
      }
      if (tail.isNotEmpty) {
        final atEnd = caret == result.length;
        result += tail.toString();
        if (atEnd) caret = result.length;
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: caret.clamp(0, result.length)),
    );
  }

  /// The mask rendered as a fill-in template — tokens become [fill], literals
  /// stay. `(###) ###-####` → `(___) ___-____`.
  String template([String fill = '_']) {
    final b = StringBuffer();
    for (final s in _slots) {
      b.write(s.placeholder ? fill : s.literal);
    }
    return b.toString();
  }

  /// Number of token (placeholder) slots — the mask's capacity.
  int get length => _slots.where((s) => s.placeholder).length;

  /// True once every token slot is filled.
  bool complete(String text) =>
      _extract(text, text.length).chars.length >= length;
}

class _Slot {
  final bool placeholder;
  final String literal;
  final RegExp? pattern;

  const _Slot.literal(this.literal) : placeholder = false, pattern = null;
  const _Slot.token(this.pattern) : placeholder = true, literal = '';
}

final _digit = RegExp(r'[0-9]');
final _letter = RegExp(r'[A-Za-z]');
final _alnum = RegExp(r'[A-Za-z0-9]');

List<_Slot> _parse(String mask) {
  final slots = <_Slot>[];
  for (var i = 0; i < mask.length; i++) {
    final c = mask[i];
    if (c == r'\' && i + 1 < mask.length) {
      slots.add(_Slot.literal(mask[i + 1]));
      i++;
      continue;
    }
    switch (c) {
      case '#':
        slots.add(_Slot.token(_digit));
      case 'A':
        slots.add(_Slot.token(_letter));
      case '*':
        slots.add(_Slot.token(_alnum));
      default:
        slots.add(_Slot.literal(c));
    }
  }
  return slots;
}

/// The bare masked control — no label or capability chrome, so it sits inside a
/// [FieldShell] like the other field bodies. Holds the *formatted* string as its
/// value; [MaskFormatter.unmask] recovers the raw payload for storage.
///
/// Drive it like [TextBody]: a [controller] you own, or a [value] + [onChanged]
/// with an internal controller that reseeds when the value changes underneath.
/// A null [onChanged] (managed mode) renders it read-only — full contrast,
/// focusable and selectable, see [FieldState]. [enabled] false, or a disabled
/// [FieldStateScope], disables it.
class MaskedBody extends StatefulWidget {
  final String mask;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? value;
  final ValueChanged<String>? onChanged;

  /// Overrides the auto-generated fill-in template hint.
  final String? hint;

  /// Show the mask template (`(___) ___-____`) as the placeholder when empty.
  /// Ignored when [ghostMask] is on.
  final bool showTemplate;

  /// Keep the unfilled positions visible at all times as a faint inline ghost —
  /// typing `15` over `##:##` shows `15` solid with `:__` trailing in grey. The
  /// ghost suffix sits exactly where the next character will land.
  final bool ghostMask;

  /// The string the ghost draws when [ghostMask] is on — must match the mask
  /// length and literal positions. Lets a date field show `MM/DD/YYYY` instead
  /// of `__/__/____`. Defaults to the `_`-filled template.
  final String? ghostTemplate;

  /// Reveal a separator as soon as its group is filled (`15` → `15:`). Off by
  /// default; see [MaskFormatter.eager].
  final bool eager;

  final TextInputType? keyboardType;

  /// Forces read-only regardless of how it's driven. Null uses the default —
  /// read-only only in managed mode with a null [onChanged].
  final bool? readOnly;

  final bool enabled;

  /// A custom formatter (e.g. a clamping date formatter) in place of the default
  /// [MaskFormatter] built from [mask] + [eager]. Must format the same [mask].
  final MaskFormatter? formatter;

  const MaskedBody({
    super.key,
    required this.mask,
    this.controller,
    this.focusNode,
    this.value,
    this.onChanged,
    this.hint,
    this.showTemplate = true,
    this.ghostMask = false,
    this.ghostTemplate,
    this.eager = false,
    this.keyboardType,
    this.readOnly,
    this.enabled = true,
    this.formatter,
  });

  @override
  State<MaskedBody> createState() => _MaskedBodyState();
}

class _MaskedBodyState extends State<MaskedBody> {
  late final MaskFormatter _formatter =
      widget.formatter ?? MaskFormatter(widget.mask, eager: widget.eager);
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  String get _seed => _formatter.format(widget.value ?? '');

  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: _seed));
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  bool get _readOnly =>
      widget.readOnly ??
      (widget.controller == null && widget.onChanged == null);
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    // The ghost overlay redraws on every keystroke (suffix shrinks) and on focus
    // (border colour); plain mode lets the TextField repaint itself.
    if (widget.ghostMask) {
      _controller.addListener(_refresh);
      _focusNode.addListener(_onFocus);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void didUpdateWidget(covariant MaskedBody old) {
    super.didUpdateWidget(old);
    if (widget.controller == null &&
        widget.value != null &&
        _seed != _controller.text) {
      _controller.text = _seed;
    }
  }

  @override
  void dispose() {
    if (widget.ghostMask) {
      _controller.removeListener(_refresh);
      _focusNode.removeListener(_onFocus);
    }
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  TextStyle _textStyle(BuildContext context) =>
      fieldTextStyle(context)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  TextField _field(BuildContext context, InputDecoration decoration) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: FieldStateScope.of(context).readOnly,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      inputFormatters: [_formatter],
      style: _textStyle(context),
      decoration: decoration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: _readOnly,
      builder: (context) {
        if (widget.ghostMask) return _ghostField(context);
        final hint =
            widget.hint ?? (widget.showTemplate ? _formatter.template() : null);
        return _field(context, fieldInputDecoration(context, hint: hint));
      },
    );
  }

  /// The real, fully-decorated [TextField] (so its rounded chrome and focus
  /// border are exactly right) with the ghost painted on top through an
  /// [InputDecorator] that mirrors the field's geometry — same content padding,
  /// same (but transparent) border width — so the ghost's transparent prefix and
  /// grey suffix land pixel-aligned with the editable text underneath.
  Widget _ghostField(BuildContext context) {
    final base = fieldInputDecoration(context);
    return Stack(
      children: [
        _field(context, base),
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: InputDecorator(
                isFocused: _focused,
                decoration: base.copyWith(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: null,
                  // An outline, like the field's, so the ghost lays out on
                  // the same geometry.
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
                child: _ghost(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ghost(BuildContext context) {
    final text = _controller.text;
    final template = widget.ghostTemplate ?? _formatter.template();
    final suffix = text.length >= template.length
        ? ''
        : template.substring(text.length);
    if (suffix.isEmpty) return const SizedBox.shrink();
    final base = _textStyle(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: base.copyWith(color: Colors.transparent),
          ),
          TextSpan(
            text: suffix,
            style: base.copyWith(color: context.colors.placeholder),
          ),
        ],
      ),
      maxLines: 1,
    );
  }
}
