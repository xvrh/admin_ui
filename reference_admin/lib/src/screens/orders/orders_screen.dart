import 'dart:async';
import 'dart:convert';

import 'package:admin_ui/collection.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/orders_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import '../../widgets/money_text.dart';
import '../../widgets/page_width.dart';
import 'order_board.dart';
import 'order_widgets.dart';

/// The order queue: saved views, search and filters over a paged list, bulk
/// status changes with an undo, a right-click menu per row, CSV export, and
/// the fulfilment board behind the list/board switch.
///
/// Holds the list's controllers for as long as `/orders` is open, the board
/// included, so switching between the two keeps the query.
class OrdersScreen extends StatefulWidget {
  final Orders route;

  const OrdersScreen({super.key, required this.route});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final AppServices _services = context.services;
  ShopApi get _api => _services.api;

  // FRICTION(F-202): the controller fetches as it is made, and the saved
  // views then apply their default view: the list is read twice on open.
  late final _list = CollectionController<Order>(
    fetcher: _api.listOrders,
    rowKey: (o) => o.number,
    initialQuery: const CollectionQuery(
      sortKey: OrderFields.placedAt,
      ascending: false,
    ),
  );

  late final SavedViewsController<Order> _views;

  late final CollectionRealtime<Order> _realtime;
  late final StreamSubscription<bool> _reconnected;
  final _listConnected = StreamController<bool>();

  static const _initial = ColumnLayout();
  ColumnLayout _layout = _initial;

  @override
  void initState() {
    super.initState();
    // Made here, not on first use: dispose must not be the first to read
    // one, which would start its load as the screen goes.
    _views = SavedViewsController<Order>(
      store: _api.savedViews,
      collectionKey: CollectionKeys.orders,
      collection: _list,
      readColumns: () => _layout,
      writeColumns: (layout) => setState(() => _layout = layout ?? _initial),
      nameForCopy: (name) => context.adminL10n.collection.copyOf(name),
    );
    _realtime = CollectionRealtime.bind(
      _list,
      onChanged: _api.events.where(
        (e) => e is OrdersChangedEvent || e is NewOrderEvent,
      ),
      onConnected: _listConnected.stream,
    );
    // FRICTION(F-214): CollectionRealtime refreshes the rows on reconnect,
    // but the saved views' failed load stays failed until retried; a retry
    // applies the default view, which reads the rows itself.
    _reconnected = _api.connected.listen((online) async {
      if (online && _views.lastError != null) {
        await _views.retry();
        if (mounted && _list.error != null) await _list.refresh();
        return;
      }
      _listConnected.add(online);
    });
    if (widget.route.savedView case final id?) _selectOnLoad(id);
  }

  /// Opens the view [id] names once the views have loaded: a deep link to a
  /// saved view.
  void _selectOnLoad(String id) {
    void pick() {
      if (_views.loading || _views.views.isEmpty) return;
      _views.removeListener(pick);
      final view = _views.views.where((v) => v.id == id).firstOrNull;
      if (view != null && view.id != _views.activeId) _views.select(view);
    }

    _views.addListener(pick);
  }

  @override
  void dispose() {
    _reconnected.cancel();
    _listConnected.close();
    _realtime.dispose();
    _views.dispose();
    _list.dispose();
    super.dispose();
  }

  bool get _canManage => _services.session.can(Permission.manageOrders);

  // -------------------------------------------------------------------------
  // Actions

  void _open(Order order) => context.go(OrderDetail(order.number));

  void _showView(OrdersView view) =>
      context.go(Orders(view: view, savedView: widget.route.savedView));

