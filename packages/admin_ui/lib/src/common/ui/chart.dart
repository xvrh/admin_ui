import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show DateFormat, Intl;
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'empty_state.dart';
import 'panel.dart';
import 'skeleton.dart';

/// One named data series for [LineChart] / [BarChart]. [values] line up with the
/// chart's category labels by index. A null [color] is filled from the theme's
/// categorical ramp ([AdminPalette.chart]) in series order.
class ChartSeries {
  final String label;
  final List<double> values;
  final Color? color;

  const ChartSeries(this.label, this.values, {this.color});
}

/// One slice for a [DonutChart]. A null [color] takes the next colour of the
/// theme's categorical ramp, which says nothing about the slice: a slice with
/// a meaning of its own (a neutral "Pending", a failed share) passes its own,
/// since any ramp colour may be a red.
class ChartSlice {
  final String label;
  final double value;
  final Color? color;

  const ChartSlice(this.label, this.value, {this.color});
}

/// One named series for [LineChart.time]: readings at the instants they were
/// taken, in any order. A null [color] is filled from the theme's categorical
/// ramp ([AdminPalette.chart]) in series order, as a [ChartSeries]' is.
class ChartTimeSeries {
  final String label;
  final List<(DateTime, double)> points;
  final Color? color;

  const ChartTimeSeries(this.label, this.points, {this.color});
}

/// [n] series colours: the palette's categorical [AdminPalette.chart] ramp,
/// cycled — what every chart here gives a series or slice without its own
/// colour. Only a palette authored with an empty ramp falls back to rotating
/// the primary's hue, each step lifted to 3:1 on `surface`.
List<Color> chartSeriesColors(AdminPalette palette, int n) {
  final ramp = palette.chart;
  if (ramp.isNotEmpty) {
    return [for (var i = 0; i < n; i++) ramp[i % ramp.length]];
  }
  final base = HSLColor.fromColor(palette.primary);
  final dark = palette.brightness == Brightness.dark;
  final sat = base.saturation.clamp(0.45, 0.78);
  final light = dark ? 0.62 : 0.50;
  return [
    for (var i = 0; i < n; i++)
      palette.readableOn(
        HSLColor.fromAHSL(1, (base.hue + i * 47) % 360, sat, light).toColor(),
        surfaces: [palette.surface],
        minContrast: 3,
      ),
  ];
}

/// Each series' own colour, or the ramp's in series order.
List<Color> _resolve(List<Color?> own, AdminPalette palette) {
  final ramp = chartSeriesColors(palette, own.length);
  return [for (var i = 0; i < own.length; i++) own[i] ?? ramp[i]];
}

/// A multi-series line chart with value/category axes and an optional legend.
/// Static (no hover) by design — for trends on a dashboard, not interactive
/// exploration. [curved] smooths the line; [area] fills beneath it (single
/// series reads best filled).
///
/// This constructor spaces the points evenly, one per category label: months,
/// quarters, one value a day. Readings taken at irregular times go to
/// [LineChart.time], which places each at its instant, so two readings an
/// hour apart sit closer than two a week apart.
///
/// A category axis too crowded to name every point names every second, third
/// or further one, counted back from the last so the latest point is named;
/// the labels shown are evenly spaced. An empty label is not shown and not
/// counted.
///
/// The value axis fits the data in round steps; [minY] and [maxY] fix either
/// end instead, as for a score out of 10 that reads against 10 when no value
/// reaches it. Marks outside a fixed range are cut at the plot's edge.
///
/// Right to left, the chart mirrors: the categories (or time) run from the
/// right, and the value axis stands on the right. Values default to the app's
/// locale in compact form ('1.2K', '1,2 k' in French); [formatY] overrides
/// that.
class LineChart extends StatelessWidget {
  /// The series of a category chart; empty on a [LineChart.time].
  final List<ChartSeries> series;
  final List<String> labels;

  /// The series of a [LineChart.time]; empty on a category chart.
  final List<ChartTimeSeries> timeSeries;
  final double height;
  final bool area;

  /// Smooths the line with a monotone cubic: between two points the curve
  /// never rises above or dips below both, so it draws no peak or dip the
  /// data does not have. False joins the points with straight segments.
  final bool curved;
  final bool showDots;
  final bool showLegend;
  final int yTicks;
  final String Function(double)? formatY;

  /// Anchor the y-axis at zero rather than auto-scaling to the data range.
  /// Defaults to [area] — a filled chart reads better off a zero baseline,
  /// while a plain line auto-scales so small movements stay visible. A
  /// [minY] takes its place.
  final bool? startAtZero;

  /// The bottom of the value axis whatever the data; null fits the data.
  final double? minY;

  /// The top of the value axis whatever the data; null fits the data.
  final double? maxY;

  final bool _time;

  const LineChart({
    super.key,
    required this.series,
    required this.labels,
    this.height = 220,
    this.area = false,
    this.curved = true,
    this.showDots = false,
    this.showLegend = true,
    this.yTicks = 4,
    this.formatY,
    this.startAtZero,
    this.minY,
    this.maxY,
  }) : timeSeries = const [],
       _time = false,
       assert(minY == null || maxY == null || minY < maxY);

