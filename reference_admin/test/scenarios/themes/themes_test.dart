import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart' show Check, Tip;
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/appearance/themes.dart';
import 'package:reference_admin/src/keys/catalogue_keys.dart';
import 'package:reference_admin/src/keys/orders_keys.dart';
import 'package:reference_admin/src/keys/settings_keys.dart';

import '../../support/harness.dart';

// The theme gallery: the same five screens in every theme, light then dark,
// reached through the app itself: the pages, the menus, and the top bar's
// mode toggle. Then brand accents laid over two themes from the appearance
// page.

void main() {
  scenario('Iris', (s) => themeTour(s, 'Iris'));
  scenario('Material', (s) => themeTour(s, 'Material'));
  scenario('shadcn', (s) => themeTour(s, 'shadcn'));
  scenario('Ant', (s) => themeTour(s, 'Ant'));
  scenario('Fluent', (s) => themeTour(s, 'Fluent'));
  scenario('Carbon', (s) => themeTour(s, 'Carbon'));
  scenario(
    'Greenhouse (a theme of our own)',
    (s) => themeTour(s, 'Greenhouse'),
  );

  scenario('Brand accents', (s) async {
    final shop = await openShop(
      s,
      at: const SettingsAppearance(),
      mode: ThemeMode.light,
      latency: Latency.none,
    );
    final teal = adminAccents['Teal']!;
    final crimson = adminAccents['Crimson']!;

    await s.tap(
      _swatch(s.kit.inputs.accentName('Teal')),
      shot: const Shot('Brand accents · Iris teal · appearance'),
    );
    expect(_tokens(s), appTokens(irisTheme, accent: teal));
    await navTo(
      s,
      Nav.orders,
      shot: const Shot('Brand accents · Iris teal · orders'),
    );
    expect(_tokens(s), appTokens(irisTheme, accent: teal));

    await navTo(s, Nav.settings);
    await s.tap(_theme('Carbon'));
    await s.tap(_segment(s.kit.inputs.modeDark));
    await s.tap(_swatch(s.kit.inputs.accentName('Crimson')));
    final carbonCrimson = appTokens(carbonTheme, dark: true, accent: crimson);
    expect(_tokens(s), carbonCrimson);

    await navTo(
      s,
      Nav.orders,
      shot: const Shot('Brand accents · Carbon crimson dark · orders'),
    );
    await _openFern(
      s,
      shop,
      shot: const Shot('Brand accents · Carbon crimson dark · product'),
    );
    expect(shop.route, const ProductDetail('p-12'));
    expect(_tokens(s), carbonCrimson);
    expect(
      shop.db.prefs[shop.api.currentStaff!.id]?.accent,
      crimson.toARGB32(),
    );
  });
}

/// The gallery's five screens in [themeName], light, then again in dark
/// after the top bar's mode toggle, checking at each that the app is drawn
/// with that theme's own tokens.
Future<void> themeTour(ScenarioTester s, String themeName) async {
  final theme = themeNamed(themeName);
  final shop = await openShop(
    s,
    theme: themeName,
    mode: ThemeMode.light,
    latency: Latency.none,
    shot: Shot('$themeName · light · dashboard'),
  );
  expect(_tokens(s), appTokens(theme));
  await _walk(s, shop, themeName, 'light');

  await s.tap(ShellKeys.modeToggle);
  expect(shop.services.appearance.mode, ThemeMode.dark);
  await navTo(s, Nav.dashboard, shot: Shot('$themeName · dark · dashboard'));
  expect(_tokens(s), appTokens(theme, dark: true));
  await _walk(s, shop, themeName, 'dark');
}

/// Orders with two rows selected, a product with an edit and an error, an
/// order's status submenu, and its refund dialog.
Future<void> _walk(
  ScenarioTester s,
  Shop shop,
  String themeName,
  String mode,
) async {
  await navTo(s, Nav.orders);
  final checks = find.descendant(
    of: find.byKey(OrdersKeys.list),
    matching: find.byType(Check),
  );
  await s.tap(checks.at(1));
  await s.tap(checks.at(2), shot: Shot('$themeName · $mode · orders'));

  await _openFern(s, shop);
  await s.enterText(
    find
        .descendant(
          of: find.byKey(CatalogueKeys.name),
          matching: find.byType(EditableText),
        )
        .first,
    '',
    shot: Shot('$themeName · $mode · product'),
  );
  expect(shop.route, const ProductDetail('p-12'));

  // Leaving the edited product asks first; the gallery discards the edit.
  final order = shop.db.orders.firstWhere((o) => o.number == 1042);
  await _openFromPalette(
    s,
    order.label,
    find.text(s.strings.shell.orderHit(order.label, order.customerName)),
  );
  await s.tap(find.text(s.kit.shell.discard).last);
  expect(shop.route, const OrderDetail(1042));
  await s.tap(OrdersKeys.more);
  await s.tap(
    find.text(s.strings.orders.changeStatus),
    shot: Shot('$themeName · $mode · menu'),
  );
  await s.tap(
    find.text(s.strings.orders.refund).last,
    shot: Shot('$themeName · $mode · dialog'),
  );
  expect(find.byKey(OrdersKeys.refundDialog), findsOneWidget);
  await s.back();
  expect(find.byKey(OrdersKeys.refundDialog), findsNothing);
  expect(shop.calls.countOf(Endpoint.refund), 0);
}

/// Opens the Boston fern's editor through the command palette, which finds
/// it whatever view the product list opens on.
Future<void> _openFern(ScenarioTester s, Shop shop, {Shot? shot}) {
  final fern = shop.db.productById('p-12');
  return _openFromPalette(
    s,
    fern.sku,
    find.text(inLanguage(fern.name, s.language)),
    shot: shot,
  );
}

/// Searches the command palette for [query] and opens [hit]. The search is
/// debounced on a timer, which draws no frame, so it settles on the hit.
Future<void> _openFromPalette(
  ScenarioTester s,
  String query,
  Finder hit, {
  Shot? shot,
}) async {
  await s.tap(ShellKeys.search);
  await searchIn(s, find.byType(EditableText).last, query, until: hit);
  await s.tap(hit, shot: shot);
}

Finder _theme(String name) => find.descendant(
  of: find.byKey(SettingsKeys.theme),
  matching: find.text(name),
);

Finder _segment(String label) => find.descendant(
  of: find.byKey(SettingsKeys.theme),
  matching: find.text(label),
);

// FRICTION(F-502): a swatch has no key and shows no text; only its Tip names
// it.
Finder _swatch(String label) => find.descendant(
  of: find.byKey(SettingsKeys.theme),
  matching: find.byWidgetPredicate((w) => w is Tip && w.message == label),
);

AdminTokens _tokens(ScenarioTester s) =>
    s.tester.element(find.byKey(ShellKeys.frame)).adminTokens;
