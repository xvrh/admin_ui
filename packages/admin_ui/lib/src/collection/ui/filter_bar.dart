/// @docImport '../../common/ui/menu.dart';
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/pointer.dart';
import '../../common/text_metrics.dart';
import '../../common/ui/button.dart';
import '../../common/ui/calendar.dart';
import '../../common/ui/checkbox.dart';
import '../../common/ui/field_chrome.dart' show filterTriggerChrome;
import '../../common/ui/icon_action.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/labeled_field.dart' show FieldMessage;
import '../../common/ui/listbox.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../filter.dart';

/// One option in an [OptionsFilterField].
class FilterOption {
  final String id;
  final String label;

  /// The key of the row built for this option, to find it by in a test.
  final Key? key;

  const FilterOption(this.id, this.label, {this.key});
}

/// A filterable field the [FilterBar] can edit. [key] is the [FieldId] carried
/// into the resulting [FilterCondition].
///
/// Each kind is named for the filter it makes, and ends in `FilterField`:
/// [OptionsFilterField], [NumberRangeFilterField], [DateRangeFilterField],
/// [BoolFilterField] and [TextFilterField].
sealed class FilterField {
  final FieldId key;
  final String label;
  const FilterField(this.key, this.label);
}

/// Multi-select over a fixed option set → [OptionsFilter].
class OptionsFilterField extends FilterField {
  final List<FilterOption> options;
  const OptionsFilterField(super.key, super.label, this.options);
}

/// Min/max numeric range → [NumberRangeFilter].
class NumberRangeFilterField extends FilterField {
  const NumberRangeFilterField(super.key, super.label);
}

/// From/to date range → [DateRangeFilter].
class DateRangeFilterField extends FilterField {
  const DateRangeFilterField(super.key, super.label);
}

/// A yes/no choice → [BoolFilter]. [yes] and [no] name the two choices;
/// by default "Yes" and "No" in the app's language.
class BoolFilterField extends FilterField {
  final String? yes;
  final String? no;
  const BoolFilterField(super.key, super.label, {this.yes, this.no});

  String _yes(BuildContext context) => yes ?? context.adminL10n.collection.yes;

  String _no(BuildContext context) => no ?? context.adminL10n.collection.no;
}

/// Free-text contains → [TextFilter].
class TextFilterField extends FilterField {
  const TextFilterField(super.key, super.label);
}

/// A row of filter controls — one button per [fields] entry that opens its
/// editor in a popover, showing a summary + clear when active, plus a trailing
/// "Clear all". Controlled: renders [active] and reports edits via [onChanged].
///
/// Summaries follow the app's locale: numbers in its notation, dates as
/// "Jan 5, 2026" ([DateFormat.yMMMd]), a search term in its quotes.
class FilterBar extends StatelessWidget {
  final List<FilterField> fields;
  final List<FilterCondition> active;
  final ValueChanged<List<FilterCondition>> onChanged;

  const FilterBar({
    super.key,
    required this.fields,
    required this.active,
    required this.onChanged,
  });

  FilterCondition? _conditionFor(FieldId key) =>
      active.where((c) => c.field == key).firstOrNull;

  void _set(FieldId key, FilterCondition? condition) {
    final next = active.where((c) => c.field != key).toList();
    if (condition != null && condition.isActive) next.add(condition);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final anyActive = active.any((c) => c.isActive);
    return Wrap(
      spacing: AdminSpacing.sm,
      runSpacing: AdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final f in fields)
          _FieldButton(
            field: f,
            condition: _conditionFor(f.key),
            onChanged: (c) => _set(f.key, c),
          ),
        if (anyActive) _ClearAll(onTap: () => onChanged(const [])),
      ],
    );
  }
}

class _FieldButton extends StatelessWidget {
  final FilterField field;
  final FilterCondition? condition;
  final ValueChanged<FilterCondition?> onChanged;

  const _FieldButton({
    required this.field,
    required this.condition,
    required this.onChanged,
  });