  /// A line chart over time: each point of [series] at its instant, on an
  /// axis running from the earliest point to the latest.
  ///
  /// The axis is ticked on the calendar, as many ticks as fit: hours,
  /// midnights, the first day of the locale's week, months, years. Each is
  /// named in the app's locale ('Mar 2', '2 mars'; a month's tick by its
  /// name, January's by its year).
  const LineChart.time({
    super.key,
    required List<ChartTimeSeries> series,
    this.height = 220,
    this.area = false,
    this.curved = true,
    this.showDots = false,
    this.showLegend = true,
    this.yTicks = 4,
    this.formatY,
    this.startAtZero,
    this.minY,
    this.maxY,
  }) : timeSeries = series,
       series = const [],
       labels = const [],
       _time = true,
       assert(minY == null || maxY == null || minY < maxY);

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final colors = _resolve([
      for (final s in series) s.color,
      for (final s in timeSeries) s.color,
    ], palette);
    final names = [
      for (final s in series) s.label,
      for (final s in timeSeries) s.label,
    ];
    var lo = double.infinity, hi = -double.infinity;
    for (final s in series) {
      for (final v in s.values) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
    DateTime? from, to;
    for (final s in timeSeries) {
      for (final (t, v) in s.points) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
        if (from == null || t.isBefore(from)) from = t;
        if (to == null || t.isAfter(to)) to = t;
      }
    }
    if (startAtZero ?? area) lo = math.min(lo, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLegend && names.length > 1) ...[
          _Legend(
            entries: [
              for (var i = 0; i < names.length; i++) (names[i], colors[i]),
            ],
          ),
          const Gap(AdminSpacing.lg),
        ],
        if (!hi.isFinite)
          SizedBox(height: height, width: double.infinity)
        else
          _AxisChart(
            height: height,
            dataMin: lo,
            dataMax: hi,
            minY: minY,
            maxY: maxY,
            yTicks: yTicks,
            formatY: formatY ?? context.adminFormats.compact,
            x: _time
                ? _TimeAxis.of(context, from!, to!)
                : _Categories(
                    labels,
                    count: series.first.values.length,
                    points: true,
                  ),
            painter: (layout) => _LineChartPainter(
              layout: layout,
              series: series,
              timeSeries: timeSeries,
              colors: colors,
              area: area,
              curved: curved,
              showDots: showDots,
              grid: palette.border,
              dotFill: palette.surface,
            ),
          ),
      ],
    );
  }
}

/// A categorical bar chart. One series → plain bars; multiple → grouped bars,
/// or [stacked] segments. Negative values hang down from the zero line (and
/// stack downward). Pairs with a [LineChart] on the same dashboard, and
/// mirrors right to left the same way.
class BarChart extends StatelessWidget {
  final List<ChartSeries> series;
  final List<String> labels;
  final double height;
  final bool stacked;
  final bool showLegend;
  final int yTicks;
  final String Function(double)? formatY;

  const BarChart({
    super.key,
    required this.series,
    required this.labels,
    this.height = 220,
    this.stacked = false,
    this.showLegend = true,
    this.yTicks = 4,
    this.formatY,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final colors = _resolve([for (final s in series) s.color], palette);
    final count = series.isEmpty ? 0 : series.first.values.length;
    var lo = 0.0, hi = 0.0;
    for (var i = 0; i < count; i++) {
      var up = 0.0, down = 0.0;
      for (final s in series) {
        final v = _valueAt(s, i);
        if (stacked) {
          if (v > 0) up += v;
          if (v < 0) down += v;
        } else {
          up = math.max(up, v);
          down = math.min(down, v);
        }
      }
      hi = math.max(hi, up);
      lo = math.min(lo, down);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLegend && series.length > 1) ...[
          _Legend(
            entries: [
              for (var i = 0; i < series.length; i++)
                (series[i].label, colors[i]),
            ],
          ),
          const Gap(AdminSpacing.lg),
        ],
        if (count == 0)
          SizedBox(height: height, width: double.infinity)
        else
          _AxisChart(
            height: height,
            dataMin: lo,
            dataMax: hi,
            yTicks: yTicks,
            formatY: formatY ?? context.adminFormats.compact,
            x: _Categories(labels, count: count, points: false),
            painter: (layout) => _BarChartPainter(
              layout: layout,
              series: series,
              colors: colors,
              stacked: stacked,
              grid: palette.border,
              radius: context.radii.radiusSmall,
            ),
          ),
      ],
    );
  }
}

double _valueAt(ChartSeries s, int i) => i < s.values.length ? s.values[i] : 0;

/// A donut (ring) chart for part-of-whole breakdowns, with an optional [center]
/// widget (a total, a percentage) and a legend listing each slice. For a single
/// progress value use [ProgressRing] instead.
class DonutChart extends StatelessWidget {
  final List<ChartSlice> slices;
  final double size;
  final double thickness;
  final Widget? center;
  final bool showLegend;

