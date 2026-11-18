import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class StatCardDemo extends StatelessWidget {
  @Preview(name: 'Stat card / dashboard', wrapper: adminUiPreview)
  const StatCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 760,
      children: [
        const DemoSection('Dashboard grid (responsive)'),
        StatGrid(
          children: [
            StatCard(
              label: 'Revenue',
              value: '\$48.2k',
              icon: Icons.payments_rounded,
              delta: const StatDelta('12%', direction: TrendDirection.up),
              caption: 'vs last month',
              onTap: () {},
            ),
            const StatCard(
              label: 'Active users',
              value: '9,204',
              icon: Icons.group_rounded,
              delta: StatDelta('3.1%', direction: TrendDirection.up),
              caption: 'vs last month',
            ),
            const StatCard(
              label: 'Bounce rate',
              value: '41%',
              icon: Icons.call_missed_outgoing_rounded,
              // up is bad here → renders red
              delta: StatDelta(
                '5%',
                direction: TrendDirection.up,
                goodWhenUp: false,
              ),
              caption: 'vs last month',
            ),
            const StatCard(
              label: 'Churn',
              value: '1.8%',
              icon: Icons.exit_to_app_rounded,
              delta: StatDelta(
                '0.4%',
                direction: TrendDirection.down,
                goodWhenUp: false,
              ),
              caption: 'vs last month',
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Minimal — value only'),
        const StatGrid(
          minTileWidth: 160,
          children: [
            StatCard(label: 'Posts', value: '312'),
            StatCard(label: 'Drafts', value: '18'),
            StatCard(label: 'Comments', value: '1,047'),
            StatCard(
              label: 'Storage',
              value: '6.4 GB',
              delta: StatDelta('flat', direction: TrendDirection.flat),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Loading — as tall as the loaded cards'),
        const StatGrid(
          children: [
            StatCard(
              label: 'Revenue',
              icon: Icons.payments_rounded,
              delta: StatDelta(''),
              caption: '',
              loading: true,
            ),
            StatCard(
              label: 'Active users',
              icon: Icons.group_rounded,
              caption: '',
              loading: true,
            ),
            StatCard(delta: StatDelta(''), loading: true),
            StatCard(loading: true),
          ],
        ),
      ],
    );
  }
}

/// Activity tiles, two with the last 30 days as a trend and two without: the
/// trend beside the figure where the card has room for both, under the delta
/// and caption where it has not or where it fills the card's width, and a
/// block in its place while the figures load.
class StatCardTrendDemo extends StatelessWidget {
  /// The page's width, or null for a desktop page.
  final double? width;

  @Preview(name: 'Stat card / trend', wrapper: adminUiPreview)
  const StatCardTrendDemo({super.key}) : width = null;

  /// At a phone's width: one column of cards, each trend beside its figure,
  /// or under it when it fills the card's width.
  @Preview(name: 'Stat card / trend (phone width)', wrapper: adminUiPreview)
  const StatCardTrendDemo.phone({super.key}) : width = 375;

  @override
  Widget build(BuildContext context) {
    final phone = width != null;
    return DemoPage(
      maxWidth: width ?? 1040,
      padding: EdgeInsets.all(phone ? AdminSpacing.xl : AdminSpacing.xxxl),
      children: [
        DemoSection(
          phone
              ? 'One column: the trend beside the figure'
              : 'Four across: the trend beside the figure',
        ),
        const _Activity(),
        const Gap(AdminSpacing.xxl),
        const _Activity(loading: true),
        const Gap(AdminSpacing.xxxl),
        if (phone) ...const [
          DemoSection('Filling its width: the trend under'),
          _Activity(fill: true),
          Gap(AdminSpacing.xxl),
          _Activity(fill: true, loading: true),
        ] else ...const [
          DemoSection('Two across a narrow column: the trend under'),
          _NarrowColumn(_Activity()),
          Gap(AdminSpacing.xxl),
          _NarrowColumn(_Activity(loading: true)),
        ],
      ],
    );
  }
}

/// Up to 440 wide, at the start.
class _NarrowColumn extends StatelessWidget {
  final Widget child;

  const _NarrowColumn(this.child);

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: child,
    ),
  );
}

/// Who was active each day of the last 30, and who signed up.
const _active = <double>[
  ...[212, 218, 205, 221, 230, 226, 219, 232, 240, 236, 228, 241, 247, 239],
  ...[245, 251, 249, 238, 244, 256, 260, 253, 248, 259, 264, 258, 262, 270],
  ...[266, 268],
];
const _signUps = <double>[
  ...[4, 6, 3, 5, 7, 2, 4, 6, 5, 8, 4, 3, 6, 7, 5, 4, 9, 6, 5, 7, 4, 6, 8],
  ...[5, 7, 6, 9, 5, 8, 6],
];

/// A product's activity tiles: active people and sign-ups over the last 7
/// days with their last 30 days as a trend, messages and open reports
/// without one, so that every row has cards with and without.
class _Activity extends StatelessWidget {
  /// Whether the trends fill the card's width.
  final bool fill;
  final bool loading;

  const _Activity({this.fill = false, this.loading = false});

  @override
  Widget build(BuildContext context) {
    String text(String words) => loading ? '' : words;
    final width = fill ? null : 88.0;
    return StatGrid(
      children: [
        StatCard(
          label: 'Active, last 7 days',
          value: text('268'),
          icon: Icons.group_rounded,
          delta: StatDelta(text('12')),
          caption: text('vs the week before'),
          trend: Sparkline(loading ? const [] : _active, width: width),
          loading: loading,
        ),
        StatCard(
          label: 'Messages sent',
          value: text('1,906'),
          icon: Icons.chat_bubble_outline_rounded,
          delta: StatDelta(text('3%'), direction: TrendDirection.down),
          caption: text('vs the week before'),
          loading: loading,
        ),
        StatCard(
          label: 'Sign-ups, last 7 days',
          value: text('41'),
          icon: Icons.person_add_alt_rounded,
          delta: StatDelta(text('6')),
          caption: text('vs the week before'),
          trend: BarSparkline(
            loading ? const [] : _signUps,
            highlightLast: true,
            width: width,
          ),
          loading: loading,
        ),
        StatCard(
          label: 'Open reports',
          value: text('7'),
          icon: Icons.flag_outlined,
          caption: text('the oldest from yesterday'),
          loading: loading,
        ),
      ],
    );
  }
}
