import 'dart:math';

import 'package:admin_ui/assets.dart';
import 'package:admin_ui/collection.dart';
import 'package:flutter/widgets.dart' show AssetImage;

import '../api/shop_api.dart';
import 'seed_accounts.dart';
import 'seed_vocabulary.dart';

/// Which shop the fake starts with.
enum DemoSeed {
  /// A shop two months into trading: the story and the screenshots.
  demo,

  /// A shop that has just signed up: no catalogue, no orders, setup to do.
  empty,
}

/// Every table of the fake shop, shared by all its endpoints, so one call's
/// effects show in the others: a refund moves the dashboard, a mention adds
/// a notification.
class FakeShopDb {
  final products = <Product>[];
  final categories = <Category>[];
  final suppliers = <Supplier>[];
  final customers = <Customer>[];
  final orders = <Order>[];

  /// By product id, oldest version first.
  final revisions = <String, List<ProductRevision>>{};
  final staff = <StaffMember>[];

  /// Sign-in email to password.
  final accounts = <String, String>{};
  final invites = <Invite>[];
  final assets = <Asset>[];

  /// By staff id, newest first.
  final notifications = <String, List<AppNotification>>{};

  /// By staff id.
  final prefs = <String, UserPrefs>{};

  /// By collection key.
  final savedViews = <String, List<SavedView>>{};
  ShopSettings shop = ShopSettings.blank;

  /// Wrong passwords in a row, by email.
  final failedSignIns = <String, int>{};

  int nextOrderNumber = 1;
  int nextProductNumber = 1;

  /// Ids minted at run time start past every seeded one.
  int nextId = 100;

  Product productById(String id) => products.firstWhere(
    (p) => p.id == id,
    orElse: () => throw const ShopError.notFound(),
  );

  Order orderByNumber(int number) => orders.firstWhere(
    (o) => o.number == number,
    orElse: () => throw const ShopError.notFound(),
  );

  Customer customerById(String id) => customers.firstWhere(
    (c) => c.id == id,
    orElse: () => throw const ShopError.notFound(),
  );

  StaffMember staffById(String id) => staff.firstWhere(
    (s) => s.id == id,
    orElse: () => throw const ShopError.notFound(),
  );

  void replaceProduct(Product product) {
    final i = products.indexWhere((p) => p.id == product.id);
    products[i] = product;
  }

  void replaceOrder(Order order) {
    final i = orders.indexWhere((o) => o.number == order.number);
    orders[i] = order;
  }

  void replaceStaff(StaffMember member) {
    final i = staff.indexWhere((s) => s.id == member.id);
    staff[i] = member;
  }

  /// Every table as plain JSON, in a fixed order: what the seed digest in
  /// `test/unit/model_test.dart` hashes.
  Map<String, Object?> dump() => {
    'shop': shop.toJson(),
    'products': [for (final p in products) p.toJson()],
    'categories': [
      for (final c in categories)
        {'id': c.id, 'name': c.name, 'parentId': c.parentId},
    ],
    'suppliers': [for (final s in suppliers) '${s.id} ${s.name} ${s.email}'],
    'customers': [for (final c in customers) c.toJson()],
    'orders': [for (final o in orders) o.toJson()],
    'revisions': [
      for (final entry in revisions.entries)
        for (final r in entry.value)
          '${r.productId}@${r.version} ${r.at.toIso8601String()} ${r.by} ${r.snapshot.priceCents}',
    ],
    'staff': [for (final s in staff) s.toJson()],
    'invites': [
      for (final i in invites)
        '${i.token} ${i.email} ${i.expiresAt.toIso8601String()}',
    ],
    'assets': [
      for (final a in assets)
        '${a.id} ${a.name} ${a.bytes} ${a.usageCount} ${a.alt}',
    ],
    'notifications': [
      for (final entry in notifications.entries)
        for (final n in entry.value) {'to': entry.key, ...n.toJson()},
    ],
    'savedViews': [
      for (final entry in savedViews.entries)
        for (final v in entry.value) '${entry.key}/${v.id} ${v.name}',
    ],
  };
}

