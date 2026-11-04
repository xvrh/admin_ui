import 'package:admin_ui/collection.dart'
    show AsyncValueBuilder, AsyncValueController, KanbanBoard, SavedView;
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/orders_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';
import '../../widgets/money_text.dart';
import '../../widgets/status_meta.dart';

/// The statuses an order moves through by hand, in order.
const orderStatusFlow = [
  OrderStatus.pending,
  OrderStatus.paid,
  OrderStatus.picking,
  OrderStatus.packed,
  OrderStatus.shipped,
  OrderStatus.delivered,
];

/// A saved view's name in the page's language. The shop's own shared views
/// are stored under English names, and read in the page's language while
/// they keep them; a view someone renamed, or a teammate's, keeps the name
/// typed.
// FRICTION(F-201): SavedViewsBar shows SavedView.name as stored, so the
// shop's seeded views are renamed per language before the bar sees them.
SavedView localizedView(BuildContext context, SavedView view) {
  final strings = context.strings.orders;
  final name = switch ((view.id, view.name)) {
    ('orders-all', 'All') => strings.viewAll,
    ('orders-to-ship', 'To ship') => strings.viewToShip,
    ('orders-refunds', 'Refund requests') => strings.viewRefundRequests,
    _ => null,
  };
  return name == null ? view : view.copyWith(name: name);
}

/// The menu entries that move [order] to another status: the current one
/// checked, cancelling left to the order page, where it asks first.
List<MenuEntry> statusEntries(
  BuildContext context,
  Order order,
  void Function(OrderStatus status) onPick,
) {
  final shell = context.strings.shell;
  return [
    for (final status in orderStatusFlow)
      MenuItem(
        shell.orderStatus(status),
        checked: status == order.status,
        onSelect: status == order.status ? null : () => onPick(status),
      ),
  ];
}

class OrderStatusPill extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) =>
      StatusPill(context.orderStatusMeta(status));
}

/// How the order was paid, and where its money stands: a refund asked for,
/// or part of it given back.
class PaymentSummary extends StatelessWidget {
  final Order order;
  final bool compact;

  const PaymentSummary(this.order, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final tag = order.refundRequested
        ? Tag(
            strings.orders.refundRequested,
            severity: Severity.warning,
            dot: true,
          )
        : order.partiallyRefunded
        ? Tag(strings.shell.partiallyRefunded, severity: Severity.info)
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact || tag == null)
          Flexible(
            child: Text(
              strings.shell.payment(order.payment),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (tag != null) ...[
          if (!compact) const Gap(AdminSpacing.sm),
          Flexible(child: tag),
        ],
      ],
    );
  }
}

/// The customer's avatar and name. Under a mouse, resting on it opens a
/// card with who they are.
class OrderCustomer extends StatelessWidget {
  final Order order;
  final bool hoverCard;

  const OrderCustomer(this.order, {super.key, this.hoverCard = true});

  @override
  Widget build(BuildContext context) {
    final name = Row(
      key: OrdersKeys.customer(order.number),
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(name: order.customerName, size: 24),
        const Gap(AdminSpacing.sm),
        Flexible(
          child: Text(
            order.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    if (!hoverCard) return name;
    return HoverCard(
      side: PopoverSide.bottom,
      align: PopoverAlign.start,
      width: 300,
      content: (context) => CustomerCard(customerId: order.customerId),
      child: name,
    );
  }
}

/// Who a customer is, in a few lines: the hover card's content. It reads
/// the customer as it opens.
class CustomerCard extends StatefulWidget {
  final String customerId;
  const CustomerCard({super.key, required this.customerId});

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  late final _customer = AsyncValueController(
    fetcher: () => context.api.customer(widget.customerId),
  );

  @override
  void dispose() {
    _customer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncValueBuilder<Customer>(
      controller: _customer,
      placeholder: const SkeletonGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 160, height: 16),
            Gap(AdminSpacing.sm),
            Skeleton(width: 200),
            Gap(AdminSpacing.sm),
            Skeleton(width: 120),
          ],
        ),
      ),
      errorBuilder: (error, _) => Text(
        ErrorTextScope.describe(context, error),
        style: context.type.caption,
      ),
      builder: (context, customer) => CustomerHeadline(customer),
    );
  }
}

