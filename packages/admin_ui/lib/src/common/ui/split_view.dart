import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

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

  /// Fired after a drag with the new weights, for persistence.
  final ValueChanged<List<double>>? onWeightsChanged;

  /// Fired after a drag with the new sizes, null for the free pane, for
  /// persistence; with [initialSizes] only.
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

  void _drag(int divider, double deltaPx, double paneExtent) {
    if (paneExtent <= 0) return;
    final df = deltaPx / paneExtent;
    final i = divider, j = divider + 1;
    final maxGrow = _weights[j] - _minOf(j) / paneExtent;
    final maxShrink = _weights[i] - _minOf(i) / paneExtent;
    // When the container is smaller than the sum of min sizes, both bounds can
    // go negative and cross (-maxShrink > maxGrow), which would make clamp throw.
    if (-maxShrink > maxGrow) return;
    final clamped = df.clamp(-maxShrink, maxGrow);
    if (clamped == 0) return;
    setState(() {
      _weights[i] += clamped;
      _weights[j] -= clamped;
    });
  }

  /// Moves the divider after pane [divider] by [deltaPx] from where the
  /// panes were laid out: the sized pane beside it takes the change, both
  /// when both are sized, each kept to its min size.
  void _dragSized(List<double?> sizes, int divider, double deltaPx) {
    final i = divider, j = divider + 1;
    if (_laid.length != sizes.length) return;
    final pair = _laid[i] + _laid[j];
    final upper = pair - _minOf(j);
    if (upper < _minOf(i)) return;
    final first = (_laid[i] + deltaPx).clamp(_minOf(i), upper);
    if (first == _laid[i]) return;
    setState(() {
      if (sizes[i] != null) sizes[i] = first;
      if (sizes[j] != null) sizes[j] = pair - first;
    });
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
  // [onWeightsChanged] shouldn't see a write per pointer-move.
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
        final paneExtent = extent - widget.dividerThickness * dividerCount;
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
            slivers.add(
              _Divider(
                axis: widget.axis,
                thickness: widget.dividerThickness,
                onDrag: (d) => sizes == null
                    ? _drag(i, sign * d, paneExtent)
                    : _dragSized(sizes, i, sign * d),
                onEnd: _commit,
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

class _Divider extends StatefulWidget {
  final SplitAxis axis;
  final double thickness;
  final ValueChanged<double> onDrag;
  final VoidCallback onEnd;

  const _Divider({
    required this.axis,
    required this.thickness,
    required this.onDrag,
    required this.onEnd,
  });

  @override
  State<_Divider> createState() => _DividerState();
}

class _DividerState extends State<_Divider> {
  bool _hover = false;
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final horizontal = widget.axis == SplitAxis.horizontal;
    final lit = _hover || _active;

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

    return MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: horizontal
            ? (_) => setState(() => _active = true)
            : null,
        onHorizontalDragUpdate: horizontal
            ? (d) => widget.onDrag(d.delta.dx)
            : null,
        onHorizontalDragEnd: horizontal
            ? (_) {
                setState(() => _active = false);
                widget.onEnd();
              }
            : null,
        onVerticalDragStart: horizontal
            ? null
            : (_) => setState(() => _active = true),
        onVerticalDragUpdate: horizontal
            ? null
            : (d) => widget.onDrag(d.delta.dy),
        onVerticalDragEnd: horizontal
            ? null
            : (_) {
                setState(() => _active = false);
                widget.onEnd();
              },
        child: SizedBox(
          width: horizontal ? widget.thickness : null,
          height: horizontal ? null : widget.thickness,
          child: Center(child: line),
        ),
      ),
    );
  }
}