/// Builds the shop for [seed], every date placed relative to [now].
///
/// Deterministic: one `Random(20260101)`, sequential ids, and iteration over
/// lists only. `test/unit/model_test.dart` pins the counts and a digest of
/// [FakeShopDb.dump], so a reshuffle shows up as a diff.
FakeShopDb seedShop(DemoSeed seed, {required DateTime now}) {
  final db = FakeShopDb();
  final random = Random(20260101);
  _seedStaff(db, now);
  _seedViews(db);
  if (seed == DemoSeed.empty) return db;

  db.shop = const ShopSettings(
    name: 'Potting Shed',
    supportEmail: 'hello@example.com',
    currency: 'EUR',
    taxRatePercent: 20,
    languages: ['en', 'fr', 'ar'],
    shippingZones: [
      ShippingZone(name: 'Home', countries: ['FR'], rateCents: 490),
      ShippingZone(
        name: 'Neighbours',
        countries: ['BE', 'LU', 'CH', 'DE'],
        rateCents: 890,
      ),
      ShippingZone(
        name: 'Rest of Europe',
        countries: ['NL', 'PT', 'AT'],
        rateCents: 1290,
      ),
    ],
    setupComplete: true,
  );
  _seedCatalogueReference(db);
  _seedAssets(db);
  _seedProducts(db, random, now);
  _seedRevisions(db, random, now);
  _seedCustomers(db, random, now);
  _seedOrders(db, random, now);
  _seedNotifications(db, now);
  return db;
}

Translated _words(Words w) => {'en': w.en, 'fr': w.fr, 'ar': w.ar};

String _pad(int n, [int width = 2]) => '$n'.padLeft(width, '0');

void _seedStaff(FakeShopDb db, DateTime now) {
  final demoByRole = {for (final (email, role) in demoAccounts) role: email};
  for (final (i, (name, roleName, statusName, token)) in staffWords.indexed) {
    final role = Role.values.byName(roleName);
    final status = StaffStatus.values.byName(statusName);
    final demoEmail = status == StaffStatus.active
        ? demoByRole.remove(roleName)
        : null;
    final email =
        demoEmail ?? '${name.toLowerCase().replaceAll(' ', '.')}@example.com';
    final member = StaffMember(
      id: 's-${_pad(i + 1)}',
      name: name,
      email: email,
      role: role,
      status: status,
      lastActiveAt: status == StaffStatus.active
          ? now.subtract(Duration(hours: 2 + i * 7))
          : null,
    );
    db.staff.add(member);
    if (status == StaffStatus.active) db.accounts[email] = demoPassword;
    if (token != null) {
      db.invites.add(
        Invite(
          token: token,
          email: email,
          name: name,
          role: role,
          invitedBy: staffWords.first.$1,
          expiresAt: token == 'invite-old'
              ? now.subtract(const Duration(days: 3))
              : now.add(const Duration(days: 6)),
        ),
      );
    }
  }
}

void _seedViews(FakeShopDb db) {
  db.savedViews[CollectionKeys.orders] = [
    const SavedView(
      id: 'orders-all',
      name: 'All',
      scope: SavedViewScope.shared,
      isDefault: true,
      state: ViewState(sortKey: OrderFields.placedAt, ascending: false),
    ),
    const SavedView(
      id: 'orders-to-ship',
      name: 'To ship',
      scope: SavedViewScope.shared,
      position: 1,
      state: ViewState(
        filters: [BoolFilter(OrderFields.toShip, true)],
        sortKey: OrderFields.placedAt,
        ascending: true,
      ),
    ),
    const SavedView(
      id: 'orders-refunds',
      name: 'Refund requests',
      scope: SavedViewScope.shared,
      position: 2,
      state: ViewState(
        filters: [BoolFilter(OrderFields.refundRequested, true)],
        sortKey: OrderFields.placedAt,
        ascending: false,
      ),
    ),
  ];
  db.savedViews[CollectionKeys.products] = [
    const SavedView(
      id: 'products-low-stock',
      name: 'Low stock',
      scope: SavedViewScope.shared,
      state: ViewState(
        filters: [BoolFilter(ProductFields.lowStock, true)],
        sortKey: ProductFields.stock,
      ),
    ),
    const SavedView(
      id: 'products-missing-translations',
      name: 'Missing translations',
      scope: SavedViewScope.shared,
      position: 1,
      state: ViewState(
        filters: [BoolFilter(ProductFields.missingTranslation, true)],
      ),
    ),
    const SavedView(
      id: 'products-drafts',
      name: 'Drafts',
      scope: SavedViewScope.shared,
      position: 2,
      state: ViewState(
        filters: [
          OptionsFilter(ProductFields.status, {'draft'}),
        ],
      ),
    ),
  ];
}

