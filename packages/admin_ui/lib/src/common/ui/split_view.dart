import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/shortcut_label.dart';
import '../../theme/tokens.dart';
import 'context_menu.dart';
import 'focus_ring.dart';
import 'menu.dart';

/// Lay [SplitView] panes side by side ([horizontal]) or stacked ([vertical]).
enum SplitAxis { horizontal, vertical }

/// Two or more resizable panes separated by draggable dividers — the master /
/// detail (and nav │ list │ detail) layout the shell otherwise can't express.
///
/// Pane sizes are kept internally as weights that sum to 1, so they survive a
/// container resize proportionally. Drag a divider to grow one pane at its
/// neighbour's expense, clamped by each pane's [minSizes]. Pass [initialWeights]
/// to seed the split and [onWeightsChanged] to persist it. Side by side, the
/// first pane is at the start: on the right, right to left, where a divider
/// dragged leftward grows the pane before it.
///
/// [initialSizes] keeps panes at a size of their own instead, in logical
/// pixels, as a desktop app keeps its sidebar and inspector: one pane, the
/// one without a size, takes what the others leave, and only it follows the
/// container as it resizes. A divider resizes the sized pane beside it.
/// Short of room, the sized panes give way, down to their [minSizes], before
/// the free pane goes under its own, and take their sizes back as the
/// container widens. [onSizesChanged] persists them.
///
/// **Keyboard.** Each divider is a Tab stop, announced as a slider whose
/// value is the share its pane takes of the two panes it parts. ← and →
/// move a divider between side-by-side panes the way the arrow points, in
/// either reading direction, and ↑ and ↓ one between stacked panes, 16
/// logical pixels a press. Home takes the divider's pane to its smallest
/// and End to its largest, within [minSizes]. Enter collapses the pane to
/// its min size, and restores the size it had when pressed again. A
/// divider's pane is the one before it; with [initialSizes], the sized one
/// where the other is the free pane, so that Enter on an inspector's
/// divider collapses the inspector. A screen reader's increase and decrease
/// grow and shrink the pane by the same step.
///
/// **Pointer.** A drag is never the only way: a right-click on a divider, or
/// a long press with a finger, opens a menu of the same moves, a step
/// either way and collapse or expand, each beside its key.
///
/// View-pure: sizing is presentation state, like [Accordion]'s open section — no
/// data or services. Supply the pane content as plain children.
class SplitView extends StatefulWidget {
  final SplitAxis axis;
  final List<Widget> children;

  /// Starting weights, one per pane, summing to 1. Defaults to an equal split.
  final List<double>? initialWeights;

  /// Starting sizes in logical pixels, one per pane, in place of
  /// [initialWeights]: exactly one is null, the pane that takes what the
  /// others leave. See [SplitView].
  final List<double?>? initialSizes;

  /// Minimum extent in logical pixels per pane along [axis]. A single value
  /// applies to every pane. Defaults to 80 each.
  final List<double>? minSizes;

  /// Width (horizontal) / height (vertical) of the divider hit target.
  final double dividerThickness;

  /// Fired after a drag, and after each move by a key or the divider's menu,
  /// with the new weights, for persistence.
  final ValueChanged<List<double>>? onWeightsChanged;

  /// Fired after a drag, and after each move by a key or the divider's
  /// menu, with the new sizes, null for the free pane, for persistence;
  /// with [initialSizes] only.
  final ValueChanged<List<double?>>? onSizesChanged;

  const SplitView({
    super.key,
    required this.children,
    this.axis = SplitAxis.horizontal,
    this.initialWeights,
    this.initialSizes,
    this.minSizes,
    this.dividerThickness = 10,
    this.onWeightsChanged,
    this.onSizesChanged,
  }) : assert(children.length >= 2, 'SplitView needs at least two panes'),
       assert(
         initialSizes == null || initialWeights == null,
         'Give weights or sizes, not both',
       );

