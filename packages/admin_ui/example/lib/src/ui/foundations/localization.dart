import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The kit's localisation at work in the current Locale: the shared
/// vocabulary on `context.adminL10n` (plurals included), the locale's
/// numbers and byte sizes from `context.adminFormats`, and the platform's
/// shortcut labels. Switch the Locale axis to compare en, fr and ar, and to
/// see he fall back to English strings under a right-to-left layout.
class LocalizationDemo extends StatelessWidget {
  @Preview(name: 'Localization', wrapper: adminUiPreview)
  const LocalizationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n;
    final formats = context.adminFormats;
    final drop = l10n.dropPrompt(multiple: true);
    return DemoPage(
      maxWidth: 720,
      children: [
        Text(
          '${Localizations.localeOf(context)} · strings ${l10n.localeName} · '
          'numbers ${formats.locale} · ${Directionality.of(context).name}',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('Shared vocabulary'),
        _Line(
          'apply · retry · reset',
          [l10n.apply, l10n.retry, l10n.reset].join(' · '),
        ),
        _Line('loading · saving', '${l10n.loading} · ${l10n.saving}'),
        _Line(
          'edited · unsavedChanges',
          '${l10n.edited} · ${l10n.unsavedChanges}',
        ),
        _Line('noResults · noMatches', '${l10n.noResults} · ${l10n.noMatches}'),
        _Line(
          'placeholders',
          [
            l10n.selectPlaceholder,
            l10n.filterPlaceholder,
            l10n.searchPlaceholder,
          ].join(' · '),
        ),
        _Line('removeItem', l10n.removeItem('photo.jpg')),
        _Line('countOf(3, 1200)', l10n.countOf(3, 1200)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: Text('dropPrompt', style: context.type.caption),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: context.type.body,
                    children: [
                      TextSpan(text: drop.before),
                      TextSpan(
                        text: drop.link,
                        style: TextStyle(
                          color: context.colors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: drop.after),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('Plurals · selectedCount(n)'),
        for (final n in const [0, 1, 2, 3, 11, 100])
          _Line('$n', l10n.selectedCount(n)),
        const Gap(AdminSpacing.xl),
        const DemoSection('Numbers'),
        _Line('decimal(1234567.891)', formats.decimal(1234567.891)),
        _Line('compact(1234567)', formats.compact(1234567)),
        _Line(
          'percent(0.425, decimals: 1)',
          formats.percent(0.425, decimals: 1),
        ),
        for (final size in const [512, 1500, 757760, 12300000, 2500000000])
          _Line('bytes($size)', formats.bytes(size)),
        _Line(
          'parseDecimal(decimal(1234.5))',
          '${formats.parseDecimal(formats.decimal(1234.5))}',
        ),
        const Gap(AdminSpacing.xl),
        const DemoSection('Shortcuts'),
        for (final (name, activator) in [
          ('primary + K', primaryModifierActivator(LogicalKeyboardKey.keyK)),
          ('primary + S', primaryModifierActivator(LogicalKeyboardKey.keyS)),
          (
            'primary + shift + P',
            primaryModifierActivator(LogicalKeyboardKey.keyP, shift: true),
          ),
          ('escape', const SingleActivator(LogicalKeyboardKey.escape)),
        ])
          _Line(name, shortcutLabel(context, activator)),
      ],
    );
  }
}

/// One message: the call on the start side, what it reads on the end side.
class _Line extends StatelessWidget {
  final String name;
  final String value;

  const _Line(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 220, child: Text(name, style: context.type.caption)),
          Expanded(child: Text(value, style: context.type.body)),
        ],
      ),
    );
  }
}