void _seedCatalogueReference(FakeShopDb db) {
  for (final c in categoryWords) {
    db.categories.add(
      Category(id: c.id, name: _words(c.name), parentId: c.parent),
    );
  }
  for (final (i, (name, country, terms)) in supplierWords.indexed) {
    db.suppliers.add(
      Supplier(
        id: 'sup-${_pad(i + 1)}',
        name: name,
        email: 'orders@${name.split(' ').first.toLowerCase()}.example.com',
        country: country,
        terms: terms,
      ),
    );
  }
}

/// Assets m-01 … m-40, one per [mediaPhotos] entry. The last
/// [spareMediaPhotos] are on no product; every fourth one from m-03 has no
/// Arabic alt text.
void _seedAssets(FakeShopDb db) {
  for (final (i, photo) in mediaPhotos.indexed) {
    final caption = photo.caption;
    final file = photo.take * MediaSubject.values.length + photo.subject.index;
    db.assets.add(
      Asset(
        id: 'm-${_pad(i + 1)}',
        name: '${_slug(caption.en)}.png',
        bytes: 40000 + ((i * 7919) % 180000),
        thumbnail: AssetImage('assets/media/${_pad(file + 1)}.png'),
        width: 480,
        height: 360,
        alt: {
          'en': caption.en,
          'fr': caption.fr,
          if (i % 4 != 2) 'ar': caption.ar,
        },
      ),
    );
  }
}

String _slug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

const _drafts = {5, 17, 23, 31, 38, 44, 52, 58};
const _archived = {9, 27, 41, 56};
const _lowStock = {3, 8, 14, 20, 26, 33, 39, 47, 55};
const _missingArabic = {6, 19, 29, 43, 50};
const _missingFrench = {22, 36};
const _noPhotos = {9, 21, 35, 48, 60};

/// Which photos each product carries: pictures of its own subject. The
/// Boston fern has three takes of a fern; the others share their subject's
/// photos in turn, one or two each, so every photo but the spares is used.
Map<int, List<String>> _dealPhotos(Random random) {
  final pools = <MediaSubject, List<String>>{};
  for (final (i, photo) in mediaPhotos.indexed) {
    if (i >= mediaPhotos.length - spareMediaPhotos) break;
    (pools[photo.subject] ??= []).add('m-${_pad(i + 1)}');
  }
  const fern = ['m-01', 'm-05', 'm-10'];
  final bySubject = <MediaSubject, List<int>>{};
  for (var n = 1; n <= 60; n++) {
    if (n == 12 || _noPhotos.contains(n)) continue;
    final subject = productSubjects[(n - 1) % productWords.length];
    (bySubject[subject] ??= []).add(n);
  }
  final photos = <int, List<String>>{12: fern};
  for (final subject in MediaSubject.values) {
    final pool = pools[subject] ?? const [];
    final products = bySubject[subject] ?? const [];
    for (final (j, n) in products.indexed) {
      final first = pool[j % pool.length];
      // A pool larger than its products hands the rest out as second photos.
      final extra = j + products.length < pool.length
          ? pool[j + products.length]
          : pool.length > 1 && random.nextInt(3) == 0
          ? pool[(j + 1) % pool.length]
          : null;
      photos[n] = [first, ?extra];
    }
  }
  return photos;
}

