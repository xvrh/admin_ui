import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class StatCardDemo extends StatelessWidget {
  /// The page's width, or null for a desktop page.
  final double? width;

  @Preview(name: 'Stat card / dashboard', wrapper: adminUiPreview)
  const StatCardDemo({super.key}) : width = null;

  /// At a phone's width: the tiles two across, 165.5 wide, loaded and
  /// loading.
  @Preview(name: 'Stat card / dashboard (phone width)', wrapper: adminUiPreview)
  const StatCardDemo.phone({super.key}) : width = 375;

  @override
  Widget build(BuildContext context) {
    final phone = width != null;
    final minTileWidth = phone ? 140.0 : 200.0;
    return DemoPage(
      maxWidth: width ?? 760,
      padding: EdgeInsets.all(phone ? AdminSpacing.xl : AdminSpacing.xxxl),
      children: [
        DemoSection(
          phone ? 'Two across a phone' : 'Dashboard grid (responsive)',
        ),
        StatGrid(
          minTileWidth: minTileWidth,
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

        if (!phone) ...const [
          DemoSection('Minimal — value only'),
          StatGrid(
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
          Gap(AdminSpacing.xxxl),
        ],

        DemoSection(
          phone
              ? 'Loading, two across'
              : 'Loading — as tall as the loaded cards',
        ),
        StatGrid(
          minTileWidth: minTileWidth,
          children: const [
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
