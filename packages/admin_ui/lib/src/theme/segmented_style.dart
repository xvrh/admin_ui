import 'dart:ui' show FontWeight, lerpDouble;

import 'package:flutter/foundation.dart';

/// How a segmented control draws its segments; see
/// [AdminSegmentedStyle.variant].
enum SegmentedVariant {
  /// A recessed track whose selected segment is a raised knob that slides
  /// between them: Apple's segmented control, Ant's Segmented, shadcn's tabs
  /// list, Fluent's Segmented.
  track,

  /// Segments joined in one outline, divided by rules, the selected one
  /// filled: M3's segmented button, Carbon's content switcher.
  joined,
}

/// The anatomy of a segmented control: a [SegmentedVariant.track] with a
/// raised knob, or [SegmentedVariant.joined] segments in one outline, and the
/// marks each reference system adds to its selected segment. Provided via
/// [AdminTokens]; read through `context.segmentedStyle`.
///
/// The defaults are the kit's own: a track, its knob 3 in from the edge and
/// ringed in a hairline.
@immutable
class AdminSegmentedStyle {
  /// Track and knob, or joined segments.
  final SegmentedVariant variant;

  /// The gap between a track's edge and its knob. The knob's corner is the
  /// track's less this, so the two stay concentric.
  final double inset;

  /// Rings the track in a hairline: Fluent's Segmented.
  final bool trackOutline;

  /// Rings the knob in a hairline as well as lifting it on a shadow. A dark
  /// palette, where a shadow does not read, always rings it.
  final bool knobOutline;

  /// A short accent bar under the selected segment's label, on the knob:
  /// Fluent's selection indicator.
  final bool indicator;

  /// A check before the selected segment's label, in place of its icon: M3.
  /// Every label-only segment keeps room for it, so selecting one never
  /// moves the others.
  final bool checkmark;

  /// Fills the selected segment of a [SegmentedVariant.joined] control with
  /// the foreground, inside an outline in the foreground: Carbon's
  /// high-contrast content switcher. Otherwise the selection takes the soft
  /// fill, inside a field's resting edge.
  final bool inverse;

  /// The control's corner where it is not a button's at the same size:
  /// Carbon's content switcher rounds 4 where its buttons are square.
  final double? radius;

  /// The weight of every label, selected or not, so selecting never changes
  /// a segment's width.
  final FontWeight labelWeight;

  const AdminSegmentedStyle({
    this.variant = SegmentedVariant.track,
    this.inset = 3,
    this.trackOutline = false,
    this.knobOutline = true,
    this.indicator = false,
    this.checkmark = false,
    this.inverse = false,
    this.radius,
    this.labelWeight = FontWeight.w500,
  });

  /// A copy with the given members replaced.
  AdminSegmentedStyle copyWith({
    SegmentedVariant? variant,
    double? inset,
    bool? trackOutline,
    bool? knobOutline,
    bool? indicator,
    bool? checkmark,
    bool? inverse,
    double? radius,
    FontWeight? labelWeight,
  }) => AdminSegmentedStyle(
    variant: variant ?? this.variant,
    inset: inset ?? this.inset,
    trackOutline: trackOutline ?? this.trackOutline,
    knobOutline: knobOutline ?? this.knobOutline,
    indicator: indicator ?? this.indicator,
    checkmark: checkmark ?? this.checkmark,
    inverse: inverse ?? this.inverse,
    radius: radius ?? this.radius,
    labelWeight: labelWeight ?? this.labelWeight,
  );

  /// Interpolates [inset] and [radius] (a missing one stays missing); the
  /// rest comes from the side [t] is nearer.
  static AdminSegmentedStyle lerp(
    AdminSegmentedStyle a,
    AdminSegmentedStyle b,
    double t,
  ) {
    final near = t < 0.5 ? a : b;
    return AdminSegmentedStyle(
      variant: near.variant,
      inset: lerpDouble(a.inset, b.inset, t)!,
      trackOutline: near.trackOutline,
      knobOutline: near.knobOutline,
      indicator: near.indicator,
      checkmark: near.checkmark,
      inverse: near.inverse,
      radius: a.radius != null && b.radius != null
          ? lerpDouble(a.radius, b.radius, t)
          : near.radius,
      labelWeight: near.labelWeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminSegmentedStyle &&
      other.variant == variant &&
      other.inset == inset &&
      other.trackOutline == trackOutline &&
      other.knobOutline == knobOutline &&
      other.indicator == indicator &&
      other.checkmark == checkmark &&
      other.inverse == inverse &&
      other.radius == radius &&
      other.labelWeight == labelWeight;

  @override
  int get hashCode => Object.hash(
    variant,
    inset,
    trackOutline,
    knobOutline,
    indicator,
    checkmark,
    inverse,
    radius,
    labelWeight,
  );

  @override
  String toString() {
    final marks = [
      if (trackOutline) 'outlined track',
      if (knobOutline) 'outlined knob',
      if (indicator) 'indicator',
      if (checkmark) 'checkmark',
      if (inverse) 'inverse',
      if (radius != null) 'radius $radius',
    ];
    return 'AdminSegmentedStyle(${variant.name}, inset $inset, '
        '${labelWeight.value} labels'
        '${marks.isEmpty ? '' : ', ${marks.join(', ')}'})';
  }
}
