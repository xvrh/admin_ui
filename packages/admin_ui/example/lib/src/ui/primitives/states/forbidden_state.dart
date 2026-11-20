import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class ForbiddenStateDemo extends StatelessWidget {
  @Preview(name: 'Not allowed', wrapper: adminUiPreview)
  const ForbiddenStateDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Default — the kit\'s words, and no way back'),
        const Panel(child: ForbiddenState()),
        const Gap(AdminSpacing.xl),

        const DemoSection('With a way back'),
        Panel(child: ForbiddenState(onBack: () {})),
        const Gap(AdminSpacing.xl),

        const DemoSection('The app\'s own words: the role, and where back is'),
        Panel(
          child: ForbiddenState(
            title: 'Not available to editors',
            message: 'Only an owner invites people and changes their roles.',
            backLabel: 'Back to the dashboard',
            onBack: () {},
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With no message'),
        const Panel(child: ForbiddenState(message: '')),
      ],
    );
  }
}
