import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_ui/assets.dart' show Asset;
import 'package:admin_ui/collection.dart';
import 'package:admin_ui/comments.dart' show mentionRuns;
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;

import '../api/shop_api.dart';
import 'fake_media.dart';
import 'fake_presence.dart';
import 'faults.dart';
import 'seed.dart';
import 'seed_accounts.dart';

export 'faults.dart';
export 'seed.dart' show DemoSeed, FakeShopDb;

/// The whole shop in memory: the app's only backend. `main.dart` runs on it,
/// and so does every scenario.
///
/// One [db] behind every endpoint, the role matrix checked on every write,
/// [latency] on every call, [faults] to fail or hold one, [calls] to count
/// them, and [simulate] to push what a live shop would push.
class FakeShopApi implements ShopApi {
  final FakeShopDb db;
  Latency latency;
  late final FaultPlan faults = FaultPlan(_setConnected);
  final calls = CallLog();
  late final simulate = FakeShopSimulator._(this);

  FakeShopApi({DemoSeed seed = DemoSeed.demo, this.latency = Latency.realistic})
    : db = seedShop(seed, now: clock.now());

  /// A fake over [db] as it stands, for a test that shaped it by hand.
  FakeShopApi.over(this.db, {this.latency = Latency.none});

  StaffMember? _current;
  var _sessions = 0;
  final _inFlight = ValueNotifier<int>(0);
  final _events = StreamController<ShopEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  late final FakeAssetSource _assets = FakeAssetSource(db, run, _require);
  late final FakeSavedViews _views = FakeSavedViews(db, run);
  final _presence = <String, FakePresence>{};

  /// Who the fake believes is signed in.
  StaffMember? get currentStaff => _current;

  /// Signs [member] in without a call: the app started signed in, or a
  /// scenario that is not about signing in.
  Session adoptSession(StaffMember member) {
    _current = member;
    return Session(
      token: 'session-${member.id}-${++_sessions}',
      staff: member,
      shopName: db.shop.name,
    );
  }

  /// The first active staff member with [role].
  StaffMember staffWithRole(Role role) => db.staff.firstWhere(
    (s) => s.role == role && s.status == StaffStatus.active,
  );

  // -------------------------------------------------------------------------
  // The call machinery

  /// Runs [body] as the call [endpoint]: counted in [inFlight] throughout,
  /// held by an armed [Gate], delayed by [latency], failed by an armed fault,
  /// and logged in [calls] as it finishes.
  Future<T> run<T>(
    Endpoint endpoint,
    Map<String, Object?> args,
    FutureOr<T> Function() body,
  ) async {
    _inFlight.value++;
    try {
      if (faults.takeHold(endpoint) case final gate?) await gate.opened;
      final delay = latency.of(endpoint.kind);
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (faults.takeFailure(endpoint) case final error?) throw error;
      final result = await body();
      calls.record(CallRecord(endpoint, args, null));
      return result;
    } on ShopError catch (error) {
      calls.record(CallRecord(endpoint, args, error));
      rethrow;
    } finally {
      _inFlight.value--;
    }
  }

  StaffMember _signedIn() => _current ?? (throw const ShopError.forbidden());

  void _require(Permission permission) {
    if (!_signedIn().role.can(permission)) {
      throw const ShopError.forbidden();
    }
  }

  void _setConnected(bool online) => _connected.add(online);

  void _emit(ShopEvent event) => _events.add(event);

  DateTime get _now => clock.now();

  // -------------------------------------------------------------------------
  // auth

  @override
  Future<Session> signIn(String email, String password) =>
      run(Endpoint.signIn, {'email': email}, () {
        final key = email.trim().toLowerCase();
        final failures = db.failedSignIns[key] ?? 0;
        if (failures >= lockAfterAttempts) {
          throw const ShopError.validation({'email': ValidationCodes.locked});
        }
        if (db.accounts[key] != password) {
          db.failedSignIns[key] = failures + 1;
          throw ShopError.validation({
            if (failures + 1 >= lockAfterAttempts)
              'email': ValidationCodes.locked
            else
              'password': ValidationCodes.wrongPassword,
          });
        }
        db.failedSignIns.remove(key);
        final member = db.staff.firstWhere((s) => s.email == key);
        if (member.status != StaffStatus.active) {
          throw const ShopError.forbidden();
        }
        final signedIn = member.copyWith(lastActiveAt: _now);
        db.replaceStaff(signedIn);
        return adoptSession(signedIn);
      });

