import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class TimelineDemo extends StatelessWidget {
  @Preview(name: 'Timeline / activity', wrapper: adminUiPreview)
  const TimelineDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 480,
      children: [
        const DemoSection('Activity feed'),
        Timeline(
          entries: [
            TimelineEntry(
              titleWidget: _RichLine('Maya Cohen', ' published the page'),
              timestamp: '2 hours ago',
              color: context.colors.success,
              icon: Icons.publish_rounded,
              trailing: const Tag('Published', severity: Severity.success),
            ),
            TimelineEntry(
              titleWidget: _RichLine('Tom Lee', ' left a comment'),
              subtitle: '“Can we tighten the hero copy before this goes out?”',
              timestamp: 'Yesterday · 16:40',
              leading: const Avatar(initials: 'TL', size: 24),
            ),
            TimelineEntry(
              titleWidget: _RichLine('Maya Cohen', ' edited 3 fields'),
              subtitle: 'Title, Slug, Excerpt',
              timestamp: 'Yesterday · 11:02',
              icon: Icons.edit_rounded,
            ),
            TimelineEntry(
              titleWidget: _RichLine('System', ' created the draft'),
              timestamp: 'Mon · 09:15',
              color: context.colors.foregroundMuted,
              icon: Icons.add_rounded,
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Plain titles, dot nodes'),
        const Timeline(
          entries: [
            TimelineEntry(title: 'Deployment succeeded', timestamp: '12:30'),
            TimelineEntry(title: 'Build passed', timestamp: '12:24'),
            TimelineEntry(title: 'Pushed 4 commits', timestamp: '12:20'),
          ],
        ),
      ],
    );
  }
}

class _RichLine extends StatelessWidget {
  final String bold;
  final String rest;

  const _RichLine(this.bold, this.rest);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: context.type.body.copyWith(color: context.colors.foreground),
        children: [
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: rest,
            style: TextStyle(color: context.colors.foregroundMuted),
          ),
        ],
      ),
    );
  }
}
