import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Full-bleed notice bars across the four severities, plus title / action /
/// dismiss permutations, a long message that wraps and one clipped to a line
/// behind "Show more".
class AnnouncementBarDemo extends StatefulWidget {
  @Preview(name: 'Announcement bar', wrapper: adminUiPreview)
  const AnnouncementBarDemo({super.key});

  @override
  State<AnnouncementBarDemo> createState() => _AnnouncementBarDemoState();
}

class _AnnouncementBarDemoState extends State<AnnouncementBarDemo> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    // Full-bleed, so the bars opt out of the page's width cap.
    return DemoPage(
      maxWidth: 720,
      padding: EdgeInsets.zero,
      children: [
        const _Pad(DemoSection('Severities')),
        const AnnouncementBar(
          'A read-only mirror of production — changes here are discarded nightly.',
          severity: Severity.info,
          title: 'Staging environment',
        ),
        const Gap(AdminSpacing.md),
        const AnnouncementBar(
          'All 1,204 pages were reindexed successfully.',
          severity: Severity.success,
        ),
        const Gap(AdminSpacing.md),
        const AnnouncementBar(
          'Your plan’s media quota is 90% full.',
          severity: Severity.warning,
          title: 'Heads up',
        ),
        const Gap(AdminSpacing.md),
        const AnnouncementBar(
          'Scheduled maintenance Sunday 02:00–03:00 UTC. Publishing will be paused.',
          severity: Severity.danger,
        ),
        const Gap(AdminSpacing.xxl),

        const _Pad(DemoSection('With action + dismiss')),
        if (_dismissed)
          _Pad(
            Button(
              'Restore bar',
              icon: Icons.refresh_rounded,
              onPressed: () => setState(() => _dismissed = false),
            ),
          )
        else
          AnnouncementBar(
            'A new version of the editor is available.',
            severity: Severity.info,
            title: 'Update ready',
            action: Button.primary(
              'Reload',
              size: ControlSize.small,
              onPressed: () {},
            ),
            onDismiss: () => setState(() => _dismissed = true),
          ),
        const Gap(AdminSpacing.xxl),

        const _Pad(
          DemoSection(
            'Long message — wraps; icon, action and close stay on line one',
          ),
        ),
        AnnouncementBar(
          'Publishing is paused while the search index rebuilds. Drafts still '
          'save, and everything queued goes live in the order it was '
          'scheduled once the rebuild finishes, in about twenty minutes.',
          severity: Severity.warning,
          title: 'Publishing paused',
          action: Button('Details', size: ControlSize.small, onPressed: () {}),
          onDismiss: () {},
        ),
        const Gap(AdminSpacing.xxl),

        const _Pad(DemoSection('maxLines: 1 — the rest behind “Show more”')),
        const AnnouncementBar(
          'Staging mirrors production every night at 02:00 UTC: pages, media '
          'and users are copied over and anything changed here since the '
          'last copy is discarded.',
          severity: Severity.info,
          title: 'Staging environment',
          maxLines: 1,
        ),
        const Gap(AdminSpacing.xxl),

        const _Pad(DemoSection('Capped content width (wide frame)')),
        const AnnouncementBar(
          'On very wide app frames, cap the content so the line length stays readable.',
          severity: Severity.info,
          maxContentWidth: 520,
        ),
      ],
    );
  }
}

/// Restores the page gutter for the non-bleed bits (headers, buttons) while the
/// bars themselves run edge to edge.
class _Pad extends StatelessWidget {
  final Widget child;

  const _Pad(this.child);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AdminSpacing.xxl,
      AdminSpacing.lg,
      AdminSpacing.xxl,
      0,
    ),
    child: child,
  );
}
