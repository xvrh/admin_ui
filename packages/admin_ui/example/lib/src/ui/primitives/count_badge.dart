import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class CountBadgeDemo extends StatelessWidget {
  @Preview(name: 'Count badge', wrapper: adminUiPreview)
  const CountBadgeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 420,
      children: [
        const DemoSection('On an icon'),
        Wrap(
          spacing: AdminSpacing.xxl,
          children: [
            CountBadge(
              count: 3,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: context.colors.foregroundSecondary,
              ),
            ),
            CountBadge(
              count: 128,
              child: Icon(
                Icons.mail_outline_rounded,
                size: 26,
                color: context.colors.foregroundSecondary,
              ),
            ),
            CountBadge(
              dot: true,
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 26,
                color: context.colors.foregroundSecondary,
              ),
            ),
            CountBadge(
              count: 0, // hidden
              child: Icon(
                Icons.inbox_outlined,
                size: 26,
                color: context.colors.foregroundSecondary,
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('On a card — the ring takes the card colour'),
        Panel(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Wrap(
            spacing: AdminSpacing.xxl,
            children: [
              CountBadge(
                count: 5,
                semanticLabel: '5 unread notifications',
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: context.colors.foregroundSecondary,
                ),
              ),
              CountBadge(
                count: 240,
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 26,
                  color: context.colors.foregroundSecondary,
                ),
              ),
              CountBadge(
                dot: true,
                semanticLabel: 'New messages',
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 26,
                  color: context.colors.foregroundSecondary,
                ),
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Standalone'),
        const Wrap(
          spacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CountBadge(count: 1),
            CountBadge(count: 24),
            CountBadge(count: 1500, max: 999),
            CountBadge(dot: true),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Custom colour — digits pick white or near-black'),
        Wrap(
          spacing: AdminSpacing.md,
          children: [
            CountBadge(count: 5, color: context.colors.success),
            CountBadge(count: 9, color: context.colors.warning),
            CountBadge(count: 2, color: context.colors.primary),
            CountBadge(count: 4, color: context.colors.info),
            CountBadge(count: 12, color: context.colors.foregroundSecondary),
            CountBadge(count: 7, color: context.colors.foregroundFaint),
          ],
        ),
        const Gap(AdminSpacing.lg),
        Wrap(
          spacing: AdminSpacing.xxl,
          children: [
            for (final color in [
              context.colors.warning,
              context.colors.primary,
              context.colors.success,
            ])
              CountBadge(
                count: 8,
                color: color,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: context.colors.foregroundSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
