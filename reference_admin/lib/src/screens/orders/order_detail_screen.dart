import 'dart:async';

import 'package:admin_ui/collection.dart' show TableThumb;
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/orders_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import '../../widgets/money_text.dart';
import '../../widgets/page_width.dart';
import 'note_composer.dart';
import 'order_widgets.dart';
import 'refund_dialog.dart';

/// One order: what was bought, where it goes, how it was paid, what
/// happened to it, and the team's notes. Status changes, refunds, cancelling
/// and notes all start here.
class OrderDetailScreen extends StatefulWidget {
  final int number;

  const OrderDetailScreen({super.key, required this.number});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final AppServices _services = context.services;
  ShopApi get _api => _services.api;

  Order? _order;
  List<StaffMember> _team = const [];

  /// The lines' photos by media id, as the library resolves them.
  Map<String, ImageProvider> _photos = const {};
  Object? _error;
  var _busy = false;

  bool get _canManage => _services.session.can(Permission.manageOrders);
  bool get _canRefund => _services.session.can(Permission.refund);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final (order, team) = await (
        _api.order(widget.number),
        _canManage ? _api.staff() : Future.value(const <StaffMember>[]),
      ).wait;
      if (!mounted) return;
      setState(() {
        _order = order;
        _team = team;
      });
      unawaited(_loadPhotos(order));
    } on ShopError catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  // FRICTION(F-026): AssetSource resolves one id per call.
  Future<void> _loadPhotos(Order order) async {
    final ids = {for (final line in order.lines) ?line.photoId}
        .difference(_photos.keys.toSet());
    if (ids.isEmpty) return;
    final resolved = await Future.wait([
      for (final id in ids)
        _api.assets.resolve(id).catchError((Object _) => null),
    ]);
    if (!mounted) return;
    setState(() {
      _photos = {
        ..._photos,
        for (final asset in resolved.nonNulls) asset.id: ?asset.thumbnail,
      };
    });
  }

  String _nameOf(String staffId) =>
      _team.where((s) => s.id == staffId).firstOrNull?.name ?? staffId;

  // -------------------------------------------------------------------------
  // Actions

  Future<void> _setStatus(
    OrderStatus status, {
    bool emailCustomer = false,
  }) async {
    final order = _order!;
    final strings = context.strings;
    final toasts = ToastScope.of(context);
    String describe(Object error) => ErrorTextScope.describe(context, error);
    setState(() => _busy = true);
    try {
      final updated = await toasts.promise(
        _api.moveOrder(order.number, status, emailCustomer: emailCustomer),
        loading: Toast.loading(
          strings.orders.updating(bidiIsolate(order.label)),
        ),
        success: (o) => Toast(
          strings.orders.statusChanged(
            bidiIsolate(o.label),
            strings.shell.orderStatus(o.status),
          ),
          severity: Severity.success,
        ),
        error: (error) => Toast(
          describe(error),
          title: strings.orders.statusFailed(bidiIsolate(order.label)),
          severity: Severity.danger,
        ),
      );
      if (mounted) setState(() => _order = updated);
    } on ShopError {
      // The toast has told it.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refund() async {
    final order = _order!;
    final outcome = await showRefundDialog(context, order);
    if (outcome == null || !mounted) return;
    setState(() => _order = outcome.order);
    final refunded = outcome.refundedCents;
    if (refunded > 0) {
      ToastScope.of(context).show(
        Toast(
          context.strings.orders.refundDone(
            formatMoney(context, refunded),
            bidiIsolate(order.label),
          ),
          severity: Severity.success,
        ),
      );
    }
  }

  Future<void> _cancel() async {
    final order = _order!;
    final strings = context.strings.orders;
    final confirmed = await showConfirmDialog(
      context,
      title: strings.cancelTitle(bidiIsolate(order.label)),
      message: strings.cancelMessage,
      confirmLabel: strings.cancelOrder,
      cancelLabel: strings.keepOrder,
      danger: true,
    );
    if (confirmed) await _setStatus(OrderStatus.cancelled);
  }

  Future<void> _addNote(String text) async {
    final order = _order!;
    final toasts = ToastScope.of(context);
    final strings = context.strings.orders;
    String describe(Object error) => ErrorTextScope.describe(context, error);
    try {
      final updated = await _api.addNote(order.number, text);
      if (!mounted) return;
      setState(() => _order = updated);
      toasts.show(Toast(strings.noteAdded, severity: Severity.success));
    } on ShopError catch (error) {
      toasts.show(Toast(describe(error), severity: Severity.danger));
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Building

  List<MenuEntry> _moreEntries(BuildContext context, Order order) {
    final strings = context.strings.orders;
    final open =
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.delivered;
    return [
      if (_canManage && order.status != OrderStatus.cancelled)
        MenuSubmenu(
          strings.changeStatus,
          icon: Icons.swap_horiz,
          entries: statusEntries(context, order, _setStatus),
        ),
      if (_canRefund)
        MenuItem(
          strings.refund,
          icon: Icons.undo,
          description: order.refundableCents > 0
              ? null
              : strings.nothingToRefund,
          onSelect: order.refundableCents > 0 ? _refund : null,
        ),
      if (_canManage && open) ...[
        const MenuDivider(),
        MenuItem(
          strings.cancelOrder,
          icon: Icons.block,
          danger: true,
          onSelect: _cancel,
        ),
      ],
    ];
  }

  List<Widget> _actions(BuildContext context, Order order, bool compact) {
    final strings = context.strings.orders;
    final more = _moreEntries(context, order);
    final ship = _canManage && order.status.toShip;
    if (compact) {
      return [
        MenuButton(
          key: OrdersKeys.more,
          icon: Icons.more_horiz,
          tooltip: strings.more,
          size: IconActionSize.medium,
          entries: [
            if (ship) ...[
              MenuItem(
                strings.markOrderShipped,
                icon: Icons.local_shipping_outlined,
                onSelect: () => _setStatus(OrderStatus.shipped),
              ),
              MenuItem(
                strings.shipAndEmail,
                icon: Icons.forward_to_inbox_outlined,
                onSelect: () =>
                    _setStatus(OrderStatus.shipped, emailCustomer: true),
              ),
              if (more.isNotEmpty) const MenuDivider(),
            ],
            ...more,
          ],
        ),
      ];
    }
    return [
      if (more.isNotEmpty)
        Menu(
          entries: more,
          align: PopoverAlign.end,
          builder: (context, menu) => Button(
            strings.more,
            key: OrdersKeys.more,
            trailingIcon: Icons.expand_more,
            onPressed: menu.toggle,
          ),
        ),
      if (ship)
        SplitButton(
          key: OrdersKeys.markShipped,
          label: strings.markOrderShipped,
          icon: Icons.local_shipping_outlined,
          loading: _busy,
          menuSemanticLabel: strings.moreActions,
          onPressed: () => _setStatus(OrderStatus.shipped),
          entries: [
            MenuItem(
              strings.shipAndEmail,
              description: strings.shipAndEmailHint,
              icon: Icons.forward_to_inbox_outlined,
              onSelect: () =>
                  _setStatus(OrderStatus.shipped, emailCustomer: true),
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final compact = AdminBreakpoint.of(context).isCompact;
    final order = _order;
    final label = '#${widget.number}';
    final crumbs = Breadcrumbs([
      Crumb(
        strings.orders.breadcrumbOrders,
        onTap: () => context.go(const Orders()),
      ),
      Crumb(label, loading: order == null && _error == null),
    ]);

    if (_error is NotFoundError) {
      return PageScaffold(
        title: label,
        breadcrumb: crumbs,
        body: EmptyState(
          icon: Icons.search_off,
          title: strings.orders.orderNotFoundTitle,
          message: strings.orders.orderNotFoundMessage(bidiIsolate(label)),
          action: Button(
            strings.orders.backToOrders,
            onPressed: () => context.go(const Orders()),
          ),
        ),
      );
    }
    if (_error case final error?) {
      return PageScaffold(
        title: label,
        breadcrumb: crumbs,
        body: ErrorState(
          title: context.adminL10n.couldNotLoad,
          message: ErrorTextScope.describe(context, error),
          onRetry: _load,
        ),
      );
    }
    if (order == null) {
      return PageScaffold(
        title: label,
        breadcrumb: crumbs,
        titleLoading: true,
        maxWidth: pageMaxWidth,
        body: const _Loading(),
      );
    }

    final main = [
      _Section(
        title: strings.orders.items,
        child: _Lines(order: order, photos: _photos),
      ),
      _Section(
        title: strings.orders.notes,
        child: _Notes(
          order: order,
          nameOf: _nameOf,
          composer: _canManage
              ? NoteComposer(team: _team, onSubmit: _addNote)
              : null,
        ),
      ),
    ];
    final side = [
      _Section(
        title: strings.orders.customer,
        child: _CustomerBlock(order: order),
      ),
      _Section(
        title: strings.orders.payment,
        child: _PaymentBlock(order: order),
      ),
      _Section(
        title: strings.orders.activity,
        child: _Activity(order: order, nameOf: _nameOf),
      ),
    ];
    Widget column(List<Widget> sections) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in sections.indexed) ...[
          if (i > 0) const Gap(AdminSpacing.xl),
          s,
        ],
      ],
    );
    final wide = AdminBreakpoint.of(context).isExpanded;
    return PageScaffold(
      title: order.label,
      subtitle: strings.orders.placedOn(
        formatDateTime(context, order.placedAt),
      ),
      breadcrumb: crumbs,
      titleTrailing: OrderStatusPill(order.status),
      maxWidth: pageMaxWidth,
      actions: _actions(context, order, compact),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: column(main)),
                const Gap(AdminSpacing.xl),
                Expanded(flex: 2, child: column(side)),
              ],
            )
          : column([side[0], main[0], side[1], side[2], main[1]]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.type.heading),
          ),
          const Gap(AdminSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SkeletonGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeleton(height: 160),
          Gap(AdminSpacing.xl),
          Skeleton(height: 120),
          Gap(AdminSpacing.xl),
          Skeleton(height: 200),
        ],
      ),
    );
  }
}

