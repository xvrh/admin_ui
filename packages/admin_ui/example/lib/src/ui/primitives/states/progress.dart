import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class ProgressBarDemo extends StatelessWidget {
  @Preview(name: 'Progress bar', wrapper: adminUiPreview)
  const ProgressBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Bare bar — fill levels'),
        for (final v in const [0.0, 0.25, 0.62, 1.0])
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
            child: ProgressBar(value: v),
          ),
        const Gap(AdminSpacing.md),

        const DemoSection('Indeterminate (total unknown)'),
        const ProgressBar(value: null),
        const Gap(AdminSpacing.xl),

        const DemoSection('Thickness'),
        const ProgressBar(value: 0.55, thickness: 3),
        const Gap(AdminSpacing.lg),
        const ProgressBar(value: 0.55),
        const Gap(AdminSpacing.lg),
        const ProgressBar(value: 0.55, thickness: 10),
        const Gap(AdminSpacing.xl),

        const DemoSection('Severity'),
        const ProgressBar(value: 0.7),
        for (final (value, severity) in const [
          (0.5, Severity.info),
          (1.0, Severity.success),
          (0.92, Severity.warning),
          (0.4, Severity.danger),
        ]) ...[
          const Gap(AdminSpacing.lg),
          ProgressBar(value: value, severity: severity),
        ],
        const Gap(AdminSpacing.xl),

        const DemoSection('With label + percent'),
        const ProgressBar(
          value: 0.62,
          label: 'brochure_final.pdf',
          showPercent: true,
        ),
        const Gap(AdminSpacing.lg),
        const ProgressBar(value: 0.9, label: 'Uploading…'),
        const Gap(AdminSpacing.lg),
        const ProgressBar(value: 0.33, showPercent: true),
        const Gap(AdminSpacing.lg),
        const ProgressBar(
          value: 1.0,
          severity: Severity.success,
          label: 'Done',
          showPercent: true,
        ),
      ],
    );
  }
}

/// The fill in each [Severity], beside the primary fill of work in flight:
/// info, success once it completes, warning near a limit, danger once it
/// failed partway.
class ProgressBarSeveritiesDemo extends StatelessWidget {
  @Preview(name: 'Progress bar · severities', wrapper: adminUiPreview)
  const ProgressBarSeveritiesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPage(
      maxWidth: 520,
      children: [
        DemoSection('In flight — no severity'),
        ProgressBar(
          value: 0.62,
          label: 'Importing 420 rows',
          showPercent: true,
        ),
        Gap(AdminSpacing.xl),
        DemoSection('Severities'),
        ProgressBar(
          value: 0.5,
          severity: Severity.info,
          label: 'Info — syncing in the background',
          showPercent: true,
        ),
        Gap(AdminSpacing.lg),
        ProgressBar(
          value: 1.0,
          severity: Severity.success,
          label: 'Success — upload complete',
          showPercent: true,
        ),
        Gap(AdminSpacing.lg),
        ProgressBar(
          value: 0.92,
          severity: Severity.warning,
          label: 'Warning — storage almost full',
          showPercent: true,
        ),
        Gap(AdminSpacing.lg),
        ProgressBar(
          value: 0.4,
          severity: Severity.danger,
          label: 'Danger — 3 files failed',
          showPercent: true,
        ),
      ],
    );
  }
}
