/// @docImport 'radii.dart';
/// @docImport 'tokens.dart';
/// @docImport 'typography.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart' show Curve;
import 'package:flutter/foundation.dart';

import 'motion.dart';

/// How an overlay arrives and leaves. It always fades; it can also grow
/// from a smaller [scale] and travel a [slide] into place. Leaving plays the
/// same move back.
///
/// The default is a fade alone over [AdminMotion.medium], on the motion's
/// [AdminMotion.enter] and [AdminMotion.exit] curves.
@immutable
class AdminOverlayMotion {
  /// The scale it grows from as it fades in, up to 1: 0.95 for shadcn's
  /// `zoom-in-95`, 0.85 in Fluent, 0.2 for Ant's zoom. 1 does not scale.
  final double scale;

  /// How far above its place it starts, in logical pixels, sliding down as
  /// it fades in: Carbon's modal travels 24. Zero does not slide.
  final double slide;

  /// Which of the motion's durations the move takes. Reduced motion zeroes
  /// it with the rest.
  final MotionSpeed speed;

  /// The curve it arrives on; null is [AdminMotion.enter].
  final Curve? curve;

  /// The curve it leaves on as time runs, so an accelerating curve
  /// accelerates it away; null is [AdminMotion.exit]. The overlay flips it
  /// for the animation it plays back (see [AdminMotion.exit]).
  final Curve? reverseCurve;

  const AdminOverlayMotion({
    this.scale = 1,
    this.slide = 0,
    this.speed = MotionSpeed.medium,
    this.curve,
    this.reverseCurve,
  }) : assert(scale > 0 && scale <= 1),
       assert(slide >= 0);

  /// Whether the overlay moves as well as fades.
  bool get moves => scale != 1 || slide != 0;

  /// A copy with the given members replaced. A null argument keeps the
  /// current value, so [curve] and [reverseCurve] cannot be cleared here;
  /// build a new motion for that.
  AdminOverlayMotion copyWith({
    double? scale,
    double? slide,
    MotionSpeed? speed,
    Curve? curve,
    Curve? reverseCurve,
  }) => AdminOverlayMotion(
    scale: scale ?? this.scale,
    slide: slide ?? this.slide,
    speed: speed ?? this.speed,
    curve: curve ?? this.curve,
    reverseCurve: reverseCurve ?? this.reverseCurve,
  );

  /// Interpolates [scale] and [slide]; the speed and the curves come from
  /// the side [t] is nearer.
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
      slide: lerpDouble(a.slide, b.slide, t)!,
      speed: near.speed,
      curve: near.curve,
      reverseCurve: near.reverseCurve,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminOverlayMotion &&
      other.scale == scale &&
      other.slide == slide &&
      other.speed == speed &&
      other.curve == curve &&
      other.reverseCurve == reverseCurve;

  @override
  int get hashCode => Object.hash(scale, slide, speed, curve, reverseCurve);

  @override
  String toString() =>
      'AdminOverlayMotion(a fade'
      '${scale == 1 ? '' : ', from scale $scale'}'
      '${slide == 0 ? '' : ', sliding $slide'}'
      ', ${speed.name}'
      '${curve == null && reverseCurve == null ? '' : ', its own curves'})';
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
/// text wraps at, and the size of the arrow a tooltip or a popover draws.
/// Provided via [AdminTokens]; read through `context.overlayStyle`.
///
/// The defaults are the kit's own: a plain chip at the small radius, padded
/// 8 by 4 around caption text, shown after 400ms, that wraps at 280; and a
/// 12×6 arrow where a popover asks for one.
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
    this.arrowWidth = 12,
    this.arrowHeight = 6,
  }) : assert(tooltipRadius == null || tooltipRadius >= 0),
       assert(tooltipPaddingX >= 0 && tooltipPaddingY >= 0);

  /// A copy with the given members replaced.
  AdminOverlayStyle copyWith({
    bool? tooltipArrow,
    double? tooltipMaxWidth,
    double? tooltipRadius,
    double? tooltipPaddingX,
    double? tooltipPaddingY,
    TooltipText? tooltipText,
    Duration? tooltipDelay,
    AdminOverlayMotion? modalMotion,
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
    arrowWidth: arrowWidth ?? this.arrowWidth,
    arrowHeight: arrowHeight ?? this.arrowHeight,
  );

  /// Interpolates the lengths (a [tooltipRadius] only where both sides
  /// author one); [tooltipArrow], [tooltipText] and [tooltipDelay] come from
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
      '$arrowWidth×$arrowHeight; modals $modalMotion)';
}
