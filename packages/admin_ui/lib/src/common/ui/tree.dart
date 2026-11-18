/// @docImport 'tree_editor.dart';
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/shortcut_label.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'focus_ring.dart';
import 'icon_action.dart';
import 'menu.dart';
import 'menu_button.dart';

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

/// The moves a key or a menu makes on one row of a [Tree], each a call to
/// [Tree.onMove]: one place [up] or [down] among its siblings, [indent] to
/// the end of the sibling above it, [outdent] to just after its parent. A
/// null move is not open to the row: the first of its siblings has no [up]
/// and no [indent], a root no [outdent], and [Tree.maxDepth] stops an
/// [indent] that would take the row or anything under it past it.
@immutable
class TreeRowMoves {
  final VoidCallback? up;
  final VoidCallback? down;
  final VoidCallback? indent;
  final VoidCallback? outdent;

  const TreeRowMoves({this.up, this.down, this.indent, this.outdent});
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

  /// The moves open to the row without a drag, null in a tree with no
  /// [Tree.onMove]. The tree binds them to its keys and lists them in the
  /// row's menu itself; a row that is a control of its own
  /// ([Tree.rowControls] false) offers them from here.
  final TreeRowMoves? moves;

  const TreeRowInfo({
    required this.depth,
    required this.hasChildren,
    required this.expanded,
    this.dragging = false,
    this.subtreeCount = 0,
    this.moves,
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
///
/// **Keyboard.** The tree is one Tab stop: the row that held focus last, or
/// the first. ↑ and ↓ move between the rows on screen and Home and End go
/// to the first and the last. → opens a closed parent, and on an open one
/// goes to its first child; ← closes an open parent, and on any other row
/// goes to its parent; Enter or Space opens or closes a parent. Right to
/// left, → and ← trade places. Tab goes on from the focused row to the
/// controls inside it, then out of the tree.
///
/// With [onMove], Alt+↑ and Alt+↓ move the focused row one place among its
/// siblings, Alt+→ nests it under the sibling above and Alt+← takes it out
/// beside its parent (Alt+← nests right to left), and each row ends in a ⋯
/// menu of the same four moves, each beside its key: a move never needs a
/// drag. Focus stays on the moved row, and a screen reader hears where it
/// went.
///
/// A caret is a button named "Expand" or "Collapse" that carries its row's
/// expanded state, as the focused row does.
///
/// [rowControls] false leaves the keyboard and the menu to rows that are
/// controls of their own, as [TreeEditor]'s are.
class Tree extends StatefulWidget {
  final List<TreeNode> roots;
  final TreeRowBuilder itemBuilder;

  /// Shown when [roots] is empty (centered in a short box). Null renders nothing.
  final Widget? empty;

  /// Caps the tree's height. Below it the tree shrink-wraps its rows; past it the
  /// rows scroll internally and a drag near an edge auto-scrolls. Null = no cap
  /// (the tree is as tall as its content and relies on an outer scrollable).
  final double? maxHeight;

  /// Called when a drag, a move key or an item of a row's menu commits: move
  /// the node `id` under `newParentId` (null = root) at `index` among that
  /// parent's children.
  final void Function(String id, String? newParentId, int index)? onMove;

  /// Whether the tree operates its rows itself: one Tab stop with the arrow
  /// keys between its rows and, with [onMove], the move keys and a ⋯ menu
  /// at the end of each row. See [Tree].
  ///
  /// False where each row is a control of the caller's own, a Tab stop that
  /// offers its [TreeRowInfo.moves] itself as a [TreeEditor] row does, so
  /// that nothing is offered twice: the tree then adds no Tab stop, key or
  /// menu to a row, and each caret is a Tab stop.
  final bool rowControls;

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
    this.rowControls = true,
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

  /// The focus node of each row on screen, by node id, which each row
  /// registers while it is mounted; with [Tree.rowControls].
  final _rowNodes = <String, FocusNode>{};

  /// The row that is the tree's Tab stop: the one that held focus last. The
  /// first row stands in while it is null or off screen.
  String? _current;

  /// Where each node of [_placedRoots] sits among its siblings.
  Map<String, _Place> _places = const {};
  List<TreeNode>? _placedRoots;

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
    final closing = !_collapsed.contains(id);
    if (widget.rowControls) {
      // A row about to go from under the focus hands it to the parent that
      // closes over it.
      final focused = _focusedRow;
      if (closing && focused != null && _isUnder(focused, id)) {
        _rowNodes[id]?.requestFocus();
      }
      _current = id;
    }
    setState(() {
      if (!_collapsed.remove(id)) _collapsed.add(id);
    });
    widget.onToggle?.call(id);
  }

  /// The row that holds focus, itself or through a control inside it.
  String? get _focusedRow {
    for (final MapEntry(key: id, value: node) in _rowNodes.entries) {
      if (node.hasFocus) return id;
    }
    return null;
  }

  Map<String, _Place> get _placeOf {
    if (!identical(_placedRoots, widget.roots)) {
      final places = <String, _Place>{};
      void walk(List<TreeNode> nodes, String? parent) {
        for (final (index, node) in nodes.indexed) {
          places[node.id] = _Place(node, parent, nodes, index);
          walk(node.children, node.id);
        }
      }

      walk(widget.roots, null);
      _places = places;
      _placedRoots = widget.roots;
    }
    return _places;
  }

  /// Whether [id] sits somewhere under [ancestor].
  bool _isUnder(String id, String ancestor) {
    final places = _placeOf;
    for (var p = places[id]?.parentId; p != null; p = places[p]?.parentId) {
      if (p == ancestor) return true;
    }
    return false;
  }

  /// Levels under [node]: 0 for a leaf.
  static int _heightOf(TreeNode node) {
    var height = 0;
    for (final child in node.children) {
      height = math.max(height, _heightOf(child) + 1);
    }
    return height;
  }

  /// The moves open to the row [id] at [depth] without a drag; see
  /// [TreeRowMoves].
  TreeRowMoves? _movesOf(String id, int depth) {
    final onMove = widget.onMove;
    final place = _placeOf[id];
    if (onMove == null || place == null) return null;
    final _Place(:node, :parentId, :siblings, :index) = place;
    final maxDepth = widget.maxDepth;

    VoidCallback? indent;
    if (index > 0 &&
        (maxDepth == null || depth + 1 + _heightOf(node) <= maxDepth)) {
      final above = siblings[index - 1];
      indent = () => onMove(id, above.id, above.children.length);
    }
    VoidCallback? outdent;
    if (_placeOf[parentId] case final parent?) {
      outdent = () => onMove(id, parent.parentId, parent.index + 1);
    }
    return TreeRowMoves(
      up: index > 0 ? () => onMove(id, parentId, index - 1) : null,
      down: index < siblings.length - 1
          ? () => onMove(id, parentId, index + 1)
          : null,
      indent: indent,
      outdent: outdent,
    );
  }

  /// [move], then [done] said to a screen reader: focus stays on the row,
  /// which says nothing of where it went.
  VoidCallback? _announced(VoidCallback? move, String done) {
    if (move == null) return null;
    return () {
      move();
      SemanticsService.sendAnnouncement(
        View.of(context),
        done,
        Directionality.of(context),
      );
    };
  }

  /// Gives the row [id] the focus, and scrolls it into view.
  void _focusRow(String id) {
    final node = _rowNodes[id];
    if (node == null) return;
    node.requestFocus();
    final row = node.context;
    if (row == null) return;
    for (final policy in const [
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    ]) {
      Scrollable.ensureVisible(row, alignmentPolicy: policy);
    }
  }

  static const _upKey = SingleActivator(LogicalKeyboardKey.arrowUp, alt: true);
  static const _downKey = SingleActivator(
    LogicalKeyboardKey.arrowDown,
    alt: true,
  );

  /// The arrow toward the end edge, where a row's children are and where
  /// nesting deeper moves it: → left to right, ← right to left.
  static LogicalKeyboardKey _inward(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
      ? LogicalKeyboardKey.arrowLeft
      : LogicalKeyboardKey.arrowRight;

  static LogicalKeyboardKey _outward(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
      ? LogicalKeyboardKey.arrowRight
      : LogicalKeyboardKey.arrowLeft;

  /// The tree's keys on the row [id], while the row itself holds the focus:
  /// a control inside it keeps its own.
  KeyEventResult _onRowKey(String id, FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final rows = flattenTree(widget.roots, collapsed: _collapsed);
    final index = rows.indexWhere((row) => row.id == id);
    if (index < 0) return KeyEventResult.ignored;
    final row = rows[index];
    final key = event.logicalKey;
    final inward = key == _inward(context);
    final outward = key == _outward(context);

    if (keyboard.isAltPressed) {
      final moves = _movesOf(id, row.depth);
      if (moves == null) return KeyEventResult.ignored;
      final strings = context.adminL10n.display;
      final VoidCallback? move;
      if (key == LogicalKeyboardKey.arrowUp) {
        move = _announced(moves.up, strings.rowMovedUp);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        move = _announced(moves.down, strings.rowMovedDown);
      } else if (inward) {
        move = _announced(moves.indent, strings.rowIndented);
      } else if (outward) {
        move = _announced(moves.outdent, strings.rowOutdented);
      } else {
        return KeyEventResult.ignored;
      }
      // A move the row cannot make is still the tree's key: Alt+← must not
      // go on to take a browser back a page.
      move?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (index + 1 < rows.length) _focusRow(rows[index + 1].id);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) _focusRow(rows[index - 1].id);
    } else if (key == LogicalKeyboardKey.home) {
      _focusRow(rows.first.id);
    } else if (key == LogicalKeyboardKey.end) {
      _focusRow(rows.last.id);
    } else if (inward) {
      if (row.hasChildren && !row.expanded) {
        _toggle(id);
      } else if (row.hasChildren) {
        _focusRow(rows[index + 1].id);
      }
    } else if (outward) {
      if (row.hasChildren && row.expanded) {
        _toggle(id);
      } else if (row.parentId case final parent?) {
        _focusRow(parent);
      }
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (!row.hasChildren) return KeyEventResult.ignored;
      if (event is KeyDownEvent) _toggle(id);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
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

    // The Tab stop: the row focused last, or the first once that one is gone
    // or folded away.
    final tabStop = all.any((row) => row.id == _current)
        ? _current!
        : all.first.id;

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
              child: _row(
                context,
                ordered[i],
                floating: false,
                tabStop: ordered[i].id == tabStop,
              ),
            ),
          if (expanded) _expansion(context, expandedIndex),
          if (drop != null) _slot(context, drop),
          if (dragging)
            _floatingRow(context, all, drop, maxTop, carried, tabStop),
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
    String tabStop,
  ) {
    final node = all.firstWhere((f) => f.id == _dragId);
    return AnimatedPositionedDirectional(
      key: ValueKey('tree-row-${node.id}'),
      duration: Duration.zero,
      top: (_pointerY - widget.rowHeight / 2).clamp(0.0, maxTop),
      start: (drop?.depth ?? node.depth) * widget.indent,
      end: 0,
      child: _row(
        context,
        node,
        floating: true,
        subtreeCount: carried,
        tabStop: node.id == tabStop,
      ),
    );
  }

  Widget _row(
    BuildContext context,
    TreeFlatNode node, {
    required bool floating,
    required bool tabStop,
    int subtreeCount = 0,
  }) {
    final canDrag = widget.onMove != null;
    final moves = _movesOf(node.id, node.depth);
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
              moves: moves,
            ),
          ),
        ),
        if (widget.rowControls && moves != null) _moveMenu(context, moves),
        if (floating && subtreeCount > 0) _carriedBadge(context, subtreeCount),
      ],
    );

    // The flow and floating rows MUST share one widget structure, or switching
    // between them on pickup rebuilds the drag handle's GestureDetector and
    // cancels the in-flight pan. Only the decoration toggles.
    final row = SizedBox(
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
    if (!widget.rowControls) return row;
    return _RowFocus(
      id: node.id,
      tabStop: tabStop,
      expanded: node.hasChildren ? node.expanded : null,
      nodes: _rowNodes,
      onFocused: (id) {
        if (id != _current) setState(() => _current = id);
      },
      onKeyEvent: _onRowKey,
      child: row,
    );
  }

  /// The ⋯ at the end of a row, with the moves a drag makes, each beside
  /// its key.
  Widget _moveMenu(BuildContext context, TreeRowMoves moves) {
    final l10n = context.adminL10n;
    final strings = l10n.display;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AdminSpacing.xs),
      child: MenuButton(
        icon: Icons.more_horiz_rounded,
        tooltip: l10n.moreActions,
        entries: [
          MenuItem(
            l10n.moveUp,
            icon: Icons.arrow_upward_rounded,
            shortcut: shortcutLabel(context, _upKey),
            onSelect: _announced(moves.up, strings.rowMovedUp),
          ),
          MenuItem(
            l10n.moveDown,
            icon: Icons.arrow_downward_rounded,
            shortcut: shortcutLabel(context, _downKey),
            onSelect: _announced(moves.down, strings.rowMovedDown),
          ),
          MenuItem(
            strings.indent,
            icon: Icons.format_indent_increase_rounded,
            shortcut: shortcutLabel(
              context,
              SingleActivator(_inward(context), alt: true),
            ),
            onSelect: _announced(moves.indent, strings.rowIndented),
          ),
          MenuItem(
            strings.outdent,
            icon: Icons.format_indent_decrease_rounded,
            shortcut: shortcutLabel(
              context,
              SingleActivator(_outward(context), alt: true),
            ),
            onSelect: _announced(moves.outdent, strings.rowOutdented),
          ),
        ],
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
    // → and ← open and close a row the tree operates.
    focusable: !widget.rowControls,
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

/// Where a node sits in a tree: under [parentId], at [index] among
/// [siblings].
class _Place {
  final TreeNode node;
  final String? parentId;
  final List<TreeNode> siblings;
  final int index;

  const _Place(this.node, this.parentId, this.siblings, this.index);
}

/// One row of a tree that operates its rows: the focus node the arrow keys
/// move between, a Tab stop on the one row that is [tabStop], with the
/// focus ring and the row's semantics.
class _RowFocus extends StatefulWidget {
  final String id;
  final bool tabStop;

  /// A parent's expanded state; null for a leaf.
  final bool? expanded;

  /// Where the row keeps its focus node, under its [id], while mounted.
  final Map<String, FocusNode> nodes;

  /// Focus came to the row, or to a control inside it.
  final ValueChanged<String> onFocused;
  final KeyEventResult Function(String id, FocusNode node, KeyEvent event)
  onKeyEvent;
  final Widget child;

  const _RowFocus({
    required this.id,
    required this.tabStop,
    required this.expanded,
    required this.nodes,
    required this.onFocused,
    required this.onKeyEvent,
    required this.child,
  });

  @override
  State<_RowFocus> createState() => _RowFocusState();
}

class _RowFocusState extends State<_RowFocus> {
  final _node = FocusNode(debugLabel: 'tree row');

  @override
  void initState() {
    super.initState();
    widget.nodes[widget.id] = _node;
    // The row's own semantics and its ring carry the focus.
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_RowFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      if (widget.nodes[oldWidget.id] == _node) {
        widget.nodes.remove(oldWidget.id);
      }
      widget.nodes[widget.id] = _node;
    }
  }

  @override
  void dispose() {
    if (widget.nodes[widget.id] == _node) widget.nodes.remove(widget.id);
    _node.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasPrimaryFocus;
    // Drawn inside the row's edge, where neither a scrolling tree nor a
    // panel around it clips it.
    final reach = math.max(0.0, FocusRing.reachOf(context));
    return Focus(
      focusNode: _node,
      // One Tab stop for the tree: the other rows, and the controls in
      // them, are reached with the arrows first.
      skipTraversal: !widget.tabStop,
      descendantsAreTraversable: widget.tabStop,
      includeSemantics: false,
      onFocusChange: (focused) {
        if (focused) widget.onFocused(widget.id);
      },
      onKeyEvent: (node, event) => widget.onKeyEvent(widget.id, node, event),
      child: Semantics(
        container: true,
        focusable: true,
        focused: focused,
        expanded: widget.expanded,
        onFocus: defaultTargetPlatform != TargetPlatform.iOS
            ? _node.requestFocus
            : null,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(reach),
                child: FocusRing(
                  focused: focused,
                  radius: context.radii.radius,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The expand / collapse chevron, a button named for what a press does:
/// the whole cell is the hit target, and keyboard focus rings the [size]
/// square around the glyph where the caret is [focusable].
class _Caret extends StatefulWidget {
  final bool expanded;
  final double size;

  /// Whether the caret is a Tab stop: in a tree whose rows are controls of
  /// their own, which have no key for it.
  final bool focusable;
  final VoidCallback onTap;

  const _Caret({
    required this.expanded,
    required this.size,
    required this.focusable,
    required this.onTap,
  });

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return Semantics(
      container: true,
      button: true,
      label: widget.expanded
          ? material.expandedIconTapHint
          : material.collapsedIconTapHint,
      expanded: widget.expanded,
      child: _target(context),
    );
  }

  Widget _target(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      canRequestFocus: widget.focusable,
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