  @override
  Future<void> signOut() => run(Endpoint.signOut, const {}, () {
    _current = null;
  });

  Invite _validInvite(String token) {
    final invite = db.invites.firstWhere(
      (i) => i.token == token,
      orElse: () => throw const ShopError.notFound(),
    );
    if (invite.expiresAt.isBefore(_now)) throw const ShopError.expired();
    return invite;
  }

  @override
  Future<Invite> inviteInfo(String token) =>
      run(Endpoint.inviteInfo, {'token': token}, () => _validInvite(token));

  @override
  Future<Session> setPassword(String token, String password) => run(
    Endpoint.setPassword,
    {'token': token},
    () {
      final invite = _validInvite(token);
      if (password.length < 8) {
        throw const ShopError.validation({'password': ValidationCodes.tooWeak});
      }
      db.invites.remove(invite);
      db.accounts[invite.email] = password;
      final member = db.staff.firstWhere((s) => s.email == invite.email);
      final active = member.copyWith(
        status: StaffStatus.active,
        lastActiveAt: _now,
      );
      db.replaceStaff(active);
      return adoptSession(active);
    },
  );

  @override
  Future<void> changePassword(String current, String next) =>
      run(Endpoint.changePassword, const {}, () {
        final me = _signedIn();
        if (db.accounts[me.email] != current) {
          throw const ShopError.validation({
            'current': ValidationCodes.wrongPassword,
          });
        }
        if (next.length < 8) {
          throw const ShopError.validation({'next': ValidationCodes.tooWeak});
        }
        db.accounts[me.email] = next;
      });

  // -------------------------------------------------------------------------
  // prefs

  @override
  Future<UserPrefs> loadPrefs() => run(
    Endpoint.loadPrefs,
    const {},
    () => db.prefs[_signedIn().id] ?? const UserPrefs(),
  );

  @override
  Future<void> savePrefs(UserPrefs prefs) =>
      run(Endpoint.savePrefs, prefs.toJson(), () {
        db.prefs[_signedIn().id] = prefs;
      });

  // -------------------------------------------------------------------------
  // dashboard

  /// Revenue net of refunds from orders placed in [from, to), cancelled ones
  /// left out: what the dashboard's revenue figure sums.
  int revenueBetween(DateTime from, DateTime to) =>
      [for (final o in _ordersBetween(from, to)) o.totalCents - o.refundedCents]
          .fold(0, (a, b) => a + b);

  List<Order> _ordersBetween(DateTime from, DateTime to) => [
    for (final o in db.orders)
      if (!o.placedAt.isBefore(from) &&
          o.placedAt.isBefore(to) &&
          o.status != OrderStatus.cancelled)
        o,
  ];

  /// The last [DashboardRange.days] full days, ending where today starts:
  /// a day still under way would read as a drop on every trend.
  (DateTime, DateTime) rangeBounds(DashboardRange range, {int back = 0}) {
    final now = _now;
    final end = DateTime(now.year, now.month, now.day);
    final to = end.subtract(Duration(days: range.days * back));
    return (to.subtract(Duration(days: range.days)), to);
  }

