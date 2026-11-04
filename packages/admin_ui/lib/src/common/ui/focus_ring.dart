import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/contrast.dart';
import '../../theme/tokens.dart';

/// The theme's keyboard-focus ring around [child]: a `context.focus.width`
/// outline in the palette's `focusRing`, starting `context.focus.offset`
/// outside the child's edge (a negative offset draws it inside, over the
/// child). Wherever the ring would otherwise touch the child it is kept off it
/// by a band of `surface` — the offset gap outside, a 1px line inside an inset
/// ring — so a ring in the fill's own colour still reads. A theme that draws
/// its ring flush (offset 0) keeps it so while the ring stands 3:1 off the
/// primary; one that doesn't (a brand accent that is also the ring) moves it
/// out by a 1px `surface` band, or on a primary fill it would not show. A
/// flush ring with a `context.focus.innerWidth` lays a `surface` band that
/// wide just inside it, over the child's edge: Fluent's two-tone ring.
///
/// Shown while [focused] and the app is in keyboard highlight mode, so a click
/// or a tap never lights it. Painted over and around the child without taking
/// space or changing the child's constraints, so showing it never moves
/// anything. Every focusable control in the kit draws its focus with this.
class FocusRing extends StatefulWidget {
  /// Whether [child] holds keyboard focus — e.g. tracked from an [InkWell]'s
  /// `onFocusChange`, or a [FocusableActionDetector]'s
  /// `onShowFocusHighlight`.
  final bool focused;

  /// Corner radius of [child]'s edge; the ring follows it.
  final double radius;

  /// Per-corner radii of [child]'s edge, for a child whose corners differ
  /// (a joined segment); when set it wins over [radius].
  final BorderRadiusGeometry? borderRadius;

  final Widget child;

  const FocusRing({
    super.key,
    required this.focused,
    this.radius = 0,
    this.borderRadius,
    required this.child,
  });

  /// How far the ring reaches outside its child's edge in [context]'s theme:
  /// the offset plus the width, the 1px band that moves a flush ring off the
  /// primary included; zero or less for a ring drawn inside. A box that
  /// clips around a ringed child must leave it this much room.
  static double reachOf(BuildContext context) =>
      _offsetOf(context) + context.focus.width;

  /// The theme's offset, or 1px where a flush ring would not stand 3:1 off
  /// the primary.
  static double _offsetOf(BuildContext context) {
    final offset = context.focus.offset;
    final colors = context.colors;
    return offset == 0 && contrastRatio(colors.focusRing, colors.primary) < 3
        ? 1.0
        : offset;
  }

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode _) {
    if (widget.focused) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final spec = context.focus;
    final colors = context.colors;
    final offset = FocusRing._offsetOf(context);
    final corners =
        (widget.borderRadius ?? BorderRadius.circular(widget.radius)).resolve(
          Directionality.maybeOf(context),
        );
    Radius grow(Radius r, double by) => Radius.circular(math.max(0, r.x + by));
    // A band covering [outer - width, outer] from the child's edge, outward.
    Widget band(double outer, double width, Color color) => Positioned(
      left: -outer,
      top: -outer,
      right: -outer,
      bottom: -outer,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Physical: [corners] is already resolved against the direction.
            borderRadius: BorderRadius.only(
              topLeft: grow(corners.topLeft, outer),
              topRight: grow(corners.topRight, outer),
              bottomLeft: grow(corners.bottomLeft, outer),
              bottomRight: grow(corners.bottomRight, outer),
            ),
            border: Border.all(color: color, width: width),
          ),
        ),
      ),
    );

    // Passthrough, so a tight parent still sizes the child and the bands
    // follow the child's real box.
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (visible) ...[
          if (offset > 0)
            band(offset, offset, colors.surface)
          else if (offset < 0)
            band(offset, 1, colors.surface)
          else if (spec.innerWidth > 0)
            band(0, spec.innerWidth, colors.surface),
          band(offset + spec.width, spec.width, colors.focusRing),
        ],
      ],
    );
  }
}