  /// The common two-pane case (master / detail, content / inspector).
  ///
  /// [firstSize] or [secondSize] keeps that pane at its size in logical
  /// pixels, the other taking the rest, in place of [initialWeight] (see
  /// [initialSizes]).
  SplitView.two({
    Key? key,
    required Widget first,
    required Widget second,
    SplitAxis axis = SplitAxis.horizontal,
    double initialWeight = 0.5,
    double? firstSize,
    double? secondSize,
    double minFirst = 80,
    double minSecond = 80,
    double dividerThickness = 10,
    ValueChanged<List<double>>? onWeightsChanged,
    ValueChanged<List<double?>>? onSizesChanged,
  }) : this(
         key: key,
         axis: axis,
         children: [first, second],
         initialWeights: firstSize == null && secondSize == null
             ? [initialWeight, 1 - initialWeight]
             : null,
         initialSizes: firstSize == null && secondSize == null
             ? null
             : [firstSize, secondSize],
         minSizes: [minFirst, minSecond],
         dividerThickness: dividerThickness,
         onWeightsChanged: onWeightsChanged,
         onSizesChanged: onSizesChanged,
       );

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late List<double> _weights;

  /// The panes' own sizes, null for the free one; null when the panes are
  /// weighted.
  List<double?>? _sizes;

  /// The sizes laid out last, which a drag starts from.
  List<double> _laid = const [];

  /// The extent the panes shared as they were laid out last, the dividers
  /// left out.
  double _paneExtent = 0;

  /// By divider, the size its pane had as Enter collapsed it, which Enter
  /// restores. Forgotten once the pane is resized any other way, by this
  /// divider or by the one on its other side.
  final _collapsedFrom = <int, double>{};

  /// How far an arrow key, a screen reader's increase or decrease, or a
  /// step from the divider's menu moves a divider, in logical pixels.
  static const _step = 16.0;

  /// The slack under which a pane counts as at one of its limits: weights
  /// are fractions, and come back from the layout a rounding error off.
  static const _slack = 0.01;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  void _seed() {
    assert(
      widget.initialSizes == null ||
          widget.initialSizes!.length == widget.children.length,
      'One size per pane',
    );
    assert(
      widget.initialSizes == null ||
          widget.initialSizes!.where((size) => size == null).length == 1,
      'Exactly one pane, the free one, has no size',
    );
    _collapsedFrom.clear();
    _weights = _normalized(widget.initialWeights, widget.children.length);
    _sizes = switch (widget.initialSizes) {
      final sizes? => List.of(sizes),
      null => null,
    };
  }

  @override
  void didUpdateWidget(SplitView old) {
    super.didUpdateWidget(old);
    final sizes = widget.initialSizes;
    final free = sizes?.indexOf(null);
    if (widget.children.length != _weights.length ||
        (sizes == null) != (_sizes == null) ||
        free != _sizes?.indexOf(null)) {
      _seed();
    }
  }

  static List<double> _normalized(List<double>? weights, int count) {
    if (weights == null || weights.length != count) {
      return List.filled(count, 1 / count);
    }
    final total = weights.fold(0.0, (a, b) => a + b);
    if (total <= 0) return List.filled(count, 1 / count);
    return [for (final w in weights) w / total];
  }

  double _minOf(int i) {
    final mins = widget.minSizes;
    if (mins == null || mins.isEmpty) return 80;
    return i < mins.length ? mins[i] : mins.last;
  }

  /// Moves the divider after pane [divider] by [deltaPx] toward the end
  /// edge, each pane kept to its min size, and says whether it moved.
  bool _drag(int divider, double deltaPx, double paneExtent) {
    if (paneExtent <= 0) return false;
    final df = deltaPx / paneExtent;
    final i = divider, j = divider + 1;
    final maxGrow = _weights[j] - _minOf(j) / paneExtent;
    final maxShrink = _weights[i] - _minOf(i) / paneExtent;
    // When the container is smaller than the sum of min sizes, both bounds can
    // go negative and cross (-maxShrink > maxGrow), which would make clamp throw.
    if (-maxShrink > maxGrow) return false;
    final clamped = df.clamp(-maxShrink, maxGrow);
    if (clamped == 0) return false;
    setState(() {
      _weights[i] += clamped;
      _weights[j] -= clamped;
    });
    return true;
  }

