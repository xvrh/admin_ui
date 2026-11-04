import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/sections/inputs_messages.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'calendar.dart';
import 'clear_button.dart';
import 'field_chrome.dart';
import 'input_decoration.dart';
import 'popover.dart';
import 'popover_menu.dart';
import 'tappable.dart';

/// A named span shortcut shown alongside the range calendar (e.g. "Last 7
/// days"). [build] derives the span from the picker's "today" — a date at
/// midnight — so presets stay relative and a demo can pin them. The picker
/// keeps the dates of what it returns and clamps them to its bounds.
class DateRangePreset {
  final String label;
  final DateTimeRange Function(DateTime today) build;

  const DateRangePreset(this.label, this.build);

  /// The default dashboard spans, labelled in [context]'s language: today,
  /// the last 7 and 30 days, this month, last month and the year to date.
  /// Each is relative to today and ends on it, but last month. The list is
  /// unmodifiable: to add or drop a span, pass a list of your own as
  /// [DateRangePicker.presets].
  static List<DateRangePreset> defaults(BuildContext context) => _defaults(
    MaterialLocalizations.of(context).currentDateLabel,
    context.adminL10n.inputs,
  );

  static List<DateRangePreset> _defaults(String today, InputsMessages strings) {
    return List.unmodifiable([
      DateRangePreset(today, (t) => DateTimeRange(start: t, end: t)),
      DateRangePreset(
        strings.lastDays(7),
        (t) =>
            DateTimeRange(start: DateTime(t.year, t.month, t.day - 6), end: t),
      ),
      DateRangePreset(
        strings.lastDays(30),
        (t) =>
            DateTimeRange(start: DateTime(t.year, t.month, t.day - 29), end: t),
      ),
      DateRangePreset(
        strings.thisMonth,
        (t) => DateTimeRange(start: DateTime(t.year, t.month, 1), end: t),
      ),
      DateRangePreset(
        strings.lastMonth,
        (t) => DateTimeRange(
          start: DateTime(t.year, t.month - 1, 1),
          end: DateTime(t.year, t.month, 0),
        ),
      ),
      DateRangePreset(
        strings.yearToDate,
        (t) => DateTimeRange(start: DateTime(t.year, 1, 1), end: t),
      ),
    ]);
  }
}

/// A trigger showing the selected span ("Jun 1 – Jun 15") that opens a
/// popover with quick presets beside a range [Calendar]. View-pure: it drives
/// [value] / [onChanged] and owns no source of truth.
///
/// A span is two local dates at midnight, both included: [DateTimeRange.end]
/// is the span's last day, so a one-day span has `start == end`.
///
/// A null [onChanged] makes it read-only: the span stays at full contrast
/// and focusable, but nothing opens. A disabled look comes from an enclosing
/// `FieldStateScope(enabled: false)`.
///
/// Built on the range mode the [Calendar] already provides — this is the field
/// wrapper (trigger, presets, clear) around it. Presets default to the common
/// dashboard spans; pass [presets] to override (empty list hides the column).
/// Each is clamped to [min]–[max], and one with no selectable day left is
/// shown disabled.
///
/// **Keyboard.** The trigger is a Tab stop announced with its span and
/// whether the popover is open. Enter, Space, ↓ or Alt+↓ opens it with focus
/// on the calendar's day (see [Calendar] for the grid's keys). The presets
/// before it are one Tab stop: ↑/↓, Home and End move through them and Enter
/// or Space picks one. Escape closes the popover and returns focus to the
/// trigger, as does a pick that closes it.
class DateRangePicker extends StatefulWidget {
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?>? onChanged;

  /// Selectable bounds, both included; days outside are shown disabled in the
  /// calendar, and presets are clamped to them.
  final DateTime? min;
  final DateTime? max;

  /// The day marked as today and the anchor the relative presets are built
  /// from; defaults to the current date. Pass a fixed day where the render
  /// must not depend on the clock, as a demo or a test does.
  final DateTime? today;

  /// Overrides the locale of the span and the calendar's names (e.g. `'fr'`);
  /// null follows the ambient locale.
  final String? locale;

  /// Offer a clear (×) affordance when a span is set.
  final bool clearable;

  /// The trigger's text while no span is set; the localized "Select range"
  /// when null.
  final String? hint;

  /// The trigger's height, from the theme's control sizes.
  final ControlSize size;

  /// Quick-span shortcuts; null uses [DateRangePreset.defaults], an empty
  /// list hides them.
  final List<DateRangePreset>? presets;

  /// Whether tapping a preset dismisses the popover. False keeps it open so the
  /// preset can be nudged on the calendar (the picked tile stays highlighted).
  final bool closeOnPreset;

