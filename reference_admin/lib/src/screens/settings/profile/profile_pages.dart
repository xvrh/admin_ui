import 'package:admin_ui/auth.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart';

import '../../../api/shop_api.dart';
import '../../../keys/settings_keys.dart';
import '../../../l10n/money.dart';
import '../../../l10n/ref_strings.dart';
import '../../../routing/routes.dart';
import '../../../services.dart';
import '../../../widgets/status_meta.dart';
import '../appearance/settings_tabs.dart';

Widget profilePage(BuildContext context, SettingsProfile route) =>
    const ProfileScreen(key: SettingsKeys.profilePage);

/// The signed-in staff member's account, read-only, and their password.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _submitting = false;
  String? _error;

  /// Bumped after a change, so the form starts empty again.
  int _generation = 0;

  Future<void> _change(String current, String next) async {
    final strings = context.strings;
    final toasts = ToastScope.maybeOf(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.api.changePassword(current, next);
      if (!mounted) return;
      setState(() => _generation++);
      toasts?.show(
        Toast(
          strings.settings.passwordChangedDetail,
          title: strings.settings.passwordChanged,
          severity: Severity.success,
        ),
      );
    } on ValidationError catch (error) {
      if (!mounted) return;
      // FRICTION(F-504): ChangePasswordForm shows a server error only as an
      // alert over the form, not under the field it concerns.
      setState(
        () => _error = switch (error.fields) {
          {'current': _} => strings.settings.wrongCurrentPassword,
          {'next': _} => strings.settings.passwordTooWeak,
          _ => strings.shell.error(error),
        },
      );
    } on ShopError catch (error) {
      if (mounted) setState(() => _error = strings.shell.error(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.services.session.user;
    if (user == null) return const SizedBox.shrink();
    return SettingsScaffold(
      section: SettingsSection.profile,
      subtitle: context.strings.settings.profileSubtitle,
      body: ProfileView(
        user: user,
        // FRICTION(F-506): the form keeps what was typed after a successful
        // change; a new key is the only way to empty it.
        password: ChangePasswordForm(
          key: ValueKey(_generation),
          onSubmit: _change,
          submitting: _submitting,
          errorText: _error,
        ),
      ),
    );
  }
}

/// The profile page's content: the account card beside the password card.
class ProfileView extends StatelessWidget {
  final StaffMember user;

  /// The password form, in its card.
  final Widget password;

  const ProfileView({super.key, required this.user, required this.password});

  static const twoColumnsMin = 820.0;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.settings;
    final account = SettingsCard(
      key: SettingsKeys.account,
      title: strings.accountTitle,
      description: strings.accountDescription(
        canManageTeam: context.services.session.can(Permission.manageTeam),
      ),
      children: [_AccountSummary(user: user)],
    );
    final passwordCard = SettingsCard(
      key: SettingsKeys.changePassword,
      title: strings.passwordTitle,
      description: strings.passwordDescription,
      children: [password],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < twoColumnsMin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [account, const Gap(AdminSpacing.xl), passwordCard],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 9, child: account),
            const Gap(AdminSpacing.xl),
            Expanded(flex: 11, child: passwordCard),
          ],
        );
      },
    );
  }
}

class _AccountSummary extends StatelessWidget {
  final StaffMember user;
  const _AccountSummary({required this.user});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.settings;
    final shell = context.strings.shell;
    final lastActive = user.lastActiveAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Avatar(name: user.name, size: 48),
            const Gap(AdminSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: context.type.heading,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(AdminSpacing.xxs),
                  Text(
                    bidiIsolate(user.email),
                    style: context.type.caption.copyWith(
                      color: context.colors.foregroundMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.lg),
        DescriptionList(
          items: [
            DescriptionItem(strings.roleLabel, value: shell.role(user.role)),
            DescriptionItem(
              strings.statusLabel,
              child: StatusPill(context.staffStatusMeta(user.status)),
            ),
            DescriptionItem(
              strings.lastActiveLabel,
              value: lastActive == null
                  ? null
                  : _lastActive(context, lastActive),
            ),
          ],
        ),
      ],
    );
  }

  /// A recent time as a span ago, an older one as its date.
  static String _lastActive(BuildContext context, DateTime at) {
    final now = clock.now();
    if (now.difference(at).inDays >= 7) return formatDate(context, at);
    return context.strings.settings.activeAgo(formatAgo(context, at, now));
  }
}