  /// Moves the divider after pane [divider] by [deltaPx] from where the
  /// panes were laid out: the sized pane beside it takes the change, both
  /// when both are sized, each kept to its min size. Says whether it moved.
  bool _dragSized(List<double?> sizes, int divider, double deltaPx) {
    final i = divider, j = divider + 1;
    if (_laid.length != sizes.length) return false;
    final pair = _laid[i] + _laid[j];
    final upper = pair - _minOf(j);
    if (upper < _minOf(i)) return false;
    final first = (_laid[i] + deltaPx).clamp(_minOf(i), upper);
    if (first == _laid[i]) return false;
    setState(() {
      if (sizes[i] != null) sizes[i] = first;
      if (sizes[j] != null) sizes[j] = pair - first;
    });
    return true;
  }

  /// A pointer drag of the divider after pane [divider], [deltaPx] toward
  /// the end edge.
  void _dragBy(int divider, double deltaPx) {
    final moved = switch (_sizes) {
      final sizes? => _dragSized(sizes, divider, deltaPx),
      null => _drag(divider, deltaPx, _paneExtent),
    };
    if (moved) _forgetCollapsed(divider);
  }

  /// Forgets the collapsed size of the panes on either side of [divider],
  /// which a move of it has just resized, whichever divider collapsed
  /// them: a pane that was resized since is not collapsed any more, and
  /// has no size to go back to.
  void _forgetCollapsed(int divider) {
    _collapsedFrom.removeWhere((collapsedBy, _) {
      final pane = _paneOf(collapsedBy);
      return pane == divider || pane == divider + 1;
    });
  }

  /// The pane the keys and the menu of the divider after pane [divider]
  /// resize: the one before it, or the one after it where that one alone
  /// has a size of its own.
  int _paneOf(int divider) => switch (_sizes) {
    final sizes? when sizes[divider] == null => divider + 1,
    _ => divider,
  };

  /// The smallest and the largest size the divider's pane can take, its
  /// neighbour across the divider giving way down to its own min size.
  (double, double) _limits(int divider) {
    final pane = _paneOf(divider);
    final other = pane == divider ? divider + 1 : divider;
    return (_minOf(pane), _laid[pane] + _laid[other] - _minOf(other));
  }

  /// Takes the divider's pane to [size], within its limits, in one step: a
  /// key, a screen reader's action or an item of the divider's menu. Unlike
  /// a drag it is reported at once. Says whether the pane changed size.
  bool _resizeTo(int divider, double size) {
    if (_laid.length != widget.children.length) return false;
    final pane = _paneOf(divider);
    final delta = size - _laid[pane];
    final towardEnd = pane == divider ? delta : -delta;
    final moved = switch (_sizes) {
      final sizes? => _dragSized(sizes, divider, towardEnd),
      null => _drag(divider, towardEnd, _paneExtent),
    };
    if (!moved) return false;
    _forgetCollapsed(divider);
    _commit();
    return true;
  }

  /// Collapses the divider's pane to its min size, or restores the size it
  /// had when it was collapsed.
  void _toggleCollapsed(int divider) {
    if (_laid.length != widget.children.length) return;
    final from = _collapsedFrom[divider];
    if (from != null) {
      if (!_resizeTo(divider, from)) _collapsedFrom.remove(divider);
      return;
    }
    final size = _laid[_paneOf(divider)];
    final (smallest, _) = _limits(divider);
    if (size <= smallest + _slack) return;
    if (_resizeTo(divider, smallest)) _collapsedFrom[divider] = size;
  }

