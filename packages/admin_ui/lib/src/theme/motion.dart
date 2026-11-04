import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// How the kit moves: three durations by how far something travels, a
/// [pulse] for a looping placeholder, and the easing curves a move takes.
/// Provided via [AdminTokens]; read through `context.motion`, which is
/// [reduced] while the platform asks for less motion.
///
/// - [fast]: a change in place — a toggle's knob, a chevron turning, a
///   hover fading in.
/// - [medium]: a panel opening in the flow — an accordion, a tree's rows, a
///   tab indicator sliding.
/// - [slow]: an overlay crossing the screen — a side sheet, a modal, a
///   toast.
///
/// A timer that paces an interaction rather than easing a change (a hover
/// delay, a search debounce, a toast's dwell) is not motion and does not
/// read these.
@immutable
class AdminMotion {
  final Duration fast;
  final Duration medium;
  final Duration slow;

  /// Half of a loading placeholder's breathing cycle (a skeleton fading out,
  /// then in again).
  final Duration pulse;

  /// A move from one resting place to another, both on screen.
  final Curve standard;

  /// Something arriving: decelerates into place.
  final Curve enter;

  /// Something leaving: accelerates away.
  final Curve exit;

  /// A larger move that should be noticed — a sheet or a dialog opening.
  final Curve emphasized;

  const AdminMotion({
    this.fast = const Duration(milliseconds: 120),
    this.medium = const Duration(milliseconds: 180),
    this.slow = const Duration(milliseconds: 240),
    this.pulse = const Duration(milliseconds: 900),
    this.standard = Curves.easeOutCubic,
    this.enter = Curves.easeOutCubic,
    this.exit = Curves.easeInCubic,
    this.emphasized = Curves.easeInOutCubicEmphasized,
  });

  /// This motion with every duration [Duration.zero] and the curves kept:
  /// what `context.motion` returns while animations are disabled, so a
  /// change lands on its end state in the next frame.
  ///
  /// An [AnimatedSize] cannot run at zero, and a scroll position cannot
  /// animate over it: see `motionReduced`.
  AdminMotion get reduced => copyWith(
    fast: Duration.zero,
    medium: Duration.zero,
    slow: Duration.zero,
    pulse: Duration.zero,
  );

  /// A copy with the given fields replaced.
  AdminMotion copyWith({
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Duration? pulse,
    Curve? standard,
    Curve? enter,
    Curve? exit,
    Curve? emphasized,
  }) => AdminMotion(
    fast: fast ?? this.fast,
    medium: medium ?? this.medium,
    slow: slow ?? this.slow,
    pulse: pulse ?? this.pulse,
    standard: standard ?? this.standard,
    enter: enter ?? this.enter,
    exit: exit ?? this.exit,
    emphasized: emphasized ?? this.emphasized,
  );

  /// Interpolates the durations; the curves switch over at `t = 0.5`.
  static AdminMotion lerp(AdminMotion a, AdminMotion b, double t) {
    Duration d(Duration x, Duration y) => Duration(
      microseconds:
          (x.inMicroseconds + (y.inMicroseconds - x.inMicroseconds) * t)
              .round(),
    );
    final near = t < 0.5 ? a : b;
    return AdminMotion(
      fast: d(a.fast, b.fast),
      medium: d(a.medium, b.medium),
      slow: d(a.slow, b.slow),
      pulse: d(a.pulse, b.pulse),
      standard: near.standard,
      enter: near.enter,
      exit: near.exit,
      emphasized: near.emphasized,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminMotion &&
      other.fast == fast &&
      other.medium == medium &&
      other.slow == slow &&
      other.pulse == pulse &&
      other.standard == standard &&
      other.enter == enter &&
      other.exit == exit &&
      other.emphasized == emphasized;

  @override
  int get hashCode =>
      Object.hash(fast, medium, slow, pulse, standard, enter, exit, emphasized);

  @override
  String toString() =>
      'AdminMotion(${fast.inMilliseconds}/${medium.inMilliseconds}/'
      '${slow.inMilliseconds}ms, pulse ${pulse.inMilliseconds}ms)';
}

/// The kit's own motion (Iris): 120 / 180 / 240ms, decelerating in and
/// accelerating out on cubic curves.
const defaultMotion = AdminMotion();
