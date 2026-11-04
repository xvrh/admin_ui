import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// One column of a [KanbanBoard]. [id] is the stable key reported back on a move
/// and used as the drop-target identity; [items] are the cards currently in it.
/// Optional chrome: an [accent] for the header dot and the drop highlight, a
/// [subtitle] under the title, and a [trailing] control at the header's end.
class KanbanColumn<T> {
  final String id;
  final String title;
  final List<T> items;
  final Color? accent;
  final String? subtitle;

  /// A small control after the count — an add-card or column-menu
  /// [IconAction] at [IconActionSize.small], or a small button. The title row
  /// keeps one height, so columns with and without it line up.
  final Widget? trailing;

  const KanbanColumn({
    required this.id,
    required this.title,
    required this.items,
    this.accent,
    this.subtitle,
    this.trailing,
  });
}

/// A generic, presentational kanban board: fixed-width columns of draggable
/// cards, horizontally scrollable, each column scrolling its own cards.
///
/// Pure View — [columns] in, intent out via [onMove] (a card dropped on a
/// different column) and [onCardTap]. It holds no data; the parent holds the
/// card→column assignment and rebuilds after a move. The board only supplies
/// drag mechanics and column chrome; [cardBuilder] fully owns each card's
/// visual (border, tint, badges), so a caller can, e.g., flag an outdated card
/// with its own red border without the board knowing.
///
/// Every column header has the same shape — a title row (dot, title, count,
/// [KanbanColumn.trailing]) over a subtitle line whenever any column has a
/// subtitle — so first cards line up across the board. The header starts
/// where a card's content does, given a card padded by [cardPadding] inside
/// a 1px border. Without [onMove] the cards don't drag. With it, a focused
/// card also moves with Alt+← / Alt+→, and assistive technology offers a
/// "Move to …" action per other column.
///
/// Place inside a bounded-height slot (an [Expanded] in a [Column]); columns
/// take the full height and scroll their cards internally.
class KanbanBoard<T> extends StatefulWidget {
  final List<KanbanColumn<T>> columns;
  final Widget Function(BuildContext context, T item) cardBuilder;

  /// Stable identity per card — the widget key and drag-payload identity.
  final Object Function(T item) itemKey;

  /// A card was dropped on a different column. `from` and `to` are the
  /// columns' [KanbanColumn.id]s.
  final void Function(T item, String from, String to)? onMove;

  /// Opens a card. The tap is named for what the view draws: a table's
  /// `onRowTap`, a card view's or a board's `onCardTap`.
  final void Function(T item)? onCardTap;

  /// Placeholder for a column with no cards. Defaults to a muted "No items",
  /// which reads "Drop here" while a card is being dragged, in the app's
  /// language.
  ///
  /// A builder, where the table and the card view take an `empty` widget:
  /// it fills one column, which it is given, and an empty column is a drop
  /// target on a board that has cards, not an empty result.
  final Widget Function(BuildContext context, KanbanColumn<T> column)?
  emptyBuilder;

  final double columnWidth;

  /// The padding a card gives its content inside its 1px border: the column
  /// header is inset to match, so its dot and count line up with the cards'
  /// content.
  static const cardPadding = EdgeInsets.all(AdminSpacing.lg);

  const KanbanBoard({
    super.key,
    required this.columns,
    required this.cardBuilder,
    required this.itemKey,
    this.onMove,
    this.onCardTap,
    this.emptyBuilder,
    this.columnWidth = 300,
  });

  @override
  State<KanbanBoard<T>> createState() => _KanbanBoardState<T>();
}

class _KanbanBoardState<T> extends State<KanbanBoard<T>> {
  /// Horizontal inset of the cards from the column edge.
  static const _inset = AdminSpacing.md;

  /// Horizontal inset of the header: a card's content inset, border and
  /// [KanbanBoard.cardPadding] included.
  static final _headerStart = _inset + 1 + KanbanBoard.cardPadding.left;
  static final _headerEnd = _inset + 1 + KanbanBoard.cardPadding.right;

  bool _dragging = false;