/// A customer's avatar, name, email and where they live, with their tags.
class CustomerHeadline extends StatelessWidget {
  final Customer customer;

  /// Whether the email, the place, the date and the tags show under the
  /// name: false where a list below says them already.
  final bool details;

  const CustomerHeadline(this.customer, {super.key, this.details = true});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    final muted = context.type.caption.copyWith(
      color: context.colors.foregroundMuted,
    );
    return Row(
      crossAxisAlignment: details
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Avatar(name: customer.name, size: 40),
        const Gap(AdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.name, style: context.type.heading),
              if (details) ...[
                Text(
                  bidiIsolate(customer.email),
                  style: muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(AdminSpacing.xs),
                Text(
                  strings.place(
                    bidiIsolate(customer.city),
                    strings.countryName(customer.country),
                  ),
                  style: context.type.bodySmall,
                ),
                Text(
                  strings.customerSince(
                    formatDate(context, customer.createdAt),
                  ),
                  style: muted,
                ),
                if (customer.tags.isNotEmpty) ...[
                  const Gap(AdminSpacing.sm),
                  CustomerTags(customer.tags),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CustomerTags extends StatelessWidget {
  final List<String> tags;
  const CustomerTags(this.tags, {super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    return Wrap(
      spacing: AdminSpacing.xs,
      runSpacing: AdminSpacing.xs,
      children: [
        for (final tag in tags)
          switch (tag) {
            'vip' => Tag(strings.vip, severity: Severity.success),
            'wholesale' => Tag(strings.wholesale, severity: Severity.info),
            _ => Tag(tag),
          },
      ],
    );
  }
}

/// One order as a card: a phone's list and the fulfilment board.
class OrderCard extends StatelessWidget {
  final Order order;

  /// Whether the card draws its own border, as a board's card does; a
  /// collection's cards get theirs from the collection.
  final bool framed;

  /// Keeps the top-start corner clear for the selection check a collection
  /// lays over a selectable card.
  final bool checkRoom;

  const OrderCard(
    this.order, {
    super.key,
    this.framed = false,
    this.checkRoom = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = context.type.caption.copyWith(color: colors.foregroundMuted);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // FRICTION(F-212): a selectable card's check sits over its
            // content's corner, and nothing says how much room it needs.
            if (checkRoom) const Gap(AdminSpacing.xxl + AdminSpacing.xs),
            Text(order.label, style: context.type.bodyStrong),
            const Gap(AdminSpacing.sm),
            Expanded(
              child: Text(
                formatAgo(context, order.placedAt, clock.now()),
                style: muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!framed) OrderStatusPill(order.status),
          ],
        ),
        const Gap(AdminSpacing.sm),
        OrderCustomer(order, hoverCard: false),
        const Gap(AdminSpacing.sm),
        Row(
          children: [
            Expanded(child: PaymentSummary(order, compact: true)),
            const Gap(AdminSpacing.sm),
            MoneyText(order.totalCents, style: context.type.bodyStrong),
          ],
        ),
      ],
    );
    // Keyed on a box that takes the pointer everywhere on the card, so a
    // tap or a drag aimed at the key lands on the card.
    return DecoratedBox(
      key: OrdersKeys.card(order.number),
      decoration: framed
          ? BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(context.radii.radiusLarge),
              border: Border.all(color: colors.border),
            )
          : const BoxDecoration(),
      child: Padding(
        padding: framed
            ? KanbanBoard.cardPadding
            : const EdgeInsets.all(AdminSpacing.lg),
        child: body,
      ),
    );
  }
}
