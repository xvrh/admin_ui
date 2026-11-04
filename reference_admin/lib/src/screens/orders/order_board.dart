import 'package:admin_ui/collection.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart' show AdminSpacing;
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';
import '../../widgets/status_meta.dart';
import 'order_widgets.dart';

/// The statuses the board lays out, one column each: fulfilment, from paid
/// to handed over.
const boardStatuses = [
  OrderStatus.paid,
  OrderStatus.picking,
  OrderStatus.packed,
  OrderStatus.shipped,
];

/// Fulfilment as a board: every paid order not yet delivered, by status.
/// Dragging a card to another column moves the order there at once, and
/// back if the shop refuses.
class OrderBoard extends StatefulWidget {
  final void Function(Order order) onOpen;

  const OrderBoard({super.key, required this.onOpen});

  @override
  State<OrderBoard> createState() => _OrderBoardState();
}

class _OrderBoardState extends State<OrderBoard> {
  late final AppServices _services = context.services;
  ShopApi get _api => _services.api;

  late final _orders = CollectionController<Order>(
    fetcher: _api.listOrders,
    rowKey: (o) => o.number,
    initialQuery: CollectionQuery(
      sortKey: OrderFields.placedAt,
      ascending: false,
      pageSize: 500,
      filters: [
        OptionsFilter(OrderFields.status, {
          for (final s in boardStatuses) s.name,
        }),
      ],
    ),
  );

  late final CollectionRealtime<Order> _realtime;

  @override
  void initState() {
    super.initState();
    _realtime = CollectionRealtime.bind(
      _orders,
      onChanged: _api.events.where(
        (e) => e is OrdersChangedEvent || e is NewOrderEvent,
      ),
      onConnected: _api.connected,
    );
  }

  @override
  void dispose() {
    _realtime.dispose();
    _orders.dispose();
    super.dispose();
  }

  Future<void> _move(Order order, String from, String to) async {
    final status = OrderStatus.values.byName(to);
    final strings = context.strings.orders;
    final toasts = ToastScope.of(context);
    try {
      await _orders.optimistic(
        update: (rows) => [
          for (final o in rows)
            o.number == order.number ? o.copyWith(status: status) : o,
        ],
        commit: () => _api.moveOrder(order.number, status),
      );
    } on ShopError catch (error) {
      if (!mounted) return;
      toasts.show(
        Toast(
          ErrorTextScope.describe(context, error),
          title: strings.moveFailed(bidiIsolate(order.label)),
          severity: Severity.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final canMove = _services.session.can(Permission.manageOrders);
    return ListenableBuilder(
      listenable: _orders,
      builder: (context, _) {
        final error = _orders.error;
        if (error != null) {
          return ErrorState(
            title: context.adminL10n.couldNotLoad,
            message: ErrorTextScope.describe(context, error),
            onRetry: _orders.refresh,
          );
        }
        if (_orders.loading && _orders.items.isEmpty) {
          return const LoadingPanel();
        }
        return LayoutBuilder(
          builder: (context, constraints) => KanbanBoard<Order>(
            columnWidth: boardColumnWidth(constraints.maxWidth),
            itemKey: (o) => o.number,
            onMove: canMove ? _move : null,
            onCardTap: widget.onOpen,
            cardBuilder: (context, order) => OrderCard(order, framed: true),
            columns: [
              for (final status in boardStatuses)
                KanbanColumn(
                  id: status.name,
                  title: strings.shell.orderStatus(status),
                  subtitle: strings.orders.boardColumnSubtitle(status),
                  accent: context.orderStatusMeta(status).color,
                  items: [
                    for (final o in _orders.items)
                      if (o.status == status) o,
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A board column's width in [available]: as many whole columns as fit at
/// 240 or wider, shared out, so the viewport's edge falls in the gap after
/// the last one rather than through a card.
// FRICTION(F-208): the board's own padding and gap are fixed and not
// exposed, so they are repeated here to share the width out.
double boardColumnWidth(double available) {
  // The scroll view's end padding only shows at the end of the board, so
  // the room is the width less the leading padding, and each column brings
  // its gap.
  const leading = AdminSpacing.xl;
  const gap = AdminSpacing.lg;
  const narrowest = 240.0;
  final room = available - leading;
  final fit = (room / (narrowest + gap)).floor().clamp(1, 99);
  return room / fit - gap;
}
