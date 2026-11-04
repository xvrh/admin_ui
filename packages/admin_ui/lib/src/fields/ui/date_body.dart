import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../../common/pointer.dart';
import '../../common/ui/calendar.dart';
import '../../common/ui/clear_button.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/field_style.dart';
import '../../theme/spacing.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'masked_body.dart';

/// What the control captures.
enum DateGranularity {
  /// A calendar day.
  date,

  /// A day and a time of day.
  dateTime,

  /// A time of day only — no calendar.
  time,
}

/// How the field is edited.
/// - [segmented]: the classic read-only trigger → popover with per-part cells.
/// - [masked]: the same trigger → popover, but a single masked field inside.
/// - [inline]: no trigger — an always-editable masked field with a calendar
///   button beside it (faster for keyboard/paste; no compact read-only display).
enum DateEditorStyle { segmented, masked, inline }

/// The bare date/time control — no label or capability chrome — so the same
/// body sits inside a [FieldShell] (a real `DateTime`) or one lane of a
/// translatable field.
///
/// A clean display of the value. Pressing it opens a popover holding a strict
/// segmented editor — numeric `DD / MM / YYYY` (and `HH : MM`), each cell
/// bounded to its range so only valid parts can be entered, and blank until
/// a value is set — above the calendar. Opened from the keyboard, focus lands
/// on the calendar's day; a time-only editor takes it on its first cell.
///
/// A null [onChanged] makes it read-only: the value stays at full contrast
/// and focusable, but nothing opens and no chevron or clear shows. A disabled
/// look, and a red outline, come from the enclosing [FieldStateScope].
class DateBody extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final DateGranularity granularity;

  /// Selectable bounds; days outside are shown disabled in the calendar.
  final DateTime? min;
  final DateTime? max;

  /// Offer a clear (×) affordance when a value is set.
  final bool clearable;

  final String? hint;

  /// Overrides the locale for the displayed value and the calendar's
  /// month/weekday labels (e.g. `'fr'`, `'ja'`). Null follows the ambient
  /// [Localizations.localeOf]. The editor cells stay ISO-numeric regardless,
  /// so strict entry is locale-independent.
  final String? locale;

  /// Which keyboard editor the popover shows above the calendar.
  final DateEditorStyle editor;

  /// The day the calendar marks as today, and the date an empty value takes
  /// its missing parts from once one is entered; defaults to the current
  /// date. Pass a fixed day where the render must not depend on the clock.
  final DateTime? today;

  /// The time of day an empty value takes once a date is entered or picked
  /// ([DateGranularity.dateTime]), or once only one of hour and minute is
  /// ([DateGranularity.time]).
  final TimeOfDay defaultTime;

  const DateBody({
    super.key,
    this.value,
    this.onChanged,
    this.granularity = DateGranularity.date,
    this.min,
    this.max,
    this.clearable = true,
    this.hint,
    this.locale,
    this.editor = DateEditorStyle.segmented,
    this.today,
    this.defaultTime = const TimeOfDay(hour: 0, minute: 0),
  });

  bool get _readOnly => onChanged == null;

  String _placeholder(BuildContext context) {
    if (hint case final hint?) return hint;
    if (_readOnly) return '—';
    final messages = context.adminL10n.fields;
    return switch (granularity) {
      DateGranularity.date => messages.selectDate,
      DateGranularity.dateTime => messages.selectDateTime,
      DateGranularity.time => messages.selectTime,
    };
  }

  // The explicit override, else the ambient Flutter locale, else Intl's default.
  String? _localeFor(BuildContext context) =>
      locale ?? Localizations.maybeLocaleOf(context)?.toString();

  // Locale-aware skeletons — the part order localizes too (en: "Jun 18, 2026",
  // fr: "18 juin 2026", ja: "2026年6月18日") — in the digits of the kit's
  // numbers.
  DateFormat _format(BuildContext context, String? loc) {
    final formats = locale == null
        ? context.adminFormats
        : AdminFormats(locale!);
    return formats.dateFormat(switch (granularity) {
      DateGranularity.date => DateFormat.yMMMd(loc),
      DateGranularity.dateTime => DateFormat.yMMMd(loc).add_Hm(),
      DateGranularity.time => DateFormat.Hm(loc),
    });
  }

  IconData get _icon => granularity == DateGranularity.time
      ? Icons.schedule_rounded
      : Icons.calendar_month_outlined;

  DateTime get _today => DateUtils.dateOnly(today ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    var loc = _localeFor(context);
    if (editor == DateEditorStyle.inline) return _inline(context, loc);
    return _PopoverFocus(
      builder: (context, content, focusFirst) => Popover(
        side: PopoverSide.bottom,
        align: PopoverAlign.start,
        // Don't grab focus into a segment — that would block external updates
        // (a calendar pick) from reseeding the focused cell. Only a keyboard
        // open moves focus in: to the calendar's day, or the first cell of a
        // time-only editor.
        autofocus: false,
        closeOnFocusOut: true,
        anchor: (context, controller) => _trigger(
          context,
          controller,
          loc,
          granularity == DateGranularity.time ? focusFirst : null,
        ),
        content: (context, controller) => content(_picker(context, loc)),
      ),
    );
  }

  // Inline: the masked field is the control, with a calendar button alongside
  // (none for time-only). No read-only trigger.
  Widget _inline(BuildContext context, String? loc) {
    final field = MaskedDateField(
      value: value,
      onChanged: onChanged,
      granularity: granularity,
      locale: loc,
    );
    final state = FieldStateScope.of(context).merge(readOnly: _readOnly);
    if (granularity == DateGranularity.time || state.readOnly) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: AdminSpacing.md),
        _CalendarButton(
          value: value,
          min: min,
          max: max,
          locale: locale,
          today: today,
          onChanged: (day) => onChanged!(_withDay(day)),
        ),
      ],
    );
  }

  Widget _trigger(
    BuildContext context,
    PopoverController controller,
    String? loc,
    VoidCallback? onKeyboardOpen,
  ) {
    var v = value;
    return FieldTrigger(
      controller: controller,
      readOnly: _readOnly,
      chevron: true,
      onKeyboardOpen: onKeyboardOpen,
      trailing: clearable && v != null
          ? ClearButton(
              onPressed: () => onChanged?.call(null),
              label: context.adminL10n.fields.clearDate,
            )
          : null,
      // Built under the trigger's field state, for its colours.
      child: Builder(
        builder: (context) {
          final sizes = context.sizes;
          final style = fieldTextStyle(context);
          return Row(
            children: [
              Icon(
                _icon,
                size: sizes.fieldIcon,
                color: FieldStateScope.of(context).iconColor(context.colors),
              ),
              SizedBox(width: sizes.fieldIconGap),
              Expanded(
                child: Text(
                  v == null
                      ? _placeholder(context)
                      : _format(context, loc).format(v),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: v == null
                      ? style.copyWith(color: context.colors.placeholder)
                      : style,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _picker(BuildContext context, String? loc) {
    // The dateTime editor lays five number cells plus a time pair on one row,
    // which needs more than the default 296; the calendar adds enough height
    // that a picker carrying one needs headroom past the default 360, and its
    // six touch-size week rows 48px more on a touch-first platform.
    final hasTime = granularity != DateGranularity.date;
    final hasCalendar = granularity != DateGranularity.time;
    return pickerSurface(
      width: hasTime && hasCalendar ? 340 : 296,
      maxHeight: hasCalendar ? (coarsePointerByDefault ? 456 : 408) : 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (editor == DateEditorStyle.masked)
            MaskedDateField(
              value: value,
              granularity: granularity,
              locale: loc,
              onChanged: (dt) => onChanged!(dt),
            )
          else
            _DateEditor(
              value: value,
              granularity: granularity,
              locale: loc,
              today: _today,
              defaultTime: defaultTime,
              onChanged: (dt) => onChanged!(dt),
            ),
          if (hasCalendar) ...[
            const SizedBox(height: AdminSpacing.lg),
            Calendar(
              value: value,
              min: min,
              max: max,
              locale: locale,
              today: today,
              autofocus: Popover.openedByKeyboard(context),
              onChanged: (day) => onChanged!(_withDay(day)),
            ),
          ],
        ],
      ),
    );
  }

  DateTime _withDay(DateTime day) {
    var t = value;
    return DateTime(
      day.year,
      day.month,
      day.day,
      t?.hour ?? defaultTime.hour,
      t?.minute ?? defaultTime.minute,
    );
  }
}

/// Which date part a cell edits.
enum _DatePart { year, month, day }

/// A strict, segmented editor whose date cells follow the locale's part order
/// (en_US `MM / DD / YYYY`, fr `DD / MM / YYYY`, ja `YYYY / MM / DD`) and
/// separator. Each cell is bounded; editing one never disturbs the others.
/// Pasting a full value into *any* cell is detected and distributed across the
/// cells in the same order — so a locale-shaped paste lands correctly.
///
/// With no [value] the cells are blank, each showing its part's token; the
/// first entry fills the parts not typed from [today] and [defaultTime].
class _DateEditor extends StatelessWidget {
  final DateTime? value;
  final DateGranularity granularity;
  final String? locale;
  final DateTime today;
  final TimeOfDay defaultTime;
  final ValueChanged<DateTime> onChanged;

  const _DateEditor({
    required this.value,
    required this.granularity,
    required this.locale,
    required this.today,
    required this.defaultTime,
    required this.onChanged,
  });

  bool get _hasDate => granularity != DateGranularity.time;
  bool get _hasTime => granularity != DateGranularity.date;

  int _digits(_DatePart p) => p == _DatePart.year ? 4 : 2;

  // Part order + separator from the locale's short-date pattern
  // (en_US: M/d/y, fr: dd/MM/y, de: dd.MM.y, ja: y/MM/dd).
  (List<_DatePart>, String) _localeDate() => _localeDateLayout(locale);

  void _emit({int? year, int? month, int? day, int? hour, int? minute}) {
    var v = value;
    var y = (year ?? v?.year ?? today.year).clamp(1, 9999);
    var mo = (month ?? v?.month ?? today.month).clamp(1, 12);
    var d = (day ?? v?.day ?? today.day).clamp(
      1,
      DateUtils.getDaysInMonth(y, mo),
    );
    var h = (hour ?? v?.hour ?? defaultTime.hour).clamp(0, 23);
    var mi = (minute ?? v?.minute ?? defaultTime.minute).clamp(0, 59);
    onChanged(DateTime(y, mo, d, h, mi));
  }

  // A full value pasted into one cell. The date is always 8 digits (YYYY+MM+DD
  // in some order) and the time the trailing 4. We try ISO, then the locale
  // order, then DMY/MDY, and take the first interpretation that's a real date
  // — so an ISO paste works in a US/French editor and vice versa.
  void _onBulk(List<_DatePart> order, String digits) {
    var dateLen = _hasDate ? 8 : 0;
    var total = dateLen + (_hasTime ? 4 : 0);
    // Paste lands on top of the cell's existing digits — keep the trailing run.
    if (digits.length > total) digits = digits.substring(digits.length - total);
    if (digits.length < total) return;

    int? hour, minute;
    if (_hasTime) {
      var t = digits.substring(dateLen);
      hour = int.parse(t.substring(0, 2));
      minute = int.parse(t.substring(2, 4));
    }
    if (!_hasDate) {
      _emit(hour: hour, minute: minute);
      return;
    }

    var d8 = digits.substring(0, 8);
    const iso = [_DatePart.year, _DatePart.month, _DatePart.day];
    const dmy = [_DatePart.day, _DatePart.month, _DatePart.year];
    const mdy = [_DatePart.month, _DatePart.day, _DatePart.year];
    for (var cand in [iso, order, dmy, mdy]) {
      var p = _slice(d8, cand);
      if (_validDate(p)) {
        _emit(
          year: p[_DatePart.year],
          month: p[_DatePart.month],
          day: p[_DatePart.day],
          hour: hour,
          minute: minute,
        );
        return;
      }
    }
    // Nothing fully valid — fall back to the locale order (clamped by _emit).
    var p = _slice(d8, order);
    _emit(
      year: p[_DatePart.year],
      month: p[_DatePart.month],
      day: p[_DatePart.day],
      hour: hour,
      minute: minute,
    );
  }

  Map<_DatePart, int> _slice(String d8, List<_DatePart> order) {
    var map = <_DatePart, int>{};
    var idx = 0;
    for (var p in order) {
      map[p] = int.parse(d8.substring(idx, idx + _digits(p)));
      idx += _digits(p);
    }
    return map;
  }

  bool _validDate(Map<_DatePart, int> p) {
    var y = p[_DatePart.year]!, mo = p[_DatePart.month]!, d = p[_DatePart.day]!;
    if (mo < 1 || mo > 12 || y < 1 || y > 9999) return false;
    return d >= 1 && d <= DateUtils.getDaysInMonth(y, mo);
  }

  /// The cells' [tokens], in the order the cells are laid out. In
  /// right-to-left text a right-to-left mark after each date token keeps
  /// Latin ones in the mirrored order of the date cells, and the time is a
  /// left-to-right isolate, in the order of its cells.
  String _legend(
    List<_DatePart> order,
    String sep,
    TextDirection direction,
    ({String year, String month, String day, String hour, String minute})
    tokens,
  ) {
    final rtl = direction == TextDirection.rtl;
    final mark = rtl ? '\u200F' : '';
    var date = [for (var p in order) _partToken(p, tokens)].join('$mark $sep ');
    // A left-to-right mark after the hour keeps even right-to-left tokens
    // in the order of the cells.
    final time = rtl
        ? '\u2066${tokens.hour}\u200E : ${tokens.minute}\u2069'
        : '${tokens.hour} : ${tokens.minute}';
    return switch (granularity) {
      DateGranularity.date => date,
      DateGranularity.dateTime => '$date$mark · $time',
      DateGranularity.time => time,
    };
  }

  @override
  Widget build(BuildContext context) {
    var (order, sep) = _localeDate();
    var v = value;
    final messages = context.adminL10n.fields;
    final tokens = messages.dateTokens;
    var bulk = [
      for (var p in order) _digits(p),
      if (_hasTime) ...[2, 2],
    ].fold(0, (a, c) => a + c);

    Widget seg(
      int? value,
      int min,
      int max,
      double width,
      String semantic,
      String token,
      ValueChanged<int> onCh,
    ) => _Seg(
      value: value,
      min: min,
      max: max,
      width: width,
      semantic: semantic,
      token: token,
      bulkDigits: bulk,
      onChanged: onCh,
      onBulk: (d) => _onBulk(order, d),
    );

    Widget cell(_DatePart p) => switch (p) {
      _DatePart.year => seg(
        v?.year,
        1,
        9999,
        60,
        messages.year,
        _partToken(p, tokens),
        (n) => _emit(year: n),
      ),
      _DatePart.month => seg(
        v?.month,
        1,
        12,
        42,
        messages.month,
        _partToken(p, tokens),
        (n) => _emit(month: n),
      ),
      _DatePart.day => seg(
        v?.day,
        1,
        31,
        42,
        messages.day,
        _partToken(p, tokens),
        (n) => _emit(day: n),
      ),
    };

    var row = <Widget>[];
    if (_hasDate) {
      for (var i = 0; i < order.length; i++) {
        if (i > 0) row.add(_sep(context, sep));
        row.add(cell(order[i]));
      }
    }
    if (_hasDate && _hasTime) row.add(const Spacer());
    if (_hasTime) {
      // A clock reads hours then minutes left to right in every script, so
      // the pair keeps its order in a right-to-left date row.
      row.add(
        Directionality(
          // Physical: hours before minutes.
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              seg(
                v?.hour,
                0,
                23,
                42,
                messages.hour,
                tokens.hour,
                (n) => _emit(hour: n),
              ),
              _sep(context, ':'),
              seg(
                v?.minute,
                0,
                59,
                42,
                messages.minute,
                tokens.minute,
                (n) => _emit(minute: n),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: row),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          _legend(order, sep, Directionality.of(context), tokens),
          style: context.type.caption,
        ),
      ],
    );
  }

  Widget _sep(BuildContext context, String s) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs),
    child: Text(
      s,
      style: context.type.body.copyWith(color: context.colors.foregroundMuted),
    ),
  );
}

/// One bounded numeric cell, zero-padded to its width and blank, showing its
/// [token], while [value] is null. Focusing it selects its digits, so typing
/// replaces them; typing past its width keeps the latest digits. Pasting a
/// whole value (≥ [bulkDigits] digits) is forwarded to [onBulk] instead.
class _Seg extends StatefulWidget {
  final int? value;
  final int min;
  final int max;
  final double width;
  final String semantic;

  /// The part's placeholder, e.g. `DD`.
  final String token;
  final int bulkDigits;
  final ValueChanged<int> onChanged;
  final ValueChanged<String> onBulk;

  const _Seg({
    required this.value,
    required this.min,
    required this.max,
    required this.width,
    required this.semantic,
    required this.token,
    required this.bulkDigits,
    required this.onChanged,
    required this.onBulk,
  });

  @override
  State<_Seg> createState() => _SegState();
}

class _SegState extends State<_Seg> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);

  int get _maxLen => '${widget.max}'.length;

  String _format(int? n) => n == null ? '' : '$n'.padLeft(_maxLen, '0');

  // Set after a bulk paste so the upcoming blur doesn't re-commit this cell's
  // now-stale text over the distributed value.
  bool _skipCommit = false;

  void _onFocus() {
    if (!_focus.hasFocus) {
      if (_skipCommit) {
        _skipCommit = false;
      } else {
        _commit();
      }
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _Seg old) {
    super.didUpdateWidget(old);
    final text = _format(widget.value);
    if (!_focus.hasFocus && text != _controller.text) _controller.text = text;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _set(String t) => _controller.value = TextEditingValue(
    text: t,
    selection: TextSelection.collapsed(offset: t.length),
  );

  void _onChanged(String s) {
    if (s.length > _maxLen) {
      // A multi-part paste (full date) — hand the whole digit run upward and
      // bow out; unfocus so the reseed (didUpdateWidget) restores this cell.
      if (s.length >= widget.bulkDigits) {
        widget.onBulk(s);
        _skipCommit = true;
        _focus.unfocus();
        return;
      }
      // Typing on past a full cell — the latest digits, or the last one
      // alone when they read past the part's range.
      var tail = s.substring(s.length - _maxLen);
      if (int.parse(tail) > widget.max) tail = s.substring(s.length - 1);
      s = tail;
      _set(s);
    }
    if (s.isEmpty) return;
    var n = int.parse(s);
    if (n > widget.max) {
      n = widget.max;
      _set('$n');
    }
    widget.onChanged(n);
  }

  void _commit() {
    final typed = int.tryParse(_controller.text);
    final n = (typed ?? widget.value)?.clamp(widget.min, widget.max);
    final text = _format(n);
    if (text != _controller.text) _controller.text = text;
    if (typed != null && n != null) widget.onChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.adminTokens;
    final type = context.type;
    // The field's type on its fixed line, at the control height.
    final style = type.weighted(type.fieldText, type.spec.strong);
    // Each cell in the theme's field anatomy, except that it draws no frame
    // of its own where the field has none to lend it: a filled or underlined
    // theme's cell is its fill and rule, the way Fluent's underline input is.
    final field = tokens.field;
    final border = FieldBorder(
      palette: tokens.palette,
      stroke: tokens.stroke,
      style: field.variant == FieldVariant.outlined
          ? field
          : field.copyWith(variant: FieldVariant.filled),
      borderRadius: BorderRadius.circular(
        math.min(tokens.radii.radiusSmall, tokens.radii.radiusField),
      ),
    );
    return SizedBox(
      width: widget.width,
      child: Semantics(
        label: widget.semantic,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          selectAllOnFocus: true,
          // No length limit — a full-value paste must reach onChanged to be
          // detected and distributed.
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onChanged,
          style: style,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.token,
            hintStyle: style.copyWith(color: tokens.palette.placeholder),
            contentPadding: EdgeInsets.symmetric(
              vertical: fieldPaddingY(type, context.sizes.medium),
              horizontal: AdminSpacing.xs,
            ),
            filled: true,
            fillColor: WidgetStateColor.resolveWith(
              (states) => border.chromeOf(states).fill,
            ),
            hoverColor: const Color(0x00000000),
            border: border,
          ),
        ),
      ),
    );
  }
}

// Part order + separator from the locale's short-date pattern, always returning
// all three parts (en_US M/d/y, fr dd/MM/y, ja y/MM/dd; fallback ISO).
(List<_DatePart>, String) _localeDateLayout(String? locale) {
  String pattern;
  try {
    pattern = DateFormat.yMd(locale).pattern ?? 'y/M/d';
  } catch (_) {
    pattern = 'y/M/d';
  }
  final order = <_DatePart>[];
  for (final ch in pattern.split('')) {
    final p = switch (ch) {
      'y' => _DatePart.year,
      'M' || 'L' => _DatePart.month,
      'd' => _DatePart.day,
      _ => null,
    };
    if (p != null && !order.contains(p)) order.add(p);
  }
  for (final p in _DatePart.values) {
    if (!order.contains(p)) order.add(p);
  }
  // Bidi marks around the separators (Arabic's 'd‏/M‏/y') are not one.
  var sep = '/';
  for (final ch in pattern.split('')) {
    if (!RegExp('[a-zA-Z\u200E\u200F\u061C]').hasMatch(ch) &&
        ch.trim().isNotEmpty) {
      sep = ch;
      break;
    }
  }
  return (order, sep);
}

/// The calendar-icon button used by [DateEditorStyle.inline] — a square of
/// the control height in the field's chrome that opens just the [Calendar]
/// in a popover, and hands focus back to itself when a pick closes it.
class _CalendarButton extends StatefulWidget {
  final DateTime? value;
  final DateTime? min;
  final DateTime? max;
  final String? locale;
  final DateTime? today;
  final ValueChanged<DateTime> onChanged;

  const _CalendarButton({
    required this.value,
    required this.min,
    required this.max,
    required this.locale,
    required this.today,
    required this.onChanged,
  });

  @override
  State<_CalendarButton> createState() => _CalendarButtonState();
}

class _CalendarButtonState extends State<_CalendarButton> {
  final _node = FocusNode(debugLabel: 'Calendar button');
  final _content = FocusNode(
    debugLabel: 'Calendar button popover',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _node.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(context).datePickerHelpText;
    final state = FieldStateScope.of(context);
    final side = context.sizes.medium;
    return Popover(
      side: PopoverSide.bottom,
      align: PopoverAlign.end,
      autofocus: false,
      closeOnFocusOut: true,
      anchor: (context, controller) => Tip(
        message: label,
        excludeFromSemantics: true,
        child: Tappable.states(
          onTap: state.enabled ? controller.toggle : null,
          focusNode: _node,
          semanticLabel: label,
          excludeSemantics: true,
          expanded: controller.isOpen,
          // The chrome's field focus shows keyboard focus.
          showFocusRing: false,
          builder: (context, states) => FieldChrome(
            active: controller.isOpen || states.contains(WidgetState.focused),
            hovered: states.contains(WidgetState.hovered),
            padding: EdgeInsets.zero,
            child: SizedBox.square(
              // Inside a control-wide edge.
              dimension: side - 2 * context.stroke.control,
              child: Center(
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: context.sizes.fieldIcon,
                  color: state.iconColor(context.colors),
                ),
              ),
            ),
          ),
        ),
      ),
      content: (context, controller) => FocusTraversalGroup(
        child: Focus(
          focusNode: _content,
          includeSemantics: false,
          child: pickerSurface(
            child: Calendar(
              value: widget.value,
              min: widget.min,
              max: widget.max,
              locale: widget.locale,
              today: widget.today,
              autofocus: Popover.openedByKeyboard(context),
              onChanged: (day) {
                final refocus = _content.hasFocus;
                widget.onChanged(day);
                controller.close();
                if (refocus) _node.requestFocus();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Holds a popover's content in a focus subtree so a keyboard open can move
/// focus to its first stop: [builder] gets the wrapper for the content and
/// the callback that focuses it, to run once the popover is open.
class _PopoverFocus extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    Widget Function(Widget content) content,
    VoidCallback focusFirst,
  )
  builder;

  const _PopoverFocus({required this.builder});

  @override
  State<_PopoverFocus> createState() => _PopoverFocusState();
}

class _PopoverFocusState extends State<_PopoverFocus> {
  final _content = FocusNode(
    debugLabel: 'date popover',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  // Its own traversal group, so Tab walks the content in order wherever the
  // popover sits over the page.
  Widget _wrap(Widget content) => FocusTraversalGroup(
    child: Focus(focusNode: _content, child: content),
  );

  /// Focuses the content's first stop, or once it is built when the popover
  /// has only just been told to open.
  void _focusFirst() {
    if (_content.context != null) {
      _content.traversalDescendants.firstOrNull?.requestFocus();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _content.traversalDescendants.firstOrNull?.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _wrap, _focusFirst);
}

int _partWidth(_DatePart p) => p == _DatePart.year ? 4 : 2;

String _partToken(
  _DatePart p,
  ({String year, String month, String day, String hour, String minute}) tokens,
) => switch (p) {
  _DatePart.year => tokens.year,
  _DatePart.month => tokens.month,
  _DatePart.day => tokens.day,
};

int _partValue(_DatePart p, DateTime d) => switch (p) {
  _DatePart.year => d.year,
  _DatePart.month => d.month,
  _DatePart.day => d.day,
};

/// A single masked date/time input — the [DateBody] popover's editor under
/// [DateEditorStyle.masked], and usable on its own. A locale-ordered mask with a
/// labelled ghost (`MM/DD/YYYY`), so keyboard entry and paste flow through one
/// [MaskFormatter] instead of per-part cells.
///
/// Emits only when the value is complete and valid — a partial edit doesn't
/// clobber the field; emptying it emits null. Parsing reads the locale order
/// first (typing is unambiguous), then ISO/DMY/MDY (so an ISO paste into a US
/// field still lands), then clamps to a real calendar date (Feb 30 → Feb 28).
class MaskedDateField extends StatefulWidget {
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final DateGranularity granularity;
  final String? locale;

  const MaskedDateField({
    super.key,
    this.value,
    this.onChanged,
    this.granularity = DateGranularity.date,
    this.locale,
  });

  @override
  State<MaskedDateField> createState() => _MaskedDateFieldState();
}

class _MaskedDateFieldState extends State<MaskedDateField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late _DateShape _shape;
  late DateMaskFormatter _formatter;
  bool _suppress = false;

  bool get _disabled => widget.onChanged == null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  void _rebuildShape() {
    _shape = _DateShape.of(
      _localeFor(context),
      widget.granularity,
      context.adminL10n.fields.dateTokens,
    );
    _formatter = DateMaskFormatter(
      _shape.mask,
      bounds: _shape.bounds,
      eager: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildShape();
    _syncText();
  }

  @override
  void didUpdateWidget(covariant MaskedDateField old) {
    super.didUpdateWidget(old);
    if (old.granularity != widget.granularity || old.locale != widget.locale) {
      _rebuildShape();
    }
    _syncText();
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _focus.removeListener(_onFocus);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? _localeFor(BuildContext context) =>
      widget.locale ?? Localizations.maybeLocaleOf(context)?.toString();

  // Pull the text back in line with the value — but never mid-typing; the
  // canonical (clamped) reformat happens on blur and external change.
  void _syncText() {
    if (_focus.hasFocus) return;
    final text = widget.value == null ? '' : _shape.toMasked(widget.value!);
    if (_controller.text != text) {
      _suppress = true;
      _controller.text = text;
      _suppress = false;
    }
  }

  void _onFocus() {
    if (!_focus.hasFocus) _syncText();
  }

  void _onText() {
    if (_suppress) return;
    final digits = MaskFormatter.unmask(_shape.mask, _controller.text);
    if (digits.isEmpty) {
      widget.onChanged?.call(null);
      return;
    }
    final dt = _shape.parse(digits, day: widget.value ?? DateTime.now());
    if (dt != null) widget.onChanged?.call(dt); // partial → keep current value
  }

  @override
  Widget build(BuildContext context) {
    return MaskedBody(
      controller: _controller,
      focusNode: _focus,
      mask: _shape.mask,
      formatter: _formatter,
      ghostMask: true,
      ghostTemplate: _shape.label,
      eager: true,
      readOnly: _disabled,
      keyboardType: TextInputType.number,
    );
  }
}

/// The locale-derived shape: the [mask] tokens, a matching ghost [label], and
/// the date-part order used to slice typed digits.
class _DateShape {
  final String mask;

  /// The part tokens laid over the mask, or null where a language's tokens
  /// are not as long as their parts: the mask's own blanks show instead.
  final String? label;
  final List<_DatePart> order; // empty for time-only
  final bool hasTime;

  const _DateShape({
    required this.mask,
    required this.label,
    required this.order,
    required this.hasTime,
  });

  /// Per-segment `(min, max)` in mask order — the clamp bounds for
  /// [DateMaskFormatter]. Days use a flat 1–31; the real days-in-month is
  /// applied later in [parse].
  List<(int, int)> get bounds => [
    for (final p in order)
      switch (p) {
        _DatePart.year => (1, 9999),
        _DatePart.month => (1, 12),
        _DatePart.day => (1, 31),
      },
    if (hasTime) ...[(0, 23), (0, 59)],
  ];

  static _DateShape of(
    String? locale,
    DateGranularity g,
    ({String year, String month, String day, String hour, String minute})
    tokens,
  ) {
    final hasDate = g != DateGranularity.time;
    final hasTime = g != DateGranularity.date;
    var order = <_DatePart>[];
    var sep = '';
    if (hasDate) (order, sep) = _localeDateLayout(locale);

    final maskParts = [for (final p in order) '#' * _partWidth(p)];
    final labelParts = [for (final p in order) _partToken(p, tokens)];
    var mask = maskParts.join(sep);
    var label = labelParts.join(sep);
    if (hasDate && hasTime) {
      mask += '  ';
      label += '  ';
    }
    if (hasTime) {
      mask += '##:##';
      label += '${tokens.hour}:${tokens.minute}';
    }
    return _DateShape(
      mask: mask,
      label: label.length == mask.length ? label : null,
      order: order,
      hasTime: hasTime,
    );
  }

  String toMasked(DateTime d) {
    final b = StringBuffer();
    for (final p in order) {
      b.write(_partValue(p, d).toString().padLeft(_partWidth(p), '0'));
    }
    if (hasTime) {
      b.write(d.hour.toString().padLeft(2, '0'));
      b.write(d.minute.toString().padLeft(2, '0'));
    }
    return MaskFormatter.apply(mask, b.toString());
  }

  static const _iso = [_DatePart.year, _DatePart.month, _DatePart.day];
  static const _dmy = [_DatePart.day, _DatePart.month, _DatePart.year];
  static const _mdy = [_DatePart.month, _DatePart.day, _DatePart.year];

  /// Parse a raw digit run into a clamped calendar date, or null if incomplete.
  /// A time-only shape puts the time on [day].
  DateTime? parse(String digits, {required DateTime day}) {
    final dateLen = order.isEmpty ? 0 : 8;
    final need = dateLen + (hasTime ? 4 : 0);
    if (digits.length < need) return null;

    var hour = 0, minute = 0;
    if (hasTime) {
      hour = int.parse(digits.substring(dateLen, dateLen + 2)).clamp(0, 23);
      minute = int.parse(digits.substring(dateLen + 2, dateLen + 4))
          .clamp(0, 59);
    }
    if (order.isEmpty) {
      return DateTime(day.year, day.month, day.day, hour, minute);
    }

    final d8 = digits.substring(0, 8);
    for (final cand in [order, _iso, _dmy, _mdy]) {
      final (y, m, d) = _slice(d8, cand);
      if (m >= 1 &&
          m <= 12 &&
          y >= 1 &&
          d >= 1 &&
          d <= DateUtils.getDaysInMonth(y, m)) {
        return DateTime(y, m, d, hour, minute);
      }
    }
    final (y, m, d) = _slice(d8, order);
    final cy = y.clamp(1, 9999), cm = m.clamp(1, 12);
    return DateTime(
      cy,
      cm,
      d.clamp(1, DateUtils.getDaysInMonth(cy, cm)),
      hour,
      minute,
    );
  }

  (int, int, int) _slice(String d8, List<_DatePart> cand) {
    var i = 0, year = 0, month = 0, day = 0;
    for (final p in cand) {
      final n = int.parse(d8.substring(i, i + _partWidth(p)));
      i += _partWidth(p);
      switch (p) {
        case _DatePart.year:
          year = n;
        case _DatePart.month:
          month = n;
        case _DatePart.day:
          day = n;
      }
    }
    return (year, month, day);
  }
}

/// A [MaskFormatter] that, while typing, clamps each completed numeric segment
/// to its `(min, max)` (month `99→12`, day `99→31`) — Tier-1 of the imask-style
/// "autofix" behaviour. Clamps only on single-character typing: a paste keeps
/// its raw digits so the cross-format parser can still reinterpret them.
class DateMaskFormatter extends MaskFormatter {
  /// Per-segment `(min, max)` in mask order.
  final List<(int, int)> bounds;

  // (charStart, width, min, max) per segment, in the formatted text's columns.
  late final List<(int, int, int, int)> _segments = _segmentsFor(mask, bounds);

  DateMaskFormatter(super.mask, {required this.bounds, super.eager});

  static List<(int, int, int, int)> _segmentsFor(
    String mask,
    List<(int, int)> bounds,
  ) {
    final segs = <(int, int, int, int)>[];
    var i = 0, b = 0;
    while (i < mask.length) {
      if (mask[i] != '#') {
        i++;
        continue;
      }
      final start = i;
      while (i < mask.length && mask[i] == '#') {
        i++;
      }
      final (min, max) = b < bounds.length ? bounds[b] : (0, 0);
      segs.add((start, i - start, min, max));
      b++;
    }
    return segs;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // A single character (a typed digit or a separator) clamps; a paste (raw
    // digits must survive for the cross-format parser) and a deletion don't.
    final single = newValue.text.length == oldValue.text.length + 1;
    final result = super.formatEditUpdate(
      oldValue,
      _padOnSeparator(oldValue, newValue),
    );
    return single ? _clamp(result) : result;
  }

  // Typing a separator while the current segment is half-filled left-pads it, so
  // "1/1/2000" enters Jan 1 instead of running the digits together into "11/20".
  TextEditingValue _padOnSeparator(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length != oldValue.text.length + 1) return newValue;
    final caret = newValue.selection.end;
    if (caret != newValue.text.length || caret <= 0) return newValue;
    final code = newValue.text.codeUnitAt(caret - 1);
    // A digit, not a separator.
    if (code >= 0x30 && code <= 0x39) return newValue;
    final digits = MaskFormatter.unmask(mask, oldValue.text);
    if (digits.isEmpty) return newValue;
    var acc = 0;
    for (final (_, width, _, _) in _segments) {
      if (digits.length < acc + width) {
        if (digits.length == acc) return newValue; // current segment empty
        final padded = digits.substring(acc).padLeft(width, '0');
        final next = digits.substring(0, acc) + padded;
        return TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
      acc += width;
    }
    return newValue;
  }

  // Clamp each fully-typed segment to its (min, max), in place.
  TextEditingValue _clamp(TextEditingValue v) {
    final chars = v.text.split('');
    var changed = false;
    for (final (start, width, min, max) in _segments) {
      if (start + width > chars.length) break; // segment not fully typed yet
      final seg = chars.sublist(start, start + width).join();
      if (seg.codeUnits.any((c) => c < 0x30 || c > 0x39)) continue;
      final n = int.parse(seg).clamp(min, max);
      final padded = n.toString().padLeft(width, '0');
      if (padded != seg) {
        for (var k = 0; k < width; k++) {
          chars[start + k] = padded[k];
        }
        changed = true;
      }
    }
    return changed
        ? TextEditingValue(text: chars.join(), selection: v.selection)
        : v;
  }
}
