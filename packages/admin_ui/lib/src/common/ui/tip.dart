/// @docImport 'menu.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'popover.dart';

/// A token-styled tooltip — hover (or long-press) [child] to reveal [message].
///
/// Built on Material's [Tooltip]; the chip's fill, radius, padding, type and
/// maximum width (`context.overlayStyle.tooltipMaxWidth`) come from the
/// `tooltipTheme` baked into the admin [ThemeData], so a bare `Tooltip` gets
/// the same chip — plain, centred below its child. What a bare one lacks, a
/// Tip adds: it opens on any [side] of [child], lined up by [align], and
/// flips where that side has no room, as a [Popover] does, mirrored right to
/// left; it points at [child] with an arrow where the theme's tooltips do
/// ([showArrow]); it takes its own [waitDuration]; and it shows a [shortcut]
/// after the message.
///
/// A Tip also opens while keyboard focus is inside [child] (in the keyboard
/// highlight mode only, so a click never opens it), and closes when focus
/// leaves or on Escape.
class Tip extends StatefulWidget {
  final String message;
  final Widget child;

  /// The side of [child] the chip opens on. Where it does not fit there, it
  /// flips to the opposite side when that has more room.
  final PopoverSide side;

  /// Where the chip lines up along [side]: its middle on [child]'s middle
  /// by default.
  final PopoverAlign align;

  /// The distance from [child] to the chip, or to its arrow's tip.
  ///
  /// Null takes 4 beside [child] or with an arrow. Above or below [child],
  /// a chip without an arrow keeps a bare [Tooltip]'s distance instead: its
  /// near edge the tooltip theme's `verticalOffset` (24) from [child]'s
  /// middle, clear of the pointer resting there.
  final double? gap;

  /// How long the pointer rests on [child] before the chip opens: the
  /// tooltip theme's 400ms when null. Focus opens it at once.
  final Duration? waitDuration;

  /// Whether the chip points at [child] with an arrow, sized by
  /// `context.overlayStyle`. Null takes the theme's
  /// `context.overlayStyle.tooltipArrow`: on in shadcn, Ant, Fluent and
  /// Carbon, off in Iris and Material.
  final bool? showArrow;

  /// A key hint after [message], muted, such as '⌘S'. It reads left to
  /// right in either direction, as a [MenuItem]'s does, and a screen reader
  /// hears it after the message.
  final String? shortcut;

  /// Keeps [message] out of the semantics tree — for a child that already
  /// announces the same text as its label, so it is read once.
  final bool excludeFromSemantics;

  const Tip({
    super.key,
    required this.message,
    required this.child,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.center,
    this.gap,
    this.waitDuration,
    this.showArrow,
    this.shortcut,
    this.excludeFromSemantics = false,
  });

  @override
  State<Tip> createState() => _TipState();
}

/// The gap a chip keeps from its target where [Tip.gap] leaves it to the
/// Tip: beside the target, or to the tip of an arrow.
const _gap = 4.0;

/// The margin a chip keeps from the viewport's edges: a bare [Tooltip]'s.
const _margin = 10.0;

class _TipState extends State<Tip> {
  final _tooltip = GlobalKey<TooltipState>();

  /// Where the chip's layout last put it, for the arrow its decoration
  /// paints.
  late final _placement = ValueNotifier(
    PopoverPlacement(side: widget.side, align: widget.align),
  );

  /// Whether the tooltip is up because focus arrived, and so is this tip's to
  /// close again.
  bool _shownForFocus = false;

  bool _focused = false;

  @override
  void dispose() {
    _placement.dispose();
    super.dispose();
  }

  void _onFocusChange(bool focused) {
    _focused = focused;
    if (focused) {
      // Opened once the focus change settles: the tip that focus is leaving
      // is notified after this one, and its close dismisses every open
      // tooltip.
      scheduleMicrotask(_showForFocus);
    } else {
      _hide();
    }
  }

