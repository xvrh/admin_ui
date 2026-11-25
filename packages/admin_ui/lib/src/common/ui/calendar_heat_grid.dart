/// @docImport '../../theme/palette.dart';
/// @docImport 'calendar.dart';
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/date_locale.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'chart.dart';
import 'focus_ring.dart';
import 'popover.dart';
import 'tip.dart';

/// A square per day, a column per week and a row per day of the week, each
/// day filled by its value: on which days someone used something, and how
/// much.
///
/// [CalendarHeatGrid.new] shows [weeks] weeks, [today]'s the last;
/// [CalendarHeatGrid.range] the weeks of a span. Days after [today], and a
/// range's days outside it, are left blank, with no square and no tip, and a
/// range's weeks after [today] are left out.
///
/// **Values.** [values] maps a day to its value; a key's time of day is
/// ignored, and two keys on one day add up. A day with no value above zero
/// is empty: a faint square, which shows on a card and on the page alike.
/// Any other takes one of [levels] fills, by its share of [max]: [color] at
/// its lightest for the smallest share, [color] itself for the largest. For
/// days used or not, give each day used a value of 1 and set [levels] to 1.
///
/// **Labels.** Each month is named above the first week that starts in it,
/// and every second day of the week at the side; [showLegend] adds the
/// fills, from "Less" to "More", under the grid's end. The names, the dates
/// and the week's first day follow the app's locale, or an explicit
/// [locale], as a [Calendar]'s do; [firstDayOfWeek] overrides the week's
/// first day.
///
/// **Reading a day.** Hovering a day, or pressing it long, opens a [Tip]
/// with its date and its value ([formatValue]). The grid is one Tab stop,
/// the latest day; the arrows move by day and by week, Home and End to the
/// week's first and last day, and the focused day opens its tip. Each day is
/// announced as its date and value.
///
/// **Width.** Narrower than its weeks need, the grid scrolls sideways under
/// a drag, opening on the latest week, while the names of the days stay at
/// its side. Right to left, it mirrors: the weeks run from the right.
class CalendarHeatGrid extends StatefulWidget {
  /// Each day's value; see [CalendarHeatGrid].
  final Map<DateTime, num> values;

  /// How many weeks [CalendarHeatGrid.new] shows, [today]'s the last; null
  /// on a [CalendarHeatGrid.range].
  final int? weeks;

  /// The days [CalendarHeatGrid.range] shows, both ends included; null on
  /// [CalendarHeatGrid.new].
  final DateTimeRange? range;

  /// How many fills a day with a value takes, by its share of [max]; 1 for
  /// days used or not.
  final int levels;

  /// The value that takes the fullest fill, as do those above it; null takes
  /// the largest value shown.
  final num? max;

  /// The fullest fill; null takes the theme's first chart colour
  /// ([AdminPalette.chart]), as a [BarList]'s bars do.
  final Color? color;

  /// A day's value as its tip writes it and a screen reader reads it, after
  /// its date; null writes it in the locale's digits. A day without a value
  /// is given 0.
  final String Function(num value)? formatValue;

  /// Whether the fills show under the grid, from "Less" to "More"; null
  /// shows them for more than one level.
  final bool? showLegend;

  /// An `intl` locale for the names, the dates and the week's first day,
  /// e.g. `'fr'`; null follows the app's.
  final String? locale;

  /// The first row, 0 for Sunday, 1 for Monday … 6 for Saturday; null takes
  /// the locale's.
  final int? firstDayOfWeek;

  /// The last day that can be filled, the end of a [CalendarHeatGrid.new];
  /// defaults to the current date. Pass a fixed day where the render must
  /// not depend on the clock, as a demo or a test does.
  final DateTime? today;

  /// The side of a day's square; the gap between two days is a quarter of
  /// it.
  final double cellSize;

  /// Moves focus to the grid's Tab stop, the latest day, once it is first
  /// built.
  final bool autofocus;

  /// The [weeks] up to [today]'s.
  const CalendarHeatGrid({
    super.key,
    required this.values,
    int this.weeks = 26,
    this.levels = 4,
    this.max,
    this.color,
    this.formatValue,
    this.showLegend,
    this.locale,
    this.firstDayOfWeek,
    this.today,
    this.cellSize = 12,
    this.autofocus = false,
  }) : range = null,
       assert(weeks > 0),
       assert(levels > 0),
       assert(
         firstDayOfWeek == null || (firstDayOfWeek >= 0 && firstDayOfWeek < 7),
       );

