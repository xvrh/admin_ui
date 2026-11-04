import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

/// The pulse held at its midpoint, for reduced motion.
const _stillPulse = AlwaysStoppedAnimation<double>(0.5);

/// Runs [pulse] back and forth over [period], `motion.pulse` (half a cycle);
/// a zero period, as under reduced motion, stops it.
void _breathe(AnimationController pulse, Duration period) {
  if (period == Duration.zero) {
    pulse.stop();
  } else if (pulse.duration != period || !pulse.isAnimating) {
    pulse
      ..duration = period
      ..repeat(reverse: true);
  }
}

/// A pulsing placeholder block shown while real content loads. Compose several
/// to sketch the shape of the content to come — a row, a card, a paragraph.
///
/// Each [Skeleton] pulses on its own ticker. Wrap a cluster in a
/// [SkeletonGroup] to drive them all from one controller: synchronised, and
/// cheaper when many are on screen at once (a loading list, a card grid).
///
/// [width] defaults to filling the available width — give it a fixed value for
/// a short bar, or use [Skeleton.circle] for an avatar/thumb.
///
/// The pulse is the theme's `motion.pulse` each way. With animations
/// disabled (reduced motion) the blocks hold a still, mid-pulse shade.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool _circle;

  const Skeleton({super.key, this.width, this.height = 12, this.borderRadius})
    : _circle = false;

  const Skeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = null,
      _circle = true;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _own;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_own case final own?) _breathe(own, context.motion.pulse);
  }

  @override
  Widget build(BuildContext context) {
    final period = context.motion.pulse;
    final pulse = period == Duration.zero
        ? _stillPulse
        : SkeletonGroup._of(context) ?? _ownPulse(period);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = 0.4 + pulse.value * 0.45;
          final color = Color.lerp(
            context.colors.borderSubtle,
            context.colors.border,
            t,
          )!;
          return Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: color,
              shape: widget._circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget._circle
                  ? null
                  : (widget.borderRadius ??
                        BorderRadius.circular(context.radii.radiusSmall)),
            ),
          );
        },
      ),
    );
  }

  Animation<double> _ownPulse(Duration period) {
    final pulse = _own ??= AnimationController(vsync: this);
    _breathe(pulse, period);
    return pulse;
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }
}

/// Drives every descendant [Skeleton] from a single pulse controller, so a
/// cluster pulses in sync and only pays for one ticker.
class SkeletonGroup extends StatefulWidget {
  final Widget child;

  const SkeletonGroup({super.key, required this.child});

  static Animation<double>? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonPulse>()?.pulse;

  @override
  State<SkeletonGroup> createState() => _SkeletonGroupState();
}

class _SkeletonGroupState extends State<SkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _breathe(_controller, context.motion.pulse);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonPulse(pulse: _controller, child: widget.child);
}

class _SkeletonPulse extends InheritedWidget {
  final Animation<double> pulse;

  const _SkeletonPulse({required this.pulse, required super.child});

  @override
  bool updateShouldNotify(_SkeletonPulse oldWidget) => pulse != oldWidget.pulse;
}
