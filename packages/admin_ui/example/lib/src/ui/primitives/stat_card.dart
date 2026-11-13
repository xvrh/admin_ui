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
