import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The icon-only button: its three sizes, every interaction state pinned so a
/// static render shows it (hover, press and focus are seeded through a states
/// controller, with the keyboard highlight forced on while this page is up),
/// the close action, and the sizes beside what they sit next to.
class IconActionDemo extends StatefulWidget {
  @Preview(name: 'Icon action', wrapper: adminUiPreview)
  const IconActionDemo({super.key});

  @override
  State<IconActionDemo> createState() => _IconActionDemoState();
}

class _IconActionDemoState extends State<IconActionDemo> {
  static const _pinned = [
    WidgetState.hovered,
    WidgetState.pressed,
    WidgetState.focused,
  ];

  final _pins = {
    for (final danger in [false, true])
      for (final state in _pinned)
        (danger, state): WidgetStatesController({state}),
  };
  final _hovered = {
    for (final size in IconActionSize.values)
      size: WidgetStatesController({WidgetState.hovered}),
  };

  @override
  void dispose() {
    for (final controller in [..._pins.values, ..._hovered.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 640,
        children: [
          const DemoSection('Sizes — at rest, and hovered to show the box'),
          _Grid(
            columns: [
              '',
              'inline · 24',
              'small · 28',
              'medium · ${context.sizes.medium.round()}',
            ],
            rows: [
              for (final (caption, icon, label) in const [
                ('Edit', Icons.edit_outlined, 'Edit'),
                ('More', Icons.more_horiz, 'More options'),
              ])
                [
                  _caption(context, caption),
                  for (final size in IconActionSize.values)
                    IconAction(
                      icon,
                      label: label,
                      size: size,
                      onPressed: _noop,
                    ),
                ],
              [
                _caption(context, 'Hovered'),
                for (final size in IconActionSize.values)
                  IconAction(
                    Icons.notifications_none_rounded,
                    label: 'Notifications',
                    size: size,
                    onPressed: _noop,
                    statesController: _hovered[size],
                  ),
              ],
            ],
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('States'),
          _Grid(
            columns: const [
              '',
              'Rest',
              'Hover',
              'Pressed',
              'Focused',
              'Disabled',
              'Selected',
            ],
            rows: [
              for (final (caption, icon, label, danger) in const [
                ('Neutral', Icons.push_pin_outlined, 'Pin', false),
                ('Danger', Icons.delete_outline, 'Delete', true),
              ])
                [
                  _caption(context, caption),
                  IconAction(
                    icon,
                    label: label,
                    danger: danger,
                    onPressed: _noop,
                  ),
                  for (final state in _pinned)
                    IconAction(
                      icon,
                      label: label,
                      danger: danger,
                      onPressed: _noop,
                      statesController: _pins[(danger, state)],
                    ),
                  IconAction(icon, label: label, danger: danger),
                  IconAction(
                    icon,
                    label: label,
                    danger: danger,
                    selected: true,
                    onPressed: _noop,
                  ),
                ],
            ],
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('Close'),
          _Grid(
            columns: const ['inline', 'small', 'medium'],
            rows: [
              [
                for (final size in IconActionSize.values)
                  IconAction.close(onPressed: _noop, size: size),
              ],
            ],
          ),
          const Gap(AdminSpacing.lg),
          const _DialogHeader(),
          const Gap(AdminSpacing.xl),

          const DemoSection('Beside the controls they sit with'),
          DemoVariant(
            'medium matches a medium Button: a toolbar',
            Row(
              children: [
                const Button.primary('Publish', onPressed: _noop),
                const Gap(AdminSpacing.sm),
                const Button('Preview', onPressed: _noop),
                const Gap(AdminSpacing.sm),
                IconAction(
                  Icons.history_rounded,
                  label: 'History',
                  onPressed: _noop,
                ),
                IconAction(
                  Icons.more_horiz,
                  label: 'More options',
                  onPressed: _noop,
                ),
              ],
            ),
          ),
          DemoVariant(
            'small matches a small Button: a dense row',
            Row(
              children: [
                const Button(
                  'Filter',
                  size: ControlSize.small,
                  icon: Icons.filter_list_rounded,
                  onPressed: _noop,
                ),
                const Gap(AdminSpacing.xs),
                IconAction(
                  Icons.view_column_outlined,
                  label: 'Columns',
                  size: IconActionSize.small,
                  onPressed: _noop,
                ),
                IconAction(
                  Icons.refresh_rounded,
                  label: 'Refresh',
                  size: IconActionSize.small,
                  onPressed: _noop,
                ),
              ],
            ),
          ),
          DemoVariant(
            'inline clears a value: ClearButton',
            SizedBox(
              width: 260,
              child: Panel(
                padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Mar 4 – Mar 18', style: context.type.body),
                    ),
                    ClearButton(onPressed: _noop),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caption(BuildContext context, String text) => Text(
    text,
    style: context.type.caption.copyWith(color: context.colors.foregroundMuted),
  );
}

/// A dialog's title row with its close action, the way overlays use it.
class _DialogHeader extends StatelessWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.xl,
        AdminSpacing.md,
        AdminSpacing.md,
        AdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.radii.radiusDialog),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Delete 3 pages?', style: context.type.bodyStrong),
          ),
          IconAction.close(onPressed: _noop),
        ],
      ),
    );
  }
}

/// A caption row over rows of actions, one per column.
class _Grid extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;

  const _Grid({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, AdminSpacing.xl, 6),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            for (final c in columns)
              cell(
                Text(
                  c,
                  style: context.type.caption.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(children: [for (final w in row) cell(w)]),
      ],
    );
  }
}

void _noop() {}
