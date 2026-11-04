import 'dart:async';

import 'package:admin_ui/collection.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/orders_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import '../../widgets/page_width.dart';
import '../orders/order_widgets.dart';
import 'customer_quick_view.dart';

/// Everyone who has ordered, searchable by name (in either script), email
/// or city. A row opens the customer's quick view in a side sheet, which
/// the URL names, so a link from an order opens it too.
class CustomersScreen extends StatefulWidget {
  final Customers route;

  const CustomersScreen({super.key, required this.route});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final AppServices _services = context.services;

  late final _list = CollectionController<Customer>(
    fetcher: _services.api.listCustomers,
    rowKey: (c) => c.id,
    initialQuery: const CollectionQuery(sortKey: CustomerFields.name),
  );

  /// The customer whose sheet is open.
  String? _open;

  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didUpdateWidget(CustomersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  /// Opens the sheet the route names, once this frame is built.
  void _follow() {
    final id = widget.route.selected;
    if (id == null || id == _open) return;
    _open = id;
    final known = _list.items.where((c) => c.id == id).firstOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_show(id, known));
    });
  }

  Future<void> _show(String id, Customer? known) async {
    final width = MediaQuery.sizeOf(context).width;
    await showSideSheet<void>(
      context,
      // FRICTION(F-002): no bottom sheet; a phone's quick view takes the
      // whole width.
      width: AdminBreakpoint.of(context).isCompact ? width : 480,
      builder: (sheet) => CustomerQuickView(
        key: OrdersKeys.customerSheet,
        customerId: id,
        initial: known,
        onOpenOrder: (order) {
          Navigator.of(sheet).pop();
          _open = null;
          _services.router.go(OrderDetail(order.number));
        },
      ),
    );
    if (!mounted || _open != id) return;
    _open = null;
    if (widget.route.selected == id) {
      unawaited(_services.router.go(const Customers(), confirm: false));
    }
  }

  List<TableColumn<Customer>> _columns(BuildContext context) {
    final strings = context.strings.orders;
    final muted = tableMutedStyle(context);
    return [
      TableColumn(
        id: CustomerFields.name,
        label: strings.columnCustomer,
        flex: 3,
        minWidth: 220,
        pinned: true,
        sortKey: CustomerFields.name,
        cellBuilder: (context, c) => Row(
          key: OrdersKeys.customerRow(c.id),
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(name: c.name, size: 28),
            const Gap(AdminSpacing.sm),
            Flexible(
              child: Text(
                c.name,
                style: context.type.bodyStrong,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      TableColumn(
        id: CustomerFields.email,
        label: strings.columnEmail,
        flex: 3,
        minWidth: 200,
        sortKey: CustomerFields.email,
        cellBuilder: (context, c) => Text(bidiIsolate(c.email), style: muted),
      ),
      TableColumn(
        id: CustomerFields.city,
        label: strings.columnCity,
        flex: 3,
        minWidth: 200,
        sortKey: CustomerFields.city,
        cellBuilder: (context, c) => Text(
          strings.place(bidiIsolate(c.city), strings.countryName(c.country)),
        ),
      ),
      TableColumn(
        id: CustomerFields.tags,
        label: strings.columnTags,
        fixed: 140,
        cellBuilder: (context, c) => CustomerTags(c.tags),
      ),
      TableColumn(
        id: CustomerFields.createdAt,
        label: strings.columnSince,
        fixed: 150,
        sortKey: CustomerFields.createdAt,
        cellBuilder: (context, c) =>
            Text(formatDate(context, c.createdAt), style: muted),
      ),
    ];
  }

  Widget _card(BuildContext context, Customer c) {
    final muted = context.type.caption.copyWith(
      color: context.colors.foregroundMuted,
    );
    return Padding(
      key: OrdersKeys.customerRow(c.id),
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Row(
        children: [
          Avatar(name: c.name, size: 36),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: context.type.bodyStrong),
                Text(
                  bidiIsolate(c.email),
                  style: muted,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  context.strings.orders.place(
                    bidiIsolate(c.city),
                    context.strings.orders.countryName(c.country),
                  ),
                  style: muted,
                ),
              ],
            ),
          ),
          if (c.tags.isNotEmpty) CustomerTags(c.tags),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = AdminBreakpoint.of(context).isCompact;
    final collection = ListenableBuilder(
      listenable: _services.appearance,
      builder: (context, _) => Collection<Customer>(
        key: OrdersKeys.customerList,
        controller: _list,
        columns: _columns(context),
        density: _services.appearance.density,
        onRowTap: (c) => context.go(Customers(selected: c.id)),
        // FRICTION(F-011): the screen switches to cards on a phone.
        viewMode: compact ? CollectionViewMode.cards : CollectionViewMode.table,
        cardBuilder: _card,
        empty: EmptyState(
          icon: Icons.people_outline,
          title: strings.orders.noCustomersTitle,
          message: strings.orders.noCustomersMessage,
        ),
      ),
    );
    return PageScaffold(
      maxWidth: pageMaxWidth,
      title: strings.shell.navCustomers,
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CollectionToolbar(
            searchController: _list.searchController,
            searchHint: strings.orders.searchCustomers,
            searchMaxWidth: 400,
          ),
          const Gap(AdminSpacing.md),
          Expanded(child: compact ? collection : Panel(child: collection)),
        ],
      ),
    );
  }
}