  const DonutChart({
    super.key,
    required this.slices,
    this.size = 160,
    this.thickness = 22,
    this.center,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final ramp = chartSeriesColors(context.colors, slices.length);
    final colors = [
      for (var i = 0; i < slices.length; i++) slices[i].color ?? ramp[i],
    ];
    final ring = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: slices,
          colors: colors,
          thickness: thickness,
          track: context.colors.border,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );

    if (!showLegend) return ring;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ring,
        const Gap(AdminSpacing.xxl),
        Flexible(
          child: _Legend(
            vertical: true,
            entries: [
              for (var i = 0; i < slices.length; i++)
                (slices[i].label, colors[i]),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single-value progress ring (0..1) — a gauge for completion, usage, or
/// quota. For a multi-slice breakdown use [DonutChart].
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double thickness;
  final Color? color;
  final Widget? center;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.thickness = 12,
    this.color,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          value: value.clamp(0.0, 1.0),
          color: color ?? context.colors.primary,
          track: context.colors.border,
          thickness: thickness,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

/// One row of a [BarList].
class BarListItem {
  final String label;
  final double value;
  final Color? color;
  final Widget? leading;

  const BarListItem(this.label, this.value, {this.color, this.leading});
}

/// A ranked horizontal-bar list — the "top N" dashboard pattern (top pages,
/// referrers, products): each row is a label on a proportional bar with its
/// value trailing. Bars scale to [max] (defaults to the largest value), grow
/// from the start edge, and take the first chart colour unless an item has
/// its own. Sorted descending unless [sort] is false; capped at [maxItems] if
/// set. Values default to the app's locale in compact form.
class BarList extends StatelessWidget {
  final List<BarListItem> items;
  final double? max;
  final bool sort;
  final int? maxItems;
  final double barHeight;
  final String Function(double)? formatValue;

  const BarList({
    super.key,
    required this.items,
    this.max,
    this.sort = true,
    this.maxItems,
    this.barHeight = 30,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final format = formatValue ?? context.adminFormats.compact;

    var rows = items;
    if (sort) {
      rows = [...items]..sort((a, b) => b.value.compareTo(a.value));
    }
    if (maxItems != null && rows.length > maxItems!) {
      rows = rows.sublist(0, maxItems!);
    }
    final top = max ?? rows.fold<double>(0, (m, i) => math.max(m, i.value));
    final scale = top <= 0 ? 1.0 : top;
    // Taller by as much as the labels grow at a large text size.
    final barHeight = this.barHeight + textGrowthOf(context, context.type.body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: (item.value / scale).clamp(0.0, 1.0),
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: (item.color ?? colors.chart.first)
                                // token-literal: a bar's wash under its value
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(
                              context.radii.radiusSmall,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: barHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AdminSpacing.md,
                          ),
                          child: Row(
                            children: [
                              ?item.leading,
                              if (item.leading != null)
                                const Gap(AdminSpacing.md),
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.type.body.copyWith(
                                    color: colors.foreground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(AdminSpacing.lg),
                Text(
                  format(item.value),
                  style: context.type.bodyStrong.copyWith(
                    color: colors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A dashboard tile that frames any chart: a [Panel] with a [title]/[subtitle]
/// header, an optional [trailing] slot (e.g. a period selector), and built-in
/// [loading] / [isEmpty] states so a chart drops in without each caller
/// re-implementing them.
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget chart;
  final bool loading;
  final bool isEmpty;

  /// Shown when [isEmpty]; the localized "No data for this period" when null.
  final String? emptyMessage;
  final double bodyHeight;

  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.trailing,
    this.loading = false,
    this.isEmpty = false,
    this.emptyMessage,
    this.bodyHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget body;
    if (loading) {
      body = SizedBox(height: bodyHeight, child: const _ChartSkeleton());
    } else if (isEmpty) {
      body = EmptyState(
        icon: Icons.bar_chart_rounded,
        title: emptyMessage ?? context.adminL10n.display.chartEmpty,
        minHeight: bodyHeight,
      );
    } else {
      body = chart;
    }

    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.type.bodyStrong.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const Gap(AdminSpacing.xxs),
                      Text(
                        subtitle!,
                        style: context.type.caption.copyWith(
                          color: colors.foregroundMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const Gap(AdminSpacing.xl),
          body,
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final f in const [0.4, 0.7, 0.5, 0.85, 0.6, 1.0, 0.75]) ...[
            Expanded(
              child: FractionallySizedBox(
                heightFactor: f,
                alignment: Alignment.bottomCenter,
                child: const Skeleton(width: double.infinity, height: 999),
              ),
            ),
            const Gap(AdminSpacing.md),
          ],
        ],
      ),
    );
  }
}

// ── shared ──────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final List<(String, Color)> entries;
  final bool vertical;

  const _Legend({required this.entries, this.vertical = false});

  /// Even, so it centres on whole pixels beside its label.
  static const _swatch = 8.0;

  @override
  Widget build(BuildContext context) {
    final style = context.type.caption.copyWith(
      color: context.colors.foregroundMuted,
    );
    // A quarter of the swatch at most, so a rounder theme keeps a square
    // swatch rather than a dot.
    final corner = math.min(context.radii.radiusSmall, _swatch / 4);
    final items = [
      for (final (label, color) in entries)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _swatch,
              height: _swatch,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(corner),
              ),
            ),
            const Gap(AdminSpacing.sm),
            Text(label, style: style),
          ],
        ),
    ];
    return vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AdminSpacing.md),
                  child: item,
                ),
            ],
          )
        : Wrap(
            spacing: AdminSpacing.xl,
            runSpacing: AdminSpacing.md,
            children: items,
          );
  }
}

/// A "nice" axis scale: rounded min/max bounding the data, divided into [ticks]
/// even steps that land on human numbers (1/2/5 × 10ⁿ). A fixed `min` or
/// `max` is kept as given, and the steps divide the range between.
class _Scale {
  final double min;
  final double max;
  final double step;

