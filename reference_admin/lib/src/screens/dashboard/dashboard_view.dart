import 'dart:math' as math;

import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/access_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../widgets/page_width.dart';

/// What the dashboard shows: the stats of a range, and the shop's settings
/// when nothing has sold yet (whether it was ever set up).
class DashboardData {
  final DashboardStats stats;
  final ShopSettings? shop;
  const DashboardData({required this.stats, this.shop});
}

/// The dashboard as a pure widget: the greeting, the range picker, the
/// KPIs, what needs attention and the charts, or the loading, failed and
/// empty-shop states in their place.
class DashboardView extends StatelessWidget {
  final String userName;
  final DateTime now;
  final DashboardRange range;

  /// The last stats loaded; kept while another range loads.
  final DashboardData? data;
  final ShopError? error;
  final bool loading;
  final bool canSetUp;
  final ValueChanged<DashboardRange> onRange;
  final VoidCallback onRetry;
  final ValueChanged<AppRoute> onOpen;
  final VoidCallback onSetUp;

  const DashboardView({
    super.key,
    required this.userName,
    required this.now,
    required this.range,
    required this.data,
    required this.error,
    required this.loading,
    required this.canSetUp,
    required this.onRange,
    required this.onRetry,
    required this.onOpen,
    required this.onSetUp,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final formats = context.adminFormats;
    final data = this.data;
    final error = this.error;
    final firstName = userName.split(' ').first;
    final compact = AdminBreakpoint.of(context).isCompact;

    final Widget body;
    if (error != null) {
      body = Panel(
        child: ErrorState(
          key: AccessKeys.statsError,
          title: strings.statsErrorTitle,
          message: context.strings.shell.error(error),
          onRetry: onRetry,
          minHeight: 320,
        ),
      );
    } else if (data == null) {
      body = _Loading(compact: compact);
    } else if (data.stats.isEmpty) {
      body = _EmptyShop(
        setupDone: data.shop?.setupComplete ?? true,
        canSetUp: canSetUp,
        onSetUp: onSetUp,
      );
    } else {
      body = _Loaded(
        stats: data.stats,
        now: now,
        compact: compact,
        onOpen: onOpen,
      );
    }

    // With nothing sold yet there is no period to compare.
    final empty = data != null && data.stats.isEmpty;
    return PageScaffold(
      key: AccessKeys.dashboardPage,
      title: strings.greeting(now.hour, firstName),
      subtitle: empty
          ? null
          : strings.comparedWith(range.days, formats.integer(range.days)),
      titleLoading: loading && data != null,
      maxWidth: pageMaxWidth,
      actions: [
        if (!empty)
          Segmented<DashboardRange>(
            key: AccessKeys.range,
            semanticLabel: strings.rangeLabel,
            value: range,
            size: compact ? ControlSize.small : ControlSize.medium,
            onChanged: onRange,
            segments: [
              for (final r in DashboardRange.values)
                SegmentOption(
                  r,
                  strings.rangeSegment(r.days, formats.integer(r.days)),
                ),
            ],
          ),
      ],
      body: body,
    );
  }
}

const _gap = AdminSpacing.xl;

class _Loaded extends StatelessWidget {
  final DashboardStats stats;
  final DateTime now;
  final bool compact;
  final ValueChanged<AppRoute> onOpen;

  const _Loaded({
    required this.stats,
    required this.now,
    required this.compact,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final kpis = _Kpis(stats: stats, compact: compact);
    final attention = _Attention(counts: stats.attention, onOpen: onOpen);
    // The series are whole days, up to yesterday.
    final revenue = _RevenueChart(
      stats: stats,
      lastDay: DateTime(now.year, now.month, now.day - 1),
    );
    final top = _TopProducts(stats: stats);
    final channels = _Channels(stats: stats);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: compact
          ? [
              attention,
              const Gap(_gap),
              kpis,
              const Gap(_gap),
              revenue,
              const Gap(_gap),
              top,
              const Gap(_gap),
              channels,
            ]
          : [
              kpis,
              const Gap(_gap),
              attention,
              const Gap(_gap),
              revenue,
              const Gap(_gap),
              // FRICTION(F-108): DonutChart's legend overflows a narrow card
              // rather than wrapping, so the two cards stack below this width.
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 880
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [top, const Gap(_gap), channels],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: top),
                            const Gap(_gap),
                            Expanded(flex: 2, child: channels),
                          ],
                        ),
                      ),
              ),
            ],
    );
  }
}

/// Four KPI tiles, each with its change over the period before and its
/// trend. Two across on a phone.
class _Kpis extends StatelessWidget {
  final DashboardStats stats;
  final bool compact;

