import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/button.dart';
import '../../common/ui/field_chrome.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/sections/fields_messages.dart';
import '../../theme/field_style.dart';
import '../../theme/palette.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// The languages [CodeBody] can highlight and validate. [plain] is an
/// un-highlighted monospace editor; [json] adds tokenised colouring, live
/// validation, and a prettify action.
enum CodeLanguage { json, plain }

/// A monospace code / JSON field body. Like [TextBody] and a markdown body it's
/// chrome-free — its value is a [String], it emits through [onChanged], and a
/// null [onChanged] renders it read-only (full contrast, focusable and
/// selectable, see [FieldState]) — so it drops into a [FieldShell] or a
/// translatable lane unchanged. [enabled] false, or a disabled
/// [FieldStateScope], disables it.
///
/// For [CodeLanguage.json] it highlights tokens as you type, validates on every
/// change (surfacing the failing line in the footer and turning the outline
/// red, as an invalid [FieldStateScope] does), and offers a Format button
/// that re-indents valid JSON. Height grows with the line count between
/// [minHeight] and [maxHeight], then the editor scrolls with a line-number
/// gutter kept in lockstep.
///
/// Code reads left to right in every language, so in a right-to-left app the
/// editor and its gutter keep that layout, gutter on the left, while the
/// footer mirrors with the rest of the page.
class CodeBody extends StatefulWidget {
  final String value;
  final ValueChanged<String>? onChanged;

  /// Notified whenever validity flips. [CodeLanguage.plain] is always valid.
  final ValueChanged<bool>? onValidChanged;

  final CodeLanguage language;
  final bool showLineNumbers;
  final bool showFooter;

  /// Auto-close brackets and quotes (with type-over and paired backspace) as you
  /// type. Auto-indent on Enter and Tab indentation are always on.
  final bool autoClosePairs;

  final double minHeight;
  final double maxHeight;
  final String? hint;
  final bool enabled;

  const CodeBody({
    super.key,
    required this.value,
    this.onChanged,
    this.onValidChanged,
    this.language = CodeLanguage.json,
    this.showLineNumbers = true,
    this.showFooter = true,
    this.autoClosePairs = true,
    this.minHeight = 120,
    this.maxHeight = 420,
    this.hint,
    this.enabled = true,
  });

  @override
  State<CodeBody> createState() => _CodeBodyState();
}

/// The editor's inset above the first line and below the last.
const _padV = AdminSpacing.md;

class _CodeBodyState extends State<CodeBody> {
  late _CodeController _controller;
  final _scroll = ScrollController();
  final _focus = FocusNode();
  CodeError? _error;

  /// The value last seen by [_onControllerChanged], diffed against the next to
  /// recognise a single-character edit (auto-close / -indent).
  late TextEditingValue _prev;

  /// True while we're writing back a transformed value, so the resulting
  /// notification is ignored instead of re-diffed.
  bool _applying = false;

  bool _hovered = false;

  bool get _readOnly => widget.onChanged == null;

  @override
  void initState() {
    super.initState();
    _controller = _CodeController(
      language: widget.language,
      text: widget.value,
    );
    _prev = _controller.value;
    _error = _validate(widget.value);
    _focus.addListener(_onFocusChange);
    _controller.addListener(_onControllerChanged);
  }

  void _onFocusChange() => setState(() {});