  const _Scale(this.min, this.max, this.step);

  factory _Scale.nice(
    double lo,
    double hi,
    int ticks, {
    double? min,
    double? max,
  }) {
    lo = min ?? lo;
    hi = max ?? hi;
    // A fixed end past every value: the fitted end meets it.
    if (hi < lo) {
      if (max == null) {
        hi = lo;
      } else {
        lo = hi;
      }
    }
    if (lo == hi) {
      final pad = lo == 0 ? 1.0 : lo.abs() * 0.5;
      if (max == null) {
        hi = lo + pad;
      } else {
        lo = hi - pad;
      }
    }
    final range = _niceNum(hi - lo, false);
    final step = _niceNum(range / (ticks - 1).clamp(1, 1000), true);
    return _Scale(
      min ?? (lo / step).floor() * step,
      max ?? (hi / step).ceil() * step,
      step,
    );
  }

  /// The multiples of [step] from [min] to [max].
  Iterable<double> get gridLines sync* {
    // Leeway for the rounding in min / step.
    const slack = 1e-9;
    for (
      var i = (min / step - slack).ceil();
      i * step <= max + step * slack;
      i++
    ) {
      yield i * step;
    }
  }

  static double _niceNum(double range, bool round) {
    if (range == 0) return 1;
    final exp = (math.log(range) / math.ln10).floor();
    final frac = range / math.pow(10, exp);
    final double nice;
    if (round) {
      nice = frac < 1.5 ? 1 : (frac < 3 ? 2 : (frac < 7 ? 5 : 10));
    } else {
      nice = frac <= 1 ? 1 : (frac <= 2 ? 2 : (frac <= 5 ? 5 : 10));
    }
    return nice * math.pow(10, exp);
  }
}

/// What an axis chart's x axis runs along.
sealed class _XAxis {
  const _XAxis();
}

/// [count] categories in order, named by [labels]: on points from edge to
/// edge of the plot ([points], a line) or centred in equal slots (bars).
class _Categories extends _XAxis {
  final List<String> labels;
  final int count;
  final bool points;

  const _Categories(this.labels, {required this.count, required this.points});
}

/// Time from [from] to [to], in proportion, ticked on the calendar and
/// named in the app's locale.
class _TimeAxis extends _XAxis {
  final DateTime from;
  final DateTime to;

  /// The locale's first day of the week, 0 for Sunday.
  final int firstDayOfWeek;

  final DateFormat _dayMonth;
  final DateFormat _month;
  final DateFormat _year;
  final DateFormat _hour;
  final DateFormat _minute;

  _TimeAxis._(
    this.from,
    this.to, {
    required this.firstDayOfWeek,
    required this._dayMonth,
    required this._month,
    required this._year,
    required this._hour,
    required this._minute,
  });

  /// The axis in [context]'s locale; one whose date data isn't loaded (no
  /// Material delegates) falls back to intl's current one.
  factory _TimeAxis.of(BuildContext context, DateTime from, DateTime to) {
    final formats = context.adminFormats;
    final locale = Intl.verifiedLocale(
      formats.locale,
      DateFormat.localeExists,
      onFailure: (_) => null,
    );
    return _TimeAxis._(
      from,
      to,
      // intl counts from Monday.
      firstDayOfWeek:
          (DateFormat(null, locale).dateSymbols.FIRSTDAYOFWEEK + 1) % 7,
      dayMonth: formats.dateFormat(DateFormat.MMMd(locale)),
      month: formats.dateFormat(DateFormat.MMM(locale)),
      year: formats.dateFormat(DateFormat.y(locale)),
      hour: formats.dateFormat(DateFormat.j(locale)),
      minute: formats.dateFormat(DateFormat.jm(locale)),
    );
  }

  /// The day and month of [t]: what a single instant is named by.
  String day(DateTime t) => _dayMonth.format(t);

  /// What a tick of [unit] is named: a time of day, the date at midnight; a
  /// day and month; a month, January by its year; a year.
  String label(DateTime t, _TimeUnit unit) => switch (unit) {
    _TimeUnit.minute when t.hour == 0 && t.minute == 0 => _dayMonth.format(t),
    _TimeUnit.minute => _minute.format(t),
    _TimeUnit.hour when t.hour == 0 => _dayMonth.format(t),
    _TimeUnit.hour => _hour.format(t),
    _TimeUnit.day || _TimeUnit.week => _dayMonth.format(t),
    _TimeUnit.month when t.month == 1 => _year.format(t),
    _TimeUnit.month => _month.format(t),
    _TimeUnit.year => _year.format(t),
  };

