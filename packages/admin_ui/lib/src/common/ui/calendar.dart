import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../pointer.dart';
import '../text_metrics.dart';
import 'focus_ring.dart';
import 'icon_action.dart';
import 'tappable.dart';

/// What a [Calendar] selects.
enum CalendarMode {
  /// A single day.
  single,

  /// A start–end span; tap once for the start, again for the end.
  range,
}

/// A month grid — header nav, weekday strip, 6×7 day cells — usable on its own
/// (a popover body, an inline scheduler, a filter). In [CalendarMode.single] it
/// drives [value] / [onChanged]; in [CalendarMode.range] it drives [range] /
/// [onRangeChanged], painting a connected band with a live hover preview while
/// the end is being chosen. A picked day, and each end of a range, is filled
/// with the control accent, as a checked Check is.
///
/// Every day it reports is a local date at midnight, and a range includes its
/// [DateTimeRange.end]: a one-day span has `start == end`.
///
/// **Locale.** The month title, the weekday initials, the week's first day
/// and each day's spoken date follow the app's locale, or an explicit
/// [locale], from `intl`'s date data: Material's delegates load it for the
/// app's locale, and `initializeDateFormatting` for any other. Its digits
/// are the ones the kit's numbers use ([AdminFormats.dateFormat]), so an
/// Arabic month title matches the day numbers under it. Without that data
/// they come from the ambient [MaterialLocalizations]. [firstDayOfWeek]
/// overrides the week start either way.
///
/// **Keyboard.** The grid is one Tab stop: the selected day, else today, else
/// the month's first selectable day. The arrows move by day and by week,
/// Home and End to the week's first and last day, Page Up and Page Down by a
/// month, and with Shift by a year, never past [min] or [max]; the month
/// follows the focused day. Enter or Space picks it. Each day is announced as
/// a button with its full date, whether it is selected, today, or a range's
/// start or end.
class Calendar extends StatefulWidget {
  final CalendarMode mode;

  /// Selected day, single mode.
  final DateTime? value;

  /// Called with the picked day, single mode.
  final ValueChanged<DateTime>? onChanged;

  /// Selected span, range mode; its [DateTimeRange.end] is included.
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange>? onRangeChanged;

  /// Selectable bounds, both included; days outside are disabled.
  final DateTime? min;
  final DateTime? max;

  /// An `intl` locale for the names and the week layout, e.g. `'fr'`; null
  /// follows [MaterialLocalizations].
  final String? locale;

  /// The first column, as an index into [MaterialLocalizations.narrowWeekdays]
  /// (0 is Sunday, 1 Monday … 6 Saturday); null takes the locale's.
  final int? firstDayOfWeek;

  /// The day marked as today; defaults to the current date. Pass a fixed day
  /// where the render must not depend on the clock, as a demo or a test does.
  final DateTime? today;

  /// Moves focus to the grid's Tab stop once it is first laid out — for a
  /// popover opened from the keyboard.
  final bool autofocus;

  const Calendar({
    super.key,
    this.mode = CalendarMode.single,
    this.value,
    this.onChanged,
    this.range,
    this.onRangeChanged,
    this.min,
    this.max,
    this.locale,
    this.firstDayOfWeek,
    this.today,
    this.autofocus = false,
  });

  @override
  State<Calendar> createState() => _CalendarState();
}

/// The side of a day's fill and the height of its week row, whose whole
/// height and column width take the day's taps: 32 in a 36px row for a
/// mouse; on a touch-first platform 36 in a 44px row, Material's 40dp day in
/// its 48dp target brought to the 44px touch minimum.
({double day, double row}) get _cell =>
    coarsePointerByDefault ? (day: 36, row: 44) : (day: 32, row: 36);

/// Six weeks of seven days: every month fits whatever its first weekday.
const int _slots = 42;

class _CalendarState extends State<Calendar> {
  /// One node per grid slot, kept as the month changes under them.
  final _nodes = [
    for (var i = 0; i < _slots; i++) FocusNode(debugLabel: 'Calendar day $i'),
  ];

  late DateTime _month = _monthOf(_anchorDay);

  /// The first column's weekday, 0 for Sunday; resolved on every build.
  int _weekStart = 0;

  /// The day the keyboard or a pick last settled on; the Tab stop while it
  /// is in the shown month.
  DateTime? _focused;

  /// Range mode: the first picked endpoint while the second is pending.
  DateTime? _pendingStart;
  DateTime? _hover;

  DateTime get _today => DateUtils.dateOnly(widget.today ?? DateTime.now());

  DateTime get _anchorDay => widget.value ?? widget.range?.end ?? _today;