void _seedProducts(FakeShopDb db, Random random, DateTime now) {
  final owner = db.staff.first.name;
  final photos = _dealPhotos(random);
  // By noun: the larger run costs about half as much again.
  final basePrices = <int>[];
  for (var n = 1; n <= 60; n++) {
    final (noun, categoryId) = productWords[(n - 1) % productWords.length];
    final large = n > productWords.length;
    final category = categoryWords.firstWhere((c) => c.id == categoryId);
    var name = <String, String>{
      'en': large ? '${noun.en} ${largeWord.en}' : noun.en,
      'fr': large ? '${noun.fr} ${largeWord.fr}' : noun.fr,
      'ar': large ? '${noun.ar} ${largeWord.ar}' : noun.ar,
    };
    var description = _words(category.blurb);
    if (_missingArabic.contains(n)) {
      name = {...name}..remove('ar');
      description = {...description}..remove('ar');
    }
    if (_missingFrench.contains(n)) {
      name = {...name}..remove('fr');
      description = {...description}..remove('fr');
    }
    final nounIndex = (n - 1) % productWords.length;
    final int price;
    if (large) {
      price = (basePrices[nounIndex] * 3 ~/ 2 ~/ 100) * 100 + 90;
    } else {
      price = n == 12 ? 2450 : (6 + random.nextInt(60)) * 50 - 10;
      basePrices.add(price);
    }
    final lowStockAt = 5;
    final stock = _lowStock.contains(n)
        ? random.nextInt(lowStockAt + 1)
        : lowStockAt + 3 + random.nextInt(40);
    final status = _drafts.contains(n)
        ? ProductStatus.draft
        : _archived.contains(n)
        ? ProductStatus.archived
        : ProductStatus.active;
    final isPlant =
        categoryId == 'cat-01' ||
        categoryId == 'cat-02' ||
        categoryId == 'cat-03' ||
        categoryId == 'cat-04';
    final care = isPlant
        ? {
            for (final entry in careWords.entries)
              entry.key: entry.value[random.nextInt(entry.value.length)],
          }
        : <String, String>{};
    final variants = n == 12
        ? const [
            Variant(
              size: '12 cm',
              skuSuffix: 'S',
              priceDeltaCents: 0,
              stock: 14,
            ),
            Variant(
              size: '17 cm',
              skuSuffix: 'L',
              priceDeltaCents: 1000,
              stock: 6,
            ),
          ]
        : isPlant && random.nextInt(3) == 0
        ? [
            Variant(
              size: '12 cm',
              skuSuffix: 'S',
              priceDeltaCents: 0,
              stock: random.nextInt(20),
            ),
            Variant(
              size: '19 cm',
              skuSuffix: 'L',
              priceDeltaCents: 800,
              stock: random.nextInt(10),
            ),
          ]
        : const <Variant>[];
    db.products.add(
      Product(
        id: 'p-${_pad(n)}',
        sku: 'PS-${_pad(n, 4)}',
        name: name,
        description: description,
        categoryId: categoryId,
        tags: {
          productTags[random.nextInt(productTags.length)],
          if (random.nextBool())
            productTags[random.nextInt(productTags.length)],
        }.toList(),
        priceCents: price,
        compareAtCents: random.nextInt(6) == 0 ? price + 500 : null,
        stock: stock,
        lowStockAt: lowStockAt,
        status: status,
        featured: n == 12 || random.nextInt(8) == 0,
        availableFrom: status == ProductStatus.draft
            ? now.add(Duration(days: 14 + n))
            : null,
        labelColor: labelColors[n % labelColors.length],
        care: care,
        variants: variants,
        photoIds: photos[n] ?? const [],
        supplierId: 'sup-${_pad(n % 8 + 1)}',
        revision: 1,
        updatedAt: now.subtract(Duration(days: 1 + (n * 5) % 50, hours: n)),
        updatedBy: owner,
      ),
    );
  }
  db.nextProductNumber = 61;
  for (var i = 0; i < db.assets.length; i++) {
    final asset = db.assets[i];
    final uses = db.products.where((p) => p.photoIds.contains(asset.id)).length;
    db.assets[i] = Asset(
      id: asset.id,
      name: asset.name,
      bytes: asset.bytes,
      thumbnail: asset.thumbnail,
      width: asset.width,
      height: asset.height,
      alt: asset.alt,
      usageCount: uses,
    );
  }
}