  /// The instants from [from] to [to] that start a [step] of [unit] on the
  /// calendar: whole minutes and hours of the day, midnights (every other
  /// day from the 1st, for two), the week's first day, months from January,
  /// years in multiples of [step].
  List<DateTime> ticks(_TimeUnit unit, int step) {
    DateTime at(int y, [int mo = 1, int d = 1, int h = 0, int mi = 0]) =>
        from.isUtc ? DateTime.utc(y, mo, d, h, mi) : DateTime(y, mo, d, h, mi);
    final f = from;
    var t = switch (unit) {
      _TimeUnit.minute => at(
        f.year,
        f.month,
        f.day,
        f.hour,
        f.minute - f.minute % step,
      ),
      _TimeUnit.hour => at(f.year, f.month, f.day, f.hour - f.hour % step),
      _TimeUnit.day => at(f.year, f.month, f.day),
      _TimeUnit.week => at(
        f.year,
        f.month,
        f.day - (f.weekday % 7 - firstDayOfWeek) % 7,
      ),
      _TimeUnit.month => at(f.year, f.month - (f.month - 1) % step),
      _TimeUnit.year => at(f.year - f.year % step),
    };
    DateTime next(DateTime t) {
      final n = switch (unit) {
        _TimeUnit.minute => at(t.year, t.month, t.day, t.hour, t.minute + step),
        _TimeUnit.hour => at(t.year, t.month, t.day, t.hour + step),
        _TimeUnit.day => at(t.year, t.month, t.day + 1),
        _TimeUnit.week => at(t.year, t.month, t.day + 7),
        _TimeUnit.month => at(t.year, t.month + step),
        _TimeUnit.year => at(t.year + step),
      };
      // A local hour a clock change skips can map back onto [t].
      return n.isAfter(t) ? n : t.add(Duration(microseconds: unit.micros));
    }

    return [
      for (; !t.isAfter(to); t = next(t))
        if (!t.isBefore(from) &&
            (unit != _TimeUnit.day || (t.day - 1) % step == 0))
          t,
    ];
  }
}

/// A time axis' tick sizes.
enum _TimeUnit {
  minute(Duration.microsecondsPerMinute),
  hour(Duration.microsecondsPerHour),
  day(Duration.microsecondsPerDay),
  week(Duration.microsecondsPerDay * 7),
  month(Duration.microsecondsPerDay * 30),
  year(Duration.microsecondsPerDay * 365);

  /// About how long one is, for a first guess at how many ticks a span
  /// takes.
  final int micros;

  const _TimeUnit(this.micros);
}

/// The ticks a time axis tries, finest first: a unit and how many of them
/// one tick spans.
const _timeSteps = [
  (_TimeUnit.minute, 1),
  (_TimeUnit.minute, 5),
  (_TimeUnit.minute, 15),
  (_TimeUnit.minute, 30),
  (_TimeUnit.hour, 1),
  (_TimeUnit.hour, 3),
  (_TimeUnit.hour, 6),
  (_TimeUnit.hour, 12),
  (_TimeUnit.day, 1),
  (_TimeUnit.day, 2),
  (_TimeUnit.week, 1),
  (_TimeUnit.month, 1),
  (_TimeUnit.month, 3),
  (_TimeUnit.month, 6),
  (_TimeUnit.year, 1),
  (_TimeUnit.year, 2),
  (_TimeUnit.year, 5),
  (_TimeUnit.year, 10),
  (_TimeUnit.year, 25),
  (_TimeUnit.year, 50),
  (_TimeUnit.year, 100),
];

/// The room a time axis gives each tick at least, so the finest ticks that
/// fit do not crowd the axis.
const _tickSpacing = 64.0;

/// [t] as an x of a time axis.
double _instant(DateTime t) => t.microsecondsSinceEpoch.toDouble();

/// An axis chart's body: the y grid with its value labels, the x axis'
/// labels, and whatever [painter] draws in the plot. The geometry is worked
/// out here at the laid-out width, so the axis labels are real [Text]
/// (measured, scaled and read like any other text) and the painters only
/// draw marks.
class _AxisChart extends StatelessWidget {
  final double height;
  final double dataMin;
  final double dataMax;

  /// Fixed ends of the value axis, where given.
  final double? minY;
  final double? maxY;
  final int yTicks;
  final String Function(double) formatY;
  final _XAxis x;

  final CustomPainter Function(_AxisLayout layout) painter;

