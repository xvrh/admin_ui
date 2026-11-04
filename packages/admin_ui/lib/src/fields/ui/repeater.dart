import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_chrome.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/panel.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// A repeatable list of sub-records — a gallery's captions, a page's FAQ items,
/// a product's variants. Index-based like `ListView.builder`: the caller owns
/// the list and passes [itemCount] + [itemBuilder]; the Repeater supplies the
/// per-item chrome (drag handle, remove) plus an [AddRowButton] and an empty
/// state.
///
/// Reordering turns on when [onReorder] is given (and there's more than one
/// item). For correct drag animations, give each item a stable identity via
/// [keyForItem]; the default falls back to the index.
///
/// Under a read-only or disabled [FieldStateScope] (a read-only form, say)
/// the rows show without the add, remove and reorder actions, as if none of
/// [onAdd], [onRemove] and [onReorder] were given. Under an invalid one (a
/// list its rules want a row in) the default empty state takes the field's
/// error edge, as an invalid input's box does.
class Repeater extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Stable per-item key. Defaults to `ValueKey(index)` — fine visually, but
  /// supply a real identity so reorder animations track the right row.
  final Key Function(int index)? keyForItem;

  /// Called when a row is dragged to a new position. `newIndex` is the final
  /// resting index (already adjusted for the removed row) — just
  /// `items.insert(newIndex, items.removeAt(oldIndex))`.
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(int index)? onRemove;

  /// The accessible name and tooltip of a row's remove action, so each one
  /// says which row it removes. Defaults to "Remove item 1", "Remove item 2"…
  /// in the app's language.
  final String Function(int index)? removeLabel;

  final VoidCallback? onAdd;

  /// The add button's label; null reads "Add item" in the app's language.
  final String? addLabel;

  /// Shown in place of the list when [itemCount] is 0. Defaults to a muted
  /// "No items yet." placeholder.
  final Widget? emptyState;

  /// Vertical gap between items.
  final double spacing;

  const Repeater({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.keyForItem,
    this.onReorder,
    this.onRemove,
    this.removeLabel,
    this.onAdd,
    this.addLabel,
    this.emptyState,
    this.spacing = AdminSpacing.md,
  });

  Key _keyOf(int index) => keyForItem?.call(index) ?? ValueKey(index);

  String _removeLabelOf(BuildContext context, int index) =>
      removeLabel?.call(index) ??
      context.adminL10n.fields.removeItemAt(index + 1);

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    final onReorder = editable ? this.onReorder : null;
    final onRemove = editable ? this.onRemove : null;
    final onAdd = editable ? this.onAdd : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (itemCount == 0)
          emptyState ?? const _Empty()
        else if (onReorder != null && itemCount > 1)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: onReorder,
            proxyDecorator: (child, index, animation) =>
                _DragProxy(child: child),
            children: [
              for (var i = 0; i < itemCount; i++)
                Padding(
                  key: _keyOf(i),
                  padding: EdgeInsets.only(bottom: spacing),
                  child: _Item(
                    index: i,
                    reorderable: true,
                    onRemove: onRemove,
                    removeLabel: _removeLabelOf(context, i),
                    child: itemBuilder(context, i),
                  ),
                ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < itemCount; i++) ...[
                if (i > 0) Gap(spacing),
                _Item(
                  key: _keyOf(i),
                  index: i,
                  reorderable: false,
                  onRemove: onRemove,
                  removeLabel: _removeLabelOf(context, i),
                  child: itemBuilder(context, i),
                ),
              ],
            ],
          ),
        if (onAdd != null) ...[
          if (itemCount > 0) Gap(spacing),
          AddRowButton(
            label: addLabel ?? context.adminL10n.addItem,
            onPressed: onAdd,
          ),
        ],
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final int index;
  final bool reorderable;
  final void Function(int index)? onRemove;
  final String removeLabel;
  final Widget child;

  const _Item({
    super.key,
    required this.index,
    required this.reorderable,
    required this.onRemove,
    required this.removeLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reorderable) ...[
            ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: context.iconSizes.md,
                  color: context.colors.foregroundFaint,
                ),
              ),
            ),
            const Gap(AdminSpacing.sm),
          ],
          Expanded(child: child),
          if (onRemove != null) ...[
            const Gap(AdminSpacing.sm),
            IconAction(
              Icons.close_rounded,
              label: removeLabel,
              size: IconActionSize.inline,
              danger: true,
              onPressed: () => onRemove!(index),
            ),
          ],
        ],
      ),
    );
  }
}

/// A subtle floating look for the row being dragged.
class _DragProxy extends StatelessWidget {
  final Widget child;

  const _DragProxy({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      // token-literal: the lifted item's shadow
      shadowColor: context.colors.shadow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(context.radii.radiusLarge),
      child: child,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final empty = Panel(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xl),
      child: Center(
        child: Text(
          context.adminL10n.fields.noItemsYet,
          style: context.type.bodyMuted,
        ),
      ),
    );
    if (!FieldStateScope.of(context).invalid) return empty;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(
          color: context.colors.danger,
          width: context.stroke.fieldError,
        ),
      ),
      child: empty,
    );
  }
}