/// 3 to 6 revisions on p-01 … p-20; five on the Boston fern. Each older
/// version had a lower price and, before version 3, no French description.
void _seedRevisions(FakeShopDb db, Random random, DateTime now) {
  final editors = [for (final s in db.staff.take(5)) s.name];
  for (var n = 1; n <= 20; n++) {
    final product = db.productById('p-${_pad(n)}');
    final count = n == 12 ? 5 : 3 + n % 4;
    final history = <ProductRevision>[];
    for (var v = 1; v <= count; v++) {
      final age = count - v;
      final snapshot = v == count
          ? product.copyWith(revision: v)
          : product.copyWith(
              revision: v,
              priceCents: product.priceCents - age * 100,
              stock: product.stock + age * 3,
              description: v < 3
                  ? ({...product.description}..remove('fr'))
                  : product.description,
              tags: v < 2 ? const [] : product.tags,
              updatedAt: product.updatedAt.subtract(Duration(days: age * 6)),
              updatedBy: editors[(n + v) % editors.length],
            );
      history.add(
        ProductRevision(
          productId: product.id,
          version: v,
          at: snapshot.updatedAt,
          by: snapshot.updatedBy,
          snapshot: snapshot,
        ),
      );
    }
    db.revisions[product.id] = history;
    db.replaceProduct(product.copyWith(revision: count));
  }
}

/// 120 customers, c-001 the oldest, signing up faster as the shop grows:
/// about a fifth of them in the last two months.
void _seedCustomers(FakeShopDb db, Random random, DateTime now) {
  for (var i = 1; i <= 120; i++) {
    final age = 420 * pow((120 - i) / 119, 1.3) + 1;
    final arabic = i % 6 == 2;
    String name;
    String emailName;
    if (i == 7) {
      name = 'Layla Haddad';
      emailName = 'layla.haddad';
    } else if (arabic) {
      final f = random.nextInt(arabicFirstNames.length);
      final l = random.nextInt(arabicLastNames.length);
      name = '${arabicFirstNames[f]} ${arabicLastNames[l]}';
      emailName = '${arabicFirstLatin[f]}.${arabicLastLatin[l]}$i';
    } else {
      final f = latinFirstNames[random.nextInt(latinFirstNames.length)];
      final l = latinLastNames[random.nextInt(latinLastNames.length)];
      name = '$f $l';
      emailName = '${_ascii(f)}.${_ascii(l)}$i';
    }
    final (city, country) = places[random.nextInt(places.length)];
    db.customers.add(
      Customer(
        id: 'c-${_pad(i, 3)}',
        name: name,
        email: '${emailName.toLowerCase()}@example.com',
        city: city,
        country: country,
        tags: [if (i % 11 == 0 || i == 7) 'vip', if (i % 17 == 0) 'wholesale'],
        createdAt: now.subtract(
          Duration(minutes: (age * 24 * 60).round() + random.nextInt(600)),
        ),
      ),
    );
  }
}

String _ascii(String s) => s
    .replaceAll('é', 'e')
    .replaceAll('è', 'e')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u');

