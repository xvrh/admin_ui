import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/listbox.dart';
import '../../common/ui/popover.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

export 'field_primitives.dart' show Tappable, CircleButton;

/// How the choice control renders.
enum SelectAppearance {
  /// A closed box that opens a popover list. The default — scales to long lists.
  dropdown,

  /// A row of pills, one per option — for a few prominent choices (2–5).
  segmented,

  /// A vertical list of radios, room for a description line each.
  radio,
}

/// One choice in a [SelectBody]. [value] is the stored code (e.g. an enum name);
/// [label] is what the editor reads. An optional [swatch] dot or leading [icon]
/// carries status colour or meaning; [description] shows under the label in the
/// [SelectAppearance.radio] and dropdown lists.
class SelectOption {
  final String value;
  final String label;
  final IconData? icon;
  final Color? swatch;
  final String? description;

  const SelectOption({
    required this.value,
    required this.label,
    this.icon,
    this.swatch,
    this.description,
  });
}

/// The bare single-choice control — no label or capability chrome — so the same
/// body sits inside a [FieldShell] (a real `String`/enum) or one lane of a
/// translatable field. A Dart enum is just a select whose [options] come from
/// `MyEnum.values`.
///
/// A null [onChanged] shows the value read-only: full contrast, no chevron,
/// nothing opens. A disabled [FieldStateScope] disables it, and an invalid
/// one draws the dropdown's error outline.
///
/// The dropdown opens a listbox at least as wide as the trigger, with the
/// selected option highlighted and scrolled into view; see [ListboxMenu] for
/// its keys. A filter box tops it on long lists ([searchable]).
class SelectBody extends StatelessWidget {
  final List<SelectOption> options;
  final String? value;
  final ValueChanged<String>? onChanged;
  final SelectAppearance appearance;

  /// Placeholder shown by [SelectAppearance.dropdown] when nothing is
  /// selected; null reads "Select…" in the app's language.
  final String? hint;

  /// Show a filter box at the top of the dropdown. Null auto-enables it once
  /// the list grows past [_searchThreshold]. Ignored by other appearances.
  final bool? searchable;

  const SelectBody({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.appearance = SelectAppearance.dropdown,
    this.hint,
    this.searchable,
  });

  static const _searchThreshold = 12;

  SelectOption? get _selected {
    for (var o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    switch (appearance) {
      case SelectAppearance.dropdown:
        return _Dropdown(
          options: options,
          selected: _selected,
          hint: hint ?? context.adminL10n.selectPlaceholder,
          searchable: searchable ?? options.length > _searchThreshold,
          onChanged: onChanged,
        );
      case SelectAppearance.segmented:
        return _Segmented(options: options, value: value, onChanged: onChanged);
      case SelectAppearance.radio:
        return _RadioList(options: options, value: value, onChanged: onChanged);
    }
  }
}

/// A leading status dot or icon, sized to sit inline with a label.
class Glyph extends StatelessWidget {
  final SelectOption option;
  final Color color;

  const Glyph({super.key, required this.option, required this.color});

  @override
  Widget build(BuildContext context) {
    if (option.icon != null) {
      return Icon(option.icon, size: context.sizes.fieldIcon, color: color);
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: option.swatch, shape: BoxShape.circle),
    );
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

class _Dropdown extends StatefulWidget {
  final List<SelectOption> options;
  final SelectOption? selected;
  final String hint;
  final bool searchable;
  final ValueChanged<String>? onChanged;

  const _Dropdown({
    required this.options,
    required this.selected,
    required this.hint,
    required this.searchable,
    required this.onChanged,
  });

  @override
  State<_Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<_Dropdown> {
  final _listbox = ListboxController();
  String _query = '';
  bool _open = false;

  List<SelectOption> get _items => _filter(widget.options, _query);

  @override
  void didUpdateWidget(_Dropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open) _sync(reset: false);
  }

  @override
  void dispose() {
    _listbox.dispose();
    super.dispose();
  }

  void _onOpenChanged(bool open) {
    _open = open;
    if (!open) return;
    setState(() => _query = '');
    _sync(reset: true);
  }

  void _onFilter(String query) {
    setState(() => _query = query);
    _sync(reset: true);
  }

  /// Hands the listbox the current options: with the highlight on the
  /// selected one — or, once filtering, the first match — on [reset].
  void _sync({required bool reset}) {
    final items = _items;
    final at = items.indexWhere((o) => o.value == widget.selected?.value);
    final selected = at < 0 ? null : at;
    String labelOf(int i) => items[i].label;
    if (reset) {
      _listbox.reset(
        items.length,
        selected: selected,
        highlight: _query.isEmpty ? null : 0,
        labelOf: labelOf,
      );
    } else {
      _listbox.update(items.length, selected: selected, labelOf: labelOf);
    }
  }

