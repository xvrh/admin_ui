import 'package:flutter/widgets.dart';

import '../../keys/orders_keys.dart';
import '../../routing/routes.dart';
import 'order_detail_screen.dart';
import 'orders_screen.dart';

Widget ordersPage(BuildContext context, Orders route) =>
    OrdersScreen(key: OrdersKeys.ordersPage, route: route);

Widget orderDetailPage(BuildContext context, OrderDetail route) =>
    OrderDetailScreen(key: OrdersKeys.orderPage, number: route.number);