  String? _summary(BuildContext context) {
    final c = condition;
    if (c == null || !c.isActive) return null;
    final strings = context.adminL10n.collection;
    final formats = context.adminFormats;
    String? number(num? v) => v == null ? null : formats.decimal(v);
    String? date(DateTime? d) => d == null ? null : _formatDate(context, d);
    return switch (c) {
      OptionsFilter(:final selected) => strings.optionsSummary([
        for (final o in (field as OptionsFilterField).options)
          if (selected.contains(o.id)) o.label,
      ]),
      NumberRangeFilter(:final min, :final max) => strings.numberRange(
        number(min),
        number(max),
      ),
      DateRangeFilter(:final from, :final to) => strings.dateRange(
        date(from),
        date(to),
      ),
      BoolFilter(:final value) =>
        value
            ? (field as BoolFilterField)._yes(context)
            : (field as BoolFilterField)._no(context),
      TextFilter(:final value) => strings.quoted(value),
    };
  }

  @override
  Widget build(BuildContext context) {
    final active = condition?.isActive ?? false;
    final summary = _summary(context);
    return Popover(
      side: PopoverSide.bottom,
      anchor: (context, c) => _pill(context, c, active, summary),
      content: (context, c) {
        // The choice lists are listboxes on their own surface; the other
        // editors are forms on a popover's.
        Widget form(Widget child) => PopoverMenuSurface(
          width: field is DateRangeFilterField ? 300 : null,
          minWidth: 220,
          maxWidth: 280,
          maxHeight: field is DateRangeFilterField
              ? (coarsePointerByDefault ? 488 : 440)
              : 360,
          child: child,
        );
        return switch (field) {
          OptionsFilterField f => _OptionsEditor(
            field: f,
            anchorWidth: c.anchorWidth,
            selected: condition is OptionsFilter
                ? (condition as OptionsFilter).selected
                : const {},
            onChanged: (sel) =>
                onChanged(OptionsFilter(field.key, sel, label: field.label)),
          ),
          BoolFilterField f => _BoolEditor(
            field: f,
            anchorWidth: c.anchorWidth,
            value: condition is BoolFilter
                ? (condition as BoolFilter).value
                : null,
            onChanged: (v) =>
                onChanged(BoolFilter(field.key, v, label: field.label)),
          ),
          NumberRangeFilterField _ => form(
            _RangeEditor(
              initial: condition is NumberRangeFilter
                  ? condition as NumberRangeFilter
                  : null,
              onApply: (min, max) {
                onChanged(
                  NumberRangeFilter(
                    field.key,
                    min: min,
                    max: max,
                    label: field.label,
                  ),
                );
                c.close();
              },
            ),
          ),
          DateRangeFilterField _ => form(
            _DateRangeEditor(
              initial: condition is DateRangeFilter
                  ? condition as DateRangeFilter
                  : null,
              onApply: (from, to) {
                onChanged(
                  DateRangeFilter(
                    field.key,
                    from: from,
                    to: to,
                    label: field.label,
                  ),
                );
                c.close();
              },
            ),
          ),
          TextFilterField _ => form(
            _TextEditor(
              initial: condition is TextFilter
                  ? (condition as TextFilter).value
                  : '',
              onApply: (v) {
                onChanged(
                  v.isEmpty
                      ? null
                      : TextFilter(field.key, v, label: field.label),
                );
                c.close();
              },
            ),
          ),
        };
      },
    );
  }

