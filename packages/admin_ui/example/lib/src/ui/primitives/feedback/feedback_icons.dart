import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import 'toast.dart';

/// The severity glyph of the feedback surfaces, replaced by an icon of the
/// caller's or left out: an [Alert], an [AnnouncementBar] and pinned
/// [Toast]s, so a row with no glyph can be checked against one with.
class FeedbackIconsDemo extends StatelessWidget {
  @Preview(name: 'Feedback · icons', wrapper: adminUiPreview)
  const FeedbackIconsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Alert'),
        const Alert(
          'Publishing is scheduled for 09:00 tomorrow.',
          icon: Icons.schedule_rounded,
        ),
        const Gap(AdminSpacing.md),
        const Alert(
          'Some translations are out of date and may show stale content.',
          severity: Severity.warning,
          title: 'Translations need review',
          showIcon: false,
        ),
        const Gap(AdminSpacing.md),
        Alert(
          'Failed to upload 2 files.',
          severity: Severity.danger,
          showIcon: false,
          action: Button.ghost(
            'Retry',
            size: ControlSize.small,
            onPressed: () {},
          ),
          onDismiss: () {},
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Announcement bar'),
        const AnnouncementBar(
          'Changes here are discarded nightly.',
          title: 'Staging environment',
          icon: Icons.dns_outlined,
        ),
        const Gap(AdminSpacing.md),
        AnnouncementBar(
          'All 1,204 pages were reindexed.',
          severity: Severity.success,
          showIcon: false,
          onDismiss: () {},
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Toast'),
        PinnedToastStack(
          width: 320,
          height: 260,
          toasts: [
            const Toast(
              'Scheduled for 09:00.',
              icon: Icons.schedule_rounded,
              duration: null,
            ),
            const Toast(
              'Copied to the clipboard.',
              showIcon: false,
              duration: null,
            ),
            Toast(
              'Item deleted.',
              showIcon: false,
              actionLabel: 'Undo',
              onAction: () {},
              duration: null,
            ),
          ],
        ),
      ],
    );
  }
}