  const DateRangePicker({
    super.key,
    this.value,
    this.onChanged,
    this.min,
    this.max,
    this.today,
    this.locale,
    this.clearable = true,
    this.hint,
    this.size = ControlSize.medium,
    this.presets,
    this.closeOnPreset = true,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  /// Around the trigger, to hand focus back to it when a pick closes the
  /// popover from inside.
  final _trigger = FocusNode(
    debugLabel: 'DateRangePicker trigger',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final _panel = FocusNode(
    debugLabel: 'DateRangePicker panel',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _trigger.dispose();
    _panel.dispose();
    super.dispose();
  }

  DateTime get _anchor => DateUtils.dateOnly(widget.today ?? DateTime.now());

  String? _localeFor(BuildContext context) =>
      widget.locale ?? Localizations.maybeLocaleOf(context)?.toString();

  static bool _sameDay(DateTime a, DateTime b) => DateUtils.isSameDay(a, b);

  @override
  Widget build(BuildContext context) {
    return Popover(
      side: PopoverSide.bottom,
      align: PopoverAlign.start,
      closeOnFocusOut: true,
      anchor: (context, controller) => _triggerFor(context, controller),
      content: (context, controller) => _panelFor(context, controller),
    );
  }

  String _label(BuildContext context, bool readOnly) {
    final v = widget.value;
    if (v == null) {
      return widget.hint ??
          (readOnly
              ? '—'
              : MaterialLocalizations.of(context).dateRangePickerHelpText);
    }
    final locale = widget.locale;
    final formats = locale == null
        ? context.adminFormats
        : AdminFormats(locale);
    final fmt = formats.dateFormat(DateFormat.MMMd(_localeFor(context)));
    if (_sameDay(v.start, v.end)) return fmt.format(v.start);
    return context.adminL10n.inputs.dateSpan(
      fmt.format(v.start),
      fmt.format(v.end),
    );
  }

  void _pick(PopoverController controller, DateTimeRange range, bool close) {
    widget.onChanged?.call(range);
    if (!close) return;
    final refocus = _panel.hasFocus;
    controller.close();
    if (refocus) _trigger.traversalDescendants.firstOrNull?.requestFocus();
  }

  Widget _triggerFor(BuildContext context, PopoverController controller) {
    final v = widget.value;
    final readOnly = widget.onChanged == null;
    return Focus(
      focusNode: _trigger,
      includeSemantics: false,
      child: FieldTrigger(
        controller: controller,
        readOnly: readOnly,
        size: widget.size,
        chevron: true,
        // Read ahead of the span, which is the child's own text; with no span
        // the hint alone says what this is.
        semanticLabel: v == null ? null : context.adminL10n.inputs.dateRange,
        trailing: widget.clearable && v != null
            ? ClearButton(
                onPressed: () => widget.onChanged?.call(null),
                label: context.adminL10n.inputs.clearDates,
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
                  Icons.date_range_outlined,
                  size: sizes.fieldIcon,
                  color: FieldStateScope.of(context).iconColor(context.colors),
                ),
                SizedBox(width: sizes.fieldIconGap),
                Expanded(
                  child: Text(
                    _label(context, readOnly),
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
      ),
    );
  }

  /// [preset] as dates, clamped to the bounds; null when no day of it is
  /// selectable.
  DateTimeRange? _resolve(DateRangePreset preset, DateTime anchor) {
    final span = preset.build(anchor);
    var start = DateUtils.dateOnly(span.start);
    var end = DateUtils.dateOnly(span.end);
    final min = widget.min, max = widget.max;
    if (min != null && start.isBefore(DateUtils.dateOnly(min))) {
      start = DateUtils.dateOnly(min);
    }
    if (max != null && end.isAfter(DateUtils.dateOnly(max))) {
      end = DateUtils.dateOnly(max);
    }
    if (end.isBefore(start)) return null;
    return DateTimeRange(start: start, end: end);
  }

  bool _matches(DateTimeRange r) {
    final v = widget.value;
    return v != null && _sameDay(v.start, r.start) && _sameDay(v.end, r.end);
  }

  Widget _panelFor(BuildContext context, PopoverController controller) {
    final anchor = _anchor;
    final presets = widget.presets ?? DateRangePreset.defaults(context);
    final spans = [for (final p in presets) _resolve(p, anchor)];
    final hasPresets = presets.isNotEmpty;

    final calendarWidth = _calendarWidth(context);
    final divider = context.stroke.hairline;
    final calendar = Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: SizedBox(
        width: calendarWidth,
        child: Calendar(
          mode: CalendarMode.range,
          range: widget.value,
          min: widget.min,
          max: widget.max,
          today: anchor,
          locale: widget.locale,
          autofocus: Popover.openedByKeyboard(context),
          onRangeChanged: (r) => _pick(controller, r, true),
        ),
      ),
    );

    // One traversal group, so Tab walks the presets and then the calendar
    // wherever the popover sits over the page.
    return FocusTraversalGroup(
      child: Focus(
        focusNode: _panel,
        includeSemantics: false,
        child: PopoverMenuSurface(
          width:
              calendarWidth +
              2 * AdminSpacing.lg +
              (hasPresets ? _presetsWidth + divider : 0),
          // As tall as the calendar, with the preset column and the divider
          // stretched to it, rather than to the surface's height cap; past
          // the cap, as under a large text size, it scrolls.
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPresets) ...[
                    FocusTraversalGroup(
                      child: SizedBox(
                        width: _presetsWidth,
                        child: _PresetList(
                          labels: [for (final p in presets) p.label],
                          enabled: [for (final s in spans) s != null],
                          selected: spans.indexWhere(
                            (s) => s != null && _matches(s),
                          ),
                          onChanged: (i) => _pick(
                            controller,
                            spans[i]!,
                            widget.closeOnPreset,
                          ),
                        ),
                      ),
                    ),
                    VerticalDivider(
                      width: divider,
                      thickness: divider,
                      color: context.colors.border,
                    ),
                  ],
                  FocusTraversalGroup(child: calendar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The calendar's width: seven 40px day columns, each wider by as much as a
/// day number grows at the platform's text size, so a large text scale
/// widens the days rather than cramping them.
double _calendarWidth(BuildContext context) =>
    7 * (40 + textGrowthOf(context, context.type.bodySmall));

/// The preset column's width: room for the default presets' labels in each
/// shipped language.
const _presetsWidth = 132.0;

/// The preset column: one Tab stop, on the selected preset or the first
/// enabled one; ↑/↓, Home and End move between the enabled presets.
class _PresetList extends StatefulWidget {
  final List<String> labels;

  /// Per preset, whether any of its span is selectable.
  final List<bool> enabled;

  /// Index of the preset matching the value, or -1.
  final int selected;
  final ValueChanged<int> onChanged;

  const _PresetList({
    required this.labels,
    required this.enabled,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_PresetList> createState() => _PresetListState();
}

class _PresetListState extends State<_PresetList> {
  late List<FocusNode> _nodes;

  /// The preset holding the column's single Tab stop, or -1 when none is
  /// enabled.
  late int _stop;

  @override
  void initState() {
    super.initState();
    _nodes = _nodesFor(widget.labels.length);
    _stop = _defaultStop();
    _syncStops();
  }

  @override
  void didUpdateWidget(_PresetList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.labels.length != _nodes.length) {
      final old = _nodes;
      _nodes = _nodesFor(widget.labels.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in old) {
          node.dispose();
        }
      });
    }
    if (widget.selected >= 0 && widget.selected != oldWidget.selected) {
      _stop = widget.selected;
    }
    if (!_enabledAt(_stop)) _stop = _defaultStop();
    _syncStops();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  static List<FocusNode> _nodesFor(int count) => [
    for (var i = 0; i < count; i++) FocusNode(debugLabel: 'Preset $i'),
  ];

  bool _enabledAt(int i) =>
      i >= 0 && i < widget.enabled.length && widget.enabled[i];

  int _defaultStop() => _enabledAt(widget.selected)
      ? widget.selected
      : widget.enabled.indexOf(true);

  void _syncStops() {
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != _stop;
    }
  }

  void _focus(int index) {
    setState(() => _stop = index);
    _syncStops();
    _nodes[index].requestFocus();
  }

  /// The nearest enabled preset from [from] in [step]'s direction, or null.
  int? _next(int from, int step) {
    for (var i = from + step; i >= 0 && i < _nodes.length; i += step) {
      if (_enabledAt(i)) return i;
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final at = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (at < 0) return KeyEventResult.ignored;
    final int? next;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        next = _next(at, 1) ?? at;
      case LogicalKeyboardKey.arrowUp:
        next = _next(at, -1) ?? at;
      case LogicalKeyboardKey.home:
        next = _next(-1, 1) ?? at;
      case LogicalKeyboardKey.end:
        next = _next(_nodes.length, -1) ?? at;
      default:
        return KeyEventResult.ignored;
    }
    if (next != at) _focus(next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _onKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              _PresetTile(
                label: widget.labels[i],
                selected: i == widget.selected,
                focusNode: _nodes[i],
                onTap: widget.enabled[i]
                    ? () {
                        setState(() => _stop = i);
                        _syncStops();
                        widget.onChanged(i);
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final bool selected;
  final FocusNode focusNode;

  /// Null for a preset with no selectable day.
  final VoidCallback? onTap;

  const _PresetTile({
    required this.label,
    required this.selected,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = context.radii.radiusSmall;
    final colors = context.colors;
    final enabled = onTap != null;
    return Tappable.states(
      onTap: onTap,
      focusNode: focusNode,
      selected: selected,
      focusRadius: radius,
      builder: (context, states) => Container(
        decoration: BoxDecoration(
          color: selected
              ? colors.primarySubtle
              : enabled && states.contains(WidgetState.hovered)
              ? colors.listHighlight
              : null,
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.md,
          vertical: AdminSpacing.md,
        ),
        child: Text(
          label,
          style: context.type
              .weighted(
                context.type.bodySmall,
                selected ? FontWeight.w600 : FontWeight.w500,
              )
              .copyWith(
                color: !enabled
                    ? colors.foregroundSubtle
                    : selected
                    ? colors.primaryText
                    : colors.foregroundSecondary,
              ),
        ),
      ),
    );
  }
}