  void _showForFocus() {
    if (!mounted || !_focused || _shownForFocus) return;
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return;
    }
    _shownForFocus = _tooltip.currentState?.ensureTooltipVisible() ?? false;
  }

  bool _hide() {
    if (!_shownForFocus) return false;
    _shownForFocus = false;
    // Material exposes no per-tooltip dismiss; while keyboard focus drives
    // the tooltips there is no other one to keep.
    return Tooltip.dismissAllToolTips();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _hide()) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final overlay = context.overlayStyle;
    final arrow = widget.showArrow ?? overlay.tooltipArrow;
    final direction = Directionality.of(context);
    final chip =
        TooltipTheme.of(context).decoration ??
        BoxDecoration(
          color: context.colors.foreground,
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        );
    final fill = switch (chip) {
      BoxDecoration(:final color?) => color,
      _ => context.colors.foreground,
    };
    final radius = switch (chip) {
      BoxDecoration(:final borderRadius?) =>
        borderRadius.resolve(direction).topLeft.x,
      _ => context.radii.radiusSmall,
    };

    Offset position(TooltipPositionContext at) {
      final beside =
          widget.side == PopoverSide.start || widget.side == PopoverSide.end;
      final placed = placePopover(
        anchor: Rect.fromCenter(
          center: at.target,
          width: at.targetSize.width,
          height: at.targetSize.height,
        ),
        child: at.tooltipSize,
        viewport: at.overlaySize,
        side: widget.side,
        align: widget.align,
        gap:
            widget.gap ??
            (beside || arrow
                ? _gap
                : at.verticalOffset - at.targetSize.height / 2),
        arrowHeight: arrow ? overlay.arrowHeight : 0,
        arrowPadding: arrow ? radius + overlay.arrowWidth / 2 : 0,
        textDirection: direction,
        margin: _margin,
      );
      _placement.value = placed.placement;
      return placed.offset;
    }

    final shortcut = widget.shortcut;
    Widget tooltip = Tooltip(
      key: _tooltip,
      message: shortcut == null ? widget.message : null,
      richMessage: shortcut == null
          ? null
          : TextSpan(
              text: widget.message,
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _Shortcut(shortcut, fill: fill),
                ),
              ],
            ),
      decoration: arrow
          ? _ArrowChip(
              chip: chip,
              fill: fill,
              placement: _placement,
              textDirection: direction,
              arrowWidth: overlay.arrowWidth,
              arrowHeight: overlay.arrowHeight,
            )
          : null,
      waitDuration: widget.waitDuration,
      positionDelegate: position,
      // The rich message's plain text holds the shortcut as a placeholder
      // character; the tip announces it itself, below.
      excludeFromSemantics: widget.excludeFromSemantics || shortcut != null,
      child: widget.child,
    );
    if (shortcut != null && !widget.excludeFromSemantics) {
      tooltip = Semantics(
        tooltip: '${widget.message} $shortcut',
        child: tooltip,
      );
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _onFocusChange,
      onKeyEvent: _onKeyEvent,
      child: tooltip,
    );
  }
}

/// [Tip.shortcut] in the chip: the chip's type, muted toward its fill.
class _Shortcut extends StatelessWidget {
  final String keys;
  final Color fill;

  const _Shortcut(this.keys, {required this.fill});

  @override
  Widget build(BuildContext context) {
    final text = DefaultTextStyle.of(context).style.color ?? fill;
    // Most of the way to the message's colour, then back toward it as far
    // as reading on the chip needs.
    final muted = context.colors.readableOn(
      Color.lerp(fill, text, 0.7)!,
      surfaces: [fill],
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AdminSpacing.md),
      child: Text(
        keys,
        // Physical: shortcuts read left to right.
        textDirection: TextDirection.ltr,
        style: TextStyle(color: muted),
      ),
    );
  }
}

/// The tooltip theme's [chip], with an arrow on its edge that faces the
/// target, where the tooltip's layout put it in [placement].
///
/// The layout runs before the chip paints, so the arrow is where the chip
/// is in the frame that places it; a later move repaints it.
class _ArrowChip extends Decoration {
  final Decoration chip;
  final Color fill;
  final ValueListenable<PopoverPlacement> placement;
  final TextDirection textDirection;
  final double arrowWidth;
  final double arrowHeight;

  const _ArrowChip({
    required this.chip,
    required this.fill,
    required this.placement,
    required this.textDirection,
    required this.arrowWidth,
    required this.arrowHeight,
  });

  @override
  EdgeInsetsGeometry get padding => chip.padding;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _ArrowChipPainter(this, onChanged);

  @override
  bool operator ==(Object other) =>
      other is _ArrowChip &&
      other.chip == chip &&
      other.fill == fill &&
      other.placement == placement &&
      other.textDirection == textDirection &&
      other.arrowWidth == arrowWidth &&
      other.arrowHeight == arrowHeight;

  @override
  int get hashCode => Object.hash(
    chip,
    fill,
    placement,
    textDirection,
    arrowWidth,
    arrowHeight,
  );
}

class _ArrowChipPainter extends BoxPainter {
  final _ArrowChip _decoration;
  final BoxPainter _chip;
  final PopoverArrowPainter _arrow;

  _ArrowChipPainter(this._decoration, VoidCallback? onChanged)
    : _chip = onChanged == null
          ? _decoration.chip.createBoxPainter()
          : _decoration.chip.createBoxPainter(onChanged),
      _arrow = PopoverArrowPainter(
        placement: _decoration.placement,
        textDirection: _decoration.textDirection,
        width: _decoration.arrowWidth,
        height: _decoration.arrowHeight,
        fill: _decoration.fill,
        border: Colors.transparent,
        // Its base reaches a pixel into an opaque chip, so no seam shows
        // between them; over a translucent one the overlap would.
        hairline: _decoration.fill.a < 1 ? 0 : 1,
      ),
      super(onChanged) {
    _decoration.placement.addListener(_repaint);
  }

  void _repaint() => onChanged?.call();

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    _chip.paint(canvas, offset, configuration);
    final size = configuration.size;
    if (size == null) return;
    canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    _arrow.paint(canvas, size);
    canvas.restore();
  }

  @override
  void dispose() {
    _decoration.placement.removeListener(_repaint);
    _chip.dispose();
    super.dispose();
  }
}
