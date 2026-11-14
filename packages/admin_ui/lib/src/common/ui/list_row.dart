/// @docImport '../../collection/ui/collection_table.dart';
/// @docImport '../../shell/ui/sidebar.dart';
/// @docImport 'avatar.dart';
/// @docImport 'listbox.dart';
/// @docImport 'panel.dart';
/// @docImport 'split_view.dart';
/// @docImport 'status_pill.dart';
/// @docImport 'tag.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'tappable.dart';

/// One row of a list the user picks an item from: a [title], a muted
/// [subtitle] under it, and a [leading] and a [trailing] widget beside them.
/// A column of them is the master list of a [SplitView], whose next pane
/// shows the detail of the [selected] row.
///
/// The app keeps which row is selected: [onTap] tells it a row was picked,
/// and [selected] says which one is. The selected row is filled as a
/// selected table row is ([AdminPalette.tableRowSelected]) and announced as
/// selected. Hover and press lay the state layer
/// ([AdminPalette.hoverOverlay], [AdminPalette.pressedOverlay]) over
/// whatever fill the row has, so the selection never reads weaker under the
/// pointer. The subtitle is muted, and so are an icon in [leading] or
/// [trailing] and text in [trailing] that set no colour of their own: held
/// to 4.5:1 on each of those fills, over the surface or the page background.
/// The list belongs on the surface, in a [Panel] or a card, as a table
/// does: the selected fill is measured against it, and on the page
/// background some themes' selection stands closer to the page than hover.
///
/// The title and the subtitle take one line each and end in an ellipsis;
/// [trailing] keeps its own width, so a long title never pushes it out. Rows
/// sit edge to edge, flush with a pane that clips, so keyboard focus draws
/// the ring just inside the row rather than around it.
///
/// With [onTap] the row is a [Tappable]: the hand, a Tab stop, Enter and
/// Space, a button for assistive technology, and its text left out of a
/// selection. Without one it is content, not a control: no hand, no hover,
/// no Tab stop and no button. Its text still reads as one node, and selects
/// under a [SelectionArea] as a table's with no row tap does.
///
/// The sidebar's items are [NavItem]s, a dropdown's options a [Listbox], and
/// records in columns a [CollectionTable].
class ListRow extends StatelessWidget {
  final String title;

  /// One muted line under [title].
  final String? subtitle;

  /// Before the text, centred on it: an icon, an [Avatar], a [StatusDot].
  final Widget? leading;

  /// After the text, at its own width: a [StatusPill], a [Tag], a count, a
  /// timestamp.
  final Widget? trailing;

  /// Whether this is the picked row, the one whose detail shows: filled as a
  /// selected item and announced as selected.
  final bool selected;

  /// Picks the row. Null for a row that does not open: no hover, the arrow,
  /// no Tab stop, and its text still read.
  final VoidCallback? onTap;

  const ListRow(
    this.title, {
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    if (onTap == null) {
      return Semantics(
        container: true,
        selected: selected ? true : null,
        child: _row(context, const {}),
      );
    }
    return Tappable.states(
      onTap: onTap,
      selected: selected ? true : null,
      // Drawn inside the row instead: a ring around it would be clipped by
      // the pane, and covered by the row after it.
      showFocusRing: false,
      builder: _row,
    );
  }

  Widget _row(BuildContext context, Set<WidgetState> states) {
    final colors = context.colors;
    final type = context.type;
    final base = selected ? colors.tableRowSelected : null;
    final overlay = states.contains(WidgetState.pressed)
        ? colors.pressedOverlay
        : states.contains(WidgetState.hovered)
        ? colors.hoverOverlay
        : null;
    final fill = overlay == null || base == null
        ? overlay ?? base
        : Color.alphaBlend(overlay, base);
    final muted = _mutedOn(colors);
    final trailing = this.trailing;
    final leading = this.leading;
    final subtitle = this.subtitle;

    return Container(
      color: fill,
      foregroundDecoration: states.contains(WidgetState.focused)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(context.radii.radiusSmall),
              border: Border.all(
                color: colors.focusRing,
                width: context.focus.width,
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.md,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme.merge(
              data: IconThemeData(color: muted, size: context.iconSizes.lg),
              child: leading,
            ),
            const Gap(AdminSpacing.lg),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodyStrong.copyWith(color: colors.foreground),
                ),
                if (subtitle != null) ...[
                  const Gap(AdminSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const Gap(AdminSpacing.md),
            IconTheme.merge(
              data: IconThemeData(color: muted, size: context.iconSizes.md),
              child: DefaultTextStyle.merge(
                style: type.caption.copyWith(color: muted),
                child: trailing,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// [AdminPalette.foregroundMutedOnTint], held to 4.5:1 on every fill a row
  /// takes, at rest, hovered and pressed, over the surface or the page
  /// background: one ink for every row of a list, whatever its state.
  static Color _mutedOn(AdminPalette colors) => colors.readableOn(
    colors.foregroundMutedOnTint,
    surfaces: [
      for (final base in [
        colors.surface,
        colors.background,
        colors.tableRowSelected,
      ]) ...[
        base,
        Color.alphaBlend(colors.hoverOverlay, base),
        Color.alphaBlend(colors.pressedOverlay, base),
      ],
    ],
  );
}
