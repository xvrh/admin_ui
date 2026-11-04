import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// Line widths for the admin UI. Provided via [AdminTokens]; read through
/// `context.stroke`. The focus ring's width is [AdminFocusSpec.width].
@immutable
class AdminStroke {
  /// A divider, a card's edge, a table's rule.
  final double hairline;

  /// A control's resting outline: an input, a secondary button, a trigger.
  final double control;

  /// An outline that must read as a control on its own: an unchecked
  /// checkbox or radio.
  final double controlStrong;

  /// A focused field's outline (see `fieldBorderSide`).
  final double fieldFocus;

  /// A field's outline in error. Focused, it takes the wider of this and
  /// [fieldFocus].
  final double fieldError;

  /// A focused field's halo: a band this wide just outside its outline, in
  /// a translucent focus colour (see `fieldFocusHalo`), as shadcn draws its
  /// `ring-[3px]` around a focused input. Zero, the default, draws none.
  final double fieldFocusHalo;

  /// A selection bar or underline: the selected tab, the selected nav item.
  final double indicator;

  const AdminStroke({
    this.hairline = 1,
    this.control = 1,
    this.controlStrong = 1.5,
    this.fieldFocus = 1.5,
    this.fieldError = 1.5,
    this.fieldFocusHalo = 0,
    this.indicator = 2,
  });

  /// A copy with the given widths replaced.
  AdminStroke copyWith({
    double? hairline,
    double? control,
    double? controlStrong,
    double? fieldFocus,
    double? fieldError,
    double? fieldFocusHalo,
    double? indicator,
  }) => AdminStroke(
    hairline: hairline ?? this.hairline,
    control: control ?? this.control,
    controlStrong: controlStrong ?? this.controlStrong,
    fieldFocus: fieldFocus ?? this.fieldFocus,
    fieldError: fieldError ?? this.fieldError,
    fieldFocusHalo: fieldFocusHalo ?? this.fieldFocusHalo,
    indicator: indicator ?? this.indicator,
  );

  static AdminStroke lerp(AdminStroke a, AdminStroke b, double t) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminStroke(
      hairline: d(a.hairline, b.hairline),
      control: d(a.control, b.control),
      controlStrong: d(a.controlStrong, b.controlStrong),
      fieldFocus: d(a.fieldFocus, b.fieldFocus),
      fieldError: d(a.fieldError, b.fieldError),
      fieldFocusHalo: d(a.fieldFocusHalo, b.fieldFocusHalo),
      indicator: d(a.indicator, b.indicator),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminStroke &&
      other.hairline == hairline &&
      other.control == control &&
      other.controlStrong == controlStrong &&
      other.fieldFocus == fieldFocus &&
      other.fieldError == fieldError &&
      other.fieldFocusHalo == fieldFocusHalo &&
      other.indicator == indicator;

  @override
  int get hashCode => Object.hash(
    hairline,
    control,
    controlStrong,
    fieldFocus,
    fieldError,
    fieldFocusHalo,
    indicator,
  );

  @override
  String toString() =>
      'AdminStroke(hairline $hairline, control $control/$controlStrong, '
      'field focus $fieldFocus, error $fieldError, halo $fieldFocusHalo, '
      'indicator $indicator)';
}