  @override
  Future<DashboardStats> stats(DashboardRange range) => run(
    Endpoint.stats,
    {'range': range.name},
    () {
      _signedIn();
      final (from, to) = rangeBounds(range);
      final (prevFrom, prevTo) = rangeBounds(range, back: 1);
      final orders = _ordersBetween(from, to);
      final previous = _ordersBetween(prevFrom, prevTo);
      final revenue = revenueBetween(from, to);
      final previousRevenue = revenueBetween(prevFrom, prevTo);
      int newCustomers(DateTime from, DateTime to) => db.customers
          .where((c) => !c.createdAt.isBefore(from) && c.createdAt.isBefore(to))
          .length;

      final revenueSeries = List.filled(range.days, 0);
      final ordersSeries = List.filled(range.days, 0);
      final customersSeries = List.filled(range.days, 0);
      for (final o in orders) {
        final day = o.placedAt.difference(from).inDays;
        if (day < 0 || day >= range.days) continue;
        revenueSeries[day] += o.totalCents - o.refundedCents;
        ordersSeries[day]++;
      }
      for (final c in db.customers) {
        final day = c.createdAt.difference(from).inDays;
        if (c.createdAt.isBefore(from) || day >= range.days) continue;
        customersSeries[day]++;
      }
      final units = <String, (int, int)>{};
      for (final o in orders) {
        for (final l in o.lines) {
          final (u, r) = units[l.productId] ?? (0, 0);
          units[l.productId] = (u + l.qty, r + l.totalCents);
        }
      }
      final ranked = units.entries.toList()
        ..sort((a, b) {
          final byUnits = b.value.$1.compareTo(a.value.$1);
          return byUnits != 0 ? byUnits : a.key.compareTo(b.key);
        });
      final channels = {for (final c in OrderChannel.values) c: 0};
      for (final o in orders) {
        channels[o.channel] = channels[o.channel]! + 1;
      }
      return DashboardStats(
        range: range,
        revenueCents: revenue,
        orders: orders.length,
        averageOrderCents: orders.isEmpty ? 0 : revenue ~/ orders.length,
        newCustomers: newCustomers(from, to),
        previousRevenueCents: previousRevenue,
        previousOrders: previous.length,
        previousAverageOrderCents: previous.isEmpty
            ? 0
            : previousRevenue ~/ previous.length,
        previousNewCustomers: newCustomers(prevFrom, prevTo),
        revenueSeries: revenueSeries,
        ordersSeries: ordersSeries,
        customersSeries: customersSeries,
        topProducts: [
          for (final e in ranked.take(5))
            TopProduct(
              productId: e.key,
              name: db.productById(e.key).name,
              units: e.value.$1,
              revenueCents: e.value.$2,
            ),
        ],
        channels: channels,
        attention: attention(),
      );
    },
  );

  /// What the dashboard's attention tiles count.
  AttentionCounts attention() => AttentionCounts(
    toShip: db.orders.where((o) => o.status.toShip).length,
    lowStock: db.products
        .where((p) => p.status != ProductStatus.archived && p.isLowStock)
        .length,
    missingTranslations: db.products
        .where((p) => p.missingLanguages.isNotEmpty)
        .length,
    refundRequests: db.orders.where((o) => o.refundRequested).length,
  );

  // -------------------------------------------------------------------------
  // notifications

  List<AppNotification> _inbox() => db.notifications[_signedIn().id] ??= [];

  @override
  Future<List<AppNotification>> notifications() =>
      run(Endpoint.notifications, const {}, () => [..._inbox()]);

  @override
  Future<void> markRead(String id) => run(Endpoint.markRead, {'id': id}, () {
    final inbox = _inbox();
    final i = inbox.indexWhere((n) => n.id == id);
    if (i < 0) throw const ShopError.notFound();
    inbox[i] = inbox[i].copyWith(read: true);
  });

  @override
  Future<void> markAllRead() => run(Endpoint.markAllRead, const {}, () {
    final inbox = _inbox();
    for (var i = 0; i < inbox.length; i++) {
      inbox[i] = inbox[i].copyWith(read: true);
    }
  });

  @override
  Future<NavBadges> navBadges() => run(
    Endpoint.navBadges,
    const {},
    () => NavBadges(
      toShip: db.orders.where((o) => o.status.toShip).length,
      unreadNotifications: _inbox().where((n) => !n.read).length,
    ),
  );

  void _notify(String staffId, AppNotification notification) {
    (db.notifications[staffId] ??= []).insert(0, notification);
    if (_current?.id == staffId) _emit(NotificationEvent(notification));
  }

  // -------------------------------------------------------------------------
  // orders