  const _Kpis({required this.stats, required this.compact});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final formats = context.adminFormats;
    // A tile has room for about a month of points: a quarter's days are
    // summed in threes, so its trend reads as clearly as a month's.
    final days = math.max(
      1,
      (stats.revenueSeries.length / _trendPoints).ceil(),
    );
    final revenue = _summed(stats.revenueSeries, days);
    final orders = _summed(stats.ordersSeries, days);
    final averages = [
      for (var i = 0; i < revenue.length; i++)
        orders[i] == 0 ? 0 : revenue[i] / orders[i],
    ];
    return StatGrid(
      key: AccessKeys.stats,
      minTileWidth: compact ? 150 : 220,
      spacing: compact ? AdminSpacing.md : AdminSpacing.lg,
      children: [
        _Kpi(
          key: AccessKeys.revenue,
          label: strings.kpiRevenue,
          value: formatMoney(context, stats.revenueCents),
          current: stats.revenueCents,
          previous: stats.previousRevenueCents,
          trend: revenue,
          icon: Icons.payments_outlined,
        ),
        _Kpi(
          label: strings.kpiOrders,
          value: formats.integer(stats.orders),
          current: stats.orders,
          previous: stats.previousOrders,
          trend: orders,
          icon: Icons.receipt_long_outlined,
        ),
        _Kpi(
          label: strings.kpiAverageOrder,
          value: formatMoney(context, stats.averageOrderCents),
          current: stats.averageOrderCents,
          previous: stats.previousAverageOrderCents,
          trend: averages,
          icon: Icons.shopping_basket_outlined,
        ),
        // A shop gains a customer or two a day, which a daily line draws
        // as a zigzag; the running total climbs to the figure on the card.
        _Kpi(
          label: strings.kpiNewCustomers,
          value: formats.integer(stats.newCustomers),
          current: stats.newCustomers,
          previous: stats.previousNewCustomers,
          trend: _runningTotal(_summed(stats.customersSeries, days)),
          icon: Icons.person_add_alt_outlined,
        ),
      ],
    );
  }
}

const _trendPoints = 30;

/// [daily] summed over runs of [days], oldest first.
List<int> _summed(List<int> daily, int days) => [
  for (var i = 0; i < daily.length; i += days)
    daily.skip(i).take(days).fold(0, (sum, n) => sum + n),
];

