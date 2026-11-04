import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class PanelDemo extends StatelessWidget {
  @Preview(name: 'Panel', wrapper: adminUiPreview)
  const PanelDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 560,
      children: [
        const DemoSection('Padded (form section / card)'),
        Panel(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General', style: context.type.heading),
              const Gap(AdminSpacing.xs),
              Text(
                'Grouped settings sit inside a Panel so the border and radius '
                'are consistent with every other surface.',
                style: context.type.bodyMuted,
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Flush (clips a table to the corners)'),
        Panel(
          child: Column(
            children: [
              for (final (i, row) in const [
                ('Homepage', 'Published'),
                ('About us', 'Draft'),
                ('Contact', 'Published'),
              ].indexed)
                Container(
                  decoration: BoxDecoration(
                    color: i.isOdd
                        ? context.colors.background
                        : context.colors.surface,
                    border: i == 0
                        ? null
                        : Border(
                            top: BorderSide(color: context.colors.borderSubtle),
                          ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.lg,
                    vertical: AdminSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Text(row.$1, style: context.type.bodyStrong),
                      const Spacer(),
                      Text(row.$2, style: context.type.bodyMuted),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Tinted surface'),
        Panel(
          color: context.colors.background,
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Text(
            'A panel in the background colour — useful for an inset / '
            'secondary block.',
            style: context.type.bodyMuted,
          ),
        ),
      ],
    );
  }
}
