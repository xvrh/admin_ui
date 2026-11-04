import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class SkeletonDemo extends StatelessWidget {
  @Preview(name: 'Skeleton', wrapper: adminUiPreview)
  const SkeletonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Building blocks'),
        const Skeleton(),
        const Gap(AdminSpacing.lg),
        const Skeleton(width: 180),
        const Gap(AdminSpacing.lg),
        const Row(
          children: [
            Skeleton.circle(size: 40),
            Gap(AdminSpacing.lg),
            Expanded(child: Skeleton(height: 14)),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Paragraph'),
        const SkeletonGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 10),
              Gap(AdminSpacing.md),
              Skeleton(height: 10),
              Gap(AdminSpacing.md),
              Skeleton(width: 220, height: 10),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('List rows — synced via SkeletonGroup'),
        const Panel(
          padding: EdgeInsets.all(AdminSpacing.lg),
          child: SkeletonGroup(
            child: Column(
              children: [
                _ListRow(),
                Gap(AdminSpacing.lg),
                _ListRow(),
                Gap(AdminSpacing.lg),
                _ListRow(),
              ],
            ),
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Card'),
        const Panel(
          child: Padding(
            padding: EdgeInsets.all(AdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 120, borderRadius: BorderRadius.zero),
                Gap(AdminSpacing.lg),
                Skeleton(width: 200, height: 14),
                Gap(AdminSpacing.md),
                Skeleton(height: 10),
                Gap(AdminSpacing.sm),
                Skeleton(width: 160, height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Skeleton(width: 36, height: 36),
        Gap(AdminSpacing.lg),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 140, height: 10),
              Gap(AdminSpacing.md),
              Skeleton(width: 90, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