/// What was bought, then what it came to.
class _Lines extends StatelessWidget {
  final Order order;
  final Map<String, ImageProvider> photos;

  const _Lines({required this.order, required this.photos});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final language = Localizations.localeOf(context).languageCode;
    final muted = context.type.caption.copyWith(
      color: context.colors.foregroundMuted,
    );
    Widget amountRow(String label, Widget value, {bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: strong ? context.type.bodyStrong : context.type.body,
                ),
              ),
              value,
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in order.lines) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photos[line.photoId] case final photo?)
                  TableThumb(image: photo, size: 36)
                else
                  Avatar(
                    name: inLanguage(line.productName, language),
                    shape: AvatarShape.rounded,
                    size: 36,
                  ),
                const Gap(AdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inLanguage(line.productName, language),
                        style: context.type.bodyStrong,
                      ),
                      Text([line.sku, ?line.variant].join(' · '), style: muted),
                    ],
                  ),
                ),
                const Gap(AdminSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(line.totalCents),
                    Text(
                      '${strings.quantity(line.qty)} · '
                      '${formatMoney(context, line.unitCents)}',
                      style: muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        const Gap(AdminSpacing.sm),
        amountRow(strings.subtotal, MoneyText(order.subtotalCents)),
        amountRow(
          strings.shipping,
          order.shippingCents == 0
              ? Text(strings.free)
              : MoneyText(order.shippingCents),
        ),
        amountRow(
          strings.taxIncluded(context.adminFormats.percent(0.2)),
          MoneyText(order.taxCents(), style: muted),
        ),
        amountRow(
          strings.total,
          MoneyText(order.totalCents, style: context.type.bodyStrong),
          strong: true,
        ),
        if (order.refundedCents > 0)
          amountRow(
            strings.refunded,
            MoneyText(
              -order.refundedCents,
              style: context.type.body.copyWith(
                color: context.colors.dangerText,
              ),
            ),
          ),
      ],
    );
  }
}

