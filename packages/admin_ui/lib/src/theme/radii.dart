import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'sizes.dart';

/// Corner radii for the admin UI. Provided via [AdminTokens]; read through
/// `context.radii`.
///
/// [radiusSmall], [radius] and [radiusLarge] are the base scale. The role
/// radii ([radiusMenu], [radiusDialog], [radiusPill], [radiusField],
/// [radiusButton]) default to a step of that scale; a theme authors one only
/// where its design system gives that component a corner of its own
/// (Material's 4dp menus and fields, 28dp dialogs and full-round buttons,
/// Carbon's square overlays).
///
/// A radius of 999 is full: a pill, or a stadium on a button.
@immutable
class AdminRadii {
  final double radiusSmall;
  final double radius;
  final double radiusLarge;

  // authored roles; null means derived (see the getters)
  final double? _radiusMenu;
  final double? _radiusDialog;
  final double? _radiusPill;
  final double? _radiusField;
  final double? _radiusButton;

  const AdminRadii({
    required this.radiusSmall,
    required this.radius,
    required this.radiusLarge,
    this._radiusMenu,
    this._radiusDialog,
    this._radiusPill,
    this._radiusField,
    this._radiusButton,
  });

  /// Menus, popovers, pickers, the command palette and toasts: authored, or
  /// [radius].
  double get radiusMenu => _radiusMenu ?? radius;

  /// Modals, confirms and side sheets: authored, or [radiusLarge].
  double get radiusDialog => _radiusDialog ?? radiusLarge;

  /// Tags, count badges and status pills: authored, or 999 (a full pill).
  double get radiusPill => _radiusPill ?? 999;

  /// A field's box — every input, select and picker trigger — at every
  /// size: authored, or [radius].
  double get radiusField => _radiusField ?? radius;

  /// A button's corner at every size where the theme authors one, else null:
  /// read [button], which falls back to the base scale.
  double? get radiusButton => _radiusButton;

  /// A button's corner at [size]: [radiusButton] where authored, otherwise
  /// [radiusSmall] at [ControlSize.small] and [radius] at the medium and
  /// large sizes.
  double button(ControlSize size) =>
      _radiusButton ??
      switch (size) {
        ControlSize.small => radiusSmall,
        ControlSize.medium || ControlSize.large => radius,
      };

  /// Checkbox corners: [radiusSmall], capped at 4 so an 18px box never reads
  /// as a radio.
  double get radiusCheck => math.min(radiusSmall, 4);

  AdminRadii copyWith({
    double? radiusSmall,
    double? radius,
    double? radiusLarge,
    double? radiusMenu,
    double? radiusDialog,
    double? radiusPill,
    double? radiusField,
    double? radiusButton,
  }) {
    return AdminRadii(
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radius: radius ?? this.radius,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      radiusMenu: radiusMenu ?? _radiusMenu,
      radiusDialog: radiusDialog ?? _radiusDialog,
      radiusPill: radiusPill ?? _radiusPill,
      radiusField: radiusField ?? _radiusField,
      radiusButton: radiusButton ?? _radiusButton,
    );
  }

  /// Interpolates every radius. A role neither side authored stays derived;
  /// otherwise the two resolved values are interpolated. A [radiusButton]
  /// one side derives counts as its medium size's [radius] on the way, so a
  /// frame between them draws that one corner at every size; the ends are
  /// [a] and [b] themselves.
  static AdminRadii lerp(AdminRadii a, AdminRadii b, double t) {
    if (t == 0) return a;
    if (t == 1) return b;
    double d(double x, double y) => x + (y - x) * t;
    double? o(double? x, double? y, double resolvedX, double resolvedY) =>
        x == null && y == null ? null : d(resolvedX, resolvedY);
    return AdminRadii(
      radiusSmall: d(a.radiusSmall, b.radiusSmall),
      radius: d(a.radius, b.radius),
      radiusLarge: d(a.radiusLarge, b.radiusLarge),
      radiusMenu: o(a._radiusMenu, b._radiusMenu, a.radiusMenu, b.radiusMenu),
      radiusDialog: o(
        a._radiusDialog,
        b._radiusDialog,
        a.radiusDialog,
        b.radiusDialog,
      ),
      radiusPill: o(a._radiusPill, b._radiusPill, a.radiusPill, b.radiusPill),
      radiusField: o(
        a._radiusField,
        b._radiusField,
        a.radiusField,
        b.radiusField,
      ),
      radiusButton: o(
        a._radiusButton,
        b._radiusButton,
        a.button(ControlSize.medium),
        b.button(ControlSize.medium),
      ),
    );
  }

  /// Equal when every radius matches and the same roles are authored: a role
  /// left to derive is not the same token as one authored at today's value.
  @override
  bool operator ==(Object other) =>
      other is AdminRadii &&
      other.radiusSmall == radiusSmall &&
      other.radius == radius &&
      other.radiusLarge == radiusLarge &&
      other._radiusMenu == _radiusMenu &&
      other._radiusDialog == _radiusDialog &&
      other._radiusPill == _radiusPill &&
      other._radiusField == _radiusField &&
      other._radiusButton == _radiusButton;

  @override
  int get hashCode => Object.hash(
    radiusSmall,
    radius,
    radiusLarge,
    _radiusMenu,
    _radiusDialog,
    _radiusPill,
    _radiusField,
    _radiusButton,
  );
}

const defaultRadii = AdminRadii(
  radiusSmall: 7.0,
  radius: 9.0,
  radiusLarge: 12.0,
);
