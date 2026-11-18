import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The day every grid here ends on, so the page renders the same on any day.
final _today = DateTime(2026, 6, 12);

/// Sessions a day over the 26 weeks up to [_today]: most weekdays and a few
/// weekend days, none for a fortnight in April. Drawn from a fixed seed, so
/// it is the same on every render.
final Map<DateTime, num> _sessions = () {
  var seed = 20260612;
  int next(int bound) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed % bound;
  }

  final out = <DateTime, num>{};
  for (var i = 0; i < 26 * 7; i++) {
    final day = DateTime(_today.year, _today.month, _today.day - i);
    final weekend = day.weekday >= DateTime.saturday;
    final away =
        day.isAfter(DateTime(2026, 4, 5)) &&
        day.isBefore(DateTime(2026, 4, 20));
    if (away || next(100) < (weekend ? 75 : 18)) continue;
    out[day] = 1 + next(weekend ? 3 : 9);
  }
  return out;
}();

/// The days with a session, each worth 1: used or not.
final Map<DateTime, num> _used = {for (final day in _sessions.keys) day: 1};

String _sessionCount(num n) => n == 1 ? '1 session' : '$n sessions';

/// A calendar heat grid: in a chart card, on or off, at phone width, over a
/// range, in its own colour, in other locales and from the keyboard.
class CalendarHeatGridDemo extends StatelessWidget {
  @Preview(name: 'Calendar heat grid', wrapper: adminUiPreview)
  const CalendarHeatGridDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // The locale rows read intl's date symbols; the bundled data loads
    // synchronously, so the returned future needs no waiting on.
    initializeDateFormatting();
    return DemoPage(
      maxWidth: 720,
      children: [
        const DemoSection('Sessions a day'),
        ChartCard(
          title: 'Sessions',
          subtitle: 'Last 26 weeks',
          chart: CalendarHeatGrid(
            values: _sessions,
            today: _today,
            formatValue: _sessionCount,
          ),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoSection('On or off'),
        DemoVariant(
          'levels: 1 — a day used or not, no legend',
          CalendarHeatGrid(
            values: _used,
            levels: 1,
            today: _today,
            formatValue: (v) => v > 0 ? 'Used' : 'Not used',
          ),
        ),
        const DemoSection('Narrow'),
        DemoVariant(
          'at phone width — scrolls sideways, opens on the latest week',
          SizedBox(
            width: 300,
            child: Panel(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              child: CalendarHeatGrid(
                values: _sessions,
                today: _today,
                formatValue: _sessionCount,
              ),
            ),
          ),
        ),
        const DemoSection('Range'),
        DemoVariant(
          'range: April through August — nothing after today (June 12)',
          CalendarHeatGrid.range(
            range: DateTimeRange(
              start: DateTime(2026, 4, 1),
              end: DateTime(2026, 8, 31),
            ),
            values: _sessions,
            today: _today,
            formatValue: _sessionCount,
          ),
        ),
        DemoVariant(
          'color: success, max: 4 — four sessions or more fill a day',
          CalendarHeatGrid(
            values: _sessions,
            weeks: 12,
            max: 4,
            color: context.colors.success,
            today: _today,
            formatValue: _sessionCount,
          ),
        ),
        const DemoSection('Locale — names and week start'),
        for (final (code, label, rtl) in _locales)
          DemoVariant(
            "locale: '$code' — $label",
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: CalendarHeatGrid(
                values: _sessions,
                weeks: 16,
                locale: code,
                today: _today,
              ),
            ),
          ),
        const DemoSection('Keyboard'),
        DemoVariant(
          'autofocus — one Tab stop; arrows move by day and week, Home/End to '
          'the week’s ends, and the focused day shows its tip',
          KeyboardHighlight(
            child: Padding(
              // Room for the tip above the latest day.
              padding: const EdgeInsets.only(top: AdminSpacing.xxxl),
              child: CalendarHeatGrid(
                values: _sessions,
                weeks: 12,
                today: _today,
                formatValue: _sessionCount,
                autofocus: true,
              ),
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
  ];
}