  /// The panes' extents along the axis in [extent]: the sized panes at their
  /// sizes and the free one the rest. Short of room, the sized panes give
  /// way to their min sizes in proportion to what they have above it, then
  /// every pane to its min size in proportion, so they always fill [extent].
  List<double> _layOut(List<double?> sizes, double extent) {
    final free = sizes.indexOf(null);
    var taken = 0.0, floor = 0.0;
    for (var i = 0; i < sizes.length; i++) {
      if (i == free) continue;
      taken += sizes[i]!;
      floor += math.min(_minOf(i), sizes[i]!);
    }
    final room = extent - _minOf(free);
    final List<double> laid;
    if (taken <= room) {
      laid = [for (final size in sizes) size ?? extent - taken];
    } else if (floor <= room) {
      // Each sized pane keeps its min and its share of the room above them.
      final share = taken == floor ? 0.0 : (room - floor) / (taken - floor);
      laid = [
        for (var i = 0; i < sizes.length; i++)
          if (i == free)
            _minOf(free)
          else
            math.min(_minOf(i), sizes[i]!) +
                (sizes[i]! - math.min(_minOf(i), sizes[i]!)) * share,
      ];
      laid[free] = extent - (laid.fold(0.0, (a, b) => a + b) - laid[free]);
    } else {
      final mins = [
        for (var i = 0; i < sizes.length; i++)
          i == free ? _minOf(free) : math.min(_minOf(i), sizes[i]!),
      ];
      final total = mins.fold(0.0, (a, b) => a + b);
      laid = [for (final min in mins) total <= 0 ? 0 : extent * min / total];
    }
    return [for (final size in laid) math.max(0, size)];
  }

  // Fired once when a drag ends, not per frame — a persistence callback wired to
  // [onWeightsChanged] shouldn't see a write per pointer-move — and once per
  // move by a key or the menu.
  void _commit() {
    if (_sizes case final sizes?) {
      widget.onSizesChanged?.call(List.of(sizes));
    } else {
      widget.onWeightsChanged?.call(List.of(_weights));
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == SplitAxis.horizontal;
    final count = widget.children.length;
    final dividerCount = count - 1;
    // A drag toward the end edge grows the pane before the divider.
    final sign = horizontal && Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final paneExtent = _paneExtent =
            extent - widget.dividerThickness * dividerCount;
        final sizes = _sizes;
        final laid = _laid = sizes == null
            ? [
                for (final weight in _weights)
                  (paneExtent * weight).clamp(0.0, double.infinity),
              ]
            : _layOut(sizes, paneExtent);

        final slivers = <Widget>[];
        for (var i = 0; i < count; i++) {
          final size = laid[i];
          slivers.add(
            SizedBox(
              width: horizontal ? size : null,
              height: horizontal ? null : size,
              child: widget.children[i],
            ),
          );
          if (i < dividerCount) {
            final pane = _paneOf(i);
            final (smallest, largest) = _limits(i);
            slivers.add(
              _Divider(
                axis: widget.axis,
                thickness: widget.dividerThickness,
                size: laid[pane],
                smallest: smallest,
                largest: largest,
                pair: laid[i] + laid[i + 1],
                leads: pane == i,
                step: _step,
                slack: _slack,
                collapsed: _collapsedFrom.containsKey(i),
                onDrag: (d) => _dragBy(i, sign * d),
                onEnd: _commit,
                onResize: (size) => _resizeTo(i, size),
                onToggleCollapsed: () => _toggleCollapsed(i),
              ),
            );
          }
        }

        return horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: slivers,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: slivers,
              );
      },
    );
  }
}

/// One divider: the drag target, the Tab stop and the slider a screen
/// reader hears, and the menu a right-click opens.
class _Divider extends StatefulWidget {
  final SplitAxis axis;
  final double thickness;

  /// The size of the pane the divider resizes, between [smallest] and
  /// [largest], out of [pair], the two panes it parts together.
  final double size;
  final double smallest;
  final double largest;
  final double pair;

  /// Whether that pane is the one before the divider, which grows as the
  /// divider moves toward the end edge.
  final bool leads;

  /// What one key press moves, and how close to a limit counts as on it.
  final double step;
  final double slack;