  LocalCollectionSource<Order> get _orderSource => LocalCollectionSource(
    db.orders,
    fields: {
      OrderFields.number: (o) => o.number,
      OrderFields.customerId: (o) => o.customerId,
      OrderFields.customer: (o) => o.customerName,
      OrderFields.email: (o) => o.customerEmail,
      OrderFields.placedAt: (o) => o.placedAt,
      OrderFields.status: (o) => o.status,
      OrderFields.payment: (o) => o.payment,
      OrderFields.channel: (o) => o.channel,
      OrderFields.total: (o) => o.totalCents / 100,
      OrderFields.items: (o) => o.itemCount,
      OrderFields.refundRequested: (o) => o.refundRequested,
      OrderFields.partiallyRefunded: (o) => o.partiallyRefunded,
      OrderFields.toShip: (o) => o.status.toShip,
    },
    searchFields: {OrderFields.number, OrderFields.customer, OrderFields.email},
  );

  Map<String, Object?> _queryArgs(CollectionQuery q) => {
    'page': q.pageIndex,
    if (q.search.isNotEmpty) 'search': q.search,
    if (q.filters.any((f) => f.isActive))
      'filters': [
        for (final f in q.filters)
          if (f.isActive) f.field,
      ],
    if (q.sortKey != null)
      'sort': '${q.sortKey} ${q.ascending ? 'asc' : 'desc'}',
  };

  @override
  Future<CollectionPage<Order>> listOrders(CollectionQuery query) =>
      run(Endpoint.listOrders, _queryArgs(query), () {
        _signedIn();
        return _orderSource.fetch(query);
      });

  @override
  Future<Order> order(int number) =>
      run(Endpoint.order, {'number': number}, () {
        _signedIn();
        return db.orderByNumber(number);
      });

  Order _setStatus(Order order, OrderStatus status) {
    if (order.status == status) return order;
    if (!order.status.canBecome(status)) {
      throw const ShopError.validation({'status': ValidationCodes.notAllowed});
    }
    final kind = OrderEventKind.values.byName(status.name);
    final updated = order.copyWith(
      status: status,
      events: [
        ...order.events,
        OrderEvent(kind: kind, at: _now, by: _signedIn().name),
      ],
    );
    db.replaceOrder(updated);
    return updated;
  }

  @override
  Future<void> bulkSetStatus(List<int> numbers, OrderStatus status) => run(
    Endpoint.bulkSetStatus,
    {'numbers': numbers, 'status': status.name},
    () {
      _require(Permission.manageOrders);
      final orders = [for (final n in numbers) db.orderByNumber(n)];
      // All or nothing: one order that cannot move refuses the lot.
      if (orders.any((o) => !o.status.canBecome(status))) {
        throw const ShopError.validation({
          'status': ValidationCodes.notAllowed,
        });
      }
      for (final o in orders) {
        _setStatus(o, status);
      }
      _emit(OrdersChangedEvent(numbers));
    },
  );

  @override
  Future<Order> moveOrder(
    int number,
    OrderStatus status, {
    bool emailCustomer = false,
  }) => run(
    Endpoint.moveOrder,
    {
      'number': number,
      'status': status.name,
      if (emailCustomer) 'emailCustomer': true,
    },
    () {
      _require(Permission.manageOrders);
      var updated = _setStatus(db.orderByNumber(number), status);
      if (emailCustomer) {
        updated = updated.copyWith(
          events: [
            ...updated.events,
            OrderEvent(
              kind: OrderEventKind.emailed,
              at: _now,
              by: _signedIn().name,
              detail: status.name,
            ),
          ],
        );
        db.replaceOrder(updated);
      }
      _emit(OrdersChangedEvent([number]));
      return updated;
    },
  );

  @override
  Future<Order> refund(int number, int amountCents, String reason) =>
      run(Endpoint.refund, {'number': number, 'amountCents': amountCents}, () {
        _require(Permission.refund);
        final order = db.orderByNumber(number);
        if (amountCents <= 0) {
          throw const ShopError.validation({'amount': ValidationCodes.invalid});
        }
        if (amountCents > order.refundableCents) {
          throw const ShopError.validation({'amount': ValidationCodes.tooHigh});
        }
        final updated = order.copyWith(
          refundedCents: order.refundedCents + amountCents,
          refundRequested: false,
          events: [
            ...order.events,
            OrderEvent(
              kind: OrderEventKind.refunded,
              at: _now,
              by: _signedIn().name,
              detail: reason.isEmpty ? '$amountCents' : '$amountCents $reason',
            ),
          ],
        );
        db.replaceOrder(updated);
        _emit(OrdersChangedEvent([number]));
        return updated;
      });