  @override
  void didUpdateWidget(covariant CodeBody old) {
    super.didUpdateWidget(old);
    if (widget.language != old.language) {
      _controller.language = widget.language;
    }
    if (widget.value != _controller.text) {
      _writeBack(
        TextEditingValue(
          text: widget.value,
          selection: TextSelection.collapsed(offset: widget.value.length),
        ),
      );
      _error = _validate(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scroll.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  CodeError? _validate(String text) {
    if (widget.language != CodeLanguage.json) return null;
    return validateJson(text);
  }

  /// Apply [value] to the controller without re-entering the diff logic.
  void _writeBack(TextEditingValue value) {
    _applying = true;
    _controller.value = value;
    _applying = false;
    _prev = value;
  }

  void _onControllerChanged() {
    if (_applying) return;
    final prev = _prev;
    final cur = _controller.value;
    if (prev.text == cur.text) {
      _prev = cur;
      return;
    }
    final edited = autoEditOnChange(
      prev,
      cur,
      autoClose: widget.autoClosePairs,
    );
    if (edited != null) {
      _writeBack(edited);
    } else {
      _prev = cur;
    }
    _emit(_controller.text);
  }

  void _emit(String text) {
    final before = _error == null;
    final error = _validate(text);
    if ((error == null) != before) {
      widget.onValidChanged?.call(error == null);
    }
    setState(() => _error = error);
    widget.onChanged?.call(text);
  }

  void _indent({required bool outdent}) {
    if (_readOnly) return;
    _writeBack(codeIndent(_controller.value, outdent: outdent));
    _emit(_controller.text);
  }

  void _format() {
    try {
      final pretty = const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(_controller.text));
      _writeBack(
        TextEditingValue(
          text: pretty,
          selection: TextSelection.collapsed(offset: pretty.length),
        ),
      );
      _emit(pretty);
    } on FormatException {
      // Unparseable — leave the text and its error in place.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: _readOnly,
      invalid: _error != null,
      builder: _build,
    );
  }

  Widget _build(BuildContext context) {
    final colors = context.colors;
    final tokens = context.adminTokens;
    final state = FieldStateScope.of(context);
    final lineCount = '\n'.allMatches(_controller.text).length + 1;
    final contentH = lineCount * _lineHeight(context) + _padV * 2;
    final height = contentH.clamp(widget.minHeight, widget.maxHeight);
    final corners = BorderRadius.circular(tokens.radii.radiusField);
    final states = state.states(hovered: _hovered, focused: _focus.hasFocus);
    final chrome = resolveFieldChrome(tokens, states);
    // The content keeps the room of the widest edge in every state; the
    // decoration pads by this state's edges, so they come off it and the
    // content never shifts as an edge thickens (FieldChrome's trick).
    final room = fieldEdgeRoom(tokens);
    final outer = [
      room.left,
      room.top,
      room.right,
      room.bottom,
    ].reduce(math.max);
    // A code surface: the background tint inside a box with an outline of
    // its own. A filled box is its fill, so it keeps it, as it does disabled.
    final tint = state.enabled && chrome.variant != FieldVariant.filled;
    final decoration = switch (fieldDecoration(tokens, states, corners)) {
      final BoxDecoration box when tint => box.copyWith(
        color: colors.background,
      ),
      final ShapeDecoration shape when tint => ShapeDecoration(
        color: colors.background,
        shape: shape.shape,
      ),
      final other => other,
    };

    final box = Container(
      decoration: decoration,
      foregroundDecoration: fieldForegroundDecoration(tokens, states, corners),
      padding: (room - chrome.border).clamp(
        EdgeInsets.zero,
        EdgeInsetsGeometry.infinity,
      ),
      child: ClipRRect(
        borderRadius: chrome.corners(
          BorderRadius.circular(math.max(0, tokens.radii.radiusField - outer)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height.toDouble(),
              child: Directionality(
                // Physical: code reads left to right in every language.
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showLineNumbers)
                      _Gutter(
                        scroll: _scroll,
                        lineCount: lineCount,
                        color: colors.foregroundMuted,
                        background: colors.surfaceMuted,
                        errorLine: _error?.line,
                        errorColor: colors.dangerText,
                      ),
                    Expanded(child: _editor(context)),
                  ],
                ),
              ),
            ),
            if (widget.showFooter) _footer(context),
          ],
        ),
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: box,
    );
  }

  Widget _editor(BuildContext context) {
    final field = _field(context);
    if (FieldStateScope.of(context).readOnly) return field;
    // Intercept Tab before focus traversal so it indents instead of leaving the
    // field. Esc still releases focus, keeping keyboard navigation possible.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.tab): _IndentIntent(false),
        SingleActivator(LogicalKeyboardKey.tab, shift: true): _IndentIntent(
          true,
        ),
      },
      child: Actions(
        actions: {
          _IndentIntent: CallbackAction<_IndentIntent>(
            onInvoke: (intent) {
              _indent(outdent: intent.outdent);
              return null;
            },
          ),
        },
        child: field,
      ),
    );
  }

  Widget _field(BuildContext context) {
    final state = FieldStateScope.of(context);
    return TextField(
      controller: _controller,
      scrollController: _scroll,
      focusNode: _focus,
      readOnly: state.readOnly,
      enabled: state.enabled,
      maxLines: null,
      minLines: null,
      expands: true,
      cursorColor: context.colors.primary,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      style: _mono(context, state.textColor(context.colors)),
      strutStyle: StrutStyle.fromTextStyle(
        context.type.mono,
        forceStrutHeight: true,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        border: InputBorder.none,
        hintText: widget.hint,
        hintStyle: _mono(context, context.colors.placeholder),
        // Beside the gutter the text needs less room than from the border.
        contentPadding: EdgeInsetsDirectional.fromSTEB(
          widget.showLineNumbers
              ? AdminSpacing.md
              : context.sizes.fieldPaddingX,
          _padV,
          context.sizes.fieldPaddingX,
          _padV,
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final colors = context.colors;
    final error = _error;
    final isJson = widget.language == CodeLanguage.json;
    final empty = _controller.text.trim().isEmpty;
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    final messages = context.adminL10n.fields;

    return Container(
      // A small button's height with a hairline of room, taller by as much
      // as its label grows at a large text size.
      height:
          context.sizes.small +
          2 * AdminSpacing.xxs +
          textGrowthOf(context, context.type.buttonSmall),
      padding: const EdgeInsetsDirectional.only(
        start: AdminSpacing.lg,
        end: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          if (isJson && !empty) ...[
            Icon(
              error == null ? Icons.check_circle_outline : Icons.error_outline,
              size: context.iconSizes.sm,
              color: error == null ? colors.successText : colors.dangerText,
            ),
            const Gap(AdminSpacing.sm),
            Expanded(
              child: Text(
                error == null
                    ? messages.validJson
                    : messages.jsonError(
                        error.line,
                        error.column,
                        error.message,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.bodySmall.copyWith(
                  color: error == null
                      ? colors.foregroundMuted
                      : colors.dangerText,
                ),
              ),
            ),
          ] else
            Expanded(
              child: Text(
                _languageLabel(messages),
                style: context.type.bodySmall.copyWith(
                  color: colors.foregroundMuted,
                ),
              ),
            ),
          if (isJson && editable)
            Button.ghost(
              messages.formatJson,
              size: ControlSize.small,
              onPressed: error == null && !empty ? _format : null,
            ),
        ],
      ),
    );
  }

  String _languageLabel(FieldsMessages messages) => switch (widget.language) {
    CodeLanguage.json => 'JSON',
    CodeLanguage.plain => messages.plainText,
  };
}

/// The editor's text: the theme's [AdminTypography.mono] in [color].
TextStyle _mono(BuildContext context, Color color) =>
    context.type.mono.copyWith(color: color);

/// The height of one editor line, as the text scale lays it out.
double _lineHeight(BuildContext context) {
  final mono = context.type.mono;
  return MediaQuery.textScalerOf(context).scale(mono.fontSize!) * mono.height!;
}

/// Scroll-synced line-number column. Repaints as the editor scrolls so numbers
/// track the text rows exactly: each in [AdminTypography.monoSmall], on its
/// line's baseline.
class _Gutter extends StatelessWidget {
  final ScrollController scroll;
  final int lineCount;
  final Color color;
  final Color background;
  final int? errorLine;
  final Color errorColor;

  const _Gutter({
    required this.scroll,
    required this.lineCount,
    required this.color,
    required this.background,
    required this.errorColor,
    this.errorLine,
  });

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final number = type.monoSmall.copyWith(color: color);
    final digits = lineCount.toString().length;
    final width =
        digits * (number.fontSize! * 0.62) + AdminSpacing.lg + AdminSpacing.md;
    return Container(
      width: width,
      color: background,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: scroll,
          builder: (context, _) {
            final offset = scroll.hasClients ? scroll.offset : 0.0;
            return CustomPaint(
              painter: _GutterPainter(
                lineCount: lineCount,
                offset: offset,
                line: _mono(context, color),
                lineHeight: _lineHeight(context),
                number: number,
                error: type
                    .weighted(type.monoSmall, FontWeight.w700)
                    .copyWith(color: errorColor),
                errorLine: errorLine,
                marker: context.stroke.indicator,
                textScaler: MediaQuery.textScalerOf(context),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GutterPainter extends CustomPainter {
  final int lineCount;
  final double offset;

  /// The editor's text, whose lines the numbers sit on, and the height of
  /// one of them.
  final TextStyle line;
  final double lineHeight;
  final TextStyle number;
  final TextStyle error;
  final int? errorLine;

  /// The width of the bar that marks the error line.
  final double marker;
  final TextScaler textScaler;

  _GutterPainter({
    required this.lineCount,
    required this.offset,
    required this.line,
    required this.lineHeight,
    required this.number,
    required this.error,
    required this.marker,
    required this.textScaler,
    this.errorLine,
  });

  /// The distance from the top of a line in [style] to its baseline.
  double _baseline(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: '0', style: style),
      // Physical: a digit's baseline, in the left-to-right editor.
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.dispose();
    return baseline;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final end = size.width - AdminSpacing.md;
    final shift = _baseline(line) - _baseline(number);
    final bar = Paint()..color = error.color!;
    for (var i = 0; i < lineCount; i++) {
      final y = _padV + i * lineHeight - offset;
      if (y + lineHeight < 0 || y > size.height) continue;
      final isError = errorLine == i + 1;
      if (isError) {
        canvas.drawRRect(
          RRect.fromLTRBR(
            0,
            y + 1,
            marker,
            y + lineHeight - 1,
            Radius.circular(marker / 2),
          ),
          bar,
        );
      }
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: isError ? error : number),
        // Physical: the gutter is part of the left-to-right editor.
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: end);
      tp.paint(canvas, Offset(end - tp.width, y + shift));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_GutterPainter old) =>
      old.offset != offset ||
      old.lineCount != lineCount ||
      old.line != line ||
      old.lineHeight != lineHeight ||
      old.number != number ||
      old.error != error ||
      old.errorLine != errorLine ||
      old.marker != marker ||
      old.textScaler != textScaler;
}

/// Tab / Shift-Tab inside the editor: indent or [outdent] the current line(s).
class _IndentIntent extends Intent {
  final bool outdent;
  const _IndentIntent(this.outdent);
}

/// A [TextEditingController] that colours JSON tokens by overriding
/// [buildTextSpan]. Unrecognised / partial input falls back to the base style,
/// so a half-typed document still renders.
class _CodeController extends TextEditingController {
  CodeLanguage language;

  _CodeController({required this.language, required String text})
    : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final state = FieldStateScope.of(context);
    final base = (style ?? const TextStyle()).merge(
      _mono(context, state.textColor(context.colors)),
    );
    // Disabled text is dimmed whole; tokens coloured at full strength would
    // read as editable.
    if (language != CodeLanguage.json || text.isEmpty || !state.enabled) {
      return TextSpan(text: text, style: base);
    }
    return TextSpan(
      style: base,
      children: _highlightJson(text, base, context.colors),
    );
  }
}

List<TextSpan> _highlightJson(String src, TextStyle base, AdminPalette colors) {
  final syntax = colors.syntax;
  Color? colorFor(JsonTokenKind kind) => switch (kind) {
    JsonTokenKind.key => syntax.key,
    JsonTokenKind.string => syntax.string,
    JsonTokenKind.number => syntax.number,
    JsonTokenKind.literal => syntax.literal,
    JsonTokenKind.punctuation => syntax.punctuation,
    JsonTokenKind.plain => null,
  };
  return [
    for (final t in tokenizeJson(src))
      TextSpan(
        text: src.substring(t.start, t.end),
        style: colorFor(t.kind) is Color
            ? TextStyle(color: colorFor(t.kind))
            : null,
      ),
  ];
}

/// The lexical classes [tokenizeJson] distinguishes for colouring. [key] is a
/// string immediately preceding a colon; [plain] is whitespace / anything
/// unrecognised.
enum JsonTokenKind { key, string, number, literal, punctuation, plain }

/// A half-open `[start, end)` slice of the source and its [kind].
class JsonToken {
  final int start;
  final int end;
  final JsonTokenKind kind;

  const JsonToken(this.start, this.end, this.kind);
}

/// Splits [src] into contiguous, non-overlapping [JsonToken]s covering every
/// character. Deliberately forgiving — it lexes partial / invalid JSON so a
/// half-typed document still colours; it does not parse structure.
List<JsonToken> tokenizeJson(String src) {
  final tokens = <JsonToken>[];
  var i = 0;
  final n = src.length;
  while (i < n) {
    final c = src[i];
    if (c == '"') {
      final start = i;
      i++;
      while (i < n) {
        if (src[i] == '\\' && i + 1 < n) {
          i += 2;
          continue;
        }
        if (src[i] == '"') {
          i++;
          break;
        }
        i++;
      }
      var j = i;
      while (j < n && (src[j] == ' ' || src[j] == '\t')) {
        j++;
      }
      final isKey = j < n && src[j] == ':';
      tokens.add(
        JsonToken(start, i, isKey ? JsonTokenKind.key : JsonTokenKind.string),
      );
    } else if (c == '-' || _isDigit(c)) {
      final start = i;
      while (i < n && _isNumberChar(src[i])) {
        i++;
      }
      tokens.add(JsonToken(start, i, JsonTokenKind.number));
    } else if (_isLetter(c)) {
      final start = i;
      while (i < n && _isLetter(src[i])) {
        i++;
      }
      final word = src.substring(start, i);
      final isLiteral = word == 'true' || word == 'false' || word == 'null';
      tokens.add(
        JsonToken(
          start,
          i,
          isLiteral ? JsonTokenKind.literal : JsonTokenKind.plain,
        ),
      );
    } else if ('{}[],:'.contains(c)) {
      tokens.add(JsonToken(i, i + 1, JsonTokenKind.punctuation));
      i++;
    } else {
      tokens.add(JsonToken(i, i + 1, JsonTokenKind.plain));
      i++;
    }
  }
  return tokens;
}

bool _isDigit(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

bool _isNumberChar(String c) {
  if (c == '.' || c == '-' || c == '+' || c == 'e' || c == 'E') return true;
  return _isDigit(c);
}

bool _isLetter(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 0x61 && u <= 0x7a) || (u >= 0x41 && u <= 0x5a);
}

/// A JSON parse failure mapped to a 1-based line/column for the footer.
class CodeError {
  final int line;
  final int column;
  final String message;

  const CodeError({
    required this.line,
    required this.column,
    required this.message,
  });

  factory CodeError._fromFormatException(String src, FormatException e) {
    final offset = (e.offset ?? 0).clamp(0, src.length);
    var line = 1;
    var col = 1;
    for (var i = 0; i < offset; i++) {
      if (src[i] == '\n') {
        line++;
        col = 1;
      } else {
        col++;
      }
    }
    var msg = e.message;
    final paren = msg.indexOf(' (at ');
    if (paren != -1) msg = msg.substring(0, paren);
    return CodeError(line: line, column: col, message: msg);
  }
}

/// Parses [text] as JSON, returning `null` when it's valid (or blank) and a
/// [CodeError] pinned to the failing line/column otherwise. The validation that
/// backs [CodeBody]'s footer, exposed for form wiring.
CodeError? validateJson(String text) {
  if (text.trim().isEmpty) return null;
  try {
    jsonDecode(text);
    return null;
  } on FormatException catch (e) {
    return CodeError._fromFormatException(text, e);
  }
}

const _openToClose = {'{': '}', '[': ']', '(': ')', '"': '"'};
const _closers = {'}', ']', ')', '"'};

/// Given the [prev] and [cur] editor values across a single-character change,
/// returns the value [CodeBody] should write back to apply auto-indent and
/// (when [autoClose]) bracket/quote pairing — or `null` to leave [cur] as is.
///
/// Diff-based rather than key-intercepting so it behaves identically on web,
/// where typed characters arrive through the text-input pipeline, not as key
/// events. Only clean single-char inserts/deletes at a collapsed caret are
/// transformed; pastes and multi-char edits pass through untouched.
TextEditingValue? autoEditOnChange(
  TextEditingValue prev,
  TextEditingValue cur, {
  bool autoClose = true,
  int indentSize = 2,
}) {
  final sel = cur.selection;
  if (!sel.isCollapsed) return null;
  final caret = sel.baseOffset;

  // One character inserted at the caret.
  if (cur.text.length == prev.text.length + 1 && caret > 0) {
    final p = caret - 1;
    final inserted = cur.text[p];
    final rebuilt = cur.text.substring(0, p) + cur.text.substring(caret);
    if (rebuilt != prev.text) return null;

    if (inserted == '\n') return _indentAfterNewline(cur, p, indentSize);
    if (!autoClose) return null;

    final after = caret < cur.text.length ? cur.text[caret] : '';
    // Typed a closer that's already there — step over it instead of doubling.
    if (_closers.contains(inserted) && after == inserted) {
      return TextEditingValue(
        text: prev.text,
        selection: TextSelection.collapsed(offset: caret),
      );
    }
    final closing = _openToClose[inserted];
    if (closing != null) {
      return TextEditingValue(
        text:
            cur.text.substring(0, caret) + closing + cur.text.substring(caret),
        selection: TextSelection.collapsed(offset: caret),
      );
    }
    return null;
  }

  // One character deleted — if it was an opener sitting against its closer,
  // take the closer with it.
  if (autoClose && cur.text.length == prev.text.length - 1) {
    final rebuilt =
        prev.text.substring(0, caret) + prev.text.substring(caret + 1);
    if (rebuilt != cur.text) return null;
    final deleted = prev.text[caret];
    final closing = _openToClose[deleted];
    if (closing != null &&
        caret < cur.text.length &&
        cur.text[caret] == closing) {
      return TextEditingValue(
        text: cur.text.substring(0, caret) + cur.text.substring(caret + 1),
        selection: TextSelection.collapsed(offset: caret),
      );
    }
  }
  return null;
}

/// After a newline was inserted at [newlinePos], carry the previous line's
/// indentation onto the new line — adding one level inside a freshly opened
/// bracket, and dropping the matching closer onto its own dedented line when the
/// caret split an empty pair (`{|}` → block).
TextEditingValue? _indentAfterNewline(
  TextEditingValue cur,
  int newlinePos,
  int indentSize,
) {
  final t = cur.text;
  final lineStart = _lineStart(t, newlinePos);
  final indent = _leadingWhitespace(t.substring(lineStart, newlinePos));
  final before = newlinePos > 0 ? t[newlinePos - 1] : '';
  final caret = newlinePos + 1;
  final after = caret < t.length ? t[caret] : '';
  final unit = ' ' * indentSize;

  if (before == '{' || before == '[' || before == '(') {
    final inner = indent + unit;
    if (after == _openToClose[before]) {
      final insert = '$inner\n$indent';
      return TextEditingValue(
        text: t.substring(0, caret) + insert + t.substring(caret),
        selection: TextSelection.collapsed(offset: caret + inner.length),
      );
    }
    return TextEditingValue(
      text: t.substring(0, caret) + inner + t.substring(caret),
      selection: TextSelection.collapsed(offset: caret + inner.length),
    );
  }
  if (indent.isEmpty) return null;
  return TextEditingValue(
    text: t.substring(0, caret) + indent + t.substring(caret),
    selection: TextSelection.collapsed(offset: caret + indent.length),
  );
}

/// Indents (or [outdent]s) the line(s) the selection touches. A collapsed caret
/// indents by inserting a unit at the caret; outdent and multi-line selections
/// act on whole lines.
TextEditingValue codeIndent(
  TextEditingValue value, {
  required bool outdent,
  int indentSize = 2,
}) {
  final t = value.text;
  final sel = value.selection;
  final start = sel.start;
  final end = sel.end;
  final unit = ' ' * indentSize;

  if (!outdent && sel.isCollapsed) {
    return TextEditingValue(
      text: t.replaceRange(start, start, unit),
      selection: TextSelection.collapsed(offset: start + indentSize),
    );
  }

  final firstStart = _lineStart(t, start);
  final lastEnd = t.indexOf('\n', end) == -1 ? t.length : t.indexOf('\n', end);
  final lines = t.substring(firstStart, lastEnd).split('\n');

  var firstDelta = 0;
  var totalDelta = 0;
  final out = <String>[];
  for (var k = 0; k < lines.length; k++) {
    final line = lines[k];
    int delta;
    if (outdent) {
      var remove = 0;
      while (remove < indentSize &&
          remove < line.length &&
          line[remove] == ' ') {
        remove++;
      }
      if (remove == 0 && line.isNotEmpty && line[0] == '\t') remove = 1;
      out.add(line.substring(remove));
      delta = -remove;
    } else {
      out.add(unit + line);
      delta = indentSize;
    }
    if (k == 0) firstDelta = delta;
    totalDelta += delta;
  }

  final newText = t.replaceRange(firstStart, lastEnd, out.join('\n'));
  final newStart = (start + firstDelta).clamp(firstStart, newText.length);
  final newEnd = (end + totalDelta).clamp(newStart, newText.length);
  return TextEditingValue(
    text: newText,
    selection: sel.isCollapsed
        ? TextSelection.collapsed(offset: newStart)
        : TextSelection(baseOffset: newStart, extentOffset: newEnd),
  );
}

/// The offset of the start of the line containing [offset] (0 or just past the
/// preceding newline). Safe at [offset] 0, unlike a bare `lastIndexOf`.
int _lineStart(String t, int offset) {
  if (offset <= 0) return 0;
  return t.lastIndexOf('\n', offset - 1) + 1;
}

String _leadingWhitespace(String line) {
  var i = 0;
  while (i < line.length && (line[i] == ' ' || line[i] == '\t')) {
    i++;
  }
  return line.substring(0, i);
}