List<int> _runningTotal(List<int> values) {
  var sum = 0;
  return [for (final n in values) sum += n];
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final int current;
  final int previous;
  final List<num> trend;
  final IconData icon;

  const _Kpi({
    super.key,
    required this.label,
    required this.value,
    required this.current,
    required this.previous,
    required this.trend,
    required this.icon,
  });

  StatDelta? _delta(BuildContext context) {
    if (previous == 0) {
      return current == 0 ? null : StatDelta(context.strings.access.deltaNew);
    }
    final change = (current - previous) / previous;
    final direction = change.abs() < 0.005
        ? TrendDirection.flat
        : change > 0
        ? TrendDirection.up
        : TrendDirection.down;
    return StatDelta(
      context.adminFormats.percent(change.abs()),
      direction: direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    // FRICTION(F-101): StatCard has no slot for a trend line; the
    // sparkline is laid over the card's delta row from outside.
    return Stack(
      children: [
        StatCard(
          label: label,
          value: value,
          icon: icon,
          delta: _delta(context),
        ),
        PositionedDirectional(
          end: AdminSpacing.xl,
          bottom: AdminSpacing.xl,
          child: ExcludeSemantics(
            child: Sparkline(
              [for (final v in trend) v.toDouble()],
              width: 72,
              height: 22,
              showDot: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _Attention extends StatelessWidget {
  final AttentionCounts counts;
  final ValueChanged<AppRoute> onOpen;

  const _Attention({required this.counts, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    return AttentionGrid(
      key: AccessKeys.attention,
      title: strings.attentionTitle,
      emptyMessage: strings.attentionClear,
      items: [
        if (counts.toShip > 0)
          AttentionItem(
            label: strings.attentionToShip,
            count: counts.toShip,
            icon: Icons.local_shipping_outlined,
            tone: Severity.info,
            caption: strings.attentionToShipCaption,
            onTap: () => onOpen(const Orders(savedView: 'orders-to-ship')),
          ),
        if (counts.refundRequests > 0)
          AttentionItem(
            label: strings.attentionRefunds,
            count: counts.refundRequests,
            icon: Icons.undo_rounded,
            tone: Severity.danger,
            caption: strings.attentionRefundsCaption,
            onTap: () => onOpen(const Orders(savedView: 'orders-refunds')),
          ),
        if (counts.lowStock > 0)
          AttentionItem(
            label: strings.attentionLowStock,
            count: counts.lowStock,
            icon: Icons.inventory_2_outlined,
            tone: Severity.warning,
            caption: strings.attentionLowStockCaption,
            onTap: () =>
                onOpen(const Products(savedView: 'products-low-stock')),
          ),
        if (counts.missingTranslations > 0)
          AttentionItem(
            label: strings.attentionMissingTranslations,
            count: counts.missingTranslations,
            icon: Icons.translate_rounded,
            tone: Severity.info,
            caption: strings.attentionMissingTranslationsCaption,
            onTap: () => onOpen(
              const Products(savedView: 'products-missing-translations'),
            ),
          ),
      ],
    );
  }
}

/// Euros in [context]'s locale, short enough for an axis: `€1.2K`.
// FRICTION(F-009): no compact currency in AdminFormats.
String _compactMoney(BuildContext context, double euros) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.compactSimpleCurrency(
    locale: locale,
    name: 'EUR',
    decimalDigits: euros == euros.roundToDouble() && euros < 1000 ? 0 : null,
  ).format(euros);
}

class _RevenueChart extends StatelessWidget {
  final DashboardStats stats;

  /// The last day of the series.
  final DateTime lastDay;

  const _RevenueChart({required this.stats, required this.lastDay});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final days = stats.revenueSeries.length;
    return ChartCard(
      key: AccessKeys.revenueChart,
      title: strings.revenueChart,
      subtitle: strings.revenueChartSubtitle(
        context.adminFormats.integer(stats.range.days),
      ),
      chart: LineChart.time(
        series: [
          ChartTimeSeries(strings.kpiRevenue, [
            for (final (i, cents) in stats.revenueSeries.indexed)
              (
                DateTime(
                  lastDay.year,
                  lastDay.month,
                  lastDay.day - (days - 1 - i),
                ),
                cents / 100,
              ),
          ]),
        ],
        area: true,
        showLegend: false,
        formatY: (v) => _compactMoney(context, v),
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  final DashboardStats stats;
  const _TopProducts({required this.stats});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final language = Localizations.localeOf(context).languageCode;
    return ChartCard(
      key: AccessKeys.topProducts,
      title: strings.topProductsChart,
      subtitle: strings.topProductsSubtitle,
      bodyHeight: 200,
      isEmpty: stats.topProducts.isEmpty,
      chart: BarList(
        items: [
          for (final p in stats.topProducts)
            BarListItem(inLanguage(p.name, language), p.units.toDouble()),
        ],
        formatValue: (v) => context.adminFormats.integer(v.round()),
      ),
    );
  }
}

class _Channels extends StatelessWidget {
  final DashboardStats stats;
  const _Channels({required this.stats});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final total = stats.channels.values.fold(0, (a, b) => a + b);
    return ChartCard(
      key: AccessKeys.channels,
      title: strings.access.channelsChart,
      subtitle: strings.access.channelsSubtitle,
      bodyHeight: 200,
      isEmpty: total == 0,
      chart: Center(
        child: DonutChart(
          size: 148,
          slices: [
            for (final c in OrderChannel.values)
              ChartSlice(
                strings.shell.channel(c),
                (stats.channels[c] ?? 0).toDouble(),
              ),
          ],
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.adminFormats.integer(total),
                style: context.type.heading,
              ),
              Text(
                strings.access.ordersUnit,
                style: context.type.caption.copyWith(
                  color: context.colors.foregroundMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final bool compact;
  const _Loading({required this.compact});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    // The tiles' names and glyphs show while their figures load.
    final tiles = StatGrid(
      minTileWidth: compact ? 150 : 220,
      spacing: compact ? AdminSpacing.md : AdminSpacing.lg,
      children: [
        StatCard(
          label: strings.kpiRevenue,
          icon: Icons.payments_outlined,
          loading: true,
        ),
        StatCard(
          label: strings.kpiOrders,
          icon: Icons.receipt_long_outlined,
          loading: true,
        ),
        StatCard(
          label: strings.kpiAverageOrder,
          icon: Icons.shopping_basket_outlined,
          loading: true,
        ),
        StatCard(
          label: strings.kpiNewCustomers,
          icon: Icons.person_add_alt_outlined,
          loading: true,
        ),
      ],
    );
    final attention = AttentionGrid(
      title: strings.attentionTitle,
      items: const [],
      loading: true,
    );
    final chart = ChartCard(
      title: strings.revenueChart,
      loading: true,
      chart: const SizedBox.shrink(),
    );
    return Column(
      key: AccessKeys.loading,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: compact
          ? [attention, const Gap(_gap), tiles, const Gap(_gap), chart]
          : [tiles, const Gap(_gap), attention, const Gap(_gap), chart],
    );
  }
}

class _EmptyShop extends StatelessWidget {
  final bool setupDone;
  final bool canSetUp;
  final VoidCallback onSetUp;

  const _EmptyShop({
    required this.setupDone,
    required this.canSetUp,
    required this.onSetUp,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final offerSetup = !setupDone && canSetUp;
    return Panel(
      child: EmptyState(
        key: AccessKeys.empty,
        icon: Icons.local_florist_outlined,
        title: strings.emptyTitle,
        message: offerSetup
            ? strings.emptySetupMessage
            : strings.emptyReadyMessage,
        minHeight: math.max(320, MediaQuery.sizeOf(context).height / 2),
        action: offerSetup
            ? Button.primary(
                strings.setUpShop,
                key: AccessKeys.setUpShop,
                icon: Icons.storefront_outlined,
                onPressed: onSetUp,
              )
            : null,
      ),
    );
  }
}