  const _AxisChart({
    required this.height,
    required this.dataMin,
    required this.dataMax,
    this.minY,
    this.maxY,
    required this.yTicks,
    required this.formatY,
    required this.x,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(
      context.type.micro.copyWith(color: context.colors.foregroundMuted),
    );
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    Size measure(String text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final size = tp.size;
      tp.dispose();
      return size;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _AxisLayout.measure(
            Size(constraints.maxWidth, height),
            scale: _Scale.nice(
              dataMin,
              dataMax,
              yTicks + 1,
              min: minY,
              max: maxY,
            ),
            formatY: formatY,
            x: x,
            rtl: direction == TextDirection.rtl,
            measure: measure,
          );
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: painter(layout))),
              for (final (text, box) in [...layout.yLabels, ...layout.xLabels])
                // Physical: the boxes are laid out already mirrored.
                Positioned(
                  left: box.left,
                  top: box.top,
                  child: Text(text, style: style, maxLines: 1, softWrap: false),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Where an axis chart's pieces go at one size: the plot rect inside the axes,
/// the y scale, and the box of every axis label that is shown.
///
/// Right to left the chart is the left-to-right one mirrored, as Carbon's
/// charts are: the first category on the right, the value axis on the right.
/// [plot], [x] and [y] stay in left-to-right terms, and a painter draws
/// through [mirror]; the label boxes are laid out already mirrored.
class _AxisLayout {
  final Rect plot;
  final _Scale scale;

  /// The x values at the plot's left and right edges: category indices, or
  /// instants ([_instant]) on a time axis. Unused when [slots] is set.
  final double xMin;
  final double xMax;

  /// The number of equal slots a bar chart centres its categories in; null
  /// when they sit on points.
  final int? slots;
  final bool rtl;

  /// The chart's width, the axis [mirror] flips about.
  final double width;

  final yLabels = <(String, Rect)>[];
  final xLabels = <(String, Rect)>[];

  _AxisLayout._(
    this.plot,
    this.scale, {
    this.xMin = 0,
    this.xMax = 0,
    this.slots,
    required this.rtl,
    required this.width,
  });

  factory _AxisLayout.measure(
    Size size, {
    required _Scale scale,
    required String Function(double) formatY,
    required _XAxis x,
    required bool rtl,
    required Size Function(String) measure,
  }) {
    const gap = AdminSpacing.md;
    final ys = [for (final v in scale.gridLines) (v, formatY(v))];
    final ySizes = [for (final (_, text) in ys) measure(text)];
    final yWidth = ySizes.fold(0.0, (w, s) => math.max(w, s.width));
    final names = switch (x) {
      _Categories(:final labels, :final count) => labels.take(count).toList(),
      _TimeAxis() => const <String>[],
    };
    final hasXLabels = x is _TimeAxis || names.isNotEmpty;
    final xHeight = hasXLabels ? measure('Ag').height : 0.0;

    // A line puts its first and last points on the plot's edges, so the plot
    // is inset by half those labels' widths: each stays centred under its
    // point without leaving the chart.
    var left = yWidth + gap;
    var right = size.width;
    if (x case _Categories(:final count, points: true)
        when count > 1 && names.isNotEmpty) {
      left = math.max(left, measure(names.first).width / 2);
      if (names.length == count) right -= measure(names.last).width / 2;
    }
    // The top value label is centred on the plot's top edge.
    final top = math.max(4.0, ySizes.isEmpty ? 0.0 : ySizes.first.height / 2);
    final bottom = size.height - (hasXLabels ? xHeight + gap : 0);
    _AxisLayout frameAt(double plotRight) {
      final plot = Rect.fromLTRB(
        left,
        top,
        math.max(left, plotRight),
        math.max(top, bottom),
      );
      return switch (x) {
        _Categories(:final count, points: true) => _AxisLayout._(
          plot,
          scale,
          xMax: count - 1.0,
          rtl: rtl,
          width: size.width,
        ),
        _Categories(:final count) => _AxisLayout._(
          plot,
          scale,
          slots: count,
          rtl: rtl,
          width: size.width,
        ),
        _TimeAxis(:final from, :final to) => _AxisLayout._(
          plot,
          scale,
          xMin: _instant(from),
          xMax: _instant(to),
          rtl: rtl,
          width: size.width,
        ),
      };
    }

    // Each x label is centred under its point; [box] keeps it inside the
    // chart.
    Rect centred(_AxisLayout frame, double at, Size s) => Rect.fromLTWH(
      frame.x(at) - s.width / 2,
      frame.plot.bottom + gap,
      s.width,
      s.height,
    );
    Rect box(Rect r) => r.translate(
      r.left.clamp(0.0, math.max(0.0, size.width - r.width)) - r.left,
      0,
    );

    bool clear(List<Rect> boxes) {
      for (var i = 1; i < boxes.length; i++) {
        if (boxes[i].left < boxes[i - 1].right + gap) return false;
      }
      return true;
    }

    var frame = frameAt(right);
    final xLabels = <(String, Rect)>[];
    switch (x) {
      case _Categories():
        // Every k-th named category, counted back from the last, for the
        // smallest k whose labels clear each other: a dense axis thins out
        // evenly instead of overprinting.
        final named = [
          for (var i = 0; i < names.length; i++)
            if (names[i].isNotEmpty) i,
        ];
        final boxes = {
          for (final i in named)
            i: box(centred(frame, i.toDouble(), measure(names[i]))),
        };
        for (var k = 1; k <= named.length; k++) {
          final shown = [
            for (var j = named.length - 1; j >= 0; j -= k) named[j],
          ].reversed.toList();
          if (!clear([for (final i in shown) boxes[i]!])) continue;
          for (final i in shown) {
            xLabels.add((names[i], boxes[i]!));
          }
          break;
        }
      case _TimeAxis(:final from, :final to) when !to.isAfter(from):
        final text = x.day(from);
        xLabels.add((text, box(centred(frame, _instant(from), measure(text)))));
      case _TimeAxis(:final from, :final to):
        // The finest calendar ticks whose labels clear each other, at no
        // more than one per [_tickSpacing], each label centred on its tick.
        final span = to.difference(from).inMicroseconds;
        List<(String, Rect)> pick() {
          final most = math.max(2, frame.plot.width ~/ _tickSpacing);
          for (final (unit, step) in _timeSteps) {
            if (span / (unit.micros * step) > 2 * most) continue;
            final ticks = x.ticks(unit, step);
            if (ticks.isEmpty || ticks.length > most) continue;
            final labels = [
              for (final t in ticks)
                (
                  x.label(t, unit),
                  centred(frame, _instant(t), measure(x.label(t, unit))),
                ),
            ];
            if (clear([for (final (_, r) in labels) box(r)])) return labels;
          }
          return const [];
        }

        var ticks = pick();
        // Rather than shift the last label off its tick, the plot draws in
        // by as much as it would leave the chart.
        final over = ticks.isEmpty ? 0.0 : ticks.last.$2.right - size.width;
        if (over > 0) {
          frame = frameAt(frame.plot.right - over);
          ticks = pick();
        }
        xLabels.addAll([for (final (text, r) in ticks) (text, box(r))]);
    }
    frame.xLabels.addAll(xLabels);

    final plot = frame.plot;
    for (final (i, (v, text)) in ys.indexed) {
      final s = ySizes[i];
      frame.yLabels.add((
        text,
        Rect.fromLTWH(
          plot.left - gap - s.width,
          frame.y(v) - s.height / 2,
          s.width,
          s.height,
        ),
      ));
    }

    if (rtl) {
      Rect flip(Rect r) => Rect.fromLTRB(
        size.width - r.right,
        r.top,
        size.width - r.left,
        r.bottom,
      );
      for (final list in [frame.yLabels, frame.xLabels]) {
        for (var i = 0; i < list.length; i++) {
          list[i] = (list[i].$1, flip(list[i].$2));
        }
      }
    }
    return frame;
  }

  /// Flips [canvas] about the chart's middle when it runs right to left, so
  /// marks placed by [plot], [x] and [y] land mirrored. Call it first in
  /// `paint`; the canvas is restored after.
  void mirror(Canvas canvas) {
    if (!rtl) return;
    canvas
      ..translate(width, 0)
      ..scale(-1, 1);
  }

  /// The x of [at]: a category's centre, or an instant on a time axis.
  double x(double at) {
    if (slots case final n?) return plot.left + plot.width / n * (at + 0.5);
    if (xMax <= xMin) return plot.left + plot.width / 2;
    return plot.left + plot.width * (at - xMin) / (xMax - xMin);
  }

  double y(double v) =>
      plot.bottom - (v - scale.min) / (scale.max - scale.min) * plot.height;

  /// What the marks are placed by — equal between two layouts means the same
  /// picture for the same data.
  Object get geometry =>
      (plot, scale.min, scale.max, scale.step, xMin, xMax, slots, rtl, width);

  void paintGrid(Canvas canvas, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final v in scale.gridLines) {
      final gy = y(v);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), paint);
    }
  }
}

class _LineChartPainter extends CustomPainter {
  final _AxisLayout layout;
  final List<ChartSeries> series;
  final List<ChartTimeSeries> timeSeries;
  final List<Color> colors;
  final bool area;
  final bool curved;
  final bool showDots;
  final Color grid;
  final Color dotFill;

