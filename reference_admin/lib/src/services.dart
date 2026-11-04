import 'package:admin_ui/widgets.dart';
import 'package:flutter/widgets.dart';

import 'api/shop_api.dart';
import 'appearance/appearance_controller.dart';
import 'fake/fake_shop_api.dart';
import 'fake/seed_accounts.dart';
import 'routing/router_delegate.dart';
import 'routing/routes.dart';
import 'session/session_controller.dart';

/// Everything the app shares across its pages, made once per app.
///
/// Provided above the Navigator (`MaterialApp.builder`), so the dialogs and
/// sheets pushed as routes reach it too.
class AppServices {
  final ShopApi api;

  /// The fake behind [api], when it is one: what dev tooling and scenarios
  /// arm faults on and read the database of.
  final FakeShopApi? fake;

  /// The accounts a sign-in page may offer to fill in, on a demo build
  /// only. Null over a real shop, whose sign-in page then shows no hint.
  final DemoSignIns? demoSignIns;

  AppServices({required this.api, this.fake, this.demoSignIns});

  /// The app over an in-memory shop seeded with [seed], optionally already
  /// signed in as the first active staff member with [signInAs].
  factory AppServices.fake({
    Latency latency = Latency.realistic,
    DemoSeed seed = DemoSeed.demo,
    Role? signInAs,
  }) {
    final fake = FakeShopApi(seed: seed, latency: latency);
    final services = AppServices(
      api: fake,
      fake: fake,
      demoSignIns: DemoSignIns(
        accounts: [
          for (final (email, role) in demoAccounts)
            (email: email, role: Role.values.byName(role)),
        ],
        password: demoPassword,
      ),
    );
    if (signInAs != null) {
      services.session.adopt(fake.adoptSession(fake.staffWithRole(signInAs)));
    }
    return services;
  }

  late final appearance = AppearanceController();
  late final session = SessionController(api, appearance);

  /// Where the forms' unsaved-changes guards register, shared by the
  /// signed-in frame's `AdminScope` and the signed-out page's, and asked by
  /// the router before a route changes.
  final leaveGuards = LeaveGuardRegistry();

  /// The commands the palette lists besides the frame's own.
  final commands = CommandRegistry();

  late final router = AppRouterDelegate(this);

  /// Detail pages visited, newest first: the palette's Recent section.
  final recent = ValueNotifier<List<AppRoute>>(const []);

  /// What the Recent section calls a detail page, by the page's path, in
  /// each language: a page names itself once it has loaded.
  final recentTitles = <String, Translated>{};

  void dispose() {
    router.dispose();
    commands.dispose();
    leaveGuards.dispose();
    session.dispose();
    appearance.dispose();
    recent.dispose();
  }
}

/// Test sign-ins a demo build lists under its sign-in card.
class DemoSignIns {
  final List<({String email, Role role})> accounts;

  /// The password every one of [accounts] takes.
  final String password;

  const DemoSignIns({required this.accounts, required this.password});
}

class AppServicesScope extends InheritedWidget {
  final AppServices services;

  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'No AppServicesScope above $context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) =>
      services != oldWidget.services;
}

extension AppServicesContext on BuildContext {
  AppServices get services => AppServicesScope.of(this);
  ShopApi get api => AppServicesScope.of(this).api;

  /// Opens [route], asking first when a form would lose unsaved edits.
  Future<bool> go(AppRoute route) => AppServicesScope.of(this).router.go(route);
}