  Widget _pill(
    BuildContext context,
    PopoverController c,
    bool active,
    String? summary,
  ) {
    final tokens = context.adminTokens;
    final colors = tokens.palette;
    final strings = context.adminL10n.collection;
    final radius = BorderRadius.circular(tokens.radii.radiusField);
    final clearable = active && summary != null;
    // The kit's padding for a medium control, half its height less 4, at
    // both ends: the trailing glyph (chevron or ×) inset like the leading
    // text.
    final padX = context.sizes.medium / 2 - 4;
    final glyph = context.iconSizes.md;
    const glyphGap = AdminSpacing.xs;
    final control = context.stroke.control;
    final slot = IconActionSize.inline;
    final hovered = Color.alphaBlend(colors.hoverOverlay, colors.primarySubtle);
    final pressed = Color.alphaBlend(
      colors.pressedOverlay,
      colors.primarySubtle,
    );
    // Readable on the active fill in every state it takes.
    final activeText = colors.readableOn(
      colors.primaryText,
      surfaces: [colors.primarySubtle, hovered, pressed],
    );
    final body = context.type.body;
    // The clear × is its own action, laid over the pill's end rather than
    // nested in the trigger, so each is one Tab stop.
    final pill = Tappable.states(
      onTap: c.toggle,
      expanded: c.isOpen,
      focusRadius: tokens.radii.radiusField,
      semanticLabel: clearable
          ? strings.filterValue(field.label, summary)
          : field.label,
      excludeSemantics: true,
      builder: (context, states) {
        // Idle, a field's box, as a select's: it lines up with the search
        // box beside it in a toolbar.
        final chrome = filterTriggerChrome(tokens, states, active: active);
        final edges = chrome.border;
        // The decoration pads by its edges; the content sits inside a
        // control-wide one, whichever edges the anatomy draws.
        return Container(
          // Taller by as much as the text grows at a large text size.
          height: context.sizes.medium + textGrowthOf(context, body),
          padding: EdgeInsetsDirectional.fromSTEB(
            padX - edges.left,
            control - edges.top,
            padX - edges.right,
            control - edges.bottom,
          ).clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity),
          decoration: chrome.decoration(radius),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                field.label,
                maxLines: 1,
                style: context.type
                    .weighted(body, FontWeight.w500)
                    .copyWith(
                      color: active ? activeText : colors.foregroundSecondary,
                    ),
              ),
              if (clearable) ...[
                Text(
                  strings.valueSeparator,
                  style: body.copyWith(color: activeText),
                ),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      summary,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: context.type
                          .weighted(body, FontWeight.w600)
                          .copyWith(color: activeText),
                    ),
                  ),
                ),
              ],
              const Gap(glyphGap),
              // The × lands over this slot when the filter is set.
              if (clearable)
                SizedBox(width: glyph)
              else
                Icon(
                  Icons.expand_more,
                  size: glyph,
                  color: active ? activeText : colors.foregroundMuted,
                ),
            ],
          ),
        );
      },
    );
    if (!clearable) return pill;
    return Stack(
      children: [
        pill,
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: padX - (slot.box - glyph) / 2,
          width: slot.box,
          child: Center(
            child: IconAction(
              Icons.close,
              label: strings.clearFilter(field.label),
              size: slot,
              color: activeText,
              onPressed: () => onChanged(null),
            ),
          ),
        ),
      ],
    );
  }
}

/// A checkbox drawn in a listbox row, which takes the tap, the highlight and
/// the announcement for it.
Widget _drawnCheck(bool checked) => IgnorePointer(
  child: ExcludeFocus(
    child: ExcludeSemantics(child: Check(value: checked, readOnly: true)),
  ),
);

class _OptionsEditor extends StatefulWidget {
  final OptionsFilterField field;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// The pill's width, which the list is at least as wide as.
  final double? anchorWidth;

  const _OptionsEditor({
    required this.field,
    required this.selected,
    required this.onChanged,
    required this.anchorWidth,
  });

  @override
  State<_OptionsEditor> createState() => _OptionsEditorState();
}

/// A multi-select list: arrows move the highlight, Space or Enter checks the
/// highlighted option, and the list stays open.
class _OptionsEditorState extends State<_OptionsEditor> {
  final _listbox = ListboxController();

  List<FilterOption> get _options => widget.field.options;

  int? get _firstChecked {
    final i = _options.indexWhere((o) => widget.selected.contains(o.id));
    return i < 0 ? null : i;
  }

  @override
  void initState() {
    super.initState();
    _listbox.reset(
      _options.length,
      selected: _firstChecked,
      labelOf: (i) => _options[i].label,
    );
  }

  @override
  void didUpdateWidget(_OptionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listbox.update(
      _options.length,
      selected: _firstChecked,
      labelOf: (i) => _options[i].label,
    );
  }

  @override
  void dispose() {
    _listbox.dispose();
    super.dispose();
  }

  void _toggle(FilterOption option) {
    final next = {...widget.selected};
    next.contains(option.id) ? next.remove(option.id) : next.add(option.id);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return ListboxMenu(
      controller: _listbox,
      anchorWidth: widget.anchorWidth,
      itemCount: _options.length,
      closeOnSelect: false,
      onSelect: (i) => _toggle(_options[i]),
      semanticLabel: widget.field.label,
      itemBuilder: (context, i) {
        final option = _options[i];
        final checked = widget.selected.contains(option.id);
        return ListboxOption(
          key: option.key,
          controller: _listbox,
          index: i,
          label: option.label,
          checkbox: true,
          selected: checked,
          leading: _drawnCheck(checked),
          onTap: () => _toggle(option),
        );
      },
    );
  }
}

