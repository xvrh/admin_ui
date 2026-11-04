import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The "today" every picker here anchors its presets on, so the page renders
/// the same on any day.
final _today = DateTime(2026, 6, 12);

/// The range picker: presets + range calendar in a popover, with bounds,
/// locale, sizes, preselection and the no-presets / read-only / disabled
/// variants.
class DateRangePickerDemo extends StatelessWidget {
  @Preview(name: 'Date-range picker', wrapper: adminUiPreview)
  const DateRangePickerDemo({super.key});

  static final _initial = DateTimeRange(
    start: DateTime(2026, 6, 8),
    end: DateTime(2026, 6, 14),
  );

  @override
  Widget build(BuildContext context) {
    // The fr variant reads intl's date symbols; the bundled data loads
    // synchronously, so the returned future needs no waiting on.
    initializeDateFormatting();
    return DemoPage(
      maxWidth: 360,
      children: [
        const DemoSection('Default presets'),
        DemoVariant(
          'click a preset or paint a range on the calendar',
          LiveValue<DateTimeRange?>(
            initial: _initial,
            builder: (range, onChanged) => _framed(
              range,
              DateRangePicker(
                today: _today,
                value: range,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const DemoSection('Preset keeps popover open (experiment)'),
        DemoVariant(
          'closeOnPreset: false — pick a preset, then nudge it on the calendar',
          LiveValue<DateTimeRange?>(
            initial: _initial,
            builder: (range, onChanged) => _framed(
              range,
              DateRangePicker(
                today: _today,
                value: range,
                closeOnPreset: false,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const DemoSection('Empty + hint'),
        DemoVariant(
          'no value, custom placeholder',
          LiveValue<DateTimeRange?>(
            initial: null,
            builder: (range, onChanged) => _framed(
              range,
              DateRangePicker(
                today: _today,
                value: range,
                hint: 'Filter by date…',
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const DemoSection('Sizes'),
        for (final size in ControlSize.values)
          DemoVariant(
            'size: ControlSize.${size.name}',
            LiveValue<DateTimeRange?>(
              initial: _initial,
              builder: (range, onChanged) => DateRangePicker(
                today: _today,
                value: range,
                size: size,
                onChanged: onChanged,
              ),
            ),
          ),
        const DemoSection('No presets + bounds'),
        DemoVariant(
          'presets: const [] — calendar only; June selectable',
          LiveValue<DateTimeRange?>(
            initial: _initial,
            builder: (range, onChanged) => _framed(
              range,
              DateRangePicker(
                today: _today,
                value: range,
                presets: const [],
                min: DateTime(2026, 6, 1),
                max: DateTime(2026, 6, 30),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const DemoSection('Localized (fr)'),
        DemoVariant(
          "locale: 'fr'",
          LiveValue<DateTimeRange?>(
            initial: _initial,
            builder: (range, onChanged) => _framed(
              range,
              DateRangePicker(
                today: _today,
                value: range,
                locale: 'fr',
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const DemoSection('States'),
        DemoVariant(
          'Read-only — onChanged: null',
          DateRangePicker(today: _today, value: _initial),
        ),
        DemoVariant(
          'Disabled — FieldStateScope(enabled: false)',
          FieldStateScope(
            enabled: false,
            child: DateRangePicker(
              today: _today,
              value: _initial,
              onChanged: (_) {},
            ),
          ),
        ),
        DemoVariant(
          'Invalid — FieldStateScope(invalid: true)',
          FieldStateScope(
            invalid: true,
            child: DateRangePicker(today: _today, onChanged: (_) {}),
          ),
        ),
      ],
    );
  }

  Widget _framed(DateTimeRange? range, Widget picker) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          picker,
          const Gap(AdminSpacing.md),
          Text(
            range == null ? 'No range' : '${_days(range)} days selected',
            style: context.type.caption,
          ),
        ],
      ),
    );
  }

  /// Days in [range], both ends included — counted in UTC, where no day is
  /// 23 or 25 hours long.
  static int _days(DateTimeRange range) {
    DateTime utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);
    return utc(range.end).difference(utc(range.start)).inDays + 1;
  }
}

/// The picker pinned open, on a page of its own so the popover covers no
/// other variant: the selected preset beside the calendar, bounded to June
/// 5–30, so the presets clamp and "Last month" has no day left.
class DateRangePickerOpenDemo extends StatelessWidget {
  @Preview(name: 'Date-range picker / open', wrapper: adminUiPreview)
  const DateRangePickerOpenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();
    return DemoPage(
      maxWidth: 360,
      children: [
        const DemoSection('Open, bounded to June 5–30'),
        PinnedOpen(
          reserve: 380,
          child: LiveValue<DateTimeRange?>(
            initial: DateTimeRange(
              start: DateTime(2026, 6, 6),
              end: DateTime(2026, 6, 12),
            ),
            builder: (range, onChanged) => DateRangePicker(
              today: _today,
              value: range,
              min: DateTime(2026, 6, 5),
              max: DateTime(2026, 6, 30),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
