import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'focus_ring.dart';
import 'icon_action.dart';

/// A node in a [Tree]. Structure only — the row's content is drawn by the
/// tree's `itemBuilder`, keyed by [id]; the caller owns the payload.
class TreeNode {
  final String id;
  final List<TreeNode> children;

  const TreeNode({required this.id, this.children = const []});
}

/// A flattened, depth-tagged view of one visible node. Public so the projection
/// helpers can be unit-tested.
@immutable
class TreeFlatNode {
  final String id;
  final int depth;
  final String? parentId;
  final bool hasChildren;
  final bool expanded;

  const TreeFlatNode({
    required this.id,
    required this.depth,
    required this.parentId,
    required this.hasChildren,
    required this.expanded,
  });
}

/// Where a drag would land: the gap [index] in the working list, the projected
/// [depth], and the resolved drop target ([parentId] + [childIndex] among that
/// parent's children).
@immutable
class TreeDrop {
  final int index;
  final int depth;
  final String? parentId;
  final int childIndex;

  const TreeDrop({
    required this.index,
    required this.depth,
    required this.parentId,
    required this.childIndex,
  });
}

/// Depth-first flatten of [roots] into visible rows, skipping the children of
/// any node in [collapsed].
List<TreeFlatNode> flattenTree(
  List<TreeNode> roots, {
  Set<String> collapsed = const {},
}) {
  final out = <TreeFlatNode>[];
  void walk(List<TreeNode> nodes, int depth, String? parent) {
    for (final n in nodes) {
      final hasChildren = n.children.isNotEmpty;
      final expanded = !collapsed.contains(n.id);
      out.add(
        TreeFlatNode(
          id: n.id,
          depth: depth,
          parentId: parent,
          hasChildren: hasChildren,
          expanded: expanded,
        ),
      );
      if (hasChildren && expanded) walk(n.children, depth + 1, n.id);
    }
  }

  walk(roots, 0, null);
  return out;
}

/// Removes [id] and its whole subtree from a flattened list — the working list a
/// drag projects against (so a node can never drop inside itself).
List<TreeFlatNode> excludeSubtree(List<TreeFlatNode> flat, String id) {
  final i = flat.indexWhere((f) => f.id == id);
  if (i < 0) return List.of(flat);
  final depth = flat[i].depth;
  var j = i + 1;
  while (j < flat.length && flat[j].depth > depth) {
    j++;
  }
  return [...flat.take(i), ...flat.skip(j)];
}

/// Projects a drag to a concrete drop, porting the dnd-kit sortable-tree
/// algorithm: the gap is [overIndex] in [working] (which must already exclude
/// the dragged subtree), [rawDepth] is the depth the pointer's horizontal offset
/// suggests, clamped to what the neighbours allow and to [maxDepth].
TreeDrop projectTreeDrop(
  List<TreeFlatNode> working,
  int overIndex,
  int rawDepth, {
  int? maxDepth,
}) {
  final i = overIndex.clamp(0, working.length);
  final prev = i > 0 ? working[i - 1] : null;
  final next = i < working.length ? working[i] : null;

  final maxAllowed = prev == null ? 0 : prev.depth + 1;
  final minAllowed = next == null ? 0 : next.depth;
  var depth = rawDepth;
  if (depth > maxAllowed) depth = maxAllowed;
  if (depth < minAllowed) depth = minAllowed;
  if (maxDepth != null && depth > maxDepth) {
    depth = maxDepth < minAllowed ? minAllowed : maxDepth;
  }

  String? parentId;
  if (depth == 0 || prev == null) {
    parentId = null;
  } else if (depth == prev.depth) {
    parentId = prev.parentId;
  } else if (depth > prev.depth) {
    parentId = prev.id;
  } else {
    parentId = null;
    for (final f in working.take(i).toList().reversed) {
      if (f.depth == depth) {
        parentId = f.parentId;
        break;
      }
    }
  }

  final childIndex = working
      .take(i)
      .where((f) => f.parentId == parentId)
      .length;
  return TreeDrop(
    index: i,
    depth: depth,
    parentId: parentId,
    childIndex: childIndex,
  );
}

/// Per-row state handed to a [Tree]'s `itemBuilder`.
@immutable
class TreeRowInfo {
  final int depth;
  final bool hasChildren;
  final bool expanded;

  /// This row is the one currently being dragged (the floating avatar).
  final bool dragging;

  /// Descendants riding along under a dragged parent (0 unless [dragging]).
  final int subtreeCount;

