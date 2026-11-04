import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../keys/access_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';

/// The shop's mark above every signed-out card: a leaf on the primary's
/// soft tint, so it follows the theme and the brand accent.
class AuthMark extends StatelessWidget {
  const AuthMark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primarySubtle,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
      ),
      child: Icon(
        Icons.yard_outlined,
        color: colors.primaryText,
        size: context.iconSizes.xl,
      ),
    );
  }
}

/// Under the sign-in card on a demo build: its test accounts, one per role.
/// Picking one fills the form with it.
class DemoAccounts extends StatelessWidget {
  final DemoSignIns demo;
  final ValueChanged<String> onPick;

  const DemoAccounts({super.key, required this.demo, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.colors;
    return Column(
      key: AccessKeys.demoAccounts,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.access.demoAccountsTitle,
          style: context.type.sectionLabel.copyWith(
            color: colors.foregroundMuted,
          ),
        ),
        const Gap(AdminSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AdminSpacing.lg,
          runSpacing: AdminSpacing.xs,
          children: [
            for (final (:email, :role) in demo.accounts)
              TextLink(
                '${strings.shell.role(role)} · ${bidiIsolate(email)}',
                onPressed: () => onPick(email),
              ),
          ],
        ),
        const Gap(AdminSpacing.xs),
        Text(
          strings.access.demoAccountsPassword(bidiIsolate(demo.password)),
          style: context.type.caption.copyWith(color: colors.foregroundMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
