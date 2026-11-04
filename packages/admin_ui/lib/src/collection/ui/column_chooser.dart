/// @docImport 'collection_toolbar.dart';
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/checkbox.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/search_field.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../column_layout.dart';
import 'collection_table.dart';

/// One selectable column in a [ColumnChooser]. [locked] columns can't be hidden
/// (the visibility box is fixed on) — for a table's anchor column.
@immutable
class ColumnChoice {
  final String key;
  final String label;
  final bool locked;

  const ColumnChoice({
    required this.key,
    required this.label,
    this.locked = false,
  });

  /// One choice per table column, in order: its [TableColumn.key] and
  /// [TableColumn.label], locked when it isn't [TableColumn.hideable] — so the
  /// chooser never restates what the table already declares.
  static List<ColumnChoice> fromColumns<T>(List<TableColumn<T>> columns) => [
    for (final c in columns)
      ColumnChoice(key: c.key, label: c.label, locked: !c.hideable),
  ];
}

/// A reorderable checklist of table columns — toggle visibility, reorder.
/// Pure View: it renders [layout] over [columns] and reports the edited
/// [ColumnLayout] through [onChanged]; it owns no column state.
///
/// Each row is one Tab stop: Space or Enter toggles it, Alt+↑ / Alt+↓ move
/// it, and assistive technology offers "Move up" / "Move down"; the pointer
/// drags it by its handle. Past [searchThreshold] columns a search box and
/// Show all / Hide all head the list; reordering waits for the search to be
/// cleared.
///
/// Pair it with a [CollectionTable] by feeding `layout.apply(allColumns)` as the
/// table's columns, and [ColumnChoice.fromColumns] as [columns].
/// [ColumnChooserButton] wraps this in a toolbar popover.
class ColumnChooser extends StatefulWidget {
  final List<ColumnChoice> columns;
  final ColumnLayout layout;
  final ValueChanged<ColumnLayout> onChanged;

  /// Shows a "Reset" affordance in the header when set.
  final VoidCallback? onReset;

  /// More columns than this add the search box and Show all / Hide all.
  final int searchThreshold;

  const ColumnChooser({
    super.key,
    required this.columns,
    required this.layout,
    required this.onChanged,
    this.onReset,
    this.searchThreshold = 8,
  });

  @override
  State<ColumnChooser> createState() => _ColumnChooserState();
}

class _ColumnChooserState extends State<ColumnChooser> {
  String _query = '';

  List<ColumnChoice> get _ordered {
    final byKey = {for (final c in widget.columns) c.key: c};
    final known = [
      for (final k in widget.layout.order)
        if (byKey[k] != null) byKey[k]!,
    ];
    final knownKeys = known.map((c) => c.key).toSet();
    final fresh = [
      for (final c in widget.columns)
        if (!knownKeys.contains(c.key)) c,
    ];
    return [...known, ...fresh];
  }

  int get _visibleCount =>
      widget.columns.where((c) => widget.layout.isVisible(c.key)).length;

  bool get _searchable => widget.columns.length > widget.searchThreshold;

  void _reorder(int oldIndex, int newIndex) {
    final keys = [for (final c in _ordered) c.key];
    final moved = keys.removeAt(oldIndex);
    keys.insert(newIndex, moved);
    widget.onChanged(widget.layout.withOrder(keys));
  }

