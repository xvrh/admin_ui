/// @docImport '../../theme/palette.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/pointer.dart';
import '../../common/ui/checkbox.dart';
import '../../common/ui/delayed_loading.dart';
import '../../common/ui/empty_state.dart';
import '../../common/ui/focus_ring.dart';
import '../../common/ui/skeleton.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'view_support.dart';

/// A presentational card/grid view of a collection — the gallery counterpart to
/// `CollectionTable`, fed by the same data. Each row is rendered by the caller's
/// [cardBuilder] inside shared card chrome (border, hover lift, selected tint
/// and ring).
///
/// Pure View: plain [rows] in, intent out via callbacks. No fetching, no global
/// reads. The grid reflows to as many columns as fit at [minTileWidth] and
/// builds only the tiles in view. Tiles share one width; with a [tileHeight]
/// every tile takes it, and without one each row of tiles stretches to its
/// tallest card, so the bottoms line up.
///
/// Selection is controlled: pass [selected] + [onSelectionChanged]. Rows are
/// told apart by [rowKey] (by `==` without one). A corner checkbox shows
/// under the pointer and while the card holds focus, on every card once
/// anything is selected, and always under touch. A long press toggles a
/// card; from the keyboard Space toggles the focused card and Enter opens it.
///
/// [onCardTap] opens a card, and [canOpen] leaves out the rows that have
/// nothing to open yet, such as an upload still on its way.
///
/// [loading]/[empty]/[error] drive the body state ([error] takes precedence,
/// then [loading]). A load that runs past 150ms shows a top progress bar and
/// dims the cards, which take no input until it lands; the first load
/// sketches skeleton cards. An empty result reads "No results" with a "Clear
/// filters" action ([onClearFilters]) while [filtered], and [empty] (by
/// default "Nothing here yet") otherwise.
class CollectionCards<T> extends StatefulWidget {
  final List<T> rows;

  /// Builds a card's content, with the card's context, as
  /// `KanbanBoard.cardBuilder` does. A selected card is filled with
  /// [AdminPalette.tableRowSelected]: set muted secondary text on it — a SKU,
  /// a caption — in [AdminPalette.foregroundMutedOnTint], which reads there
  /// as it does on the surface.
  final Widget Function(BuildContext context, T row) cardBuilder;

  /// Opens a card. The tap is named for what the view draws: a table's
  /// `onRowTap`, a card view's or a board's `onCardTap`.
  final void Function(T row)? onCardTap;

  /// Whether [onCardTap] opens [row]; null opens every row. A card that does
  /// not open is content, not a control: no hand, no hover lift, no Tab stop
  /// and no button for assistive technology. Under a selection its tap still
  /// selects it.
  final bool Function(T row)? canOpen;

  /// Identifies a row across reloads — a record id — so a refetch that
  /// returns fresh objects keeps its selection.
  final Object Function(T row)? rowKey;

  final Set<T>? selected;
  final ValueChanged<Set<T>>? onSelectionChanged;

  final bool loading;
  final Widget? empty;

  /// Whether a search or filter narrows [rows]; see [CollectionCards].
  final bool filtered;
  final VoidCallback? onClearFilters;
  final Widget? error;

  /// Smallest a tile may get before the grid drops a column.
  final double minTileWidth;

  /// Fixed tile height, or null to size each row of tiles to its tallest card.
  final double? tileHeight;

  final double spacing;
  final EdgeInsetsGeometry padding;

  const CollectionCards({
    super.key,
    required this.rows,
    required this.cardBuilder,
    this.onCardTap,
    this.canOpen,
    this.rowKey,
    this.selected,
    this.onSelectionChanged,
    this.loading = false,
    this.empty,
    this.filtered = false,
    this.onClearFilters,
    this.error,
    this.minTileWidth = 240,
    this.tileHeight,
    this.spacing = AdminSpacing.xl,
    this.padding = const EdgeInsets.all(AdminSpacing.xl),
  });

  @override
  State<CollectionCards<T>> createState() => _CollectionCardsState<T>();
}

class _CollectionCardsState<T> extends State<CollectionCards<T>> {
  /// Whether the last pointer on the grid was a finger or a pen; null until
  /// one lands.
  bool? _touch;