  const TreeRowInfo({
    required this.depth,
    required this.hasChildren,
    required this.expanded,
    this.dragging = false,
    this.subtreeCount = 0,
  });
}

typedef TreeRowBuilder = Widget Function(
  BuildContext context,
  String id,
  TreeRowInfo info,
);

/// A generic, View-pure hierarchy editor: faint indent guide rails,
/// expand/collapse carets, and indent-based drag that reorders **and**
/// re-parents in one gesture (a drop indicator shows the projected position +
/// depth; a collapsed parent auto-expands when hovered mid-drag). Rows are a
/// fixed [rowHeight]; their content is drawn by [itemBuilder], keyed by node id.
/// The tree owns no data — it emits [onMove] (`id → newParentId @ index`);
/// collapse state is internal. A null [onMove] makes it read-only (no drag
/// handles).
///
/// Right to left the tree mirrors: rows indent from the right, the guide
/// rails run down the right-hand gutter, and a drag toward the left nests.
///
/// With animations disabled (reduced motion) rows, carets and the drop slot
/// move at once instead of sliding.
class Tree extends StatefulWidget {
  final List<TreeNode> roots;
  final TreeRowBuilder itemBuilder;

  /// Shown when [roots] is empty (centered in a short box). Null renders nothing.
  final Widget? empty;

  /// Caps the tree's height. Below it the tree shrink-wraps its rows; past it the
  /// rows scroll internally and a drag near an edge auto-scrolls. Null = no cap
  /// (the tree is as tall as its content and relies on an outer scrollable).
  final double? maxHeight;

  /// Called when a drag commits: move the node `id` under `newParentId` (null
  /// = root) at `index` among that parent's children.
  final void Function(String id, String? newParentId, int index)? onMove;

  final double rowHeight;
  final double indent;

  /// Deepest allowed nesting level (0-based). Null = unlimited.
  final int? maxDepth;

  /// Nodes collapsed on first build.
  final Set<String> initiallyCollapsed;

  /// Observe expand/collapse toggles.
  final ValueChanged<String>? onToggle;

  /// The node whose inline editor panel is open beneath it, or null. Its
  /// [expansionBuilder] is measured and the rows below it are pushed down by
  /// that height (an accordion in place, not a fixed-height row). Suppressed
  /// during a drag — reordering happens against uniform rows.
  final String? expandedId;

  /// Builds the variable-height panel rendered under [expandedId]. Null (or a
  /// null [expandedId]) means no inline panel.
  final Widget Function(BuildContext context, String id)? expansionBuilder;

  const Tree({
    super.key,
    required this.roots,
    required this.itemBuilder,
    this.empty,
    this.onMove,
    this.rowHeight = 44,
    this.indent = 28,
    this.maxDepth,
    this.maxHeight,
    this.initiallyCollapsed = const {},
    this.onToggle,
    this.expandedId,
    this.expansionBuilder,
  });

  @override
  State<Tree> createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  final _stackKey = GlobalKey();
  final _viewportKey = GlobalKey();
  final _scroll = ScrollController();
  late final Set<String> _collapsed = {...widget.initiallyCollapsed};

  String? _dragId;
  // Measured height of the open inline panel; rows below the expanded one are
  // pushed down by it. Kept across an [expandedId] switch (re-measured next
  // frame) so the panel resizes smoothly rather than collapsing to zero first.
  double _expandedHeight = 0;
  int _dragOriginDepth = 0;
  double _startX = 0;
  double _pointerX = 0;
  double _pointerY = 0;
  Offset _pointerGlobal = Offset.zero;

  String? _expandCandidate;
  Timer? _expandTimer;
  Timer? _scrollTimer;
  // The scrollable auto-scroll drives during a drag: the internal viewport when
  // height-capped, otherwise the nearest enclosing vertical scrollable.
  ScrollableState? _outerScrollable;

  /// The caret's and the drag handle's cells: the smallest target an icon
  /// action takes.
  static final _caretWidth = IconActionSize.inline.box;
  static final _handleWidth = IconActionSize.inline.box;
  static const _autoExpandDelay = Duration(milliseconds: 600);
  // Edge band that triggers auto-scroll, and the max pixels nudged per tick.
  static const _autoScrollBand = 48.0;
  static const _autoScrollMaxStep = 14.0;