  void _setDragging(bool dragging) {
    if (dragging != _dragging) setState(() => _dragging = dragging);
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns;
    final subtitles = columns.any((c) => c.subtitle != null);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) const Gap(AdminSpacing.lg),
            SizedBox(
              width: widget.columnWidth,
              child: _column(context, i, subtitles: subtitles),
            ),
          ],
        ],
      ),
    );
  }

  Widget _column(BuildContext context, int index, {required bool subtitles}) {
    final c = context.colors;
    final column = widget.columns[index];
    final accent = column.accent ?? c.foregroundMuted;
    final radius = BorderRadius.circular(context.radii.radiusLarge);
    return DragTarget<_KanbanDrag<T>>(
      onWillAcceptWithDetails: (d) => d.data.from != column.id,
      onAcceptWithDetails: (d) =>
          widget.onMove?.call(d.data.item, d.data.from, column.id),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        final fill = active
            ? Color.alphaBlend(
                accent.withValues(alpha: c.stateLayer.tintHover),
                c.background,
              )
            : c.background;
        // The highlight is painted over the resting 1px border rather than
        // widening it, so the cards never shift as a drag passes over.
        return AnimatedContainer(
          duration: context.motion.fast,
          curve: context.motion.standard,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: c.border),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: active ? accent : accent.withValues(alpha: 0),
              width: context.stroke.indicator,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, column, accent, subtitles: subtitles),
              Expanded(child: _body(context, index, fill)),
            ],
          ),
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    KanbanColumn<T> column,
    Color accent, {
    required bool subtitles,
  }) {
    final c = context.colors;
    // Tall enough for a small trailing control, so a column with one is no
    // taller than one without, and taller by as much as the title grows at
    // a large text size.
    final rowHeight =
        math.max(context.sizes.small, IconActionSize.small.box) +
        textGrowthOf(context, context.type.bodyStrong);
    const dot = 8.0;
    const dotGap = AdminSpacing.md;
    final subtitle = column.subtitle;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        _headerStart,
        AdminSpacing.md,
        _headerEnd,
        AdminSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(dotGap),
                Expanded(
                  child: Text(
                    column.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.bodyStrong,
                  ),
                ),
                const Gap(AdminSpacing.sm),
                _count(context, column.items.length),
                if (column.trailing != null) ...[
                  const Gap(AdminSpacing.xs),
                  column.trailing!,
                ],
              ],
            ),
          ),
          // A column without a subtitle keeps the line empty, so every
          // header on the board has one height.
          if (subtitles)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: dot + dotGap),
              child: subtitle == null
                  ? ExcludeSemantics(
                      child: Text(' ', style: context.type.caption),
                    )
                  : Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.caption.copyWith(
                        color: c.readableOn(
                          c.foregroundMuted,
                          surfaces: [c.background],
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _count(BuildContext context, int count) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: c.borderSubtle,
        borderRadius: BorderRadius.circular(context.radii.radiusPill),
      ),
      child: Text(
        context.adminFormats.integer(count),
        style: context.type
            .weighted(context.type.caption, FontWeight.w700)
            .copyWith(color: c.foregroundSecondary),
      ),
    );
  }

  Widget _body(BuildContext context, int index, Color fill) {
    final column = widget.columns[index];
    if (column.items.isEmpty) {
      return widget.emptyBuilder?.call(context, column) ??
          _emptyColumn(context, fill);
    }
    return ListView.separated(
      padding: const EdgeInsetsDirectional.fromSTEB(_inset, 0, _inset, _inset),
      itemCount: column.items.length,
      separatorBuilder: (_, _) => const Gap(AdminSpacing.md),
      itemBuilder: (context, i) => _card(context, index, column.items[i]),
    );
  }

  /// Moves [item] from column [index] to the one [step] places along, if any.
  void _step(int index, T item, int step) {
    final to = index + step;
    if (to < 0 || to >= widget.columns.length) return;
    widget.onMove?.call(item, widget.columns[index].id, widget.columns[to].id);
  }

  Widget _card(BuildContext context, int index, T item) {
    final column = widget.columns[index];
    final card = widget.cardBuilder(context, item);
    final onMove = widget.onMove;
    final onCardTap = widget.onCardTap;

    Widget tile = card;
    if (onMove != null) {
      tile = Semantics(
        // Its own node when no tap makes one around it.
        container: onCardTap == null,
        customSemanticsActions: {
          for (final (i, other) in widget.columns.indexed)
            if (i != index)
              CustomSemanticsAction(
                label: context.adminL10n.collection.moveTo(other.title),
              ): () =>
                  onMove(item, column.id, other.id),
        },
        child: Draggable<_KanbanDrag<T>>(
          data: _KanbanDrag(item, column.id),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _feedback(context, card),
          childWhenDragging: Opacity(opacity: 0.35, child: card),
          onDragStarted: () => _setDragging(true),
          onDragEnd: (_) => _setDragging(false),
          child: card,
        ),
      );
    }
    final cursor = onMove == null ? null : SystemMouseCursors.grab;
    if (onCardTap == null) {
      tile = MouseRegion(cursor: cursor ?? MouseCursor.defer, child: tile);
    } else {
      // A Tab stop that Enter opens; with onMove, Alt+arrows move it.
      tile = Tappable(
        onTap: () => onCardTap(item),
        cursor: cursor,
        focusRadius: context.radii.radiusLarge,
        child: tile,
      );
    }
    if (onMove != null) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      tile = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () =>
              _step(index, item, rtl ? 1 : -1),
          const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () =>
              _step(index, item, rtl ? -1 : 1),
        },
        child: tile,
      );
    }
    return KeyedSubtree(key: ValueKey(widget.itemKey(item)), child: tile);
  }

  Widget _feedback(BuildContext context, Widget card) {
    final colors = context.colors;
    final dark = colors.brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Tipped toward the reading direction, mirrored right to left.
    return Transform.rotate(
      angle: rtl ? -0.02 : 0.02,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: widget.columnWidth - _inset * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.radii.radiusLarge),
              boxShadow: [
                BoxShadow(
                  // token-literal: the lifted card's shadow
                  color: colors.shadow.withValues(alpha: dark ? 0.5 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: card,
          ),
        ),
      ),
    );
  }

  Widget _emptyColumn(BuildContext context, Color fill) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: Text(
          _dragging
              ? context.adminL10n.collection.dropHere
              : context.adminL10n.collection.noItems,
          style: context.type.caption.copyWith(
            color: c.readableOn(
              c.foregroundMuted,
              surfaces: [c.background, fill],
            ),
          ),
        ),
      ),
    );
  }
}

/// The drag payload — the card plus the column it left, so the target can ignore
/// same-column drops and report the transition.
class _KanbanDrag<T> {
  final T item;
  final String from;
  const _KanbanDrag(this.item, this.from);
}
