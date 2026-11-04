import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class ControlsDemo extends StatelessWidget {
  @Preview(name: 'Controls', wrapper: adminUiPreview)
  const ControlsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Toggle'),
        LiveValue<bool>(
          initial: true,
          builder: (v, set) =>
              Toggle(value: v, onChanged: set, label: 'Enable comments'),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<bool>(
          initial: false,
          builder: (v, set) => Toggle(
            value: v,
            onChanged: set,
            label:
                'Notify subscribers by email when this page is published '
                'or its title changes',
          ),
        ),
        const Gap(AdminSpacing.md),
        const Toggle(value: true, readOnly: true, label: 'Read-only (on)'),
        const Gap(AdminSpacing.md),
        const Toggle(value: true, label: 'Disabled (on)'),
        const Gap(AdminSpacing.md),
        const Toggle(value: false, label: 'Disabled (off)'),
        const Gap(AdminSpacing.xl),

        const DemoSection('Checkbox'),
        LiveValue<bool>(
          initial: false,
          builder: (v, set) =>
              Check(value: v, onChanged: set, label: 'Send a notification'),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<bool>(
          initial: true,
          builder: (v, set) =>
              Check(value: v, onChanged: set, label: 'Include drafts'),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<bool>(
          initial: false,
          builder: (v, set) => Check(
            value: v,
            indeterminate: !v,
            onChanged: set,
            label: 'Select all (some selected)',
          ),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<bool>(
          initial: false,
          builder: (v, set) => Check(
            value: v,
            onChanged: set,
            label:
                'Keep the previous version available as a draft so editors '
                'can compare and restore it later',
          ),
        ),
        const Gap(AdminSpacing.md),
        const Check(value: true, readOnly: true, label: 'Read-only (checked)'),
        const Gap(AdminSpacing.md),
        const Check(value: true, label: 'Disabled (checked)'),
        const Gap(AdminSpacing.md),
        const Check(
          value: false,
          indeterminate: true,
          label: 'Disabled (some selected)',
        ),
        const Gap(AdminSpacing.md),
        const Check(value: false, label: 'Disabled (unchecked)'),
        const Gap(AdminSpacing.lg),
        LiveValue<bool>(
          initial: false,
          builder: (v, set) => FieldShell(
            label: 'Consent',
            errorText: v ? null : 'Accept the terms to continue',
            child: Check(
              value: v,
              onChanged: set,
              label: 'I accept the terms of use',
            ),
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Segmented'),
        LiveValue<String>(
          initial: 'list',
          builder: (v, set) => Segmented<String>(
            value: v,
            onChanged: set,
            segments: const [
              SegmentOption('list', 'List', icon: Icons.view_list_rounded),
              SegmentOption('grid', 'Grid', icon: Icons.grid_view_rounded),
              SegmentOption('board', 'Board', icon: Icons.view_column_rounded),
            ],
          ),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<String>(
          initial: 'grid',
          builder: (v, set) => Segmented<String>(
            value: v,
            onChanged: set,
            segments: const [
              SegmentOption(
                'grid',
                'Grid view',
                icon: Icons.grid_view_rounded,
                showLabel: false,
              ),
              SegmentOption(
                'list',
                'List view',
                icon: Icons.view_list_rounded,
                showLabel: false,
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<String>(
          initial: 'week',
          builder: (v, set) => Segmented<String>(
            value: v,
            onChanged: set,
            expand: true,
            segments: const [
              SegmentOption('day', 'Day'),
              SegmentOption('week', 'Week'),
              SegmentOption('month', 'Month'),
            ],
          ),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<int>(
          initial: 25,
          builder: (v, set) => Segmented<int>(
            value: v,
            onChanged: set,
            size: ControlSize.small,
            segments: const [
              SegmentOption(10, '10'),
              SegmentOption(25, '25'),
              SegmentOption(50, '50'),
            ],
          ),
        ),
        const Gap(AdminSpacing.md),
        const Segmented<String>(
          value: 'week',
          readOnly: true,
          semanticLabel: 'Read-only',
          segments: [
            SegmentOption('day', 'Day'),
            SegmentOption('week', 'Week'),
            SegmentOption('month', 'Month'),
          ],
        ),
        const Gap(AdminSpacing.md),
        const Segmented<String>(
          value: 'week',
          semanticLabel: 'Disabled',
          segments: [
            SegmentOption('day', 'Day'),
            SegmentOption('week', 'Week'),
            SegmentOption('month', 'Month'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Slider'),
        LiveValue<double>(
          initial: 0.4,
          builder: (v, set) => ValueSlider(
            value: v,
            onChanged: set,
            format: (x) => '${(x * 100).round()}%',
          ),
        ),
        const Gap(AdminSpacing.md),
        LiveValue<double>(
          initial: 3,
          builder: (v, set) => ValueSlider(
            value: v,
            onChanged: set,
            min: 1,
            max: 10,
            divisions: 9,
          ),
        ),
        const Gap(AdminSpacing.md),
        const ValueSlider(value: 0.6, onChanged: null), // read-only
        const Gap(AdminSpacing.xl),

        const DemoSection('Radio group — plain'),
        LiveValue<String>(
          initial: 'draft',
          builder: (v, set) => Choice<String>(
            value: v,
            onChanged: set,
            semanticLabel: 'Status',
            options: const [
              ChoiceOption('draft', 'Draft'),
              ChoiceOption('review', 'In review'),
              ChoiceOption('published', 'Published'),
            ],
          ),
        ),
        const Gap(AdminSpacing.lg),
        const Choice<String>(
          value: 'b',
          onChanged: null,
          readOnly: true,
          semanticLabel: 'Read-only',
          direction: Axis.horizontal,
          options: [
            ChoiceOption('a', 'One'),
            ChoiceOption('b', 'Two'),
            ChoiceOption('c', 'Three'),
          ],
        ),
        const Gap(AdminSpacing.lg),
        const Choice<String>(
          value: 'b',
          onChanged: null,
          semanticLabel: 'Disabled',
          direction: Axis.horizontal,
          options: [
            ChoiceOption('a', 'One'),
            ChoiceOption('b', 'Two'),
            ChoiceOption('c', 'Three'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Radio group — card'),
        LiveValue<String>(
          initial: 'auto',
          builder: (v, set) => Choice<String>(
            value: v,
            onChanged: set,
            style: ChoiceStyle.card,
            options: const [
              ChoiceOption(
                'auto',
                'Automatic',
                icon: Icons.bolt_rounded,
                description: 'Publish as soon as review is approved.',
              ),
              ChoiceOption(
                'scheduled',
                'Scheduled',
                icon: Icons.schedule_rounded,
                description: 'Go live at a date and time you choose.',
              ),
              ChoiceOption(
                'manual',
                'Manual',
                icon: Icons.touch_app_rounded,
                description: 'Stay in draft until someone publishes.',
                enabled: false,
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Tag — status'),
        const Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
          children: [
            Tag('Published', severity: Severity.success, dot: true),
            Tag('Draft', dot: true),
            Tag('Needs review', severity: Severity.warning, dot: true),
            Tag('Error', severity: Severity.danger, dot: true),
          ],
        ),
        const Gap(AdminSpacing.lg),

        const DemoSection('Tag — variants'),
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
          children: [
            Tag('Soft', color: context.colors.primary),
            Tag(
              'Solid',
              color: context.colors.primary,
              variant: TagVariant.solid,
            ),
            const Tag('Outline', variant: TagVariant.outline),
            const Tag(
              '3',
              severity: Severity.danger,
              variant: TagVariant.solid,
            ),
            Tag(
              'With icon',
              icon: Icons.star_rounded,
              color: context.colors.warning,
            ),
          ],
        ),
        const Gap(AdminSpacing.lg),

        const DemoSection('Tag — custom colours, soft'),
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
          children: [
            for (final (label, color) in _customColors(context))
              Tag(label, color: color, dot: true),
          ],
        ),
        const Gap(AdminSpacing.lg),

        const DemoSection('Tag — custom colours, solid'),
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
          children: [
            for (final (label, color) in _customColors(context))
              Tag(label, color: color, variant: TagVariant.solid),
          ],
        ),
        const Gap(AdminSpacing.lg),

        const DemoSection('Tag — severity, solid'),
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
          children: [
            for (final severity in Severity.values)
              Tag(
                severity.name,
                severity: severity,
                variant: TagVariant.solid,
                dot: true,
              ),
          ],
        ),
        const Gap(AdminSpacing.lg),

        const DemoSection('Tag — removable (chip)'),
        const _Chips(),
        const Gap(AdminSpacing.xl),

        const DemoSection('Narrow — 250px'),
        const _Narrow(),
      ],
    );
  }
}

List<(String, Color)> _customColors(BuildContext context) => [
  ('Primary', context.colors.primary),
  ('Amber', context.colors.warning),
  ('Green', context.colors.success),
  ('Info', context.colors.info),
  ('Red', context.colors.danger),
  ('Violet', const Color(0xFF7C3AED)),
  ('Teal', const Color(0xFF0D9488)),
];

class _Chips extends StatefulWidget {
  const _Chips();

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  List<String> _tags = ['design', 'flutter', 'admin', 'i18n'];

  @override
  Widget build(BuildContext context) {
    if (_tags.isEmpty) {
      return Button(
        'Reset',
        size: ControlSize.small,
        onPressed: () =>
            setState(() => _tags = ['design', 'flutter', 'admin', 'i18n']),
      );
    }
    return Wrap(
      spacing: AdminSpacing.sm,
      runSpacing: AdminSpacing.sm,
      children: [
        for (final t in _tags)
          Tag(
            t,
            color: context.colors.primary,
            onRemove: () =>
                setState(() => _tags = _tags.where((x) => x != t).toList()),
          ),
      ],
    );
  }
}

/// The controls squeezed into 250px: labels wrap or ellipsize, nothing
/// overflows.
class _Narrow extends StatelessWidget {
  const _Narrow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LiveValue<String>(
              initial: 'live',
              builder: (v, set) => Segmented<String>(
                value: v,
                onChanged: set,
                segments: const [
                  SegmentOption('all', 'All'),
                  SegmentOption('live', 'Live'),
                  SegmentOption('scheduled', 'Scheduled for review'),
                ],
              ),
            ),
            const Gap(AdminSpacing.lg),
            LiveValue<bool>(
              initial: true,
              builder: (v, set) => Toggle(
                value: v,
                onChanged: set,
                label: 'Show this page in the main navigation',
              ),
            ),
            const Gap(AdminSpacing.lg),
            LiveValue<String>(
              initial: 'now',
              builder: (v, set) => Choice<String>(
                value: v,
                onChanged: set,
                options: const [
                  ChoiceOption(
                    'now',
                    'Publish immediately after the review is approved',
                  ),
                  ChoiceOption('later', 'Schedule'),
                ],
              ),
            ),
            const Gap(AdminSpacing.lg),
            const Row(
              children: [
                Flexible(
                  child: Tag(
                    'Needs review by the legal team',
                    severity: Severity.warning,
                    dot: true,
                  ),
                ),
                Gap(AdminSpacing.sm),
                Tag('Draft'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
