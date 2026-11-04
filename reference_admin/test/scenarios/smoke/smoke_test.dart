import 'package:admin_ui/widgets.dart' show CommandPalette;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterware/flutter_test.dart';
import 'package:reference_admin/src/fake/seed_accounts.dart';
import 'package:reference_admin/src/keys/orders_keys.dart';

import '../../support/harness.dart';

// The app end to end, as the core ships it: sign in through the page, open
// every navigation item the way a person would at this width, then every
// other page, then sign out. Whatever each work package builds, this walk
// must stay green.

void main() {
  scenario('Signing in and opening every page', (s) async {
    final shop = await openShop(
      s,
      as: null,
      shot: const Shot('Smoke · sign in'),
    );
    expect(shop.route, isA<SignIn>());

    final fields = find.byType(EditableText);
    await s.enterText(fields.at(0), demoAccounts.first.$1);
    await s.enterText(fields.at(1), demoPassword);
    await s.tap(
      find.text(s.kit.shell.signIn),
      shot: const Shot('Smoke · dashboard', tags: ['smoke']),
    );
    expect(shop.route, isA<Dashboard>());
    expect(shop.calls.paths.take(2), ['auth.signIn', 'prefs.load']);
    expect(shop.calls.countOf(Endpoint.navBadges), 1);
    expect(shop.calls.countOf(Endpoint.notifications), 1);

    for (final nav in Nav.values.skip(1)) {
      await navTo(s, nav, shot: Shot('Smoke · ${nav.name}'));
      expect(shop.route.nav, nav);
    }

    const direct = <(String, AppRoute)>[
      ('setup', Setup()),
      ('order board', Orders(view: OrdersView.board)),
      ('order', OrderDetail(1042)),
      ('new product', NewProduct()),
      ('product', ProductDetail('p-12')),
      ('product history', ProductDetail('p-12', tab: ProductTab.history)),
      ('profile', SettingsProfile()),
      ('shop settings', SettingsShop()),
      ('not found', NotFound('/nowhere')),
    ];
    for (final (name, route) in direct) {
      await s.act('Smoke · $name', () => shop.router.go(route));
      expect(shop.route, route);
    }

    await s.tap(ShellKeys.userMenu, shot: const Shot('Smoke · user menu'));
    await s.tap(
      find.text(s.strings.shell.signOut),
      shot: const Shot('Smoke · signed out'),
    );
    expect(shop.route, isA<SignIn>());
    expect(shop.api.currentStaff, isNull);
  });

  scenario('A viewer is turned away from the team page', (s) async {
    final shop = await openShop(
      s,
      as: Role.viewer,
      at: const Team(),
      shot: const Shot('Smoke · forbidden'),
    );
    expect(shop.route, isA<Forbidden>());
    expect(find.byKey(ShellKeys.forbidden), findsOneWidget);

    await s.tap(ShellKeys.backToDashboard);
    expect(shop.route, isA<Dashboard>());
  });

  scenario('A deep link waits for sign-in, then opens', (s) async {
    final shop = await openShop(s, as: null, at: const OrderDetail(1042));
    expect(shop.route, const SignIn(next: OrderDetail(1042)));

    // Not awaited inside the step: the shop answers in fake time, which only
    // the step's settling moves on.
    // FRICTION(T-007): awaiting it inside act hangs until the test times out. The sign-in page shows no progress bar,
    // so nothing draws while the call runs: settle on the page it opens.
    await s.act('Smoke · deep link after sign-in', () {
      shop.services.session
          .signIn(demoAccounts.first.$1, demoPassword)
          .ignore();
    }, settle: const Settle.until(OrdersKeys.orderPage));
    expect(shop.route, const OrderDetail(1042));
  });

  scenario('The palette and the shop push reach the frame', (s) async {
    final shop = await openShop(s);
    final toShip = shop.db.orders.where((o) => o.status.toShip).length;

    // The dashboard behind the palette may list the product too.
    final fern = find.descendant(
      of: find.byType(CommandPalette),
      matching: find.text(
        inLanguage(shop.db.productById('p-12').name, s.language),
      ),
    );
    await pressShortcut(s, LogicalKeyboardKey.keyK, shot: 'Smoke · palette');
    await searchIn(
      s,
      find.byType(EditableText).last,
      'PS-0012',
      until: fern,
      shot: const Shot('Smoke · palette results'),
    );
    expect(shop.calls.countOf(Endpoint.search), 1);
    await s.tap(fern);
    expect(shop.route, const ProductDetail('p-12'));

    final order = await realtime(
      s,
      'Smoke · new order toast',
      shop.api.simulate.newOrder,
      until: find.text(s.strings.shell.newOrderTitle),
    );
    expect(shop.db.orders.where((o) => o.status.toShip), hasLength(toShip + 1));
    await s.tap(find.text(s.strings.shell.view));
    expect(shop.route, OrderDetail(order.number));
  });
}
