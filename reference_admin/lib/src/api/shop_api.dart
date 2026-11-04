import 'dart:typed_data';

import 'package:admin_ui/assets.dart';
import 'package:admin_ui/collection.dart';
import 'package:admin_ui/widgets.dart' show PresenceChannel;
import 'package:flutter/foundation.dart' show ValueListenable;

import 'models.dart';

export 'errors.dart';
export 'models.dart';

/// How long a kind of call takes.
enum CallKind { read, list, search, write, refund }

/// One value per call the shop answers: the name faults, holds, the call log
/// and assertions use, so a typo is a compile error.
enum Endpoint {
  signIn('auth.signIn', CallKind.write),
  signOut('auth.signOut', CallKind.write),
  inviteInfo('auth.inviteInfo', CallKind.read),
  setPassword('auth.setPassword', CallKind.write),
  changePassword('auth.changePassword', CallKind.write),
  loadPrefs('prefs.load', CallKind.read),
  savePrefs('prefs.save', CallKind.write),
  stats('dashboard.stats', CallKind.read),
  notifications('notifications.list', CallKind.read),
  markRead('notifications.markRead', CallKind.write),
  markAllRead('notifications.markAllRead', CallKind.write),
  navBadges('shell.badges', CallKind.read),
  listOrders('orders.list', CallKind.list),
  order('orders.get', CallKind.read),
  bulkSetStatus('orders.bulkSetStatus', CallKind.write),
  moveOrder('orders.move', CallKind.write),
  refund('orders.refund', CallKind.refund),
  addNote('orders.addNote', CallKind.write),
  exportCsv('orders.exportCsv', CallKind.list),
  listCustomers('customers.list', CallKind.list),
  customer('customers.get', CallKind.read),
  listProducts('products.list', CallKind.list),
  product('products.get', CallKind.read),
  createProduct('products.create', CallKind.write),
  saveProduct('products.save', CallKind.write),
  patchStock('products.patchStock', CallKind.write),
  skuAvailable('products.skuAvailable', CallKind.search),
  revisions('products.revisions', CallKind.read),
  restoreRevision('products.restoreRevision', CallKind.write),
  categories('products.categories', CallKind.read),
  searchSuppliers('products.searchSuppliers', CallKind.search),
  resolveAsset('media.resolve', CallKind.read),
  browseAssets('media.browse', CallKind.list),
  uploadAsset('media.upload', CallKind.write),
  updateAlt('media.updateAlt', CallKind.write),
  listViews('views.list', CallKind.read),
  createView('views.create', CallKind.write),
  updateView('views.update', CallKind.write),
  deleteView('views.delete', CallKind.write),
  setDefaultView('views.setDefault', CallKind.write),
  reorderViews('views.reorder', CallKind.write),
  staff('staff.list', CallKind.read),
  invite('staff.invite', CallKind.write),
  setRole('staff.setRole', CallKind.write),
  deactivate('staff.deactivate', CallKind.write),
  shop('shop.get', CallKind.read),
  saveShop('shop.save', CallKind.write),
  completeSetup('shop.completeSetup', CallKind.write),
  search('search.all', CallKind.search);

  /// `area.call`, as the call log and a run report show it.
  final String path;
  final CallKind kind;
  const Endpoint(this.path, this.kind);
}

/// The field ids list queries filter and sort on: what a screen's columns,
/// filters and saved views name, and what the fake's sources read.
abstract final class OrderFields {
  static const number = 'number';
  static const customerId = 'customerId';
  static const customer = 'customer';
  static const email = 'email';
  static const placedAt = 'placedAt';
  static const status = 'status';
  static const payment = 'payment';
  static const channel = 'channel';
  static const total = 'total';
  static const items = 'items';
  static const refundRequested = 'refundRequested';
  static const partiallyRefunded = 'partiallyRefunded';
  static const toShip = 'toShip';
}

abstract final class CustomerFields {
  static const name = 'name';
  static const email = 'email';
  static const city = 'city';
  static const country = 'country';
  static const tags = 'tags';
  static const createdAt = 'createdAt';
}

