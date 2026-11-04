import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'button.dart';

/// The centred placeholder a list, table, or panel shows when its load failed:
/// a danger icon, a [title], an optional [message] (the error detail) and a
/// Retry button when [onRetry] is given. The error arm of the load →
/// empty/error triad alongside [LoadingPanel] / [EmptyState].
///
/// This is the full-area version; for an inline banner use [Alert].
class ErrorState extends StatelessWidget {
  /// The headline; the localized "Something went wrong" when null.
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  /// The retry button's label; the localized "Retry" when null.
  final String? retryLabel;
  final IconData icon;
  final double minHeight;

  const ErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.error_outline_rounded,
    this.minHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n;
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
                color: context.colors.danger,
              ),
              const Gap(AdminSpacing.md),
              Text(
                title ?? l10n.somethingWentWrong,
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
              if (onRetry != null) ...[
                const Gap(AdminSpacing.lg),
                Button(
                  retryLabel ?? l10n.retry,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