/// 420 orders over the last 180 days, busier as the shop grows (twice as
/// many a day now as six months ago), numbered in order so that #1042, the
/// story's order, is the eleventh newest. Counting back from the newest: 6
/// pending, then 21 to ship (12 paid with #1042, 5 picking, 4 packed), then
/// shipped, then delivered; 4 cancelled and 6 partly refunded among the
/// older ones, 3 refunds requested. Each order's customer had signed up by
/// then.
void _seedOrders(FakeShopDb db, Random random, DateTime now) {
  const total = 420;
  const days = 180;
  const first = 1042 - (total - 1 - 10);
  const cancelled = {60, 110, 160, 220};
  const refunded = {70, 90, 130, 170, 190, 230};
  const refundRequests = {75, 95, 140};
  final active = [
    for (final p in db.products)
      if (p.status == ProductStatus.active) p,
  ];
  final staffNames = [
    for (final s in db.staff)
      if (s.status == StaffStatus.active) s.name,
  ];
  final placed = _orderTimes(total, days, now, random);
  for (var i = 0; i < total; i++) {
    final number = first + i;
    final k = total - 1 - i;
    final placedAt = placed[k];
    final signedUp = db.customers
        .where((c) => !c.createdAt.isAfter(placedAt))
        .toList();
    final customer = number == 1042
        ? db.customerById('c-007')
        : signedUp[random.nextInt(signedUp.length)];
    final status = number == 1042
        ? OrderStatus.paid
        : switch (k) {
            < 3 => OrderStatus.pending,
            < 15 => OrderStatus.paid,
            < 20 => OrderStatus.picking,
            < 24 => OrderStatus.packed,
            _ when cancelled.contains(k) => OrderStatus.cancelled,
            < 46 => OrderStatus.shipped,
            _ => OrderStatus.delivered,
          };
    final lines = number == 1042
        ? [
            OrderLine.of(
              db.productById('p-12'),
              variant: '12 cm',
              qty: 2,
              unitCents: 2450,
            ),
            OrderLine.of(db.productById('p-23'), qty: 1, unitCents: 1850),
            OrderLine.of(db.productById('p-33'), qty: 1, unitCents: 1700),
          ]
        : [
            // Baskets fill up a little as regulars come back.
            for (
              var l = 0, count = 1 + random.nextInt(i < total * 2 ~/ 3 ? 3 : 4);
              l < count;
              l++
            )
              () {
                final product = active[random.nextInt(active.length)];
                return OrderLine.of(product, qty: 1 + random.nextInt(3));
              }(),
          ];
    final subtotal = lines.fold(0, (sum, l) => sum + l.totalCents);
    final shipping = subtotal >= 5000 ? 0 : 490;
    final events = _eventsFor(status, placedAt, staffNames, random);
    final orderTotal = subtotal + shipping;
    final refundedCents =
        refunded.contains(k) && status != OrderStatus.cancelled
        ? (orderTotal ~/ 3 ~/ 10) * 10
        : 0;
    if (refundedCents > 0) {
      events.add(
        OrderEvent(
          kind: OrderEventKind.refunded,
          at: events.last.at.add(const Duration(days: 2)),
          by: staffNames[1],
          detail: '$refundedCents',
        ),
      );
    }
    db.orders.add(
      Order(
        number: number,
        customerId: customer.id,
        customerName: customer.name,
        customerEmail: customer.email,
        placedAt: placedAt,
        status: status,
        payment: i % 5 == 3 ? PaymentMethod.bankTransfer : PaymentMethod.card,
        channel: switch (i % 10) {
          0 || 5 => OrderChannel.marketStall,
          7 => OrderChannel.wholesale,
          _ => OrderChannel.online,
        },
        refundedCents: refundedCents,
        refundRequested: refundRequests.contains(k),
        lines: lines,
        shippingCents: shipping,
        shipTo: Address(
          name: customer.name,
          line1:
              '${1 + random.nextInt(80)} '
              '${streets[random.nextInt(streets.length)]}',
          postcode: '${10000 + random.nextInt(89999)}',
          city: customer.city,
          country: customer.country,
        ),
        events: events,
      ),
    );
  }
  db.nextOrderNumber = first + total;
}

/// When each of [total] orders was placed, newest first, over the last
/// [days] days: a shop that sells about twice as much a day now as at the
/// start, a little more at weekends, and no day like the one before.
List<DateTime> _orderTimes(int total, int days, DateTime now, Random random) {
  final today = DateTime(now.year, now.month, now.day);
  final weights = [
    for (var age = 0; age < days; age++)
      (2 - age / days) *
          (today.subtract(Duration(days: age)).weekday >= DateTime.saturday
              ? 1.3
              : 1.0) *
          (0.7 + random.nextDouble() * 0.6) *
          // Today is under way: its morning so far.
          (age == 0 ? 0.3 : 1.0),
  ];
  final sum = weights.fold(0.0, (a, b) => a + b);
  // Largest remainder, so the counts add up to [total] exactly.
  final exact = [for (final w in weights) w / sum * total];
  final counts = [for (final e in exact) e.floor()];
  final byRemainder = [for (var a = 0; a < days; a++) a]
    ..sort((x, y) {
      final order = (exact[y] - counts[y]).compareTo(exact[x] - counts[x]);
      return order != 0 ? order : x.compareTo(y);
    });
  for (final a in byRemainder.take(total - counts.fold(0, (s, c) => s + c))) {
    counts[a]++;
  }
  final times = <DateTime>[];
  for (var age = 0; age < days; age++) {
    final start = today.subtract(Duration(days: age));
    // Today's orders fall between midnight and a little before now.
    final span = age == 0
        ? now.difference(start) - const Duration(minutes: 25)
        : const Duration(hours: 24);
    final m = counts[age];
    for (var j = 0; j < m; j++) {
      final slot =
          span.inMinutes *
          (m - j - 0.5 + (random.nextDouble() - 0.5) * 0.8) ~/
          m;
      times.add(start.add(Duration(minutes: slot)));
    }
  }
  return times;
}

