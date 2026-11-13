import 'package:admin_ui/collection.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/orders_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import '../../widgets/money_text.dart';
import '../orders/order_widgets.dart';

/// A customer at a glance, in a side sheet: who they are, then their orders
/// in a list of their own. [initial] saves a read when the list already
/// holds the customer.
class CustomerQuickView extends StatefulWidget {
  final String customerId;
  final Customer? initial;
  final void Function(Order order) onOpenOrder;

  const CustomerQuickView({
    super.key,
    required this.customerId,
    this.initial,
    required this.onOpenOrder,
  });

  @override
  State<CustomerQuickView> createState() => _CustomerQuickViewState();
}

class _CustomerQuickViewState extends State<CustomerQuickView> {
  late final ShopApi _api = context.api;
  late Customer? _customer = widget.initial;
  CollectionController<Order>? _orders;
  Object? _error;
  var _tab = 0;

  @override
  void initState() {
    super.initState();
    if (_customer case final customer?) {
      _watchOrders(customer);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _orders?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final customer = await _api.customer(widget.customerId);
      if (!mounted) return;
      setState(() => _customer = customer);
      _watchOrders(customer);
    } on ShopError catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Their orders, newest first.
  void _watchOrders(Customer customer) {
    _orders = CollectionController<Order>(
      fetcher: _api.listOrders,
      rowKey: (o) => o.number,
      initialQuery: CollectionQuery(
        sortKey: OrderFields.placedAt,
        ascending: false,
        pageSize: 10,
        filters: [
          OptionsFilter(OrderFields.customerId, {customer.id}),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final customer = _customer;
    final Widget body;
    if (_error case final error?) {
      body = ErrorState(
        title: context.adminL10n.couldNotLoad,
        message: ErrorTextScope.describe(context, error),
        onRetry: _load,
      );
    } else if (customer == null) {
      body = const Padding(
        padding: EdgeInsets.all(AdminSpacing.xl),
        child: SkeletonGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Skeleton(height: 48),
              Gap(AdminSpacing.lg),
              Skeleton(height: 120),
            ],
          ),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg),
            child: Tabs(
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
              tabs: [
                TabItem(strings.customerDetails, icon: Icons.person_outline),
                TabItem(
                  strings.customerOrders,
                  icon: Icons.receipt_long_outlined,
                  trailing: ListenableBuilder(
                    listenable: _orders!,
                    builder: (context, _) => _orders!.loading
                        ? const SizedBox.shrink()
                        : Text(
                            context.adminFormats.integer(_orders!.total),
                            style: context.type.caption.copyWith(
                              color: context.colors.foregroundMuted,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? _Details(customer: customer, orders: _orders!)
                : _Orders(orders: _orders!, onOpen: widget.onOpenOrder),
          ),
        ],
      );
    }
    return SideSheet(
      title: strings.customer,
      onDismiss: () => Navigator.of(context).maybePop(),
      child: body,
    );
  }
}

class _Details extends StatelessWidget {
  final Customer customer;
  final CollectionController<Order> orders;

  const _Details({required this.customer, required this.orders});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomerHeadline(customer, details: false),
          const Gap(AdminSpacing.lg),
          ListenableBuilder(
            listenable: orders,
            builder: (context, _) => orders.loading && orders.items.isEmpty
                ? SkeletonGroup(
                    child: SkeletonText(style: context.type.body, width: 240),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key: OrdersKeys.customerSummary,
                        // The name keeps its own direction inside the
                        // sentence: an Arabic name reads right in an
                        // English line.
                        strings.customerSummary(
                          bidiIsolate(customer.name),
                          orders.total,
                        ),
                        style: context.type.body,
                      ),
                      if (orders.items.firstOrNull case final latest?) ...[
                        const Gap(AdminSpacing.xs),
                        TextLink(
                          strings.latestOrder(bidiIsolate(latest.label)),
                          key: OrdersKeys.latestOrder,
                          onPressed: () =>
                              context.go(OrderDetail(latest.number)),
                        ),
                      ],
                    ],
                  ),
          ),
          const Gap(AdminSpacing.lg),
          DescriptionList(
            items: [
              DescriptionItem(
                strings.email,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        bidiIsolate(customer.email),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CopyButton(customer.email),
                  ],
                ),
              ),
              DescriptionItem(strings.city, value: customer.city),
              DescriptionItem(
                strings.country,
                value: strings.countryName(customer.country),
              ),
              DescriptionItem(
                strings.tags,
                child: customer.tags.isEmpty
                    ? Text(
                        strings.noTags,
                        style: context.type.body.copyWith(
                          color: context.colors.foregroundMuted,
                        ),
                      )
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CustomerTags(customer.tags),
                      ),
              ),
              DescriptionItem(
                strings.columnSince,
                value: formatDate(context, customer.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Orders extends StatelessWidget {
  final CollectionController<Order> orders;
  final void Function(Order order) onOpen;

  const _Orders({required this.orders, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Panel(
        child: Collection<Order>(
          key: OrdersKeys.customerOrders,
          controller: orders,
          onRowTap: onOpen,
          density: TableDensity.compact,
          empty: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: strings.noCustomerOrders,
          ),
          columns: [
            TableColumn(
              id: OrderFields.number,
              label: strings.columnOrder,
              fixed: 80,
              cellBuilder: (context, o) =>
                  Text(o.label, style: context.type.bodyStrong),
            ),
            TableColumn(
              id: OrderFields.placedAt,
              label: strings.columnPlaced,
              flex: 2,
              minWidth: 100,
              cellBuilder: (context, o) => Text(
                formatDate(context, o.placedAt),
                style: tableMutedStyle(context),
              ),
            ),
            TableColumn(
              id: OrderFields.status,
              label: strings.columnStatus,
              fixed: 112,
              cellBuilder: (context, o) => OrderStatusPill(o.status),
            ),
            TableColumn(
              id: OrderFields.total,
              label: strings.columnTotal,
              fixed: 96,
              numeric: true,
              cellBuilder: (context, o) => MoneyText(o.totalCents),
            ),
          ],
        ),
      ),
    );
  }
}
