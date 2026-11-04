import 'dart:convert';

import 'package:admin_ui/collection.dart';
import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:reference_admin/src/api/shop_api.dart';
import 'package:reference_admin/src/app.dart';
import 'package:reference_admin/src/fake/fake_shop_api.dart';
import 'package:reference_admin/src/fake/seed_accounts.dart';
import 'package:reference_admin/src/routing/route_parser.dart';
import 'package:reference_admin/src/routing/routes.dart';
import 'package:reference_admin/src/services.dart';

/// flutterware's pinned scenario clock, in UTC: the seed is placed relative
/// to it, and UTC has no daylight saving to move a date by the machine's
/// time zone.
final _now = DateTime.utc(2026, 1, 1, 9, 41);

FakeShopApi _shop({DemoSeed seed = DemoSeed.demo, Role? as = Role.owner}) =>
    withClock(Clock.fixed(_now), () {
      final api = FakeShopApi(seed: seed, latency: Latency.none);
      if (as != null) api.adoptSession(api.staffWithRole(as));
      return api;
    });

void main() {
  group('seed', () {
    final db = _shop().db;

    test('holds the counts the story relies on', () {
      final products = db.products;
      expect(products, hasLength(60));
      int withStatus(ProductStatus s) =>
          products.where((p) => p.status == s).length;
      expect(withStatus(ProductStatus.active), 48);
      expect(withStatus(ProductStatus.draft), 8);
      expect(withStatus(ProductStatus.archived), 4);
      expect(products.where((p) => p.isLowStock), hasLength(9));
      expect(
        products.where((p) => p.missingLanguages.isNotEmpty),
        hasLength(7),
      );
      expect(
        products.where((p) => p.missingLanguages.contains('ar')),
        hasLength(5),
      );
      expect(products.where((p) => p.photoIds.isEmpty), hasLength(5));

      expect(db.categories, hasLength(8));
      expect(db.suppliers, hasLength(8));
      expect(db.customers, hasLength(120));
      final arabicScript = RegExp('[؀-ۿ]');
      expect(
        db.customers.where((c) => arabicScript.hasMatch(c.name)).length,
        greaterThanOrEqualTo(15),
      );

      expect(db.orders, hasLength(420));
      expect(db.orders.where((o) => o.status.toShip), hasLength(21));
      expect(db.orders.where((o) => o.partiallyRefunded), hasLength(6));
      expect(
        db.orders.where((o) => o.status == OrderStatus.cancelled),
        hasLength(4),
      );
      expect(db.orders.where((o) => o.refundRequested), hasLength(3));
      final placed = db.orders.map((o) => o.placedAt);
      expect(
        placed.every((d) => _now.difference(d) < const Duration(days: 181)),
        isTrue,
      );

      expect(db.revisions, hasLength(20));
      for (final history in db.revisions.values) {
        expect(history.length, inInclusiveRange(3, 6));
      }

      final staff = db.staff;
      expect(staff.where((s) => s.status == StaffStatus.active), hasLength(7));
      expect(staff.where((s) => s.status == StaffStatus.invited), hasLength(2));
      for (final role in Role.values) {
        expect(staff.where((s) => s.role == role), isNotEmpty);
      }

      expect(db.assets, hasLength(40));
      expect(db.assets.where((a) => a.usageCount == 0), hasLength(6));
      expect(db.assets.where((a) => !a.alt.containsKey('ar')), hasLength(10));

      final inbox = db.notifications.values.expand((n) => n).toList();
      expect(inbox, hasLength(15));
      expect(inbox.where((n) => !n.read), hasLength(6));
      final newOrders = inbox.where((n) => n.kind == NotificationKind.newOrder);
      expect(newOrders, isNotEmpty);
      for (final n in newOrders) {
        final number = int.parse(n.route.split('/').last);
        expect(
          db.orderByNumber(number).status,
          OrderStatus.paid,
          reason: n.route,
        );
      }

      expect(db.savedViews[CollectionKeys.orders]!.map((v) => v.name), [
        'All',
        'To ship',
        'Refund requests',
      ]);
      expect(db.savedViews[CollectionKeys.products]!.map((v) => v.name), [
        'Low stock',
        'Missing translations',
        'Drafts',
      ]);
      expect(db.shop.setupComplete, isTrue);
    });

    test('carries the story fixtures', () {
      final fern = db.productById('p-12');
      expect(fern.name['en'], 'Boston fern');
      expect(fern.status, ProductStatus.active);
      expect(fern.missingLanguages, isEmpty);
      expect(fern.photoIds, hasLength(3));
      expect(fern.variants, hasLength(2));
      expect(db.revisions['p-12'], hasLength(5));
      expect(fern.revision, 5);
      expect(db.products.where((p) => p.sku == 'PS-0007'), hasLength(1));

      expect(db.customerById('c-007').name, 'Layla Haddad');

      final order = db.orderByNumber(1042);
      expect(order.status, OrderStatus.paid);
      expect(order.lines, hasLength(3));
      expect(order.customerId, 'c-007');
      expect(order.totalCents, 8450);

      expect(db.invites.map((i) => i.token), ['invite-7', 'invite-old']);
    });

    test('is the same shop on every run', () {
      final dump = jsonEncode(db.dump());
      expect(jsonEncode(_shop().db.dump()), dump);
      // A reshuffle of the seed moves every picture of the story: when this
      // changes on purpose, update it in the same commit.
      expect(sha1.convert(utf8.encode(dump)).toString(), _seedDigest);
    });

    test('an empty shop has setup to do and nothing to sell', () {
      final empty = _shop(seed: DemoSeed.empty).db;
      expect(empty.shop.setupComplete, isFalse);
      expect(empty.products, isEmpty);
      expect(empty.orders, isEmpty);
      expect(empty.customers, isEmpty);
      expect(empty.staff, hasLength(9));
    });
  });

  group('routes', () {
    test('every route survives a round trip through its URL', () {
      const routes = <AppRoute>[
        ...everyPage,
        SignIn(),
        SignIn(next: OrderDetail(1042)),
        SetPassword('invite-7'),
        Orders(savedView: 'orders-to-ship'),
        Customers(selected: 'c-007'),
        Products(savedView: 'products-low-stock'),
      ];
      for (final route in routes) {
        expect(AppRouteParser.parse(route.uri), route, reason: '${route.uri}');
      }
    });

    for (final (signedIn, url, expected) in [
      (true, '/orders/1042', const OrderDetail(1042)),
      (false, '/team', const SignIn(next: Team())),
    ]) {
      testWidgets(
        'the platform URL opens its page (${signedIn ? 'signed in' : 'signed out'}: $url)',
        (tester) async {
          // What a web deep link or a reload hands the app.
          tester.binding.platformDispatcher.defaultRouteNameTestValue = url;
          addTearDown(
            tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
          );
          final services = AppServices.fake(
            latency: Latency.none,
            signInAs: signedIn ? Role.owner : null,
          );
          await tester.pumpWidget(ReferenceAdminApp(services: services));
          await tester.pump();
          expect(services.router.route, expected);
          await tester.pumpWidget(const SizedBox());
          services.dispose();
        },
      );
    }

    test('an unknown URL is a NotFound', () {
      expect(AppRouteParser.parse(Uri.parse('/nowhere')), isA<NotFound>());
      expect(AppRouteParser.parse(Uri.parse('/orders/abc')), isA<NotFound>());
      expect(AppRouteParser.parse(Uri.parse('/set-password')), isA<NotFound>());
    });
  });

  group('faults, holds and the call log', () {
    test('failNext fails the next call only, and the log says so', () async {
      final api = _shop();
      api.faults.failNext(Endpoint.stats, const ShopError.server());
      await expectLater(
        api.stats(DashboardRange.days7),
        throwsA(isA<ServerError>()),
      );
      await api.stats(DashboardRange.days7);
      expect(api.calls.countOf(Endpoint.stats), 2);
      expect(api.calls.failuresOf(Endpoint.stats), 1);
      expect(api.calls.paths, ['dashboard.stats', 'dashboard.stats']);
    });

    test('a hold keeps the call in flight until released', () async {
      final api = _shop();
      final gate = api.faults.hold(Endpoint.order);
      var done = false;
      final call = api.order(1042).then((_) => done = true);
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse);
      expect(api.inFlight.value, 1);
      gate.release();
      await call;
      expect(api.inFlight.value, 0);
    });

    test('offline fails every call and tells the listeners', () async {
      final api = _shop();
      final states = <bool>[];
      api.connected.listen(states.add);
      api.faults.goOffline();
      expect(api.isConnected, isFalse);
      await expectLater(api.navBadges(), throwsA(isA<OfflineError>()));
      api.faults.goOnline();
      await api.navBadges();
      await Future<void>.delayed(Duration.zero);
      expect(states, [false, true]);
    });
  });

  group('the shop enforces the role matrix', () {
    test('matches the spec', () {
      expect(rolePermissions[Role.owner], Permission.values.toSet());
      expect(
        rolePermissions[Role.manager],
        Permission.values.toSet()..remove(Permission.manageTeam),
      );
      expect(rolePermissions[Role.staff], {
        Permission.editCatalogue,
        Permission.manageOrders,
      });
      expect(rolePermissions[Role.viewer], isEmpty);
    });

    test('a viewer cannot write, even by calling directly', () async {
      final api = _shop(as: Role.viewer);
      await expectLater(
        api.bulkSetStatus([1042], OrderStatus.shipped),
        throwsA(isA<ForbiddenError>()),
      );
      await expectLater(
        api.patchStock('p-12', 3),
        throwsA(isA<ForbiddenError>()),
      );
      expect(api.db.orderByNumber(1042).status, OrderStatus.paid);
    });

    test('staff cannot invite', () async {
      final api = _shop(as: Role.staff);
      await expectLater(
        api.invite('someone@example.com', Role.staff),
        throwsA(isA<ForbiddenError>()),
      );
    });
  });

  group('endpoints', () {
    test('a refund above what is left is refused on the amount', () async {
      final api = _shop();
      await expectLater(
        api.refund(1042, 9000, ''),
        throwsA(
          isA<ValidationError>().having((e) => e.fields, 'fields', {
            'amount': ValidationCodes.tooHigh,
          }),
        ),
      );
      final refunded = await api.refund(1042, 1000, 'Damaged pot');
      expect(refunded.refundedCents, 1000);
      expect(refunded.events.last.kind, OrderEventKind.refunded);
    });

    test('a mention notifies the teammate it names', () async {
      final api = _shop();
      final samir = api.db.staff.firstWhere((s) => s.name == 'Samir Benali');
      await api.addNote(1042, 'Can you check the pot, <@${samir.id}>?');
      final inbox = api.db.notifications[samir.id]!;
      expect(inbox.first.kind, NotificationKind.mention);
      expect(inbox.first.route, '/orders/1042');
    });

    test('shipping can email the customer', () async {
      final api = _shop();
      final order = await api.moveOrder(
        1042,
        OrderStatus.shipped,
        emailCustomer: true,
      );
      expect(order.events.map((e) => e.kind).skip(order.events.length - 2), [
        OrderEventKind.shipped,
        OrderEventKind.emailed,
      ]);
      expect(
        api.db.orderByNumber(1042).events.last.kind,
        OrderEventKind.emailed,
      );
    });

    test('an order moves only the way orders move', () async {
      final api = _shop();
      final cancelled = api.db.orders.firstWhere(
        (o) => o.status == OrderStatus.cancelled,
      );
      final shipped = api.db.orders.firstWhere(
        (o) => o.status == OrderStatus.shipped,
      );
      final refused = throwsA(
        isA<ValidationError>().having((e) => e.fields, 'fields', {
          'status': ValidationCodes.notAllowed,
        }),
      );
      // One order that cannot ship refuses the lot, and nothing changes.
      await expectLater(
        api.bulkSetStatus([1042, cancelled.number], OrderStatus.shipped),
        refused,
      );
      expect(api.db.orderByNumber(1042).status, OrderStatus.paid);
      expect(
        api.db.orderByNumber(cancelled.number).status,
        OrderStatus.cancelled,
      );
      await expectLater(
        api.moveOrder(shipped.number, OrderStatus.pending),
        refused,
      );
      // Back a step within fulfilment is fine; so is shipping from paid.
      await api.moveOrder(1042, OrderStatus.picking);
      await api.moveOrder(1042, OrderStatus.paid);
      await api.bulkSetStatus([1042], OrderStatus.shipped);
      expect(api.db.orderByNumber(1042).status, OrderStatus.shipped);
    });

    test('the demo dashboard opens on a shop that is growing', () {
      return withClock(Clock.fixed(_now), () async {
        final api = _shop();
        final month = await api.stats(DashboardRange.days30);
        expect(month.revenueCents, greaterThan(month.previousRevenueCents));
        expect(month.orders, greaterThan(month.previousOrders));
        expect(month.newCustomers, greaterThan(month.previousNewCustomers));
        final quarter = await api.stats(DashboardRange.days90);
        expect(quarter.previousOrders, greaterThan(0), reason: 'no empty past');
        expect(
          quarter.revenueSeries.where((cents) => cents == 0),
          hasLength(lessThan(5)),
          reason: 'the 90 days are all in the seed',
        );
      });
    });

    test('an order keeps the name and SKU it was bought under', () {
      final api = _shop();
      final line = api.db.orderByNumber(1042).lines.first;
      final fern = api.db.productById('p-12');
      expect(line.productName, fern.name);
      expect(line.sku, fern.sku);
    });

    test('saving alt text replaces it, so a language can be cleared', () async {
      final api = _shop();
      final asset = api.db.assets.firstWhere((a) => a.alt.length == 3);
      await api.assets.updateAlt(asset.id, {'en': asset.alt['en']!});
      expect(api.db.assets.firstWhere((a) => a.id == asset.id).alt.keys, [
        'en',
      ]);
    });

    test('lists filter, search and page server side', () async {
      final api = _shop();
      final toShip = await api.listOrders(
        const CollectionQuery(filters: [BoolFilter(OrderFields.toShip, true)]),
      );
      expect(toShip.total, 21);
      final layla = await api.listCustomers(
        const CollectionQuery(search: 'layla haddad'),
      );
      expect(layla.items.single.id, 'c-007');
    });

    test('signing in locks after five wrong passwords', () async {
      final api = _shop(as: null);
      final email = demoAccounts.first.$1;
      for (var i = 1; i < lockAfterAttempts; i++) {
        await expectLater(
          api.signIn(email, 'wrong'),
          throwsA(
            isA<ValidationError>().having((e) => e.fields, 'fields', {
              'password': ValidationCodes.wrongPassword,
            }),
          ),
        );
      }
      await expectLater(
        api.signIn(email, 'wrong'),
        throwsA(
          isA<ValidationError>().having((e) => e.fields, 'fields', {
            'email': ValidationCodes.locked,
          }),
        ),
      );
      await expectLater(
        api.signIn(email, demoPassword),
        throwsA(isA<ValidationError>()),
      );
    });

    test('an expired invitation says so', () async {
      final api = withClock(Clock.fixed(_now), () => _shop(as: null));
      await withClock(Clock.fixed(_now), () async {
        await expectLater(
          api.inviteInfo('invite-old'),
          throwsA(isA<ExpiredError>()),
        );
        expect((await api.inviteInfo('invite-7')).role, Role.staff);
      });
    });

    test('the CSV export lists every matching order', () async {
      final api = _shop();
      final csv = utf8.decode(
        await api.exportCsv(
          const CollectionQuery(
            filters: [BoolFilter(OrderFields.toShip, true)],
          ),
        ),
      );
      final lines = const LineSplitter().convert(csv);
      expect(lines.first, startsWith('number,placed_at,customer'));
      expect(lines, hasLength(22));
    });
  });
}

const _seedDigest = 'b983551602a7195d28deff654859a88ee2a4c64b';