  @override
  Future<Order> addNote(int number, String text) => run(
    Endpoint.addNote,
    {'number': number, 'text': text},
    () {
      _require(Permission.manageOrders);
      final me = _signedIn();
      final order = db.orderByNumber(number);
      final updated = order.copyWith(
        notes: [...order.notes, text],
        events: [
          ...order.events,
          OrderEvent(
            kind: OrderEventKind.note,
            at: _now,
            by: me.name,
            detail: text,
          ),
        ],
      );
      db.replaceOrder(updated);
      final mentioned = {
        for (final run in mentionRuns(text, (id) => id)) ?run.mentionId,
      };
      for (final id in mentioned) {
        if (id == me.id || !db.staff.any((s) => s.id == id)) continue;
        _notify(
          id,
          AppNotification(
            id: 'n-${db.nextId++}',
            kind: NotificationKind.mention,
            subject: {'en': order.label, 'fr': order.label, 'ar': order.label},
            actor: me.name,
            at: _now,
            read: false,
            route: '/orders/$number',
          ),
        );
      }
      return updated;
    },
  );

  @override
  Future<Uint8List> exportCsv(CollectionQuery query) =>
      run(Endpoint.exportCsv, _queryArgs(query), () {
        _signedIn();
        String cell(Object? value) {
          final text = '$value';
          return text.contains(RegExp('[",\n]'))
              ? '"${text.replaceAll('"', '""')}"'
              : text;
        }

        String money(int cents) =>
            '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
        final rows = [
          'number,placed_at,customer,email,status,payment,items,total,refunded',
          for (final o in _orderSource.matching(query))
            [
              o.number,
              o.placedAt.toUtc().toIso8601String(),
              o.customerName,
              o.customerEmail,
              o.status.name,
              o.payment.name,
              o.itemCount,
              money(o.totalCents),
              money(o.refundedCents),
            ].map(cell).join(','),
        ];
        return Uint8List.fromList(utf8.encode('${rows.join('\n')}\n'));
      });

  // -------------------------------------------------------------------------
  // customers

  @override
  Future<CollectionPage<Customer>> listCustomers(CollectionQuery query) =>
      run(Endpoint.listCustomers, _queryArgs(query), () {
        _signedIn();
        return LocalCollectionSource<Customer>(
          db.customers,
          fields: {
            CustomerFields.name: (c) => c.name,
            CustomerFields.email: (c) => c.email,
            CustomerFields.city: (c) => c.city,
            CustomerFields.country: (c) => c.country,
            CustomerFields.tags: (c) => c.tags.join(' '),
            CustomerFields.createdAt: (c) => c.createdAt,
          },
          searchFields: {
            CustomerFields.name,
            CustomerFields.email,
            CustomerFields.city,
          },
        ).fetch(query);
      });

  @override
  Future<Customer> customer(String id) =>
      run(Endpoint.customer, {'id': id}, () {
        _signedIn();
        return db.customerById(id);
      });

  // -------------------------------------------------------------------------
  // products

  LocalCollectionSource<Product> get _productSource => LocalCollectionSource(
    db.products,
    fields: {
      ProductFields.sku: (p) => p.sku,
      ProductFields.name: (p) => p.name.values.join(' '),
      ProductFields.category: (p) => p.categoryId,
      ProductFields.status: (p) => p.status,
      ProductFields.price: (p) => p.priceCents / 100,
      ProductFields.stock: (p) => p.stock,
      ProductFields.lowStock: (p) => p.isLowStock,
      ProductFields.missingTranslation: (p) => p.missingLanguages.isNotEmpty,
      ProductFields.missingArabic: (p) => p.missingLanguages.contains('ar'),
      ProductFields.featured: (p) => p.featured,
      ProductFields.tags: (p) => p.tags.join(' '),
      ProductFields.supplier: (p) => p.supplierId,
      ProductFields.updatedAt: (p) => p.updatedAt,
    },
    searchFields: {ProductFields.sku, ProductFields.name, ProductFields.tags},
  );

