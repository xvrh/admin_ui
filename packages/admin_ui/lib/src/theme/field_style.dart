import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// How a field draws its box; see [AdminFieldStyle.variant].
enum FieldVariant {
  /// A box stroked on every side: shadcn, Ant, M3's outlined text field.
  outlined,

  /// A `fieldFill` box with only a bottom rule, its top corners rounded and
  /// its bottom square: Carbon's text input, M3's filled text field.
  filled,

  /// A hairline box in `border` over a bottom rule in the accessible stroke
  /// (`fieldRule`): Fluent 2's input.
  underlined,
}

/// Which edge a focused (or invalid) field marks; see
/// [AdminFieldStyle.focusIndicator].
enum FieldFocusIndicator {
  /// The whole edge takes the focus stroke.
  outline,

  /// Only the bottom rule thickens, to the focus stroke.
  underline,
}

/// How a field's label says whether the field must be filled in; see
/// [AdminFieldStyle.requiredMark].
enum FieldRequiredMark {
  /// A `*` after a required field's label: M3's "Label*", Fluent 2's
  /// required label.
  trailing,

  /// A `*` before a required field's label, 4 from it: Ant's `requiredMark`.
  leading,

  /// No mark on a required field, and "(optional)" after the label of one
  /// that is not: Carbon, which marks the exceptions. Only a form that
  /// declares which fields it requires can say which are optional, so
  /// elsewhere a required field takes the [trailing] `*`.
  optionalText,
}

/// The anatomy of a field: which [variant] of box it draws, how focus shows
/// on it, which colours its focused and hovered edges take, and how its label
/// marks it required ([requiredMark]).
/// Provided via [AdminTokens]; read through `context.fieldStyle`. The widths
/// come from [AdminStroke] (`fieldFocus`, `fieldError`, `fieldFocusHalo`),
/// the corner from `AdminRadii.radiusField`, and `resolveFieldChrome` turns
/// the three into the colours and sides of one state, so every input and
/// trigger in a theme agrees.
///
/// The defaults are the kit's own outlined box, focused in the palette's
/// `focusRing`.
@immutable
class AdminFieldStyle {
  /// The box a field draws.
  final FieldVariant variant;

  /// Which edge focus and error mark.
  final FieldFocusIndicator focusIndicator;

  /// The focused edge (and the halo) in `controlAccent` rather than
  /// `focusRing`: M3's primary outline, Ant's colorPrimary, Fluent's brand
  /// underline.
  final bool accentFocus;

  /// The hovered edge in a lighter step of the focus accent rather than a
  /// stronger neutral: Ant's colorPrimaryHover. The accent is eased toward
  /// the fill as far as it keeps 3:1 there (and the resting edge's
  /// contrast), so a hovered field never outweighs a focused one.
  final bool accentHover;

  /// The opacity of the focus halo's colour, where the theme draws one
  /// (`AdminStroke.fieldFocusHalo`): shadcn's `ring-ring/50` at the default.
  final double haloOpacity;

  /// How the label marks a required field, or the optional ones.
  final FieldRequiredMark requiredMark;

  const AdminFieldStyle({
    this.variant = FieldVariant.outlined,
    this.focusIndicator = FieldFocusIndicator.outline,
    this.accentFocus = false,
    this.accentHover = false,
    this.haloOpacity = 0.5,
    this.requiredMark = FieldRequiredMark.trailing,
  });

  /// A copy with the given members replaced.
  AdminFieldStyle copyWith({
    FieldVariant? variant,
    FieldFocusIndicator? focusIndicator,
    bool? accentFocus,
    bool? accentHover,
    double? haloOpacity,
    FieldRequiredMark? requiredMark,
  }) => AdminFieldStyle(
    variant: variant ?? this.variant,
    focusIndicator: focusIndicator ?? this.focusIndicator,
    accentFocus: accentFocus ?? this.accentFocus,
    accentHover: accentHover ?? this.accentHover,
    haloOpacity: haloOpacity ?? this.haloOpacity,
    requiredMark: requiredMark ?? this.requiredMark,
  );

  /// Interpolates [haloOpacity]; the rest switches at the midpoint.
  static AdminFieldStyle lerp(AdminFieldStyle a, AdminFieldStyle b, double t) {
    final near = t < 0.5 ? a : b;
    return AdminFieldStyle(
      variant: near.variant,
      focusIndicator: near.focusIndicator,
      accentFocus: near.accentFocus,
      accentHover: near.accentHover,
      haloOpacity: lerpDouble(a.haloOpacity, b.haloOpacity, t)!,
      requiredMark: near.requiredMark,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminFieldStyle &&
      other.variant == variant &&
      other.focusIndicator == focusIndicator &&
      other.accentFocus == accentFocus &&
      other.accentHover == accentHover &&
      other.haloOpacity == haloOpacity &&
      other.requiredMark == requiredMark;

  @override
  int get hashCode => Object.hash(
    variant,
    focusIndicator,
    accentFocus,
    accentHover,
    haloOpacity,
    requiredMark,
  );

  @override
  String toString() =>
      'AdminFieldStyle(${variant.name}, focus ${focusIndicator.name}'
      '${accentFocus ? ' in the accent' : ''}'
      '${accentHover ? ', accent hover' : ''}, halo $haloOpacity, '
      '${requiredMark.name} mark)';
}
