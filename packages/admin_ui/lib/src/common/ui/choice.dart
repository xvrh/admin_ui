/// @docImport '../../theme/stroke.dart';
/// @docImport 'checkbox.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/palette.dart';
import '../../theme/selection_style.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'control_label.dart';
import 'focus_ring.dart';
import 'tappable.dart';

/// One choice in a [Choice].
class ChoiceOption<T> {
  final T value;
  final String label;

  /// Secondary line under the label — only rendered in [ChoiceStyle.card].
  final String? description;
  final IconData? icon;
  final bool enabled;

  /// Reports, and can seed, the option's hovered, pressed and focused states
  /// — e.g. to pin a state in a catalog. Created internally when null.
  final WidgetStatesController? statesController;

  /// The key of the option built for this choice, to find it by in a test.
  final Key? key;

  const ChoiceOption(
    this.value,
    this.label, {
    this.key,
    this.description,
    this.icon,
    this.enabled = true,
    this.statesController,
  });
}

enum ChoiceStyle {
  /// A radio dot + label per row. Compact; the default form control.
  plain,

  /// A bordered, tappable card per option, with optional [ChoiceOption.description].
  /// Reads as a stronger, more deliberate choice.
  card,
}

/// A single-choice control: a column (or row) of [options], exactly one selected.
/// Generic over the option value [T].
///
/// A radio group: one Tab stop (the selected option, else the first enabled
/// one); the arrow keys move to the next or previous enabled option and select
/// it, wrapping around, and Home and End jump to the ends. Each option is
/// announced as a radio with its checked state, inside a group named
/// [semanticLabel]. Keyboard focus rings the dot, or the whole card.
///
/// A null [onChanged] disables the group: its rings and labels grey, as a
/// disabled [Check] does, and it leaves the Tab order. [readOnly] shows the
/// value at full contrast without letting it change: still one Tab stop, the
/// arrow keys move focus without selecting, and each option is announced
/// read-only, with no hover (see `FieldState`).
class Choice<T> extends StatefulWidget {
  final List<ChoiceOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final ChoiceStyle style;

  /// Lay the options out horizontally. Plain options hug their labels, best
  /// for a few short ones. Cards share the width evenly and stand as tall as
  /// the tallest; with no width to share, in a horizontal scroll view, each is
  /// as wide as the widest card's content on one line.
  final Axis direction;

  /// The group's accessible name — the question the options answer.
  final String? semanticLabel;

  /// Shows [value] at full contrast, taking no input; see [Choice].
  final bool readOnly;

  const Choice({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
    this.style = ChoiceStyle.plain,
    this.direction = Axis.vertical,
    this.semanticLabel,
    this.readOnly = false,
  });

  @override
  State<Choice<T>> createState() => _ChoiceState<T>();
}

class _ChoiceState<T> extends State<Choice<T>> {
  final _nodes = <FocusNode>[];

  /// Whether the group takes focus: editable, or read-only.
  bool get _live => widget.onChanged != null || widget.readOnly;

  /// Whether option [i] takes focus.
  bool _focusable(int i) => _live && widget.options[i].enabled;

  /// Whether option [i] can be picked.
  bool _enabled(int i) => _focusable(i) && !widget.readOnly;