  /// Whether Enter collapsed the pane, and restores it next.
  final bool collapsed;

  final ValueChanged<double> onDrag;
  final VoidCallback onEnd;

  /// Takes the pane to a size, which the view keeps within its limits.
  final ValueChanged<double> onResize;
  final VoidCallback onToggleCollapsed;

  const _Divider({
    required this.axis,
    required this.thickness,
    required this.size,
    required this.smallest,
    required this.largest,
    required this.pair,
    required this.leads,
    required this.step,
    required this.slack,
    required this.collapsed,
    required this.onDrag,
    required this.onEnd,
    required this.onResize,
    required this.onToggleCollapsed,
  });

  @override
  State<_Divider> createState() => _DividerState();
}

class _DividerState extends State<_Divider> {
  final _focusNode = FocusNode(debugLabel: 'split view divider');
  bool _hover = false;
  bool _active = false;

  /// Whether the keyboard focus highlight shows on the divider.
  bool _showsFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // The divider's own semantics carry the focused flag.
  void _onFocus() => setState(() {});

  bool get _horizontal => widget.axis == SplitAxis.horizontal;

  bool get _canGrow => widget.size < widget.largest - widget.slack;

  bool get _canShrink => widget.size > widget.smallest + widget.slack;

  bool get _canToggle => widget.collapsed || _canShrink;

  void _grow() => widget.onResize(widget.size + widget.step);

  void _shrink() => widget.onResize(widget.size - widget.step);

  /// Whether a step toward the end edge grows the pane: it does for the pane
  /// before the divider.
  bool _grows({required bool towardEnd}) => towardEnd == widget.leads;

  /// One step toward the end edge or the start edge, or null at the limit.
  VoidCallback? _stepper({required bool towardEnd}) {
    final grows = _grows(towardEnd: towardEnd);
    if (grows ? !_canGrow : !_canShrink) return null;
    return grows ? _grow : _shrink;
  }

  void _startDrag() {
    // A divider that was dragged takes the keys next, as a slider does.
    _focusNode.requestFocus();
    setState(() => _active = true);
  }

  void _endDrag() {
    setState(() => _active = false);
    widget.onEnd();
  }

  /// The pane's share of the two panes at [size], as the slider's value.
  String _share(BuildContext context, double size) {
    final clamped = size.clamp(
      widget.smallest,
      math.max(widget.smallest, widget.largest),
    );
    return context.adminFormats.percent(
      widget.pair <= 0 ? 0 : (clamped / widget.pair).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final horizontal = _horizontal;
    final lit = _hover || _active || _showsFocus;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Side by side, the end edge is the left one right to left.
    final endIsForward = !(horizontal && rtl);

    final motion = context.motion;
    final stroke = context.stroke;
    final thickness = lit ? stroke.indicator : stroke.hairline;
    final line = AnimatedContainer(
      duration: motion.fast,
      curve: motion.standard,
      width: horizontal ? thickness : double.infinity,
      height: horizontal ? double.infinity : thickness,
      color: lit ? colors.primary : colors.border,
    );
    // The ring stays inside the view: the line gives up, at its two ends,
    // the room the ring takes around it.
    final reach = math.max(0.0, FocusRing.reachOf(context));
    final ringed = Padding(
      padding: !_showsFocus
          ? EdgeInsets.zero
          : horizontal
          ? EdgeInsets.symmetric(vertical: reach)
          : EdgeInsets.symmetric(horizontal: reach),
      child: FocusRing(
        focused: _showsFocus,
        radius: context.radii.radiusSmall,
        child: line,
      ),
    );

    const leftKey = SingleActivator(LogicalKeyboardKey.arrowLeft);
    const rightKey = SingleActivator(LogicalKeyboardKey.arrowRight);
    const upKey = SingleActivator(LogicalKeyboardKey.arrowUp);
    const downKey = SingleActivator(LogicalKeyboardKey.arrowDown);
    const enterKey = SingleActivator(LogicalKeyboardKey.enter);
    // What ← or ↑ does, and what → or ↓ does; null at the pane's limit.
    final stepBack = _stepper(towardEnd: !endIsForward);
    final stepForward = _stepper(towardEnd: endIsForward);

    final l10n = context.adminL10n;
    final toggleLabel = widget.collapsed ? l10n.expand : l10n.collapse;

    final target = MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // The slider's own semantics below carry the moves.
        excludeFromSemantics: true,
        // A finger's drag has to outrun the long press that opens the menu;
        // the pane then catches up with the finger rather than trail it.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: horizontal ? (_) => _startDrag() : null,
        onHorizontalDragUpdate: horizontal
            ? (d) => widget.onDrag(d.delta.dx)
            : null,
        onHorizontalDragEnd: horizontal ? (_) => _endDrag() : null,
        onVerticalDragStart: horizontal ? null : (_) => _startDrag(),
        onVerticalDragUpdate: horizontal
            ? null
            : (d) => widget.onDrag(d.delta.dy),
        onVerticalDragEnd: horizontal ? null : (_) => _endDrag(),
        child: SizedBox(
          width: horizontal ? widget.thickness : null,
          height: horizontal ? null : widget.thickness,
          child: Center(child: ringed),
        ),
      ),
    );

