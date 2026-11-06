/// @docImport 'button.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/field_style.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'focus_ring.dart';
import 'tappable.dart';
import 'tip.dart';

/// One choice in a [Segmented] control.
class SegmentOption<T> {
  final T value;

  /// The segment's name: shown beside [icon], and always its accessible name.
  final String label;
  final IconData? icon;

  /// Draws [label] beside [icon]. False makes an icon-only segment that still
  /// announces [label] and shows it as a tooltip. A segment with an [icon]
  /// and an empty [label] is icon-only too, but nameless: give it a label.
  final bool showLabel;

  /// Reports, and can seed, the segment's hovered, pressed and focused states
  /// — e.g. to pin a state in a catalog. Created internally when null.
  final WidgetStatesController? statesController;

  /// The key of the segment built for this option, to find it by in a test.
  final Key? key;

  const SegmentOption(
    this.value,
    this.label, {
    this.key,
    this.icon,
    this.showLabel = true,
    this.statesController,
  });

  bool get _iconOnly => icon != null && (!showLabel || label.isEmpty);
}

/// A joined single-select control — a row of segments sharing one border,
/// the active one filled with the soft primary tint. For 2–4 either/or
/// choices; for many options or wrapping pills use a select field instead.
///
/// The group takes a [Button]'s corner at its [size] (a stadium in Material,
/// square in Carbon), and a field's resting edge, so it lines up with the
/// search box and the buttons beside it in a toolbar.
///
/// A null [onChanged] disables it: the labels grey, the selected segment
/// keeps a soft fill in a neutral tone (a disabled filled button's), so it
/// never outweighs an enabled selection, and it leaves the Tab order.
/// [readOnly] shows
/// the value at full contrast without letting it change: still one Tab stop,
/// the arrow keys move focus without selecting, and each segment is announced
/// read-only, with no hover (see `FieldState`).
///
/// It hugs its segments, the theme's control height for [size] like a
/// [Button] of that size; [expand] splits a bounded width
/// into equal segments instead. Short of room, the widest labels ellipsize
/// first, so it never overflows.
///
/// One Tab stop, the selected segment: the arrow keys move to the next or
/// previous segment and select it, Home and End jump to the ends, and keyboard
/// focus rings the whole control. Announced as a radio group, like `Choice`:
/// each segment is a radio with its checked state, and the group is named
/// [semanticLabel].
class Segmented<T> extends StatefulWidget {
  final List<SegmentOption<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;

  /// The control height, from the theme's [ControlSize]s: small, with the
  /// small body text and tighter padding, for tight chrome such as a
  /// toolbar.
  final ControlSize size;

  /// Fills a bounded width with equal segments, like Ant's `block`.
  final bool expand;

  /// The group's accessible name — the question the segments answer.
  final String? semanticLabel;

  /// Shows [value] at full contrast, taking no input; see [Segmented].
  final bool readOnly;

  const Segmented({
    super.key,
    required this.segments,
    required this.value,
    this.onChanged,
    this.size = ControlSize.medium,
    this.expand = false,
    this.semanticLabel,
    this.readOnly = false,
  });

  @override
  State<Segmented<T>> createState() => _SegmentedState<T>();
}

class _SegmentedState<T> extends State<Segmented<T>> {
  final _nodes = <FocusNode>[];
  final _ownStates = <WidgetStatesController>[];
  List<WidgetStatesController> _states = const [];
  bool _focused = false;

  /// Counts font loads, keying the labels. A paragraph keeps the intrinsic
  /// width it measured before a font arrived (the framework resets its layout
  /// but not its intrinsics painter), so the strip would size a segment for
  /// the fallback font and ellipsize the label; a fresh key measures anew.
  int _fontLoads = 0;

  /// Whether a segment can be picked.
  bool get _editable => widget.onChanged != null && !widget.readOnly;

  /// Whether the group takes focus and shows its value at full contrast:
  /// editable, or read-only.
  bool get _live => widget.onChanged != null || widget.readOnly;

  /// The segment Tab lands on: the selected one, else the first.
  int get _tabStop {
    final i = widget.segments.indexWhere((s) => s.value == widget.value);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _sync();
    PaintingBinding.instance.systemFonts.addListener(_onFontsChanged);
  }

