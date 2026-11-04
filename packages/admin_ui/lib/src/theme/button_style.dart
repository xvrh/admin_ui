import 'dart:ui' show FontWeight, lerpDouble;

import 'package:flutter/foundation.dart';

import 'sizes.dart';

/// Where a labelled button lays its content; see
/// [AdminButtonStyle.labelAlignment].
enum ButtonLabelAlignment {
  /// Centred in the button.
  center,

  /// At the inline start, the rest of the width left empty: Carbon.
  start,
}

/// Which side of the label a button's glyph sits on; see
/// [AdminButtonStyle.iconPlacement].
enum ButtonIconPlacement {
  /// Before the label.
  leading,

  /// At the button's inline end, after the label: Carbon.
  end,
}

/// How a disabled button draws; see [AdminButtonStyle.disabled].
enum ButtonDisabledStyle {
  /// Every variant drops to one neutral look: the disabled fill and label,
  /// as M3 and Ant draw a disabled button whatever its kind.
  neutral,

  /// The variant's own enabled look, faded to
  /// [AdminButtonStyle.fadedOpacity]: shadcn's `disabled:opacity-50`, which
  /// keeps a disabled destructive button recognisably destructive.
  faded,
}

/// A button's inline padding at one [ControlSize]: [start] before the
/// content, [end] after it, and [startWithIcon] in place of [start] when the
/// content leads with a glyph (M3 pads 24 either side, 16 on the icon side).
@immutable
class AdminButtonInsets {
  final double start;
  final double end;

  /// The start padding when a leading glyph is shown; [start] when null.
  final double? startWithIcon;

  const AdminButtonInsets({
    required this.start,
    required this.end,
    this.startWithIcon,
  });

  /// The same padding either side.
  const AdminButtonInsets.symmetric(double inline, {this.startWithIcon})
    : start = inline,
      end = inline;

  /// The start padding: [startWithIcon] beside a [leadingIcon], else [start].
  double startFor({required bool leadingIcon}) =>
      leadingIcon ? startWithIcon ?? start : start;

  /// A copy with the given insets replaced.
  AdminButtonInsets copyWith({
    double? start,
    double? end,
    double? startWithIcon,
  }) => AdminButtonInsets(
    start: start ?? this.start,
    end: end ?? this.end,
    startWithIcon: startWithIcon ?? this.startWithIcon,
  );

  /// Interpolates each inset; a [startWithIcon] one side leaves unset counts
  /// as that side's [start].
  static AdminButtonInsets lerp(
    AdminButtonInsets a,
    AdminButtonInsets b,
    double t,
  ) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminButtonInsets(
      start: d(a.start, b.start),
      end: d(a.end, b.end),
      startWithIcon: a.startWithIcon == null && b.startWithIcon == null
          ? null
          : d(a.startWithIcon ?? a.start, b.startWithIcon ?? b.start),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminButtonInsets &&
      other.start == start &&
      other.end == end &&
      other.startWithIcon == startWithIcon;

  @override
  int get hashCode => Object.hash(start, end, startWithIcon);

  @override
  String toString() =>
      'AdminButtonInsets($start/$end'
      '${startWithIcon == null ? '' : ', $startWithIcon beside an icon'})';
}

/// A button's inline padding at each [ControlSize]; see
/// [AdminButtonStyle.padding].
@immutable
class AdminButtonPadding {
  final AdminButtonInsets small;
  final AdminButtonInsets medium;
  final AdminButtonInsets large;

  const AdminButtonPadding({
    required this.small,
    required this.medium,
    required this.large,
  });

  /// The same insets at every size.
  const AdminButtonPadding.all(AdminButtonInsets insets)
    : small = insets,
      medium = insets,
      large = insets;

  /// The insets at [size].
  AdminButtonInsets of(ControlSize size) => switch (size) {
    ControlSize.small => small,
    ControlSize.medium => medium,
    ControlSize.large => large,
  };

  /// A copy with the given sizes replaced.
  AdminButtonPadding copyWith({
    AdminButtonInsets? small,
    AdminButtonInsets? medium,
    AdminButtonInsets? large,
  }) => AdminButtonPadding(
    small: small ?? this.small,
    medium: medium ?? this.medium,
    large: large ?? this.large,
  );

  static AdminButtonPadding lerp(
    AdminButtonPadding a,
    AdminButtonPadding b,
    double t,
  ) => AdminButtonPadding(
    small: AdminButtonInsets.lerp(a.small, b.small, t),
    medium: AdminButtonInsets.lerp(a.medium, b.medium, t),
    large: AdminButtonInsets.lerp(a.large, b.large, t),
  );

  @override
  bool operator ==(Object other) =>
      other is AdminButtonPadding &&
      other.small == small &&
      other.medium == medium &&
      other.large == large;