  /// Whether the pointer is coarse — the last one was a finger or a pen, or
  /// none has landed on a touch-first platform. The checkboxes then stay up,
  /// as there is no hover to reveal them.
  bool get _coarse => _touch ?? coarsePointerByDefault;

  bool get _selectable =>
      widget.selected != null && widget.onSelectionChanged != null;

  Object? _key(T row) => widget.rowKey == null ? row : widget.rowKey!(row);

  void _toggle(T row, Set<Object?> keys) {
    final key = _key(row);
    final next = <T>{
      for (final r in widget.selected!)
        if (_key(r) != key) r,
      if (!keys.contains(key)) row,
    };
    widget.onSelectionChanged!(next);
  }

  void _onPointerDown(PointerDownEvent event) {
    final coarse = isCoarsePointer(event.kind);
    if (coarse != _touch) setState(() => _touch = coarse);
  }

  int _columns(double available) {
    final inner = available - widget.padding.horizontal + widget.spacing;
    final n = (inner / (widget.minTileWidth + widget.spacing)).floor();
    return n < 1 ? 1 : n;
  }

  double _tileWidth(double available, int cols) {
    final inner = available - widget.padding.horizontal;
    return math.max(0, (inner - widget.spacing * (cols - 1)) / cols);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      child: DelayedLoading(
        loading: widget.loading,
        builder: (context, show) {
          final hasRows = widget.rows.isNotEmpty;
          final Widget body;
          if (widget.error != null) {
            body = Center(child: widget.error!);
          } else if (!hasRows) {
            body = !widget.loading
                ? Center(child: _empty())
                : (show ? _skeleton() : const SizedBox.shrink());
          } else {
            body = _grid();
          }
          final dim = show && hasRows && widget.error == null;
          return Stack(
            children: [
              Positioned.fill(child: body),
              // Stale cards: dimmed, and out of reach until the load lands.
              if (dim)
                Positioned.fill(
                  child: ColoredBox(
                    // token-literal: the veil over stale cards
                    color: context.colors.surface.withValues(alpha: 0.45),
                  ),
                ),
              if (show)
                const PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: TopProgressBar(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() {
    if (widget.filtered) {
      return NoResultsState(onClearFilters: widget.onClearFilters);
    }
    return widget.empty ??
        EmptyState(title: context.adminL10n.collection.nothingHereYet);
  }

  Widget _grid() {
    final selectable = _selectable;
    final keys = selectable
        ? {for (final r in widget.selected!) _key(r)}
        : const <Object?>{};
    final checks = selectable && (keys.isNotEmpty || _coarse);

    Widget tile(int index) {
      final row = widget.rows[index];
      final selected = selectable && keys.contains(_key(row));
      final open = widget.onCardTap;
      final opens = open != null && (widget.canOpen?.call(row) ?? true);
      return _CardTile(
        // Keyed by record, so focus follows a card the list reorders.
        key: widget.rowKey == null ? null : ValueKey(_key(row)),
        index: index,
        selectable: selectable,
        selected: selected,
        showCheck: checks,
        onOpen: opens ? () => open(row) : null,
        onToggle: selectable ? () => _toggle(row, keys) : null,
        child: Builder(builder: (context) => widget.cardBuilder(context, row)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columns(constraints.maxWidth);
        final count = widget.rows.length;
        if (widget.tileHeight case final height?) {
          return GridView.builder(
            padding: widget.padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisExtent: height,
              mainAxisSpacing: widget.spacing,
              crossAxisSpacing: widget.spacing,
            ),
            itemCount: count,
            itemBuilder: (context, i) => tile(i),
          );
        }
        final width = _tileWidth(constraints.maxWidth, cols);
        final rows = (count / cols).ceil();
        return ListView.builder(
          padding: widget.padding,
          itemCount: rows,
          itemBuilder: (context, r) {
            final last = r == rows - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : widget.spacing),
              child: _EqualHeightRow(
                tileWidth: width,
                spacing: widget.spacing,
                children: [
                  for (
                    var i = r * cols;
                    i < math.min(count, (r + 1) * cols);
                    i++
                  )
                    tile(i),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Placeholder cards for a first load: two rows of a cover and two lines.
  Widget _skeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columns(constraints.maxWidth);
        final width = _tileWidth(constraints.maxWidth, cols);
        final radius = context.radii.radiusLarge;
        Widget card() => Container(
          width: width,
          height: widget.tileHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: context.colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tileHeight == null)
                const Skeleton(height: 96, borderRadius: BorderRadius.zero)
              else
                const Expanded(
                  child: Skeleton(
                    height: double.infinity,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: width * 0.6, height: 12),
                    const Gap(AdminSpacing.sm),
                    Skeleton(width: width * 0.35, height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
        return SkeletonGroup(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: widget.padding,
            child: Wrap(
              spacing: widget.spacing,
              runSpacing: widget.spacing,
              children: [for (var i = 0; i < cols * 2; i++) card()],
            ),
          ),
        );
      },
    );
  }
}

class _ToggleIntent extends Intent {
  const _ToggleIntent();
}

class _CardTile extends StatefulWidget {
  /// The row's position on the page, which names its checkbox.
  final int index;
  final bool selectable;
  final bool selected;

  /// Keeps the checkbox up whatever the pointer and focus do.
  final bool showCheck;
  final VoidCallback? onOpen;
  final VoidCallback? onToggle;
  final Widget child;

  const _CardTile({
    super.key,
    required this.index,
    required this.selectable,
    required this.selected,
    required this.showCheck,
    required this.onOpen,
    required this.onToggle,
    required this.child,
  });

  @override
  State<_CardTile> createState() => _CardTileState();
}

/// A Tab stop that Enter opens and Space selects. Its selection checkbox —
/// the next Tab stop — shows under the pointer and while focus is on the card
/// or on it; the card's ring stays off while that checkbox holds focus.
class _CardTileState extends State<_CardTile> {
  /// Holds the card's Tab stop and its checkbox's as siblings: the checkbox
  /// sits inside the card's [Tappable] on screen, but is a Tab stop of its
  /// own, not a second stop on the card.
  final _within = FocusNode(debugLabel: 'card and its checkbox');

  bool _focusWithin = false;

  @override
  void dispose() {
    _within.dispose();
    super.dispose();
  }

  /// Hidden, [child] takes no pointer: a click there opens the card.
  Widget _reveal(bool visible, Widget child) => IgnorePointer(
    ignoring: !visible,
    child: Opacity(
      opacity: visible ? 1 : 0,
      alwaysIncludeSemantics: true,
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radiusLarge;
    final selected = widget.selected;
    final toggle = widget.onToggle;
    final shape = BorderRadius.circular(radius);

    Widget tile = Tappable.states(
      // Without an open action, a tap selects.
      onTap: widget.onOpen ?? toggle,
      selected: widget.selectable ? selected : null,
      showFocusRing: false,
      builder: (context, states) {
        // The lift says a tap does something, so a card with no tap of its
        // own stays flat under the pointer.
        final hovered =
            states.contains(WidgetState.hovered) &&
            (widget.onOpen != null || toggle != null);
        return FocusRing(
          focused: states.contains(WidgetState.focused),
          radius: radius,
          child: AnimatedContainer(
            duration: context.motion.fast,
            curve: context.motion.standard,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: selected ? colors.tableRowSelected : colors.surface,
              borderRadius: shape,
              border: Border.all(
                color: selected
                    ? colors.primary
                    : (hovered ? colors.border : colors.borderSubtle),
              ),
              boxShadow: hovered && !selected ? context.elevation.md : null,
            ),
            // The ring is drawn over the card, inside its edge, so selecting
            // never moves the content.
            foregroundDecoration: selected
                ? BoxDecoration(
                    borderRadius: shape,
                    border: Border.all(
                      color: colors.primary,
                      width: context.stroke.indicator,
                    ),
                  )
                : null,
            child: Stack(
              children: [
                widget.child,
                if (widget.selectable)
                  PositionedDirectional(
                    top: AdminSpacing.md,
                    start: AdminSpacing.md,
                    child: _reveal(
                      widget.showCheck || hovered || selected || _focusWithin,
                      Focus(
                        parentNode: _within,
                        canRequestFocus: false,
                        skipTraversal: true,
                        child: _CheckChip(
                          value: selected,
                          label: context.adminL10n.collection.selectCard(
                            widget.index + 1,
                          ),
                          onChanged: (_) => toggle?.call(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (toggle != null) {
      tile = Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): _ToggleIntent(),
        },
        child: Actions(
          actions: {
            _ToggleIntent: CallbackAction<_ToggleIntent>(
              onInvoke: (_) => toggle(),
            ),
          },
          child: GestureDetector(
            excludeFromSemantics: true,
            onLongPress: toggle,
            child: tile,
          ),
        ),
      );
    }

    return Focus(
      focusNode: _within,
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focusWithin = f),
      child: tile,
    );
  }
}

/// The selection checkbox sits on a small opaque chip so it stays legible over
/// whatever the card paints behind it (a cover image, a colour block). The
/// whole 24px chip is the checkbox — its target, its focus ring and its hover
/// — so it meets the minimum target size the 18px box alone would miss.
class _CheckChip extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;
  const _CheckChip({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radius;
    final changed = onChanged;
    return Tappable.states(
      onTap: changed == null ? null : () => changed(!value),
      checked: value,
      semanticLabel: label,
      focusRadius: radius,
      builder: (context, states) => Container(
        // token-literal: the 18px box inset to the 24px minimum target
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: states.contains(WidgetState.hovered)
              ? Color.alphaBlend(colors.hoverOverlay, colors.surface)
              : colors.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: context.elevation.sm,
        ),
        // Drawn only: the chip is the control.
        child: ExcludeFocus(
          child: ExcludeSemantics(
            child: IgnorePointer(child: Check(value: value, readOnly: true)),
          ),
        ),
      ),
    );
  }
}

/// One run of cards, each [tileWidth] wide and [spacing] apart, stretched to
/// the tallest of them — what a CSS grid row does. Each card is laid out
/// once at its own height to find the tallest, then again at least that
/// tall: not held to it, so a card whose content grows later (a font that
/// lands, an image that sizes it) lays the row out again rather than
/// overflowing the height it had.
class _EqualHeightRow extends MultiChildRenderObjectWidget {
  final double tileWidth;
  final double spacing;

  const _EqualHeightRow({
    required this.tileWidth,
    required this.spacing,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualHeightRow(
        tileWidth: tileWidth,
        spacing: spacing,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEqualHeightRow renderObject,
  ) {
    renderObject
      ..tileWidth = tileWidth
      ..spacing = spacing
      ..textDirection = Directionality.of(context);
  }
}

class _RowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowParentData> {
  _RenderEqualHeightRow({
    required this._tileWidth,
    required this._spacing,
    required this._textDirection,
  });

  double _tileWidth;
  set tileWidth(double value) {
    if (value == _tileWidth) return;
    _tileWidth = value;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowParentData) {
      child.parentData = _RowParentData();
    }
  }

  double get _contentWidth => childCount == 0
      ? 0
      : childCount * _tileWidth + (childCount - 1) * _spacing;

  double _tallest(double Function(RenderBox child) height) {
    var tallest = 0.0;
    var child = firstChild;
    while (child != null) {
      tallest = math.max(tallest, height(child));
      child = childAfter(child);
    }
    return tallest;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _contentWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _contentWidth;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallest((c) => c.getMinIntrinsicHeight(_tileWidth));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallest((c) => c.getMaxIntrinsicHeight(_tileWidth));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final height = _tallest(
      (c) => c.getDryLayout(BoxConstraints.tightFor(width: _tileWidth)).height,
    );
    return constraints.constrain(Size(_width(constraints), height));
  }

  double _width(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : constraints.constrainWidth(_contentWidth);

  @override
  void performLayout() {
    final natural = BoxConstraints.tightFor(width: _tileWidth);
    final height = constraints.constrainHeight(
      _tallest((c) {
        c.layout(natural, parentUsesSize: true);
        return c.size.height;
      }),
    );
    final width = _width(constraints);
    final rtl = _textDirection == TextDirection.rtl;
    var x = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(
        BoxConstraints(
          minWidth: _tileWidth,
          maxWidth: _tileWidth,
          minHeight: height,
        ),
        parentUsesSize: true,
      );
      final data = child.parentData! as _RowParentData;
      data.offset = Offset(rtl ? width - x - _tileWidth : x, 0);
      x += _tileWidth + _spacing;
      child = data.nextSibling;
    }
    size = constraints.constrain(Size(width, height));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
