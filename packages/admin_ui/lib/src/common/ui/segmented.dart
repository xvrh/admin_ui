/// @docImport 'button.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/field_style.dart';
import '../../theme/palette.dart';
import '../../theme/segmented_style.dart';
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

/// A single-select control for 2–4 either/or choices: a row of segments,
/// one of them selected. For many options or wrapping pills use a select
/// field instead; to move between pages or panels use `Tabs`, and for a row
/// of actions, buttons.
///
/// The theme's [AdminSegmentedStyle] draws it as its reference system does
/// (see `context.segmentedStyle`): a recessed track whose selected segment
/// is a raised knob that slides between them (Iris, Ant, shadcn, Fluent), or
/// segments joined in one outline, the selected one filled (M3 with its
/// check, Carbon in the foreground). Either takes a [Button]'s corner at its
/// [size] unless the style names one, so it lines up with the buttons and
/// fields beside it in a toolbar.
///
/// A null [onChanged] disables it: the labels grey, the selection keeps its
/// knob, or in joined segments a soft fill in a neutral tone (a disabled
/// filled button's), so it never outweighs an enabled selection, and it
/// leaves the Tab order.
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

class _SegmentedState<T> extends State<Segmented<T>>
    with SingleTickerProviderStateMixin {
  final _nodes = <FocusNode>[];
  final _ownStates = <WidgetStatesController>[];
  List<WidgetStatesController> _states = const [];
  bool _focused = false;

  /// Where a track's knob stands: the index of the segment it sits on, or a
  /// fraction between two while it slides from one to the other.
  late final AnimationController _knob = AnimationController.unbounded(
    vsync: this,
    value: math.max(0, _selected).toDouble(),
  );

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

  /// The selected segment, or -1 when none has the value.
  int get _selected =>
      widget.segments.indexWhere((s) => s.value == widget.value);

  /// The segment Tab lands on: the selected one, else the first.
  int get _tabStop {
    final i = _selected;
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
    final from = oldWidget.segments.indexWhere(
      (s) => s.value == oldWidget.value,
    );
    final to = _selected;
    if (to < 0 || to == from) return;
    if (from < 0) {
      _knob.value = to.toDouble();
    } else {
      final motion = context.motion;
      _knob.animateTo(
        to.toDouble(),
        duration: motion.medium,
        curve: motion.standard,
      );
    }
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onFontsChanged);
    _knob.dispose();
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
    final style = context.segmentedStyle;
    final colors = context.colors;
    final hairline = context.stroke.hairline;
    final radius = style.radius ?? context.radii.button(widget.size);
    final track = style.variant == SegmentedVariant.track;
    // A track's outline, inside which the segments run its full height.
    final outline = track && style.trackOutline ? hairline : 0.0;
    final metrics = _Metrics.of(
      context,
      widget.size,
      outline: outline,
      inset: track ? style.inset : 0,
      track: track,
    );
    final corner = math.max(0.0, radius - outline - metrics.inset);
    final segments = widget.segments;
    final selected = _selected;
    final last = segments.length - 1;
    final floors = [
      for (var i = 0; i <= last; i++)
        metrics.floor(segments[i], checkmark: style.checkmark) +
            (i == 0 ? metrics.inset : 0) +
            (i == last ? metrics.inset : 0),
    ];
    final children = [
      for (var i = 0; i <= last; i++)
        _segment(context, i, metrics, style, track ? corner : 0),
    ];

    final Widget strip;
    final BoxDecoration decoration;
    BoxDecoration? foreground;
    if (track) {
      strip = _SegmentStrip(
        height: metrics.height,
        expand: widget.expand,
        gap: 0,
        dividers: const [],
        floors: floors,
        knob: selected < 0 ? null : _knob,
        inset: metrics.inset,
        children: [
          if (selected >= 0)
            IgnorePointer(
              child: DecoratedBox(
                decoration: _knobDecoration(context, corner, live: _live),
                child: style.indicator
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: _pill(context, live: _live),
                      )
                    : null,
              ),
            ),
          ...children,
        ],
      );
      decoration = _trackDecoration(context, radius);
    } else {
      // The dividers match the outline, as M3's segments share theirs; an
      // inverse style divides in hairlines, which the selected fill
      // swallows.
      final edge = _joinedOutline(context, live: _live);
      final fill = _selectedFill(colors, style, live: _live);
      strip = _SegmentStrip(
        height: metrics.height,
        expand: widget.expand,
        gap: hairline,
        dividers: [
          for (var i = 0; i < segments.length - 1; i++)
            style.inverse && (i == selected || i + 1 == selected)
                ? fill
                : style.inverse
                ? colors.border
                : edge.color,
        ],
        floors: floors,
        children: children,
      );
      decoration = BoxDecoration(borderRadius: BorderRadius.circular(radius));
      // Border on top of the clipped children — drawing it in `decoration`
      // lets the anti-aliased clip crop the rounded corners.
      foreground = BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge.color, width: edge.width),
      );
    }

    Widget group = Container(
      clipBehavior: track ? Clip.none : Clip.antiAlias,
      decoration: decoration,
      foregroundDecoration: foreground,
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

  Widget _segment(
    BuildContext context,
    int i,
    _Metrics m,
    AdminSegmentedStyle style,
    double corner,
  ) {
    final colors = context.colors;
    final seg = widget.segments[i];
    final selected = seg.value == widget.value;
    final editable = _editable;
    final live = _live;
    final iconOnly = seg._iconOnly;
    // M3's check takes the place of the selected segment's icon, or comes
    // before its label; an icon-only segment keeps its icon.
    final check = style.checkmark && selected && !iconOnly;
    final glyph = check ? Icons.check_rounded : seg.icon;
    // A label-only segment keeps the check's room either side of its label
    // while it is not selected, so it is as wide either way.
    final reserve = style.checkmark && !iconOnly && seg.icon == null && !check
        ? (m.icon + m.gap) / 2
        : 0.0;

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
        final (:fill, :ink) = _segmentInk(
          colors,
          style,
          selected: selected,
          live: live,
          hovered: hovered,
          pressed: pressed,
        );
        // On a track a segment runs the control's full height, so its whole
        // band takes the tap, and draws its wash and label the track's inset
        // in from the track's edge, where the knob sits.
        final first = i == 0;
        final last = i == widget.segments.length - 1;
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: first ? m.inset : 0,
            end: last ? m.inset : 0,
            top: m.inset,
            bottom: m.inset,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: corner > 0 ? BorderRadius.circular(corner) : null,
            ),
            child: Padding(
              // Above an indicator, the labels rise by half its height, as
              // Fluent's do above its pill.
              padding: EdgeInsets.only(
                left: m.padX(seg) + reserve,
                right: m.padX(seg) + reserve,
                bottom: style.indicator ? context.stroke.indicator : 0,
              ),
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (glyph != null) Icon(glyph, size: m.icon, color: ink),
                    if (glyph != null && !iconOnly) Gap(m.gap),
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
                              .weighted(m.text(context), style.labelWeight)
                              .copyWith(color: ink),
                        ),
                      ),
                  ],
                ),
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