  void _choose(SelectOption option) => widget.onChanged?.call(option.value);

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
    final sel = widget.selected;
    return FieldTrigger(
      controller: controller,
      readOnly: widget.onChanged == null,
      chevron: true,
      // Built under the trigger's own state, so the text dims with it.
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          final sizes = context.sizes;
          final enabled = FieldStateScope.of(context).enabled;
          final style = fieldTextStyle(context);
          return Row(
            children: [
              if (sel != null && (sel.swatch != null || sel.icon != null)) ...[
                SizedBox.square(
                  dimension: sizes.fieldIcon,
                  child: Center(
                    child: Glyph(
                      option: sel,
                      color: enabled
                          ? colors.foregroundSecondary
                          : colors.foregroundSubtle,
                    ),
                  ),
                ),
                Gap(sizes.fieldIconGap),
              ],
              Expanded(
                child: Text(
                  sel?.label ?? widget.hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sel != null
                      ? style
                      : style.copyWith(
                          color: enabled
                              ? colors.placeholder
                              : colors.foregroundSubtle,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menu(BuildContext context, PopoverController controller) {
    final items = _items;
    final selected = widget.selected?.value;
    return ListboxMenu(
      controller: _listbox,
      anchorWidth: controller.anchorWidth,
      itemCount: items.length,
      onSelect: (i) => _choose(items[i]),
      onFilterChanged: widget.searchable ? _onFilter : null,
      footer: widget.searchable && _query.isNotEmpty
          ? context.adminL10n.countOf(items.length, widget.options.length)
          : null,
      itemBuilder: (context, i) {
        final o = items[i];
        return ListboxOption(
          controller: _listbox,
          index: i,
          label: o.label,
          description: o.description,
          leading: o.swatch != null || o.icon != null
              ? Glyph(option: o, color: context.colors.foregroundSecondary)
              : null,
          selected: o.value == selected,
          // Focus goes back to the trigger, not to whatever held it before
          // the menu opened.
          onTap: () {
            Popover.dismiss(context);
            _choose(o);
          },
        );
      },
    );
  }
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

class _Segmented extends StatelessWidget {
  final List<SelectOption> options;
  final String? value;
  final ValueChanged<String>? onChanged;

  const _Segmented({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context)
        .merge(readOnly: onChanged == null);
    return Wrap(
      spacing: AdminSpacing.md,
      runSpacing: AdminSpacing.md,
      children: [for (var o in options) _pill(context, o, state)],
    );
  }

  Widget _pill(BuildContext context, SelectOption o, FieldState state) {
    final colors = context.colors;
    final editable = state.enabled && !state.readOnly;
    final selected = o.value == value;
    final border = selected
        ? context.stroke.controlStrong
        : context.stroke.control;
    final Color fg;
    if (!state.enabled) {
      fg = colors.foregroundSubtle;
    } else {
      fg = selected ? colors.primaryText : colors.foregroundMuted;
    }
    return Tappable(
      onTap: editable
          ? () {
              if (!selected) onChanged!(o.value);
            }
          : null,
      selected: selected,
      focusRadius: context.radii.radius,
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
            if (o.swatch != null || o.icon != null) ...[
              Glyph(
                option: o,
                color: !state.enabled
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

/// One Tab stop for the group, on the checked option (the first when none
/// is): the arrow keys move focus and the check between options, like a
/// native radio group.
class _RadioList extends StatefulWidget {
  final List<SelectOption> options;
  final String? value;
  final ValueChanged<String>? onChanged;

  const _RadioList({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RadioList> createState() => _RadioListState();
}

class _RadioListState extends State<_RadioList> {
  final _nodes = <FocusNode>[];

  List<SelectOption> get options => widget.options;
  String? get value => widget.value;
  ValueChanged<String>? get onChanged => widget.onChanged;

  FieldState get _state =>
      FieldStateScope.of(context).merge(readOnly: onChanged == null);

  bool get _editable => _state.enabled && !_state.readOnly;

  int get _tabStop {
    var i = options.indexWhere((o) => o.value == value);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    while (_nodes.length < options.length) {
      _nodes.add(FocusNode(debugLabel: 'radio ${_nodes.length}'));
    }
    while (_nodes.length > options.length) {
      _nodes.removeLast().dispose();
    }
    var stop = _tabStop;
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != stop;
    }
  }

  void _move(int delta) {
    if (!_editable || options.isEmpty) return;
    var current = _nodes.indexWhere((n) => n.hasFocus);
    if (current < 0) return;
    var next = (current + delta) % options.length;
    _nodes[next].requestFocus();
    onChanged!(options[next].value);
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    final state = _state;
    // Left and right follow the reading direction, as in a native group.
    final forward = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _move(forward),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _move(-forward),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const Gap(AdminSpacing.md),
            _row(context, options[i], _nodes[i], state),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    SelectOption o,
    FocusNode node,
    FieldState state,
  ) {
    final colors = context.colors;
    final sizes = context.sizes;
    final editable = state.enabled && !state.readOnly;
    final selected = o.value == value;
    final border = selected
        ? context.stroke.controlStrong
        : context.stroke.control;
    final line = context.type.fieldText;
    return Tappable(
      onTap: editable
          ? () {
              if (!selected) onChanged!(o.value);
            }
          : null,
      focusNode: node,
      focusRadius: context.radii.radius,
      checked: selected,
      inMutuallyExclusiveGroup: true,
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
              child: Center(child: _radio(context, selected, state)),
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
                          color: state.enabled
                              ? colors.foregroundSecondary
                              : colors.foregroundSubtle,
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
                                color: !state.enabled
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
                        color: !state.enabled
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

  Widget _radio(BuildContext context, bool selected, FieldState state) {
    final colors = context.colors;
    final color = !state.enabled
        ? colors.foregroundFaint
        : (selected ? colors.controlAccent : colors.controlBorder);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: selected ? 5 : 1.5),
      ),
    );
  }
}
