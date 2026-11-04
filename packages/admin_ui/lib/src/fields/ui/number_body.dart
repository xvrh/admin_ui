import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/field_style.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// How the numeric control renders.
enum NumberAppearance {
  /// A numeric text input. The default.
  plain,

  /// The input flanked by −/+ buttons that nudge by [NumberBody.step].
  stepper,

  /// A slider over [NumberBody.min]…[NumberBody.max] with a value readout.
  slider,
}

/// The bare numeric control — no label or capability chrome — so the same body
/// sits inside a [FieldShell] (a real `num`) or one lane of a translatable
/// field. Carries the value's *shape* (range, step, decimals) and its display
/// affordances ([prefix] like `$`, [unit] suffix like `px`).
///
/// Two ways to drive [NumberAppearance.plain] and [NumberAppearance.stepper]:
/// hand over a [controller], or give a [value] + [onChanged] and the body
/// manages an internal controller, reseeding when [value] changes to
/// something other than what the field shows.
///
/// **Locale.** The number shows in the app's locale ([AdminFormats]):
/// `1,234.5` in English, `1.234,5` in German. Typing takes the locale's own
/// separators, and a separator that could be read either way is not taken
/// as a number (see [AdminFormats.parseDecimal]).
///
/// **Typing.** Only digits, the locale's group separator, one decimal separator
/// (with [decimals]) and a leading minus (when [min] allows negatives) get in.
/// A number in range is reported as it is typed, and a cleared field as null;
/// the text stays as typed — never refilled with a `0` — so it can be cleared
/// and retyped. A number outside [min]…[max] turns the field red and goes to
/// [onInvalid] instead. The text is committed on Enter or when the field loses
/// focus: a value out of range is clamped into it and rounded to [decimals],
/// text with no digit yet (a lone `-`) reverts to [value], and a field left
/// empty whose host kept a value (a required number ignores the null) shows
/// that value again. Digits that do not read as a number in the locale ('1,5'
/// in English, where ',' groups thousands) stay as typed, the field turns red
/// with an example of the notation, and nothing is reported until they do; once
/// red, the field checks as it is typed.
///
/// **Keys.** ArrowUp and ArrowDown step by [step], with Shift or PageUp and
/// PageDown by ten steps, clamped to the range.
///
/// A null [onChanged] renders it read-only: full contrast, focusable and
/// selectable, no steppers (see [FieldState]). [enabled] false, or a disabled
/// [FieldStateScope], disables it.
class NumberBody extends StatefulWidget {
  final num? value;
  final ValueChanged<num?>? onChanged;

  /// Reports a short message while the number the field shows — typed, or
  /// handed in as [value] — is outside [min]…[max], or its committed text is
  /// no number in the locale's notation, and null once it is right again,
  /// for a shell to show under the field.
  final ValueChanged<String?>? onInvalid;

  final NumberAppearance appearance;

  final num? min;
  final num? max;
  final num step;

  /// Decimal places to display; 0 keeps it an integer.
  final int decimals;

  /// Inline adornments — a leading symbol (e.g. `$`) and a trailing unit
  /// (e.g. `px`, `%`, `kg`).
  final String? prefix;
  final String? unit;

  final String? hint;
  final bool enabled;

  /// Caller-owned controller for [NumberAppearance.plain] and
  /// [NumberAppearance.stepper]; mutually exclusive with [value]. Unused by
  /// [NumberAppearance.slider].
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const NumberBody({
    super.key,
    this.value,
    this.onChanged,
    this.onInvalid,
    this.appearance = NumberAppearance.plain,
    this.min,
    this.max,
    this.step = 1,
    this.decimals = 0,
    this.prefix,
    this.unit,
    this.hint,
    this.enabled = true,
    this.controller,
    this.focusNode,
  });

  @override
  State<NumberBody> createState() => _NumberBodyState();
}

