import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';
import '../primitives/feedback/toast.dart' show PinnedToastStack;
import '../primitives/tip.dart' show PinnedTips;

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

/// An alert and a toast in every shipped theme at once, each card in its own
/// theme's tokens, in the preview's mode: the feedback anatomy side by side,
/// as [ThemeSheetDemo] shows the controls.
class ThemeFeedbackSheetDemo extends StatelessWidget {
  @Preview(name: 'Every theme · feedback', wrapper: adminUiPreview)
  const ThemeFeedbackSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.brightness == Brightness.dark;
    return DemoPage(
      maxWidth: 820,
      padding: const EdgeInsets.all(AdminSpacing.xl),
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
                child: _FeedbackCard(theme.name),
              ),
          ],
        ),
      ],
    );
  }
}

/// One theme's alert and toast, on that theme's page colour.
class _FeedbackCard extends StatelessWidget {
  final String name;

  const _FeedbackCard(this.name);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 372,
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: context.type.sectionLabel),
          const Gap(AdminSpacing.sm),
          const Alert(
            'Check the price before publishing.',
            title: 'Could not publish',
            severity: Severity.danger,
          ),
          const Gap(AdminSpacing.sm),
          const PinnedToastStack(
            width: 348,
            toasts: [
              Toast(
                'Page published.',
                severity: Severity.success,
                duration: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The type roles a theme weighs and inks apart from its headings, in every
/// shipped theme at once: a page's title, a dialog's title, a field's label
/// and its error. Each card is in its own theme's tokens, in the preview's
/// mode, as [ThemeSheetDemo] shows the controls.
class ThemeTypeSheetDemo extends StatelessWidget {
  @Preview(name: 'Every theme · type', wrapper: adminUiPreview)
  const ThemeTypeSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.brightness == Brightness.dark;
    return DemoPage(
      maxWidth: 820,
      padding: const EdgeInsets.all(AdminSpacing.xl),
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
                child: _TypeCard(theme.name),
              ),
          ],
        ),
      ],
    );
  }
}

/// One theme's titles and field text, on that theme's page colour.
class _TypeCard extends StatelessWidget {
  final String name;

  const _TypeCard(this.name);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Container(
      width: 372,
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: type.sectionLabel),
          const Gap(AdminSpacing.sm),
          Text('Orders', style: type.pageTitle),
          const Gap(AdminSpacing.md),
          Modal(
            title: 'Delete page?',
            message: 'It cannot be restored.',
            onDismiss: () {},
            actions: [
              Button.ghost('Cancel', onPressed: () {}),
              Button.danger('Delete', onPressed: () {}),
            ],
          ),
          const Gap(AdminSpacing.md),
          InputField(
            value: '',
            label: 'Price',
            hint: '0.00',
            errorText: 'Enter a price.',
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

/// A button and a text input at each [ControlSize], in every shipped theme at
/// once: the text a control holds as it grows. Each card is in its own
/// theme's tokens, in the preview's mode, as [ThemeSheetDemo] shows the
/// controls.
class ThemeSizesSheetDemo extends StatelessWidget {
  @Preview(name: 'Every theme · sizes', wrapper: adminUiPreview)
  const ThemeSizesSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.brightness == Brightness.dark;
    return DemoPage(
      maxWidth: 820,
      padding: const EdgeInsets.all(AdminSpacing.xl),
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
                child: _SizesCard(theme.name),
              ),
          ],
        ),
      ],
    );
  }
}

/// One theme's button and input at the three sizes, on that theme's surface.
class _SizesCard extends StatelessWidget {
  final String name;

  const _SizesCard(this.name);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 372,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: context.type.sectionLabel),
          for (final size in ControlSize.values) ...[
            const Gap(AdminSpacing.md),
            Row(
              children: [
                Expanded(
                  child: InputField(
                    value: 'Boston fern',
                    size: size,
                    onChanged: (_) {},
                  ),
                ),
                const Gap(AdminSpacing.md),
                Button('Publish', size: size, onPressed: () {}),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A tooltip pinned open in every shipped theme at once: the chip each
/// theme fills with its inverse surface, its corner, padding and text. Each
/// card is in its own theme's tokens, in the preview's mode, as
/// [ThemeSheetDemo] shows the controls.
class ThemeTooltipSheetDemo extends StatelessWidget {
  @Preview(name: 'Every theme · tooltip', wrapper: adminUiPreview)
  const ThemeTooltipSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.brightness == Brightness.dark;
    final pageFont = context.type.spec.fontFamily;
    return DemoPage(
      maxWidth: 720,
      children: [
        PinnedTips(
          child: Wrap(
            spacing: AdminSpacing.lg,
            runSpacing: AdminSpacing.lg,
            children: [
              for (final theme in adminThemes)
                Theme(
                  data: buildAppTheme(
                    _inFont(
                      dark ? theme.dark ?? theme.tokens : theme.tokens,
                      pageFont,
                    ),
                  ),
                  child: _TooltipCard(theme.name),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// [tokens], set in [family] where its theme names no font (Ant). Text in
  /// a card of such a theme inherits the page's font; a tooltip is drawn in
  /// the overlay, where it would inherit none.
  static AdminTokens _inFont(AdminTokens tokens, String? family) {
    final spec = tokens.typography.spec;
    if (spec.fontFamily != null || family == null) return tokens;
    return tokens.copyWith(
      typography: AdminTypography.from(
        tokens.palette,
        spec.copyWith(fontFamily: family),
      ),
    );
  }
}

/// One theme's tooltip under its trigger, on that theme's page colour.
class _TooltipCard extends StatelessWidget {
  final String name;

  const _TooltipCard(this.name);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 204,
      // Room under the trigger for the tallest chip, Carbon's.
      height: 168,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: context.type.sectionLabel),
          const Gap(AdminSpacing.md),
          Center(
            child: Tip(
              message: 'Archive',
              shortcut: 'E',
              side: PopoverSide.bottom,
              child: IconAction(
                Icons.archive_outlined,
                label: '$name archive',
                tooltip: false,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
