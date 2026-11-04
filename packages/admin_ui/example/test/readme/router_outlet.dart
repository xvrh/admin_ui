// The router_outlet sample under "Routing" in admin_ui's README.md,
// verbatim from the imports down. It lives in the example, which depends on
// flutterware; admin_ui does not. docs_barrels_readme_test.dart fails when
// the two differ, and router_outlet_recipe_test.dart runs it.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutterware/router_outlet.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const MyAdmin());

class MyAdmin extends StatelessWidget {
  const MyAdmin({super.key});

  // The root reads and writes the browser's URL; outlets below match it.
  @override
  Widget build(BuildContext context) => RouterOutlet.root(
    child: MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      builder: (context, child) => ToastScope(child: child!),
      home: const AdminScope(child: Frame()),
    ),
  );
}

/// The one frame: its body is the outlet, which follows the URL.
class Frame extends StatelessWidget {
  const Frame({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Shell(
      sidebar: Sidebar(
        entries: [
          NavItem(
            'Home',
            icon: Icons.home_outlined,
            selected: router.isSelected('home'),
            onTap: () => context.go('home'),
          ),
          NavItem(
            'Orders',
            icon: Icons.receipt_long_outlined,
            // Lit on /orders/42 too.
            selected: router.isSelected('orders'),
            onTap: () => context.go('orders'),
          ),
        ],
      ),
      topBar: const TopBar(title: 'My admin'),
      child: RouterOutlet({
        'home': (_) => const PageScaffold(title: 'Home', body: SizedBox()),
        'orders': (_) => const OrdersPage(),
      }, onNotFound: (_) => 'home'),
    );
  }
}

/// The orders and one order: an outlet of its own, matching what follows
/// /orders in the URL.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) => RouterOutlet({
    '': (_) => PageScaffold(
      title: 'Orders',
      body: Builder(
        // Relative to this outlet: /orders/42.
        builder: (context) =>
            TextLink('Order 42', onPressed: () => go(context, '42')),
      ),
    ),
    ':number': (path) =>
        PageScaffold(title: 'Order ${path['number']}', body: const SizedBox()),
  });
}

/// Opens [route] once the page's leave guards let it go. A sidebar item asks
/// them before its `onTap`; every other link in the app comes through here.
Future<void> go(BuildContext context, String route) async {
  if (!await LeaveGuardScope.confirmLeave(context)) return;
  if (context.mounted) context.go(route);
}
