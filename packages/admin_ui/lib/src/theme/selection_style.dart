/// @docImport 'radii.dart';
/// @docImport 'stroke.dart';
/// @docImport 'tokens.dart';
library;

import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/foundation.dart';

import 'contrast.dart';
import 'palette.dart';

/// How an off switch draws its track; see [AdminSelectionStyle.toggleOff].
enum ToggleOffStyle {
  /// A solid track in [AdminPalette.controlBorder] under a knob in the
  /// surface colour: the kit's own, shadcn's and Ant's Switch, Carbon's
  /// Toggle.
  filled,

  /// A clear track ringed in [AdminPalette.controlBorder], around a knob in
  /// the ring's colour: Fluent's Switch.
  outlined,

  /// The [outlined] track over a wash of the foreground: M3's switch.
  tonal,
}

/// What an on switch fills its track with; see
/// [AdminSelectionStyle.toggleOn].
enum ToggleOnColor {
  /// [AdminPalette.controlAccent], as a checked box is.
  accent,

  /// [AdminPalette.success], whatever the brand: Carbon's Toggle is
  /// `$support-success`. A success colour nearer than 3:1 to the surface or
  /// the page is moved until it stands that far from both, hue kept, as
  /// [AdminPalette.controlAccent] is.
  success,
}

/// What a checked box and a selected radio are drawn in; see
/// [AdminSelectionStyle.ink].
enum SelectionInk {
  /// [AdminPalette.controlAccent] under [AdminPalette.onControlAccent].
  accent,

  /// [AdminPalette.foreground], whatever the brand: Carbon's Checkbox and
  /// RadioButton are `$icon-primary`.
  foreground,
}

/// What rings an unchecked box and an unselected radio; see
/// [AdminSelectionStyle.outline].
enum SelectionOutline {
  /// [AdminPalette.controlBorder], a field's outline.
  control,

  /// [AdminPalette.foregroundSecondary]: M3's on-surface-variant.
  secondary,

  /// [AdminPalette.foreground]: Carbon's `$icon-primary`.
  foreground,
}

/// How a selected radio is marked; see [AdminSelectionStyle.radioMark].
enum RadioMark {
  /// A disc in the ink around a dot in the ink's on-colour: the kit's own,
  /// Ant's Radio, shadcn's.
  disc,

  /// The outline, in the ink, around a dot in the ink: M3's radio button,
  /// Fluent's Radio, Carbon's RadioButton.
  dot,
}

/// The anatomy of the selection controls: a `Toggle`'s track and knob, a
/// `Check`'s box, a radio's ring and mark, and what they are drawn in.
/// Provided via [AdminTokens]; read through `context.selectionStyle`.
///
/// The outline of an unchecked box, of an unselected radio and of an
/// [ToggleOffStyle.outlined] track is [AdminStroke.controlStrong] wide, and a
/// box's corner is [AdminRadii.radiusCheck].
///
/// The defaults are the kit's own: a 36×20 switch whose off track is filled,
/// an 18px box and an 18px radio marked by a disc, in the accent.
@immutable
class AdminSelectionStyle {
  /// A switch's track, end to end.
  final double toggleWidth;

  /// A switch's track, top to bottom. Its ends are half-rounds at every
  /// height: no reference system squares off a switch.
  final double toggleHeight;

  /// The knob's diameter, at most [toggleHeight].
  final double toggleKnob;

  /// The knob's diameter while the switch is on, where it grows: M3's handle
  /// is 16 off and 24 on. Null keeps [toggleKnob]. The knob travels between
  /// the same two margins either way, the larger knob's.
  final double? toggleKnobOn;

  /// How the off track is drawn.
  final ToggleOffStyle toggleOff;

  /// What the on track is filled with.
  final ToggleOnColor toggleOn;

  /// The side of a checkbox's box.
  final double checkSize;

  /// A radio's diameter.
  final double radioSize;

