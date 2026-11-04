import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// The three control heights of a theme; see [AdminControlSizes].
enum ControlSize { small, medium, large }

/// Control geometry for the admin UI: the height of every control at each
/// [ControlSize] — buttons, inputs, field triggers, icon actions — and the
/// insets a field lays its text and icons out with. Provided via [AdminTokens];
/// read through `context.sizes`.
///
/// One height per size across control types is what lets a button, an input
/// and a select sit in one row: each theme picks the ramp of its design
/// system, and every control reads it.
@immutable
class AdminControlSizes {
  final double small;
  final double medium;
  final double large;

  /// Horizontal padding between a field's edge and its text, or its leading
  /// or trailing glyph.
  final double fieldPaddingX;

  /// A field's leading and trailing glyphs.
  final double fieldIcon;

  /// Between a field's glyph and its text.
  final double fieldIconGap;

  const AdminControlSizes({
    required this.small,
    required this.medium,
    required this.large,
    this.fieldPaddingX = 12,
    this.fieldIcon = 16,
    this.fieldIconGap = 8,
  });

  /// The control height at [size].
  double height(ControlSize size) => switch (size) {
    ControlSize.small => small,
    ControlSize.medium => medium,
    ControlSize.large => large,
  };

  /// Where a field's text starts after a leading glyph, and ends before a
  /// trailing one: [fieldPaddingX] + [fieldIcon] + [fieldIconGap].
  double get fieldIconInset => fieldPaddingX + fieldIcon + fieldIconGap;

  AdminControlSizes copyWith({
    double? small,
    double? medium,
    double? large,
    double? fieldPaddingX,
    double? fieldIcon,
    double? fieldIconGap,
  }) {
    return AdminControlSizes(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      fieldPaddingX: fieldPaddingX ?? this.fieldPaddingX,
      fieldIcon: fieldIcon ?? this.fieldIcon,
      fieldIconGap: fieldIconGap ?? this.fieldIconGap,
    );
  }

  static AdminControlSizes lerp(
    AdminControlSizes a,
    AdminControlSizes b,
    double t,
  ) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminControlSizes(
      small: d(a.small, b.small),
      medium: d(a.medium, b.medium),
      large: d(a.large, b.large),
      fieldPaddingX: d(a.fieldPaddingX, b.fieldPaddingX),
      fieldIcon: d(a.fieldIcon, b.fieldIcon),
      fieldIconGap: d(a.fieldIconGap, b.fieldIconGap),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminControlSizes &&
      other.small == small &&
      other.medium == medium &&
      other.large == large &&
      other.fieldPaddingX == fieldPaddingX &&
      other.fieldIcon == fieldIcon &&
      other.fieldIconGap == fieldIconGap;

  @override
  int get hashCode =>
      Object.hash(small, medium, large, fieldPaddingX, fieldIcon, fieldIconGap);

  @override
  String toString() =>
      'AdminControlSizes($small/$medium/$large, padding $fieldPaddingX, '
      'icon $fieldIcon + $fieldIconGap)';
}

/// The kit's own ramp (Iris): 28 / 36 / 40.
const defaultControlSizes = AdminControlSizes(small: 28, medium: 36, large: 40);

/// Glyph sizes for the admin UI: 12 / 14 / 16 / 20 / 24. Provided via
/// [AdminTokens]; read through `context.iconSizes`. The defaults serve every
/// shipped theme — a 16px glyph in a control, as lucide's `size-4` in
/// shadcn and the 16px icons of Fluent and Carbon — and a theme overrides
/// them whole.
///
/// A field's own leading and trailing glyphs are
/// [AdminControlSizes.fieldIcon].
@immutable
class AdminIconSizes {
  /// A glyph inside a badge, a chip or a micro label.
  final double xs;

  /// A glyph beside caption or small text: a small button, a status line.
  final double sm;

  /// The glyph in a control or beside body text: a button, a menu item, a
  /// list row.
  final double md;

  /// A glyph that leads a larger element: an alert, a toolbar, a nav item.
  final double lg;

  /// An empty state's or a tile's glyph.
  final double xl;

  const AdminIconSizes({
    this.xs = 12,
    this.sm = 14,
    this.md = 16,
    this.lg = 20,
    this.xl = 24,
  });

  /// A copy with the given sizes replaced.
  AdminIconSizes copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) => AdminIconSizes(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
  );

  static AdminIconSizes lerp(AdminIconSizes a, AdminIconSizes b, double t) {
    double d(double x, double y) => lerpDouble(x, y, t)!;
    return AdminIconSizes(
      xs: d(a.xs, b.xs),
      sm: d(a.sm, b.sm),
      md: d(a.md, b.md),
      lg: d(a.lg, b.lg),
      xl: d(a.xl, b.xl),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminIconSizes &&
      other.xs == xs &&
      other.sm == sm &&
      other.md == md &&
      other.lg == lg &&
      other.xl == xl;

  @override
  int get hashCode => Object.hash(xs, sm, md, lg, xl);

  @override
  String toString() => 'AdminIconSizes($xs/$sm/$md/$lg/$xl)';
}
