// The router of its own under "Routing" in README.md, verbatim from the
// imports down.
// docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const MyAdmin());

/// The sidebar's destinations.
enum Section { home, orders }

/// Every page: its URL, and the destination the sidebar lights for it.
sealed class AppRoute {
  const AppRoute();
  Uri get uri;
  Section get section;
}

class HomeRoute extends AppRoute {
  const HomeRoute();
  @override
  Uri get uri => Uri(path: '/');
  @override
  Section get section => Section.home;
}

class OrderRoute extends AppRoute {
  final int? number;
  const OrderRoute([this.number]);
  @override
  Uri get uri => Uri(path: number == null ? '/orders' : '/orders/$number');
  @override
  Section get section => Section.orders;
}

class RouteParser extends RouteInformationParser<AppRoute> {
  @override
  Future<AppRoute> parseRouteInformation(RouteInformation info) async =>
      switch (info.uri.pathSegments) {
        ['orders'] => const OrderRoute(),
        ['orders', final n] => OrderRoute(int.tryParse(n)),
        _ => const HomeRoute(),
      };

  @override
  RouteInformation restoreRouteInformation(AppRoute route) =>
      RouteInformation(uri: route.uri);
}

class AppRouter extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoute> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  /// On the frame, below its AdminScope: where leaving is asked from.
  final _frame = GlobalKey();

  AppRoute _route = const HomeRoute();

  @override
  AppRoute get currentConfiguration => _route;

  /// Opens [route] once the page's leave guards let it go. A sidebar item
  /// has asked them itself, and passes [asked].
  Future<void> go(AppRoute route, {bool asked = false}) async {
    final frame = _frame.currentContext;
    if (!asked && frame != null && !await LeaveGuardScope.confirmLeave(frame)) {
      // Stayed: puts the browser's URL back on the page kept.
      notifyListeners();
      return;
    }
    _route = route;
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) => go(configuration);

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    // One page: the frame stays, and its body follows the route.
    pages: [
      MaterialPage<void>(
        child: AdminScope(
          child: Frame(key: _frame, route: _route, router: this),
        ),
      ),
    ],
    onDidRemovePage: (_) {},
  );
}

class Frame extends StatelessWidget {
  final AppRoute route;
  final AppRouter router;

  const Frame({super.key, required this.route, required this.router});

  @override
  Widget build(BuildContext context) {
    return Shell(
      sidebar: Sidebar(
        selected: route.section,
        entries: [
          NavItem(
            'Home',
            icon: Icons.home_outlined,
            value: Section.home,
            onTap: () => router.go(const HomeRoute(), asked: true),
          ),
          NavItem(
            'Orders',
            icon: Icons.receipt_long_outlined,
            value: Section.orders,
            onTap: () => router.go(const OrderRoute(), asked: true),
          ),
        ],
      ),
      topBar: const TopBar(title: 'My admin'),
      child: switch (route) {
        HomeRoute() => const PageScaffold(title: 'Home', body: SizedBox()),
        OrderRoute(:final number) => PageScaffold(
          title: number == null ? 'Orders' : 'Order $number',
          body: const SizedBox(),
        ),
      },
    );
  }
}

class MyAdmin extends StatefulWidget {
  const MyAdmin({super.key});

  @override
  State<MyAdmin> createState() => _MyAdminState();
}

class _MyAdminState extends State<MyAdmin> {
  final _router = AppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    theme: buildAppTheme(irisTheme.tokens),
    localizationsDelegates: AdminLocalizations.localizationsDelegates,
    supportedLocales: AdminLocalizations.supportedLocales,
    builder: (context, child) => ToastScope(child: child!),
    routerDelegate: _router,
    routeInformationParser: RouteParser(),
  );
}
