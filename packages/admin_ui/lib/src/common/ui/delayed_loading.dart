import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/tokens.dart';
import '../motion.dart';

/// Holds a loading treatment back until a load has run for [delay], so one
/// that finishes sooner — an in-memory refetch, a cached page — never
/// flashes a bar or a dimmed body.
///
/// [builder] gets `show`: true once [loading] has stayed true for [delay],
/// false again the moment it turns false. A zero [delay] shows at once.
class DelayedLoading extends StatefulWidget {
  final bool loading;
  final Duration delay;
  final Widget Function(BuildContext context, bool show) builder;

  const DelayedLoading({
    super.key,
    required this.loading,
    this.delay = const Duration(milliseconds: 150),
    required this.builder,
  });

  @override
  State<DelayedLoading> createState() => _DelayedLoadingState();
}

class _DelayedLoadingState extends State<DelayedLoading> {
  bool _show = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(DelayedLoading old) {
    super.didUpdateWidget(old);
    if (widget.loading != old.loading) _sync();
  }

  void _sync() {
    if (!widget.loading) {
      _timer?.cancel();
      _timer = null;
      _show = false;
    } else if (widget.delay <= Duration.zero) {
      _show = true;
    } else {
      _timer ??= Timer(widget.delay, () {
        _timer = null;
        if (mounted) setState(() => _show = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _show);
}

/// The thin bar a surface runs along its top edge while it reloads: 2px of
/// indeterminate progress in the primary, on a transparent track so the
/// content beneath stays in view. Pair it with [DelayedLoading].
class TopProgressBar extends StatelessWidget {
  const TopProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: motionReduced(context)
          ? StillLinearProgress(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: context.colors.primary,
              semanticsLabel: context.adminL10n.display.loadingLabel,
            )
          : LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: context.colors.primary,
              semanticsLabel: context.adminL10n.display.loadingLabel,
            ),
    );
  }
}
