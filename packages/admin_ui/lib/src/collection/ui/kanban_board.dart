import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/pointer.dart';
import '../../common/text_metrics.dart';
import '../../common/ui/focus_ring.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/sizes.dart';
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
/// a 1px border.
///
/// **Moving a card.** Without [onMove] the cards don't drag. With it a drag
/// is never the only way:
///
/// - every card is a Tab stop, whether or not it opens, and Alt+← / Alt+→
///   move the focused card a column over, the way the arrow points;
/// - a ⋯ in the card's top end corner opens a menu with a "Move to …" item
///   per other column. It shows while the pointer is over the card or focus
///   is on or in it, and for good where the pointer is a finger, which has
///   no hover; it is the Tab stop after its card either way, and a screen
///   reader is read it while it shows. It lies over
///   the card, on a chip of its own, 28px square and [AdminSpacing.sm] in
///   from the corner: a card keeps what must stay readable out of there;
/// - assistive technology is offered the same "Move to …" actions on the
///   card itself.
///
/// Enter opens the focused card that [onCardTap] opens.
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

  /// Whether [onCardTap] opens [item]; null opens every card. A card that
  /// does not open shows no hand and Enter does nothing on it. It still
  /// moves with [onMove], and is then a Tab stop to move it from; without
  /// [onMove] it is none.
  final bool Function(T item)? canOpen;

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
    this.canOpen,
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

  /// Whether the last pointer on the board was a finger or a pen; null
  /// until one lands.
  bool? _touch;

  /// Whether the pointer is coarse: the last one was a finger or a pen, or
  /// none has landed on a touch-first platform. The cards' menus then stay
  /// up, as there is no hover to reveal them.
  bool get _coarse => _touch ?? coarsePointerByDefault;

  void _setDragging(bool dragging) {
    if (dragging != _dragging) setState(() => _dragging = dragging);
  }

  void _onPointerDown(PointerDownEvent event) {
    final coarse = isCoarsePointer(event.kind);
    if (coarse != _touch) setState(() => _touch = coarse);
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns;
    final subtitles = columns.any((c) => c.subtitle != null);
    return Listener(
      onPointerDown: widget.onMove == null ? null : _onPointerDown,
      child: SingleChildScrollView(
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
    final onCardTap = (widget.canOpen?.call(item) ?? true)
        ? widget.onCardTap
        : null;
    final key = ValueKey(widget.itemKey(item));
    final open = onCardTap == null ? null : () => onCardTap(item);

    if (onMove == null) {
      // A read-only board: a card that opens is a control, a Tab stop that
      // shows the hand; any other is content.
      if (open == null) return KeyedSubtree(key: key, child: card);
      return Tappable(
        key: key,
        onTap: open,
        focusRadius: context.radii.radiusLarge,
        child: card,
      );
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    return _MovableCard(
      key: key,
      onOpen: open,
      moves: [
        for (final (i, other) in widget.columns.indexed)
          if (i != index)
            (
              context.adminL10n.collection.moveTo(other.title),
              () => onMove(item, column.id, other.id),
            ),
      ],
      // The way the arrow points, whichever way the columns run.
      onStepLeft: () => _step(index, item, rtl ? 1 : -1),
      onStepRight: () => _step(index, item, rtl ? -1 : 1),
      menuRevealed: _coarse,
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

/// A card of a board that moves its cards: a Tab stop that Enter opens
/// where [onOpen] is set, that Alt+← / Alt+→ move a column over, and that
/// carries a ⋯ menu of [moves] in its top end corner.
class _MovableCard extends StatefulWidget {
  /// Opens the card; null for one that does not open.
  final VoidCallback? onOpen;

  /// The moves to the other columns, each with its name: "Move to Done".
  final List<(String, VoidCallback)> moves;

  final VoidCallback onStepLeft; // Physical: the arrow key's own way.
  final VoidCallback onStepRight; // Physical: the arrow key's own way.

  /// Keeps the menu up without hover or focus, as for a finger.
  final bool menuRevealed;

  /// The card, draggable.
  final Widget child;

  const _MovableCard({
    super.key,
    required this.onOpen,
    required this.moves,
    required this.onStepLeft,
    required this.onStepRight,
    required this.menuRevealed,
    required this.child,
  });

  @override
  State<_MovableCard> createState() => _MovableCardState();
}

class _MovableCardState extends State<_MovableCard> {
  /// The Tab stop of a card that does not open; one that opens is a
  /// [Tappable] with its own.
  final _focus = FocusNode(debugLabel: 'kanban card');

  bool _hover = false;

  /// Focus is on the card or on its menu.
  bool _focusWithin = false;

  @override
  void initState() {
    super.initState();
    // The card's own semantics and its ring carry the focus.
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final radius = context.radii.radiusLarge;
    final actions = {
      for (final (label, move) in widget.moves)
        CustomSemanticsAction(label: label): move,
    };

    final Widget tile;
    if (widget.onOpen case final open?) {
      // A Tab stop that Enter opens. A card that opens is a control and
      // shows the hand, movable or not.
      tile = Tappable(
        onTap: open,
        focusRadius: radius,
        child: Semantics(customSemanticsActions: actions, child: widget.child),
      );
    } else {
      // Nothing to open: a Tab stop to move the card from, under the open
      // hand that says it can be moved.
      final focused = _focus.hasPrimaryFocus;
      tile = Focus(
        focusNode: _focus,
        includeSemantics: false,
        child: Semantics(
          container: true,
          focusable: true,
          focused: focused,
          onFocus: defaultTargetPlatform != TargetPlatform.iOS
              ? _focus.requestFocus
              : null,
          customSemanticsActions: actions,
          child: FocusRing(
            focused: focused,
            radius: radius,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: widget.child,
            ),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
            widget.onStepLeft,
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
            widget.onStepRight,
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: (focused) => setState(() => _focusWithin = focused),
          child: Stack(
            children: [
              tile,
              if (widget.moves.isNotEmpty)
                PositionedDirectional(
                  top: AdminSpacing.sm,
                  end: AdminSpacing.sm,
                  child: _menu(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The ⋯ over the card's top end corner, on a chip of its own so that it
  /// reads over whatever the card draws there. Hidden, it keeps its place
  /// in the Tab order, where focus shows it, and takes no pointer. A screen
  /// reader is not read it then, as its press would do nothing: the card's
  /// own "Move to …" actions move it.
  Widget _menu(BuildContext context) {
    final colors = context.colors;
    return Menu(
      align: PopoverAlign.end,
      entries: [
        for (final (label, move) in widget.moves)
          MenuItem(label, onSelect: move),
      ],
      builder: (context, menu) {
        final shown =
            widget.menuRevealed || _hover || _focusWithin || menu.isOpen;
        return IgnorePointer(
          ignoring: !shown,
          child: ExcludeSemantics(
            excluding: !shown,
            child: AnimatedOpacity(
              opacity: shown ? 1 : 0,
              duration: context.motion.fast,
              curve: context.motion.standard,
              // Read for as long as it takes the pointer, its fade in too.
              alwaysIncludeSemantics: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(
                    context.radii.button(ControlSize.small),
                  ),
                  border: Border.all(color: colors.border),
                ),
                child: IconAction(
                  Icons.more_horiz_rounded,
                  label: context.adminL10n.collection.moveCard,
                  size: IconActionSize.small,
                  expanded: menu.isOpen,
                  onPressed: menu.toggle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