  /// The weeks from [range]'s start to its end, or to [today] when that
  /// comes first.
  const CalendarHeatGrid.range({
    super.key,
    required DateTimeRange this.range,
    required this.values,
    this.levels = 4,
    this.max,
    this.color,
    this.formatValue,
    this.showLegend,
    this.locale,
    this.firstDayOfWeek,
    this.today,
    this.cellSize = 12,
    this.autofocus = false,
  }) : weeks = null,
       assert(levels > 0),
       assert(
         firstDayOfWeek == null || (firstDayOfWeek >= 0 && firstDayOfWeek < 7),
       );

  @override
  State<CalendarHeatGrid> createState() => _CalendarHeatGridState();
}

/// The share of [CalendarHeatGrid.color] the lowest level takes, over the
/// empty fill; the levels above step evenly up to all of it.
const _lightest = 0.3;

/// The rows named at the side: every second day of the week, from the
/// second, so the first and last rows stay unnamed as on a wall calendar's
/// edge.
const _namedRows = [1, 3, 5];

class _CalendarHeatGridState extends State<CalendarHeatGrid> {
  /// One node per day shown, by slot, made as the day is first built.
  final _nodes = <int, FocusNode>{};

  /// The slot holding focus, if any.
  int? _focused;

  /// The slot focus last left; the Tab stop while it is shown.
  int? _stop;

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _node(int slot) =>
      _nodes[slot] ??= FocusNode(debugLabel: 'CalendarHeatGrid day $slot');

