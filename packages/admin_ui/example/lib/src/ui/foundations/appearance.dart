import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The [AppearancePicker] bound to a local [AdminAppearance], and under it
/// a sample drawn with the tokens the value builds: buttons, a status,
/// a check, a switch and three table rows at the picked density. The
/// picker itself stays in the preview's own theme.
class AppearanceDemo extends StatelessWidget {
  final bool _carbonTeal;

  @Preview(name: 'Appearance picker', wrapper: adminUiPreview)
  const AppearanceDemo({super.key}) : _carbonTeal = false;

  /// Carbon, dark, with the Teal accent picked.
  @Preview(
    name: 'Appearance picker · Carbon dark, Teal',
    wrapper: adminUiPreview,
  )
  const AppearanceDemo.carbonTeal({super.key}) : _carbonTeal = true;

  @override
  Widget build(BuildContext context) {
    final initial = _carbonTeal
        ? AdminAppearance(
            theme: carbonTheme,
            mode: ThemeMode.dark,
            accent: adminAccents['Teal'],
          )
        : AdminAppearance(theme: irisTheme);
    return LiveValue<AdminAppearance>(
      initial: initial,
      builder: (value, onChanged) => DemoPage(
        children: [
          AppearancePicker(value: value, onChanged: onChanged),
          const Gap(AdminSpacing.xxl),
          const DemoSection('Result'),
          _Sample(value),
        ],
      ),
    );
  }
}

/// A few parts drawn in [appearance]'s tokens.
class _Sample extends StatelessWidget {
  final AdminAppearance appearance;

  const _Sample(this.appearance);

  @override
  Widget build(BuildContext context) {
    final brightness = appearance.resolveBrightness(
      MediaQuery.platformBrightnessOf(context),
    );
    return Theme(
      data: appearance.themeData(brightness),
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          final row = context.tableMetrics.rowHeight(appearance.density);
          return Panel(
            color: colors.background,
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AdminSpacing.md,
                  runSpacing: AdminSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Button.primary('Save', onPressed: () {}),
                    Button('Cancel', onPressed: () {}),
                    StatusPill(StatusMeta('Paid', colors.info)),
                    Check(value: true, onChanged: (_) {}),
                    Toggle(value: true, onChanged: (_) {}),
                  ],
                ),
                const Gap(AdminSpacing.lg),
                for (final name in ['Order 1041', 'Order 1042', 'Order 1043'])
                  Container(
                    height: row,
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(bottom: BorderSide(color: colors.border)),
                    ),
                    padding: EdgeInsetsDirectional.only(
                      start: context.tableMetrics.cellPaddingX,
                    ),
                    child: Text(name, style: context.type.body),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