class _RangeEditor extends StatefulWidget {
  final NumberRangeFilter? initial;
  final void Function(num? min, num? max) onApply;

  const _RangeEditor({required this.initial, required this.onApply});

  @override
  State<_RangeEditor> createState() => _RangeEditorState();
}

/// Reads and writes its bounds in the app's notation, so a French user
/// types "12,5". A bound that is no number there ("1,5" in English) is
/// flagged on Apply, which then applies nothing.
class _RangeEditorState extends State<_RangeEditor> {
  // First read by build, where the locale can be looked up.
  late final _min = TextEditingController(text: _format(widget.initial?.min));
  late final _max = TextEditingController(text: _format(widget.initial?.max));

  /// The bounds that were no number at the last Apply.
  var _badMin = false;
  var _badMax = false;

  String _format(num? value) => value == null
      ? ''
      : context.adminFormats.decimal(value, maxFractionDigits: 10);

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    final formats = context.adminFormats;
    final min = formats.parseDecimal(_min.text);
    final max = formats.parseDecimal(_max.text);
    final badMin = min == null && _min.text.trim().isNotEmpty;
    final badMax = max == null && _max.text.trim().isNotEmpty;
    if (badMin || badMax) {
      setState(() {
        _badMin = badMin;
        _badMax = badMax;
      });
      return;
    }
    widget.onApply(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n;
    final formats = context.adminFormats;
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _num(context, _min, strings.collection.min, _badMin),
              ),
              const Gap(AdminSpacing.sm),
              Expanded(
                child: _num(context, _max, strings.collection.max, _badMax),
              ),
            ],
          ),
          if (_badMin || _badMax) ...[
            const Gap(AdminSpacing.sm),
            FieldMessage(
              error: strings.fields.numberLike(
                formats.decimal(1234.5, maxFractionDigits: 1),
              ),
            ),
          ],
          const Gap(AdminSpacing.md),
          Button.primary(strings.apply, expand: true, onPressed: _apply),
        ],
      ),
    );
  }

  Widget _num(
    BuildContext context,
    TextEditingController c,
    String hint,
    bool invalid,
  ) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: _compactDecoration(context, hint, invalid: invalid),
  );
}

/// The field chrome of [fieldInputDecoration] at the small radius the filter
/// popovers use (no rounder than a field's), applied to every border state so
/// the theme's own radius never shows through.
InputDecoration _compactDecoration(
  BuildContext context,
  String hint, {
  bool invalid = false,
}) {
  final base = fieldInputDecoration(context, hint: hint, invalid: invalid);
  final radii = context.radii;
  final radius = BorderRadius.circular(
    math.min(radii.radiusSmall, radii.radiusField),
  );
  InputBorder? small(InputBorder? border) => border is OutlineInputBorder
      ? border.copyWith(borderRadius: radius)
      : border;
  return base.copyWith(
    border: small(base.border),
    enabledBorder: small(base.enabledBorder),
    focusedBorder: small(base.focusedBorder),
    disabledBorder: small(base.disabledBorder),
    errorBorder: small(base.errorBorder),
    focusedErrorBorder: small(base.focusedErrorBorder),
  );
}

/// [d] as an ISO 8601 date, "2026-01-05": for keys and URLs. People read
/// dates in their locale's words, as the filter chips show them.
String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// [date] as the filter chips and the date editor show it: "Jan 5, 2026" in
/// English, "5 janv. 2026" in French. A locale whose date data isn't loaded
/// (no Material delegates) falls back to intl's current one.
String _formatDate(BuildContext context, DateTime date) {
  final locale = Intl.verifiedLocale(
    context.adminFormats.locale,
    DateFormat.localeExists,
    onFailure: (_) => null,
  );
  return context.adminFormats.dateFormat(DateFormat.yMMMd(locale)).format(date);
}

class _DateRangeEditor extends StatefulWidget {
  final DateRangeFilter? initial;
  final void Function(DateTime? from, DateTime? to) onApply;
  const _DateRangeEditor({required this.initial, required this.onApply});

  @override
  State<_DateRangeEditor> createState() => _DateRangeEditorState();
}

class _DateRangeEditorState extends State<_DateRangeEditor> {
  DateTime? _from;
  DateTime? _to;
  bool _editingFrom = true;