  void _onFocusChange(int slot, bool focused, double reach) {
    setState(() {
      if (focused) {
        _focused = _stop = slot;
      } else if (_focused == slot) {
        _focused = null;
      }
    });
    if (!focused) return;
    // Scrolled into view, its ring with it, along the grid and the page.
    final box = _nodes[slot]?.context?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      box.showOnScreen(rect: (Offset.zero & box.size).inflate(reach));
    }
  }

  KeyEventResult _onKey(KeyEvent event, _Days days) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final slot = _focused;
    if (slot == null) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final row = slot % 7;
    final target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => slot - 1,
      LogicalKeyboardKey.arrowDown => slot + 1,
      LogicalKeyboardKey.arrowLeft => rtl ? slot + 7 : slot - 7,
      LogicalKeyboardKey.arrowRight => rtl ? slot - 7 : slot + 7,
      LogicalKeyboardKey.home => slot - row,
      LogicalKeyboardKey.end => slot + 6 - row,
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    final to = target.clamp(days.from, days.to);
    if (to != slot) _nodes[to]?.requestFocus();
    return KeyEventResult.handled;
  }

  _Days _days(int weekStart) {
    final today = DateUtils.dateOnly(widget.today ?? DateTime.now());
    final DateTime start, end;
    if (widget.range case final range?) {
      start = DateUtils.dateOnly(range.start);
      end = DateUtils.dateOnly(range.end);
    } else {
      final week = _weekOf(today, weekStart);
      start = DateTime(
        week.year,
        week.month,
        week.day - (widget.weeks! - 1) * 7,
      );
      end = today;
    }
    final last = end.isAfter(today) ? today : end;
    final first = _weekOf(start, weekStart);
    return _Days(
      first: first,
      columns: _between(first, last.isBefore(start) ? start : last) ~/ 7 + 1,
      from: _between(first, start),
      to: _between(first, last),
    );
  }

  /// The empty fill, then each level's.
  List<Color> _fills(BuildContext context) {
    final colors = context.colors;
    final dark = colors.brightness == Brightness.dark;
    // Faint enough to leave the lightest level apart, and translucent, so it
    // shows on a card and on the page alike.
    // token-literal: an empty day's square, in every theme and mode
    final empty = colors.foreground.withValues(alpha: dark ? 0.1 : 0.08);
    final accent = widget.color ?? chartSeriesColors(colors, 1).first;
    final levels = widget.levels;
    return [
      empty,
      for (var level = 1; level < levels; level++)
        Color.alphaBlend(
          accent.withValues(alpha: _share(level, levels)),
          empty,
        ),
      accent,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final names = _GridNames.of(context, widget.locale);
    final weekStart = widget.firstDayOfWeek ?? names.firstDayOfWeek;
    final days = _days(weekStart);
    final colors = context.colors;
    final display = context.adminL10n.display;
    final format = widget.formatValue ?? context.adminFormats.decimal;

    final values = <int, num>{};
    for (final MapEntry(:key, :value) in widget.values.entries) {
      final slot = _between(days.first, key);
      if (days.shows(slot)) values[slot] = (values[slot] ?? 0) + value;
    }
    final top = widget.max ?? values.values.fold<num>(0, math.max);
    int levelOf(num value) => value <= 0 || top <= 0
        ? 0
        : (value / top * widget.levels).ceil().clamp(1, widget.levels);

    final fills = _fills(context);
    final cell = widget.cellSize;
    final gap = cell / 4;
    final pitch = cell + gap;
    final corner = math.min(context.radii.radiusSmall, cell / 4);
    final radius = BorderRadius.circular(corner);
    final reach = math.max(0.0, FocusRing.reachOf(context));
    final labelStyle = context.type.micro.copyWith(
      color: colors.foregroundMuted,
    );
    final lineHeight = lineHeightOf(context, labelStyle);
    final gridWidth = days.columns * pitch - gap;
    final gridHeight = 7 * pitch - gap;

    final stop = _stop != null && days.shows(_stop!) ? _stop! : days.to;

    Widget square(Color fill) => DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: SizedBox.square(dimension: cell),
    );

    Widget day(int slot) {
      final value = values[slot] ?? 0;
      final message = display.statValue(
        names.date(days.dayAt(slot)),
        format(value),
      );
      return Tip(
        message: message,
        side: PopoverSide.top,
        excludeFromSemantics: true,
        child: Semantics(
          container: true,
          label: message,
          child: Focus(
            focusNode: _node(slot)..skipTraversal = slot != stop,
            autofocus: widget.autofocus && slot == stop,
            onFocusChange: (focused) => _onFocusChange(slot, focused, reach),
            child: square(fills[levelOf(value)]),
          ),
        ),
      );
    }

    final focused = _focused;
    final grid = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (_, event) => _onKey(event, days),
      child: SizedBox(
        width: gridWidth,
        height: gridHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var slot = days.from; slot <= days.to; slot++)
              PositionedDirectional(
                start: slot ~/ 7 * pitch,
                top: slot % 7 * pitch,
                child: day(slot),
              ),
            // Over the days beside it, which a ring of its own would sit
            // under.
            if (focused != null && days.shows(focused))
              PositionedDirectional(
                start: focused ~/ 7 * pitch,
                top: focused % 7 * pitch,
                width: cell,
                height: cell,
                child: FocusRing(
                  focused: true,
                  radius: corner,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );

    // Each month above the first week whose first shown day is in it; a
    // name that would run into the next one is dropped, the earlier going.
    final months = <(double, String)>[];
    var nextStart = double.infinity;
    for (var column = days.columns - 1; column >= 0; column--) {
      final slot = math.max(column * 7, days.from);
      if (slot > days.to) continue;
      final date = days.dayAt(slot);
      final previous = math.max((column - 1) * 7, days.from);
      if (column * 7 > days.from && days.dayAt(previous).month == date.month) {
        continue;
      }
      final name = names.month(date);
      final width = textWidthOf(context, name, labelStyle);
      // A month begun in the last weeks ends with the grid.
      final start = math.max(0.0, math.min(column * pitch, gridWidth - width));
      if (start + width + AdminSpacing.sm > nextStart) continue;
      months.add((start, name));
      nextStart = start;
    }
    final monthsWidth = months.fold(
      gridWidth,
      (w, m) => math.max(w, m.$1 + textWidthOf(context, m.$2, labelStyle)),
    );
    final monthRow = SizedBox(
      width: monthsWidth,
      height: lineHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (start, name) in months)
            PositionedDirectional(
              start: start,
              top: 0,
              child: Text(
                name,
                style: labelStyle,
                maxLines: 1,
                softWrap: false,
              ),
            ),
        ],
      ),
    );

    final weekdays = [
      for (final row in _namedRows) names.weekdays[(weekStart + row) % 7],
    ];
    final weekdayRow = SizedBox(
      width: weekdays.fold<double>(
        0,
        (w, name) => math.max(w, textWidthOf(context, name, labelStyle)),
      ),
      height: gridHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, row) in _namedRows.indexed)
            PositionedDirectional(
              start: 0,
              top: row * pitch + (cell - lineHeight) / 2,
              child: Text(
                weekdays[i],
                style: labelStyle,
                maxLines: 1,
                softWrap: false,
              ),
            ),
        ],
      ),
    );

    final scroller = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        dragDevices: {
          ...ScrollConfiguration.of(context).dragDevices,
          PointerDeviceKind.mouse,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Opens on the latest week, the scroll's start.
        reverse: true,
        // Room for the focus ring of a day on the edge.
        padding: EdgeInsets.all(reach),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: monthRow),
            const Gap(AdminSpacing.xs),
            grid,
          ],
        ),
      ),
    );

    final legend = widget.showLegend ?? widget.levels > 1;
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: reach + lineHeight + AdminSpacing.xs,
                  ),
                  child: weekdayRow,
                ),
              ),
              const Gap(AdminSpacing.sm),
              Flexible(child: scroller),
            ],
          ),
          if (legend)
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: reach),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(display.heatLess, style: labelStyle),
                    const Gap(AdminSpacing.xs),
                    for (final (i, fill) in fills.indexed) ...[
                      if (i > 0) Gap(gap),
                      square(fill),
                    ],
                    const Gap(AdminSpacing.xs),
                    Text(display.heatMore, style: labelStyle),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The share of the colour level [level] of [levels] takes, below the top:
