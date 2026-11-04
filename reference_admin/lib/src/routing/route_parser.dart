import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'routes.dart';

/// URL ↔ [AppRoute], both ways: a deep link lands on its page, and the page
/// writes its URL back.
class AppRouteParser extends RouteInformationParser<AppRoute> {
  const AppRouteParser();

  @override
  Future<AppRoute> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture(parse(routeInformation.uri));

  @override
  RouteInformation restoreRouteInformation(AppRoute configuration) =>
      RouteInformation(uri: configuration.uri);

  /// The route [uri] names, or [NotFound].
  static AppRoute parse(Uri uri) {
    final segments = [
      for (final s in uri.pathSegments)
        if (s.isNotEmpty) s,
    ];
    final query = uri.queryParameters;
    final notFound = NotFound(uri.toString());
    return switch (segments) {
      [] => const Dashboard(),
      ['sign-in'] => SignIn(
        next: switch (query['next']) {
          final next? when next.isNotEmpty => switch (parse(Uri.parse(next))) {
            SignIn() || SetPassword() || NotFound() => null,
            final route => route,
          },
          _ => null,
        },
      ),
      ['set-password'] => switch (query['token']) {
        final token? when token.isNotEmpty => SetPassword(token),
        _ => notFound,
      },
      ['setup'] => const Setup(),
      ['orders'] => Orders(
        view: query['view'] == 'board' ? OrdersView.board : OrdersView.list,
        savedView: query['saved'],
      ),
      ['orders', final number] => switch (int.tryParse(number)) {
        final n? => OrderDetail(n),
        null => notFound,
      },
      ['customers'] => Customers(selected: query['selected']),
      ['products'] => Products(savedView: query['saved']),
      ['products', 'new'] => const NewProduct(),
      ['products', final id] => ProductDetail(
        id,
        tab: query['tab'] == 'history'
            ? ProductTab.history
            : ProductTab.details,
      ),
      ['media'] => const Media(),
      ['team'] => const Team(),
      ['settings'] => const SettingsAppearance(),
      ['settings', 'appearance'] => const SettingsAppearance(),
      ['settings', 'profile'] => const SettingsProfile(),
      ['settings', 'shop'] => const SettingsShop(),
      _ => notFound,
    };
  }
}