  @override
  int get hashCode => Object.hash(small, medium, large);

  @override
  String toString() => 'AdminButtonPadding($small, $medium, $large)';
}

/// A labelled button's minimum width at each [ControlSize]; see
/// [AdminButtonStyle.minWidth]. Zero sets none.
@immutable
class AdminButtonMinWidth {
  final double small;
  final double medium;
  final double large;

  const AdminButtonMinWidth({this.small = 0, this.medium = 0, this.large = 0});

  /// The same minimum at every size.
  const AdminButtonMinWidth.all(double width)
    : small = width,
      medium = width,
      large = width;

  /// The minimum at [size].
  double of(ControlSize size) => switch (size) {
    ControlSize.small => small,
    ControlSize.medium => medium,
    ControlSize.large => large,
  };

  /// A copy with the given sizes replaced.
  AdminButtonMinWidth copyWith({
    double? small,
    double? medium,
    double? large,
  }) => AdminButtonMinWidth(
    small: small ?? this.small,
    medium: medium ?? this.medium,
    large: large ?? this.large,
  );

  static AdminButtonMinWidth lerp(
    AdminButtonMinWidth a,
    AdminButtonMinWidth b,
    double t,
  ) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminButtonMinWidth(
      small: d(a.small, b.small),
      medium: d(a.medium, b.medium),
      large: d(a.large, b.large),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminButtonMinWidth &&
      other.small == small &&
      other.medium == medium &&
      other.large == large;

  @override
  int get hashCode => Object.hash(small, medium, large);

  @override
  String toString() => 'AdminButtonMinWidth($small, $medium, $large)';
}

/// The anatomy of a button beyond its colours: where its content sits, its
/// padding, minimum width and label weight, how it looks disabled, and a few
/// per-variant choices a reference system makes. Provided via
/// [AdminTokens]; read through `context.buttonStyle`, and overridable per
/// button. The corner is `AdminRadii.button(size)` and the height
/// `AdminControlSizes.height(size)`.
///
/// The defaults are the kit's own button: centred content after a leading
/// glyph, `height / 2 - 4` of padding either side, the theme's strong
/// weight, and one neutral disabled look.
@immutable
class AdminButtonStyle {
  /// Where a labelled button lays its content. An icon-only button is
  /// always centred.
  final ButtonLabelAlignment labelAlignment;

  /// Which side of the label the button's glyph sits on. With
  /// [ButtonIconPlacement.end] the glyph takes the button's end edge,
  /// inside [AdminButtonInsets.end].
  final ButtonIconPlacement iconPlacement;

  /// The inline padding at each size; null keeps the kit's `height / 2 - 4`
  /// either side (10 at 28, 14 at 36, 16 at 40). See [paddingOf].
  final AdminButtonPadding? padding;

  /// The narrowest a labelled button draws at each size; null sets none.
  /// See [minWidthOf].
  final AdminButtonMinWidth? minWidth;

  /// The label's weight; null keeps `AdminTypography.button`'s own, the type
  /// spec's `strong`. Apply it with `AdminTypography.weighted`, which keeps
  /// a Google font in step.
  final FontWeight? labelWeight;

  /// How a disabled button draws.
  final ButtonDisabledStyle disabled;

  /// The opacity a [ButtonDisabledStyle.faded] button is drawn at.
  final double fadedOpacity;

  /// `ButtonVariant.secondary` as a filled button in the palette's
  /// `neutralFill` (hovered `neutralFillHover`, pressed
  /// `neutralFillActive`) with its label in `onNeutralFill` and no outline,
  /// rather than the outlined surface button: Carbon's secondary.
  final bool filledSecondary;

  /// `ButtonVariant.secondary`'s outline in `controlBorder`, 3:1 on the
  /// page, rather than the quieter `border`: M3's outlined button.
  final bool strongOutline;

  /// `ButtonVariant.ghost`'s label and glyph in `primaryText` rather than a
  /// neutral: M3's text button, Carbon's ghost in `$link-primary`.
  final bool accentGhost;

  /// `ButtonVariant.secondary`'s outline and label in `primaryHover` under
  /// the pointer: Ant's default button, which turns colorPrimaryHover.
  final bool accentHover;

  const AdminButtonStyle({
    this.labelAlignment = ButtonLabelAlignment.center,
    this.iconPlacement = ButtonIconPlacement.leading,
    this.padding,
    this.minWidth,
    this.labelWeight,
    this.disabled = ButtonDisabledStyle.neutral,
    this.fadedOpacity = 0.5,
    this.filledSecondary = false,
    this.strongOutline = false,
    this.accentGhost = false,
    this.accentHover = false,
  });

  /// The inline padding at [size], for a button [height] tall: [padding]'s
  /// insets there, or `height / 2 - 4` either side.
  AdminButtonInsets paddingOf(ControlSize size, double height) =>
      padding?.of(size) ?? AdminButtonInsets.symmetric(height / 2 - 4);