  /// How a selected radio is marked.
  final RadioMark radioMark;

  /// The diameter of a selected radio's dot, smaller than [radioSize].
  final double radioDot;

  /// What a checked box and a selected radio are drawn in.
  final SelectionInk ink;

  /// What rings an unchecked box and an unselected radio.
  final SelectionOutline outline;

  const AdminSelectionStyle({
    this.toggleWidth = 36,
    this.toggleHeight = 20,
    this.toggleKnob = 16,
    this.toggleKnobOn,
    this.toggleOff = ToggleOffStyle.filled,
    this.toggleOn = ToggleOnColor.accent,
    this.checkSize = 18,
    this.radioSize = 18,
    this.radioMark = RadioMark.disc,
    this.radioDot = 8,
    this.ink = SelectionInk.accent,
    this.outline = SelectionOutline.control,
  }) : assert(toggleKnob <= toggleHeight),
       assert(toggleKnobOn == null || toggleKnobOn <= toggleHeight),
       assert(toggleHeight <= toggleWidth),
       assert(radioDot < radioSize);

  /// The larger of the knob's two diameters: the slot it travels in.
  double get toggleKnobSlot {
    final on = toggleKnobOn;
    return on != null && on > toggleKnob ? on : toggleKnob;
  }

  /// The fill of a checked box and the mark of a selected radio in [colors]:
  /// the accent, its hover shade when [hovered]; or the foreground, a step
  /// toward the page when [hovered], as `AdminPalette.neutralFillHover` is.
  Color inkOf(AdminPalette colors, {bool hovered = false}) => switch (ink) {
    SelectionInk.accent =>
      hovered ? colors.controlAccentHover : colors.controlAccent,
    SelectionInk.foreground =>
      hovered
          ? Color.alphaBlend(
              colors.surface.withValues(alpha: colors.stateLayer.hover),
              colors.foreground,
            )
          : colors.foreground,
  };

  /// What is drawn on [inkOf]: a check's glyph, the dot of a
  /// [RadioMark.disc].
  Color onInkOf(AdminPalette colors) => switch (ink) {
    SelectionInk.accent => colors.onControlAccent,
    SelectionInk.foreground => colors.foregroundOn(colors.foreground),
  };

  /// The outline of an unchecked box and of an unselected radio in [colors],
  /// at rest.
  Color outlineOf(AdminPalette colors) => switch (outline) {
    SelectionOutline.control => colors.controlBorder,
    SelectionOutline.secondary => colors.foregroundSecondary,
    SelectionOutline.foreground => colors.foreground,
  };

  /// That outline under the pointer: [inkOf] where it stands out from the
  /// surface at least as much as the resting [outlineOf], otherwise that
  /// outline deepened by the pressed overlay, so hovering never makes the
  /// control fainter.
  Color hoverOutlineOf(AdminPalette colors) {
    final rest = outlineOf(colors);
    final ink = inkOf(colors);
    return contrastRatio(ink, colors.surface) >=
            contrastRatio(rest, colors.surface)
        ? ink
        : Color.alphaBlend(colors.pressedOverlay, rest);
  }

  /// An on switch's track in [colors], deepened when [hovered].
  Color toggleOnOf(AdminPalette colors, {bool hovered = false}) {
    switch (toggleOn) {
      case ToggleOnColor.accent:
        return hovered ? colors.controlAccentHover : colors.controlAccent;
      case ToggleOnColor.success:
        final track = colors.readableOn(colors.success, minContrast: 3);
        return hovered ? Color.alphaBlend(colors.pressedOverlay, track) : track;
    }
  }

  /// An on switch's knob in [colors]. On the accent,
  /// [AdminPalette.onControlAccent]. On the success colour, the surface
  /// colour, as an off switch's knob, where it stands 3:1 from the track,
  /// and otherwise whichever of white and near-black stands out more.
  Color toggleKnobOnOf(AdminPalette colors) {
    switch (toggleOn) {
      case ToggleOnColor.accent:
        return colors.onControlAccent;
      case ToggleOnColor.success:
        final track = toggleOnOf(colors);
        return contrastRatio(colors.surface, track) >= 3
            ? colors.surface
            : colors.foregroundOn(track);
    }
  }

