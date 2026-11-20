/// @docImport 'radii.dart';
/// @docImport 'tokens.dart';
/// @docImport 'typography.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart' show Curve;
import 'package:flutter/foundation.dart';

import 'motion.dart';

/// How an overlay arrives and leaves. It always fades; it can also grow
/// from a smaller [scale], unfold from a shorter [stretch] and travel a
/// [slide] into place. Leaving plays the same move back, unless a popover's
/// does not [leaves] at all.
///
/// A modal moves about its own middle and slides down from above. A popover
/// moves from its anchor: it grows out of the point on its edge that faces
/// the anchor, and slides away from the anchor into place.
///
/// The default is a fade alone over [AdminMotion.medium], on the motion's
/// [AdminMotion.enter] and [AdminMotion.exit] curves.
@immutable
class AdminOverlayMotion {
  /// The scale it grows from as it fades in, up to 1: 0.95 for shadcn's
  /// `zoom-in-95`, 0.85 in Fluent, 0.2 for Ant's zoom. 1 does not scale.
  final double scale;

  /// The share of its height it unfolds from as it fades in, its width
  /// kept: Ant's `slide-up` starts a menu at 0.8 of its height. It unfolds
  /// from its top edge, or from its bottom edge where a popover opens above
  /// its anchor. 1 does not stretch.
  final double stretch;

  /// How far from its place it starts, in logical pixels, sliding in as it
  /// fades: a modal from above (Carbon's travels 24), a popover from the
  /// side of its anchor (8 in shadcn, 10 in Fluent). Zero does not slide.
  final double slide;

  /// Which of the motion's durations the move takes. Reduced motion zeroes
  /// it with the rest.
  final MotionSpeed speed;

  /// How long the move takes where none of the motion's three durations is
  /// it: Fluent's popover takes 400ms. Null is the duration [speed] names.
  /// Reduced motion zeroes it too.
  final Duration? duration;

  /// The curve it arrives on; null is [AdminMotion.enter].
  final Curve? curve;

  /// The curve it leaves on as time runs, so an accelerating curve
  /// accelerates it away; null is [AdminMotion.exit]. The overlay flips it
  /// for the animation it plays back (see [AdminMotion.exit]).
  final Curve? reverseCurve;

  /// Whether a popover plays the move back as it leaves. False, and it is
  /// gone at once: Fluent's popover and menu have an entrance and no exit.
  /// A modal plays its arrival back whatever this says, as its route does.
  final bool leaves;

  const AdminOverlayMotion({
    this.scale = 1,
    this.stretch = 1,
    this.slide = 0,
    this.speed = MotionSpeed.medium,
    this.duration,
    this.curve,
    this.reverseCurve,
    this.leaves = true,
  }) : assert(scale > 0 && scale <= 1),
       assert(stretch > 0 && stretch <= 1),
       assert(slide >= 0);

  /// Whether the overlay moves as well as fades.
  bool get moves => scale != 1 || stretch != 1 || slide != 0;

  /// How long the move takes under [motion]: its own [duration], or the one
  /// of the motion's three that [speed] names. A caller under reduced motion
  /// takes zero whatever this says (`context.motion` zeroes the three, not
  /// an authored [duration]).
  Duration durationIn(AdminMotion motion) =>
      duration ?? motion.durationOf(speed);

  /// A copy with the given members replaced. A null argument keeps the
  /// current value, so [duration], [curve] and [reverseCurve] cannot be
  /// cleared here; build a new motion for that.
  AdminOverlayMotion copyWith({
    double? scale,
    double? stretch,
    double? slide,
    MotionSpeed? speed,
    Duration? duration,
    Curve? curve,
    Curve? reverseCurve,
    bool? leaves,
  }) => AdminOverlayMotion(
    scale: scale ?? this.scale,
    stretch: stretch ?? this.stretch,
    slide: slide ?? this.slide,
    speed: speed ?? this.speed,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    reverseCurve: reverseCurve ?? this.reverseCurve,
    leaves: leaves ?? this.leaves,
  );