class _CustomerBlock extends StatelessWidget {
  final Order order;
  const _CustomerBlock({required this.order});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final to = order.shipTo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Avatar(name: order.customerName, size: 36),
            const Gap(AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customerName, style: context.type.bodyStrong),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bidiIsolate(order.customerEmail),
                          style: context.type.caption.copyWith(
                            color: context.colors.foregroundMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CopyButton(order.customerEmail),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.md),
        DescriptionList(
          layout: DescriptionLayout.stacked,
          items: [
            DescriptionItem(
              strings.shipTo,
              value: [
                to.name,
                to.line1,
                '${to.postcode} ${to.city}',
                strings.countryName(to.country),
              ].join('\n'),
            ),
          ],
        ),
        const Gap(AdminSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextLink(
            strings.viewCustomer,
            icon: Icons.arrow_forward,
            onPressed: () => context.go(Customers(selected: order.customerId)),
          ),
        ),
      ],
    );
  }
}

class _PaymentBlock extends StatelessWidget {
  final Order order;
  const _PaymentBlock({required this.order});

  StatusMeta _meta(BuildContext context) {
    final strings = context.strings;
    final c = context.colors;
    if (order.refundedCents > 0 && order.refundableCents <= 0) {
      return StatusMeta(strings.orders.fullyRefunded, c.foregroundMuted);
    }
    if (order.partiallyRefunded) {
      return StatusMeta(strings.shell.partiallyRefunded, c.info);
    }
    if (order.refundRequested) {
      return StatusMeta(strings.orders.refundRequested, c.warning);
    }
    return switch (order.status) {
      OrderStatus.pending => StatusMeta(
        strings.orders.awaitingPayment,
        c.foregroundSubtle,
        ring: true,
      ),
      OrderStatus.cancelled => StatusMeta(
        strings.shell.orderStatus(OrderStatus.cancelled),
        c.danger,
      ),
      _ => StatusMeta(strings.orders.paymentReceived, c.success),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return DescriptionList(
      items: [
        DescriptionItem(
          strings.orders.columnStatus,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(_meta(context), key: OrdersKeys.paymentPill),
          ),
        ),
        DescriptionItem(
          strings.orders.payment,
          value: strings.shell.payment(order.payment),
        ),
        DescriptionItem(
          strings.orders.channel,
          value: strings.shell.channel(order.channel),
        ),
        DescriptionItem(
          strings.orders.total,
          child: MoneyText(order.totalCents),
        ),
        if (order.refundedCents > 0)
          DescriptionItem(
            strings.orders.refunded,
            child: MoneyText(order.refundedCents),
          ),
      ],
    );
  }
}