/// One segment's fill and ink. On a track the labels take the on-tint muted
/// shade, which holds 4.5:1 on the track's wash, and the foreground under
/// the pointer, where a hovered segment's wash can't pass for the raised
/// knob; the segments are clear, the knob drawn behind the selected one.
/// Joined segments are filled on the group's surface, and muted text keeps
/// its on-tint shade on the hover and press tints — still muted, like
/// shadcn's toggle, so a hovered segment never passes for the selected one
/// where the selection is soft; an inverse selection is unmistakable, so a
/// hover there takes the foreground, as Carbon's does.
({Color fill, Color ink}) _segmentInk(
  AdminPalette colors,
  AdminSegmentedStyle style, {
  required bool selected,
  required bool live,
  required bool hovered,
  required bool pressed,
}) {
  const clear = Color(0x00000000);
  final track = style.variant == SegmentedVariant.track;
  final Color ink;
  if (!live) {
    ink = colors.foregroundSubtle;
  } else if (selected) {
    ink = track
        ? colors.foreground
        : style.inverse
        ? colors.foregroundOn(colors.foreground)
        : colors.onSoft;
  } else if (hovered || pressed) {
    ink = track || style.inverse
        ? colors.foreground
        : colors.foregroundMutedOnTint;
  } else {
    ink = track ? colors.foregroundMutedOnTint : colors.foregroundMuted;
  }
  final Color fill;
  if (selected) {
    fill = track ? clear : _selectedFill(colors, style, live: live);
  } else if (pressed) {
    fill = track
        ? colors.pressedOverlay
        : Color.alphaBlend(colors.pressedOverlay, colors.surface);
  } else if (hovered) {
    fill = track
        ? colors.hoverOverlay
        : Color.alphaBlend(colors.hoverOverlay, colors.surface);
  } else {
    fill = track ? clear : colors.surface;
  }
  return (fill: fill, ink: ink);
}

