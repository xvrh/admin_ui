import '../api/shop_api.dart';
import '../keys/shell_keys.dart';

/// Every page of the app, typed. A route knows its URL, the navigation item
/// it lights, and the permission it needs; `AppRouteParser` reads one back
/// from a URL.
sealed class AppRoute {
  const AppRoute();

  /// The URL shown in the browser and parsed back on a deep link.
  Uri get uri;

  /// The sidebar item this route belongs to.
  Nav? get nav => null;

  /// What the signed-in role needs to open it, beyond being signed in.
  Permission? get permission => null;

  /// Whether it is a page of the signed-out app.
  bool get isPublic => false;

  static Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final params = {
      for (final e in query.entries)
        if (e.value != null) e.key: e.value!,
    };
    return Uri(path: path, queryParameters: params.isEmpty ? null : params);
  }

  @override
  bool operator ==(Object other) =>
      other is AppRoute && other.runtimeType == runtimeType && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => '$runtimeType($uri)';
}

class SignIn extends AppRoute {
  /// Where to go once signed in.
  final AppRoute? next;
  const SignIn({this.next});
  @override
  Uri get uri => AppRoute._uri('/sign-in', {'next': next?.uri.toString()});
  @override
  bool get isPublic => true;
}

class SetPassword extends AppRoute {
  final String token;
  const SetPassword(this.token);
  @override
  Uri get uri => AppRoute._uri('/set-password', {'token': token});
  @override
  bool get isPublic => true;
}

class Dashboard extends AppRoute {
  const Dashboard();
  @override
  Uri get uri => AppRoute._uri('/');
  @override
  Nav get nav => Nav.dashboard;
}

class Setup extends AppRoute {
  const Setup();
  @override
  Uri get uri => AppRoute._uri('/setup');
  @override
  Nav get nav => Nav.dashboard;
  @override
  Permission get permission => Permission.manageShop;
}

enum OrdersView { list, board }

class Orders extends AppRoute {
  final OrdersView view;

  /// A saved view's id.
  final String? savedView;
  const Orders({this.view = OrdersView.list, this.savedView});
  @override
  Uri get uri => AppRoute._uri('/orders', {
    'view': view == OrdersView.board ? 'board' : null,
    'saved': savedView,
  });
  @override
  Nav get nav => Nav.orders;
}

class OrderDetail extends AppRoute {
  final int number;
  const OrderDetail(this.number);
  @override
  Uri get uri => AppRoute._uri('/orders/$number');
  @override
  Nav get nav => Nav.orders;
}

class Customers extends AppRoute {
  /// The customer whose quick view is open.
  final String? selected;
  const Customers({this.selected});
  @override
  Uri get uri => AppRoute._uri('/customers', {'selected': selected});
  @override
  Nav get nav => Nav.customers;
}

class Products extends AppRoute {
  final String? savedView;
  const Products({this.savedView});
  @override
  Uri get uri => AppRoute._uri('/products', {'saved': savedView});
  @override
  Nav get nav => Nav.products;
}

class NewProduct extends AppRoute {
  const NewProduct();
  @override
  Uri get uri => AppRoute._uri('/products/new');
  @override
  Nav get nav => Nav.products;
  @override
  Permission get permission => Permission.editCatalogue;
}

enum ProductTab { details, history }

class ProductDetail extends AppRoute {
  final String id;
  final ProductTab tab;
  const ProductDetail(this.id, {this.tab = ProductTab.details});
  @override
  Uri get uri => AppRoute._uri('/products/$id', {
    'tab': tab == ProductTab.history ? 'history' : null,
  });
  @override
  Nav get nav => Nav.products;
}

class Media extends AppRoute {
  const Media();
  @override
  Uri get uri => AppRoute._uri('/media');
  @override
  Nav get nav => Nav.media;
}

class Team extends AppRoute {
  const Team();
  @override
  Uri get uri => AppRoute._uri('/team');
  @override
  Nav get nav => Nav.team;
  @override
  Permission get permission => Permission.manageTeam;
}

class SettingsAppearance extends AppRoute {
  const SettingsAppearance();
  @override
  Uri get uri => AppRoute._uri('/settings/appearance');
  @override
  Nav get nav => Nav.settings;
}

class SettingsProfile extends AppRoute {
  const SettingsProfile();
  @override
  Uri get uri => AppRoute._uri('/settings/profile');
  @override
  Nav get nav => Nav.settings;
}

class SettingsShop extends AppRoute {
  const SettingsShop();
  @override
  Uri get uri => AppRoute._uri('/settings/shop');
  @override
  Nav get nav => Nav.settings;
  @override
  Permission get permission => Permission.manageShop;
}

/// A page the signed-in role may not open. The URL stays the one asked for.
class Forbidden extends AppRoute {
  final AppRoute from;
  const Forbidden(this.from);
  @override
  Uri get uri => from.uri;
  @override
  Nav? get nav => from.nav;
}

class NotFound extends AppRoute {
  final String path;
  const NotFound(this.path);
  @override
  Uri get uri => Uri.parse(path);
}

/// Every page a signed-in owner can reach, one of each: what the layout
/// sweep and the smoke scenario visit.
const everyPage = <AppRoute>[
  Dashboard(),
  Setup(),
  Orders(),
  Orders(view: OrdersView.board),
  OrderDetail(1042),
  Customers(),
  Products(),
  NewProduct(),
  ProductDetail('p-12'),
  ProductDetail('p-12', tab: ProductTab.history),
  Media(),
  Team(),
  SettingsAppearance(),
  SettingsProfile(),
  SettingsShop(),
  NotFound('/nowhere'),
];
