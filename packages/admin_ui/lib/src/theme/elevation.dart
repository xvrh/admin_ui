import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Shadow tokens for raised surfaces — menus, popovers, modals, cards. Three
/// steps; read through `context.elevation`. Provided via [AdminTokens]: the
/// shipped themes take [defaultElevation] in light mode and
/// [defaultDarkElevation] in dark, and a theme may pass its own set instead.
@immutable
class AdminElevation {
  /// Resting lift — dropdowns, hover cards.
  final List<BoxShadow> sm;

  /// Floating surfaces — popovers, menus.
  final List<BoxShadow> md;

  /// Overlay surfaces — modals, dialogs.
  final List<BoxShadow> lg;

  const AdminElevation({required this.sm, required this.md, required this.lg});

  static AdminElevation lerp(AdminElevation a, AdminElevation b, double t) {
    return AdminElevation(
      sm: BoxShadow.lerpList(a.sm, b.sm, t) ?? const [],
      md: BoxShadow.lerpList(a.md, b.md, t) ?? const [],
      lg: BoxShadow.lerpList(a.lg, b.lg, t) ?? const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminElevation &&
      listEquals(other.sm, sm) &&
      listEquals(other.md, md) &&
      listEquals(other.lg, lg);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(sm), Object.hashAll(md), Object.hashAll(lg));
}

/// Neutral shadow set used unless a theme overrides it.
const defaultElevation = AdminElevation(
  sm: [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
  ],
  md: [
    BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
  ],
  lg: [
    BoxShadow(color: Color(0x29000000), blurRadius: 28, offset: Offset(0, 12)),
  ],
);

/// The dark-theme counterpart of [defaultElevation]: black at 40–60% with a
/// wider blur, since a light-theme shadow barely registers on a dark page.
const defaultDarkElevation = AdminElevation(
  sm: [
    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1)),
  ],
  md: [
    BoxShadow(color: Color(0x80000000), blurRadius: 18, offset: Offset(0, 6)),
  ],
  lg: [
    BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 16)),
  ],
);