    return ContextMenuRegion(
      entries: (context) => [
        if (horizontal) ...[
          MenuItem(
            l10n.display.moveLeft,
            icon: context.icons.resizeLeft,
            shortcut: shortcutLabel(context, leftKey),
            onSelect: stepBack,
          ),
          MenuItem(
            l10n.display.moveRight,
            icon: context.icons.resizeRight,
            shortcut: shortcutLabel(context, rightKey),
            onSelect: stepForward,
          ),
        ] else ...[
          MenuItem(
            l10n.moveUp,
            icon: context.icons.resizeUp,
            shortcut: shortcutLabel(context, upKey),
            onSelect: stepBack,
          ),
          MenuItem(
            l10n.moveDown,
            icon: context.icons.resizeDown,
            shortcut: shortcutLabel(context, downKey),
            onSelect: stepForward,
          ),
        ],
        const MenuDivider(),
        MenuItem(
          toggleLabel,
          shortcut: shortcutLabel(context, enterKey),
          onSelect: _canToggle ? widget.onToggleCollapsed : null,
        ),
      ],
      child: CallbackShortcuts(
        bindings: {
          // At a limit the arrow is still the divider's key, and does not
          // go on to move the focus to a neighbour.
          (horizontal ? leftKey : upKey): stepBack ?? () {},
          (horizontal ? rightKey : downKey): stepForward ?? () {},
          const SingleActivator(LogicalKeyboardKey.home): () =>
              widget.onResize(widget.smallest),
          const SingleActivator(LogicalKeyboardKey.end): () =>
              widget.onResize(widget.largest),
          enterKey: widget.onToggleCollapsed,
          const SingleActivator(LogicalKeyboardKey.numpadEnter):
              widget.onToggleCollapsed,
        },
        child: FocusableActionDetector(
          focusNode: _focusNode,
          includeFocusSemantics: false,
          onShowFocusHighlight: (shows) => setState(() => _showsFocus = shows),
          child: Semantics(
            container: true,
            slider: true,
            label: l10n.display.resizePanes,
            value: _share(context, widget.size),
            increasedValue: _share(context, widget.size + widget.step),
            decreasedValue: _share(context, widget.size - widget.step),
            onIncrease: _canGrow ? _grow : null,
            onDecrease: _canShrink ? _shrink : null,
            focusable: true,
            focused: _focusNode.hasPrimaryFocus,
            onFocus: defaultTargetPlatform != TargetPlatform.iOS
                ? _focusNode.requestFocus
                : null,
            customSemanticsActions: {
              if (_canToggle)
                CustomSemanticsAction(label: toggleLabel):
                    widget.onToggleCollapsed,
            },
            child: target,
          ),
        ),
      ),
    );
  }
}
