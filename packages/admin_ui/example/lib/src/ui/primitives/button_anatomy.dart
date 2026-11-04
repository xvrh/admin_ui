import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Every button variant in both tones, neutral and danger, pinned at rest,
/// hovered, pressed, keyboard-focused and disabled, so a static render
/// shows the whole state matrix of a theme's buttons: the states come
/// through each button's states controller, with the keyboard highlight
/// forced on while the page is up. Icon-only buttons and split buttons
/// close the page.
class ButtonAnatomyDemo extends StatefulWidget {
  @Preview(name: 'Button · variants and tones', wrapper: adminUiPreview)
  const ButtonAnatomyDemo({super.key});

  @override
  State<ButtonAnatomyDemo> createState() => _ButtonAnatomyDemoState();
}

class _ButtonAnatomyDemoState extends State<ButtonAnatomyDemo> {
  static const _pinned = [
    WidgetState.hovered,
    WidgetState.pressed,
    WidgetState.focused,
  ];

  static const _variants = [
    ('Primary', ButtonVariant.primary),
    ('Secondary', ButtonVariant.secondary),
    ('Soft', ButtonVariant.soft),
    ('Ghost', ButtonVariant.ghost),
    ('Link', ButtonVariant.link),
  ];

  /// One controller per pinned button, keyed by where it sits and seeded
  /// with one state.
  final _seeded = <Object, WidgetStatesController>{};

  WidgetStatesController _pin(Object at, WidgetState state) =>
      _seeded.putIfAbsent((at, state), () => WidgetStatesController({state}));

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
    for (final controller in _seeded.values) {
      controller.dispose();
    }
    _splitAction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 900,
        children: [
          const DemoSection('Variants × tones'),
          _Grid(
            columns: const [
              '',
              'Rest',
              'Hover',
              'Pressed',
              'Focused',
              'Disabled',
            ],
            rows: [
              for (final (name, variant) in _variants)
                for (final danger in [false, true])
                  [
                    _RowLabel(danger ? '$name · danger' : name),
                    Button(
                      danger ? 'Delete' : 'Save',
                      variant: variant,
                      danger: danger,
                      onPressed: _noop,
                    ),
                    for (final state in _pinned)
                      Button(
                        danger ? 'Delete' : 'Save',
                        variant: variant,
                        danger: danger,
                        onPressed: _noop,
                        statesController: _pin((variant, danger), state),
                      ),
                    Button(
                      danger ? 'Delete' : 'Save',
                      variant: variant,
                      danger: danger,
                    ),
                  ],
              for (final (name, variant) in _variants.take(4))
                [
                  _RowLabel('$name · icon'),
                  Button.icon(
                    Icons.tune_rounded,
                    semanticLabel: 'Filters',
                    variant: variant,
                    onPressed: _noop,
                  ),
                  for (final state in _pinned)
                    Button.icon(
                      Icons.tune_rounded,
                      semanticLabel: 'Filters',
                      variant: variant,
                      onPressed: _noop,
                      statesController: _pin(('icon', variant), state),
                    ),
                  Button.icon(
                    Icons.tune_rounded,
                    semanticLabel: 'Filters',
                    variant: variant,
                  ),
                ],
            ],
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('With glyphs'),
          const Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Button.primary(
                'Publish',
                icon: Icons.send_rounded,
                onPressed: _noop,
              ),
              Button('Filter', icon: Icons.tune_rounded, onPressed: _noop),
              Button(
                'Options',
                trailingIcon: Icons.keyboard_arrow_down_rounded,
                onPressed: _noop,
              ),
              Button.soft('Add', icon: Icons.add_rounded, onPressed: _noop),
              Button.ghost(
                'Remove',
                icon: Icons.delete_outline,
                danger: true,
                onPressed: _noop,
              ),
            ],
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('Split'),
          Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SplitButton(
                label: 'Publish',
                icon: Icons.send_rounded,
                onPressed: _noop,
                focusNode: _splitAction,
                entries: _options,
                menuSemanticLabel: 'More publish options',
              ),
              SplitButton(
                label: 'Save',
                variant: ButtonVariant.secondary,
                onPressed: _noop,
                entries: _options,
                menuSemanticLabel: 'More save options',
              ),
              SplitButton(
                label: 'Delete',
                danger: true,
                onPressed: _noop,
                entries: _options,
                menuSemanticLabel: 'More delete options',
              ),
              SplitButton(
                label: 'Publish',
                onPressed: null,
                entries: _options,
                menuSemanticLabel: 'More publish options',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String text;

  const _RowLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.type.caption.copyWith(color: context.colors.foregroundMuted),
  );
}

class _Grid extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;

  const _Grid({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, AdminSpacing.lg, 6),
      child: Align(alignment: AlignmentDirectional.centerStart, child: child),
    );
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [for (final c in columns) cell(_RowLabel(c))]),
        for (final row in rows)
          TableRow(children: [for (final w in row) cell(w)]),
      ],
    );
  }
}

void _noop() {}

final _options = <MenuEntry>[
  const MenuItem('Schedule…', icon: Icons.schedule_rounded, onSelect: _noop),
  const MenuDivider(),
  const MenuItem('Delete', danger: true, onSelect: _noop),
];