class _NumberBodyState extends State<NumberBody> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  FocusNode? _listening;

  /// Why what the field shows is out of range, while it is.
  String? _invalid;

  /// Whether the text was typed into since it was last committed.
  bool _edited = false;

  /// The app locale's number formats, from [didChangeDependencies].
  AdminFormats? _formats;

  /// What the field lets through, for the locale and shape it was built
  /// for.
  _NumberTextFormatter? _formatter;

  bool get _readOnly => widget.onChanged == null;

  bool get _editable {
    final state = FieldStateScope.of(context);
    return !_readOnly && widget.enabled && state.enabled && !state.readOnly;
  }

  /// [v] in the locale's digits and separators. The field lays its text out
  /// left to right, so the bidi marks a locale puts in its minus sign
  /// (Arabic's) have nothing to do and are left out.
  String _format(num v) => _formats!
      .decimal(v, fractionDigits: widget.decimals)
      .replaceAll(_bidiMarks, '');

  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(
        text: widget.value == null ? '' : _format(widget.value!),
      ));
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  num? _parse(String s) => _formats!.parseDecimal(s);

  bool get _allowsNegative => widget.min == null || widget.min! < 0;

  /// [_formatter], built again only when the locale or the shape changes.
  _NumberTextFormatter get _textFormatter {
    final key = (_formats!.locale, widget.decimals > 0, _allowsNegative);
    final formatter = _formatter;
    if (formatter != null && formatter.key == key) return formatter;
    return _formatter = _NumberTextFormatter(
      locale: key.$1,
      decimal: key.$2,
      negative: key.$3,
    );
  }

  static final _digit = RegExp(r'\p{Nd}', unicode: true);

  /// Why [text] is not a number: it has digits that do not read as one in
  /// the locale. Null for a number, and for text with no digit yet.
  String? _notANumber(String text) {
    if (_parse(text) != null || !_digit.hasMatch(text)) return null;
    final example = _formats!.decimal(
      widget.decimals == 0 ? 1234 : 1234.5,
      maxFractionDigits: widget.decimals,
    );
    return context.adminL10n.fields.numberLike(example);
  }

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final previous = _formats;
    final formats = context.adminFormats;
    if (previous != null && previous.locale == formats.locale) return;
    _formats = formats;
    if (previous == null) {
      final error = _shownError();
      if (error != null) _setInvalid(error);
      return;
    }
    // Another locale: what the field shows is reprinted in it, unless it is
    // being typed.
    final value = previous.parseDecimal(_controller.text);
    if (widget.controller == null && !_edited && value != null) {
      _controller.text = _format(value);
    }
    _setInvalid(_shownError());
  }

  void _listen() {
    final node = _focusNode;
    if (identical(node, _listening)) return;
    _listening?.removeListener(_onFocus);
    _listening = node..addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant NumberBody old) {
    super.didUpdateWidget(old);
    _listen();
    if (widget.controller != null) return;
    // Reseed only when the value changed *outside* the field (revert, live
    // link). What the user typed already parses to the value it reported, and
    // text that reported nothing (empty, out of range) keeps its value —
    // otherwise "2" would reformat to "2.00" mid-keystroke, and a cleared
    // field would refill before it could be retyped.
    if (widget.value != old.value && widget.value != _parse(_controller.text)) {
      _controller.text = widget.value == null ? '' : _format(widget.value!);
      _edited = false;
      _setInvalid(_shownError());
    }
  }

  @override
  void dispose() {
    _listening?.removeListener(_onFocus);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focusNode.hasFocus) _commit();
  }

  num _clamp(num v) {
    if (widget.min != null && v < widget.min!) return widget.min!;
    if (widget.max != null && v > widget.max!) return widget.max!;
    return v;
  }

  num _round(num v) => widget.decimals == 0
      ? v.round()
      : num.parse(v.toStringAsFixed(widget.decimals));

  /// [v] for a message, where a locale's bidi marks keep a minus in front
  /// of the number in right-to-left text.
  String _bound(num v) =>
      '${widget.prefix?.trim() ?? ''}'
      '${_formats!.decimal(v, fractionDigits: widget.decimals)}';

  String get _unit {
    final unit = widget.unit?.trim() ?? '';
    return unit.isEmpty ? '' : ' $unit';
  }

  /// Why [v] is out of range, or null when it is in.
  String? _rangeError(num v) {
    final min = widget.min;
    final max = widget.max;
    if ((min == null || v >= min) && (max == null || v <= max)) return null;
    final messages = context.adminL10n.fields;
    if (min != null && max != null) {
      return messages.numberBetween(_bound(min), '${_bound(max)}$_unit');
    }
    return min != null
        ? messages.numberAtLeast('${_bound(min)}$_unit')
        : messages.numberAtMost('${_bound(max!)}$_unit');
  }

  /// Why what the field shows is not a number in range, or null. Text
  /// still being typed is not judged yet.
  String? _shownError() {
    final text = _controller.text;
    final shown = _parse(text);
    if (shown == null) return _edited ? null : _notANumber(text);
    return _rangeError(shown);
  }

  void _setInvalid(String? message) {
    if (message == _invalid) return;
    setState(() => _invalid = message);
    final onInvalid = widget.onInvalid;
    if (onInvalid == null) return;
    // Mid-build (a first mount, a new value from the host) the host hears
    // it the frame after, when it may rebuild.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _invalid == message) onInvalid(message);
      });
    } else {
      onInvalid(message);
    }
  }

  void _emit(num? v) {
    if (v != widget.value) widget.onChanged?.call(v);
  }

  void _onText(String raw) {
    _edited = true;
    final parsed = _parse(raw);
    if (parsed == null) {
      if (raw.trim().isEmpty) {
        _setInvalid(null);
        _emit(null);
      } else if (_invalid != null) {
        // A field already red says why as it is typed; one that is not
        // waits for the commit, so '1,' on its way to '1,234' stays calm.
        _setInvalid(_notANumber(raw));
      }
      return;
    }
    final error = _rangeError(parsed);
    _setInvalid(error);
    if (error == null) _emit(parsed);
  }

  void _commit() {
    // Only typed text commits: tabbing through a field that shows an
    // out-of-range value from the host leaves it flagged, not rewritten.
    if (!mounted || !_edited || _readOnly) return;
    _edited = false;
    final text = _controller.text;
    // Digits that are no number stay as typed, so they can be corrected.
    final error = _notANumber(text);
    _setInvalid(error);
    if (error != null) return;
    if (text.trim().isEmpty) {
      // Reported as it was cleared; a host that kept a value shows it again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final value = widget.value;
        if (mounted &&
            widget.controller == null &&
            value != null &&
            !_focusNode.hasFocus &&
            _controller.text.trim().isEmpty) {
          _controller.text = _format(value);
        }
      });
      return;
    }
    final parsed = _parse(text);
    final next = parsed == null ? widget.value : _round(_clamp(parsed));
    final shown = next == null ? '' : _format(next);
    if (_controller.text != shown) _controller.text = shown;
    if (parsed != null) _emit(next);
  }

  /// Nudges the value [steps] steps from what the field shows, clamped.
  void _stepBy(int steps) {
    if (!_editable) return;
    final base = _parse(_controller.text) ?? widget.value ?? widget.min ?? 0;
    final next = _round(_clamp(base + widget.step * steps));
    final text = _format(next);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _edited = false;
    _setInvalid(null);
    _emit(next);
  }

  bool _atLimit(int direction) {
    final current = _parse(_controller.text) ?? widget.value;
    if (current == null) return false;
    return direction < 0
        ? widget.min != null && current <= widget.min!
        : widget.max != null && current >= widget.max!;
  }

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: _readOnly,
      invalid: _invalid != null,
      builder: (context) => switch (widget.appearance) {
        NumberAppearance.slider => _slider(context),
        NumberAppearance.stepper => _input(context, stepper: true),
        NumberAppearance.plain => _input(context, stepper: false),
      },
    );
  }

  Widget _input(BuildContext context, {required bool stepper}) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    final sizes = context.sizes;
    final chromeless = ChromelessFieldScope.of(context);
    final direction = Directionality.of(context);
    final inset = chromeless ? 0.0 : sizes.fieldPaddingX;
    final tokens = context.adminTokens;
    // The steppers sit inside the widest edge the field draws in any state,
    // so a focus outline or rule never runs under them, on whole pixels so
    // their dividers stay crisp: a fraction of an edge (a 1.5px focus
    // outline) may.
    final edges = fieldEdgeRoom(tokens);
    final room = chromeless
        ? EdgeInsets.zero
        // Physical: as the chrome's edges, whose rule is at the bottom.
        : EdgeInsets.fromLTRB(
            edges.left.floorToDouble(),
            edges.top.floorToDouble(),
            edges.right.floorToDouble(),
            edges.bottom.floorToDouble(),
          );
    final affixStyle = context.type.fieldText.copyWith(
      color: state.iconColor(context.colors),
    );
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: affixStyle),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width.ceilToDouble();
      painter.dispose();
      return width;
    }

    final prefix = widget.prefix?.trim();
    final unit = widget.unit?.trim();
    final hasPrefix = prefix != null && prefix.isNotEmpty;
    final hasUnit = unit != null && unit.isNotEmpty;
    // Steppers are an editing affordance: a read-only field shows none.
    final steppers = stepper && !state.readOnly;
    final segment = sizes.height(ControlSize.medium) - room.vertical;
    // The strip, and the room it keeps from the end beyond the resting edge
    // the text's padding already clears.
    final rest = chromeless ? 0.0 : context.stroke.control;
    final steppersWidth = steppers
        ? 2 * (segment + 1) + room.right - rest
        : 0.0;
    final corner = Radius.circular(
      chromeless ? 0 : math.max(0, tokens.radii.radiusField - room.right),
    );
    const gap = AdminSpacing.xs;
    final unitWidth = hasUnit ? widthOf(unit) + gap : 0.0;

    final base = fieldInputDecoration(context, hint: widget.hint);
    final padding = (base.contentPadding ?? EdgeInsets.zero).resolve(direction);
    final decoration = base.copyWith(
      // Holds the prefix's room ahead of the text and the hint; the prefix
      // itself is drawn over it, so it shows while the field is empty too.
      prefix: hasPrefix ? SizedBox(width: widthOf(prefix) + gap) : null,
      contentPadding: EdgeInsetsDirectional.fromSTEB(
        inset,
        padding.top,
        inset + unitWidth + steppersWidth,
        padding.bottom,
      ),
    );

    // The prefix and unit are read as the field's hint rather than as nodes
    // of their own beside the text, which would trip a Flutter semantics
    // assertion once merged under a FieldShell's label.
    final affixes = [prefix, unit].nonNulls.where((a) => a.isNotEmpty);
    Widget affix(String text) => IgnorePointer(
      child: ExcludeSemantics(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: Text(text, maxLines: 1, style: affixStyle),
        ),
      ),
    );

    final field = Semantics(
      hint: affixes.isEmpty ? null : affixes.join(' '),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: state.readOnly,
        onChanged: editable ? _onText : null,
        onSubmitted: editable ? (_) => _commit() : null,
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.decimals > 0,
          signed: _allowsNegative,
        ),
        inputFormatters: [_textFormatter],
        // A number reads left to right in every script, so a minus stays in
        // front of it, and still starts at the right in right-to-left text.
        // Physical: the number's own order.
        textDirection: TextDirection.ltr,
        textAlign: direction == TextDirection.rtl
            // Physical: the start of a right-to-left field.
            ? TextAlign.right
            : TextAlign.start,
        style: fieldTextStyle(context)
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: decoration,
      ),
    );

    return CallbackShortcuts(
      bindings: editable
          ? {
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _stepBy(1),
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _stepBy(-1),
              const SingleActivator(
                LogicalKeyboardKey.arrowUp,
                shift: true,
              ): () =>
                  _stepBy(10),
              const SingleActivator(
                LogicalKeyboardKey.arrowDown,
                shift: true,
              ): () =>
                  _stepBy(-10),
              const SingleActivator(LogicalKeyboardKey.pageUp): () =>
                  _stepBy(10),
              const SingleActivator(LogicalKeyboardKey.pageDown): () =>
                  _stepBy(-10),
            }
          : const {},
      child: Stack(
        children: [
          field,
          if (hasPrefix)
            PositionedDirectional(
              start: inset,
              top: 0,
              bottom: 0,
              child: affix(prefix),
            ),
          if (hasUnit)
            PositionedDirectional(
              end: inset + steppersWidth,
              top: 0,
              bottom: 0,
              child: affix(unit),
            ),
          if (steppers)
            PositionedDirectional(
              end: room.right,
              top: room.top,
              bottom: room.bottom,
              child: ClipRRect(
                borderRadius: BorderRadiusDirectional.only(
                  topEnd: corner,
                  // A filled box is square at the bottom.
                  bottomEnd: tokens.field.variant == FieldVariant.filled
                      ? Radius.zero
                      : corner,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final direction in const [-1, 1]) ...[
                      _Divider(color: context.colors.border),
                      _Segment(
                        width: segment,
                        icon: direction < 0
                            ? Icons.remove_rounded
                            : Icons.add_rounded,
                        label: direction < 0
                            ? context.adminL10n.fields.decrease
                            : context.adminL10n.fields.increase,
                        onTap: editable && !_atLimit(direction)
                            ? () => _stepBy(direction)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slider(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    final colors = context.colors;
    final min = (widget.min ?? 0).toDouble();
    final max = (widget.max ?? 100).toDouble();
    final v = (widget.value ?? min).toDouble().clamp(min, max);
    final divisions = widget.step > 0
        ? ((max - min) / widget.step).round()
        : null;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: context.sizes.medium,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: colors.controlAccent,
                inactiveTrackColor: colors.border,
                thumbColor: colors.controlAccent,
                disabledActiveTrackColor: state.enabled
                    ? colors.controlAccent
                    : colors.foregroundFaint,
                disabledInactiveTrackColor: colors.border,
                disabledThumbColor: state.enabled
                    ? colors.controlAccent
                    : colors.foregroundSubtle,
                overlayColor: colors.primarySubtle,
                thumbShape: _RingThumbShape(
                  fill: colors.surface,
                  shadow: colors.shadow,
                ),
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: v,
                min: min,
                max: max,
                divisions: divisions == 0 ? null : divisions,
                onChanged: editable ? (d) => widget.onChanged!(_snap(d)) : null,
              ),
            ),
          ),
        ),
        const Gap(AdminSpacing.lg),
        _readout(context, v),
      ],
    );
  }

  /// Snap a raw slider value to the nearest step, keeping the declared decimals.
  num _snap(double d) {
    if (widget.step <= 0) {
      return widget.decimals == 0
          ? d.round()
          : num.parse(d.toStringAsFixed(widget.decimals));
    }
    final min = widget.min ?? 0;
    final steps = ((d - min) / widget.step).round();
    final snapped = min + steps * widget.step;
    return widget.decimals == 0
        ? snapped.round()
        : num.parse(snapped.toStringAsFixed(widget.decimals));
  }

  Widget _readout(BuildContext context, double v) {
    final state = FieldStateScope.of(context);
    final style = context.type
        .weighted(fieldTextStyle(context), FontWeight.w600)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Container(
      // Taller by as much as the number grows at a large text size.
      height: context.sizes.medium + textGrowthOf(context, style),
      constraints: const BoxConstraints(minWidth: 64),
      padding: EdgeInsets.symmetric(horizontal: context.sizes.fieldPaddingX),
      alignment: Alignment.center,
      // The field's box at rest, as Carbon and Ant pair a slider with an
      // input.
      decoration: fieldDecoration(
        context.adminTokens,
        state.states(),
        BorderRadius.circular(context.radii.radiusField),
      ),
      child: Text(
        '${widget.prefix ?? ''}${_format(_snap(v))}${widget.unit == null ? '' : ' ${widget.unit}'}',
        // Physical: a number reads left to right in every script.
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

final _bidiMarks = RegExp('[\u200E\u200F\u061C]');

/// Lets through what can become a number in [locale]: its digits and ASCII
/// ones, its group separator, one decimal separator when [decimal], and a
/// minus only in front when [negative]. Anything else leaves the text as it
/// was. Whether the groups are well formed is for parsing to judge, so an
/// edit in the middle ('1,234' losing its '1') is never refused.
class _NumberTextFormatter extends TextInputFormatter {
  factory _NumberTextFormatter({
    required String locale,
    required bool decimal,
    required bool negative,
  }) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    final zero = symbols.ZERO_DIGIT.codeUnitAt(0);
    final digits = {
      '0-9',
      if (zero != 0x30)
        '${String.fromCharCode(zero)}-${String.fromCharCode(zero + 9)}',
    }.join();
    const spaces = {' ', '\u00A0', '\u202F', '\u2009'};
    final groups = {
      symbols.GROUP_SEP,
      if (spaces.contains(symbols.GROUP_SEP)) ...spaces,
      if (symbols.GROUP_SEP == "'") '’',
    };
    final decimals = {symbols.DECIMAL_SEP, if (!groups.contains('.')) '.'};
    // Escaped for a character class, where '-' would make a range.
    String set(Iterable<String> chars) => chars
        .map(
          (c) => c.replaceAllMapped(RegExp(r'[\\\]\[^-]'), (m) => '\\${m[0]}'),
        )
        .join();
    final number = '[$digits${set(groups)}]*';
    final fraction = decimal ? '([${set(decimals)}][$digits]*)?' : '';
    final allowed = {
      ...groups,
      if (decimal) ...decimals,
      if (negative) ...['-', '\u2212'],
    };
    return _NumberTextFormatter._(
      (locale, decimal, negative),
      RegExp('^${negative ? '[-\u2212]?' : ''}$number$fraction\$'),
      RegExp('[^$digits${set(allowed)}]'),
    );
  }

  _NumberTextFormatter._(this.key, this._pattern, this._stray);

  /// The locale and shape this formatter was built for.
  final (String, bool, bool) key;

  final RegExp _pattern;

  /// What a paste may carry besides the number: a currency sign, a letter.
  final RegExp _stray;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_pattern.hasMatch(newValue.text)) return newValue;
    // A paste with stray characters (a currency sign, a unit) keeps what
    // fits, as long as that reads as a number.
    final kept = newValue.text.replaceAll(_stray, '');
    if (kept != newValue.text && _pattern.hasMatch(kept)) {
      return TextEditingValue(
        text: kept,
        selection: TextSelection.collapsed(offset: kept.length),
      );
    }
    return oldValue;
  }
}

/// A 1px rule between the text and a stepper segment, and between segments.
class _Divider extends StatelessWidget {
  final Color color;

  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 1, child: ColoredBox(color: color));
}

