import 'package:admin_ui/collection.dart' show SavedViewsBar;
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart' show ErrorState, PopoverMenuSurface, Tip;
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/appearance/themes.dart';
import 'package:reference_admin/src/fake/seed_accounts.dart';
import 'package:reference_admin/src/keys/access_keys.dart';
import 'package:reference_admin/src/keys/settings_keys.dart';
import 'package:reference_admin/src/routing/route_parser.dart';

import '../../../support/harness.dart';

// Settings: the look and language a staff member picks, and how it follows
// them from device to device; their password; the app offline; a page that
// does not exist.

void main() {
  scenario('Appearance and language', (s) async {
    final shop = await openShop(
      s,
      at: const SettingsAppearance(),
      shot: const Shot('Appearance', tags: ['tour']),
    );
    final me = shop.api.currentStaff!;
    expect(find.byKey(SettingsKeys.theme), findsOneWidget);

    await s.tap(_theme('Carbon'));
    await s.tap(
      _segment(s.kit.inputs.modeDark),
      shot: const Shot('Appearance · Carbon dark'),
    );
    expect(_brightness(s), Brightness.dark);

    await s.tap(
      _swatch(s.kit.inputs.accentName('Teal')),
      shot: const Shot('Appearance · Teal accent'),
    );
    final teal = adminAccents['Teal']!;
    expect(
      _tokens(s),
      withArabicFallback(carbonTheme.dark!.branded(teal)),
      reason: 'the page is drawn with Carbon dark, branded teal',
    );

    await s.scrollTo(SettingsKeys.language);
    await s.tap(
      find.descendant(
        of: find.byKey(SettingsKeys.language),
        matching: find.text(s.strings.shell.languageSystem),
      ),
    );
    await s.tap(
      find.text(s.strings.shell.languageName('ar')).last,
      shot: const Shot('Appearance · Arabic'),
    );
    expect(s.language, 'ar');
    expect(_direction(s), TextDirection.rtl);

    await navTo(
      s,
      Nav.orders,
      shot: const Shot('Orders · Arabic, right to left'),
    );
    expect(shop.route, isA<Orders>());
    expect(_direction(s), TextDirection.rtl);
    expect(_tokens(s).palette, carbonTheme.dark!.branded(teal).palette);

    final saved = shop.db.prefs[me.id]!;
    expect(saved.theme, 'Carbon');
    expect(saved.mode, AppearanceMode.dark);
    expect(saved.accent, teal.toARGB32());
    expect(saved.locale, 'ar');
    expect(shop.calls.countOf(Endpoint.savePrefs), 4);
  });

  scenario('Appearance follows me', (s) async {
    final shop = await openShop(
      s,
      at: const SettingsAppearance(),
      mode: ThemeMode.light,
    );
    final owner = shop.api.currentStaff!;
    await s.tap(_segment(s.kit.inputs.modeDark));
    expect(shop.db.prefs[owner.id]?.mode, AppearanceMode.dark);

    await s.tap(ShellKeys.userMenu);
    await s.tap(
      find.text(s.strings.shell.signOut),
      shot: const Shot('Sign in · dark, after signing out'),
    );
    expect(shop.route, isA<SignIn>());
    expect(_brightness(s), Brightness.dark);

    // Someone else signs in at the same desk, and their own look comes in.
    await _signIn(s, _emailOf(Role.manager));
    expect(shop.api.currentStaff!.role, Role.manager);
    // The manager keeps the system's look, whatever the owner chose, so
    // the dark export (`--brightness=dark`) passes too.
    expect(shop.services.appearance.mode, ThemeMode.system);
    expect(_brightness(s), s.tester.platformDispatcher.platformBrightness);
    await s.tap(ShellKeys.userMenu);
    await s.tap(find.text(s.strings.shell.signOut));

    shop.calls.clear();
    await _signIn(
      s,
      owner.email,
      shot: const Shot('Dashboard · my appearance back'),
    );
    expect(shop.route, isA<Dashboard>());
    expect(shop.calls.countOf(Endpoint.loadPrefs), 1);
    expect(shop.services.appearance.mode, ThemeMode.dark);
    expect(_brightness(s), Brightness.dark);
  });

  scenario('Picking a theme from the user menu', (s) async {
    final shop = await openShop(s);
    final me = shop.api.currentStaff!;
    final strings = s.strings.shell;

    // Clicked with a mouse, frames apart: a tap chose every row even while
    // a click on one past the menu closed the menu instead (F-029).
    await click(s, ShellKeys.userMenu);
    await click(s, find.text(strings.appearance));
    await click(s, find.text(strings.theme), shot: 'User menu · themes');

    // The avatar sits in the window's end corner, so Appearance opens toward
    // the start and Theme over the menu, running past its last row. The last
    // theme lies over no other level: the row that lost its click.
    final greenhouse = find.text(greenhouseTheme.name).last;
    final at = s.tester.getCenter(greenhouse);
    expect(_menuHolding(s, strings.signOut).contains(at), isFalse);
    expect(_menuHolding(s, strings.mode).contains(at), isFalse);

    await click(
      s,
      greenhouse,
      shot: 'Dashboard · Greenhouse, from the user menu',
    );
    expect(find.text(strings.theme), findsNothing, reason: 'the menu closed');
    expect(shop.services.appearance.themeName, greenhouseTheme.name);
    expect(
      _tokens(s),
      appTokens(greenhouseTheme, dark: _brightness(s) == Brightness.dark),
    );
    expect(shop.db.prefs[me.id]!.theme, greenhouseTheme.name);
  });

  scenario('Changing my password', (s) async {
    final shop = await openShop(s, at: const SettingsProfile());
    final me = shop.api.currentStaff!;
    expect(find.byKey(SettingsKeys.account), findsOneWidget);

    final fields = find.descendant(
      of: find.byKey(SettingsKeys.changePassword),
      matching: find.byType(EditableText),
    );
    final submit = find.text(s.kit.shell.changePassword);

    await s.enterText(fields.at(0), demoPassword);
    await s.enterText(fields.at(1), 'repotting-season');
    await s.enterText(fields.at(2), 'repotting-seasons');
    await s.tap(submit, shot: const Shot('Password · new passwords differ'));
    expect(shop.calls.countOf(Endpoint.changePassword), 0);

    await s.enterText(fields.at(0), 'not-my-password');
    await s.enterText(fields.at(2), 'repotting-season');
    await s.tap(submit, shot: const Shot('Password · current is wrong'));
    expect(shop.calls.countOf(Endpoint.changePassword), 1);
    expect(find.text(s.strings.settings.wrongCurrentPassword), findsOneWidget);
    expect(shop.db.accounts[me.email], demoPassword);

    await s.enterText(fields.at(0), demoPassword);
    await s.tap(submit, shot: const Shot('Password · changed'));
    expect(shop.calls.countOf(Endpoint.changePassword), 2);
    expect(shop.db.accounts[me.email], 'repotting-season');
    expect(find.text(s.strings.settings.passwordChanged), findsOneWidget);
  });

  scenario('Working offline', (s) async {
    final shop = await openShop(s);

    await s.act(
      'Offline banner',
      shop.faults.goOffline,
      settle: const Settle.until(ShellKeys.offline),
    );
    expect(find.byKey(ShellKeys.offline), findsOneWidget);

    await navTo(s, Nav.orders, shot: const Shot('Orders · offline'));
    expect(shop.route, isA<Orders>());
    expect(_orderRows, findsNothing);
    // The banner says it once, the list offers the retry: the saved views,
    // which never loaded, show neither a bar nor an error of their own.
    expect(find.byType(SavedViewsBar), findsNothing);
    expect(find.byType(ErrorState), findsOneWidget);
    final refused = shop.calls.countOf(Endpoint.listOrders);

    // Coming back online reloads the list on a coalescing timer, which
    // draws no frame: settle on the rows.
    await realtime(
      s,
      'Orders · back online',
      shop.faults.goOnline,
      // FRICTION(T-009): `until` on `_orderRows.first` throws while no row
      // exists; the unrefined finder waits.
      until: _orderRows,
    );
    expect(find.byKey(ShellKeys.offline), findsNothing);
    expect(shop.calls.countOf(Endpoint.listOrders), refused + 1);
    expect(find.byType(SavedViewsBar), findsOneWidget);
    expect(_viewsError, findsNothing);
  });

  scenario('Page not found', (s) async {
    final route = await const AppRouteParser().parseRouteInformation(
      RouteInformation(uri: Uri.parse('/greenhouse/orchids')),
    );
    expect(route, isA<NotFound>());
    final shop = await openShop(s, at: route, shot: const Shot('Not found'));
    expect(shop.route, route);
    expect(find.byKey(ShellKeys.notFound), findsOneWidget);
  });
}