  /// The option Tab lands on: the selected one when it can take focus, else
  /// the first that can.
  int? get _tabStop {
    final options = widget.options;
    final selected = options.indexWhere((o) => o.value == widget.value);
    if (selected >= 0 && _focusable(selected)) return selected;
    for (var i = 0; i < options.length; i++) {
      if (_focusable(i)) return i;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Choice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _sync() {
    final count = widget.options.length;
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: 'Choice option ${_nodes.length}'));
    }
    while (_nodes.length > count) {
      _nodes.removeLast().dispose();
    }
    final tabStop = _tabStop;
    for (var i = 0; i < count; i++) {
      _nodes[i].skipTraversal = i != tabStop;
    }
  }

  void _select(int i) {
    final value = widget.options[i].value;
    if (value != widget.value) widget.onChanged?.call(value);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!_live || event is KeyUpEvent) return KeyEventResult.ignored;
    final current = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (current < 0) return KeyEventResult.ignored;
    final forward = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    final int? target;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        target = _step(current, 1);
      case LogicalKeyboardKey.arrowUp:
        target = _step(current, -1);
      case LogicalKeyboardKey.arrowRight:
        target = _step(current, forward);
      case LogicalKeyboardKey.arrowLeft:
        target = _step(current, -forward);
      case LogicalKeyboardKey.home:
        target = _step(-1, 1);
      case LogicalKeyboardKey.end:
        target = _step(widget.options.length, -1);
      default:
        return KeyEventResult.ignored;
    }
    if (target != null) {
      _nodes[target].requestFocus();
      if (!widget.readOnly) _select(target);
    }
    return KeyEventResult.handled;
  }

  /// The next focusable option after [from] in [direction], wrapping around;
  /// from just outside either end (Home, End) it doesn't wrap. Null when
  /// none is.
  int? _step(int from, int direction) {
    final count = widget.options.length;
    final wraps = from >= 0 && from < count;
    for (var n = 1; n <= count; n++) {
      var i = from + direction * n;
      if (wraps) {
        i %= count;
      } else if (i < 0 || i >= count) {
        return null;
      }
      if (_focusable(i)) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final vertical = widget.direction == Axis.vertical;
    final options = <Widget>[
      for (final (i, option) in widget.options.indexed)
        _Option<T>(
          option: option,
          selected: option.value == widget.value,
          style: style,
          enabled: _enabled(i),
          readOnly: widget.readOnly && option.enabled,
          groupEnabled: widget.onChanged != null,
          focusNode: _nodes[i],
          onTap: () => _select(i),
        ),
    ];
    // A plain row's 24px target already holds air around its line.
    final gap = vertical ? AdminSpacing.md : AdminSpacing.xl;
    final children = <Widget>[
      for (final (i, option) in options.indexed) ...[
        if (i > 0) Gap(gap),
        option,
      ],
    ];

    return FocusTraversalGroup(
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
          child: vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                )
              : switch (style) {
                  ChoiceStyle.plain => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                  ChoiceStyle.card => _CardRow(spacing: gap, children: options),
                },
        ),
      ),
    );
  }
}

class _Option<T> extends StatelessWidget {
  final ChoiceOption<T> option;
  final bool selected;
  final ChoiceStyle style;
  final bool enabled;

  /// Shown at full contrast, focusable, but taking no input.
  final bool readOnly;

  /// Whether the group takes changes at all; false for a disabled group.
  final bool groupEnabled;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _Option({
    required this.option,
    required this.selected,
    required this.style,
    required this.enabled,
    required this.readOnly,
    required this.groupEnabled,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = style == ChoiceStyle.card;
    // The selected option stays enabled and focusable (it holds the Tab
    // stop); tapping it again changes nothing.
    final option = Tappable.states(
      key: this.option.key,
      onTap: enabled ? onTap : null,
      readOnly: readOnly,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusNode: focusNode,
      statesController: this.option.statesController,
      showFocusRing: false,
      builder: (context, states) {
        final hovered =
            enabled && !selected && states.contains(WidgetState.hovered);
        final focused = states.contains(WidgetState.focused);
        return card
            ? _card(context, hovered: hovered, focused: focused)
            : _plain(context, hovered: hovered, focused: focused);
      },
    );
    if (card) return option;
    // A plain row hugs its label, so the empty space beside it isn't a target.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: option,
    );
  }

  /// Drawn in full colour: an enabled or read-only option, or the value of a
  /// group that takes changes even though this option doesn't. A disabled
  /// group dims its selection too, as a disabled Check or Toggle does.
  bool get _live => enabled || readOnly || (selected && groupEnabled);

  Color _labelColor(AdminPalette colors) =>
      _live ? colors.foreground : colors.foregroundSubtle;