/// The selected segment's fill in joined segments: the foreground in an
/// inverse style, else the soft fill; disabled, a disabled filled button's
/// neutral tone, so it never outweighs an enabled selection.
Color _selectedFill(
  AdminPalette colors,
  AdminSegmentedStyle style, {
  required bool live,
}) {
  if (!live) return Color.alphaBlend(colors.pressedOverlay, colors.surface);
  return style.inverse ? colors.foreground : colors.softFill;
}

/// A track: recessed by the hover wash, so it reads on a card and on the
/// page alike, and ringed in a hairline where the style asks.
BoxDecoration _trackDecoration(BuildContext context, double radius) {
  final colors = context.colors;
  return BoxDecoration(
    color: colors.hoverOverlay,
    borderRadius: BorderRadius.circular(radius),
    border: context.segmentedStyle.trackOutline
        ? Border.all(color: colors.border, width: context.stroke.hairline)
        : null,
  );
}

/// A track's knob, [corner] round: the surface lifted by a shadow on a light
/// page, ringed in a hairline where the style asks; on a dark page, where a
/// shadow does not read, a step lighter than the surface and always ringed.
/// Disabled, it rests flat.
BoxDecoration _knobDecoration(
  BuildContext context,
  double corner, {
  required bool live,
}) {
  final colors = context.colors;
  final dark = colors.brightness == Brightness.dark;
  return BoxDecoration(
    color: dark
        ? Color.alphaBlend(colors.pressedOverlay, colors.surface)
        : colors.surface,
    borderRadius: BorderRadius.circular(corner),
    border: context.segmentedStyle.knobOutline || dark
        ? Border.all(color: colors.border, width: context.stroke.hairline)
        : null,
    boxShadow: live && !dark ? context.elevation.sm : null,
  );
}

