/// @docImport 'palette.dart';
/// @docImport 'radii.dart';
/// @docImport 'tokens.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// What a feedback surface is filled with; see
/// [AdminFeedbackStyle.alertFill] and [AdminFeedbackStyle.toastFill].
enum FeedbackFill {
  /// The status colour washed into the surface ([AdminPalette.statusFill]),
  /// edged a step stronger ([AdminPalette.statusBorder]): the kit's own
  /// alert, Ant's, Fluent's MessageBar, Carbon's low-contrast notification.
  tint,

  /// [AdminPalette.surface], edged in [AdminPalette.border], the status left
  /// to the icon: shadcn's Alert is a card, as a toast is in most systems.
  surface,
}

/// The anatomy of the feedback surfaces: what an `Alert` and a toast are
/// filled with, the status bar on their leading edge, an alert's corner and
/// whether a toast is outlined. Provided via [AdminTokens]; read through
/// `context.feedbackStyle`.
///
/// The defaults are the kit's own: a tinted alert with no bar, at the theme's
/// radius; an outlined toast in the surface colour behind a 4px status bar.
@immutable
class AdminFeedbackStyle {
  /// What an alert is filled with.
  final FeedbackFill alertFill;

  /// The width of the status bar on an alert's leading edge, in the status
  /// colour: Carbon's notifications carry 3. Zero is none.
  final double alertBar;

  /// An alert's corner where it is not [AdminRadii.radius]: shadcn's alert
  /// is `rounded-lg` and Ant's `borderRadiusLG`, a step rounder than their
  /// controls. Null is the theme's radius.
  final double? alertRadius;

  /// What a toast is filled with.
  final FeedbackFill toastFill;

  /// The width of the status bar on a toast's leading edge; zero is none.
  final double toastBar;

  /// Whether a toast is ringed in a hairline as well as lifted on its
  /// shadow: its fill's edge, [AdminPalette.border] around the surface and
  /// the status border around a tint. A dark palette, where a shadow does
  /// not read, always rings it.
  final bool toastOutline;

  const AdminFeedbackStyle({
    this.alertFill = FeedbackFill.tint,
    this.alertBar = 0,
    this.alertRadius,
    this.toastFill = FeedbackFill.surface,
    this.toastBar = 4,
    this.toastOutline = true,
  }) : assert(alertBar >= 0 && toastBar >= 0),
       assert(alertRadius == null || alertRadius >= 0);

  /// A copy with the given members replaced.
  AdminFeedbackStyle copyWith({
    FeedbackFill? alertFill,
    double? alertBar,
    double? alertRadius,
    FeedbackFill? toastFill,
    double? toastBar,
    bool? toastOutline,
  }) => AdminFeedbackStyle(
    alertFill: alertFill ?? this.alertFill,
    alertBar: alertBar ?? this.alertBar,
    alertRadius: alertRadius ?? this.alertRadius,
    toastFill: toastFill ?? this.toastFill,
    toastBar: toastBar ?? this.toastBar,
    toastOutline: toastOutline ?? this.toastOutline,
  );

  /// Interpolates the bars, and an [alertRadius] both sides author; the rest
  /// comes from the side [t] is nearer.
  static AdminFeedbackStyle lerp(
    AdminFeedbackStyle a,
    AdminFeedbackStyle b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    final near = t < 0.5 ? a : b;
    return AdminFeedbackStyle(
      alertFill: near.alertFill,
      alertBar: lerpDouble(a.alertBar, b.alertBar, t)!,
      alertRadius: a.alertRadius != null && b.alertRadius != null
          ? lerpDouble(a.alertRadius, b.alertRadius, t)
          : near.alertRadius,
      toastFill: near.toastFill,
      toastBar: lerpDouble(a.toastBar, b.toastBar, t)!,
      toastOutline: near.toastOutline,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminFeedbackStyle &&
      other.alertFill == alertFill &&
      other.alertBar == alertBar &&
      other.alertRadius == alertRadius &&
      other.toastFill == toastFill &&
      other.toastBar == toastBar &&
      other.toastOutline == toastOutline;

  @override
  int get hashCode => Object.hash(
    alertFill,
    alertBar,
    alertRadius,
    toastFill,
    toastBar,
    toastOutline,
  );

  @override
  String toString() =>
      'AdminFeedbackStyle(alert ${alertFill.name}, bar $alertBar, '
      '${alertRadius == null ? "the theme's radius" : 'radius $alertRadius'}; '
      'toast ${toastFill.name}, bar $toastBar, '
      '${toastOutline ? 'outlined' : 'no outline'})';
}