  @override
  Future<CollectionPage<Product>> listProducts(CollectionQuery query) =>
      run(Endpoint.listProducts, _queryArgs(query), () {
        _signedIn();
        return _productSource.fetch(query);
      });

  @override
  Future<Product> product(String id) => run(Endpoint.product, {'id': id}, () {
    _signedIn();
    return db.productById(id);
  });

  bool _skuTaken(String sku, {String? exceptId}) => db.products.any(
    (p) => p.id != exceptId && p.sku.toLowerCase() == sku.trim().toLowerCase(),
  );

  void _addRevision(Product product) {
    (db.revisions[product.id] ??= []).add(
      ProductRevision(
        productId: product.id,
        version: product.revision,
        at: product.updatedAt,
        by: product.updatedBy,
        snapshot: product,
      ),
    );
  }

  @override
  Future<Product> createProduct(ProductDraft draft) =>
      run(Endpoint.createProduct, {'sku': draft.sku}, () {
        _require(Permission.editCatalogue);
        if (_skuTaken(draft.sku)) {
          throw const ShopError.validation({'sku': ValidationCodes.taken});
        }
        final n = db.nextProductNumber++;
        final product = Product(
          id: 'p-${'$n'.padLeft(2, '0')}',
          sku: draft.sku.trim(),
          name: draft.name,
          description: const {},
          categoryId: draft.categoryId,
          tags: const [],
          priceCents: draft.priceCents,
          stock: draft.stock,
          lowStockAt: 5,
          status: draft.status,
          featured: false,
          labelColor: 0xFF2F7D4F,
          care: const {},
          variants: const [],
          photoIds: const [],
          supplierId: db.suppliers.isEmpty ? '' : db.suppliers.first.id,
          revision: 1,
          updatedAt: _now,
          updatedBy: _signedIn().name,
        );
        db.products.add(product);
        _addRevision(product);
        return product;
      });

  @override
  Future<Product> saveProduct(Product product, {int? baseRevision}) => run(
    Endpoint.saveProduct,
    {'id': product.id, 'baseRevision': ?baseRevision},
    () {
      _require(Permission.editCatalogue);
      final stored = db.productById(product.id);
      if (baseRevision != null && baseRevision != stored.revision) {
        throw const ShopError.conflict();
      }
      if (_skuTaken(product.sku, exceptId: product.id)) {
        throw const ShopError.validation({'sku': ValidationCodes.taken});
      }
      final saved = product.copyWith(
        revision: stored.revision + 1,
        updatedAt: _now,
        updatedBy: _signedIn().name,
      );
      db.replaceProduct(saved);
      _addRevision(saved);
      _usageChanged();
      return saved;
    },
  );

  @override
  Future<Product> patchStock(String id, int stock) =>
      run(Endpoint.patchStock, {'id': id, 'stock': stock}, () {
        _require(Permission.editCatalogue);
        if (stock < 0) {
          throw const ShopError.validation({'stock': ValidationCodes.invalid});
        }
        final stored = db.productById(id);
        final updated = stored.copyWith(
          stock: stock,
          updatedAt: _now,
          updatedBy: _signedIn().name,
        );
        db.replaceProduct(updated);
        if (!stored.isLowStock && updated.isLowStock) {
          _emit(StockLowEvent(updated));
        }
        return updated;
      });

  @override
  Future<bool> skuAvailable(String sku, {String? exceptId}) => run(
    Endpoint.skuAvailable,
    {'sku': sku, 'exceptId': ?exceptId},
    () => !_skuTaken(sku, exceptId: exceptId),
  );

  @override
  Future<List<ProductRevision>> revisions(String id) =>
      run(Endpoint.revisions, {'id': id}, () {
        _signedIn();
        db.productById(id);
        return [...?db.revisions[id]].reversed.toList();
      });

  @override
  Future<Product> restoreRevision(String id, int version) =>
      run(Endpoint.restoreRevision, {'id': id, 'version': version}, () {
        _require(Permission.editCatalogue);
        final stored = db.productById(id);
        final revision = (db.revisions[id] ?? const <ProductRevision>[])
            .firstWhere(
              (r) => r.version == version,
              orElse: () => throw const ShopError.notFound(),
            );
        final restored = revision.snapshot.copyWith(
          revision: stored.revision + 1,
          updatedAt: _now,
          updatedBy: _signedIn().name,
        );
        db.replaceProduct(restored);
        _addRevision(restored);
        _usageChanged();
        return restored;
      });

