import 'package:admin_ui/forms.dart' show ValidationSummary;
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart' show AdminBreakpoint;
import 'package:admin_ui/widgets.dart' show IconAction;
import 'package:flutter/services.dart';
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/keys/access_keys.dart';
import 'package:reference_admin/src/l10n/money.dart';

import '../../../support/harness.dart';

// WP-A: home. The dashboard loading, loaded, over another range and when
// its stats fail; the inbox, a live order and the palette the frame
// carries; and a blank shop set up from its first run.

void main() {
  scenario('The dashboard at a glance', (s) async {
    late Gate gate;
    final shop = await openShop(
      s,
      before: (shop) => gate = shop.faults.hold(Endpoint.stats),
      settle: const Settle.frames(2),
      shot: const Shot('Dashboard · loading'),
    );
    expect(find.byKey(AccessKeys.loading), findsOneWidget);
    gate.release();
    await s.screen('Dashboard', tags: ['tour'], force: true);
    expect(find.byKey(AccessKeys.stats), findsOneWidget);

    // The revenue figure is the fake's own sum over the same 30 days.
    final (from, to) = shop.api.rangeBounds(DashboardRange.days30);
    final revenue = find.byKey(AccessKeys.revenue);
    final shown = formatMoney(
      s.tester.element(revenue),
      shop.api.revenueBetween(from, to),
    );
    expect(
      find.descendant(of: revenue, matching: find.text(shown)),
      findsOneWidget,
    );

    final formats = s.tester.element(revenue).adminFormats;
    await s.tap(
      find.descendant(
        of: find.byKey(AccessKeys.range),
        matching: find.text(
          s.strings.access.rangeSegment(90, formats.integer(90)),
        ),
      ),
      shot: const Shot('Dashboard · last 90 days'),
    );
    expect(
      [
        for (final call in shop.calls.all)
          if (call.endpoint == Endpoint.stats) call.args['range'],
      ],
      ['days30', 'days90'],
      reason: 'one stats call per range',
    );

    await s.tap(ShellKeys.bell, shot: const Shot('Notifications'));
    await s.tap(
      s.kit.inputs.unread,
      shot: const Shot('Notifications · unread'),
    );

    final owner = shop.api.currentStaff!;
    final notification = shop.db.notifications[owner.id]!.firstWhere(
      (n) => !n.read && n.route.startsWith('/orders/'),
    );
    final title = s.strings.shell.notificationTitle(
      notification.kind,
      inLanguage(notification.subject, s.language),
    );
    await s.tap(title, shot: const Shot('Order from a notification'));
    expect(
      shop.route,
      OrderDetail(int.parse(notification.route.split('/').last)),
    );
    expect(
      shop.db.notifications[owner.id]!
          .firstWhere((n) => n.id == notification.id)
          .read,
      isTrue,
    );
    expect(shop.calls.countOf(Endpoint.markRead), 1);
  });

  scenario('A new order arrives while watching', (s) async {
    final shop = await openShop(s);
    final toShip = shop.db.orders.where((o) => o.status.toShip).length;

    final order = await realtime(
      s,
      'New order toast',
      shop.api.simulate.newOrder,
      until: find.text(s.strings.shell.newOrderTitle),
    );
    expect(shop.db.orders.where((o) => o.number == order.number), hasLength(1));
    expect(shop.db.orders.where((o) => o.status.toShip), hasLength(toShip + 1));

    await s.tap(s.strings.shell.view, shot: const Shot('Order from the toast'));
    expect(shop.route, OrderDetail(order.number));
    // The dashboard heard it too, and asked again.
    expect(shop.calls.countOf(Endpoint.stats), 2);
    if (s.breakpoint == AdminBreakpoint.expanded) {
      final formats = s.tester.element(find.byType(Sidebar)).adminFormats;
      expect(
        find.descendant(
          of: find.byType(Sidebar),
          matching: find.text(formats.integer(toShip + 1)),
        ),
        findsOneWidget,
        reason: 'the to-ship badge went up by one',
      );
    }
  });

  scenario('A product runs low while watching', (s) async {
    final shop = await openShop(s);
    final owner = shop.api.currentStaff!;
    final unread = shop.db.notifications[owner.id]!.where((n) => !n.read);
    final before = unread.length;

    final low = await realtime(
      s,
      'Low stock toast',
      () => shop.api.simulate.stockLow('p-12'),
      until: find.text(s.strings.shell.stockLowTitle),
    );
    expect(low.stock, low.lowStockAt);
    expect(shop.db.productById('p-12').isLowStock, isTrue);
    expect(unread.length, before + 1, reason: 'the inbox has it too');

    await s.tap(
      s.strings.shell.view,
      shot: const Shot('Product from the low-stock toast'),
    );
    expect(shop.route, const ProductDetail('p-12'));
  });

  scenario('The dashboard when stats fail', (s) async {
    final shop = await openShop(
      s,
      before: (shop) =>
          shop.faults.failNext(Endpoint.stats, const ShopError.server()),
      shot: const Shot('Dashboard · could not load'),
    );
    expect(find.byKey(AccessKeys.statsError), findsOneWidget);
    expect(find.byKey(AccessKeys.stats), findsNothing);

    // ErrorState's retry takes no key (F-008): its word, in the app's
    // language.
    await s.tap(
      find.descendant(
        of: find.byKey(AccessKeys.statsError),
        matching: find.text(s.kit.retry),
      ),
      shot: const Shot('Dashboard · recovered'),
    );
    expect(find.byKey(AccessKeys.stats), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.stats), 2);
    expect(shop.calls.failuresOf(Endpoint.stats), 1);
  });

  scenario('Setting up a brand-new shop', (s) async {
    final shop = await openShop(
      s,
      seed: DemoSeed.empty,
      shot: const Shot('Empty dashboard'),
    );
    expect(find.byKey(AccessKeys.empty), findsOneWidget);
    expect(find.byKey(AccessKeys.range), findsNothing);

    await s.tap(AccessKeys.setUpShop, shot: const Shot('Setup · shop details'));
    expect(shop.route, const Setup());

    // The wizard's buttons take no keys (F-008): their words.
    final next = find.text(s.kit.fields.wizardNext);
    await s.tap(next, shot: const Shot('Setup · fix the highlighted fields'));
    expect(
      find.descendant(
        of: find.byKey(AccessKeys.shopName),
        matching: find.text(s.kit.fields.valueRequired),
      ),
      findsOneWidget,
    );
    expect(find.byKey(AccessKeys.zones), findsNothing);

    await s.enterText(AccessKeys.shopName, 'Leaf & Loam');
    await s.enterText(AccessKeys.supportEmail, 'hello@example.com');
    await s.tap(next);
    expect(find.byKey(AccessKeys.zones), findsOneWidget);

    // A shop ships somewhere: with its only zone removed, Next stays and
    // the list says why.
    final access = s.strings.access;
    await s.tap(
      find.byWidgetPredicate(
        (w) =>
            w is IconAction &&
            w.label == s.kit.removeItem(access.zoneItem('', 0)),
      ),
    );
    await s.tap(next);
    expect(
      find.descendant(
        of: find.byKey(AccessKeys.zones),
        matching: find.text(access.zonesRequired),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ValidationSummary),
        matching: find.textContaining(access.zonesRequired),
      ),
      findsOneWidget,
    );
    expect(find.byKey(AccessKeys.review), findsNothing);
    await s.tap(access.addZone);
    expect(find.text(access.zonesRequired), findsNothing);

    await s.enterText(AccessKeys.zoneName(0), 'Home');
    await _addTag(s, AccessKeys.zoneCountries(0), 'FR');
    await s.enterText(AccessKeys.zoneRate(0), '5');
    await s.tap(s.strings.access.addZone);
    await s.enterText(AccessKeys.zoneName(1), 'Neighbours');
    await _addTag(s, AccessKeys.zoneCountries(1), 'BE');
    await _addTag(s, AccessKeys.zoneCountries(1), 'LU');
    await s.enterText(
      AccessKeys.zoneRate(1),
      '9',
      shot: const Shot('Setup · shipping zones'),
    );

    await s.tap(next, shot: const Shot('Setup · review'));
    expect(find.byKey(AccessKeys.review), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.saveShop), 0);
    expect(shop.calls.countOf(Endpoint.completeSetup), 0);

    await s.tap(
      s.strings.access.finishSetup,
      shot: const Shot('Shop ready', tags: ['tour']),
    );
    expect(find.byKey(AccessKeys.ready), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.completeSetup), 1);
    expect(shop.calls.countOf(Endpoint.saveShop), 0);
    expect(shop.db.shop.setupComplete, isTrue);
    expect(shop.db.shop.name, 'Leaf & Loam');
    expect(
      find.descendant(
        of: find.byType(TopBar),
        matching: find.text('Leaf & Loam'),
      ),
      findsOneWidget,
      reason: 'the header names the shop once setup has',
    );
    expect(shop.db.shop.shippingZones, const [
      ShippingZone(name: 'Home', countries: ['FR'], rateCents: 500),
      ShippingZone(name: 'Neighbours', countries: ['BE', 'LU'], rateCents: 900),
    ]);

    await s.tap(AccessKeys.goToDashboard);
    expect(shop.route, const Dashboard());
  });

  scenario('Jumping with the command palette', (s) async {
    final shop = await openShop(s);
    final name = inLanguage(shop.db.productById('p-12').name, s.language);
    // The dashboard's best sellers list it too, under the palette.
    final fern = find.text(name).hitTestable();

    await pressShortcut(s, LogicalKeyboardKey.keyK, shot: 'Command palette');
    await searchIn(
      s,
      find.byType(EditableText).last,
      'boston',
      until: fern,
      shot: const Shot('Command palette · results'),
    );
    expect(shop.calls.countOf(Endpoint.search), 1);

    await s.tap(fern, shot: const Shot('Product from the palette'));
    expect(shop.route, const ProductDetail('p-12'));
    expect(shop.route.uri.path, '/products/p-12');
  });

  scenario("Changing the shop's settings", (s) async {
    final shop = await openShop(
      s,
      at: const SettingsShop(),
      shot: const Shot('Shop settings'),
    );
    final before = shop.db.shop;

    await s.enterText(
      AccessKeys.supportEmail,
      'care@example.com',
      shot: const Shot('Shop settings · unsaved changes'),
    );

    shop.faults.failNext(Endpoint.saveShop, const ShopError.server());
    await pressShortcut(
      s,
      LogicalKeyboardKey.keyS,
      shot: 'Shop settings · could not save',
    );
    expect(shop.calls.failuresOf(Endpoint.saveShop), 1);
    expect(shop.db.shop.supportEmail, before.supportEmail);

    final bar = find.byKey(AccessKeys.shopSaveBar);
    final save = MaterialLocalizations.of(s.tester.element(bar))
        .saveButtonLabel;
    await s.tap(
      find.descendant(of: bar, matching: find.text(save)),
      shot: const Shot('Shop settings · saved'),
    );
    expect(shop.calls.countOf(Endpoint.saveShop), 2);
    expect(shop.db.shop.supportEmail, 'care@example.com');
    expect(shop.db.shop.shippingZones, before.shippingZones);
  });
}

/// Types [tag] into the tags field [field] and commits it, as Enter does.
// FRICTION(T-001): no submit (Enter) verb either; the tag is committed
// through the raw text-input channel.
Future<void> _addTag(ScenarioTester s, Key field, String tag) async {
  await s.enterText(field, tag);
  await s.tester.testTextInput.receiveAction(TextInputAction.done);
  await s.settle();
}
