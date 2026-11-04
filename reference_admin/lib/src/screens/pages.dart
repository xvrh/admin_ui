import 'package:flutter/widgets.dart';

import '../routing/routes.dart';
import 'access/access_pages.dart';
import 'customers/customers_pages.dart';
import 'dashboard/dashboard_pages.dart';
import 'media/media_pages.dart';
import 'orders/orders_pages.dart';
import 'products/products_pages.dart';
import 'settings/appearance/appearance_pages.dart';
import 'settings/profile/profile_pages.dart';
import 'setup/setup_pages.dart';
import 'shop_settings/shop_settings_pages.dart';
import 'stubs.dart';
import 'team/team_pages.dart';

/// The frame's body for [route]: each area's `*_pages.dart` builds its own.
///
/// Keyed by path, so opening another order or product starts its page
/// afresh, while a query change (a tab, a saved view) keeps it.
Widget buildPage(BuildContext context, AppRoute route) => KeyedSubtree(
  key: ValueKey(route.uri.path),
  child: switch (route) {
    Dashboard() => dashboardPage(context, route),
    Setup() => setupPage(context, route),
    Orders() => ordersPage(context, route),
    OrderDetail() => orderDetailPage(context, route),
    Customers() => customersPage(context, route),
    Products() => productsPage(context, route),
    NewProduct() => newProductPage(context, route),
    ProductDetail() => productDetailPage(context, route),
    Media() => mediaPage(context, route),
    Team() => teamPage(context, route),
    SettingsAppearance() => appearancePage(context, route),
    SettingsProfile() => profilePage(context, route),
    SettingsShop() => shopSettingsPage(context, route),
    Forbidden() => ForbiddenPage(route),
    NotFound() => NotFoundPage(route),
    SignIn() || SetPassword() => buildSignedOutPage(context, route),
  },
);

/// The page of the signed-out app for [route].
Widget buildSignedOutPage(BuildContext context, AppRoute route) =>
    switch (route) {
      SetPassword() => setPasswordPage(context, route),
      SignIn() => signInPage(context, route),
      _ => signInPage(context, const SignIn()),
    };
