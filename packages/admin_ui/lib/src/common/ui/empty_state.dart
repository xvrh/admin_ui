import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'severity.dart';

/// The centred placeholder a list, table, or panel shows when it has nothing to
/// display: a muted icon, a [title], an optional [message] and an optional
/// [action] (e.g. a "Create" button). The empty arm of the load → empty/error
/// triad alongside [LoadingPanel] / [ErrorState].
///
/// With a [tone] it is the end of something, not the lack of it: the last
/// step of a setup, an inbox dealt with.
class EmptyState extends StatelessWidget {
  /// The glyph over the title. With none it is the [tone]'s own, and an
  /// inbox where there is no tone either.
  final IconData? icon;
  final String title;
  final String? message;
  final Widget? action;
  final double minHeight;

  /// What the state reports where it is more than "nothing here":
  /// [Severity.success] for a setup that is done or a queue that is clear,
  /// [Severity.warning] for a list that waits on a step. It draws the icon
  /// in the tone's text-safe colour, and picks the tone's glyph when no
  /// [icon] is given, so the colour is not alone in saying it. The title
  /// and the message keep their colours.
  ///
  /// Null, the default, is the muted icon of an empty list. A load that
  /// failed is an [ErrorState], not a danger tone.
  final Severity? tone;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.action,
    this.minHeight = 160,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final tone = this.tone;
    final style = tone == null ? null : severityStyleOf(context, tone);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? style?.icon ?? context.icons.empty,
                size: context.iconSizes.xl,
                color: style?.foreground ?? context.colors.foregroundMuted,
              ),
              const Gap(AdminSpacing.md),
              Text(
                title,
                style: context.type.bodyStrong,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const Gap(AdminSpacing.xxs),
                Text(
                  message!,
                  style: context.type.bodyMuted,
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const Gap(AdminSpacing.lg), action!],
            ],
          ),
        ),
      ),
    );
  }
}