  bool get _interactive => widget.mode == CalendarMode.single
      ? widget.onChanged != null
      : widget.onRangeChanged != null;

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  /// [d] moved by [months], on the same day or the last one that month has.
  static DateTime _addMonths(DateTime d, int months) {
    final month = DateTime(d.year, d.month + months);
    final last = DateUtils.getDaysInMonth(month.year, month.month);
    return DateTime(month.year, month.month, math.min(d.day, last));
  }

  bool _inMonth(DateTime d) => d.year == _month.year && d.month == _month.month;

  /// Blank slots before the 1st, so it lands under its weekday.
  int get _leading =>
      (DateTime(_month.year, _month.month).weekday % 7 - _weekStart) % 7;

  DateTime _dayAt(int slot) =>
      DateTime(_month.year, _month.month, 1 - _leading + slot);

  /// The slot of [day], which is in the shown month.
  int _slotOf(DateTime day) => _leading + day.day - 1;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final stop = _stop;
        if (mounted && stop != null) _nodes[_slotOf(stop)].requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant Calendar old) {
    super.didUpdateWidget(old);
    if (widget.value != null && widget.value != old.value) {
      _month = _monthOf(widget.value!);
    }
    final range = widget.range;
    if (range != null && range != old.range) {
      _pendingStart = null;
      _hover = null;
      if (!_inMonth(range.start) && !_inMonth(range.end)) {
        _month = _monthOf(range.end);
      }
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  DateTime? get _min =>
      widget.min == null ? null : DateUtils.dateOnly(widget.min!);
  DateTime? get _max =>
      widget.max == null ? null : DateUtils.dateOnly(widget.max!);

  bool _disabled(DateTime day) {
    final min = _min, max = _max;
    return (min != null && day.isBefore(min)) ||
        (max != null && day.isAfter(max));
  }

  DateTime _clamp(DateTime day) {
    final min = _min, max = _max;
    if (min != null && day.isBefore(min)) return min;
    if (max != null && day.isAfter(max)) return max;
    return day;
  }

  /// The day holding the grid's Tab stop: the last focused one, the
  /// selection, today, or the first selectable day, whichever is first in
  /// the shown month and selectable. Null when nothing can be picked.
  DateTime? get _stop {
    if (!_interactive) return null;
    final range = widget.range;
    for (final day in [
      _focused,
      _pendingStart,
      widget.value,
      range?.start,
      range?.end,
      _today,
    ]) {
      if (day == null) continue;
      final d = DateUtils.dateOnly(day);
      if (_inMonth(d) && !_disabled(d)) return d;
    }
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    for (var i = 1; i <= days; i++) {
      final d = DateTime(_month.year, _month.month, i);
      if (!_disabled(d)) return d;
    }
    return null;
  }

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  void _pick(DateTime day) {
    setState(() => _focused = day);
    if (widget.mode == CalendarMode.single) {
      widget.onChanged?.call(day);
      return;
    }
    final a = _pendingStart;
    if (a == null) {
      setState(() {
        _pendingStart = day;
        _hover = day;
      });
      return;
    }
    setState(() {
      _pendingStart = null;
      _hover = null;
    });
    widget.onRangeChanged?.call(
      a.isAfter(day)
          ? DateTimeRange(start: day, end: a)
          : DateTimeRange(start: a, end: day),
    );
  }

  /// Moves the keyboard focus to [day], and the month with it.
  void _moveFocus(DateTime day) {
    setState(() {
      _focused = day;
      if (!_inMonth(day)) _month = _monthOf(day);
      if (_pendingStart != null) _hover = day;
    });
    // The slot's node takes the day once the grid is rebuilt for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes[_slotOf(day)].requestFocus();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final at = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (at < 0) return KeyEventResult.ignored;
    final day = _dayAt(at);
    final back = Directionality.of(context) == TextDirection.rtl ? 1 : -1;
    final column = at % 7;
    final months = HardwareKeyboard.instance.isShiftPressed ? 12 : 1;
    final target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => _addDays(day, back),
      LogicalKeyboardKey.arrowRight => _addDays(day, -back),
      LogicalKeyboardKey.arrowUp => _addDays(day, -7),
      LogicalKeyboardKey.arrowDown => _addDays(day, 7),
      LogicalKeyboardKey.home => _addDays(day, -column),
      LogicalKeyboardKey.end => _addDays(day, 6 - column),
      LogicalKeyboardKey.pageUp => _addMonths(day, -months),
      LogicalKeyboardKey.pageDown => _addMonths(day, months),
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    _moveFocus(_clamp(target));
    return KeyEventResult.handled;
  }

  /// The (lo, hi, preview) span to paint, or null when nothing is selected.
  (DateTime, DateTime, bool)? get _span {
    if (_pendingStart != null) {
      final a = _pendingStart!, b = _hover ?? _pendingStart!;
      return a.isAfter(b) ? (b, a, true) : (a, b, true);
    }
    final r = widget.range;
    if (r != null) {
      return (DateUtils.dateOnly(r.start), DateUtils.dateOnly(r.end), false);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final names = _CalendarNames.of(context, widget.locale);
    _weekStart = widget.firstDayOfWeek ?? names.firstDayOfWeek;
    final stop = _stop;
    final stopSlot = stop == null ? -1 : _slotOf(stop);
    for (var i = 0; i < _slots; i++) {
      _nodes[i].skipTraversal = i != stopSlot;
    }
    final span = _span;
    final cell = _cellFor(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context, names),
        const SizedBox(height: AdminSpacing.md),
        _weekdays(context, names),
        const SizedBox(height: AdminSpacing.xs),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: _onKey,
          child: Column(
            children: [
              for (var w = 0; w < _slots ~/ 7; w++)
                SizedBox(
                  height: cell.row,
                  child: Row(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Expanded(
                          child: _day(
                            context,
                            names,
                            w * 7 + d,
                            span,
                            cell.day,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// [_cell], grown by as much as the day number grows at the platform's
  /// text size: a large text scale makes taller rows, where a fixed row would
  /// clip the numbers.
  ({double day, double row}) _cellFor(BuildContext context) {
    final cell = _cell;
    final grow = textGrowthOf(context, _dayStyle(context, emphasised: true));
    return (day: cell.day + grow, row: cell.row + grow);
  }

  /// A day number's style: bolder for today, a selection or a range.
  TextStyle _dayStyle(BuildContext context, {required bool emphasised}) =>
      context.type.weighted(
        context.type.bodySmall,
        emphasised ? FontWeight.w600 : FontWeight.w500,
      );

  Widget _header(BuildContext context, _CalendarNames names) {
    final strings = MaterialLocalizations.of(context);
    final min = _min, max = _max;
    return Row(
      children: [
        IconAction(
          Icons.chevron_left_rounded,
          label: strings.previousMonthTooltip,
          size: IconActionSize.small,
          onPressed: min == null || _monthOf(min).isBefore(_month)
              ? () => _shift(-1)
              : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              names.monthYear(_month),
              textAlign: TextAlign.center,
              style: context.type.bodyStrong,
            ),
          ),
        ),
        IconAction(
          Icons.chevron_right_rounded,
          label: strings.nextMonthTooltip,
          size: IconActionSize.small,
          onPressed: max == null || _monthOf(max).isAfter(_month)
              ? () => _shift(1)
              : null,
        ),
      ],
    );
  }

  /// The weekday initials; each day announces its full date, so these stay
  /// out of the semantics tree.
  Widget _weekdays(BuildContext context, _CalendarNames names) {
    final style = context.type.micro.copyWith(
      color: context.colors.foregroundMuted,
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Text(
                names.narrowWeekdays[(_weekStart + i) % 7],
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
        ],
      ),
    );
  }

  /// The day in grid [slot], a [size]-square fill centred in its cell.
  Widget _day(
    BuildContext context,
    _CalendarNames names,
    int slot,
    (DateTime, DateTime, bool)? span,
    double size,
  ) {
    final day = _dayAt(slot);
    final inMonth = _inMonth(day);
    final isToday = DateUtils.isSameDay(day, _today);
    final disabled = _disabled(day);

    var inRange = false, isStart = false, isEnd = false, preview = false;
    if (span != null) {
      final (lo, hi, prev) = span;
      preview = prev;
      inRange = !day.isBefore(lo) && !day.isAfter(hi);
      isStart = DateUtils.isSameDay(day, lo);
      isEnd = DateUtils.isSameDay(day, hi);
    }
    final selectedSingle =
        widget.mode == CalendarMode.single &&
        DateUtils.isSameDay(day, widget.value);
    final filled = selectedSingle || isStart || isEnd;

    final colors = context.colors;
    final Color fg;
    if (disabled) {
      fg = colors.foregroundSubtle;
    } else if (filled) {
      fg = colors.onControlAccent;
    } else if (inRange) {
      fg = colors.foreground;
    } else if (!inMonth) {
      // Held to 4.5:1 on the hover fill as well as the surface.
      fg = colors.foregroundMutedOnTint;
    } else if (isToday) {
      fg = colors.primaryText;
    } else {
      fg = colors.foregroundSecondary;
    }

    // The theme's small corner, up to a circle.
    final radius = math.min(context.radii.radiusSmall, size / 2);
    final band = inRange && !(isStart && isEnd)
        ? (preview ? colors.primaryFaint : colors.primarySubtle)
        : null;
    // Half a band on each side, toward an interior neighbour, so the range
    // reads as one bar under the endpoint fills; rounded where a week row
    // ends it, and left out beside an endpoint's fill there, whose own
    // corners end the row.
    Widget half({required bool on, required bool rowEnd, required bool end}) {
      final corner = Radius.circular(rowEnd ? radius : 0);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: on && !(rowEnd && filled) ? band : null,
          borderRadius: end
              ? BorderRadiusDirectional.horizontal(end: corner)
              : BorderRadiusDirectional.horizontal(start: corner),
        ),
      );
    }

    final strings = MaterialLocalizations.of(context);
    var label = names.fullDate(day);
    if (isStart && !preview) {
      label = strings.dateRangeStartDateSemanticLabel(label);
    } else if (isEnd && !preview) {
      label = strings.dateRangeEndDateSemanticLabel(label);
    }
    if (isToday) label = '$label, ${strings.currentDateLabel}';

    return Tappable.states(
      onTap: _interactive && !disabled
          ? () => _pick(DateUtils.dateOnly(day))
          : null,
      onHover: (hovered) {
        if (hovered && _pendingStart != null) setState(() => _hover = day);
      },
      focusNode: _nodes[slot],
      showFocusRing: false,
      semanticLabel: label,
      excludeSemantics: true,
      selected: selectedSingle || (inRange && !preview),
      builder: (context, states) {
        final hovered = !disabled && states.contains(WidgetState.hovered);
        Color? fill;
        if (filled) {
          // A selection mark, like a checked Check: 3:1 off the page.
          fill = hovered ? colors.controlAccentHover : colors.controlAccent;
        } else if (hovered) {
          fill = band == null
              ? colors.listHighlight
              : Color.alphaBlend(colors.hoverOverlay, band);
        }
        final face = Stack(
          alignment: Alignment.center,
          children: [
            if (band != null)
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: half(
                        on: !isStart,
                        rowEnd: slot % 7 == 0,
                        end: false,
                      ),
                    ),
                    Expanded(
                      child: half(on: !isEnd, rowEnd: slot % 7 == 6, end: true),
                    ),
                  ],
                ),
              ),
            FocusRing(
              focused: states.contains(WidgetState.focused),
              radius: radius,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(radius),
                  border: isToday && !filled
                      ? Border.all(color: colors.primaryText)
                      : null,
                ),
                child: Text(
                  names.dayNumber(day),
                  style: _dayStyle(
                    context,
                    emphasised: filled || isToday || inRange,
                  ).copyWith(color: fg),
                ),
              ),
            ),
          ],
        );
        // The band and the fill keep the day's height; the rest of the
        // cell around them still takes the tap.
        return Center(
          child: SizedBox(width: double.infinity, height: size, child: face),
        );
      },
    );
  }
}

