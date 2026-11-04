import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../frame/app_frame.dart';
import '../screens/pages.dart';
import '../services.dart';
import 'routes.dart';

/// The app's one router, the kit's routing recipe (README, "Routing"): a
/// Navigator holding a single page, the signed-out page or the frame, whose
/// body the route swaps.
///
/// One frame for every signed-in page means one `AdminScope` and one modal
/// anchor for all of them, which the phone's drawer and every dialog open
/// on. Each route names the navigation item it belongs to ([AppRoute.nav]),
/// which the frame's sidebar lights (`Sidebar(selected:)`), and every change
/// of route asks the leave guards first.
class AppRouterDelegate extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoute> {
  final AppServices _services;

  AppRouterDelegate(this._services) {
    _services.session.addListener(_onSession);
  }

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  /// On the frame, below `AdminScope`: the context leaving is asked from.
  final frameKey = GlobalKey();

  AppRoute _route = const SignIn();

  /// The page shown, after the guards: a signed-out visitor asked for
  /// `/orders` is on [SignIn], a viewer asked for `/team` on [Forbidden].
  AppRoute get route => _route;

  @override
  AppRoute get currentConfiguration => _route;

  /// Opens [route]. Asks first, through the leave guards, when a form holds
  /// unsaved edits, unless [confirm] is false because the caller (a sidebar
  /// item) already asked. Resolves false when the user chose to stay.
  Future<bool> go(AppRoute route, {bool confirm = true}) async {
    if (confirm && !await _confirmLeave()) return false;
    _show(route);
    return true;
  }

  /// Signs out, once the leave guards let the page go: a dirty form asks
  /// first, as it does for any other way out. Resolves false when the user
  /// chose to stay.
  Future<bool> signOut() async {
    if (!await _confirmLeave()) return false;
    await _services.session.signOut();
    return true;
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) async {
    if (!await _confirmLeave()) {
      // Puts the browser's URL back on the page that stayed.
      notifyListeners();
      return;
    }
    _show(configuration);
  }

  Future<bool> _confirmLeave() {
    final context = frameKey.currentContext;
    if (context == null) return Future.value(true);
    return LeaveGuardScope.confirmLeave(context);
  }

  void _show(AppRoute asked) {
    final resolved = _resolve(asked);
    if (resolved == _route) return;
    _route = resolved;
    _remember(resolved);
    notifyListeners();
  }

  /// [asked] after the auth and permission guards.
  AppRoute _resolve(AppRoute asked) {
    final session = _services.session;
    if (!session.isSignedIn) {
      if (asked.isPublic) return asked;
      return SignIn(next: asked is Dashboard ? null : asked);
    }
    if (asked case SignIn(:final next)) {
      return _resolve(next ?? const Dashboard());
    }
    if (asked is SetPassword) return const Dashboard();
    if (asked.permission case final permission? when !session.can(permission)) {
      return Forbidden(asked);
    }
    return asked;
  }

  void _onSession() {
    final session = _services.session;
    final AppRoute next;
    if (session.isSignedIn) {
      if (!_route.isPublic) return;
      next = switch (_route) {
        SignIn(:final next?) => next,
        _ => const Dashboard(),
      };
    } else {
      if (_route.isPublic) return;
      next = const SignIn();
    }
    _route = _resolve(next);
    notifyListeners();
  }

  void _remember(AppRoute route) {
    if (route is! OrderDetail && route is! ProductDetail) return;
    final recent = _services.recent;
    recent.value = [
      route,
      ...recent.value.where((r) => r.uri.path != route.uri.path),
    ].take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _services.session.isSignedIn;
    return Navigator(
      key: navigatorKey,
      pages: [
        if (signedIn)
          MaterialPage<void>(
            key: const ValueKey('frame'),
            child: AdminScope(
              commands: _services.commands,
              leaveGuards: _services.leaveGuards,
              child: AppFrame(key: frameKey, route: _route),
            ),
          )
        else
          MaterialPage<void>(
            key: const ValueKey('signed-out'),
            child: AdminScope(
              leaveGuards: _services.leaveGuards,
              child: buildSignedOutPage(context, _route),
            ),
          ),
      ],
      onDidRemovePage: (_) {},
    );
  }

  @override
  void dispose() {
    _services.session.removeListener(_onSession);
    super.dispose();
  }
}
