import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class EmptyStateDemo extends StatelessWidget {
  @Preview(name: 'Empty', wrapper: adminUiPreview)
  const EmptyStateDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Title only'),
        const Panel(child: EmptyState(title: 'Nothing here yet')),
        const Gap(AdminSpacing.xl),

        const DemoSection('With message'),
        const Panel(
          child: EmptyState(
            title: 'No products',
            message: 'Products you create will show up here.',
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With action + custom icon'),
        Panel(
          child: EmptyState(
            icon: Icons.image_outlined,
            title: 'No media',
            message: 'Upload images and files to use across your content.',
            action: Button.primary(
              'Upload',
              icon: Icons.upload_rounded,
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
}