/// The saved views bar's note that its views could not load.
final _viewsError = find.descendant(
  of: find.byType(SavedViewsBar),
  matching: find.byIcon(Icons.error_outline_rounded),
);

/// Any order's row, or its card on a phone.
final _orderRows = find.byWidgetPredicate((w) {
  final key = w.key;
  return key is ValueKey<String> &&
      (key.value.startsWith('orders.row.') ||
          key.value.startsWith('orders.card.'));
});

/// The surface of the open menu level holding [text].
Rect _menuHolding(ScenarioTester s, String text) => s.tester.getRect(
  find
      .ancestor(of: find.text(text), matching: find.byType(PopoverMenuSurface))
      .first,
);

/// A theme in the appearance picker. Theme names are names, the same in
/// every language.
Finder _theme(String name) => find.descendant(
  of: find.byKey(SettingsKeys.theme),
  matching: find.text(name),
);

/// The appearance picker's segment labelled [label]: a mode or a density.
Finder _segment(String label) => find.descendant(
  of: find.byKey(SettingsKeys.theme),
  matching: find.text(label),
);

/// The accent swatch named [label].
// FRICTION(F-502): a swatch has no key and shows no text; only its Tip names
// it.
Finder _swatch(String label) => find.descendant(
  of: find.byKey(SettingsKeys.theme),
  matching: find.byWidgetPredicate((w) => w is Tip && w.message == label),
);

String _emailOf(Role role) =>
    demoAccounts.firstWhere((account) => account.$2 == role.name).$1;

Future<void> _signIn(ScenarioTester s, String email, {Shot? shot}) async {
  final fields = find.descendant(
    of: find.byKey(AccessKeys.signInPage),
    matching: find.byType(EditableText),
  );
  await s.enterText(fields.at(0), email);
  await s.enterText(fields.at(1), demoPassword);
  await s.tap(find.text(s.kit.shell.signIn), shot: shot);
}

BuildContext _frame(ScenarioTester s) =>
    s.tester.element(find.byType(Navigator).first);

AdminTokens _tokens(ScenarioTester s) =>
    s.tester.element(find.byKey(ShellKeys.frame)).adminTokens;

Brightness _brightness(ScenarioTester s) =>
    Theme.of(s.tester.element(find.byType(Navigator).first)).brightness;

TextDirection _direction(ScenarioTester s) => Directionality.of(_frame(s));