/// What happened to the order, newest first.
class _Activity extends StatelessWidget {
  final Order order;
  final String Function(String id) nameOf;

  const _Activity({required this.order, required this.nameOf});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final c = context.colors;
    final now = clock.now();
    return Timeline(
      key: OrdersKeys.timeline,
      entries: [
        for (final e in order.events.reversed)
          TimelineEntry(
            title: strings.event(e.kind),
            subtitle: [
              ?_detail(context, e),
              e.by == null ? strings.byCustomer : strings.byWhom(e.by!),
            ].join(' · '),
            timestamp: formatAgo(context, e.at, now),
            icon: _icon(e.kind),
            color: switch (e.kind) {
              OrderEventKind.refunded => c.info,
              OrderEventKind.cancelled => c.danger,
              OrderEventKind.shipped || OrderEventKind.delivered => c.success,
              _ => null,
            },
          ),
      ],
    );
  }

  String? _detail(BuildContext context, OrderEvent e) {
    final detail = e.detail;
    if (detail == null || detail.isEmpty) return null;
    if (e.kind == OrderEventKind.refunded) {
      final space = detail.indexOf(' ');
      final cents = int.tryParse(
        space < 0 ? detail : detail.substring(0, space),
      );
      if (cents == null) return detail;
      return context.strings.orders.refundDetail(
        formatMoney(context, cents),
        space < 0 ? '' : detail.substring(space + 1),
      );
    }
    if (e.kind == OrderEventKind.note) {
      return [for (final run in _runs(detail)) run].join();
    }
    return detail;
  }

  Iterable<String> _runs(String note) sync* {
    final pattern = RegExp(r'<@([^>\s]+)>');
    var at = 0;
    for (final m in pattern.allMatches(note)) {
      yield note.substring(at, m.start);
      yield '@${nameOf(m[1]!)}';
      at = m.end;
    }
    yield note.substring(at);
  }

  IconData _icon(OrderEventKind kind) => switch (kind) {
    OrderEventKind.placed => Icons.shopping_bag_outlined,
    OrderEventKind.paid => Icons.payments_outlined,
    OrderEventKind.picking => Icons.checklist,
    OrderEventKind.packed => Icons.inventory_2_outlined,
    OrderEventKind.shipped => Icons.local_shipping_outlined,
    OrderEventKind.delivered => Icons.home_outlined,
    OrderEventKind.cancelled => Icons.block,
    OrderEventKind.refunded => Icons.undo,
    OrderEventKind.note => Icons.sticky_note_2_outlined,
    OrderEventKind.emailed => Icons.mail_outline,
  };
}

class _Notes extends StatelessWidget {
  final Order order;
  final String Function(String id) nameOf;
  final Widget? composer;

  const _Notes({required this.order, required this.nameOf, this.composer});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final notes = [
      for (final e in order.events)
        if (e.kind == OrderEventKind.note) e,
    ];
    final muted = context.type.caption.copyWith(
      color: context.colors.foregroundMuted,
    );
    final now = clock.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notes.isEmpty)
          Text(strings.noNotes, style: muted)
        else
          for (final note in notes) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(name: note.by ?? '?', size: 28),
                const Gap(AdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${note.by ?? ''} · ${formatAgo(context, note.at, now)}',
                        style: muted,
                      ),
                      NoteText(note.detail ?? '', nameOf: nameOf),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(AdminSpacing.md),
          ],
        if (composer case final composer?) ...[
          const Gap(AdminSpacing.md),
          composer,
        ],
      ],
    );
  }
}
