import 'package:flutter/widgets.dart';

import '../../keys/orders_keys.dart';
import '../../routing/routes.dart';
import 'customers_screen.dart';

Widget customersPage(BuildContext context, Customers route) =>
    CustomersScreen(key: OrdersKeys.customersPage, route: route);