  void _onFontsChanged() {
    if (mounted) setState(() => _fontLoads++);
  }

  @override
  void didUpdateWidget(Segmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onFontsChanged);
    for (final states in _states) {
      states.removeListener(_onStates);
    }
    for (final states in _ownStates) {
      states.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// One focus node and states controller per segment; only the Tab stop is
  /// in the traversal order.
  void _sync() {
    final count = widget.segments.length;
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: 'Segment ${_nodes.length}'));
      _ownStates.add(WidgetStatesController());
    }
    while (_nodes.length > count) {
      _nodes.removeLast().dispose();
      _ownStates.removeLast().dispose();
    }
    final tabStop = _tabStop;
    for (var i = 0; i < count; i++) {
      _nodes[i].skipTraversal = i != tabStop;
    }

    final states = [
      for (var i = 0; i < count; i++)
        widget.segments[i].statesController ?? _ownStates[i],
    ];
    for (final old in _states) {
      old.removeListener(_onStates);
    }
    for (final s in states) {
      s.addListener(_onStates);
    }
    _states = states;
    _focused = _anyFocused;
  }

  bool get _anyFocused =>
      _states.any((s) => s.value.contains(WidgetState.focused));

  void _onStates() {
    final focused = _anyFocused;
    if (focused != _focused && mounted) setState(() => _focused = focused);
  }

  void _select(int index) {
    final value = widget.segments[index].value;
    if (value != widget.value) widget.onChanged?.call(value);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!_live || event is KeyUpEvent) return KeyEventResult.ignored;
    final current = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (current < 0) return KeyEventResult.ignored;
    final count = widget.segments.length;
    final forward = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    final int target;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        target = current + forward;
      case LogicalKeyboardKey.arrowLeft:
        target = current - forward;
      case LogicalKeyboardKey.arrowDown:
        target = current + 1;
      case LogicalKeyboardKey.arrowUp:
        target = current - 1;
      case LogicalKeyboardKey.home:
        target = 0;
      case LogicalKeyboardKey.end:
        target = count - 1;
      default:
        return KeyEventResult.ignored;
    }
    final index = target % count;
    _nodes[index].requestFocus();
    if (_editable) _select(index);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final radius = context.radii.button(widget.size);
    final metrics = _Metrics.of(context, widget.size);
    final segments = widget.segments;

    // A field's resting edge, so it lines up with the search box and selects
    // beside it in a toolbar: its outline, or in a filled theme its bottom
    // rule, which is the edge that holds 3:1 there. The dividers match it,
    // as the shared edges of shadcn's outline toggle group do.
    final states = {if (!_live) WidgetState.disabled};
    final chrome = resolveFieldChrome(context.adminTokens, states);
    final outline = chrome.variant == FieldVariant.filled
        ? chrome.rule
        : fieldBorderSide(context.colors, states, stroke: context.stroke);
    final strip = _SegmentStrip(
      height: metrics.height,
      expand: widget.expand,
      divider: outline.color,
      floors: [for (final s in segments) metrics.floor(s)],
      children: [
        for (var i = 0; i < segments.length; i++) _segment(context, i, metrics),
      ],
    );

    Widget group = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
      // Border on top of the clipped children — drawing it in `decoration`
      // lets the anti-aliased clip crop the rounded corners.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outline.color, width: outline.width),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.radioGroup,
        label: widget.semanticLabel,
        readOnly: widget.readOnly ? true : null,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: strip,
        ),
      ),
    );
    // One Tab stop, and the arrows select (or, read-only, only move), so the
    // ring goes round the whole control, where the clip can't cut it.
    group = FocusRing(focused: _focused, radius: radius, child: group);
    return widget.expand
        ? group
        : Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: group,
          );
  }

  Widget _segment(BuildContext context, int i, _Metrics m) {
    final colors = context.colors;
    final seg = widget.segments[i];
    final selected = seg.value == widget.value;
    final editable = _editable;
    final live = _live;
    final iconOnly = seg._iconOnly;

    Widget segment = Tappable.states(
      key: seg.key,
      onTap: editable ? () => _select(i) : null,
      readOnly: widget.readOnly,
      focusNode: _nodes[i],
      statesController: _states[i],
      showFocusRing: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: iconOnly ? seg.label : null,
      excludeSemantics: iconOnly,
      builder: (context, states) {
        final hovered = editable && states.contains(WidgetState.hovered);
        final pressed = editable && states.contains(WidgetState.pressed);
        // Muted text can fall short of 4.5:1 on the hover and press tints, so
        // there it takes its on-tint shade — still muted, like shadcn's
        // toggle, so a hovered segment never passes for the selected one in
        // a theme whose selection is as neutral as the hover. Disabled, the
        // selection keeps its soft fill in a neutral tone.
        final Color fg;
        if (!live) {
          fg = colors.foregroundSubtle;
        } else if (selected) {
          fg = colors.primaryText;
        } else if (hovered || pressed) {
          fg = colors.foregroundMutedOnTint;
        } else {
          fg = colors.foregroundMuted;
        }
        final Color fill;
        if (selected) {
          fill = live
              ? colors.primarySubtle
              : Color.alphaBlend(colors.pressedOverlay, colors.surface);
        } else if (pressed) {
          fill = Color.alphaBlend(colors.pressedOverlay, colors.surface);
        } else if (hovered) {
          fill = Color.alphaBlend(colors.hoverOverlay, colors.surface);
        } else {
          fill = colors.surface;
        }
        return ColoredBox(
          color: fill,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: m.padX(seg)),
            child: Center(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (seg.icon != null) Icon(seg.icon, size: m.icon, color: fg),
                  if (seg.icon != null && !iconOnly) Gap(m.gap),
                  if (!iconOnly)
                    Flexible(
                      child: Text(
                        seg.label,
                        key: ValueKey(_fontLoads),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        // One weight in both states, so selecting never
                        // changes a segment's width.
                        style: context.type
                            .weighted(m.text(context), FontWeight.w500)
                            .copyWith(color: fg),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (iconOnly && seg.label.isNotEmpty) {
      segment = Tip(
        message: seg.label,
        excludeFromSemantics: true,
        child: segment,
      );
    }
    return segment;
  }
}

/// Sizes for each [ControlSize], as a [Button] of that size takes them: small
/// takes the small body text, the small glyph and tighter padding, medium and
/// large the body text and the control glyph.
class _Metrics {
  final double height;
  final double icon;
  final double gap;
  final double _padX;
  final bool _small;

  const _Metrics(this.height, this.icon, this.gap, this._padX, this._small);

  /// The control height is taller by as much as the labels grow at a large
  /// text size.
  static _Metrics of(BuildContext context, ControlSize size) {
    final sizes = context.sizes;
    final type = context.type;
    final icons = context.iconSizes;
    return size == ControlSize.small
        ? _Metrics(
            sizes.small + textGrowthOf(context, type.bodySmall),
            icons.sm,
            AdminSpacing.sm,
            AdminSpacing.lg,
            true,
          )
        : _Metrics(
            sizes.height(size) + textGrowthOf(context, type.body),
            icons.md,
            AdminSpacing.sm,
            AdminSpacing.xl,
            false,
          );
  }

  TextStyle text(BuildContext context) =>
      _small ? context.type.bodySmall : context.type.body;

  /// Icon-only segments are square.
  double padX(SegmentOption<Object?> seg) =>
      seg._iconOnly ? (height - icon) / 2 : _padX;

  /// The narrowest a segment gets: its padding and icon, with the label
  /// ellipsized away.
  double floor(SegmentOption<Object?> seg) =>
      padX(seg) * 2 + (seg.icon == null ? 0 : icon + (seg._iconOnly ? 0 : gap));
}

/// Lays the segments out in a row, [height] tall, with a 1px [divider]
/// between them. Each segment takes its natural width while they all fit;
/// short of room the widest shrink first, to an equal share of what's left,
/// never below its [floors] entry. With [expand] a bounded width is split
/// equally. The first segment sits at the start edge: the right, in
/// right-to-left text.
class _SegmentStrip extends MultiChildRenderObjectWidget {
  final double height;
  final bool expand;
  final Color divider;
  final List<double> floors;

  const _SegmentStrip({
    required this.height,
    required this.expand,
    required this.divider,
    required this.floors,
    required super.children,
  });

  @override
  _RenderSegmentStrip createRenderObject(BuildContext context) =>
      _RenderSegmentStrip(
        height: height,
        expand: expand,
        divider: divider,
        floors: floors,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSegmentStrip renderObject,
  ) {
    renderObject
      ..height = height
      ..expand = expand
      ..divider = divider
      ..floors = floors
      ..textDirection = Directionality.of(context);
  }
}

class _StripParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSegmentStrip extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StripParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StripParentData> {
  _RenderSegmentStrip({
    required this._height,
    required this._expand,
    required this._divider,
    required this._floors,
    required this._textDirection,
  });

  static const _gap = 1.0;

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  bool _expand;
  set expand(bool value) {
    if (value == _expand) return;
    _expand = value;
    markNeedsLayout();
  }

  Color _divider;
  set divider(Color value) {
    if (value == _divider) return;
    _divider = value;
    markNeedsPaint();
  }

  List<double> _floors;
  set floors(List<double> value) {
    if (listEquals(value, _floors)) return;
    _floors = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool get _rtl => _textDirection == TextDirection.rtl;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StripParentData) {
      child.parentData = _StripParentData();
    }
  }

  double _floor(int i) => i < _floors.length ? _floors[i] : 0;

  double get _gaps => childCount < 2 ? 0 : _gap * (childCount - 1);

  /// Each segment's width with its whole label, rounded up: some fonts lay
  /// out a hair wider than they measure, which would ellipsize a label that
  /// fits.
  List<double> _natural() {
    final widths = <double>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      widths.add(
        math.max(
          _floor(widths.length),
          child.getMaxIntrinsicWidth(_height).ceilToDouble(),
        ),
      );
    }
    return widths;
  }

  List<double> _widths(BoxConstraints constraints) {
    final natural = _natural();
    if (natural.isEmpty || !constraints.hasBoundedWidth) return natural;
    final available = math.max(0.0, constraints.maxWidth - _gaps);
    final count = natural.length;
    if (_expand) {
      return [
        for (var i = 0; i < count; i++) math.max(_floor(i), available / count),
      ];
    }
    if (_sum(natural) <= available) return natural;

    // Shrink the widest first: a segment under an equal share of what's left
    // keeps its width, and the wider ones split the remainder.
    final order = List.generate(count, (i) => i)
      ..sort((a, b) => natural[a].compareTo(natural[b]));
    var remaining = available;
    var left = count;
    var cap = double.infinity;
    for (final i in order) {
      final share = remaining / left;
      if (natural[i] > share) {
        cap = share;
        break;
      }
      remaining -= natural[i];
      left--;
    }
    return [
      for (var i = 0; i < count; i++)
        math.max(_floor(i), math.min(natural[i], cap)),
    ];
  }

  static double _sum(Iterable<double> values) =>
      values.fold(0.0, (a, b) => a + b);

  Size _sizeFor(BoxConstraints constraints, List<double> widths) {
    final width = _expand && constraints.hasBoundedWidth
        ? constraints.maxWidth
        : _sum(widths) + _gaps;
    return constraints.constrain(Size(width, _height));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _sum([for (var i = 0; i < childCount; i++) _floor(i)]) + _gaps;

  @override
  double computeMaxIntrinsicWidth(double height) => _sum(_natural()) + _gaps;

  @override
  double computeMinIntrinsicHeight(double width) => _height;

  @override
  double computeMaxIntrinsicHeight(double width) => _height;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _sizeFor(constraints, _widths(constraints));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void performLayout() {
    final widths = _widths(constraints);
    final height = constraints.constrainHeight(_height);
    size = _sizeFor(constraints, widths);
    // The distance from the start edge.
    var x = 0.0;
    var i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(
        BoxConstraints.tightFor(width: widths[i], height: height),
        parentUsesSize: true,
      );
      (child.parentData! as _StripParentData).offset = Offset(
        _rtl ? size.width - x - widths[i] : x,
        0,
      );
      x += widths[i] + _gap;
      i++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()..color = _divider;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (childAfter(child) == null) break;
      final left = (child.parentData! as _StripParentData).offset.dx;
      context.canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + (_rtl ? left - _gap : left + child.size.width),
          offset.dy,
          _gap,
          size.height,
        ),
        paint,
      );
    }
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