  Widget _dot({required bool hovered}) =>
      _Dot(selected: selected, enabled: _live, hovered: hovered);

  Widget _plain(
    BuildContext context, {
    required bool hovered,
    required bool focused,
  }) {
    final color = _labelColor(context.colors);
    final style = context.type.body.copyWith(color: color);
    return minTarget(
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          onFirstLine(
            context,
            FocusRing(
              focused: focused,
              radius: context.selectionStyle.radioSize / 2,
              child: _dot(hovered: hovered),
            ),
            option.label,
            style,
          ),
          const Gap(AdminSpacing.md),
          if (option.icon != null) ...[
            onFirstLine(
              context,
              Icon(option.icon, size: context.iconSizes.md, color: color),
              option.label,
              style,
            ),
            const Gap(AdminSpacing.sm),
          ],
          Flexible(child: Text(option.label, style: style)),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required bool hovered,
    required bool focused,
  }) {
    final colors = context.colors;
    final radius = BorderRadius.circular(context.radii.radius);
    final color = _labelColor(colors);
    final style = context.type
        .weighted(context.type.body, FontWeight.w600)
        .copyWith(color: color);
    final live = _live;
    final edge = selected && live
        ? colors.controlAccent
        : colors.foregroundSubtle;
    final Color fill;
    if (selected && live) {
      fill = colors.primaryFaint;
    } else if (hovered) {
      fill = Color.alphaBlend(colors.hoverOverlay, colors.surface);
    } else {
      fill = colors.surface;
    }
    return FocusRing(
      focused: focused,
      radius: context.radii.radius,
      child: Container(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: radius,
          border: Border.all(color: selected ? edge : colors.border),
        ),
        // The selected card's heavier edge is painted over the resting border,
        // inside it, so selecting never changes the card's size.
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: edge,
                  width: context.stroke.controlStrong,
                ),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            onFirstLine(context, _dot(hovered: hovered), option.label, style),
            const Gap(AdminSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (option.icon != null) ...[
                        onFirstLine(
                          context,
                          Icon(
                            option.icon,
                            size: context.iconSizes.md,
                            color: color,
                          ),
                          option.label,
                          style,
                        ),
                        const Gap(AdminSpacing.sm),
                      ],
                      Flexible(child: Text(option.label, style: style)),
                    ],
                  ),
                  if (option.description != null) ...[
                    const Gap(AdminSpacing.xxs),
                    Text(
                      option.description!,
                      style: context.type.caption.copyWith(
                        color: live
                            ? colors.foregroundMutedOnTint
                            : colors.foregroundSubtle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The radio: a ring ([AdminSelectionStyle.outlineOf],
/// [AdminStroke.controlStrong] wide) that takes
/// [AdminSelectionStyle.hoverOutlineOf] under the pointer. Selected, the
/// theme's [RadioMark]: a disc in the ink around a dot in its on-colour, as a
/// checked Check's glyph and an on Toggle's knob, or the ring in the ink
/// around a dot in the ink. Otherwise the centre is the surface colour.
/// Disabled, the mark drops to the disabled grey — the stronger one when
/// selected, as a disabled Check's fill does.
class _Dot extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final bool hovered;

  const _Dot({
    required this.selected,
    required this.enabled,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.selectionStyle;
    final Color ring;
    if (!enabled) {
      ring = selected ? colors.foregroundSubtle : colors.foregroundFaint;
    } else if (selected) {
      ring = style.inkOf(colors);
    } else if (hovered) {
      ring = style.hoverOutlineOf(colors);
    } else {
      ring = style.outlineOf(colors);
    }
    final disc = style.radioMark == RadioMark.disc;
    final size = style.radioSize;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: disc && selected && enabled
            ? style.onInkOf(colors)
            : colors.surface,
        // A selected disc is a ring as thick as leaves its dot showing.
        border: Border.all(
          color: ring,
          width: disc && selected
              ? (size - style.radioDot) / 2
              : context.stroke.controlStrong,
        ),
      ),
      child: !disc && selected
          ? SizedBox.square(
              dimension: style.radioDot,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
              ),
            )
          : null,
    );
  }
}

/// Cards side by side, all one width and as tall as the tallest. A bounded
/// width is shared evenly; with none, each card is as wide as the widest
/// card's content wants.
class _CardRow extends MultiChildRenderObjectWidget {
  final double spacing;

  const _CardRow({required this.spacing, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCardRow(
    spacing: spacing,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderCardRow renderObject) {
    renderObject
      ..spacing = spacing
      ..textDirection = Directionality.of(context);
  }
}

class _CardRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderCardRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CardRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CardRowParentData> {
  _RenderCardRow({required this._spacing, required this._textDirection});

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
    if (child.parentData is! _CardRowParentData) {
      child.parentData = _CardRowParentData();
    }
  }

  double get _gaps => math.max(0, childCount - 1) * _spacing;

  double _most(double Function(RenderBox child) extent) {
    var most = 0.0;
    var child = firstChild;
    while (child != null) {
      most = math.max(most, extent(child));
      child = childAfter(child);
    }
    return most;
  }

  /// Each card's width: a share of a bounded width, else the widest card's.
  double _cardWidth(double maxWidth) {
    if (childCount == 0) return 0;
    if (maxWidth.isFinite) return math.max(0, (maxWidth - _gaps) / childCount);
    return _most((c) => c.getMaxIntrinsicWidth(double.infinity));
  }

  double _width(double card) => card * childCount + _gaps;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _width(_most((c) => c.getMinIntrinsicWidth(height)));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _width(_most((c) => c.getMaxIntrinsicWidth(height)));

  @override
  double computeMinIntrinsicHeight(double width) {
    final card = _cardWidth(width);
    return _most((c) => c.getMinIntrinsicHeight(card));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final card = _cardWidth(width);
    return _most((c) => c.getMaxIntrinsicHeight(card));
  }

  /// The width every card takes under [constraints], and the height of the
  /// tallest at that width, as [heightOf] measures it.
  ({double width, double height}) _measure(
    BoxConstraints constraints,
    double Function(RenderBox child, BoxConstraints natural) heightOf,
  ) {
    final width = _cardWidth(constraints.maxWidth);
    final natural = BoxConstraints.tightFor(width: width);
    final height = _most((c) => heightOf(c, natural));
    return (width: width, height: constraints.constrainHeight(height));
  }

  /// A card at [width], at least [height] tall. Not tight, so that a card
  /// whose content grows lays the row out again, and the others with it; and
  /// open below, as in a column, where a card's content would fill a bound.
  BoxConstraints _card(double width, double height) =>
      BoxConstraints(minWidth: width, maxWidth: width, minHeight: height);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final (:width, :height) = _measure(
      constraints,
      (c, natural) => c.getDryLayout(natural).height,
    );
    return constraints.constrain(Size(_width(width), height));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final (:width, :height) = _measure(
      constraints,
      (c, natural) => c.getDryLayout(natural).height,
    );
    final card = _card(width, height);
    var result = BaselineOffset.noBaseline;
    var child = firstChild;
    while (child != null) {
      result = result.minOf(
        BaselineOffset(child.getDryBaseline(card, baseline)),
      );
      child = childAfter(child);
    }
    return result.offset;
  }

  @override
  void performLayout() {
    final (:width, :height) = _measure(constraints, (c, natural) {
      c.layout(natural, parentUsesSize: true);
      return c.size.height;
    });
    size = constraints.constrain(Size(_width(width), height));
    final card = _card(width, height);
    final rtl = _textDirection == TextDirection.rtl;
    var x = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(card, parentUsesSize: true);
      final data = child.parentData! as _CardRowParentData;
      data.offset = Offset(rtl ? size.width - x - width : x, 0);
      x += width + _spacing;
      child = data.nextSibling;
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
