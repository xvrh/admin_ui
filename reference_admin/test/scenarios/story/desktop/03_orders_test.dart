import 'dart:convert';

import 'package:admin_ui/collection.dart';
import 'package:admin_ui/shell.dart' show PageHeader;
import 'package:admin_ui/widgets.dart'
    show Check, IconAction, Listbox, ListboxOption, Modal;
import 'package:clock/clock.dart';
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/keys/orders_keys.dart';
import 'package:reference_admin/src/screens/orders/orders_screen.dart'
    show CsvPreview;

import '../../../support/harness.dart';

// The order queue: filters and saved views, a bulk change with its undo,
// the board, search, the row menu and the customer card, the CSV export,
// then one order's refund and a note that mentions a teammate.

void main() {
  scenario('Working the order queue', (s) async {
    final shop = await openShop(
      s,
      at: const Orders(),
      shot: const Shot('Orders', tags: ['tour']),
    );
    expect(find.byKey(OrdersKeys.row(_newest(shop).number)), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.listViews), 1);
    // FRICTION(F-202): read once as the controller is made, once more as the
    // default view applies.
    expect(shop.calls.countOf(Endpoint.listOrders), 2);

    await _pickFilter(s, s.strings.orders.columnStatus, [
      s.strings.shell.orderStatus(OrderStatus.paid),
    ]);
    await _closePopover(s, shot: const Shot('Orders · paid'));
    expect(_lastList(shop)['filters'], [OrderFields.status]);

    await s.tap(
      find.descendant(
        of: find.byType(SavedViewsBar),
        matching: find.text(s.strings.orders.viewToShip),
      ),
      shot: const Shot('Orders · to ship'),
    );
    final toShip = [
      for (final o in shop.db.orders)
        if (o.status.toShip) o,
    ]..sort((a, b) => a.placedAt.compareTo(b.placedAt));
    expect(_lastList(shop)['filters'], [OrderFields.toShip]);
    expect(find.byKey(OrdersKeys.row(toShip.first.number)), findsOneWidget);

    // The first check box is the header's select-all.
    final checks = find.descendant(
      of: find.byKey(OrdersKeys.list),
      matching: find.byType(Check),
    );
    await s.tap(checks.at(1));
    await s.tap(checks.at(2));
    await s.tap(checks.at(3), shot: const Shot('Orders · three selected'));
    final picked = [for (final o in toShip.take(3)) o.number];
    final before = {for (final n in picked) n: shop.db.orderByNumber(n).status};

    await s.tap(
      find.descendant(
        of: find.byType(BulkActionBar),
        matching: find.text(s.strings.orders.markShipped),
      ),
      shot: const Shot('Orders · shipped, undo offered'),
    );
    // Nothing reaches the shop while the undo is on offer.
    expect(shop.calls.countOf(Endpoint.bulkSetStatus), 0);
    final shippedPills = find.descendant(
      of: find.byKey(OrdersKeys.list),
      matching: find.text(s.strings.shell.orderStatus(OrderStatus.shipped)),
    );
    expect(shippedPills, findsNWidgets(3));

    await s.split({
      'undo': () async {
        await s.tap(
          find.text(s.kit.inputs.undo),
          shot: const Shot('Orders · shipping undone'),
        );
        expect(shippedPills, findsNothing);
        // Taken back, the same three are picked again, and a toast says so.
        expect(find.text(s.strings.orders.undoneBulk(3)), findsOneWidget);
        expect(find.byType(BulkActionBar), findsOneWidget);
        await s.wait(const Duration(seconds: 11));
        expect(shop.calls.countOf(Endpoint.bulkSetStatus), 0);
        for (final n in picked) {
          expect(shop.db.orderByNumber(n).status, before[n]);
        }
      },
      'let it commit': () async {
        await s.wait(
          const Duration(seconds: 11),
          shot: const Shot('Orders · shipped'),
        );
        expect(shop.calls.countOf(Endpoint.bulkSetStatus), 1);
        for (final n in picked) {
          expect(shop.db.orderByNumber(n).status, OrderStatus.shipped);
          // Shipped, they leave the To ship view.
          expect(find.byKey(OrdersKeys.row(n)), findsNothing);
        }
      },
      'server refuses': () async {
        shop.faults.failNext(Endpoint.bulkSetStatus, const ShopError.server());
        await s.wait(
          const Duration(seconds: 11),
          shot: const Shot('Orders · shipping failed, rolled back'),
        );
        expect(shop.calls.countOf(Endpoint.bulkSetStatus), 1);
        expect(shop.calls.failuresOf(Endpoint.bulkSetStatus), 1);
        for (final n in picked) {
          expect(shop.db.orderByNumber(n).status, before[n]);
          expect(find.byKey(OrdersKeys.row(n)), findsOneWidget);
        }
        expect(shippedPills, findsNothing);
        expect(find.text(s.strings.orders.bulkFailedTitle), findsOneWidget);
      },
    });
  });

  scenario('Saving a view of my own', (s) async {
    final shop = await openShop(s, at: const Orders());
    await _pickFilter(s, s.strings.orders.columnPayment, [
      s.strings.shell.payment(PaymentMethod.bankTransfer),
    ]);
    await _closePopover(s);

    await s.tap(
      find.descendant(
        of: find.byType(SavedViewsBar),
        matching: find.byIcon(Icons.add),
      ),
    );
    final collection = s.kit.collection;
    await s.enterText(
      _inDialog(collection.saveViewTitle, find.byType(EditableText)),
      _viewName,
      shot: const Shot('Orders · save view'),
    );
    await s.tap(
      _inDialog(
        collection.saveViewTitle,
        find.text(_material(s).saveButtonLabel),
      ),
      shot: const Shot('Orders · my saved view'),
    );
    expect(shop.calls.countOf(Endpoint.createView), 1);
    final saved = shop.db.savedViews[CollectionKeys.orders]!.last;
    expect(saved.name, _viewName);
    expect(saved.scope, SavedViewScope.personal);
    expect(saved.state.filters.single.field, OrderFields.payment);

    // Renamed from its tab's menu, in the same dialog.
    await s.tap(
      find.byWidgetPredicate(
        (w) => w is IconAction && w.label == collection.viewOptions(_viewName),
      ),
    );
    await s.tap(find.text(collection.rename));
    await s.enterText(
      _inDialog(collection.renameViewTitle, find.byType(EditableText)),
      _renamed,
      shot: const Shot('Orders · rename view'),
    );
    await s.tap(
      _inDialog(collection.renameViewTitle, find.text(collection.rename)),
    );
    expect(shop.calls.countOf(Endpoint.updateView), 1);
    expect(shop.db.savedViews[CollectionKeys.orders]!.last.name, _renamed);

    // Away and back: the view comes from the shop again.
    await navTo(s, Nav.dashboard);
    await navTo(s, Nav.orders);
    expect(
      find.descendant(
        of: find.byType(SavedViewsBar),
        matching: find.text(_renamed),
      ),
      findsOneWidget,
    );
    expect(shop.calls.countOf(Endpoint.createView), 1);
  });

  scenario('The order board', (s) async {
    final shop = await openShop(s, at: const Orders());
    await s.tap(
      find.text(s.strings.orders.viewBoard),
      shot: const Shot('Order board', tags: ['tour']),
    );
    expect(shop.route, const Orders(view: OrdersView.board));

    final paid = [
      for (final o in shop.db.orders)
        if (o.status == OrderStatus.paid) o,
    ]..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    final card = OrdersKeys.card(paid.first.number);
    final picking = find
        .descendant(
          of: find.byType(KanbanBoard<Order>),
          matching: find.text(s.strings.shell.orderStatus(OrderStatus.picking)),
        )
        .first;
    // Onto the picking column, below its header.
    final by =
        s.tester.getCenter(picking) -
        s.tester.getCenter(find.byKey(card)) +
        const Offset(0, 120);

    await s.split({
      'moved': () async {
        await s.drag(card, by, shot: const Shot('Order board · card moved'));
        expect(shop.calls.countOf(Endpoint.moveOrder), 1);
        expect(
          shop.db.orderByNumber(paid.first.number).status,
          OrderStatus.picking,
        );
      },
      'refused': () async {
        shop.faults.failNext(Endpoint.moveOrder, const ShopError.server());
        await s.drag(
          card,
          by,
          shot: const Shot('Order board · move rolled back'),
        );
        expect(shop.calls.countOf(Endpoint.moveOrder), 1);
        expect(shop.calls.failuresOf(Endpoint.moveOrder), 1);
        expect(
          shop.db.orderByNumber(paid.first.number).status,
          OrderStatus.paid,
        );
        // Back in the paid column, whichever side it is on.
        final paidColumn = find
            .descendant(
              of: find.byType(KanbanBoard<Order>),
              matching: find.text(
                s.strings.shell.orderStatus(OrderStatus.paid),
              ),
            )
            .first;
        final x = s.tester.getCenter(find.byKey(card)).dx;
        expect(
          (x - s.tester.getCenter(paidColumn).dx).abs(),
          lessThan((x - s.tester.getCenter(picking).dx).abs()),
        );
      },
    });
  });

  scenario('Finding an order', (s) async {
    final shop = await openShop(s, at: const Orders());
    final search = find.descendant(
      of: find.byKey(OrdersKeys.toolbar),
      matching: find.byType(EditableText),
    );
    final lists = shop.calls.countOf(Endpoint.listOrders);
    // #1042 is on the first page already: the search has landed once the
    // newest order, someone else's, has left the list.
    await searchIn(
      s,
      search,
      'Haddad',
      until: onceGone(
        find.byKey(OrdersKeys.row(1042)),
        absent: find.byKey(OrdersKeys.row(_newest(shop).number)),
      ),
      shot: const Shot('Orders · search'),
    );
    // One read for the settled search, not one per letter.
    expect(shop.calls.countOf(Endpoint.listOrders), lists + 1);
    expect(_lastList(shop)['search'], 'Haddad');

    await _pickFilter(s, s.strings.orders.columnStatus, [
      s.strings.shell.orderStatus(OrderStatus.paid),
    ]);
    await _closePopover(s);
    final filtered = shop.calls.countOf(Endpoint.listOrders);
    await searchIn(
      s,
      search,
      'Haddadz',
      from: 6,
      until: find.text(s.kit.collection.clearFilters),
      shot: const Shot('Orders · nothing matches'),
    );
    expect(shop.calls.countOf(Endpoint.listOrders), filtered + 1);

    await s.tap(find.text(s.kit.collection.clearFilters));
    final cleared = _lastList(shop);
    expect(cleared.containsKey('search'), isFalse);
    expect(cleared.containsKey('filters'), isFalse);
    expect(find.byKey(OrdersKeys.row(_newest(shop).number)), findsOneWidget);
  });

  scenario('Right-click and hover', (s) async {
    final shop = await openShop(s, at: const Orders());
    final newest = _newest(shop);
    await rightClick(
      s,
      OrdersKeys.row(newest.number),
      shot: 'Orders · row menu',
    );
    await s.tap(
      find.text(s.strings.orders.changeStatus),
      shot: const Shot('Orders · status submenu'),
    );
    await _closePopover(s);

    await hover(
      s,
      OrdersKeys.customer(newest.number),
      shot: 'Orders · customer card',
    );
    expect(find.textContaining(newest.customerEmail), findsOneWidget);

    const writes = [
      Endpoint.bulkSetStatus,
      Endpoint.moveOrder,
      Endpoint.refund,
      Endpoint.addNote,
    ];
    for (final e in writes) {
      expect(shop.calls.countOf(e), 0, reason: e.path);
    }
  });

  scenario('Exporting the filtered orders', (s) async {
    final shop = await openShop(s, at: const Orders());
    await _pickFilter(s, s.strings.orders.columnPayment, [
      s.strings.shell.payment(PaymentMethod.bankTransfer),
    ]);
    await _closePopover(s, shot: const Shot('Orders · filtered for export'));

    await s.tap(OrdersKeys.export);
    expect(shop.calls.countOf(Endpoint.exportCsv), 1);
    final bytes = s.tester
        .widget<CsvPreview>(find.byKey(OrdersKeys.exportPreview))
        .bytes;
    await s.document(
      'orders.csv',
      bytes,
      fileName: 'orders.csv',
      mimeType: 'text/csv',
    );
    final lines = const LineSplitter().convert(utf8.decode(bytes));
    final matching = shop.db.orders.where(
      (o) => o.payment == PaymentMethod.bankTransfer,
    );
    expect(lines.length - 1, matching.length);
    // The same header and machine values in every language.
    expect(
      lines.first,
      'number,placed_at,customer,email,status,payment,items,total,refunded',
    );
    expect(lines.skip(1).every((l) => l.contains(',bankTransfer,')), isTrue);
  });

  scenario('Refunding an order', (s) async {
    final shop = await openShop(
      s,
      at: const OrderDetail(1042),
      shot: const Shot('Order', tags: ['tour']),
    );
    final order = shop.db.orderByNumber(1042);
    expect(order.totalCents, 8450);

    await s.tap(OrdersKeys.more, shot: const Shot('Order · actions'));
    await s.tap(find.text(s.strings.orders.refund), shot: const Shot('Refund'));

    // Meanwhile a teammate refunds part of it, from another screen.
    final teammate = shop.api.staffWithRole(Role.manager);
    shop.db.replaceOrder(
      order.copyWith(
        refundedCents: 3000,
        events: [
          ...order.events,
          OrderEvent(
            kind: OrderEventKind.refunded,
            at: clock.now(),
            by: teammate.name,
            detail: '3000',
          ),
        ],
      ),
    );
    await s.tap(
      OrdersKeys.refundConfirm,
      shot: const Shot('Refund · amount too high'),
    );
    expect(shop.calls.countOf(Endpoint.refund), 1);
    expect(shop.calls.failuresOf(Endpoint.refund), 1);
    expect(find.text(s.strings.orders.refundTooHigh), findsOneWidget);

    await s.enterText(
      find.descendant(
        of: find.byKey(OrdersKeys.refundAmount),
        matching: find.byType(EditableText),
      ),
      '40',
    );
    final gate = shop.faults.hold(Endpoint.refund);
    await s.tap(
      OrdersKeys.refundConfirm,
      shot: const Shot('Refund · in progress'),
      settle: const Settle.frames(2),
    );
    expect(find.byKey(OrdersKeys.refundDialog), findsOneWidget);
    gate.release();
    await s.settle();
    // The picture is of the Activity card, where the refund lands.
    await s.scrollTo(OrdersKeys.timeline, shot: const Shot('Order · refunded'));

    expect(shop.calls.countOf(Endpoint.refund), 2);
    expect(shop.calls.failuresOf(Endpoint.refund), 1);
    final refunded = shop.db.orderByNumber(1042);
    expect(refunded.refundedCents, 7000);
    expect(refunded.events.last.kind, OrderEventKind.refunded);
    expect(
      find.descendant(
        of: find.byKey(OrdersKeys.timeline),
        matching: find.text(s.strings.orders.event(OrderEventKind.refunded)),
      ),
      findsNWidgets(2),
      reason: "the teammate's refund and this one",
    );
    expect(find.byKey(OrdersKeys.refundDialog), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(OrdersKeys.paymentPill),
        matching: find.text(s.strings.shell.partiallyRefunded),
      ),
      findsOneWidget,
    );
  });

  scenario('A note that mentions a teammate', (s) async {
    final shop = await openShop(s, at: const OrderDetail(1042));
    final teammate = shop.api.staffWithRole(Role.manager);
    final first = teammate.name.split(' ').first;
    await s.enterText(
      find.descendant(
        of: find.byKey(OrdersKeys.noteField),
        matching: find.byType(EditableText),
      ),
      'Double-check the pot size with @${first.substring(0, 3)}',
      shot: const Shot('Order · mention a teammate'),
    );
    await s.tap(find.widgetWithText(ListboxOption, teammate.name));
    await s.tap(OrdersKeys.addNote, shot: const Shot('Order · note added'));

    expect(shop.calls.countOf(Endpoint.addNote), 1);
    final note = shop.db.orderByNumber(1042).notes.last;
    expect(note, contains('<@${teammate.id}>'));
    final inbox = shop.db.notifications[teammate.id]!;
    expect(inbox.first.kind, NotificationKind.mention);
    expect(inbox.first.route, '/orders/1042');
    expect(inbox.first.read, isFalse);
  });
}

