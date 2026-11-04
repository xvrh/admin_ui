import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class ButtonDemo extends StatelessWidget {
  @Preview(name: 'Button', wrapper: adminUiPreview)
  const ButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Variants'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button.primary('Primary', onPressed: _noop),
            Button('Secondary', onPressed: _noop),
            Button.ghost('Ghost', onPressed: _noop),
            Button.danger('Delete', onPressed: _noop),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With icons'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button.primary('Save', icon: Icons.check_rounded, onPressed: _noop),
            Button('Filter', icon: Icons.tune_rounded, onPressed: _noop),
            Button(
              'Options',
              trailingIcon: Icons.keyboard_arrow_down_rounded,
              onPressed: _noop,
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Sizes — the theme\'s control heights'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Button.primary('Small', size: ControlSize.small, onPressed: _noop),
            Button.primary('Medium', onPressed: _noop),
            Button.primary('Large', size: ControlSize.large, onPressed: _noop),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Icon only — a square of the control height'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Button.icon(
              Icons.tune_rounded,
              semanticLabel: 'Filters',
              size: ControlSize.small,
              onPressed: _noop,
            ),
            Button.icon(
              Icons.tune_rounded,
              semanticLabel: 'Filters',
              onPressed: _noop,
            ),
            Button.icon(
              Icons.tune_rounded,
              semanticLabel: 'Filters',
              size: ControlSize.large,
              onPressed: _noop,
            ),
            Button.icon(
              Icons.add_rounded,
              semanticLabel: 'Add',
              variant: ButtonVariant.primary,
              onPressed: _noop,
            ),
            Button.icon(
              Icons.more_horiz,
              semanticLabel: 'More',
              variant: ButtonVariant.ghost,
              onPressed: _noop,
            ),
            Button.icon(
              Icons.refresh_rounded,
              semanticLabel: 'Refresh',
              loading: true,
              onPressed: _noop,
            ),
            Button.icon(Icons.delete_outline, semanticLabel: 'Delete'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Split — an action and a menu of alternatives'),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SplitButton(
              label: 'Publish',
              icon: Icons.send_rounded,
              onPressed: _noop,
              entries: _publishOptions,
              menuSemanticLabel: 'More publish options',
            ),
            SplitButton(
              label: 'Save',
              variant: ButtonVariant.secondary,
              onPressed: _noop,
              entries: _publishOptions,
              menuSemanticLabel: 'More save options',
            ),
            SplitButton(
              label: 'Export',
              variant: ButtonVariant.ghost,
              size: ControlSize.small,
              onPressed: _noop,
              entries: _publishOptions,
              menuSemanticLabel: 'More export options',
            ),
          ],
        ),
        const Gap(AdminSpacing.md),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SplitButton(
              label: 'Publish',
              onPressed: _noop,
              loading: true,
              entries: _publishOptions,
              menuSemanticLabel: 'More publish options',
            ),
            SplitButton(
              label: 'Publish',
              onPressed: null,
              disabledHint: 'Nothing changed since the last publish',
              entries: _publishOptions,
              menuSemanticLabel: 'More publish options',
            ),
            SplitButton(
              label: 'Publish',
              size: ControlSize.large,
              onPressed: _noop,
              entries: _publishOptions,
              menuSemanticLabel: 'More publish options',
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Loading — the same width as at rest'),
        const _Pairs(
          pairs: [
            (
              Button.primary('Save', onPressed: _noop),
              Button.primary('Save', loading: true, onPressed: _noop),
            ),
            (
              Button('Refresh', icon: Icons.refresh_rounded, onPressed: _noop),
              Button(
                'Refresh',
                icon: Icons.refresh_rounded,
                loading: true,
                onPressed: _noop,
              ),
            ),
            (
              Button.danger(
                'Delete',
                size: ControlSize.small,
                onPressed: _noop,
              ),
              Button.danger(
                'Delete',
                size: ControlSize.small,
                loading: true,
                onPressed: _noop,
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Focused'),
        const _Focused(),
        const Gap(AdminSpacing.xl),

        const DemoSection('Long label — ellipsized in a narrow slot'),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 220,
            child: Button(
              'Publish every translation to the live site',
              icon: Icons.send_rounded,
              expand: true,
              onPressed: _noop,
            ),
          ),
        ),
        const Gap(AdminSpacing.md),
        const Button.primary(
          'Publish every translation to the live site',
          onPressed: _noop,
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Text link — an action in a line of text'),
        Wrap(
          spacing: AdminSpacing.lg,
          runSpacing: AdminSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'The source changed.',
              style: context.type.caption.copyWith(
                color: context.colors.foregroundMuted,
              ),
            ),
            const TextLink(
              'Retranslate',
              icon: Icons.auto_awesome_rounded,
              onPressed: _noop,
            ),
            // The pointer on it: the underline.
            PinnedHover(
              target: (widget) => widget is Text && widget.data == 'Dismiss',
              child: const TextLink('Dismiss', onPressed: _noop),
            ),
            const TextLink('Unavailable', onPressed: null),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Disabled'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button.primary('Primary'),
            Button('Secondary'),
            Button.ghost('Ghost'),
            Button.danger('Delete'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Full width'),
        const Button.primary(
          'Publish',
          icon: Icons.send_rounded,
          expand: true,
          onPressed: _noop,
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Interactive'),
        const _Counter(),
        const Gap(AdminSpacing.xl),

        const DemoSection(
          'Link — the primary text colour, underlined on hover',
        ),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Button.link('View history', onPressed: _noop),
            const Button.link(
              'Open preview',
              icon: Icons.open_in_new_rounded,
              onPressed: _noop,
            ),
            // The pointer on it: the underline.
            PinnedHover(
              target: (widget) => widget is Text && widget.data == 'Hovered',
              child: const Button.link('Hovered', onPressed: _noop),
            ),
            const Button.link('Unavailable'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Soft — the tonal button'),
        const Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Button.soft('Duplicate', onPressed: _noop),
            Button.soft('Add field', icon: Icons.add_rounded, onPressed: _noop),
            Button.soft('Small', size: ControlSize.small, onPressed: _noop),
            Button.icon(
              Icons.tune_rounded,
              semanticLabel: 'Filters',
              variant: ButtonVariant.soft,
              onPressed: _noop,
            ),
            Button.soft('Disabled'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Danger on every variant'),
        for (final enabled in [true, false]) ...[
          Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final variant in const [
                ButtonVariant.primary,
                ButtonVariant.secondary,
                ButtonVariant.soft,
                ButtonVariant.ghost,
                ButtonVariant.link,
              ])
                Button(
                  'Delete',
                  variant: variant,
                  danger: true,
                  onPressed: enabled ? _noop : null,
                ),
              Button.icon(
                Icons.delete_outline,
                semanticLabel: 'Delete',
                danger: true,
                onPressed: enabled ? _noop : null,
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
        ],
        SplitButton(
          label: 'Delete',
          icon: Icons.delete_outline,
          danger: true,
          onPressed: _noop,
          entries: _deleteOptions,
          menuSemanticLabel: 'More delete options',
        ),
      ],
    );
  }
}

void _noop() {}

final _publishOptions = <MenuEntry>[
  const MenuItem('Schedule…', icon: Icons.schedule_rounded, onSelect: _noop),
  const MenuItem('Publish to…', icon: Icons.public_rounded, onSelect: _noop),
  const MenuDivider(),
  const MenuItem('Unpublish', danger: true, onSelect: _noop),
];

final _deleteOptions = <MenuEntry>[
  const MenuItem('Move to trash', onSelect: _noop),
  const MenuItem('Delete forever', danger: true, onSelect: _noop),
];

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Button.primary(
          'Clicked $_count',
          icon: Icons.add_rounded,
          onPressed: () => setState(() => _count++),
        ),
        const Gap(AdminSpacing.md),
        if (_count > 0)
          Button.ghost(
            'Reset',
            size: ControlSize.small,
            onPressed: () => setState(() => _count = 0),
          ),
      ],
    );
  }
}

