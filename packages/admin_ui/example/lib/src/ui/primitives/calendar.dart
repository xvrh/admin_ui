import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The "today" every calendar here marks, so the page renders the same on any
/// day.
final _today = DateTime(2026, 6, 12);

/// The standalone calendar: single + range selection, bounds, locale and the
/// keyboard stop.
class CalendarDemo extends StatelessWidget {
  @Preview(name: 'Calendar', wrapper: adminUiPreview)
  const CalendarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // The explicit-locale rows read intl's date symbols; the bundled data
    // loads synchronously, so the returned future needs no waiting on.
    initializeDateFormatting();
    return DemoPage(
      maxWidth: 360,
      children: [
        const DemoSection('Single day'),
        DemoVariant(
          'value + onPick — a day under the pointer',
          _framed(
            _hovered(
              LiveValue<DateTime?>(
                initial: DateTime(2026, 6, 18),
                builder: (v, onChanged) => Calendar(
                  today: _today,
                  value: v,
                  onChanged: (d) => onChanged(d),
                ),
              ),
            ),
          ),
        ),
        const DemoSection('Range'),
        DemoVariant(
          'tap start, then end — hover previews the band; a day in the band '
          'under the pointer',
          LiveValue<DateTimeRange?>(
            initial: DateTimeRange(
              start: DateTime(2026, 6, 10),
              end: DateTime(2026, 6, 21),
            ),
            builder: (range, onChanged) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _framed(
                  _hovered(
                    Calendar(
                      mode: CalendarMode.range,
                      today: _today,
                      range: range,
                      onRangeChanged: onChanged,
                    ),
                  ),
                ),
                const Gap(AdminSpacing.md),
                Text(
                  range == null
                      ? 'No range'
                      : '${_d(range.start)} → ${_d(range.end)}  ·  '
                            '${_days(range)} days',
                  style: context.type.caption,
                ),
              ],
            ),
          ),
        ),
        const DemoSection('Bounds (min / max)'),
        DemoVariant(
          'only the 10th–24th selectable',
          _framed(
            LiveValue<DateTime?>(
              initial: DateTime(2026, 6, 16),
              builder: (v, onChanged) => Calendar(
                today: _today,
                value: v,
                min: DateTime(2026, 6, 10),
                max: DateTime(2026, 6, 24),
                onChanged: (d) => onChanged(d),
              ),
            ),
          ),
        ),
        const DemoSection('Keyboard'),
        DemoVariant(
          'autofocus — the grid is one Tab stop; arrows, Home/End and '
          'Page Up/Down move it',
          KeyboardHighlight(
            child: _framed(
              LiveValue<DateTime?>(
                initial: DateTime(2026, 6, 18),
                builder: (v, onChanged) => Calendar(
                  today: _today,
                  value: v,
                  autofocus: true,
                  onChanged: (d) => onChanged(d),
                ),
              ),
            ),
          ),
        ),
        const DemoSection('Locale — names and week start'),
        for (final (code, label, rtl) in _locales)
          DemoVariant(
            "locale: '$code' — $label",
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: _framed(
                LiveValue<DateTime?>(
                  initial: DateTime(2026, 6, 18),
                  builder: (v, onChanged) => Calendar(
                    locale: code,
                    today: _today,
                    value: v,
                    onChanged: (d) => onChanged(d),
                  ),
                ),
              ),
            ),
          ),
        DemoVariant(
          'firstDayOfWeek: 1 — Monday first, whatever the locale',
          _framed(
            Calendar(
              today: _today,
              value: DateTime(2026, 6, 18),
              firstDayOfWeek: 1,
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  // (code, what it shows, right-to-left)
  static const _locales = [
    ('en_US', 'starts on Sunday', false),
    ('fr', 'starts on Monday', false),
    ('ar', 'starts on Saturday, right to left', true),
    ('he', 'starts on Sunday, right to left', true),
  ];

  static String _d(DateTime d) => DateFormat.MMMd().format(d);

  /// Days in [range], both ends included — counted in UTC, where no day is
  /// 23 or 25 hours long.
  static int _days(DateTimeRange range) {
    DateTime utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);
    return utc(range.end).difference(utc(range.start)).inDays + 1;
  }

  Widget _framed(Widget child) => Panel(
    padding: const EdgeInsets.all(AdminSpacing.lg),
    child: SizedBox(width: 290, child: child),
  );

  /// Rests the pointer on the grid's 17th day cell: a day in the middle of
  /// the month whatever day the locale starts the week on, neither today nor
  /// the value.
  Widget _hovered(Widget calendar) => PinnedHover(
    target: (widget) => widget is Tappable && widget.focusNode != null,
    skip: 16,
    child: calendar,
  );
}
