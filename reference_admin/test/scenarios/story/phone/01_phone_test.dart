import 'package:admin_ui/collection.dart';
import 'package:admin_ui/shell.dart' show SaveBar, Sidebar;
import 'package:admin_ui/theme.dart' show AdminBreakpoint;
import 'package:admin_ui/widgets.dart'
    show Modal, ModalSize, NotificationInbox, Tabs, Tip;
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/fake/seed_accounts.dart';
import 'package:reference_admin/src/frame/navigation.dart';
import 'package:reference_admin/src/keys/access_keys.dart';
import 'package:reference_admin/src/keys/catalogue_keys.dart';
import 'package:reference_admin/src/keys/orders_keys.dart';
import 'package:reference_admin/src/keys/settings_keys.dart';

import '../../../support/harness.dart';

// The app on a phone: one column, navigation in a drawer, lists as cards,
// dialogs full screen, and the keyboard taking half the screen. The folder
// also runs on a tablet, which has the icon rail instead of the drawer: what
// only a phone does is checked where the layout is compact.

void main() {
  scenario('Signing in on a phone', (s) async {
    final shop = await openShop(s, as: null);
    expect(s.breakpoint, isNot(AdminBreakpoint.expanded));

    final fields = find.descendant(
      of: find.byKey(AccessKeys.signInPage),
      matching: find.byType(EditableText),
    );
    await s.enterText(
      fields.at(0),
      demoAccounts.first.$1,
      shot: const Shot('Phone · sign in (keyboard up)'),
    );
    expect(s.keyboard.isUp, isTrue);
    await s.enterText(fields.at(1), demoPassword);
    await s.tap(
      find.text(s.kit.shell.signIn),
      shot: const Shot('Phone · dashboard', tags: ['tour']),
    );
    expect(shop.route, isA<Dashboard>());
    expect(find.byKey(AccessKeys.dashboardPage), findsOneWidget);
  });

  scenario('Getting around on a phone', (s) async {
    final shop = await openShop(s);

    final compact = s.breakpoint.isCompact;
    if (compact) {
      await s.tap(ShellKeys.menu, shot: const Shot('Phone · navigation'));
      expect(find.byKey(ShellKeys.drawer), findsOneWidget);
      // The drawer covers the top bar's mark and heads itself with it,
      // where the bar has it.
      final barMark = find.descendant(
        of: find.byKey(ShellKeys.frame),
        matching: find.byType(ShopMark),
      );
      final drawerMark = find.descendant(
        of: find.byKey(ShellKeys.drawer),
        matching: find.byType(ShopMark),
      );
      expect(drawerMark, findsOneWidget);
      final (bar, drawer) = (
        s.tester.getCenter(barMark),
        s.tester.getCenter(drawerMark),
      );
      expect(drawer.dy, closeTo(bar.dy, 0.5));
      expect(drawer.dx, closeTo(bar.dx, 0.5));
    }
    await s.tap(
      compact
          ? find.descendant(
              of: find.byKey(ShellKeys.drawer),
              matching: find.text(s.strings.shell.navOrders),
            )
          : _railItem(s, Nav.orders),
      shot: const Shot('Phone · orders as cards', tags: ['tour']),
    );
    expect(shop.route, isA<Orders>());
    expect(find.byKey(ShellKeys.drawer), findsNothing);
    if (!compact) return;
    expect(_collectionIn(CollectionViewMode.cards), findsOneWidget);

    // A strip would cut a view's name at the phone's edge: the views are a
    // menu under the active one.
    Finder inViews(String text) => find.descendant(
      of: find.byKey(OrdersKeys.savedViews),
      matching: find.text(text),
    );
    final orders = s.strings.orders;
    expect(
      find.descendant(
        of: find.byKey(OrdersKeys.savedViews),
        matching: find.byType(Tabs),
      ),
      findsNothing,
    );
    await s.tap(
      inViews(orders.viewAll),
      shot: const Shot('Phone · saved views'),
    );
    await s.tap(find.text(orders.viewToShip).last);
    expect(inViews(orders.viewToShip), findsOneWidget);
    expect(inViews(orders.viewAll), findsNothing);

    await s.tap(OrdersKeys.filtersButton, shot: const Shot('Phone · filters'));
    expect(find.byKey(OrdersKeys.filterSheet), findsOneWidget);
  });

  scenario('An order on a phone', (s) async {
    final shop = await openShop(
      s,
      at: const OrderDetail(1042),
      shot: const Shot('Phone · order'),
    );
    expect(find.byKey(OrdersKeys.orderPage), findsOneWidget);

    await s.tap(OrdersKeys.more, shot: const Shot('Phone · order actions'));
    await s.tap(
      find.text(s.strings.orders.refund).last,
      shot: const Shot('Phone · refund'),
    );
    expect(find.byKey(OrdersKeys.refundDialog), findsOneWidget);
    if (s.breakpoint.isCompact) {
      expect(
        find.byWidgetPredicate(
          (w) => w is Modal && w.size == ModalSize.fullscreen,
        ),
        findsOneWidget,
      );
    }
    expect(shop.calls.countOf(Endpoint.refund), 0);
  });

  scenario('Editing a product on a phone', (s) async {
    final shop = await openShop(
      s,
      at: const ProductDetail('p-12'),
      shot: const Shot('Phone · product'),
    );

    await s.scrollTo(CatalogueKeys.description);
    await s.enterText(
      _editable(CatalogueKeys.description),
      'A soft, arching fern for a bright bathroom.',
      shot: const Shot(
        'Phone · unsaved changes (keyboard up, save bar visible above it)',
      ),
    );
    expect(s.keyboard.isUp, isTrue);
    final saveBar = s.tester.getRect(find.byType(SaveBar));
    final keyboardTop =
        s.tester.view.physicalSize.height / s.tester.view.devicePixelRatio -
        s.keyboard.height;
    expect(saveBar.bottom, lessThanOrEqualTo(keyboardTop + 0.5));

    await s.keyboard.dismiss();
    await s.tap(
      find.descendant(
        of: find.byKey(CatalogueKeys.localeTabs),
        // Language codes, the same in every language.
        matching: find.text('AR'),
      ),
      shot: const Shot('Phone · product in Arabic lane'),
    );
    expect(shop.route, const ProductDetail('p-12'));
    expect(shop.calls.countOf(Endpoint.saveProduct), 0);
  });

  scenario('Notifications on a phone', (s) async {
    final shop = await openShop(s);
    final panelTitle = find.text(s.strings.shell.notifications);
    expect(panelTitle, findsNothing);
    await s.tap(ShellKeys.bell, shot: const Shot('Phone · notifications'));
    // Read once as the frame mounted; the bell opens what it has.
    expect(shop.calls.countOf(Endpoint.notifications), 1);
    expect(panelTitle, findsOneWidget);
    final newest = shop.db.notifications[shop.api.currentStaff!.id]!.first;
    final item = find.text(
      s.strings.shell.notificationTitle(
        newest.kind,
        inLanguage(newest.subject, s.language),
      ),
    );
    expect(item, findsOneWidget);
    final view = s.tester.view;
    final width = view.physicalSize.width / view.devicePixelRatio;
    final rect = s.tester.getRect(item);
    expect(
      rect.left >= 0 && rect.right <= width,
      isTrue,
      reason: 'the panel fits the phone ($rect in $width)',
    );
    if (s.breakpoint.isCompact) {
      // A phone opens the inbox in a sheet as wide as the screen.
      expect(s.tester.getSize(find.byType(NotificationInbox)).width, width);
    }
  });

  scenario('Appearance on a phone', (s) async {
    final shop = await openShop(s);
    await navTo(s, Nav.settings, shot: const Shot('Phone · appearance'));
    expect(shop.route, const SettingsAppearance());
    expect(find.byKey(SettingsKeys.theme), findsOneWidget);
    expect(find.byKey(ShellKeys.drawer), findsNothing);
  });

  scenario('A dirty form survives the drawer', (s) async {
    final shop = await openShop(s, at: const ProductDetail('p-12'));
    await s.enterText(_editable(CatalogueKeys.name), 'Boston fern, large');

    final compact = s.breakpoint.isCompact;
    if (compact) {
      await s.tap(ShellKeys.menu);
      expect(find.byKey(ShellKeys.drawer), findsOneWidget);
    }
    await s.tap(
      compact
          ? find.descendant(
              of: find.byKey(ShellKeys.drawer),
              matching: find.text(s.strings.shell.navOrders),
            )
          : _railItem(s, Nav.orders),
      shot: const Shot('Phone · leave without saving?'),
    );
    expect(find.text(s.kit.shell.discardChangesTitle), findsOneWidget);

    // Staying keeps the drawer open over the untouched form.
    await s.tap(find.text(_cancel(s)));
    expect(shop.route, const ProductDetail('p-12'));
    if (compact) {
      expect(find.byKey(ShellKeys.drawer), findsOneWidget);
      await s.back();
    }
    expect(find.byKey(ShellKeys.drawer), findsNothing);
    expect(find.text('Boston fern, large'), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.saveProduct), 0);
  });
}

/// A tablet's rail item for [nav].
// FRICTION(F-016): the rail's labels are in a kit Tip, which find.byTooltip
// does not see.
Finder _railItem(ScenarioTester s, Nav nav) => find.descendant(
  of: find.byType(Sidebar),
  matching: find.byWidgetPredicate(
    (w) => w is Tip && w.message == navLabel(s.strings.shell, nav),
  ),
);

Finder _collectionIn(CollectionViewMode mode) =>
    find.byWidgetPredicate((w) => w is Collection && w.viewMode == mode);

/// The first text input of the field keyed [field]: a translated field's
/// lane in the language shown.
Finder _editable(Key field) => find
    .descendant(of: find.byKey(field), matching: find.byType(EditableText))
    .first;

/// The leave dialog's cancel, which the kit words through Material's own
/// localizations.
String _cancel(ScenarioTester s) =>
    MaterialLocalizations.of(s.tester.element(find.byType(Navigator).first))
        .cancelButtonLabel;