  /// Interpolates [scale], [stretch] and [slide]; the speed, the duration,
  /// the curves and whether it leaves come from the side [t] is nearer.
  static AdminOverlayMotion lerp(
    AdminOverlayMotion a,
    AdminOverlayMotion b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    final near = t < 0.5 ? a : b;
    return AdminOverlayMotion(
      scale: lerpDouble(a.scale, b.scale, t)!,
      stretch: lerpDouble(a.stretch, b.stretch, t)!,
      slide: lerpDouble(a.slide, b.slide, t)!,
      speed: near.speed,
      duration: near.duration,
      curve: near.curve,
      reverseCurve: near.reverseCurve,
      leaves: near.leaves,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminOverlayMotion &&
      other.scale == scale &&
      other.stretch == stretch &&
      other.slide == slide &&
      other.speed == speed &&
      other.duration == duration &&
      other.curve == curve &&
      other.reverseCurve == reverseCurve &&
      other.leaves == leaves;

  @override
  int get hashCode => Object.hash(
    scale,
    stretch,
    slide,
    speed,
    duration,
    curve,
    reverseCurve,
    leaves,
  );

  @override
  String toString() =>
      'AdminOverlayMotion(a fade'
      '${scale == 1 ? '' : ', from scale $scale'}'
      '${stretch == 1 ? '' : ', unfolding from $stretch'}'
      '${slide == 0 ? '' : ', sliding $slide'}'
      ', ${duration == null ? speed.name : '${duration!.inMilliseconds}ms'}'
      '${curve == null && reverseCurve == null ? '' : ', its own curves'}'
      '${leaves ? '' : ', gone at once'})';
}

/// The text a tooltip is set in; see [AdminOverlayStyle.tooltipText]. The
/// tooltip resolves it against `context.type`.
enum TooltipText {
  /// [AdminTypography.caption], a size under the body: the kit's own, M3's
  /// plain tooltip, shadcn's `text-xs`, Fluent's.
  caption,

  /// [AdminTypography.body]: Ant's and Carbon's tooltips are set at the
  /// body's size.
  body,
}

/// The anatomy of the floating overlays: a tooltip's corner, padding, text
/// and delay, whether it points at its target with an arrow, the width its
/// text wraps at, the size of the arrow a tooltip or a popover draws, and
/// how a modal and a popover arrive and leave.
/// Provided via [AdminTokens]; read through `context.overlayStyle`.
///
/// The defaults are the kit's own: a plain chip at the small radius, padded
/// 8 by 4 around caption text, shown after 400ms, that wraps at 280; a
/// 12×6 arrow where a popover asks for one; a modal that fades; and a
/// popover that is there, and gone, at once.
@immutable
class AdminOverlayStyle {
  /// Whether a tooltip points at its target with an arrow unless it says
  /// otherwise: Ant's, Carbon's and Fluent's do, M3's plain tooltip does
  /// not.
  final bool tooltipArrow;

  /// The width a tooltip's text wraps at.
  final double tooltipMaxWidth;

  /// A tooltip's corner where it is not [AdminRadii.radiusSmall], which a
  /// theme needs at another value for its menu items and small buttons:
  /// M3's tooltip rounds 4, Carbon's 2 in a square theme. Null is the small
  /// radius.
  final double? tooltipRadius;

  /// A tooltip's inset from its edge to its text, on either side.
  final double tooltipPaddingX;

  /// A tooltip's inset from its edge to its text, above and below.
  final double tooltipPaddingY;

  /// The text a tooltip is set in.
  final TooltipText tooltipText;

  /// How long the pointer rests on a target before its tooltip shows. A
  /// delay, not motion: reduced motion leaves it alone.
  final Duration tooltipDelay;

  /// How a `Modal` arrives and leaves: shadcn's zooms in from 95%, Ant's
  /// from 20%, Fluent's from 85%, and Carbon's slides down 24. The scrim
  /// fades with it.
  final AdminOverlayMotion modalMotion;

  /// How a `Popover` arrives and leaves, and so every menu, select, picker
  /// and hover card: shadcn's fades in from 95%, 8 off its anchor; Ant's
  /// unfolds from 80% of its height; Fluent's slides in 10 and is gone at
  /// once. Null, and it appears and vanishes at once, with no fade.
  final AdminOverlayMotion? popoverMotion;

  /// The arrow's base, along the edge it stands on.
  final double arrowWidth;

  /// How far the arrow reaches out from its edge toward the anchor. A
  /// popover with an arrow stands this much further off its anchor, so the
  /// arrow's tip keeps the popover's gap.
  final double arrowHeight;

  const AdminOverlayStyle({
    this.tooltipArrow = false,
    this.tooltipMaxWidth = 280,
    this.tooltipRadius,
    this.tooltipPaddingX = 8,
    this.tooltipPaddingY = 4,
    this.tooltipText = TooltipText.caption,
    this.tooltipDelay = const Duration(milliseconds: 400),
    this.modalMotion = const AdminOverlayMotion(),
    this.popoverMotion,
    this.arrowWidth = 12,
    this.arrowHeight = 6,
  }) : assert(tooltipRadius == null || tooltipRadius >= 0),
       assert(tooltipPaddingX >= 0 && tooltipPaddingY >= 0);

  /// A copy with the given members replaced. A null argument keeps the
  /// current value, so [tooltipRadius] and [popoverMotion] cannot be
  /// cleared here; build a new style for that.
  AdminOverlayStyle copyWith({
    bool? tooltipArrow,
    double? tooltipMaxWidth,
    double? tooltipRadius,
    double? tooltipPaddingX,
    double? tooltipPaddingY,
    TooltipText? tooltipText,
    Duration? tooltipDelay,
    AdminOverlayMotion? modalMotion,
    AdminOverlayMotion? popoverMotion,
    double? arrowWidth,
    double? arrowHeight,
  }) => AdminOverlayStyle(
    tooltipArrow: tooltipArrow ?? this.tooltipArrow,
    tooltipMaxWidth: tooltipMaxWidth ?? this.tooltipMaxWidth,
    tooltipRadius: tooltipRadius ?? this.tooltipRadius,
    tooltipPaddingX: tooltipPaddingX ?? this.tooltipPaddingX,
    tooltipPaddingY: tooltipPaddingY ?? this.tooltipPaddingY,
    tooltipText: tooltipText ?? this.tooltipText,
    tooltipDelay: tooltipDelay ?? this.tooltipDelay,
    modalMotion: modalMotion ?? this.modalMotion,
    popoverMotion: popoverMotion ?? this.popoverMotion,
    arrowWidth: arrowWidth ?? this.arrowWidth,
    arrowHeight: arrowHeight ?? this.arrowHeight,
  );

  /// Interpolates the lengths (a [tooltipRadius] only where both sides
  /// author one) and the motions (a [popoverMotion] only where both sides
  /// have one); [tooltipArrow], [tooltipText] and [tooltipDelay] come from
  /// the side [t] is nearer.
  static AdminOverlayStyle lerp(
    AdminOverlayStyle a,
    AdminOverlayStyle b,
    double t,
  ) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    final near = t < 0.5 ? a : b;
    return AdminOverlayStyle(
      tooltipArrow: near.tooltipArrow,
      tooltipMaxWidth: d(a.tooltipMaxWidth, b.tooltipMaxWidth),
      tooltipRadius: a.tooltipRadius != null && b.tooltipRadius != null
          ? d(a.tooltipRadius!, b.tooltipRadius!)
          : near.tooltipRadius,
      tooltipPaddingX: d(a.tooltipPaddingX, b.tooltipPaddingX),
      tooltipPaddingY: d(a.tooltipPaddingY, b.tooltipPaddingY),
      tooltipText: near.tooltipText,
      tooltipDelay: near.tooltipDelay,
      modalMotion: AdminOverlayMotion.lerp(a.modalMotion, b.modalMotion, t),
      popoverMotion: a.popoverMotion != null && b.popoverMotion != null
          ? AdminOverlayMotion.lerp(a.popoverMotion!, b.popoverMotion!, t)
          : near.popoverMotion,
      arrowWidth: d(a.arrowWidth, b.arrowWidth),
      arrowHeight: d(a.arrowHeight, b.arrowHeight),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminOverlayStyle &&
      other.tooltipArrow == tooltipArrow &&
      other.tooltipMaxWidth == tooltipMaxWidth &&
      other.tooltipRadius == tooltipRadius &&
      other.tooltipPaddingX == tooltipPaddingX &&
      other.tooltipPaddingY == tooltipPaddingY &&
      other.tooltipText == tooltipText &&
      other.tooltipDelay == tooltipDelay &&
      other.modalMotion == modalMotion &&
      other.popoverMotion == popoverMotion &&
      other.arrowWidth == arrowWidth &&
      other.arrowHeight == arrowHeight;

  @override
  int get hashCode => Object.hash(
    tooltipArrow,
    tooltipMaxWidth,
    tooltipRadius,
    tooltipPaddingX,
    tooltipPaddingY,
    tooltipText,
    tooltipDelay,
    modalMotion,
    popoverMotion,
    arrowWidth,
    arrowHeight,
  );

  @override
  String toString() =>
      'AdminOverlayStyle(tooltips ${tooltipArrow ? 'with' : 'without'} an '
      'arrow, wrapping at $tooltipMaxWidth, '
      '${tooltipRadius == null ? 'the small radius' : 'radius $tooltipRadius'}, '
      'padding $tooltipPaddingX×$tooltipPaddingY, ${tooltipText.name} text, '
      'after ${tooltipDelay.inMilliseconds}ms; arrow '
      '$arrowWidth×$arrowHeight; modals $modalMotion; popovers '
      '${popoverMotion ?? 'at once'})';
}
