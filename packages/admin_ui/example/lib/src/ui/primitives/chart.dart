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

        const DemoSection('Sparkline inside a StatCard'),
        StatGrid(
          minTileWidth: 220,
          children: [
            _SparkStat(
              label: 'Sessions',
              value: '24.5k',
              delta: const StatDelta('8.2%'),
              spark: const Sparkline([8, 9, 7, 11, 10, 14, 16], width: null),
            ),
            _SparkStat(
              label: 'Errors',
              value: '312',
              delta: const StatDelta(
                '5%',
                direction: TrendDirection.up,
                goodWhenUp: false,
              ),
              spark: Sparkline(
                const [2, 5, 4, 8, 6, 9, 12],
                color: context.colors.danger,
                width: null,
              ),
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

        const DemoSection('Chart card — populated / loading / empty'),
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
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Empty data'),
        const LineChart(series: [ChartSeries('None', [])], labels: []),
      ],
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

class _SparkStat extends StatelessWidget {
  final String label;
  final String value;
  final StatDelta delta;
  final Widget spark;

  const _SparkStat({
    required this.label,
    required this.value,
    required this.delta,
    required this.spark,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.type.caption.copyWith(
              color: context.colors.foregroundMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AdminSpacing.md),
          Text(
            value,
            style: context.type.pageTitle.copyWith(
              color: context.colors.foreground,
            ),
          ),
          const Gap(AdminSpacing.lg),
          SizedBox(width: double.infinity, child: spark),
        ],
      ),
    );
  }
}
