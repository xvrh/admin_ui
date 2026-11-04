import 'package:admin_ui/fields.dart';
import 'package:admin_ui/forms.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../../appearance/themes.dart';
import '../../../keys/settings_keys.dart';
import '../../../l10n/ref_strings.dart';
import 'settings_tabs.dart';

/// The language setting: a language code, or [deviceLanguage] to follow the
/// device.
const deviceLanguage = 'device';

/// The appearance page's content, without the page around it: every choice
/// applies the moment it is made, through the callbacks.
class AppearanceView extends StatelessWidget {
  /// The theme, mode, accent and density, edited by the kit's picker.
  final AdminAppearance appearance;
  final ValueChanged<AdminAppearance> onChanged;

  /// The language select's cell: its value is a language code or
  /// [deviceLanguage].
  final ValueCell<String> language;

  final bool reduceMotion;
  final ValueChanged<bool> onReduceMotion;

  const AppearanceView({
    super.key,
    required this.appearance,
    required this.onChanged,
    required this.language,
    required this.reduceMotion,
    required this.onReduceMotion,
  });

  /// The narrowest content width that takes two columns.
  static const twoColumnsMin = 820.0;

  @override
  Widget build(BuildContext context) {
    final display = _displayCard(context);
    final preview = _previewCard(context);
    final language = _languageCard(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < twoColumnsMin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              display,
              const Gap(AdminSpacing.xl),
              preview,
              const Gap(AdminSpacing.xl),
              language,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: display),
            const Gap(AdminSpacing.xl),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [preview, const Gap(AdminSpacing.xl), language],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _displayCard(BuildContext context) {
    final strings = context.strings.settings;
    return SettingsCard(
      title: strings.displayTitle,
      description: strings.displayDescription,
      children: [
        AppearancePicker(
          key: SettingsKeys.theme,
          value: appearance,
          onChanged: onChanged,
          themes: appThemes,
        ),
      ],
    );
  }

  Widget _previewCard(BuildContext context) {
    return SettingsCard(
      title: context.strings.settings.previewLabel,
      children: const [ThemePreview(key: SettingsKeys.preview)],
    );
  }

  Widget _languageCard(BuildContext context) {
    final strings = context.strings.settings;
    final shell = context.strings.shell;
    return SettingsCard(
      title: strings.languageTitle,
      children: [
        // FRICTION(F-503): SelectField binds only a form cell, so a setting
        // that applies at once keeps a LocalScope cell of its own.
        SelectField(
          language,
          key: SettingsKeys.language,
          label: shell.language,
          description: strings.languageDescription,
          options: [
            SelectOption(
              value: deviceLanguage,
              label: shell.languageSystem,
              icon: Icons.devices_outlined,
            ),
            for (final code in const ['en', 'fr', 'ar'])
              SelectOption(value: code, label: shell.languageName(code)),
          ],
        ),
        LabeledField(
          label: strings.reduceMotionLabel,
          description: strings.reduceMotionDescription,
          // FRICTION(F-505): a Toggle given a tight width (a LabeledField
          // stretches its control) draws its track that wide.
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Toggle(
              key: SettingsKeys.reduceMotion,
              semanticLabel: strings.reduceMotionLabel,
              value: reduceMotion,
              onChanged: onReduceMotion,
            ),
          ),
        ),
      ],
    );
  }
}

/// A few of the theme's parts, drawn with the kit's own widgets in the
/// colours on screen: the primary and secondary buttons, a status, and the
/// palette's main roles.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.settings;
    final colors = context.colors;
    final roles = [
      colors.primary,
      colors.info,
      colors.success,
      colors.warning,
      colors.danger,
      colors.foreground,
    ];
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Panel(
          color: colors.background,
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Button.primary(
                strings.previewPrimary,
                size: ControlSize.small,
                onPressed: () {},
              ),
              Button(
                strings.previewSecondary,
                size: ControlSize.small,
                onPressed: () {},
              ),
              StatusPill(StatusMeta(strings.previewStatus, colors.info)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, color) in roles.indexed) ...[
                    if (i > 0) const Gap(AdminSpacing.xs),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
