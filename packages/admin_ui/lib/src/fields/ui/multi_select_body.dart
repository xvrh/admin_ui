import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/checkbox.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/listbox.dart';
import '../../common/ui/popover.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';
import 'select_body.dart';

export 'select_body.dart' show SelectOption;

/// How the multi-choice control renders.
enum MultiSelectAppearance {
  /// A box of removable tokens that opens a popover checklist. The default —
  /// scales to long lists and is the only one that hosts [MultiSelectBody.creatable].
  tokens,

  /// A vertical list of checkboxes, room for a description line each.
  checklist,

  /// A row of toggle pills — for a few prominent choices (2–5).
  segmented,
}

/// The bare multi-choice control — no label or capability chrome — so the same
/// body sits inside a [FieldShell] (a `Set<String>`/enum set) or one lane of a
/// translatable field. A `Set` of enum values is just this with [options] from
/// `MyEnum.values`.
///
/// A null [onChanged] shows the values read-only: full contrast, no chevron
/// or remove buttons, nothing opens. A disabled [FieldStateScope] disables
/// it, and an invalid one draws the tokens box's error outline. With
/// [creatable] the [MultiSelectAppearance.tokens] appearance accepts values
/// typed into its filter, turning it into a free-form tags field.
///
/// The tokens box keeps the control height as tokens come and go, and opens
/// a checklist at least as wide as the box: Enter or Space toggles the
/// highlighted option and the list stays open; see [ListboxMenu] for the
/// other keys.
class MultiSelectBody extends StatelessWidget {
  final List<SelectOption> options;
  final Set<String> value;
  final ValueChanged<Set<String>>? onChanged;
  final MultiSelectAppearance appearance;

  /// Placeholder shown by [MultiSelectAppearance.tokens] when nothing is
  /// selected; null reads "Select…" in the app's language.
  final String? hint;

  /// Show a filter box at the top of the popover. Null auto-enables it once the
  /// list grows past [_searchThreshold]. Ignored by other appearances.
  final bool? searchable;

  /// Cap on selections. At the cap, unselected options go inert; selected ones
  /// can still be cleared.
  final int? maxItems;

  /// Accept values typed into the [MultiSelectAppearance.tokens] filter that
  /// aren't in [options], turning the field into free-form tags.
  final bool creatable;

  const MultiSelectBody({
    super.key,
    required this.options,
    this.value = const {},
    this.onChanged,
    this.appearance = MultiSelectAppearance.tokens,
    this.hint,
    this.searchable,
    this.maxItems,
    this.creatable = false,
  });

  static const _searchThreshold = 12;

  bool get _atCap => maxItems != null && value.length >= maxItems!;

  void _toggle(String code) {
    if (onChanged == null) return;
    var next = {...value};
    if (next.contains(code)) {
      next.remove(code);
    } else {
      if (_atCap) return;
      next.add(code);
    }
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    switch (appearance) {
      case MultiSelectAppearance.tokens:
        return _Tokens(
          options: options,
          value: value,
          hint: hint ?? context.adminL10n.selectPlaceholder,
          searchable: searchable ?? options.length > _searchThreshold,
          maxItems: maxItems,
          creatable: creatable,
          onChanged: onChanged,
        );
      case MultiSelectAppearance.checklist:
        return _Checklist(
          options: options,
          value: value,
          atCap: _atCap,
          onToggle: onChanged == null ? null : _toggle,
        );
      case MultiSelectAppearance.segmented:
        return _Segmented(
          options: options,
          value: value,
          atCap: _atCap,
          onToggle: onChanged == null ? null : _toggle,
        );
    }
  }
}

/// Filters [options] by label and description, case-insensitively.
List<SelectOption> _filter(List<SelectOption> options, String query) {
  if (query.isEmpty) return options;
  final q = query.toLowerCase();
  return [
    for (final o in options)
      if (o.label.toLowerCase().contains(q) ||
          (o.description?.toLowerCase().contains(q) ?? false))
        o,
  ];
}

/// The padding of a pill or card option: [horizontal] at the sides, one
/// line of field text centred in the medium control height, less the extra
/// width of a selected option's thicker [border] so the content never moves.
EdgeInsets _optionPadding(
  BuildContext context, {
  required double border,
  required double horizontal,
}) {
  final type = context.type.fieldText;
  final rest = context.stroke.control;
  final line = type.fontSize! * type.height!;
  final vertical = math.max(0.0, (context.sizes.medium - 2 * rest - line) / 2);
  return EdgeInsets.symmetric(
    horizontal: horizontal - (border - rest),
    vertical: vertical - (border - rest),
  );
}

