import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class AlertDemo extends StatelessWidget {
  @Preview(name: 'Alert', wrapper: adminUiPreview)
  const AlertDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Severities'),
        const Alert('Draft saved automatically.', severity: Severity.info),
        const Gap(AdminSpacing.md),
        const Alert('Page published.', severity: Severity.success),
        const Gap(AdminSpacing.md),
        const Alert(
          'This page has unsaved changes.',
          severity: Severity.warning,
        ),
        const Gap(AdminSpacing.md),
        const Alert('Failed to upload 2 files.', severity: Severity.danger),
        const Gap(AdminSpacing.xl),

        const DemoSection('With title'),
        const Alert(
          'Some translations are out of date and may show stale content.',
          severity: Severity.warning,
          title: 'Translations need review',
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With action'),
        Alert(
          'A newer version of this document exists.',
          severity: Severity.info,
          action: Button.ghost(
            'Review',
            size: ControlSize.small,
            onPressed: () {},
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Dismissible'),
        const _Dismissible(),
        const Gap(AdminSpacing.xl),

        const DemoSection('Long text — wraps beside the action and the close'),
        Alert(
          'Three translations still point at the previous version of this '
          'page, and one of its images was deleted from the media library. '
          'Publishing now shows the old text in those languages and a '
          'broken image on the live site.',
          severity: Severity.danger,
          title: 'Publishing would leave this page inconsistent',
          action: Button.ghost(
            'Review',
            size: ControlSize.small,
            onPressed: () {},
          ),
          onDismiss: () {},
        ),
      ],
    );
  }
}

class _Dismissible extends StatefulWidget {
  const _Dismissible();

  @override
  State<_Dismissible> createState() => _DismissibleState();
}

class _DismissibleState extends State<_Dismissible> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return Button(
        'Bring it back',
        size: ControlSize.small,
        onPressed: () => setState(() => _visible = true),
      );
    }
    return Alert(
      'You can dismiss this one.',
      severity: Severity.success,
      onDismiss: () => setState(() => _visible = false),
    );
  }
}
