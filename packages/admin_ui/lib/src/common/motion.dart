/// Reduced motion beyond the theme's durations.
///
/// An animation takes its duration and curve from the theme:
/// `context.motion.fast` / `.medium` / `.slow` and `.standard`, `.enter`,
/// `.exit` (see [AdminMotion]). `context.motion` is already
/// [AdminMotion.reduced] — every duration zero — while animations are
/// disabled, so reading it is the reduced-motion handling. The helpers here
/// cover what a zero duration does not.
///
/// @docImport '../theme/motion.dart';
library;

import 'package:flutter/widgets.dart';

/// Whether the platform asks for less motion: animations are disabled.
///
/// An [AnimatedSize] cannot run at zero (it would re-dirty its own layout),
/// and a scroll position cannot animate over zero: where
/// `context.motion` gives [Duration.zero], check this to leave the one out
/// and jump the other.
bool motionReduced(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// [duration], or [Duration.zero] while animations are disabled (reduced
/// motion), so an expanding panel, a sliding row or a turning caret lands on
/// its end state in the next frame instead. For motion that eases a change,
/// not for timers that pace an interaction (a hover delay, a scroll tick).
///
/// A duration of the theme's comes from `context.motion`, which is zeroed
/// already; this is for one the caller is given.
///
/// An [AnimatedSize] cannot run at zero (it would re-dirty its own layout),
/// and a scroll position cannot animate over zero: leave the one out and jump
/// the other when this returns [Duration.zero].
Duration motionDuration(BuildContext context, Duration duration) =>
    motionReduced(context) ? Duration.zero : duration;

/// The `value` of an indeterminate circular progress indicator: null, its
/// looping sweep, or while animations are disabled a still frame of three
/// quarters of the ring.
double? spinnerValue(BuildContext context) =>
    motionReduced(context) ? 0.75 : null;

/// An indeterminate linear progress indicator's still frame, for while
/// animations are disabled ([motionReduced]): a segment across the middle of
/// the track, which reads as work under way without claiming how much is
/// done. Sized and announced as a `LinearProgressIndicator` given the same
/// arguments.
class StillLinearProgress extends StatelessWidget {
  final double minHeight;
  final Color backgroundColor;
  final Color color;
  final String? semanticsLabel;

  const StillLinearProgress({
    super.key,
    required this.minHeight,
    required this.backgroundColor,
    required this.color,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: minHeight,
        ),
        child: ColoredBox(
          color: backgroundColor,
          child: FractionallySizedBox(
            widthFactor: 0.4,
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );
  }
}
