import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../motion.dart';

/// A primary-coloured progress indicator, sized. The inline loading atom — drop
/// it next to a label, inside a button slot, or wherever a bounded spinner is
/// needed.
///
/// The ring is drawn inside [size]. Screen readers hear [semanticLabel] as a
/// live region; turn [announce] off where the surrounding widget announces
/// the loading itself. With animations disabled (reduced motion) it holds
/// still.
class Spinner extends StatelessWidget {
  final double size;
  final Color? color;

  /// What a screen reader announces; null reads the localized "Loading".
  final String? semanticLabel;

  /// Whether a screen reader hears [semanticLabel] at all.
  final bool announce;

  const Spinner({
    super.key,
    this.size = 20,
    this.color,
    this.semanticLabel,
    this.announce = true,
  });

  @override
  Widget build(BuildContext context) {
    final label = announce
        ? semanticLabel ?? context.adminL10n.display.loadingLabel
        : null;
    Widget spinner = SizedBox.square(
      dimension: size,
      child: ExcludeSemantics(
        child: CircularProgressIndicator(
          value: spinnerValue(context),
          strokeWidth: size <= 20 ? 2 : 2.5,
          strokeAlign: CircularProgressIndicator.strokeAlignInside,
          color: color ?? context.colors.primary,
        ),
      ),
    );
    if (label != null) {
      spinner = Semantics(
        container: true,
        liveRegion: true,
        label: label,
        child: spinner,
      );
    }
    return spinner;
  }
}

/// Dims [child] behind a scrim with a centred [Spinner] while [loading] — the
/// re-load state, when there's already stale content to keep on screen (a list
/// refetching, a form saving). Use [LoadingPanel] instead for the first load,
/// when there's nothing to show yet.
///
/// Blocks interaction with the content underneath while loading — pointer and
/// keyboard alike — and announces [message] (or [semanticLabel]) to screen
/// readers.
class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  final String? message;

  /// Announced when there is no [message]; the localized "Loading" when
  /// null.
  final String? semanticLabel;

  const LoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.message,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ExcludeFocus(
          excluding: loading,
          child: AbsorbPointer(absorbing: loading, child: child),
        ),
        if (loading)
          Positioned.fill(
            child: ColoredBox(
              // token-literal: the veil over content while it loads
              color: context.colors.surface.withValues(alpha: 0.6),
              child: Center(
                child: _LoadingIndicator(
                  message: message,
                  semanticLabel: semanticLabel,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A centred [Spinner] with an optional [message], filling its parent — the
/// placeholder a page or panel shows while its data loads. Pair it with
/// [EmptyState] / [ErrorState] for the full load → empty/error triad.
class LoadingPanel extends StatelessWidget {
  final String? message;
  final double minHeight;

  /// Announced when there is no [message]; the localized "Loading" when
  /// null.
  final String? semanticLabel;

  const LoadingPanel({
    super.key,
    this.message,
    this.minHeight = 160,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: _LoadingIndicator(
          message: message,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

/// The spinner over an optional message, announced as one live region: the
/// message when there is one, else [semanticLabel].
class _LoadingIndicator extends StatelessWidget {
  final String? message;
  final String? semanticLabel;

  const _LoadingIndicator({required this.message, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message == null
          ? semanticLabel ?? context.adminL10n.display.loadingLabel
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Spinner(size: 26, announce: false),
          if (message != null) ...[
            const Gap(AdminSpacing.lg),
            Text(message!, style: context.type.bodyMuted),
          ],
        ],
      ),
    );
  }
}
