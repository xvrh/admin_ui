import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// A state a field's box takes: one row of the grid.
enum _State {
  rest('Rest'),
  hovered('Hovered'),
  focused('Focused'),
  invalid('Invalid'),
  invalidFocused('Invalid + focused'),
  readOnly('Read-only'),
  disabled('Disabled');

  final String label;

  const _State(this.label);

  bool get isHovered => this == hovered;
  bool get isFocused => this == focused || this == invalidFocused;
  bool get isInvalid => this == invalid || this == invalidFocused;
}

/// The theme's field anatomy (`context.fieldStyle`: an outlined, filled or
/// underlined box, its focus indicator, accent and corner) in every state,
/// on the four boxes that draw it: an input, a select trigger, a text area
/// and a number stepper. Down a column the box keeps its size and its
/// content stays put; across a row every box draws the same edges.
///
/// The input and the text area pin their states on the decorator a
/// `TextField` draws, the trigger through its states controller. One field
/// holds the page's real focus: the stepper in the focused row.
class FieldAnatomyDemo extends StatefulWidget {
  @Preview(name: 'Field anatomy', wrapper: adminUiPreview)
  const FieldAnatomyDemo({super.key});

  @override
  State<FieldAnatomyDemo> createState() => _FieldAnatomyDemoState();
}

class _FieldAnatomyDemoState extends State<FieldAnatomyDemo> {
  final _focus = FocusNode(debugLabel: 'Field anatomy · stepper');
  final _pins = {
    _State.hovered: WidgetStatesController({WidgetState.hovered}),
    _State.focused: WidgetStatesController({WidgetState.focused}),
    _State.invalidFocused: WidgetStatesController({WidgetState.focused}),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    for (final pin in _pins.values) {
      pin.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = context.type.caption.copyWith(
      color: context.colors.foregroundMuted,
    );
    Widget row(Widget label, List<Widget> cells) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: label),
        for (final (i, cell) in cells.indexed) ...[
          if (i > 0) const Gap(AdminSpacing.lg),
          Expanded(child: cell),
        ],
      ],
    );
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 880,
        children: [
          DemoSection('Every box in every state'),
          row(const SizedBox(), [
            for (final title in ['Input', 'Select', 'Text area', 'Stepper'])
              Text(title, style: caption),
          ]),
          for (final state in _State.values) ...[
            const Gap(AdminSpacing.lg),
            FieldStateScope(
              enabled: state != _State.disabled,
              readOnly: state == _State.readOnly,
              invalid: state.isInvalid,
              child: row(
                // On the boxes' first line of text.
                Padding(
                  padding: const EdgeInsets.only(top: AdminSpacing.md),
                  child: Text(state.label, style: caption),
                ),
                [
                  // Each built under the row's scope.
                  Builder(builder: (context) => _input(context, state)),
                  Builder(builder: (context) => _select(context, state)),
                  Builder(
                    builder: (context) => _input(context, state, lines: 3),
                  ),
                  _stepper(state),
                ],
              ),
            ),
          ],
          const Gap(AdminSpacing.xl),
          Text(
            'The stepper holds the page’s focus, so its invalid and focused '
            'box is not shown.',
            style: caption,
          ),
        ],
      ),
    );
  }

  /// The decorator a text body's `TextField` draws, with [lines] of text.
  Widget _input(BuildContext context, _State state, {int lines = 1}) {
    return InputDecorator(
      decoration: fieldInputDecoration(context, hovered: state.isHovered),
      isFocused: state.isFocused,
      child: Text(
        lines == 1
            ? 'A coast that keeps'
            : 'A coast that keeps its lamps lit well into the evening, '
                  'and a harbour that wakes before the town.',
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
        style: fieldTextStyle(context),
      ),
    );
  }

  Widget _select(BuildContext context, _State state) {
    return Popover(
      anchor: (context, controller) => FieldTrigger(
        controller: controller,
        chevron: true,
        statesController: _pins[state],
        child: Text(
          'Draft',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fieldTextStyle(context),
        ),
      ),
      content: (context, controller) => const SizedBox.shrink(),
    );
  }

  Widget _stepper(_State state) {
    if (state == _State.invalidFocused) return const SizedBox.shrink();
    // Empty while focused, so a touch platform's selection handle does not
    // show.
    final stepper = NumberBody(
      value: state.isFocused ? null : 8,
      hint: '8',
      appearance: NumberAppearance.stepper,
      onChanged: state == _State.readOnly ? null : (_) {},
      focusNode: state == _State.focused ? _focus : null,
    );
    return state.isHovered ? PinnedHover(child: stepper) : stepper;
  }
}
