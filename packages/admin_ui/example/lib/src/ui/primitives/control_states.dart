import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Every interaction state of the core controls side by side, pinned so a
/// static render shows them: hovered, pressed and focused buttons (labelled
/// and icon-only), checks, toggles, radios and segments are seeded through
/// their states controller, and the selected tab holds real keyboard focus
/// with the keyboard highlight forced on while this page is up. Checks,
/// toggles, radios and segments show read-only beside disabled: the value
/// at full contrast, against the dimmed one. A tab and a slider, which keep
/// their hover to themselves, have a pinned mouse resting on them. Sliders
/// at rest, hovered and disabled, and a switch named only for screen
/// readers, close the page.
class ControlStatesDemo extends StatefulWidget {
  @Preview(name: 'Control states', wrapper: adminUiPreview)
  const ControlStatesDemo({super.key});

  @override
  State<ControlStatesDemo> createState() => _ControlStatesDemoState();
}

class _ControlStatesDemoState extends State<ControlStatesDemo> {
  static const _pinned = [
    WidgetState.hovered,
    WidgetState.pressed,
    WidgetState.focused,
  ];

  final _tabsScope = FocusScopeNode(debugLabel: 'Control states tabs');

  /// One controller per pinned control, keyed by where it sits and seeded
  /// with one state.
  final _seeded = <Object, WidgetStatesController>{};

  WidgetStatesController _pin(Object at, WidgetState state) =>
      _seeded.putIfAbsent((at, state), () => WidgetStatesController({state}));

