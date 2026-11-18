import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The controls a theme's anatomy tokens draw, in every shipped theme at
/// once: a tab strip, a switch, a checkbox, a radio and a slider, each card
/// in its own theme's tokens, in the preview's mode. A change to one theme's anatomy
/// shows here beside the themes it left alone, whatever theme the preview
/// itself is in.
class ThemeSheetDemo extends StatelessWidget {
  @Preview(name: 'Every theme', wrapper: adminUiPreview)
  const ThemeSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.brightness == Brightness.dark;
    return DemoPage(
      maxWidth: 720,
      children: [
        Wrap(
          spacing: AdminSpacing.lg,
          runSpacing: AdminSpacing.lg,
          children: [
            for (final theme in adminThemes)
              Theme(
                data: buildAppTheme(
                  dark ? theme.dark ?? theme.tokens : theme.tokens,
                ),
                child: _ThemeCard(theme.name),
              ),
          ],
        ),
      ],
    );
  }
}

/// One theme's controls, on that theme's surface.
class _ThemeCard extends StatelessWidget {
  final String name;

  const _ThemeCard(this.name);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 204,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: context.type.sectionLabel),
          const Gap(AdminSpacing.sm),
          Tabs(
            tabs: const [TabItem('Details'), TabItem('Orders')],
            selected: 0,
            onChanged: (_) {},
          ),
          const Gap(AdminSpacing.md),
          Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Toggle(
                value: false,
                onChanged: (_) {},
                semanticLabel: '$name switch, off',
              ),
              Toggle(
                value: true,
                onChanged: (_) {},
                semanticLabel: '$name switch, on',
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
          Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Check(
                value: false,
                onChanged: (_) {},
                semanticLabel: '$name checkbox, off',
              ),
              Check(
                value: true,
                onChanged: (_) {},
                semanticLabel: '$name checkbox, on',
              ),
              Check(
                value: true,
                indeterminate: true,
                onChanged: (_) {},
                semanticLabel: '$name checkbox, mixed',
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
          Choice<bool>(
            value: true,
            onChanged: (_) {},
            options: const [
              ChoiceOption(true, 'Selected'),
              ChoiceOption(false, 'Unselected'),
            ],
          ),
          const Gap(AdminSpacing.sm),
          ValueSlider(value: 0.4, showValue: false, onChanged: (_) {}),
        ],
      ),
    );
  }
}
