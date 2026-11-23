import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class EmptyStateDemo extends StatelessWidget {
  @Preview(name: 'Empty', wrapper: adminUiPreview)
  const EmptyStateDemo({super.key}) : toned = false;

  /// The states that are the end of something, not the lack of it, each in
  /// its tone.
  @Preview(name: 'Empty / toned', wrapper: adminUiPreview)
  const EmptyStateDemo.toned({super.key}) : toned = true;

  /// Whether the page shows the toned states.
  final bool toned;

  @override
  Widget build(BuildContext context) {
    if (toned) return _toned();
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

  Widget _toned() {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Success: the tone picks the glyph'),
        const Panel(
          child: EmptyState(
            title: 'All caught up',
            message: 'No order waits for you.',
            tone: Severity.success,
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Success, with an icon of its own and an action'),
        Panel(
          child: EmptyState(
            icon: Icons.storefront_rounded,
            title: 'Your shop is ready',
            message: 'Customers can find it and place an order.',
            tone: Severity.success,
            action: Button.primary('Go to the dashboard', onPressed: () {}),
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Warning: a list that waits on a step'),
        Panel(
          child: EmptyState(
            title: 'No way to pay yet',
            message: 'Orders show here once a payment method is set up.',
            tone: Severity.warning,
            action: Button('Set up payments', onPressed: () {}),
          ),
        ),
      ],
    );
  }
}