  /// Moves the selected orders to [status] at once, and asks the shop only
  /// once the undo toast has gone without its Undo pressed.
  Future<void> _bulkSetStatus(OrderStatus status) async {
    final numbers = {for (final o in _list.selected) o.number};
    if (numbers.isEmpty) return;
    final strings = context.strings.orders;
    final toasts = ToastScope.of(context);
    final undo = context.adminL10n.inputs.undo;
    final message = status == OrderStatus.shipped
        ? strings.markedShipped(numbers.length)
        : strings.markedPacked(numbers.length);
    _list.clearSelection();
    try {
      final committed = await _list.undoable(
        update: (rows) => [
          for (final o in rows)
            numbers.contains(o.number) ? o.copyWith(status: status) : o,
        ],
        commit: () => _api.bulkSetStatus(numbers.toList(), status),
        undone: toasts
            .show(Toast(message, severity: Severity.success, actionLabel: undo))
            .dismissed
            .then((reason) => reason == ToastDismissReason.action),
      );
      // Undone: the same orders are picked again, as they were, so the
      // next try is one click away.
      if (!committed && mounted) {
        _list.setSelected({
          for (final o in _list.items)
            if (numbers.contains(o.number)) o,
        });
        toasts.show(Toast(strings.undoneBulk(numbers.length)));
      }
    } on ShopError {
      toasts.show(
        Toast(
          strings.bulkFailed,
          title: strings.bulkFailedTitle,
          severity: Severity.danger,
        ),
      );
    }
  }

  /// One order to [status], from its row's menu: shown at once, taken back
  /// if the shop refuses.
  Future<void> _setStatus(Order order, OrderStatus status) async {
    final strings = context.strings;
    final toasts = ToastScope.of(context);
    try {
      await _list.optimistic(
        update: (rows) => [
          for (final o in rows)
            o.number == order.number ? o.copyWith(status: status) : o,
        ],
        commit: () => _api.moveOrder(order.number, status),
      );
      toasts.show(
        Toast(
          strings.orders.statusChanged(
            bidiIsolate(order.label),
            strings.shell.orderStatus(status),
          ),
          severity: Severity.success,
        ),
      );
    } on ShopError catch (error) {
      if (!mounted) return;
      toasts.show(
        Toast(
          ErrorTextScope.describe(context, error),
          title: strings.orders.statusFailed(bidiIsolate(order.label)),
          severity: Severity.danger,
        ),
      );
    }
  }

  Future<void> _export() async {
    final query = _list.query;
    try {
      final bytes = await _api.exportCsv(query);
      if (!mounted) return;
      final rows = const LineSplitter().convert(utf8.decode(bytes)).length - 1;
      await showModal<void>(
        context,
        builder: (context) => ExportDialog(bytes: bytes, rows: rows),
      );
    } on ShopError catch (error) {
      if (!mounted) return;
      ToastScope.of(context).show(
        Toast(
          ErrorTextScope.describe(context, error),
          severity: Severity.danger,
        ),
      );
    }
  }

