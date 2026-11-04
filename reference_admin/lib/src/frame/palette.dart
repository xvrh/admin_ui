import 'dart:async';

import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../api/shop_api.dart';
import '../keys/shell_keys.dart';
import '../l10n/ref_strings.dart';
import '../routing/routes.dart';
import '../services.dart';
import 'navigation.dart';

/// Opens the command palette from [context], below the frame's `AdminScope`:
/// every page, the frame's commands and the ones pages registered, the shop
/// searched for orders, products and customers, and the recent pages.
Future<void> openCommandPalette(BuildContext context) {
  final services = context.services;
  final strings = context.strings.shell;
  final language = Localizations.localeOf(context).languageCode;
  final dark = Theme.of(context).brightness == Brightness.dark;
  void open(AppRoute route) => services.router.go(route);

  List<PaletteItem> commands() => [
    for (final nav in Nav.values)
      if (permissionOf(nav) case final p
          when p == null || services.session.can(p))
        PaletteItem(
          id: 'page.${nav.name}',
          title: navLabel(strings, nav),
          icon: navIcon(nav),
          group: strings.groupPages,
          onSelect: () => open(routeOf(nav)),
        ),
    if (services.session.can(Permission.editCatalogue))
      PaletteItem(
        id: 'command.newProduct',
        title: strings.commandNewProduct,
        icon: Icons.add_box_outlined,
        group: strings.groupCommands,
        onSelect: () => open(const NewProduct()),
      ),
    PaletteItem(
      id: 'command.mode',
      title: dark ? strings.switchToLight : strings.switchToDark,
      icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      group: strings.groupCommands,
      onSelect: () =>
          services.appearance.setMode(dark ? ThemeMode.light : ThemeMode.dark),
    ),
    PaletteItem(
      id: 'command.signOut',
      title: strings.signOut,
      icon: Icons.logout,
      group: strings.groupCommands,
      onSelect: services.router.signOut,
    ),
    ...services.commands.active(),
  ];

  List<PaletteItem> recent() => [
    for (final route in services.recent.value)
      PaletteItem(
        id: 'recent.${route.uri}',
        title: switch ((route, services.recentTitles[route.uri.path])) {
          (OrderDetail(:final number), _) => '#$number',
          (_, final title?) => inLanguage(title, language),
          (ProductDetail(:final id), _) => id,
          _ => route.uri.path,
        },
        icon: switch (route) {
          OrderDetail() => Icons.receipt_long_outlined,
          _ => Icons.local_florist_outlined,
        },
        group: strings.groupRecent,
        onSelect: () => open(route),
      ),
  ];

  List<PaletteItem> inGroup(String group) => [
    for (final item in commands())
      if (item.group == group) item,
  ];

  return showCommandPalette(
    context,
    hint: strings.searchHint,
    sources: [
      CommandSource(commands),
      // FRICTION(F-021): CommandSource lists nothing until something is
      // typed; RecentsSource, which shows only on an empty query, offers
      // the pages and commands meanwhile.
      RecentsSource(
        () => inGroup(strings.groupPages),
        title: strings.groupPages,
      ),
      RecentsSource(
        () => inGroup(strings.groupCommands),
        title: strings.groupCommands,
      ),
      _ShopSearch(services.api, strings, language, open),
      RecentsSource(recent, title: strings.groupRecent),
    ],
    groupOrder: [
      strings.groupRecent,
      strings.groupPages,
      strings.groupOrders,
      strings.groupProducts,
      strings.groupCustomers,
      strings.groupCommands,
    ],
  );
}

/// Orders, products and customers from `ShopApi.search`, asked once the
/// typing pauses.
// FRICTION(F-022): the palette asks every source on every keystroke, and
// drops only the stale answers; a remote source debounces itself.
class _ShopSearch implements SearchSource {
  final ShopApi _api;
  final ShellStrings _strings;
  final String _language;
  final void Function(AppRoute route) _open;

  _ShopSearch(this._api, this._strings, this._language, this._open);

  static const debounce = Duration(milliseconds: 200);
  var _latest = '';

  @override
  Future<List<PaletteSection>> search(String query) async {
    final q = query.trim();
    _latest = q;
    if (q.isEmpty) return const [];
    await Future<void>.delayed(debounce);
    if (q != _latest) return const [];
    final SearchHits hits;
    try {
      hits = await _api.search(q);
    } on ShopError {
      return const [];
    }
    // The shop matched on more than the title (a SKU, an email), so a hit
    // the fuzzy matcher cannot place is kept, unhighlighted.
    ScoredItem scored(PaletteItem item) {
      final match = fuzzyMatch(q, item.title);
      return ScoredItem(item, match?.matched ?? const [], match?.score ?? 0);
    }

    return [
      if (hits.orders.isNotEmpty)
        PaletteSection(_strings.groupOrders, [
          for (final o in hits.orders)
            scored(
              PaletteItem(
                id: 'order.${o.number}',
                title: _strings.orderHit(o.label, o.customerName),
                subtitle: _strings.orderStatus(o.status),
                icon: Icons.receipt_long_outlined,
                group: _strings.groupOrders,
                onSelect: () => _open(OrderDetail(o.number)),
              ),
            ),
        ]),
      if (hits.products.isNotEmpty)
        PaletteSection(_strings.groupProducts, [
          for (final p in hits.products)
            scored(
              PaletteItem(
                id: 'product.${p.id}',
                title: inLanguage(p.name, _language),
                subtitle: p.sku,
                icon: Icons.local_florist_outlined,
                group: _strings.groupProducts,
                onSelect: () => _open(ProductDetail(p.id)),
              ),
            ),
        ]),
      if (hits.customers.isNotEmpty)
        PaletteSection(_strings.groupCustomers, [
          for (final c in hits.customers)
            scored(
              PaletteItem(
                id: 'customer.${c.id}',
                title: c.name,
                subtitle: c.email,
                icon: Icons.person_outline,
                group: _strings.groupCustomers,
                onSelect: () => _open(Customers(selected: c.id)),
              ),
            ),
        ]),
    ];
  }
}