/// The [Check] of an option row that is itself the control: drawn only, with
/// no pointer, focus or semantics of its own. An option the cap has closed
/// ([enabled] false) takes the disabled box.
Widget _drawnCheck(bool checked, {required bool enabled}) => IgnorePointer(
  child: ExcludeFocus(
    child: ExcludeSemantics(
      child: Check(value: checked, readOnly: enabled),
    ),
  ),
);

class _Tokens extends StatefulWidget {
  final List<SelectOption> options;
  final Set<String> value;
  final String hint;
  final bool searchable;
  final int? maxItems;
  final bool creatable;
  final ValueChanged<Set<String>>? onChanged;

  const _Tokens({
    required this.options,
    required this.value,
    required this.hint,
    required this.searchable,
    required this.maxItems,
    required this.creatable,
    required this.onChanged,
  });

  @override
  State<_Tokens> createState() => _TokensState();
}

class _TokensState extends State<_Tokens> {
  final _listbox = ListboxController();
  final _filterController = TextEditingController();
  String _query = '';
  bool _open = false;

  bool get _atCap =>
      widget.maxItems != null && widget.value.length >= widget.maxItems!;

  @override
  void didUpdateWidget(_Tokens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open) _sync(reset: false);
  }

  @override
  void dispose() {
    _listbox.dispose();
    _filterController.dispose();
    super.dispose();
  }

  /// All options plus any created (not-in-[options]) values, so a typed tag
  /// still renders with a real label.
  SelectOption _optionFor(String code) {
    for (var o in widget.options) {
      if (o.value == code) return o;
    }
    return SelectOption(value: code, label: code);
  }

  List<SelectOption> get _items => _filter(widget.options, _query);

  bool get _canCreate {
    if (!widget.creatable || _query.trim().isEmpty) return false;
    var q = _query.trim().toLowerCase();
    var known =
        widget.options.any((o) => o.label.toLowerCase() == q) ||
        widget.value.any((v) => _optionFor(v).label.toLowerCase() == q);
    return !known;
  }

  /// The create row, when there is one, comes first.
  int get _offset => _canCreate ? 1 : 0;

  bool _inert(SelectOption o) => _atCap && !widget.value.contains(o.value);

  void _onOpenChanged(bool open) {
    _open = open;
    if (!open) return;
    _filterController.clear();
    setState(() => _query = '');
    _sync(reset: true);
  }

  void _onFilter(String query) {
    setState(() => _query = query);
    _sync(reset: true);
  }

  /// Hands the listbox the current rows: the highlight on the first checked
  /// option — or, once filtering, the first row — on [reset].
  void _sync({required bool reset}) {
    final items = _items;
    final offset = _offset;
    final checked = items.indexWhere((o) => widget.value.contains(o.value));
    final selected = checked < 0 ? null : checked + offset;
    String labelOf(int i) =>
        i < offset ? _query.trim() : items[i - offset].label;
    bool enabledOf(int i) => i < offset || !_inert(items[i - offset]);
    if (reset) {
      _listbox.reset(
        items.length + offset,
        selected: selected,
        highlight: _query.isEmpty ? null : 0,
        labelOf: labelOf,
        enabledOf: enabledOf,
      );
    } else {
      _listbox.update(
        items.length + offset,
        selected: selected,
        labelOf: labelOf,
        enabledOf: enabledOf,
      );
    }
  }

  void _emit(Set<String> next) => widget.onChanged?.call(next);

  void _toggle(String code) {
    var next = {...widget.value};
    if (next.contains(code)) {
      next.remove(code);
    } else {
      if (_atCap) return;
      next.add(code);
    }
    _emit(next);
  }

  void _create() {
    if (_atCap) return;
    _emit({...widget.value, _query.trim()});
    _filterController.clear();
    setState(() => _query = '');
    _sync(reset: true);
  }

  void _activate(int index) {
    final offset = _offset;
    if (index < offset) {
      _create();
    } else {
      _toggle(_items[index - offset].value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Popover(
      side: PopoverSide.bottom,
      align: PopoverAlign.start,
      autofocus: false,
      closeOnFocusOut: true,
      onOpenChanged: _onOpenChanged,
      anchor: _trigger,
      content: _menu,
    );
  }

  Widget _trigger(BuildContext context, PopoverController controller) {
    var selected = [for (var v in widget.value) _optionFor(v)];
    return FieldTrigger(
      controller: controller,
      readOnly: widget.onChanged == null,
      chevron: true,
      // Built under the trigger's own state, so the tokens follow it.
      child: Builder(
        builder: (context) {
          final state = FieldStateScope.of(context);
          if (selected.isEmpty) {
            return Text(
              widget.hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: fieldTextStyle(context).copyWith(
                color: state.enabled
                    ? context.colors.placeholder
                    : context.colors.foregroundSubtle,
              ),
            );
          }
          // The tokens' remove buttons stay pointer and screen-reader
          // targets only: from the keyboard the trigger is one stop, and its
          // checklist clears the same values.
          return ExcludeFocus(
            child: Wrap(
              spacing: AdminSpacing.sm,
              runSpacing: AdminSpacing.xs,
              children: [for (var o in selected) _token(context, o, state)],
            ),
          );
        },
      ),
    );
  }

  Widget _token(BuildContext context, SelectOption o, FieldState state) {
    final colors = context.colors;
    final editable = state.enabled && !state.readOnly;
    return FieldToken(
      o.label,
      leading: o.swatch != null || o.icon != null
          ? Glyph(
              option: o,
              color: state.enabled ? colors.primary : colors.foregroundSubtle,
            )
          : null,
      onRemove: editable ? () => _toggle(o.value) : null,
    );
  }

  Widget _menu(BuildContext context, PopoverController controller) {
    final items = _items;
    final offset = _offset;
    final showSearch = widget.searchable || widget.creatable;
    final l10n = context.adminL10n;
    final String? footer;
    if (_atCap) {
      footer = l10n.fields.maxSelected(widget.maxItems!);
    } else if (widget.searchable && _query.isNotEmpty) {
      footer = l10n.countOf(items.length, widget.options.length);
    } else {
      footer = null;
    }
    return ListboxMenu(
      controller: _listbox,
      anchorWidth: controller.anchorWidth,
      itemCount: items.length + offset,
      closeOnSelect: false,
      onSelect: _activate,
      onFilterChanged: showSearch ? _onFilter : null,
      filterController: _filterController,
      filterHint: widget.creatable
          ? l10n.fields.filterOrAdd
          : l10n.filterPlaceholder,
      footer: footer,
      footerIcon: _atCap ? Icons.info_outline_rounded : null,
      itemBuilder: (context, i) {
        if (i < offset) return _createRow(context);
        return _row(context, items[i - offset], i);
      },
    );
  }

  Widget _createRow(BuildContext context) {
    final colors = context.colors;
    final messages = context.adminL10n.fields;
    final label = messages.createOption(_query.trim());
    // The message places the quoted value; it is found again to embolden it.
    final quoted = messages.quoted(_query.trim());
    final at = label.indexOf(quoted);
    return ListboxOption(
      controller: _listbox,
      index: 0,
      label: label,
      leading: Icon(
        Icons.add_rounded,
        size: context.sizes.fieldIcon,
        color: colors.primaryText,
      ),
      title: Text.rich(
        TextSpan(
          children: at < 0
              ? [TextSpan(text: label)]
              : [
                  TextSpan(text: label.substring(0, at)),
                  TextSpan(
                    text: quoted,
                    style: context.type.weighted(
                      context.type.fieldText.copyWith(
                        color: colors.primaryText,
                      ),
                      FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: label.substring(at + quoted.length)),
                ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.type.fieldText.copyWith(color: colors.primaryText),
      ),
      onTap: _create,
    );
  }

  Widget _row(BuildContext context, SelectOption o, int index) {
    final colors = context.colors;
    final checked = widget.value.contains(o.value);
    final inert = _inert(o);
    final hasGlyph = o.swatch != null || o.icon != null;
    final check = _drawnCheck(checked, enabled: !inert);
    return ListboxOption(
      key: o.key,
      controller: _listbox,
      index: index,
      label: o.label,
      description: o.description,
      checkbox: true,
      selected: checked,
      enabled: !inert,
      leading: hasGlyph
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                check,
                Gap(context.sizes.fieldIconGap),
                SizedBox.square(
                  dimension: context.sizes.fieldIcon,
                  child: Center(
                    child: Glyph(
                      option: o,
                      color: inert
                          ? colors.foregroundFaint
                          : colors.foregroundSecondary,
                    ),
                  ),
                ),
              ],
            )
          : check,
      onTap: inert ? null : () => _toggle(o.value),
    );
  }
}

class _Checklist extends StatelessWidget {
  final List<SelectOption> options;
  final Set<String> value;
  final bool atCap;
  final void Function(String code)? onToggle;

  const _Checklist({
    required this.options,
    required this.value,
    required this.atCap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context).merge(readOnly: onToggle == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.md),
          _row(context, options[i], state),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, SelectOption o, FieldState state) {
    final colors = context.colors;
    final sizes = context.sizes;
    final line = context.type.fieldText;
    final selected = value.contains(o.value);
    final editable = state.enabled && !state.readOnly;
    final inert = !editable || (!selected && atCap);
    final dim = !state.enabled || (!selected && atCap);
    final border = selected
        ? context.stroke.controlStrong
        : context.stroke.control;
    return Tappable(
      key: o.key,
      onTap: inert ? null : () => onToggle!(o.value),
      focusRadius: context.radii.radius,
      checked: selected,
      child: Container(
        constraints: BoxConstraints(minHeight: sizes.medium),
        padding: _optionPadding(
          context,
          border: border,
          horizontal: sizes.fieldPaddingX,
        ),
        decoration: BoxDecoration(
          color: !state.enabled
              ? state.fillColor(colors)
              : (selected ? colors.primaryFaint : colors.surface),
          borderRadius: BorderRadius.circular(context.radii.radius),
          border: Border.all(
            color: selected && state.enabled ? colors.primary : colors.border,
            width: border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: line.fontSize! * line.height!,
              child: Center(child: _drawnCheck(selected, enabled: !dim)),
            ),
            Gap(sizes.fieldIconGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (o.swatch != null || o.icon != null) ...[
                        Glyph(
                          option: o,
                          color: dim
                              ? colors.foregroundSubtle
                              : colors.foregroundSecondary,
                        ),
                        const Gap(AdminSpacing.md),
                      ],
                      Flexible(
                        child: Text(
                          o.label,
                          style: context.type
                              .weighted(
                                line,
                                selected ? FontWeight.w600 : FontWeight.w500,
                              )
                              .copyWith(
                                color: dim
                                    ? colors.foregroundSubtle
                                    : (selected
                                          ? colors.primaryText
                                          : colors.foreground),
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (o.description != null)
                    Text(
                      o.description!,
                      style: context.type.caption.copyWith(
                        color: dim
                            ? colors.foregroundSubtle
                            : selected
                            ? colors.foregroundMutedOnTint
                            : colors.foregroundMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<SelectOption> options;
  final Set<String> value;
  final bool atCap;
  final void Function(String code)? onToggle;

  const _Segmented({
    required this.options,
    required this.value,
    required this.atCap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context).merge(readOnly: onToggle == null);
    return Wrap(
      spacing: AdminSpacing.md,
      runSpacing: AdminSpacing.md,
      children: [for (var o in options) _pill(context, o, state)],
    );
  }

  Widget _pill(BuildContext context, SelectOption o, FieldState state) {
    final colors = context.colors;
    final selected = value.contains(o.value);
    final editable = state.enabled && !state.readOnly;
    final inert = !editable || (!selected && atCap);
    final dim = !state.enabled || (!selected && atCap);
    final border = selected
        ? context.stroke.controlStrong
        : context.stroke.control;
    final fg = dim
        ? colors.foregroundSubtle
        : (selected ? colors.primaryText : colors.foregroundMuted);
    return Tappable(
      key: o.key,
      onTap: inert ? null : () => onToggle!(o.value),
      focusRadius: context.radii.radius,
      selected: selected,
      child: Container(
        constraints: BoxConstraints(minHeight: context.sizes.medium),
        padding: _optionPadding(
          context,
          border: border,
          horizontal: context.sizes.medium / 2 - 4,
        ),
        decoration: BoxDecoration(
          color: !state.enabled
              ? state.fillColor(colors)
              : (selected ? colors.primarySubtle : colors.surface),
          borderRadius: BorderRadius.circular(context.radii.radius),
          border: Border.all(
            color: selected && state.enabled ? colors.primary : colors.border,
            width: border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : Icons.add_rounded,
              size: context.sizes.fieldIcon,
              color: fg,
            ),
            const Gap(AdminSpacing.sm),
            if (o.swatch != null || o.icon != null) ...[
              Glyph(
                option: o,
                color: dim
                    ? colors.foregroundSubtle
                    : (selected
                          ? colors.primaryText
                          : colors.foregroundSecondary),
              ),
              const Gap(AdminSpacing.md),
            ],
            Text(
              o.label,
              style: context.type
                  .weighted(context.type.fieldText, FontWeight.w500)
                  .copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
