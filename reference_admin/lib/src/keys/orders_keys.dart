import 'package:flutter/foundation.dart';

/// Keys of this area's controls, as `ValueKey('<area>.<thing>')`.
abstract final class OrdersKeys {
  // the queue
  static const ordersPage = ValueKey('orders.ordersPage');
  static const viewSwitch = ValueKey('orders.viewSwitch');
  static const export = ValueKey('orders.export');
  static const pageMenu = ValueKey('orders.pageMenu');
  static const filtersButton = ValueKey('orders.filtersButton');
  static const filterSheet = ValueKey('orders.filterSheet');
  static const savedViews = ValueKey('orders.savedViews');
  static const toolbar = ValueKey('orders.toolbar');
  static const list = ValueKey('orders.list');
  static const board = ValueKey('orders.board');
  static const exportDialog = ValueKey('orders.exportDialog');
  static const exportPreview = ValueKey('orders.exportPreview');

  /// A row's order number cell, the card of it on the board or a phone.
  static ValueKey<String> row(int number) => ValueKey('orders.row.$number');
  static ValueKey<String> card(int number) => ValueKey('orders.card.$number');
  static ValueKey<String> customer(int number) =>
      ValueKey('orders.customer.$number');

  // order detail
  static const orderPage = ValueKey('orders.orderPage');
  static const markShipped = ValueKey('orders.markShipped');
  static const more = ValueKey('orders.more');
  static const timeline = ValueKey('orders.timeline');
  static const paymentPill = ValueKey('orders.paymentPill');
  static const refundDialog = ValueKey('orders.refundDialog');
  static const refundAmount = ValueKey('orders.refundAmount');
  static const refundReason = ValueKey('orders.refundReason');
  static const refundConfirm = ValueKey('orders.refundConfirm');
  static const noteField = ValueKey('orders.noteField');
  static const addNote = ValueKey('orders.addNote');

  // customers
  static const customersPage = ValueKey('orders.customersPage');
  static const customerList = ValueKey('orders.customerList');
  static const customerSheet = ValueKey('orders.customerSheet');
  static const customerSummary = ValueKey('orders.customerSummary');
  static const latestOrder = ValueKey('orders.latestOrder');
  static const customerOrders = ValueKey('orders.customerOrders');
  static ValueKey<String> customerRow(String id) =>
      ValueKey('orders.customerRow.$id');
}
