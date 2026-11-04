import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// The window widths where the kit's layouts change: Material 3's window
/// size classes, folded to the three an admin needs. Provided via
/// [AdminTokens]; read through `context.breakpoints`, or classify a width
/// with [AdminBreakpoint.of] and [AdminBreakpoint.forWidth].
///
/// - Compact, under [medium] (600): Material 3's compact class, a phone.
///   No sidebar; lists as cards, dialogs full screen.
/// - Medium, from [medium] up to [expanded] (1200): Material 3's medium and
///   expanded classes, a tablet or a small window. The sidebar folds to a
///   rail.
/// - Expanded, from [expanded] up: Material 3's large and extra-large
///   classes, a desktop window. Everything at full width.
///
/// A theme sets its own widths through `AdminTheme.from(breakpoints:)`.
@immutable
class AdminBreakpoints {
  /// The width where the medium class starts: a window this wide or wider,
  /// and narrower than [expanded], is medium.
  final double medium;

  /// The width where the expanded class starts.
  final double expanded;

  const AdminBreakpoints({this.medium = 600, this.expanded = 1200})
    : assert(medium >= 0 && medium <= expanded);

  /// A copy with the given widths replaced.
  AdminBreakpoints copyWith({double? medium, double? expanded}) =>
      AdminBreakpoints(
        medium: medium ?? this.medium,
        expanded: expanded ?? this.expanded,
      );

  /// [a] below the halfway point, [b] from it: a layout switches at one
  /// width or the other, never at one in between.
  static AdminBreakpoints lerp(
    AdminBreakpoints a,
    AdminBreakpoints b,
    double t,
  ) => t < 0.5 ? a : b;

  @override
  bool operator ==(Object other) =>
      other is AdminBreakpoints &&
      other.medium == medium &&
      other.expanded == expanded;

  @override
  int get hashCode => Object.hash(medium, expanded);

  @override
  String toString() => 'AdminBreakpoints(medium $medium, expanded $expanded)';
}

/// The size class of a window, or of any width: [compact], [medium] or
/// [expanded], split where [AdminBreakpoints] says.
enum AdminBreakpoint {
  /// Under [AdminBreakpoints.medium]: a phone.
  compact,

  /// From [AdminBreakpoints.medium] up to [AdminBreakpoints.expanded]: a
  /// tablet or a small window.
  medium,

  /// From [AdminBreakpoints.expanded] up: a desktop window.
  expanded;

  /// The class of [width], split at [breakpoints]. Classify a widget's own
  /// width with it, from a `LayoutBuilder`'s constraints and
  /// `context.breakpoints`.
  static AdminBreakpoint forWidth(
    double width, [
    AdminBreakpoints breakpoints = const AdminBreakpoints(),
  ]) => width < breakpoints.medium
      ? compact
      : width < breakpoints.expanded
      ? medium
      : expanded;

  /// The class of the window [context] is in: its [MediaQuery] width, split
  /// at the theme's `context.breakpoints`. Rebuilds [context] when the
  /// window's size changes.
  static AdminBreakpoint of(BuildContext context) => forWidth(
    MediaQuery.sizeOf(context).width,
    context.adminTokens.breakpoints,
  );

  bool get isCompact => this == compact;

  bool get isMedium => this == medium;

  bool get isExpanded => this == expanded;
}
