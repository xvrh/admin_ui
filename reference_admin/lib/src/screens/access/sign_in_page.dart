import 'package:admin_ui/auth.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/access_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import 'auth_chrome.dart';

/// `/sign-in`: staff sign in with an email and a password. The router
/// swaps to the frame (or the page asked for) once the session opens.
class SignInPage extends StatefulWidget {
  final SignIn route;

  const SignInPage({super.key, required this.route});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _submitting = false;
  ShopError? _error;

  /// A demo account picked under the card: the form is built afresh with
  /// it filled in.
  String? _picked;

  Future<void> _signIn(String email, String password) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    // Read now: once the session opens, the router swaps this page out.
    final toasts = ToastScope.maybeOf(context);
    final welcome = context.strings.access.welcomeBack;
    final session = context.services.session;
    try {
      await session.signIn(email, password);
      if (session.user case final user?) {
        toasts?.show(
          Toast(welcome(user.name), icon: Icons.waving_hand_outlined),
        );
      }
    } on ShopError catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _errorText(RefStrings strings) => switch (_error) {
    null => null,
    ValidationError(:final fields)
        when fields['email'] == ValidationCodes.locked =>
      strings.access.accountLocked,
    ValidationError() => strings.access.wrongPassword,
    ForbiddenError() => strings.access.accountInactive,
    final error => strings.shell.error(error),
  };

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final picked = _picked;
    final demo = context.services.demoSignIns;
    return AuthScaffold(
      logo: const AuthMark(),
      title: strings.access.signInTitle,
      subtitle: strings.access.signInSubtitle,
      footer: demo == null
          ? null
          : DemoAccounts(
              demo: demo,
              onPick: (email) => setState(() {
                _picked = email;
                _error = null;
              }),
            ),
      child: KeyedSubtree(
        key: AccessKeys.signInForm,
        // FRICTION(F-100): a wrong password can only be said above the
        // form: SignInForm has no per-field error, so AuthFieldError has no
        // place in it.
        child: SignInForm(
          key: ValueKey(picked),
          onSignIn: _signIn,
          submitting: _submitting,
          errorText: _errorText(strings),
          initialEmail: picked ?? '',
          initialPassword: picked == null ? '' : demo?.password ?? '',
        ),
      ),
    );
  }
}