/// Each button at rest beside its loading self.
class _Pairs extends StatelessWidget {
  final List<(Button, Button)> pairs;

  const _Pairs({required this.pairs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (rest, loading) in pairs)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.md),
            child: Row(children: [rest, const Gap(AdminSpacing.md), loading]),
          ),
      ],
    );
  }
}

/// The keyboard focus ring, pinned through the states controller with the
/// keyboard highlight forced on.
class _Focused extends StatefulWidget {
  const _Focused();

  @override
  State<_Focused> createState() => _FocusedState();
}

class _FocusedState extends State<_Focused> {
  final _states = [
    for (var i = 0; i < 3; i++) WidgetStatesController({WidgetState.focused}),
  ];

  /// The split button's action takes real focus, to show a segment's ring.
  final _splitAction = FocusNode(debugLabel: 'Split action');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _splitAction.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final states in _states) {
      states.dispose();
    }
    _splitAction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardHighlight(
      child: Wrap(
        spacing: AdminSpacing.lg,
        runSpacing: AdminSpacing.lg,
        children: [
          Button.primary(
            'Primary',
            onPressed: _noop,
            statesController: _states[0],
          ),
          Button('Secondary', onPressed: _noop, statesController: _states[1]),
          Button.ghost('Ghost', onPressed: _noop, statesController: _states[2]),
          SplitButton(
            label: 'Publish',
            onPressed: _noop,
            focusNode: _splitAction,
            entries: _publishOptions,
            menuSemanticLabel: 'More publish options',
          ),
        ],
      ),
    );
  }
}