  @override
  Future<List<Category>> categories() =>
      run(Endpoint.categories, const {}, () => [...db.categories]);

  @override
  Future<List<Supplier>> searchSuppliers(String query) =>
      run(Endpoint.searchSuppliers, {'query': query}, () {
        final q = query.trim().toLowerCase();
        return [
          for (final s in db.suppliers)
            if (q.isEmpty || s.name.toLowerCase().contains(q)) s,
        ];
      });

  /// Recounts each asset's uses after a product's photos changed.
  void _usageChanged() {
    for (var i = 0; i < db.assets.length; i++) {
      final a = db.assets[i];
      final uses = db.products.where((p) => p.photoIds.contains(a.id)).length;
      if (uses == a.usageCount) continue;
      db.assets[i] = Asset(
        id: a.id,
        name: a.name,
        type: a.type,
        bytes: a.bytes,
        thumbnail: a.thumbnail,
        url: a.url,
        swatch: a.swatch,
        width: a.width,
        height: a.height,
        usageCount: uses,
        alt: a.alt,
      );
    }
  }

  // -------------------------------------------------------------------------
  // staff

  @override
  Future<List<StaffMember>> staff() => run(Endpoint.staff, const {}, () {
    _signedIn();
    return [...db.staff];
  });

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<StaffMember> invite(String email, Role role) => run(
    Endpoint.invite,
    {'email': email, 'role': role.name},
    () {
      _require(Permission.manageTeam);
      final key = email.trim().toLowerCase();
      if (!_email.hasMatch(key)) {
        throw const ShopError.validation({'email': ValidationCodes.invalid});
      }
      if (db.staff.any((s) => s.email == key)) {
        throw const ShopError.validation({'email': ValidationCodes.duplicate});
      }
      final n = db.nextId++;
      final member = StaffMember(
        id: 's-${'$n'.padLeft(2, '0')}',
        name: key.split('@').first,
        email: key,
        role: role,
        status: StaffStatus.invited,
      );
      db.staff.add(member);
      db.invites.add(
        Invite(
          token: 'invite-$n',
          email: key,
          name: member.name,
          role: role,
          invitedBy: _signedIn().name,
          expiresAt: _now.add(const Duration(days: 7)),
        ),
      );
      return member;
    },
  );

  @override
  Future<StaffMember> setRole(String id, Role role) =>
      run(Endpoint.setRole, {'id': id, 'role': role.name}, () {
        _require(Permission.manageTeam);
        final member = db.staffById(id);
        if (member.id == _signedIn().id) throw const ShopError.forbidden();
        final updated = member.copyWith(role: role);
        db.replaceStaff(updated);
        return updated;
      });

  @override
  Future<StaffMember> deactivate(String id) =>
      run(Endpoint.deactivate, {'id': id}, () {
        _require(Permission.manageTeam);
        final member = db.staffById(id);
        if (member.id == _signedIn().id) throw const ShopError.forbidden();
        final updated = member.copyWith(status: StaffStatus.deactivated);
        db.replaceStaff(updated);
        db.accounts.remove(member.email);
        return updated;
      });

  // -------------------------------------------------------------------------
  // shop

  @override
  Future<ShopSettings> shop() => run(Endpoint.shop, const {}, () {
    _signedIn();
    return db.shop;
  });

  @override
  Future<ShopSettings> saveShop(ShopSettings settings) => run(
    Endpoint.saveShop,
    {'name': settings.name},
    () {
      _require(Permission.manageShop);
      return db.shop = settings.copyWith(setupComplete: db.shop.setupComplete);
    },
  );

  @override
  Future<ShopSettings> completeSetup(ShopSettings settings) =>
      run(Endpoint.completeSetup, {'name': settings.name}, () {
        _require(Permission.manageShop);
        return db.shop = settings.copyWith(setupComplete: true);
      });

  // -------------------------------------------------------------------------
  // search

