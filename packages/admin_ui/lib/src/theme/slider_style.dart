/// @docImport 'tokens.dart';
library;

import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/foundation.dart';

import 'palette.dart';
import 'selection_style.dart';

/// How a slider draws its thumb; see [AdminSliderStyle.thumb].
enum SliderThumb {
  /// A disc in the ink: the kit's own, Carbon's Slider.
  disc,

  /// A disc in the surface colour ringed in the ink, lifted on a shadow:
  /// shadcn's Slider, Ant's.
  ringed,

  /// A disc in the ink inside a band in the surface colour, edged in a
  /// hairline: Fluent's Slider.
  inset,

  /// A bar in the ink, taller than the track, which parts on either side of
  /// it: M3's slider.
  bar,
}

/// What a slider draws the part of its track past the thumb in; see
/// [AdminSliderStyle.rail].
enum SliderRail {
  /// [AdminPalette.border], a divider's colour.
  border,

  /// [AdminPalette.controlBorder], a field's outline: Fluent's rail is
  /// `colorNeutralStrokeAccessible`.
  control,

  /// [AdminPalette.softFill]: M3's inactive track is the secondary
  /// container.
  soft,
}

/// The anatomy of a `ValueSlider`: its track's height, its thumb, and what
/// the two are drawn in. Provided via [AdminTokens]; read through
/// `context.sliderStyle`.
///
/// The defaults are the kit's own: a 4px track under an 18px disc, in the
/// accent, over a rail in the border colour.
@immutable
class AdminSliderStyle {
  /// The track's height.
  final double trackHeight;

  /// How the thumb is drawn.
  final SliderThumb thumb;

  /// The thumb's diameter, or a [SliderThumb.bar]'s height.
  final double thumbSize;

  /// The width of a [SliderThumb.ringed] thumb's ring, and of a
  /// [SliderThumb.inset] thumb's band; the other thumbs have neither.
  final double thumbRing;

  /// What the track past the thumb is drawn in.
  final SliderRail rail;

  /// What the track up to the thumb, and the thumb, are drawn in: the accent,
  /// or the foreground whatever the brand, as Carbon's Slider is
  /// `$layer-selected-inverse`.
  final SelectionInk ink;

  const AdminSliderStyle({
    this.trackHeight = 4,
    this.thumb = SliderThumb.disc,
    this.thumbSize = 18,
    this.thumbRing = 2,
    this.rail = SliderRail.border,
    this.ink = SelectionInk.accent,
  }) : assert(trackHeight > 0),
       assert(thumbSize > 0),
       assert(thumbRing >= 0 && thumbRing * 2 < thumbSize);

  /// A bar's width, M3's 4dp handle.
  static const barWidth = 4.0;

  /// The gap a bar parts the track by on either side, M3's 6dp.
  static const barGap = 6.0;

  /// The track up to the thumb, and the thumb's own colour, in [colors].
  Color inkOf(AdminPalette colors) => switch (ink) {
    SelectionInk.accent => colors.controlAccent,
    SelectionInk.foreground => colors.foreground,
  };

  /// What is drawn on [inkOf]: a tick mark on the track up to the thumb.
  Color onInkOf(AdminPalette colors) => switch (ink) {
    SelectionInk.accent => colors.onControlAccent,
    SelectionInk.foreground => colors.foregroundOn(colors.foreground),
  };

  /// The track past the thumb in [colors].
  Color railOf(AdminPalette colors) => switch (rail) {
    SliderRail.border => colors.border,
    SliderRail.control => colors.controlBorder,
    SliderRail.soft => colors.softFill,
  };

  /// A copy with the given members replaced.
  AdminSliderStyle copyWith({
    double? trackHeight,
    SliderThumb? thumb,
    double? thumbSize,
    double? thumbRing,
    SliderRail? rail,
    SelectionInk? ink,
  }) => AdminSliderStyle(
    trackHeight: trackHeight ?? this.trackHeight,
    thumb: thumb ?? this.thumb,
    thumbSize: thumbSize ?? this.thumbSize,
    thumbRing: thumbRing ?? this.thumbRing,
    rail: rail ?? this.rail,
    ink: ink ?? this.ink,
  );

  /// Interpolates the sizes; the rest comes from the side [t] is nearer.
  static AdminSliderStyle lerp(
    AdminSliderStyle a,
    AdminSliderStyle b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    final near = t < 0.5 ? a : b;
    return AdminSliderStyle(
      trackHeight: lerpDouble(a.trackHeight, b.trackHeight, t)!,
      thumb: near.thumb,
      thumbSize: lerpDouble(a.thumbSize, b.thumbSize, t)!,
      thumbRing: lerpDouble(a.thumbRing, b.thumbRing, t)!,
      rail: near.rail,
      ink: near.ink,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminSliderStyle &&
      other.trackHeight == trackHeight &&
      other.thumb == thumb &&
      other.thumbSize == thumbSize &&
      other.thumbRing == thumbRing &&
      other.rail == rail &&
      other.ink == ink;

  @override
  int get hashCode =>
      Object.hash(trackHeight, thumb, thumbSize, thumbRing, rail, ink);

  @override
  String toString() =>
      'AdminSliderStyle(track $trackHeight, ${thumb.name} $thumbSize'
      '${thumb == SliderThumb.ringed || thumb == SliderThumb.inset ? ' ring $thumbRing' : ''}'
      ', ${rail.name} rail, ${ink.name} ink)';
}