/// The names and week layout a [Calendar] shows: `intl`'s for the locale,
/// when its date symbols are loaded, else [MaterialLocalizations]'s.
class _CalendarNames {
  final String Function(DateTime month) monthYear;
  final String Function(DateTime day) fullDate;
  final String Function(DateTime day) dayNumber;

  /// Sunday first.
  final List<String> narrowWeekdays;

  /// 0 for Sunday.
  final int firstDayOfWeek;

  const _CalendarNames({
    required this.monthYear,
    required this.fullDate,
    required this.dayNumber,
    required this.narrowWeekdays,
    required this.firstDayOfWeek,
  });

  factory _CalendarNames.of(BuildContext context, String? locale) {
    final requested =
        locale ?? Localizations.maybeLocaleOf(context)?.toString();
    final loaded = requested == null
        ? null
        : Intl.verifiedLocale(
            requested,
            DateFormat.localeExists,
            onFailure: (_) => null,
          );
    if (loaded == null) {
      final strings = MaterialLocalizations.of(context);
      return _CalendarNames(
        monthYear: strings.formatMonthYear,
        fullDate: strings.formatFullDate,
        dayNumber: (day) => strings.formatDecimal(day.day),
        narrowWeekdays: strings.narrowWeekdays,
        firstDayOfWeek: strings.firstDayOfWeekIndex,
      );
    }
    final symbols = DateFormat(null, loaded).dateSymbols;
    final formats = locale == null
        ? context.adminFormats
        : AdminFormats(loaded);
    return _CalendarNames(
      monthYear: formats.dateFormat(DateFormat.yMMMM(loaded)).format,
      fullDate: formats.dateFormat(DateFormat.yMMMMEEEEd(loaded)).format,
      dayNumber: formats.dateFormat(DateFormat.d(loaded)).format,
      narrowWeekdays: symbols.STANDALONENARROWWEEKDAYS,
      // intl counts from Monday.
      firstDayOfWeek: (symbols.FIRSTDAYOFWEEK + 1) % 7,
    );
  }
}
