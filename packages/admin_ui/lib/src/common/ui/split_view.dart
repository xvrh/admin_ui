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
/// View-pure: sizing is presentation state, like [Accordion]'s open section — no
/// data or services. Supply the pane content as plain children.
class SplitView extends StatefulWidget {
  final SplitAxis axis;
  final List<Widget> children;

  /// Starting weights, one per pane, summing to 1. Defaults to an equal split.
  final List<double>? initialWeights;

  /// Minimum extent in logical pixels per pane along [axis]. A single value
  /// applies to every pane. Defaults to 80 each.
  final List<double>? minSizes;

  /// Width (horizontal) / height (vertical) of the divider hit target.
  final double dividerThickness;

  /// Fired after a drag with the new weights, for persistence.
  final ValueChanged<List<double>>? onWeightsChanged;

  const SplitView({
    super.key,
    required this.children,
    this.axis = SplitAxis.horizontal,
    this.initialWeights,
    this.minSizes,
    this.dividerThickness = 10,
    this.onWeightsChanged,
  }) : assert(children.length >= 2, 'SplitView needs at least two panes');

  /// The common two-pane case (master / detail, content / inspector).
  SplitView.two({
    Key? key,
    required Widget first,
    required Widget second,
    SplitAxis axis = SplitAxis.horizontal,
    double initialWeight = 0.5,
    double minFirst = 80,
    double minSecond = 80,
    double dividerThickness = 10,
    ValueChanged<List<double>>? onWeightsChanged,
  }) : this(
         key: key,
         axis: axis,
         children: [first, second],
         initialWeights: [initialWeight, 1 - initialWeight],
         minSizes: [minFirst, minSecond],
         dividerThickness: dividerThickness,
         onWeightsChanged: onWeightsChanged,
       );

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late List<double> _weights;

  @override
  void initState() {
    super.initState();
    _weights = _normalized(widget.initialWeights, widget.children.length);
  }

  @override
  void didUpdateWidget(SplitView old) {
    super.didUpdateWidget(old);
    if (widget.children.length != _weights.length) {
      _weights = _normalized(widget.initialWeights, widget.children.length);
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

  // Fired once when a drag ends, not per frame — a persistence callback wired to
  // [onWeightsChanged] shouldn't see a write per pointer-move.
  void _commit() => widget.onWeightsChanged?.call(List.of(_weights));

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

        final slivers = <Widget>[];
        for (var i = 0; i < count; i++) {
          final size = (paneExtent * _weights[i]).clamp(0.0, double.infinity);
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
                onDrag: (d) => _drag(i, sign * d, paneExtent),
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