  @override
  Future<SearchHits> search(String query) =>
      run(Endpoint.search, {'query': query}, () {
        _signedIn();
        final q = query.trim().toLowerCase().replaceFirst('#', '');
        if (q.isEmpty) return const SearchHits();
        return SearchHits(
          orders: [
            for (final o in db.orders.reversed)
              if ('${o.number}'.contains(q) ||
                  o.customerName.toLowerCase().contains(q))
                o,
          ].take(5).toList(),
          products: [
            for (final p in db.products)
              if (p.sku.toLowerCase().contains(q) ||
                  p.name.values.any((n) => n.toLowerCase().contains(q)))
                p,
          ].take(5).toList(),
          customers: [
            for (final c in db.customers)
              if (c.name.toLowerCase().contains(q) ||
                  c.email.toLowerCase().contains(q))
                c,
          ].take(5).toList(),
        );
      });

  // -------------------------------------------------------------------------
  // media, views, presence, realtime

  @override
  FakeAssetSource get assets => _assets;

  @override
  FakeSavedViews get savedViews => _views;

  @override
  FakePresence presence(String productId) =>
      _presence.putIfAbsent(productId, FakePresence.new);

  @override
  Stream<ShopEvent> get events => _events.stream;

  @override
  Stream<bool> get connected => _connected.stream;

  @override
  bool get isConnected => !faults.isOffline;

  @override
  ValueListenable<int> get inFlight => _inFlight;
}

/// What a live shop would push, on demand: a scenario calls these inside
/// `s.act`, and the app hears them on `ShopApi.events`.
class FakeShopSimulator {
  final FakeShopApi _api;
  FakeShopSimulator._(this._api);

  FakeShopDb get _db => _api.db;

  /// A storefront order, paid by card, for an existing customer.
  Order newOrder({String customerId = 'c-012', String productId = 'p-12'}) {
    final now = clock.now();
    final customer = _db.customerById(customerId);
    final product = _db.productById(productId);
    final number = _db.nextOrderNumber++;
    final order = Order(
      number: number,
      customerId: customer.id,
      customerName: customer.name,
      customerEmail: customer.email,
      placedAt: now,
      status: OrderStatus.paid,
      payment: PaymentMethod.card,
      channel: OrderChannel.online,
      lines: [OrderLine.of(product, qty: 1)],
      shippingCents: 490,
      shipTo: Address(
        name: customer.name,
        line1: '4 Rue des Tilleuls',
        postcode: '69001',
        city: customer.city,
        country: customer.country,
      ),
      events: [
        OrderEvent(kind: OrderEventKind.placed, at: now),
        OrderEvent(kind: OrderEventKind.paid, at: now),
      ],
    );
    _db.orders.add(order);
    _api._emit(NewOrderEvent(order));
    for (final member in _db.staff) {
      if (member.status != StaffStatus.active ||
          !member.role.can(Permission.manageOrders)) {
        continue;
      }
      _api._notify(
        member.id,
        AppNotification(
          id: 'n-${_db.nextId++}',
          kind: NotificationKind.newOrder,
          subject: {'en': order.label, 'fr': order.label, 'ar': order.label},
          at: now,
          read: false,
          route: '/orders/$number',
        ),
      );
    }
    return order;
  }

  /// A teammate, [name], opens [productId] and edits its [field].
  void peerJoins(
    String productId, {
    String name = 'Samir',
    String field = 'description',
  }) => _api.presence(productId).join(name, field: field);

  /// [productId] drops to its low-stock threshold.
  Product stockLow(String productId) {
    final product = _db.productById(productId);
    final low = product.copyWith(
      stock: product.lowStockAt < product.stock
          ? product.lowStockAt
          : product.stock,
    );
    _db.replaceProduct(low);
    _api._emit(StockLowEvent(low));
    for (final member in _db.staff) {
      if (member.status != StaffStatus.active ||
          !member.role.can(Permission.editCatalogue)) {
        continue;
      }
      _api._notify(
        member.id,
        AppNotification(
          id: 'n-${_db.nextId++}',
          kind: NotificationKind.lowStock,
          subject: low.name,
          at: clock.now(),
          read: false,
          route: '/products/$productId',
        ),
      );
    }
    return low;
  }
}