  /// A copy with the given members replaced.
  AdminSelectionStyle copyWith({
    double? toggleWidth,
    double? toggleHeight,
    double? toggleKnob,
    double? toggleKnobOn,
    ToggleOffStyle? toggleOff,
    ToggleOnColor? toggleOn,
    double? checkSize,
    double? radioSize,
    RadioMark? radioMark,
    double? radioDot,
    SelectionInk? ink,
    SelectionOutline? outline,
  }) => AdminSelectionStyle(
    toggleWidth: toggleWidth ?? this.toggleWidth,
    toggleHeight: toggleHeight ?? this.toggleHeight,
    toggleKnob: toggleKnob ?? this.toggleKnob,
    toggleKnobOn: toggleKnobOn ?? this.toggleKnobOn,
    toggleOff: toggleOff ?? this.toggleOff,
    toggleOn: toggleOn ?? this.toggleOn,
    checkSize: checkSize ?? this.checkSize,
    radioSize: radioSize ?? this.radioSize,
    radioMark: radioMark ?? this.radioMark,
    radioDot: radioDot ?? this.radioDot,
    ink: ink ?? this.ink,
    outline: outline ?? this.outline,
  );

  /// Interpolates the sizes (a [toggleKnobOn] one side leaves out counts as
  /// its [toggleKnob]; one neither side has stays out); the rest comes from
  /// the side [t] is nearer.
  static AdminSelectionStyle lerp(
    AdminSelectionStyle a,
    AdminSelectionStyle b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    final near = t < 0.5 ? a : b;
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminSelectionStyle(
      toggleWidth: d(a.toggleWidth, b.toggleWidth),
      toggleHeight: d(a.toggleHeight, b.toggleHeight),
      toggleKnob: d(a.toggleKnob, b.toggleKnob),
      toggleKnobOn: a.toggleKnobOn == null && b.toggleKnobOn == null
          ? null
          : d(a.toggleKnobOn ?? a.toggleKnob, b.toggleKnobOn ?? b.toggleKnob),
      toggleOff: near.toggleOff,
      toggleOn: near.toggleOn,
      checkSize: d(a.checkSize, b.checkSize),
      radioSize: d(a.radioSize, b.radioSize),
      radioMark: near.radioMark,
      radioDot: d(a.radioDot, b.radioDot),
      ink: near.ink,
      outline: near.outline,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminSelectionStyle &&
      other.toggleWidth == toggleWidth &&
      other.toggleHeight == toggleHeight &&
      other.toggleKnob == toggleKnob &&
      other.toggleKnobOn == toggleKnobOn &&
      other.toggleOff == toggleOff &&
      other.toggleOn == toggleOn &&
      other.checkSize == checkSize &&
      other.radioSize == radioSize &&
      other.radioMark == radioMark &&
      other.radioDot == radioDot &&
      other.ink == ink &&
      other.outline == outline;

  @override
  int get hashCode => Object.hash(
    toggleWidth,
    toggleHeight,
    toggleKnob,
    toggleKnobOn,
    toggleOff,
    toggleOn,
    checkSize,
    radioSize,
    radioMark,
    radioDot,
    ink,
    outline,
  );

  @override
  String toString() {
    final knob = toggleKnobOn == null
        ? '$toggleKnob'
        : '$toggleKnob/$toggleKnobOn';
    return 'AdminSelectionStyle(toggle $toggleWidth×$toggleHeight knob $knob '
        '${toggleOff.name} off, ${toggleOn.name} on; check $checkSize; '
        'radio $radioSize ${radioMark.name} $radioDot; '
        '${ink.name} ink, ${outline.name} outline)';
  }
}