/// A −/+ stepper segment: square, flush with the field's end, lit by the
/// neutral hover overlay. A pointer shortcut only — the text field is the
/// one Tab stop, and its arrow keys step.
class _Segment extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Segment({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tappable.states(
      onTap: onTap,
      focusable: false,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states) {
        final enabled = !states.contains(WidgetState.disabled);
        final overlay = !enabled
            ? null
            : states.contains(WidgetState.pressed)
            ? colors.pressedOverlay
            : states.contains(WidgetState.hovered)
            ? colors.hoverOverlay
            : null;
        return Container(
          width: width,
          color: overlay,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: context.sizes.fieldIcon,
            color: !enabled
                ? colors.foregroundSubtle
                : overlay == null
                ? colors.foregroundMuted
                : colors.foregroundSecondary,
          ),
        );
      },
    );
  }
}

/// The slider knob: a [fill] disc ringed in the theme's thumb colour, so it
/// reads on the track and on the page in light and dark themes alike.
class _RingThumbShape extends SliderComponentShape {
  final Color fill;
  final Color shadow;

  const _RingThumbShape({required this.fill, required this.shadow});

  static const _radius = 9.0;
  static const _ring = 2.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final ring = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation)!;
    final canvas = context.canvas;
    canvas.drawCircle(
      center + const Offset(0, 1),
      _radius,
      Paint()
        // token-literal: the thumb's shadow
        ..color = shadow.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(center, _radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      _radius - _ring / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ring
        ..color = ring,
    );
  }
}