  @override
  void didUpdateWidget(Tree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.roots, widget.roots) || _collapsed.isEmpty) return;
    // A row on screen stays on screen when a move — a drop, a keyboard
    // indent — puts it under a collapsed parent: that parent opens.
    final shown = flattenTree(oldWidget.roots, collapsed: _collapsed);
    final parents = <String, String?>{};
    void walk(List<TreeNode> nodes, String? parent) {
      for (final n in nodes) {
        parents[n.id] = parent;
        walk(n.children, n.id);
      }
    }

    walk(widget.roots, null);
    for (final row in shown) {
      for (var p = parents[row.id]; p != null; p = parents[p]) {
        _collapsed.remove(p);
      }
    }
  }

  @override
  void dispose() {
    _expandTimer?.cancel();
    _scrollTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_collapsed.remove(id)) _collapsed.add(id);
    });
    widget.onToggle?.call(id);
  }

  Offset _toLocal(Offset global) {
    final box = _stackKey.currentContext!.findRenderObject() as RenderBox;
    return box.globalToLocal(global);
  }

  void _onDragStart(TreeFlatNode node, DragStartDetails d) {
    final local = _toLocal(d.globalPosition);
    setState(() {
      _dragId = node.id;
      _dragOriginDepth = node.depth;
      _startX = local.dx;
      _pointerX = local.dx;
      _pointerY = local.dy;
      _pointerGlobal = d.globalPosition;
    });
    _outerScrollable = widget.maxHeight == null
        ? Scrollable.maybeOf(context, axis: Axis.vertical)
        : null;
    if (widget.maxHeight != null || _outerScrollable != null) {
      _scrollTimer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => _autoScrollTick(),
      );
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final local = _toLocal(d.globalPosition);
    setState(() {
      _pointerX = local.dx;
      _pointerY = local.dy;
      _pointerGlobal = d.globalPosition;
    });
    _armAutoExpand();
  }

  /// While dragging, a pointer parked near the top or bottom edge of the active
  /// scrollable (the internal viewport when height-capped, else the enclosing
  /// page scrollable) scrolls it; the pointer's stack-local Y is re-read so the
  /// drop keeps tracking the row sliding under it.
  void _autoScrollTick() {
    if (_dragId == null) return;
    final (position, box) = _autoScrollTarget();
    if (position == null || box == null || !position.hasContentDimensions) {
      return;
    }
    final y = box.globalToLocal(_pointerGlobal).dy;
    final h = box.size.height;

    double delta = 0;
    if (y < _autoScrollBand) {
      delta = -_autoScrollMaxStep * (1 - (y / _autoScrollBand).clamp(0.0, 1.0));
    } else if (y > h - _autoScrollBand) {
      delta =
          _autoScrollMaxStep *
          (1 - ((h - y) / _autoScrollBand).clamp(0.0, 1.0));
    }
    if (delta == 0) return;

    final target = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    position.jumpTo(target);
    setState(() => _pointerY = _toLocal(_pointerGlobal).dy);
    _armAutoExpand();
  }

  (ScrollPosition?, RenderBox?) _autoScrollTarget() {
    if (widget.maxHeight != null) {
      if (!_scroll.hasClients) return (null, null);
      return (
        _scroll.position,
        _viewportKey.currentContext?.findRenderObject() as RenderBox?,
      );
    }
    final s = _outerScrollable;
    if (s == null) return (null, null);
    return (s.position, s.context.findRenderObject() as RenderBox?);
  }

  /// While dragging, dwelling over a collapsed parent expands it so its children
  /// become reachable drop targets.
  void _armAutoExpand() {
    if (_dragId == null) return;
    final working = excludeSubtree(
      flattenTree(widget.roots, collapsed: _collapsed),
      _dragId!,
    );
    final row = (_pointerY / widget.rowHeight).floor();
    final hovered = row >= 0 && row < working.length ? working[row] : null;
    final candidate =
        hovered != null && hovered.hasChildren && !hovered.expanded
        ? hovered.id
        : null;

    if (candidate == _expandCandidate) return;
    _expandCandidate = candidate;
    _expandTimer?.cancel();
    if (candidate == null) return;
    _expandTimer = Timer(_autoExpandDelay, () {
      if (_dragId == null || _expandCandidate != candidate) return;
      setState(() => _collapsed.remove(candidate));
      _expandCandidate = null;
    });
  }

  void _stopAutoExpand() {
    _expandTimer?.cancel();
    _expandCandidate = null;
  }

  void _endDrag() {
    _stopAutoExpand();
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _outerScrollable = null;
  }

  void _onDragEnd(List<TreeFlatNode> working) {
    final drop = _currentDrop(working);
    final id = _dragId;
    _endDrag();
    setState(() {
      _dragId = null;
    });
    if (id != null && drop != null) {
      widget.onMove?.call(id, drop.parentId, drop.childIndex);
    }
  }

  void _cancelDrag() {
    _endDrag();
    setState(() => _dragId = null);
  }

  TreeDrop? _currentDrop(List<TreeFlatNode> working) {
    if (_dragId == null) return null;
    final overIndex = (_pointerY / widget.rowHeight).round().clamp(
      0,
      working.length,
    );
    // Toward the end edge nests deeper: rightward, or leftward right to left.
    final inward = Directionality.of(context) == TextDirection.rtl
        ? _startX - _pointerX
        : _pointerX - _startX;
    final rawDepth = _dragOriginDepth + (inward / widget.indent).round();
    return projectTreeDrop(
      working,
      overIndex,
      rawDepth,
      maxDepth: widget.maxDepth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = flattenTree(widget.roots, collapsed: _collapsed);
    if (all.isEmpty) {
      return SizedBox(
        height: widget.rowHeight * 2,
        child: Center(child: widget.empty ?? const SizedBox.shrink()),
      );
    }

    final dragging = _dragId != null;
    // Flow rows = the tree minus the dragged subtree; the dragged row stays
    // mounted (see _floatingRow) so its drag gesture isn't cancelled mid-drag.
    final ordered = dragging ? excludeSubtree(all, _dragId!) : all;
    final drop = dragging ? _currentDrop(ordered) : null;
    // Descendants travelling under the dragged parent (excludeSubtree drops the
    // node itself plus its subtree).
    final carried = dragging ? all.length - ordered.length - 1 : 0;

    // The open inline panel (none while dragging — rows stay uniform so the drag
    // projection math holds). Rows after [expandedIndex] are pushed down by the
    // measured panel height [extra].
    final expandedIndex =
        (!dragging &&
            widget.expandedId != null &&
            widget.expansionBuilder != null)
        ? ordered.indexWhere((f) => f.id == widget.expandedId)
        : -1;
    final expanded = expandedIndex >= 0;
    final extra = expanded ? _expandedHeight : 0.0;
    double rowTop(int i) =>
        i * widget.rowHeight + (expanded && i > expandedIndex ? extra : 0);

    final height = all.length * widget.rowHeight + extra;
    final maxTop = ((all.length - 1) * widget.rowHeight).clamp(
      0.0,
      double.infinity,
    );

    final motion = context.motion;
    final content = SizedBox(
      height: height,
      child: Stack(
        key: _stackKey,
        children: [
          if (!dragging)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GuidePainter(
                    rows: ordered,
                    rowHeight: widget.rowHeight,
                    indent: widget.indent,
                    railX: _caretWidth / 2,
                    color: context.colors.borderSubtle,
                    textDirection: Directionality.of(context),
                    expandedIndex: expandedIndex,
                    extra: extra,
                  ),
                ),
              ),
            ),
          for (var i = 0; i < ordered.length; i++)
            AnimatedPositionedDirectional(
              key: ValueKey('tree-row-${ordered[i].id}'),
              duration: motion.medium,
              curve: motion.standard,
              // Open a one-row gap at the projected drop so siblings slide to
              // make room instead of snapping into the vacated slot.
              top:
                  rowTop(i) +
                  (drop != null && i >= drop.index ? widget.rowHeight : 0),
              start: ordered[i].depth * widget.indent,
              end: 0,
              child: _row(context, ordered[i], floating: false),
            ),
          if (expanded) _expansion(context, expandedIndex),
          if (drop != null) _slot(context, drop),
          if (dragging) _floatingRow(context, all, drop, maxTop, carried),
        ],
      ),
    );

    if (widget.maxHeight == null) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight!),
      child: SingleChildScrollView(
        key: _viewportKey,
        controller: _scroll,
        // A drag lives outside the scrollable's gesture arena, but a parked
        // pointer shouldn't let the list fling — auto-scroll drives it instead.
        physics: dragging ? const NeverScrollableScrollPhysics() : null,
        child: content,
      ),
    );
  }

  /// The dragged row — kept in the widget tree (same key as its flow row) so the
  /// in-flight pan gesture survives, but repositioned under the pointer at the
  /// projected depth, lifted with a shadow.
  Widget _floatingRow(
    BuildContext context,
    List<TreeFlatNode> all,
    TreeDrop? drop,
    double maxTop,
    int carried,
  ) {
    final node = all.firstWhere((f) => f.id == _dragId);
    return AnimatedPositionedDirectional(
      key: ValueKey('tree-row-${node.id}'),
      duration: Duration.zero,
      top: (_pointerY - widget.rowHeight / 2).clamp(0.0, maxTop),
      start: (drop?.depth ?? node.depth) * widget.indent,
      end: 0,
      child: _row(context, node, floating: true, subtreeCount: carried),
    );
  }

  Widget _row(
    BuildContext context,
    TreeFlatNode node, {
    required bool floating,
    int subtreeCount = 0,
  }) {
    final canDrag = widget.onMove != null;
    final content = Row(
      children: [
        SizedBox(
          width: _caretWidth,
          child: node.hasChildren ? _caret(context, node) : null,
        ),
        if (canDrag)
          _DragHandle(
            width: _handleWidth,
            onStart: (d) => _onDragStart(node, d),
            onUpdate: _onDragUpdate,
            onEnd: (_) {
              final all = flattenTree(widget.roots, collapsed: _collapsed);
              _onDragEnd(excludeSubtree(all, node.id));
            },
            onCancel: _cancelDrag,
          )
        else
          SizedBox(width: _handleWidth),
        Expanded(
          child: widget.itemBuilder(
            context,
            node.id,
            TreeRowInfo(
              depth: node.depth,
              hasChildren: node.hasChildren,
              expanded: node.expanded,
              dragging: floating,
              subtreeCount: subtreeCount,
            ),
          ),
        ),
        if (floating && subtreeCount > 0) _carriedBadge(context, subtreeCount),
      ],
    );

    // The flow and floating rows MUST share one widget structure, or switching
    // between them on pickup rebuilds the drag handle's GestureDetector and
    // cancels the in-flight pan. Only the decoration toggles.
    return SizedBox(
      height: widget.rowHeight,
      child: Material(
        elevation: floating ? 6 : 0,
        color: floating
            ? Color.alphaBlend(
                context.colors.draggedOverlay,
                context.colors.surface,
              )
            : Colors.transparent,
        borderRadius: BorderRadius.circular(context.radii.radius),
        // token-literal: the lifted row's shadow
        shadowColor: context.colors.shadow.withValues(alpha: 0.2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.radii.radius),
            border: floating
                ? Border.all(
                    // token-literal: the lifted row's edge
                    color: context.colors.primary.withValues(alpha: 0.4),
                  )
                : null,
          ),
          child: content,
        ),
      ),
    );
  }

  /// "+N" pill on a dragged parent, signalling the descendants it carries.
  Widget _carriedBadge(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AdminSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.sm,
          vertical: AdminSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: context.colors.statusFill(context.colors.primary),
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        ),
        child: Text(
          '+${context.adminFormats.integer(count)}',
          style: context.type.micro.copyWith(color: context.colors.primaryText),
        ),
      ),
    );
  }

  Widget _caret(BuildContext context, TreeFlatNode node) => _Caret(
    expanded: node.expanded,
    size: _caretWidth,
    onTap: () => _toggle(node.id),
  );

  /// The open inline panel, slotted into the gap beneath row [index]. Its height
  /// is measured (variable content) and fed back so the rows below it offset by
  /// the right amount; it slides with the row when the expanded node changes.
  Widget _expansion(BuildContext context, int index) {
    return AnimatedPositioned(
      key: const ValueKey('tree-expansion'),
      duration: context.motion.medium,
      curve: context.motion.standard,
      top: (index + 1) * widget.rowHeight,
      left: 0,
      right: 0,
      child: _MeasureSize(
        onChange: (size) {
          if (size.height == _expandedHeight) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _expandedHeight = size.height);
          });
        },
        child: widget.expansionBuilder!(context, widget.expandedId!),
      ),
    );
  }

  /// The reserved landing slot — a depth-indented outline at the gap the rows
  /// have opened. Animates as the projected position / depth changes.
  Widget _slot(BuildContext context, TreeDrop drop) {
    return AnimatedPositionedDirectional(
      key: const ValueKey('tree-drop-slot'),
      duration: context.motion.fast,
      curve: context.motion.standard,
      top: drop.index * widget.rowHeight,
      start: drop.depth * widget.indent,
      end: 0,
      height: widget.rowHeight,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxs),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(
                alpha: context.colors.stateLayer.tintHover,
              ),
              borderRadius: BorderRadius.circular(context.radii.radius),
              border: Border.all(
                // token-literal: the landing slot's edge, a soft primary
                color: context.colors.primary.withValues(alpha: 0.6),
                width: context.stroke.controlStrong,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints faint vertical rails in the indentation gutter — one per ancestor
/// level — so nesting reads at a glance. Each row at depth `d` gets rails at the
/// caret column of depths `0..d-1`; consecutive same-depth rows make them
/// continuous. [railX] and the indents count from the start edge, the right
/// one right to left.
class _GuidePainter extends CustomPainter {
  final List<TreeFlatNode> rows;
  final double rowHeight;
  final double indent;
  final double railX;
  final Color color;
  final TextDirection textDirection;

  /// Rows past [expandedIndex] are shifted down by [extra] (the open inline
  /// panel's height) so the rails line up with the offset rows.
  final int expandedIndex;
  final double extra;

  _GuidePainter({
    required this.rows,
    required this.rowHeight,
    required this.indent,
    required this.railX,
    required this.color,
    required this.textDirection,
    this.expandedIndex = -1,
    this.extra = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final rtl = textDirection == TextDirection.rtl;
    for (var i = 0; i < rows.length; i++) {
      final top =
          i * rowHeight + (expandedIndex >= 0 && i > expandedIndex ? extra : 0);
      for (var d = 0; d < rows[i].depth; d++) {
        final start = d * indent + railX;
        final x = rtl ? size.width - start : start;
        canvas.drawLine(Offset(x, top), Offset(x, top + rowHeight), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.rows != rows ||
      old.rowHeight != rowHeight ||
      old.indent != indent ||
      old.color != color ||
      old.textDirection != textDirection ||
      old.expandedIndex != expandedIndex ||
      old.extra != extra;
}

/// Reports its child's measured size after layout — used to feed the open inline
/// panel's intrinsic height back so the tree can offset the rows beneath it.
class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.onChange, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRender(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRender renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRender extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _old;

  _MeasureSizeRender(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final size = child?.size ?? Size.zero;
    if (size != _old) {
      _old = size;
      onChange(size);
    }
  }
}

/// The expand / collapse chevron: the whole cell is the hit target, and
/// keyboard focus rings the [size] square around the glyph.
class _Caret extends StatefulWidget {
  final bool expanded;
  final double size;
  final VoidCallback onTap;

  const _Caret({
    required this.expanded,
    required this.size,
    required this.onTap,
  });

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      mouseCursor: WidgetStateMouseCursor.clickable,
      borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      focusColor: Colors.transparent,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: Center(
        child: FocusRing(
          focused: _focused,
          radius: context.radii.radiusSmall,
          child: SizedBox.square(
            dimension: widget.size,
            child: Center(
              // The chevron points along the reading direction, and turns
              // down toward the children either way.
              child: AnimatedRotation(
                turns: !widget.expanded
                    ? 0
                    : Directionality.of(context) == TextDirection.rtl
                    ? -0.25
                    : 0.25,
                duration: context.motion.fast,
                curve: context.motion.standard,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: context.iconSizes.md,
                  color: context.colors.foregroundMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final double width;
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final VoidCallback onCancel;

  const _DragHandle({
    required this.width,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // An immediate multi-drag recognizer claims the pointer eagerly, so the drag
    // beats any enclosing scrollable (the page list, or the tree's own viewport)
    // for the vertical gesture instead of losing it to a scroll.
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          ImmediateMultiDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                ImmediateMultiDragGestureRecognizer
              >(
                () => ImmediateMultiDragGestureRecognizer(),
                (ImmediateMultiDragGestureRecognizer r) => r.onStart = _start,
              ),
        },
        child: SizedBox(
          width: width,
          child: Icon(
            Icons.drag_indicator_rounded,
            size: context.iconSizes.md,
            color: context.colors.foregroundMuted,
          ),
        ),
      ),
    );
  }

  Drag _start(Offset position) {
    onStart(DragStartDetails(globalPosition: position));
    return _HandleDrag(onUpdate: onUpdate, onEnd: onEnd, onCancel: onCancel);
  }
}

/// Adapts a [MultiDragGestureRecognizer] pointer stream onto the tree's
/// pan-style drag callbacks.
class _HandleDrag implements Drag {
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final VoidCallback onCancel;

  _HandleDrag({
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onEnd(details);

  @override
  void cancel() => onCancel();
}