List<OrderEvent> _eventsFor(
  OrderStatus status,
  DateTime placedAt,
  List<String> staff,
  Random random,
) {
  final events = [OrderEvent(kind: OrderEventKind.placed, at: placedAt)];
  var at = placedAt;
  void step(OrderEventKind kind, int hours, {bool byStaff = true}) {
    at = at.add(Duration(hours: hours));
    events.add(
      OrderEvent(
        kind: kind,
        at: at,
        by: byStaff ? staff[random.nextInt(staff.length)] : null,
      ),
    );
  }

  if (status == OrderStatus.pending) return events;
  step(OrderEventKind.paid, 0, byStaff: false);
  if (status == OrderStatus.cancelled) {
    step(OrderEventKind.cancelled, 5);
    return events;
  }
  if (status == OrderStatus.paid) return events;
  step(OrderEventKind.picking, 3);
  if (status == OrderStatus.picking) return events;
  step(OrderEventKind.packed, 2);
  if (status == OrderStatus.packed) return events;
  step(OrderEventKind.shipped, 20);
  if (status == OrderStatus.shipped) return events;
  step(OrderEventKind.delivered, 48, byStaff: false);
  return events;
}

/// Fifteen notifications for the owner, newest first, the six newest
/// unread. A new-order notice is dated when its order was paid, and points
/// at an order that is paid and waiting to be picked.
void _seedNotifications(FakeShopDb db, DateTime now) {
  final owner = db.staff.first;
  DateTime ago(int hours) => now.subtract(Duration(hours: hours));
  AppNotification lowStock(String productId, int hours) => AppNotification(
    id: '',
    kind: NotificationKind.lowStock,
    subject: db.productById(productId).name,
    at: ago(hours),
    read: false,
    route: '/products/$productId',
  );

  AppNotification order(NotificationKind kind, int number, {int? hours}) =>
      AppNotification(
        id: '',
        kind: kind,
        subject: {'en': '#$number', 'fr': '#$number', 'ar': '#$number'},
        at: hours == null ? db.orderByNumber(number).placedAt : ago(hours),
        read: false,
        route: '/orders/$number',
      );

  final inbox = [
    for (final number in const [1049, 1048, 1047, 1045, 1043, 1040])
      order(NotificationKind.newOrder, number),
    lowStock('p-03', 2),
    lowStock('p-14', 8),
    lowStock('p-20', 30),
    lowStock('p-26', 60),
    lowStock('p-33', 98),
    AppNotification(
      id: '',
      kind: NotificationKind.mention,
      subject: const {'en': '#1042', 'fr': '#1042', 'ar': '#1042'},
      actor: db.staff[1].name,
      at: ago(3),
      read: false,
      route: '/orders/1042',
    ),
    order(NotificationKind.refundRequest, 977, hours: 5),
    order(NotificationKind.refundRequest, 957, hours: 34),
    AppNotification(
      id: '',
      kind: NotificationKind.system,
      subject: const {
        'en': 'Weekly backup',
        'fr': 'Sauvegarde hebdomadaire',
        'ar': 'النسخ الاحتياطي الأسبوعي',
      },
      at: ago(50),
      read: false,
      route: '/',
    ),
  ]..sort((a, b) => b.at.compareTo(a.at));
  db.notifications[owner.id] = [
    for (final (i, n) in inbox.indexed)
      n.copyWith(id: 'n-${_pad(i + 1)}', read: i >= 6),
  ];
}