/// [_lightest] for the first, evenly on toward all of it.
double _share(int level, int levels) =>
    _lightest + (1 - _lightest) * (level - 1) / (levels - 1);

/// The first day of [day]'s week, the week starting on [weekStart] (0 for
/// Sunday).
DateTime _weekOf(DateTime day, int weekStart) =>
    DateTime(day.year, day.month, day.day - (day.weekday % 7 - weekStart) % 7);

/// Whole days from [a]'s date to [b]'s, by their calendar fields: neither
/// a time of day nor a clock change counts.
int _between(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// The grid's slots: [columns] weeks of seven from [first], slot `s` the day
/// `s` days after it. The days shown are the slots [from] to [to], none when
/// [to] is under [from].
class _Days {
  final DateTime first;
  final int columns;
  final int from;
  final int to;

  const _Days({
    required this.first,
    required this.columns,
    required this.from,
    required this.to,
  });

  DateTime dayAt(int slot) =>
      DateTime(first.year, first.month, first.day + slot);

  bool shows(int slot) => slot >= from && slot <= to;
}

/// The names and week layout a [CalendarHeatGrid] shows: `intl`'s for the
/// locale, when its date symbols are loaded; else `intl`'s current
/// locale's.
class _GridNames {
  /// A month's short name, standing alone: 'Mar'.
  final String Function(DateTime day) month;

  /// A day's date, with its weekday: 'Tue, Mar 3, 2026'.
  final String Function(DateTime day) date;

  /// The days' short names, standing alone, Sunday first.
  final List<String> weekdays;

  /// 0 for Sunday.
  final int firstDayOfWeek;

  const _GridNames({
    required this.month,
    required this.date,
    required this.weekdays,
    required this.firstDayOfWeek,
  });

  factory _GridNames.of(BuildContext context, String? locale) {
    final loaded = dateLocaleOf(
      locale ?? Localizations.maybeLocaleOf(context)?.toString(),
    );
    final formats = locale == null || loaded == null
        ? context.adminFormats
        : AdminFormats(loaded);
    final symbols = DateFormat(null, loaded).dateSymbols;
    return _GridNames(
      month: DateFormat.LLL(loaded).format,
      date: formats.dateFormat(DateFormat.yMMMEd(loaded)).format,
      weekdays: symbols.STANDALONESHORTWEEKDAYS,
      // intl counts from Monday.
      firstDayOfWeek: (symbols.FIRSTDAYOFWEEK + 1) % 7,
    );
  }
}