  _LineChartPainter({
    required this.layout,
    required this.series,
    required this.timeSeries,
    required this.colors,
    required this.area,
    required this.curved,
    required this.showDots,
    required this.grid,
    required this.dotFill,
  });

  static const _dotRadius = 3.0;
  static const _stroke = 2.0;

  /// Each series' points in the axis' terms, left to right: (category index
  /// or instant, value).
  Iterable<List<(double, double)>> get _lines sync* {
    for (final s in series) {
      yield [for (final (i, v) in s.values.indexed) (i.toDouble(), v)];
    }
    for (final s in timeSeries) {
      final points = [...s.points]..sort((a, b) => a.$1.compareTo(b.$1));
      yield [for (final (t, v) in points) (_instant(t), v)];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    layout.mirror(canvas);
    layout.paintGrid(canvas, grid);
    final plot = layout.plot;
    // A fixed value range can leave points outside it: their marks are cut
    // at the plot's edge, which a dot's ring may cross.
    canvas.clipRect(plot.inflate(_dotRadius + _stroke / 2));
    // The fill closes on the zero line (or the plot edge nearest it), so a dip
    // below zero shades up to it rather than down to the axis floor.
    final base = layout.y(0).clamp(plot.top, plot.bottom);

    for (final (s, line) in _lines.indexed) {
      final points = [
        for (final (x, v) in line) Offset(layout.x(x), layout.y(v)),
      ];
      if (points.isEmpty) continue;
      final path = curved ? _monotone(points) : _polyline(points);

      if (area) {
        final fill = Path.from(path)
          ..lineTo(points.last.dx, base)
          ..lineTo(points.first.dx, base)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // token-literal: the area under a line, fading out
                colors[s].withValues(alpha: 0.22),
                colors[s].withValues(alpha: 0.0),
              ],
            ).createShader(plot),
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = colors[s]
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

      if (showDots) {
        for (final p in points) {
          canvas.drawCircle(p, _dotRadius, Paint()..color = dotFill);
          canvas.drawCircle(
            p,
            _dotRadius,
            Paint()
              ..color = colors[s]
              ..style = PaintingStyle.stroke
              ..strokeWidth = _stroke,
          );
        }
      }
    }
  }

