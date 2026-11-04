import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// The centred placeholder a list, table, or panel shows when it has nothing to
/// display: a muted icon, a [title], an optional [message] and an optional
/// [action] (e.g. a "Create" button). The empty arm of the load → empty/error
/// triad alongside [LoadingPanel] / [ErrorState].
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final double minHeight;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.action,
    this.minHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: context.iconSizes.xl,
                color: context.colors.foregroundMuted,
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
