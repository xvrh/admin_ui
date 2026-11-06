// The sample under "Finding the kit's controls" in README.md, verbatim from
// the first key down. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

const ordersKey = ValueKey('nav.orders');
const confirmDeleteKey = ValueKey('dialog.confirm');

NavItem ordersItem(VoidCallback openOrders) => NavItem(
  'Orders',
  key: ordersKey,
  icon: Icons.receipt_long_outlined,
  onTap: openOrders,
);

Future<bool> confirmDelete(BuildContext context) => showConfirmDialog(
  context,
  title: 'Delete the order?',
  message: 'It cannot be restored.',
  danger: true,
  confirmKey: confirmDeleteKey,
);
