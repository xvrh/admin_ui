import 'package:admin_ui/auth.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/access_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import 'auth_chrome.dart';

/// `/set-password?token=`: an invited teammate chooses a first password,
/// which accepts the invitation and signs them in.
class SetPasswordPage extends StatefulWidget {
  final SetPassword route;

  const SetPasswordPage({super.key, required this.route});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  Invite? _invite;

  /// Why the invitation cannot be used: expired, unknown, or the shop could
  /// not be reached.
  ShopError? _problem;
  bool _submitting = false;
  ShopError? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _problem = null);
    try {
      final invite = await context.api.inviteInfo(widget.route.token);
      if (mounted) setState(() => _invite = invite);
    } on ShopError catch (error) {
      if (mounted) setState(() => _problem = error);
    }
  }

  Future<void> _submit(String password) async {
    final invite = _invite!;
    final strings = context.strings.access;
    // Taken now: the page is gone once the session opens.
    final toasts = ToastScope.maybeOf(context);
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await context.services.session.setPassword(invite.token, password);
      toasts?.show(
        Toast(
          strings.welcomeMessage(bidiIsolate(invite.name)),
          title: strings.welcomeTitle,
          severity: Severity.success,
        ),
      );
    } on ExpiredError catch (error) {
      if (mounted) setState(() => _problem = error);
    } on ShopError catch (error) {
      if (mounted) setState(() => _submitError = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final problem = _problem;
    final invite = _invite;
    if (problem != null) return _InviteProblem(problem, onRetry: _load);
    if (invite == null) {
      return AuthScaffold(
        logo: const AuthMark(),
        title: strings.access.checkingInvite,
        child: const Center(child: Spinner()),
      );
    }
    final error = switch (_submitError) {
      null => null,
      ValidationError() => strings.access.passwordTooWeak,
      final error => strings.shell.error(error),
    };
    return AuthScaffold(
      logo: const AuthMark(),
      title: strings.access.inviteWelcome(invite.name),
      subtitle: strings.access.inviteSubtitle(
        bidiIsolate(invite.invitedBy),
        strings.shell.role(invite.role),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Account(invite.email),
          const Gap(AdminSpacing.xl),
          SetPasswordForm(
            key: AccessKeys.setPasswordForm,
            onSubmit: _submit,
            submitting: _submitting,
            errorText: error,
            submitLabel: strings.access.joinShop,
          ),
        ],
      ),
    );
  }
}

/// Whose account the password is for: the invited address, not editable.
class _Account extends StatelessWidget {
  final String email;
  const _Account(this.email);

  @override
  Widget build(BuildContext context) => InputField(
    value: email,
    readOnly: true,
    icon: Icons.mail_outline_rounded,
    // An address reads left to right in every language.
    keyboardType: TextInputType.emailAddress,
  );
}

/// An invitation that cannot be accepted, and the way back.
class _InviteProblem extends StatelessWidget {
  final ShopError problem;
  final VoidCallback onRetry;

  const _InviteProblem(this.problem, {required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final back = Button(
      strings.access.backToSignIn,
      key: AccessKeys.backToSignIn,
      icon: Icons.arrow_back_rounded,
      onPressed: () => context.go(const SignIn()),
    );
    return AuthScaffold(
      logo: const AuthMark(),
      title: strings.shell.appName,
      child: switch (problem) {
        ExpiredError() => EmptyState(
          key: AccessKeys.inviteProblem,
          icon: Icons.hourglass_bottom_rounded,
          title: strings.access.inviteExpiredTitle,
          message: strings.access.inviteExpiredMessage,
          action: back,
        ),
        NotFoundError() => EmptyState(
          key: AccessKeys.inviteProblem,
          icon: Icons.link_off_rounded,
          title: strings.access.inviteInvalidTitle,
          message: strings.access.inviteInvalidMessage,
          action: back,
        ),
        final error => ErrorState(
          key: AccessKeys.inviteProblem,
          message: strings.shell.error(error),
          onRetry: onRetry,
        ),
      },
    );
  }
}
