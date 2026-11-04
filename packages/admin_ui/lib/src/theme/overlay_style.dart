import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// The anatomy of the floating overlays: whether a tooltip points at its
/// target with an arrow, the width its text wraps at, and the size of the
/// arrow a tooltip or a popover draws. Provided via [AdminTokens]; read
/// through `context.overlayStyle`.
///
/// The defaults are the kit's own: a plain chip that wraps at 280, and a
/// 12×6 arrow where a popover asks for one.
@immutable
class AdminOverlayStyle {
  /// Whether a tooltip points at its target with an arrow unless it says
  /// otherwise: Ant's, Carbon's and Fluent's do, M3's plain tooltip does
  /// not.
  final bool tooltipArrow;

  /// The width a tooltip's text wraps at.
  final double tooltipMaxWidth;

  /// The arrow's base, along the edge it stands on.
  final double arrowWidth;

  /// How far the arrow reaches out from its edge toward the anchor. A
  /// popover with an arrow stands this much further off its anchor, so the
  /// arrow's tip keeps the popover's gap.
  final double arrowHeight;

  const AdminOverlayStyle({
    this.tooltipArrow = false,
    this.tooltipMaxWidth = 280,
    this.arrowWidth = 12,
    this.arrowHeight = 6,
  });

  /// A copy with the given members replaced.
  AdminOverlayStyle copyWith({
    bool? tooltipArrow,
    double? tooltipMaxWidth,
    double? arrowWidth,
    double? arrowHeight,
  }) => AdminOverlayStyle(
    tooltipArrow: tooltipArrow ?? this.tooltipArrow,
    tooltipMaxWidth: tooltipMaxWidth ?? this.tooltipMaxWidth,
    arrowWidth: arrowWidth ?? this.arrowWidth,
    arrowHeight: arrowHeight ?? this.arrowHeight,
  );

  /// Interpolates the lengths; [tooltipArrow] comes from the side [t] is
  /// nearer.
  static AdminOverlayStyle lerp(
    AdminOverlayStyle a,
    AdminOverlayStyle b,
    double t,
  ) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminOverlayStyle(
      tooltipArrow: t < 0.5 ? a.tooltipArrow : b.tooltipArrow,
      tooltipMaxWidth: d(a.tooltipMaxWidth, b.tooltipMaxWidth),
      arrowWidth: d(a.arrowWidth, b.arrowWidth),
      arrowHeight: d(a.arrowHeight, b.arrowHeight),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminOverlayStyle &&
      other.tooltipArrow == tooltipArrow &&
      other.tooltipMaxWidth == tooltipMaxWidth &&
      other.arrowWidth == arrowWidth &&
      other.arrowHeight == arrowHeight;

  @override
  int get hashCode =>
      Object.hash(tooltipArrow, tooltipMaxWidth, arrowWidth, arrowHeight);

  @override
  String toString() =>
      'AdminOverlayStyle(tooltips ${tooltipArrow ? 'with' : 'without'} an '
      'arrow, wrapping at $tooltipMaxWidth; arrow $arrowWidth×$arrowHeight)';
}