  Future<void> _openFilters() => showSideSheet<void>(
    context,
    // FRICTION(F-002): no bottom sheet; a phone's filters take a full-width
    // side sheet.
    width: MediaQuery.sizeOf(context).width,
    builder: (sheet) => ListenableBuilder(
      listenable: _list,
      builder: (sheet, _) => SideSheet(
        key: OrdersKeys.filterSheet,
        title: sheet.strings.orders.filters,
        onDismiss: () => Navigator.of(sheet).pop(),
        footer: Button.primary(
          sheet.strings.orders.showResults,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: _filterBar(sheet),
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // Building

  List<FilterField> _filterFields(BuildContext context) {
    final strings = context.strings;
    return [
      OptionsFilterField(OrderFields.status, strings.orders.columnStatus, [
        for (final s in OrderStatus.values)
          FilterOption(s.name, strings.shell.orderStatus(s)),
      ]),
      OptionsFilterField(OrderFields.payment, strings.orders.columnPayment, [
        for (final p in PaymentMethod.values)
          FilterOption(p.name, strings.shell.payment(p)),
      ]),
      DateRangeFilterField(OrderFields.placedAt, strings.orders.columnPlaced),
      NumberRangeFilterField(OrderFields.total, strings.orders.columnTotal),
      TextFilterField(OrderFields.customer, strings.orders.columnCustomer),
      // FRICTION(F-209): FilterBar shows a pill only for its fields, yet
      // offers Clear all for any condition; the saved views' own conditions
      // get a pill while they are set.
      for (final c in _list.query.filters)
        if (c.field == OrderFields.toShip)
          BoolFilterField(OrderFields.toShip, strings.orders.viewToShip)
        else if (c.field == OrderFields.refundRequested)
          BoolFilterField(
            OrderFields.refundRequested,
            strings.orders.refundRequested,
          ),
    ];
  }

  Widget _filterBar(BuildContext context) => FilterBar(
    fields: _filterFields(context),
    active: _list.query.filters,
    onChanged: _list.setFilters,
  );

  /// Sized for the longest language and the widest theme type: the fixed
  /// columns hold their header, its sort arrow and their longest value
  /// ("En préparation", an Arabic month), and at 1024 wide (the rail) the
  /// row still fits without scrolling.
  List<TableColumn<Order>> _columns(BuildContext context, bool menus) {
    final strings = context.strings.orders;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    // FRICTION(F-203): CollectionTable has no row context menu; each cell
    // is wrapped in its own region, filled out to the cell's padding.
    Widget Function(BuildContext, Order) cell(
      Widget Function(BuildContext, Order) build, {
      AlignmentGeometry align = AlignmentDirectional.centerStart,
    }) => !menus
        ? build
        : (context, order) => ContextMenuRegion(
            entries: (context) => _rowMenu(context, order),
            child: SizedBox.expand(
              child: Align(alignment: align, child: build(context, order)),
            ),
          );
    return [
      TableColumn(
        id: OrderFields.number,
        label: strings.columnOrder,
        fixed: 100,
        pinned: true,
        hideable: false,
        sortKey: OrderFields.number,
        cellBuilder: cell(
          (context, o) => Text(
            o.label,
            key: OrdersKeys.row(o.number),
            style: context.type.bodyStrong,
          ),
        ),
      ),
      TableColumn(
        id: OrderFields.customer,
        label: strings.columnCustomer,
        flex: 3,
        minWidth: 136,
        sortKey: OrderFields.customer,
        cellBuilder: cell((context, o) => OrderCustomer(o)),
      ),
      TableColumn(
        id: OrderFields.placedAt,
        label: strings.columnPlaced,
        fixed: arabic ? 196 : 168,
        sortKey: OrderFields.placedAt,
        cellBuilder: cell(
          (context, o) => Text(
            formatDateTime(context, o.placedAt),
            style: tableMutedStyle(context),
          ),
        ),
      ),
      TableColumn(
        id: OrderFields.status,
        label: strings.columnStatus,
        fixed: 156,
        sortKey: OrderFields.status,
        cellBuilder: cell((context, o) => OrderStatusPill(o.status)),
      ),
      TableColumn(
        id: OrderFields.payment,
        label: strings.columnPayment,
        flex: 2,
        minWidth: 104,
        cellBuilder: cell((context, o) => PaymentSummary(o)),
      ),
      TableColumn(
        id: OrderFields.items,
        label: strings.columnItems,
        fixed: 96,
        numeric: true,
        sortKey: OrderFields.items,
        cellBuilder: cell(
          (context, o) => Text(context.adminFormats.integer(o.itemCount)),
          align: AlignmentDirectional.centerEnd,
        ),
      ),
      TableColumn(
        id: OrderFields.total,
        label: strings.columnTotal,
        fixed: 104,
        numeric: true,
        sortKey: OrderFields.total,
        cellBuilder: cell(
          (context, o) => MoneyText(o.totalCents),
          align: AlignmentDirectional.centerEnd,
        ),
      ),
    ];
  }

  List<MenuEntry> _rowMenu(BuildContext context, Order order) {
    final strings = context.strings.orders;
    return [
      MenuItem(
        strings.openOrder,
        icon: Icons.open_in_new,
        onSelect: () => _open(order),
      ),
      if (_canManage)
        MenuSubmenu(
          strings.changeStatus,
          icon: Icons.swap_horiz,
          entries: statusEntries(context, order, (s) => _setStatus(order, s)),
        ),
      MenuItem(
        strings.viewCustomer,
        icon: Icons.person_outline,
        onSelect: () => context.go(Customers(selected: order.customerId)),
      ),
      const MenuDivider(),
      MenuItem(
        strings.copyNumber,
        icon: Icons.content_copy,
        onSelect: () => Clipboard.setData(ClipboardData(text: order.label)),
      ),
    ];
  }

  Widget _toolbar(BuildContext context, {required bool compact}) {
    final strings = context.strings.orders;
    final columns = _columns(context, false);
    final filtered = _list.query.filters.length;
    return CollectionToolbar(
      key: OrdersKeys.toolbar,
      searchController: _list.searchController,
      searchHint: strings.searchOrders,
      searchMinWidth: compact ? 120 : 200,
      filterBar: compact ? null : _filterBar(context),
      trailing: [
        if (compact)
          Button(
            filtered == 0
                ? strings.filters
                : strings.filtersCount(
                    filtered,
                    context.adminFormats.integer(filtered),
                  ),
            key: OrdersKeys.filtersButton,
            icon: Icons.filter_list,
            onPressed: _openFilters,
          )
        else
          ColumnChooserButton(
            columns: ColumnChoice.fromColumns(columns),
            layout: _layout,
            size: ControlSize.small,
            onChanged: (layout) => setState(() => _layout = layout),
            onReset: () => setState(() => _layout = _initial),
          ),
      ],
    );
  }

  List<Widget> _actions(BuildContext context, {required bool compact}) {
    final strings = context.strings.orders;
    final board = widget.route.view == OrdersView.board;
    if (compact) {
      return [
        MenuButton(
          key: OrdersKeys.pageMenu,
          icon: Icons.more_horiz,
          tooltip: strings.moreActions,
          size: IconActionSize.medium,
          entries: [
            MenuItem(
              strings.exportCsv,
              icon: Icons.download_outlined,
              onSelect: _export,
            ),
          ],
        ),
      ];
    }
    return [
      Segmented<OrdersView>(
        key: OrdersKeys.viewSwitch,
        semanticLabel: strings.viewSwitchLabel,
        value: widget.route.view,
        onChanged: _showView,
        segments: [
          SegmentOption(
            OrdersView.list,
            strings.viewList,
            icon: Icons.view_list_outlined,
          ),
          SegmentOption(
            OrdersView.board,
            strings.viewBoard,
            icon: Icons.view_kanban_outlined,
          ),
        ],
      ),
      if (!board)
        Button(
          strings.exportCsv,
          key: OrdersKeys.export,
          icon: Icons.download_outlined,
          onPressed: _export,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = AdminBreakpoint.of(context).isCompact;
    // The board needs room to drag; a phone keeps to the list.
    final board = widget.route.view == OrdersView.board && !compact;
    return PageScaffold(
      maxWidth: pageMaxWidth,
      title: board ? strings.orders.orderBoardTitle : strings.shell.navOrders,
      scrollable: false,
      actions: _actions(context, compact: compact),
      body: board
          ? OrderBoard(key: OrdersKeys.board, onOpen: _open)
          : _listBody(context, compact: compact),
    );
  }

  Widget _listBody(BuildContext context, {required bool compact}) {
    final strings = context.strings.orders;
    final manage = _canManage;
    final collection = ListenableBuilder(
      listenable: _services.appearance,
      builder: (context, _) => Collection<Order>(
        key: OrdersKeys.list,
        controller: _list,
        columns: _layout.apply(_columns(context, !compact)),
        columnWidths: _layout.widths,
        selectable: manage,
        onRowTap: _open,
        density: _services.appearance.density,
        // FRICTION(F-011): Collection keeps its table at any width; the
        // screen switches to cards on a phone.
        viewMode: compact ? CollectionViewMode.cards : CollectionViewMode.table,
        cardBuilder: (context, order) => OrderCard(order, checkRoom: manage),
        onHideColumn: (key) =>
            setState(() => _layout = _layout.withVisible(key, false)),
        empty: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: strings.noOrdersTitle,
          message: strings.noOrdersMessage,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: _views,
          builder: (context, _) {
            final manageShop = _services.session.can(Permission.manageShop);
            // The offline banner and the list's own error say it already:
            // no bar before any view has loaded, and no error row in it.
            if (_views.views.isEmpty && _views.lastError != null) {
              return const SizedBox.shrink();
            }
            return SavedViewsBar(
              key: OrdersKeys.savedViews,
              views: [for (final v in _views.views) localizedView(context, v)],
              activeId: _views.activeId,
              dirty: _views.dirty,
              onSelect: _views.select,
              onSaveChanges:
                  _views.active?.scope == SavedViewScope.personal || manageShop
                  ? _views.saveChanges
                  : null,
              onDiscardChanges: _views.discardChanges,
              onCreate: (view) =>
                  _views.saveAsNew(view.name, scope: view.scope),
              onDuplicate: (view, name) => _views.duplicate(view, name),
              // FRICTION(F-204): the bar's actions reach every view alike, so
              // who may rename or delete the shop's shared views decides for
              // all of them.
              onRenamed: manageShop ? _views.rename : null,
              onDelete: manageShop ? _deleteView : null,
              onSetDefault: _views.setDefault,
              onReorder: _views.reorder,
              error: _api.isConnected ? _views.lastError : null,
              onRetry: _views.retry,
              onDismissError: _views.clearError,
            );
          },
        ),
        const Gap(AdminSpacing.md),
        ListenableBuilder(
          listenable: _list,
          builder: (context, _) => CollectionHeader<Order>(
            controller: _list,
            toolbar: _toolbar(context, compact: compact),
            selectedLabel: strings.ordersSelected,
            allSelectedLabel: strings.allOrdersSelected,
            bulkActions: [
              if (manage) ...[
                BulkAction(
                  strings.markPacked,
                  icon: Icons.inventory_2_outlined,
                  onPressed: () => _bulkSetStatus(OrderStatus.packed),
                ),
                BulkAction(
                  strings.markShipped,
                  icon: Icons.local_shipping_outlined,
                  primary: true,
                  onPressed: () => _bulkSetStatus(OrderStatus.shipped),
                ),
              ],
            ],
          ),
        ),
        const Gap(AdminSpacing.md),
        Expanded(child: compact ? collection : Panel(child: collection)),
      ],
    );
  }

  Future<void> _deleteView(SavedView view) async {
    final strings = context.strings.orders;
    final ok = await showConfirmDialog(
      context,
      title: strings.deleteViewTitle(localizedView(context, view).name),
      message: strings.deleteViewMessage,
      confirmLabel: strings.deleteView,
      danger: true,
    );
    if (ok) await _views.delete(view);
  }
}

/// What an export made: how many orders, the first lines of the file, and
/// a copy of it to take elsewhere.
class ExportDialog extends StatelessWidget {
  final Uint8List bytes;
  final int rows;

  const ExportDialog({super.key, required this.bytes, required this.rows});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final text = utf8.decode(bytes);
    final compact = AdminBreakpoint.of(context).isCompact;
    return Modal(
      key: OrdersKeys.exportDialog,
      title: strings.exportTitle(rows),
      description: strings.exportDescription,
      size: compact ? ModalSize.fullscreen : ModalSize.large,
      onDismiss: () => Navigator.of(context).maybePop(),
      body: CsvPreview(key: OrdersKeys.exportPreview, bytes: bytes),
      actions: [
        CopyButton(text, label: strings.copyCsv),
        Button.primary(
          strings.done,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// The head of a CSV file as it will read in a spreadsheet's import: its
/// name, then its first lines in a monospaced block, left to right whatever
/// the page's direction.
class CsvPreview extends StatelessWidget {
  final Uint8List bytes;
  static const lines = 8;

  const CsvPreview({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final all = const LineSplitter().convert(utf8.decode(bytes));
    final head = all.take(lines).join('\n');
    final more = all.length - lines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: context.iconSizes.md,
              color: context.colors.foregroundMuted,
            ),
            const Gap(AdminSpacing.sm),
            Text(strings.exportFileName, style: context.type.bodyStrong),
            const Gap(AdminSpacing.sm),
            Text(
              context.adminFormats.bytes(bytes.length),
              style: context.type.caption.copyWith(
                color: context.colors.foregroundMuted,
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.md),
        Panel(
          color: context.colors.surfaceMuted,
          padding: const EdgeInsets.all(AdminSpacing.md),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                more > 0 ? '$head\n…' : head,
                style: context.type.monoSmall,
                softWrap: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