abstract final class ProductFields {
  static const sku = 'sku';
  static const name = 'name';
  static const category = 'category';
  static const status = 'status';
  static const price = 'price';
  static const stock = 'stock';
  static const lowStock = 'lowStock';
  static const missingTranslation = 'missingTranslation';
  static const missingArabic = 'missingArabic';
  static const featured = 'featured';
  static const tags = 'tags';
  static const supplier = 'supplier';
  static const updatedAt = 'updatedAt';
}

/// The collection keys saved views are stored under.
abstract final class CollectionKeys {
  static const orders = 'orders';
  static const products = 'products';
  static const customers = 'customers';
}

/// The shop, as the screens see it. Screens import this and nothing below
/// it: `FakeShopApi` answers today, a real client could tomorrow.
///
/// Every call can fail with a `ShopError`.
abstract interface class ShopApi {
  // auth
  Future<Session> signIn(String email, String password);
  Future<void> signOut();
  Future<Invite> inviteInfo(String token);
  Future<Session> setPassword(String token, String password);
  Future<void> changePassword(String current, String next);

  // prefs, per signed-in staff member
  Future<UserPrefs> loadPrefs();
  Future<void> savePrefs(UserPrefs prefs);

  // dashboard
  Future<DashboardStats> stats(DashboardRange range);

  // notifications and the frame's counts
  Future<List<AppNotification>> notifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<NavBadges> navBadges();

  // orders
  Future<CollectionPage<Order>> listOrders(CollectionQuery query);
  Future<Order> order(int number);
  Future<void> bulkSetStatus(List<int> numbers, OrderStatus status);

  /// With [emailCustomer], the customer is told of the new status and the
  /// order's timeline records the email.
  Future<Order> moveOrder(
    int number,
    OrderStatus status, {
    bool emailCustomer = false,
  });

  /// Throws `validation({'amount': ValidationCodes.tooHigh})` above the
  /// refundable amount.
  Future<Order> refund(int number, int amountCents, String reason);

  /// [text] in mention-token form; each mentioned teammate is notified.
  Future<Order> addNote(int number, String text);

  /// The orders [query] matches, every page, as CSV in UTF-8.
  Future<Uint8List> exportCsv(CollectionQuery query);

  // customers
  Future<CollectionPage<Customer>> listCustomers(CollectionQuery query);
  Future<Customer> customer(String id);

  // products
  Future<CollectionPage<Product>> listProducts(CollectionQuery query);
  Future<Product> product(String id);
  Future<Product> createProduct(ProductDraft draft);

  /// Throws `validation({'sku': ValidationCodes.taken})`, or `conflict` when
  /// [baseRevision] is not the stored revision.
  Future<Product> saveProduct(Product product, {int? baseRevision});
  Future<Product> patchStock(String id, int stock);
  Future<bool> skuAvailable(String sku, {String? exceptId});
  Future<List<ProductRevision>> revisions(String id);
  Future<Product> restoreRevision(String id, int version);
  Future<List<Category>> categories();
  Future<List<Supplier>> searchSuppliers(String query);

  // staff
  Future<List<StaffMember>> staff();

  /// Throws `validation({'email': ValidationCodes.duplicate})` for someone
  /// already on the team.
  Future<StaffMember> invite(String email, Role role);
  Future<StaffMember> setRole(String id, Role role);
  Future<StaffMember> deactivate(String id);

  // shop
  Future<ShopSettings> shop();
  Future<ShopSettings> saveShop(ShopSettings settings);
  Future<ShopSettings> completeSetup(ShopSettings settings);

  // search, for the command palette
  Future<SearchHits> search(String query);

  // media, saved views, presence
  AssetSource get assets;
  SavedViewsStore get savedViews;

  /// Who else has [productId]'s editor open.
  PresenceChannel presence(String productId);

  // realtime
  Stream<ShopEvent> get events;
  Stream<bool> get connected;
  bool get isConnected;

  /// How many calls are running: the frame's progress bar shows while it is
  /// above zero.
  ValueListenable<int> get inFlight;
}