  /// A grid cell's controller: pinned for the hover and focus columns.
  WidgetStatesController? _cell(Object at, _Cell cell) =>
      cell.pinned == null ? null : _pin(at, cell.pinned!);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabsScope.traversalDescendants.firstOrNull?.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabsScope.dispose();
    for (final controller in _seeded.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const variants = [
      ('Primary', ButtonVariant.primary, false),
      ('Secondary', ButtonVariant.secondary, false),
      ('Danger', ButtonVariant.primary, true),
      ('Ghost', ButtonVariant.ghost, false),
    ];
    return KeyboardHighlight(
      child: DemoPage(
        // Wide enough for Carbon's buttons, the widest: five 164px columns.
        maxWidth: 900,
        children: [
          const DemoSection('Button'),
          _Grid(
            scrolls: true,
            columns: const ['Rest', 'Hover', 'Pressed', 'Focused', 'Disabled'],
            rows: [
              for (final (label, variant, danger) in variants)
                [
                  Button(
                    label,
                    variant: variant,
                    danger: danger,
                    onPressed: _noop,
                  ),
                  for (final state in _pinned)
                    Button(
                      label,
                      variant: variant,
                      danger: danger,
                      onPressed: _noop,
                      statesController: _pin(('button', label), state),
                    ),
                  Button(label, variant: variant, danger: danger),
                ],
              for (final variant in const [
                ButtonVariant.secondary,
                ButtonVariant.ghost,
              ])
                [
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

          const DemoSection('Check'),
          _Grid(
            columns: _stateColumns,
            rows: [
              for (final (label, value, mixed) in const [
                ('Off', false, false),
                ('On', true, false),
                ('Mixed', false, true),
              ])
                [
                  _RowLabel(label),
                  for (final cell in _Cell.values)
                    Check(
                      value: value,
                      indeterminate: mixed,
                      onChanged: cell == _Cell.disabled ? null : (_) {},
                      readOnly: cell == _Cell.readOnly,
                      statesController: _cell(('check', label), cell),
                    ),
                ],
            ],
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('Toggle'),
          _Grid(
            columns: _stateColumns,
            rows: [
              for (final (label, value) in const [('Off', false), ('On', true)])
                [
                  _RowLabel(label),
                  for (final cell in _Cell.values)
                    Toggle(
                      value: value,
                      onChanged: cell == _Cell.disabled ? null : (_) {},
                      readOnly: cell == _Cell.readOnly,
                      statesController: _cell(('toggle', label), cell),
                    ),
                ],
            ],
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('Radio'),
          _Grid(
            columns: _stateColumns,
            rows: [
              for (final (label, selected) in const [
                ('Off', false),
                ('On', true),
              ])
                [
                  _RowLabel(label),
                  for (final cell in _Cell.values)
                    Choice<bool>(
                      value: selected,
                      onChanged: cell == _Cell.disabled ? null : (_) {},
                      readOnly: cell == _Cell.readOnly,
                      options: [
                        ChoiceOption(
                          true,
                          '',
                          statesController: _cell(('radio', label), cell),
                        ),
                      ],
                    ),
                ],
            ],
          ),
          const Gap(AdminSpacing.lg),
          Choice<String>(
            value: 'selected',
            onChanged: (_) {},
            style: ChoiceStyle.card,
            options: [
              const ChoiceOption(
                'selected',
                'Selected',
                description: 'The chosen card keeps its size.',
              ),
              ChoiceOption(
                'hovered',
                'Hovered',
                description: 'A tint under the pointer.',
                statesController: _pin('card', WidgetState.hovered),
              ),
              ChoiceOption(
                'focused',
                'Focused',
                description: 'The ring goes round the whole card.',
                statesController: _pin('card', WidgetState.focused),
              ),
            ],
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('Segmented'),
          for (final (label, segmented) in [
            (
              'Hovered',
              Segmented<String>(
                value: 'list',
                onChanged: (_) {},
                segments: [
                  const SegmentOption('list', 'List'),
                  SegmentOption(
                    'grid',
                    'Hovered',
                    statesController: _pin('segment', WidgetState.hovered),
                  ),
                  const SegmentOption('board', 'Board'),
                ],
              ),
            ),
            (
              'Focused',
              Segmented<String>(
                value: 'list',
                onChanged: (_) {},
                segments: [
                  SegmentOption(
                    'list',
                    'Focused',
                    statesController: _pin('segment', WidgetState.focused),
                  ),
                  const SegmentOption('grid', 'Grid'),
                  const SegmentOption('board', 'Board'),
                ],
              ),
            ),
            (
              'Read-only',
              const Segmented<String>(
                value: 'list',
                readOnly: true,
                segments: _segments,
              ),
            ),
            (
              'Disabled',
              const Segmented<String>(value: 'list', segments: _segments),
            ),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
              child: Row(
                children: [
                  SizedBox(width: 88, child: _RowLabel(label)),
                  segmented,
                ],
              ),
            ),
          const Gap(AdminSpacing.xl),

          // The selected tab is the strip's one Tab stop, so it takes the focus.
          const DemoSection(
            'Tabs — rest, selected and focused, hovered, disabled',
          ),
          FocusScope(
            node: _tabsScope,
            child: PinnedHover(
              target: (widget) => widget is Text && widget.data == 'Hovered',
              child: Tabs(
                tabs: const [
                  TabItem('Rest'),
                  TabItem('Selected, focused'),
                  TabItem('Hovered'),
                  TabItem('Disabled', enabled: false),
                ],
                selected: 1,
                onChanged: (_) {},
              ),
            ),
          ),
          const Gap(AdminSpacing.lg),
          FocusScope(
            child: Tabs(
              variant: TabsVariant.enclosed,
              tabs: const [
                TabItem('Selected'),
                TabItem('Rest'),
                TabItem('Disabled', enabled: false),
              ],
              selected: 0,
              onChanged: (_) {},
            ),
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('Slider'),
          _Grid(
            columns: const ['', 'Value'],
            rows: [
              [
                const _RowLabel('Rest'),
                SizedBox(
                  width: 280,
                  child: ValueSlider(value: 0.4, onChanged: (_) {}),
                ),
              ],
              [
                const _RowLabel('Hover'),
                // Halfway, so the thumb sits under the pointer at the centre.
                SizedBox(
                  width: 280,
                  child: PinnedHover(
                    target: (widget) => widget is Slider,
                    child: ValueSlider(value: 0.5, onChanged: (_) {}),
                  ),
                ),
              ],
              const [
                _RowLabel('Disabled'),
                SizedBox(
                  width: 280,
                  child: ValueSlider(value: 0.6, onChanged: null),
                ),
              ],
            ],
          ),
          const Gap(AdminSpacing.xl),

          // The row's text names the switch visually; semanticLabel names it
          // for a screen reader.
          const DemoSection('Toggle — named without a visible label'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email notifications', style: context.type.body),
                    Text(
                      'A digest of the day’s changes.',
                      style: context.type.caption.copyWith(
                        color: context.colors.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Toggle(
                value: true,
                onChanged: (_) {},
                semanticLabel: 'Email notifications',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The columns of the selection-control grids: a row label, then each
/// [_Cell].
const _stateColumns = ['', 'Rest', 'Hover', 'Focused', 'Read-only', 'Disabled'];

/// A column of the selection-control grids.
enum _Cell {
  rest,
  hovered(WidgetState.hovered),
  focused(WidgetState.focused),
  readOnly,
  disabled;

  /// The state the cell's control is seeded with.
  final WidgetState? pinned;

  const _Cell([this.pinned]);
}

const _segments = [
  SegmentOption('list', 'List'),
  SegmentOption('grid', 'Grid'),
  SegmentOption('board', 'Board'),
];

class _RowLabel extends StatelessWidget {
  final String label;

  const _RowLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: context.type.caption.copyWith(color: context.colors.foregroundMuted),
  );
}

/// A caption row over rows of controls, one control per column. With
/// [scrolls], a page too narrow for every column scrolls sideways rather
/// than cutting the last ones off.
class _Grid extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final bool scrolls;

  const _Grid({
    required this.columns,
    required this.rows,
    this.scrolls = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, AdminSpacing.lg, 6),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
    final table = Table(
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
    return scrolls
        ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: table)
        : table;
  }
}

void _noop() {}