const _viewName = 'Bank transfers to check';
const _renamed = 'Transfers to reconcile';

/// [what] inside the kit's saved-view dialog, known by its [title].
Finder _inDialog(String title, Finder what) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(Modal)),
  matching: what,
);

/// Material's words as the mounted app reads them: the dialog's Save is
/// Material's.
MaterialLocalizations _material(ScenarioTester s) =>
    MaterialLocalizations.of(s.tester.element(find.byType(Navigator).first));

Order _newest(Shop shop) =>
    shop.db.orders.reduce((a, b) => a.placedAt.isAfter(b.placedAt) ? a : b);

/// The arguments of the last list read, as the fake logged them.
Map<String, Object?> _lastList(Shop shop) =>
    shop.calls.all.lastWhere((c) => c.endpoint == Endpoint.listOrders).args;

/// Opens the filter bar's [field] pill and ticks [options] in its list.
Future<void> _pickFilter(
  ScenarioTester s,
  String field,
  List<String> options,
) async {
  await s.tap(
    find.descendant(of: find.byType(FilterBar), matching: find.text(field)),
  );
  for (final option in options) {
    await s.tap(
      find.descendant(of: find.byType(Listbox), matching: find.text(option)),
    );
  }
}

/// Closes an open popover or menu the way a person does: a click on the
/// page's title, outside it.
Future<void> _closePopover(ScenarioTester s, {Shot? shot}) => s.tap(
  find.descendant(
    of: find.byType(PageHeader),
    matching: find.text(s.strings.shell.navOrders),
  ),
  shot: shot ?? Shot.skip,
);
