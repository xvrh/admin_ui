import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

class ChartDemo extends StatelessWidget {
  @Preview(name: 'Charts / sparklines', wrapper: adminUiPreview)
  const ChartDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 720,
      children: [
        const DemoSection('Sparklines (inline, no axes)'),
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: [
            const _Mini('Line + area', Sparkline([4, 7, 5, 9, 8, 12, 11])),
            _Mini(
              'Line, no fill',
              const Sparkline([4, 7, 5, 9, 8, 12, 11], area: false),
            ),
            _Mini(
              'Down trend (red)',
              Sparkline(const [
                12,
                10,
                11,
                7,
                8,
                5,
                4,
              ], color: context.colors.danger),
            ),
            const _Mini(
              'Bars',
              BarSparkline([4, 7, 5, 9, 8, 12, 11], highlightLast: true),
            ),
            const _Mini('Single point', Sparkline([5])),
            const _Mini('Flat', Sparkline([5, 5, 5, 5])),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection(
          "A StatCard's trend: across it, or beside its figure",
        ),
        StatGrid(
          minTileWidth: 220,
          children: [
            const StatCard(
              label: 'Sessions',
              value: '24.5k',
              delta: StatDelta('8.2%'),
              trend: Sparkline([8, 9, 7, 11, 10, 14, 16], width: null),
            ),
            StatCard(
              label: 'Errors',
              value: '312',
              delta: const StatDelta(
                '5%',
                direction: TrendDirection.up,
                goodWhenUp: false,
              ),
              trend: Sparkline(const [
                2,
                5,
                4,
                8,
                6,
                9,
                12,
              ], color: context.colors.danger),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Line chart — single series (area)'),
        const LineChart(
          height: 220,
          area: true,
          series: [
            ChartSeries('Revenue', [12, 19, 14, 23, 21, 29]),
          ],
          labels: _months,
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Line chart — multi-series'),
        const LineChart(
          series: [
            ChartSeries('This year', [12, 19, 14, 23, 21, 29]),
            ChartSeries('Last year', [9, 11, 13, 15, 14, 18]),
          ],
          labels: _months,
          showDots: true,
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Line chart — eight series (the categorical ramp)'),
        const LineChart(
          series: [
            ChartSeries('Pages', [12, 14, 13, 17, 19, 22]),
            ChartSeries('Articles', [9, 12, 15, 14, 18, 20]),
            ChartSeries('Products', [16, 15, 17, 16, 15, 18]),
            ChartSeries('Events', [4, 6, 5, 9, 8, 11]),
            ChartSeries('Assets', [20, 23, 25, 24, 27, 29]),
            ChartSeries('Authors', [2, 3, 3, 4, 4, 5]),
            ChartSeries('Menus', [7, 7, 8, 8, 9, 9]),
            ChartSeries('Forms', [5, 9, 7, 11, 13, 12]),
          ],
          labels: _months,
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Line chart — long first and last labels'),
        const LineChart(
          area: true,
          series: [
            ChartSeries('Visits', [310, 420, 380, 510, 560, 640]),
          ],
          labels: [
            'Q1 2025 (actual)',
            'Q2 2025',
            'Q3 2025',
            'Q4 2025',
            'Q1 2026',
            'Q2 2026 (forecast)',
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Line chart — with negatives, straight'),
        const LineChart(
          curved: false,
          area: true,
          series: [
            ChartSeries('Net', [4, -3, 6, -2, 8, 5]),
          ],
          labels: _months,
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection(
          'Line chart over time — irregular readings, fixed 0–10 axis',
        ),
        LineChart.time(
          minY: 0,
          maxY: 10,
          showDots: true,
          series: [
            ChartTimeSeries('Score', [
              for (final (day, hour, score) in const [
                (2, 9, 6.5),
                (2, 15, 7.0),
                (4, 10, 6.0),
                (11, 9, 7.5),
                (12, 9, 8.0),
                (26, 14, 5.5),
                (33, 9, 7.0),
              ])
                (DateTime(2026, 3, day, hour), score),
            ]),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Line chart over time — 30 days, weekly ticks'),
        LineChart.time(
          area: true,
          showLegend: false,
          series: [
            ChartTimeSeries('Signups', [
              for (var d = 0; d < 30; d++)
                (DateTime(2026, 3, 1 + d), 40.0 + (d * 37 % 23) + d),
            ]),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar chart — single series'),
        const BarChart(
          series: [
            ChartSeries('Signups', [120, 190, 140, 230, 210, 290]),
          ],
          labels: _months,
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar chart — grouped'),
        const BarChart(
          series: [
            ChartSeries('Desktop', [120, 190, 140, 230]),
            ChartSeries('Mobile', [90, 130, 170, 160]),
          ],
          labels: ['Q1', 'Q2', 'Q3', 'Q4'],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar chart — stacked'),
        const BarChart(
          stacked: true,
          series: [
            ChartSeries('Direct', [40, 55, 38, 62]),
            ChartSeries('Referral', [30, 25, 42, 28]),
            ChartSeries('Social', [20, 35, 25, 40]),
          ],
          labels: ['Q1', 'Q2', 'Q3', 'Q4'],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar chart — stacked, a quarter with no Social'),
        const BarChart(
          stacked: true,
          series: [
            ChartSeries('Direct', [40, 55, 38, 62]),
            ChartSeries('Referral', [30, 25, 42, 28]),
            ChartSeries('Social', [20, 0, 25, 40]),
          ],
          labels: ['Q1', 'Q2', 'Q3', 'Q4'],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar chart — negative values'),
        const BarChart(
          series: [
            ChartSeries('Net change', [42, -18, 27, -35, 12, 58]),
          ],
          labels: _months,
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Donut — breakdown with legend'),
        Builder(
          builder: (context) => DonutChart(
            // Ramp colours are categorical; a neutral state names its own.
            slices: [
              const ChartSlice('Published', 64),
              const ChartSlice('Draft', 21),
              const ChartSlice('Archived', 12),
              ChartSlice('Pending', 7, color: context.colors.foregroundMuted),
            ],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('104', style: context.type.heading),
                Text(
                  'total',
                  style: context.type.caption.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Progress rings'),
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: [
            _Mini(
              '72%',
              Builder(
                builder: (context) => ProgressRing(
                  value: 0.72,
                  center: Text('72%', style: context.type.bodyStrong),
                ),
              ),
            ),
            _Mini(
              'Quota (amber)',
              Builder(
                builder: (context) => ProgressRing(
                  value: 0.91,
                  color: context.colors.warning,
                  center: Text('91%', style: context.type.bodyStrong),
                ),
              ),
            ),
            const _Mini('Empty', ProgressRing(value: 0)),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar list — ranked "top N"'),
        const BarList(
          maxItems: 5,
          items: [
            BarListItem('/blog/launch', 4820),
            BarListItem('/pricing', 3110),
            BarListItem('/', 9240),
            BarListItem('/docs/getting-started', 1870),
            BarListItem('/changelog', 1240),
            BarListItem('/about', 640),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection("Bar list — a funnel, each step's share beside it"),
        _Funnel(formats: context.adminFormats),
        const Gap(AdminSpacing.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: ChartCard(
              title: 'Onboarding',
              subtitle: 'In a narrow card the labels give way',
              bodyHeight: 120,
              chart: _Funnel(formats: context.adminFormats),
            ),
          ),
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar list — a second count: people, then times'),
        BarList(
          formatValue: (v) => context.adminFormats.integer(v.round()),
          items: [
            for (final (label, people, times) in const [
              ('Exported a report', 288, 4120),
              ('Shared a link', 164, 1302),
              ('Left a comment', 97, 655),
              ('Invited a teammate', 41, 58),
            ])
              BarListItem(
                label,
                people.toDouble(),
                detail: '${context.adminFormats.integer(times)} times',
              ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Bar list and line chart — loading'),
        const BarList(
          sort: false,
          loading: true,
          items: [
            BarListItem('Visited', 0),
            BarListItem('Signed up', 0),
            BarListItem('', 0),
            BarListItem('', 0),
          ],
        ),
        const Gap(AdminSpacing.lg),
        const LineChart(
          loading: true,
          series: [ChartSeries('This year', []), ChartSeries('Last year', [])],
          labels: [],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Chart card — populated / loading / empty / error'),
        ChartCard(
          title: 'Revenue',
          subtitle: 'Last 6 months',
          trailing: Tag('6M'),
          chart: const LineChart(
            height: 200,
            area: true,
            showLegend: false,
            series: [
              ChartSeries('Revenue', [12, 19, 14, 23, 21, 29]),
            ],
            labels: _months,
          ),
        ),
        const Gap(AdminSpacing.lg),
        const ChartCard(
          title: 'Revenue',
          subtitle: 'Last 6 months',
          loading: true,
          chart: SizedBox.shrink(),
        ),
        const Gap(AdminSpacing.lg),
        const ChartCard(
          title: 'Revenue',
          subtitle: 'Last 6 months',
          isEmpty: true,
          chart: SizedBox.shrink(),
        ),
        const Gap(AdminSpacing.lg),
        // A card whose own load failed: the error in words, and a retry.
        ChartCard(
          title: 'Revenue',
          subtitle: 'Last 6 months',
          trailing: Tag('6M'),
          error: TimeoutException('revenue'),
          onRetry: () {},
          chart: const SizedBox.shrink(),
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Empty data'),
        const LineChart(series: [ChartSeries('None', [])], labels: []),
      ],
    );
  }
}

/// A [ChartCard] whose `trailing` is a four-option [Segmented] picking the
/// breakdown it charts. On a card in a column of two, about 480 wide, the
/// control goes under the title; on a card the page's width it stays beside
/// it. It stays in the header while the card loads, when the breakdown it
/// picked has no data and when its load failed, so another can be picked.
class ChartCardDemo extends StatelessWidget {
  /// The page's width, or null for a desktop page.
  final double? width;

  /// Whether the page shows the cards whose load failed alone.
  final bool _failedOnly;

  @Preview(name: 'Chart card', wrapper: adminUiPreview)
  const ChartCardDemo({super.key}) : width = null, _failedOnly = false;

  /// The cards at a phone's width, one column of them, every control under
  /// its title.
  @Preview(name: 'Chart card (phone width)', wrapper: adminUiPreview)
  const ChartCardDemo.phone({super.key}) : width = 375, _failedOnly = false;

  /// The cards whose own load failed, at the top of the page.
  @Preview(name: 'Chart card (a failed load)', wrapper: adminUiPreview)
  const ChartCardDemo.failed({super.key}) : width = null, _failedOnly = true;

  /// A card whose load failed and can be tried again, beside one that says
  /// why in the app's own words and offers no retry.
  static const _failed = <Widget>[
    DemoSection('A failed load: the error in words, and the control stays'),
    _Columns([
      _BreakdownCard(failed: true),
      ChartCard(
        title: 'Sign-ups',
        subtitle: 'Last 6 months',
        trailing: Tag('6M'),
        bodyHeight: 140,
        error: 'Sign-ups are being recounted. They will be back shortly.',
        chart: SizedBox.shrink(),
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final phone = width != null;
    if (_failedOnly) {
      return const DemoPage(
        maxWidth: 1040,
        padding: EdgeInsets.all(AdminSpacing.xxxl),
        children: _failed,
      );
    }
    return DemoPage(
      // Two columns of cards about 480 wide, a gap between them.
      maxWidth: width ?? 1040,
      padding: EdgeInsets.all(phone ? AdminSpacing.xl : AdminSpacing.xxxl),
      children: [
        DemoSection(
          phone
              ? "At a phone's width: the control goes under"
              : 'In a column of two: the control goes under',
        ),
        const _Columns([
          _BreakdownCard(),
          ChartCard(
            title: 'Sign-ups',
            subtitle: 'Last 6 months',
            trailing: Tag('6M'),
            bodyHeight: 160,
            chart: LineChart(
              height: 160,
              area: true,
              showLegend: false,
              series: [
                ChartSeries('Sign-ups', [12, 19, 14, 23, 21, 29]),
              ],
              labels: _months,
            ),
          ),
        ]),
        const Gap(AdminSpacing.xxxl),
        if (!phone) ...[
          const DemoSection('The page wide: the control stays beside'),
          const _BreakdownCard(),
          const Gap(AdminSpacing.xxxl),
        ],
        const DemoSection('No data, and loading: the control stays'),
        const _Columns([
          _BreakdownCard(initial: _Breakdown.language),
          _BreakdownCard(loading: true),
        ]),
        const Gap(AdminSpacing.xxxl),
        ..._failed,
      ],
    );
  }
}

/// [children] side by side in equal columns where each keeps 320, else one
/// under the other.
class _Columns extends StatelessWidget {
  final List<Widget> children;

  const _Columns(this.children);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AdminSpacing.lg;
        final width =
            (constraints.maxWidth - gap * (children.length - 1)) /
            children.length;
        if (width < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: children,
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [for (final child in children) Expanded(child: child)],
        );
      },
    );
  }
}

enum _Breakdown { role, organisation, platform, language }

/// Active members broken down by what its [Segmented] picks, starting at
/// [initial]. No member has a language yet, so that breakdown is empty.
/// [failed] is the card after its load timed out, with a Retry.
class _BreakdownCard extends StatefulWidget {
  final _Breakdown initial;
  final bool loading;
  final bool failed;

  const _BreakdownCard({
    this.initial = _Breakdown.role,
    this.loading = false,
    this.failed = false,
  });

  @override
  State<_BreakdownCard> createState() => _BreakdownCardState();
}

class _BreakdownCardState extends State<_BreakdownCard> {
  late var _breakdown = widget.initial;

  static const _items = {
    _Breakdown.role: [
      BarListItem('Viewer', 310),
      BarListItem('Editor', 128),
      BarListItem('Admin', 42),
    ],
    _Breakdown.organisation: [
      BarListItem('North office', 214),
      BarListItem('South office', 162),
      BarListItem('Remote', 104),
    ],
    _Breakdown.platform: [
      BarListItem('Web', 290),
      BarListItem('iOS', 120),
      BarListItem('Android', 70),
    ],
    _Breakdown.language: <BarListItem>[],
  };

  @override
  Widget build(BuildContext context) {
    final items = _items[_breakdown]!;
    return ChartCard(
      title: 'Active members',
      subtitle: 'Signed in at least once in the last 30 days',
      bodyHeight: 140,
      loading: widget.loading,
      error: widget.failed ? TimeoutException('members') : null,
      onRetry: widget.failed ? () {} : null,
      isEmpty: items.isEmpty,
      emptyMessage: 'No member has picked a language yet',
      trailing: Segmented(
        semanticLabel: 'Break down by',
        value: _breakdown,
        onChanged: (value) => setState(() => _breakdown = value),
        segments: const [
          SegmentOption(_Breakdown.role, 'Role'),
          SegmentOption(_Breakdown.organisation, 'Organisation'),
          SegmentOption(_Breakdown.platform, 'Platform'),
          SegmentOption(_Breakdown.language, 'Language'),
        ],
      ),
      chart: BarList(items: items),
    );
  }
}

class _Mini extends StatelessWidget {
  final String caption;
  final Widget child;

  const _Mini(this.caption, this.child);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const Gap(AdminSpacing.sm),
        Text(
          caption,
          style: context.type.caption.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),
      ],
    );
  }
}

/// An onboarding funnel: each step's count, and its share of the first step
/// as the row's detail.
class _Funnel extends StatelessWidget {
  final AdminFormats formats;

  const _Funnel({required this.formats});

  static const _steps = [
    ('Invited', 96),
    ('Signed up', 81),
    ('Joined a team', 64),
    ('Shared a first document with the team', 22),
  ];

  @override
  Widget build(BuildContext context) {
    final first = _steps.first.$2;
    return BarList(
      sort: false,
      formatValue: (v) => formats.integer(v.round()),
      items: [
        for (final (label, count) in _steps)
          BarListItem(
            label,
            count.toDouble(),
            detail: formats.percent(count / first),
          ),
      ],
    );
  }
}