/// Fluent's selection pill, 16 wide, for the knob's foot: the accent, or
/// the disabled grey.
Widget _pill(BuildContext context, {required bool live}) {
  final colors = context.colors;
  final height = context.stroke.indicator;
  return Container(
    width: 16,
    height: height,
    decoration: BoxDecoration(
      color: live ? colors.controlAccent : colors.foregroundSubtle,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}

/// Joined segments' outline: a field's resting edge, so they line up with
/// the search box and selects beside them in a toolbar — its outline, or in
/// a filled theme its bottom rule, which is the edge that holds 3:1 there —
/// or, in an inverse style, the foreground.
BorderSide _joinedOutline(BuildContext context, {required bool live}) {
  if (context.segmentedStyle.inverse && live) {
    return BorderSide(
      color: context.colors.foreground,
      width: context.stroke.hairline,
    );
  }
  final states = {if (!live) WidgetState.disabled};
  final chrome = resolveFieldChrome(context.adminTokens, states);
  return chrome.variant == FieldVariant.filled
      ? chrome.rule
      : fieldBorderSide(context.colors, states, stroke: context.stroke);
}

/// A toggle button drawn as a lone segment of a [Segmented] at the medium
/// size, to sit beside one in a toolbar: [active], it is a selected
/// segment — its knob raised in its track, or filled in its outline — and
/// otherwise an unselected one. Announced as a button with its selected
/// state.
@internal
class SegmentToggle extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const SegmentToggle({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = context.segmentedStyle;
    final colors = context.colors;
    final track = style.variant == SegmentedVariant.track;
    final radius = style.radius ?? context.radii.button(ControlSize.medium);
    final outline = track && style.trackOutline ? context.stroke.hairline : 0.0;
    final m = _Metrics.of(
      context,
      ControlSize.medium,
      outline: outline,
      inset: track ? style.inset : 0,
      track: track,
    );
    final corner = math.max(0.0, radius - outline - m.inset);
    // As in a segment, M3's check takes the icon's place, and a label-only
    // toggle keeps its room while off.
    final check = style.checkmark && active;
    final glyph = check ? Icons.check_rounded : icon;
    final reserve = style.checkmark && icon == null && !active
        ? (m.icon + m.gap) / 2
        : 0.0;
    return Tappable.states(
      onTap: onTap,
      selected: active,
      focusRadius: radius,
      builder: (context, states) {
        final (:fill, :ink) = _segmentInk(
          colors,
          style,
          selected: active,
          live: true,
          hovered: states.contains(WidgetState.hovered),
          pressed: states.contains(WidgetState.pressed),
        );
        final content = Padding(
          padding: EdgeInsets.only(
            left: m.labelPadX + reserve,
            right: m.labelPadX + reserve,
            bottom: style.indicator && active ? context.stroke.indicator : 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyph != null) ...[
                Icon(glyph, size: m.icon, color: ink),
                Gap(m.gap),
              ],
              // Ellipsized where the toolbar leaves it less than its label.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type
                      .weighted(m.text(context), style.labelWeight)
                      .copyWith(color: ink),
                ),
              ),
            ],
          ),
        );
        if (!track) {
          final outline = _joinedOutline(context, live: true);
          return Container(
            height: m.height,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.fromBorderSide(outline),
            ),
            child: content,
          );
        }
        return Container(
          height: m.height + outline * 2,
          padding: EdgeInsets.all(m.inset),
          decoration: _trackDecoration(context, radius),
          child: DecoratedBox(
            decoration: active
                ? _knobDecoration(context, corner, live: true)
                : BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(corner),
                  ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                content,
                if (style.indicator && active)
                  Positioned(bottom: 0, child: _pill(context, live: true)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sizes for each [ControlSize], as a [Button] of that size takes them: small
/// takes the small body text, the small glyph and tighter padding, medium and
/// large the body text and the control glyph. On a track the segments pad
/// their labels less, the knob's [inset] making up the difference.
class _Metrics {
  /// The segments' height: the control's, less a track's outline above and
  /// below.
  final double height;

  /// How far in from a track's edge a segment draws its wash and the knob
  /// sits; zero in joined segments.
  final double inset;
  final double icon;
  final double gap;
  final double _padX;
  final bool _small;

  const _Metrics(
    this.height,
    this.inset,
    this.icon,
    this.gap,
    this._padX,
    this._small,
  );

  /// The control height is taller by as much as the labels grow at a large
  /// text size.
  static _Metrics of(
    BuildContext context,
    ControlSize size, {
    double outline = 0,
    double inset = 0,
    bool track = false,
  }) {
    final sizes = context.sizes;
    final type = context.type;
    final icons = context.iconSizes;
    return size == ControlSize.small
        ? _Metrics(
            sizes.small + textGrowthOf(context, type.bodySmall) - outline * 2,
            inset,
            icons.sm,
            AdminSpacing.sm,
            track ? AdminSpacing.md : AdminSpacing.lg,
            true,
          )
        : _Metrics(
            sizes.height(size) + textGrowthOf(context, type.body) - outline * 2,
            inset,
            icons.md,
            AdminSpacing.sm,
            track ? AdminSpacing.lg : AdminSpacing.xl,
            false,
          );
  }

  TextStyle text(BuildContext context) =>
      _small ? context.type.bodySmall : context.type.body;

  /// A labelled segment's padding either side.
  double get labelPadX => _padX;

  /// Icon-only segments are square, inside the inset.
  double padX(SegmentOption<Object?> seg) =>
      seg._iconOnly ? (height - inset * 2 - icon) / 2 : _padX;

  /// The narrowest a segment gets: its padding and icon (or, with a
  /// [checkmark], the check's room), with the label ellipsized away.
  double floor(SegmentOption<Object?> seg, {bool checkmark = false}) {
    final glyph = seg.icon != null || (checkmark && !seg._iconOnly);
    return padX(seg) * 2 + (glyph ? icon + (seg._iconOnly ? 0 : gap) : 0);
  }
}

/// Lays the segments out in a row, [height] tall, [gap] apart, painting
/// each gap in its [dividers] entry. Each segment takes its natural width
/// while they all fit; short of room the widest shrink first, to an equal
/// share of what's left, never below its [floors] entry. With [expand] a
/// bounded width is split equally. The first segment sits at the start edge:
/// the right, in right-to-left text.
///
/// With a [knob], the first child is the knob: laid out behind the segments
/// over the one the knob's value indexes, or between two while the value is
/// a fraction, [inset] in from the strip's edges.
class _SegmentStrip extends MultiChildRenderObjectWidget {
  final double height;
  final bool expand;
  final double gap;
  final List<Color> dividers;
  final List<double> floors;
  final Animation<double>? knob;
  final double inset;

  const _SegmentStrip({
    required this.height,
    required this.expand,
    required this.gap,
    required this.dividers,
    required this.floors,
    this.knob,
    this.inset = 0,
    required super.children,
  });

  @override
  _RenderSegmentStrip createRenderObject(BuildContext context) =>
      _RenderSegmentStrip(
        height: height,
        expand: expand,
        gap: gap,
        dividers: dividers,
        floors: floors,
        knob: knob,
        inset: inset,
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
      ..gap = gap
      ..dividers = dividers
      ..floors = floors
      ..knob = knob
      ..inset = inset
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
    required this._gap,
    required this._dividers,
    required this._floors,
    required this._knob,
    required this._inset,
    required this._textDirection,
  });

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

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  List<Color> _dividers;
  set dividers(List<Color> value) {
    if (listEquals(value, _dividers)) return;
    _dividers = value;
    markNeedsPaint();
  }

  List<double> _floors;
  set floors(List<double> value) {
    if (listEquals(value, _floors)) return;
    _floors = value;
    markNeedsLayout();
  }

  /// The knob's place, which moves it without touching the segments.
  Animation<double>? _knob;
  set knob(Animation<double>? value) {
    if (value == _knob) return;
    if (attached) _knob?.removeListener(markNeedsLayout);
    _knob = value;
    if (attached) _knob?.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  double _inset;
  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
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
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _knob?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _knob?.removeListener(markNeedsLayout);
    super.detach();
  }

  /// The knob, the first child, when there is one.
  RenderBox? get _knobBox => _knob == null ? null : firstChild;

  /// The first segment: the first child, or the second behind a knob.
  RenderBox? get _firstSegment =>
      _knob == null ? firstChild : childAfter(firstChild!);

  /// The segments, in order.
  Iterable<RenderBox> get _segments sync* {
    for (var child = _firstSegment; child != null; child = childAfter(child)) {
      yield child;
    }
  }

  int get _segmentCount => childCount - (_knob == null ? 0 : 1);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StripParentData) {
      child.parentData = _StripParentData();
    }
  }

  double _floor(int i) => i < _floors.length ? _floors[i] : 0;

  double get _gaps => _segmentCount < 2 ? 0 : _gap * (_segmentCount - 1);

  /// Each segment's width with its whole label, rounded up: some fonts lay
  /// out a hair wider than they measure, which would ellipsize a label that
  /// fits.
  List<double> _natural() {
    final widths = <double>[];
    for (final child in _segments) {
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
      _sum([for (var i = 0; i < _segmentCount; i++) _floor(i)]) + _gaps;

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
    final rects = <Rect>[];
    for (final child in _segments) {
      child.layout(
        BoxConstraints.tightFor(width: widths[i], height: height),
        parentUsesSize: true,
      );
      final offset = Offset(_rtl ? size.width - x - widths[i] : x, 0);
      (child.parentData! as _StripParentData).offset = offset;
      // Where the segment draws: [_inset] in from the strip's edges.
      final first = i == 0;
      final last = i == widths.length - 1;
      final start = first ? _inset : 0.0;
      final end = last ? _inset : 0.0;
      rects.add(
        Rect.fromLTRB(
          offset.dx + (_rtl ? end : start),
          _inset,
          offset.dx + child.size.width - (_rtl ? start : end),
          child.size.height - _inset,
        ),
      );
      x += widths[i] + _gap;
      i++;
    }
    final knob = _knobBox;
    if (knob != null) {
      final rect = _knobRect(rects);
      knob.layout(BoxConstraints.tight(rect.size));
      (knob.parentData! as _StripParentData).offset = rect.topLeft;
    }
  }

  /// The knob's box: over the segment its value indexes, or between two.
  Rect _knobRect(List<Rect> rects) {
    if (rects.isEmpty) return Rect.zero;
    final at = _knob!.value.clamp(0.0, rects.length - 1.0);
    final i = at.floor();
    final j = math.min(i + 1, rects.length - 1);
    return Rect.lerp(rects[i], rects[j], at - i)!;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_gap > 0) {
      final paint = Paint();
      var i = 0;
      for (final child in _segments) {
        if (childAfter(child) == null || i >= _dividers.length) break;
        final left = (child.parentData! as _StripParentData).offset.dx;
        context.canvas.drawRect(
          Rect.fromLTWH(
            offset.dx + (_rtl ? left - _gap : left + child.size.width),
            offset.dy,
            _gap,
            size.height,
          ),
          paint..color = _dividers[i],
        );
        i++;
      }
    }
    // The knob, the first child, under the segments.
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