  @override
  void initState() {
    super.initState();
    _from = widget.initial?.from;
    _to = widget.initial?.to;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n;
    // One inline calendar editing whichever bound is selected — no nested
    // popover (which would dismiss this one).
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _bound(context, strings.collection.from, _from, true),
              ),
              const Gap(AdminSpacing.sm),
              Expanded(
                child: _bound(context, strings.collection.to, _to, false),
              ),
            ],
          ),
          const Gap(AdminSpacing.sm),
          Calendar(
            value: _editingFrom ? _from : _to,
            min: _editingFrom ? null : _from,
            max: _editingFrom ? _to : null,
            // A keyboard open lands in the grid, as the other date popovers.
            autofocus: Popover.openedByKeyboard(context),
            onChanged: (d) => setState(() {
              if (_editingFrom) {
                _from = d;
                _editingFrom = false; // advance to the end date
              } else {
                _to = d;
              }
            }),
          ),
          const Gap(AdminSpacing.md),
          Button.primary(
            strings.apply,
            expand: true,
            onPressed: () => widget.onApply(_from, _to),
          ),
        ],
      ),
    );
  }

  Widget _bound(
    BuildContext context,
    String label,
    DateTime? value,
    bool isFrom,
  ) {
    final active = _editingFrom == isFrom;
    final colors = context.colors;
    final muted = active
        ? colors.foregroundMutedOnTint
        : colors.foregroundMuted;
    return Tappable(
      onTap: () => setState(() => _editingFrom = isFrom),
      selected: active,
      focusRadius: context.radii.radiusSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.md,
          vertical: AdminSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? context.colors.primarySubtle : context.colors.surface,
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
          border: Border.all(
            color: active ? context.colors.primary : context.colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: context.type.caption.copyWith(color: muted)),
            Text(
              value == null
                  ? context.adminL10n.collection.any
                  : _formatDate(context, value),
              style: context.type
                  .weighted(context.type.body, FontWeight.w600)
                  .copyWith(color: value == null ? muted : colors.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoolEditor extends StatefulWidget {
  final BoolFilterField field;
  final bool? value;
  final ValueChanged<bool> onChanged;

  /// The pill's width, which the list is at least as wide as.
  final double? anchorWidth;

  const _BoolEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    required this.anchorWidth,
  });

  @override
  State<_BoolEditor> createState() => _BoolEditorState();
}

/// A single choice between yes and no: the chosen one carries the check, and
/// choosing closes the popover.
class _BoolEditorState extends State<_BoolEditor> {
  final _listbox = ListboxController();

  static const _choices = [true, false];

  int? get _selected => switch (widget.value) {
    true => 0,
    false => 1,
    null => null,
  };

  String _label(int i) =>
      _choices[i] ? widget.field._yes(context) : widget.field._no(context);

  @override
  void initState() {
    super.initState();
    _listbox.reset(_choices.length, selected: _selected, labelOf: _label);
  }

  @override
  void didUpdateWidget(_BoolEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listbox.update(_choices.length, selected: _selected, labelOf: _label);
  }

  @override
  void dispose() {
    _listbox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListboxMenu(
      controller: _listbox,
      anchorWidth: widget.anchorWidth,
      itemCount: _choices.length,
      onSelect: (i) => widget.onChanged(_choices[i]),
      semanticLabel: widget.field.label,
      itemBuilder: (context, i) => ListboxOption(
        controller: _listbox,
        index: i,
        label: _label(i),
        selected: i == _selected,
        // Focus goes back to the pill, not to whatever held it before the
        // list opened.
        onTap: () {
          Popover.dismiss(context);
          widget.onChanged(_choices[i]);
        },
      ),
    );
  }
}

class _TextEditor extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onApply;
  const _TextEditor({required this.initial, required this.onApply});

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() => widget.onApply(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            onSubmitted: (_) => _apply(),
            decoration: _compactDecoration(
              context,
              context.adminL10n.collection.containsPlaceholder,
            ),
          ),
          const Gap(AdminSpacing.md),
          Button.primary(
            context.adminL10n.apply,
            expand: true,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}

class _ClearAll extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearAll({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Button.ghost(
      context.adminL10n.collection.clearAll,
      icon: Icons.close,
      onPressed: onTap,
    );
  }
}
