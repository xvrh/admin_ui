import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class AvatarDemo extends StatelessWidget {
  @Preview(name: 'Avatar', group: 'Primitives', wrapper: adminUiPreview)
  const AvatarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Sizes'),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Avatar(initials: 'AB', size: 20),
            Gap(AdminSpacing.lg),
            Avatar(initials: 'AB', size: 28),
            Gap(AdminSpacing.lg),
            Avatar(initials: 'AB', size: 40),
            Gap(AdminSpacing.lg),
            Avatar(initials: 'AB', size: 56),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Auto colour from initials'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Avatar(initials: 'LF', size: 36),
            Avatar(initials: 'DR', size: 36),
            Avatar(initials: 'MC', size: 36),
            Avatar(initials: 'XH', size: 36),
            Avatar(initials: 'AK', size: 36),
            Avatar(initials: 'TS', size: 36),
            Avatar(initials: 'JN', size: 36),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('From a name — initials, colour and accessible name'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Avatar(name: 'Lena Fritz', size: 36),
            Avatar(name: 'Diego Ruiz', size: 36),
            Avatar(name: 'Mei Chen', size: 36),
            Avatar(name: 'Olu', size: 36),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Explicit colour'),
        Row(
          children: [
            Avatar(initials: 'XH', size: 36, color: context.colors.primary),
            const Gap(AdminSpacing.lg),
            Avatar(initials: 'OK', size: 36, color: context.colors.success),
            const Gap(AdminSpacing.lg),
            Avatar(initials: 'NO', size: 36, color: context.colors.danger),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Rounded square'),
        const Row(
          children: [
            Avatar(initials: 'AB', size: 40, shape: AvatarShape.rounded),
            Gap(AdminSpacing.lg),
            Avatar(initials: 'CD', size: 40, shape: AvatarShape.rounded),
          ],
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Image — initials while it loads, and if it fails'),
        const Row(
          children: [
            Avatar(
              size: 40,
              initials: 'NA',
              image: NetworkImage('https://i.pravatar.cc/80?img=12'),
            ),
            Gap(AdminSpacing.lg),
            Avatar(
              size: 40,
              initials: 'FB',
              image: NetworkImage('https://invalid.example/none.png'),
            ),
          ],
        ),
      ],
    );
  }
}
