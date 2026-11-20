import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'button.dart';

/// The centred placeholder a page or a panel shows where the signed-in user
/// may not go: a lock, a [title], a [message] saying who can change that,
/// and a way back when [onBack] is given. Nothing failed and nothing is
/// empty, so it is neither an [ErrorState] nor an [EmptyState]: its icon is
/// muted, and it offers no retry.
///
/// The words are the kit's, in the app's language, until the app gives its
/// own: a role's name in the title, where the way back leads in
/// [backLabel].
class ForbiddenState extends StatelessWidget {
  /// The headline; the localized "You don't have access to this" when null.
  final String? title;

  /// The line under it; the localized "Ask an administrator if you need
  /// it." when null. An empty text shows none.
  final String? message;

  /// Leaves for somewhere the user may be: the page before, or the app's
  /// home. With none, no button shows.
  final VoidCallback? onBack;

  /// The button's label; the localized "Go back" when null.
  final String? backLabel;

  /// The key of the button, to find it by in a test.
  final Key? backKey;
  final IconData icon;
  final double minHeight;

  const ForbiddenState({
    super.key,
    this.title,
    this.message,
    this.onBack,
    this.backLabel,
    this.backKey,
    this.icon = Icons.lock_outline_rounded,
    this.minHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n;
    final message = this.message ?? l10n.notAllowedAskAdministrator;
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
                title ?? l10n.notAllowed,
                style: context.type.bodyStrong,
                textAlign: TextAlign.center,
              ),
              if (message.isNotEmpty) ...[
                const Gap(AdminSpacing.xxs),
                Text(
                  message,
                  style: context.type.bodyMuted,
                  textAlign: TextAlign.center,
                ),
              ],
              if (onBack != null) ...[
                const Gap(AdminSpacing.lg),
                Button(
                  backLabel ?? l10n.goBack,
                  key: backKey,
                  onPressed: onBack,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