  /// The minimum width at [size]: [minWidth]'s, or 0.
  double minWidthOf(ControlSize size) => minWidth?.of(size) ?? 0;

  /// A copy with the given members replaced. A null argument keeps the
  /// current value, so [padding], [minWidth] and [labelWeight] cannot be
  /// cleared here; build a new style for that.
  AdminButtonStyle copyWith({
    ButtonLabelAlignment? labelAlignment,
    ButtonIconPlacement? iconPlacement,
    AdminButtonPadding? padding,
    AdminButtonMinWidth? minWidth,
    FontWeight? labelWeight,
    ButtonDisabledStyle? disabled,
    double? fadedOpacity,
    bool? filledSecondary,
    bool? strongOutline,
    bool? accentGhost,
    bool? accentHover,
  }) => AdminButtonStyle(
    labelAlignment: labelAlignment ?? this.labelAlignment,
    iconPlacement: iconPlacement ?? this.iconPlacement,
    padding: padding ?? this.padding,
    minWidth: minWidth ?? this.minWidth,
    labelWeight: labelWeight ?? this.labelWeight,
    disabled: disabled ?? this.disabled,
    fadedOpacity: fadedOpacity ?? this.fadedOpacity,
    filledSecondary: filledSecondary ?? this.filledSecondary,
    strongOutline: strongOutline ?? this.strongOutline,
    accentGhost: accentGhost ?? this.accentGhost,
    accentHover: accentHover ?? this.accentHover,
  );

  /// Interpolates the lengths and the opacity (a side that sets no
  /// [padding] or [minWidth] counts as its default at the kit's heights) and
  /// the weight; the rest switches at the midpoint.
  static AdminButtonStyle lerp(
    AdminButtonStyle a,
    AdminButtonStyle b,
    double t,
  ) {
    final near = t < 0.5 ? a : b;
    AdminButtonPadding paddingAt(AdminButtonStyle s) =>
        s.padding ??
        AdminButtonPadding(
          small: s.paddingOf(ControlSize.small, defaultControlSizes.small),
          medium: s.paddingOf(ControlSize.medium, defaultControlSizes.medium),
          large: s.paddingOf(ControlSize.large, defaultControlSizes.large),
        );
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminButtonStyle(
      labelAlignment: near.labelAlignment,
      iconPlacement: near.iconPlacement,
      padding: a.padding == null && b.padding == null
          ? null
          : AdminButtonPadding.lerp(paddingAt(a), paddingAt(b), t),
      minWidth: a.minWidth == null && b.minWidth == null
          ? null
          : AdminButtonMinWidth.lerp(
              a.minWidth ?? const AdminButtonMinWidth(),
              b.minWidth ?? const AdminButtonMinWidth(),
              t,
            ),
      labelWeight: a.labelWeight == null || b.labelWeight == null
          ? near.labelWeight
          : FontWeight.lerp(a.labelWeight, b.labelWeight, t),
      disabled: near.disabled,
      fadedOpacity: d(a.fadedOpacity, b.fadedOpacity),
      filledSecondary: near.filledSecondary,
      strongOutline: near.strongOutline,
      accentGhost: near.accentGhost,
      accentHover: near.accentHover,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminButtonStyle &&
      other.labelAlignment == labelAlignment &&
      other.iconPlacement == iconPlacement &&
      other.padding == padding &&
      other.minWidth == minWidth &&
      other.labelWeight == labelWeight &&
      other.disabled == disabled &&
      other.fadedOpacity == fadedOpacity &&
      other.filledSecondary == filledSecondary &&
      other.strongOutline == strongOutline &&
      other.accentGhost == accentGhost &&
      other.accentHover == accentHover;

  @override
  int get hashCode => Object.hash(
    labelAlignment,
    iconPlacement,
    padding,
    minWidth,
    labelWeight,
    disabled,
    fadedOpacity,
    filledSecondary,
    strongOutline,
    accentGhost,
    accentHover,
  );

  @override
  String toString() {
    final flags = [
      if (filledSecondary) 'filled secondary',
      if (strongOutline) 'strong outline',
      if (accentGhost) 'accent ghost',
      if (accentHover) 'accent hover',
    ];
    return 'AdminButtonStyle(${labelAlignment.name}, icon '
        '${iconPlacement.name}, padding ${padding ?? 'height / 2 - 4'}, '
        'min width ${minWidth ?? 'none'}, weight ${labelWeight ?? 'strong'}, '
        'disabled ${disabled.name}'
        '${disabled == ButtonDisabledStyle.faded ? ' at $fadedOpacity' : ''}'
        '${flags.isEmpty ? '' : ', ${flags.join(', ')}'})';
  }
}