  Path _polyline(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  /// A monotone cubic through [p], which runs left to right (Fritsch and
  /// Carlson, 1980): each segment's tangents are shortened until the curve
  /// between two points stays between their values, and a point where the
  /// line turns gets a flat tangent, so it is the peak or the dip.
  Path _monotone(List<Offset> p) {
    final n = p.length;
    if (n < 3) return _polyline(p);
    // The secants' slopes, and the tangents: their mean, flat at a turn.
    final d = [
      for (var k = 0; k < n - 1; k++)
        p[k + 1].dx > p[k].dx
            ? (p[k + 1].dy - p[k].dy) / (p[k + 1].dx - p[k].dx)
            : 0.0,
    ];
    final m = [
      d.first,
      for (var k = 1; k < n - 1; k++)
        d[k - 1] * d[k] <= 0 ? 0.0 : (d[k - 1] + d[k]) / 2,
      d.last,
    ];
    for (var k = 0; k < n - 1; k++) {
      if (d[k] == 0) {
        m[k] = 0;
        m[k + 1] = 0;
        continue;
      }
      final a = m[k] / d[k], b = m[k + 1] / d[k];
      final r = a * a + b * b;
      if (r > 9) {
        final t = 3 / math.sqrt(r);
        m[k] = t * a * d[k];
        m[k + 1] = t * b * d[k];
      }
    }
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var k = 0; k < n - 1; k++) {
      final h = (p[k + 1].dx - p[k].dx) / 3;
      path.cubicTo(
        p[k].dx + h,
        p[k].dy + m[k] * h,
        p[k + 1].dx - h,
        p[k + 1].dy - m[k + 1] * h,
        p[k + 1].dx,
        p[k + 1].dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.layout.geometry != layout.geometry ||
      old.series != series ||
      old.timeSeries != timeSeries ||
      !listEquals(old.colors, colors) ||
      old.area != area ||
      old.curved != curved ||
      old.showDots != showDots ||
      old.grid != grid ||
      old.dotFill != dotFill;
}

class _BarChartPainter extends CustomPainter {
  final _AxisLayout layout;
  final List<ChartSeries> series;
  final List<Color> colors;
  final bool stacked;
  final Color grid;

  /// The corner a bar's far end is rounded to, at most half its width (and
  /// no more than its length): the theme's small radius, so square in a
  /// square theme.
  final double radius;

  _BarChartPainter({
    required this.layout,
    required this.series,
    required this.colors,
    required this.stacked,
    required this.grid,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    layout.mirror(canvas);
    layout.paintGrid(canvas, grid);
    final plot = layout.plot;
    final count = layout.slots!;
    final slot = plot.width / count;

    // A bar from value [from] to [to], its far end from zero rounded when
    // [cap].
    void bar(
      double left,
      double width,
      double from,
      double to,
      Color color, {
      required bool cap,
    }) {
      final up = to > from;
      final rect = Rect.fromLTRB(
        left,
        layout.y(math.max(from, to)),
        left + width,
        layout.y(math.min(from, to)),
      );
      final end = cap
          ? Radius.circular(math.min(radius, math.min(width / 2, rect.height)))
          : Radius.zero;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: up ? end : Radius.zero,
          topRight: up ? end : Radius.zero,
          bottomLeft: up ? Radius.zero : end,
          bottomRight: up ? Radius.zero : end,
        ),
        Paint()..color = color,
      );
    }

    for (var i = 0; i < count; i++) {
      final slotLeft = plot.left + slot * i;
      if (stacked) {
        final barW = slot * 0.6;
        final left = slotLeft + (slot - barW) / 2;
        // Only the outermost segment on each side of zero is rounded: the
        // last series with a value there, which need not be the last series.
        int? outerUp, outerDown;
        for (var s = 0; s < series.length; s++) {
          final v = _valueAt(series[s], i);
          if (v > 0) outerUp = s;
          if (v < 0) outerDown = s;
        }
        var up = 0.0, down = 0.0;
        for (var s = 0; s < series.length; s++) {
          final v = _valueAt(series[s], i);
          if (v > 0) {
            bar(left, barW, up, up + v, colors[s], cap: s == outerUp);
            up += v;
          } else if (v < 0) {
            bar(left, barW, down, down + v, colors[s], cap: s == outerDown);
            down += v;
          }
        }
      } else {
        final groupW = slot * 0.7;
        final barW = groupW / series.length;
        for (var s = 0; s < series.length; s++) {
          final v = _valueAt(series[s], i);
          if (!(v > 0 || v < 0)) continue;
          final left = slotLeft + (slot - groupW) / 2 + barW * s;
          bar(left, barW * 0.86, 0, v, colors[s], cap: true);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.layout.geometry != layout.geometry ||
      old.series != series ||
      !listEquals(old.colors, colors) ||
      old.stacked != stacked ||
      old.grid != grid ||
      old.radius != radius;
}

class _DonutPainter extends CustomPainter {
  final List<ChartSlice> slices;
  final List<Color> colors;
  final double thickness;
  final Color track;

  _DonutPainter({
    required this.slices,
    required this.colors,
    required this.thickness,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = (math.min(size.width, size.height) - thickness) / 2;
    final center = rect.center;
    final arc = Rect.fromCircle(center: center, radius: r);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );

    var total = 0.0;
    for (final s in slices) {
      total += s.value;
    }
    if (total <= 0) return;

    final gap = slices.length > 1 ? 0.02 : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i].value / total * (math.pi * 2);
      if (sweep <= 0) continue;
      // Slices thinner than the gap would otherwise render as a backwards arc.
      final drawSweep = sweep - gap;
      if (drawSweep > 0) {
        canvas.drawArc(
          arc,
          start + gap / 2,
          drawSweep,
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = thickness
            ..strokeCap = StrokeCap.butt,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices ||
      old.colors != colors ||
      old.thickness != thickness;
}

class _ProgressRingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double thickness;

  _ProgressRingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - thickness) / 2;
    final center = (Offset.zero & size).center;
    final arc = Rect.fromCircle(center: center, radius: r);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );
    canvas.drawArc(
      arc,
      -math.pi / 2,
      value * math.pi * 2,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.value != value || old.color != color || old.thickness != thickness;
}