  /// Shows or hides every listed column that isn't locked.
  void _setAll(List<ColumnChoice> listed, bool visible) {
    var next = widget.layout;
    for (final c in listed) {
      if (!c.locked) next = next.withVisible(c.key, visible);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered;
    final query = _query.trim().toLowerCase();
    final filtering = _searchable && query.isNotEmpty;
    final listed = filtering
        ? [
            for (final c in ordered)
              if (c.label.toLowerCase().contains(query)) c,
          ]
        : ordered;

    Widget row(ColumnChoice c, int i) => _Row(
      key: ValueKey(c.key),
      index: i,
      choice: c,
      visible: widget.layout.isVisible(c.key),
      onToggle: c.locked
          ? null
          : (v) => widget.onChanged(widget.layout.withVisible(c.key, v)),
      // Moves only apply to the whole list, never a filtered slice of it.
      onMoveUp: filtering || i == 0 ? null : () => _reorder(i, i - 1),
      onMoveDown: filtering || i == listed.length - 1
          ? null
          : () => _reorder(i, i + 1),
      draggable: !filtering,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        if (_searchable) _tools(context, listed),
        Flexible(
          child: filtering
              ? ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AdminSpacing.xs,
                  ),
                  children: [
                    for (final (i, c) in listed.indexed) row(c, i),
                    if (listed.isEmpty) _noMatch(context),
                  ],
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(
                    vertical: AdminSpacing.xs,
                  ),
                  itemCount: listed.length,
                  onReorderItem: _reorder,
                  proxyDecorator: (child, _, _) =>
                      Material(color: context.colors.surface, child: child),
                  itemBuilder: (context, i) => row(listed[i], i),
                ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final colors = context.colors;
    final strings = context.adminL10n;
    final muted = colors.readableOn(
      colors.foregroundMuted,
      surfaces: [colors.surface],
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.md,
        AdminSpacing.sm,
        AdminSpacing.sm,
        AdminSpacing.xs,
      ),
      child: Row(
        children: [
          // The title gives way first, so a large text size never pushes
          // Reset out of the panel.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    strings.collection.columns,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type
                        .weighted(context.type.caption, FontWeight.w700)
                        .copyWith(color: muted),
                  ),
                ),
                const Gap(AdminSpacing.sm),
                Text(
                  strings.countOf(_visibleCount, widget.columns.length),
                  maxLines: 1,
                  style: context.type.caption.copyWith(color: muted),
                ),
              ],
            ),
          ),
          if (widget.onReset != null)
            Button.ghost(
              strings.reset,
              size: ControlSize.small,
              onPressed: widget.onReset,
            ),
        ],
      ),
    );
  }

  Widget _tools(BuildContext context, List<ColumnChoice> listed) {
    final strings = context.adminL10n.collection;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(
            value: _query,
            hint: strings.findColumn,
            size: ControlSize.small,
            onChanged: (v) => setState(() => _query = v),
          ),
          const Gap(AdminSpacing.xs),
          Row(
            children: [
              Button.ghost(
                strings.showAll,
                size: ControlSize.small,
                onPressed: () => _setAll(listed, true),
              ),
              const Gap(AdminSpacing.xs),
              Button.ghost(
                strings.hideAll,
                size: ControlSize.small,
                onPressed: () => _setAll(listed, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noMatch(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.md,
      ),
      child: Text(
        context.adminL10n.collection.noMatchingColumns,
        style: context.type.body.copyWith(
          color: colors.readableOn(
            colors.foregroundMuted,
            surfaces: [colors.surface],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  final int index;
  final ColumnChoice choice;
  final bool visible;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool draggable;

  const _Row({
    super.key,
    required this.index,
    required this.choice,
    required this.visible,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.draggable,
  });

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  /// Runs a move, then keeps the row — which keeps focus — in view.
  void _move(VoidCallback? move) {
    if (move == null) return;
    move();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final choice = widget.choice;
    final shown = widget.visible || choice.locked;
    final onToggle = widget.onToggle;
    final radius = context.radii.radiusSmall;
    final strings = context.adminL10n;

    final handle = Padding(
      padding: const EdgeInsets.all(AdminSpacing.xs),
      child: Icon(
        Icons.drag_indicator,
        size: context.iconSizes.md,
        color: widget.draggable
            ? colors.foregroundMuted
            : colors.foregroundSubtle,
      ),
    );

    final row = Tappable.states(
      onTap: onToggle == null ? null : () => onToggle(!widget.visible),
      // A locked row can't toggle but still takes focus, to be moved.
      readOnly: onToggle == null,
      checked: shown,
      focusRadius: radius,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AdminSpacing.xs,
            AdminSpacing.xs,
            AdminSpacing.sm,
            AdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: hovered ? colors.hoverOverlay : null,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Semantics(
            customSemanticsActions: {
              if (widget.onMoveUp != null)
                CustomSemanticsAction(label: strings.moveUp): () =>
                    _move(widget.onMoveUp),
              if (widget.onMoveDown != null)
                CustomSemanticsAction(label: strings.moveDown): () =>
                    _move(widget.onMoveDown),
            },
            child: Row(
              children: [
                if (widget.draggable)
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: handle,
                    ),
                  )
                else
                  handle,
                const Gap(AdminSpacing.xs),
                // The row is the control; the box only shows its state.
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: ExcludeFocus(
                      child: Check(
                        value: shown,
                        onChanged: onToggle == null ? null : (_) {},
                      ),
                    ),
                  ),
                ),
                const Gap(AdminSpacing.md),
                Expanded(
                  child: Text(
                    choice.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.body.copyWith(
                      color: shown
                          ? colors.foreground
                          : colors.readableOn(
                              colors.foregroundMuted,
                              surfaces: [
                                colors.surface,
                                Color.alphaBlend(
                                  colors.hoverOverlay,
                                  colors.surface,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                if (choice.locked)
                  Icon(
                    Icons.lock_outline,
                    size: context.iconSizes.sm,
                    semanticLabel: strings.collection.locked,
                    color: colors.foregroundMuted,
                  ),
              ],
            ),
          ),
        );
      },
    );

    return Padding(
      // Half the hairline gap on either side, so neighbouring fills never
      // touch.
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.xs,
        vertical: AdminSpacing.xxs / 2,
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
              _move(widget.onMoveUp),
          const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
              _move(widget.onMoveDown),
        },
        child: row,
      ),
    );
  }
}

/// A toolbar button that opens a [ColumnChooser] in a popover. Drop it into
/// [CollectionToolbar.trailing]; feed the same [columns] / [layout] / [onChanged].
class ColumnChooserButton extends StatelessWidget {
  final List<ColumnChoice> columns;
  final ColumnLayout layout;
  final ValueChanged<ColumnLayout> onChanged;
  final VoidCallback? onReset;

  /// The button's name; "Columns" in the app's language by default.
  final String? label;

  /// The trigger's size. [ControlSize.small] is a discreet icon-only
  /// trigger (with a dot when columns are hidden) — for living quietly in a
  /// toolbar alongside per-column header menus; [ControlSize.medium] (the
  /// default) and [ControlSize.large] are the labelled button at that size.
  final ControlSize size;

  const ColumnChooserButton({
    super.key,
    required this.columns,
    required this.layout,
    required this.onChanged,
    this.onReset,
    this.label,
    this.size = ControlSize.medium,
  });

  /// The hidden-columns dot: even, so it sits on whole pixels.
  static const _dot = 8.0;

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.collection;
    final label = this.label ?? strings.columns;
    final hiddenCount = columns.where((c) => !layout.isVisible(c.key)).length;
    final named = hiddenCount > 0
        ? strings.withHidden(label, hiddenCount)
        : label;
    return Popover(
      side: PopoverSide.bottom,
      align: PopoverAlign.end,
      anchor: (context, controller) => size == ControlSize.small
          ? Stack(
              children: [
                IconAction(
                  Icons.view_column_outlined,
                  label: named,
                  expanded: controller.isOpen,
                  onPressed: controller.toggle,
                ),
                // The hidden count is in the name; the dot only marks it.
                if (hiddenCount > 0)
                  PositionedDirectional(
                    top: AdminSpacing.sm,
                    end: AdminSpacing.sm,
                    child: IgnorePointer(
                      child: Container(
                        width: _dot,
                        height: _dot,
                        decoration: BoxDecoration(
                          color: context.colors.readableOn(
                            context.colors.primary,
                            surfaces: [context.colors.surface],
                            minContrast: 3,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Button(
              named,
              icon: Icons.view_column_outlined,
              trailingIcon: Icons.keyboard_arrow_down,
              size: size,
              onPressed: controller.toggle,
            ),
      content: (context, controller) => PopoverMenuSurface(
        width: 268,
        maxHeight: 400,
        child: ColumnChooser(
          columns: columns,
          layout: layout,
          onChanged: onChanged,
          onReset: onReset,
        ),
      ),
    );
  }
}
