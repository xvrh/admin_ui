import 'package:admin_ui/collection.dart' show CollectionToolbar;
import 'package:admin_ui/l10n.dart' show bidiIsolate;
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reference_admin/src/keys/orders_keys.dart';

import '../../../support/harness.dart';

// Customers: finding one by a name written in Arabic script, whatever the
// page's language, and their quick view with the orders they placed.

void main() {
  scenario('Looking a customer up', (s) async {
    final shop = await openShop(
      s,
      at: const Customers(),
      shot: const Shot('Customers'),
    );
    final arabicScript = RegExp('[؀-ۿ]');
    final customer = shop.db.customers.firstWhere(
      (c) => arabicScript.hasMatch(c.name),
    );
    final lists = shop.calls.countOf(Endpoint.listCustomers);
    await searchIn(
      s,
      find.descendant(
        of: find.byType(CollectionToolbar),
        matching: find.byType(EditableText),
      ),
      customer.name,
      until: find.byKey(OrdersKeys.customerRow(customer.id)),
      shot: const Shot('Customers · search in Arabic'),
    );
    // One read for the settled search, not one per letter.
    expect(shop.calls.countOf(Endpoint.listCustomers), lists + 1);

    await s.tap(
      OrdersKeys.customerRow(customer.id),
      shot: const Shot('Customer · quick view'),
    );
    expect(shop.route, Customers(selected: customer.id));
    final orders = [
      for (final o in shop.db.orders)
        if (o.customerId == customer.id) o,
    ]..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    final summary = s.tester.widget<Text>(
      find.byKey(OrdersKeys.customerSummary),
    );
    // The name keeps its own direction inside the page's sentence.
    expect(summary.data, contains(bidiIsolate(customer.name)));
    expect(
      summary.data,
      s.strings.orders.customerSummary(
        bidiIsolate(customer.name),
        orders.length,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(OrdersKeys.latestOrder),
        matching: find.text(
          s.strings.orders.latestOrder(bidiIsolate(orders.first.label)),
        ),
      ),
      findsOneWidget,
      reason: 'a link to the newest order',
    );

    await s.tap(
      find.descendant(
        of: find.byKey(OrdersKeys.customerSheet),
        matching: find.text(s.strings.orders.customerOrders),
      ),
      shot: const Shot('Customer · orders'),
    );
    for (final order in orders.take(5)) {
      expect(
        find.descendant(
          of: find.byKey(OrdersKeys.customerOrders),
          matching: find.text(order.label),
        ),
        findsOneWidget,
      );
    }
  });
}
