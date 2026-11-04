import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The control-size tokens at work: at each [ControlSize], a button, an
/// icon button, text inputs (plain, a leading glyph, a clear action, a
/// chevron) and a popover trigger in one row, then the field states —
/// hovered (pinned), invalid, disabled and read-only — so each theme's
/// heights and insets can be measured side by side. A last row sets the
/// other sized controls beside them: a [Segmented] and a
/// [ColumnChooserButton], which take the theme's heights, and a [Tabs]
/// strip, whose heights are its own.
class ControlSizesDemo extends StatelessWidget {
  @Preview(name: 'Control sizes', wrapper: adminUiPreview)
  const ControlSizesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return DemoPage(
      maxWidth: 1080,
      children: [
        Text(
          'small ${_px(sizes.small)} · medium ${_px(sizes.medium)} · '
          'large ${_px(sizes.large)} · padding ${_px(sizes.fieldPaddingX)} · '
          'glyph ${_px(sizes.fieldIcon)} + ${_px(sizes.fieldIconGap)}',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.xl),
        for (final size in ControlSize.values) ...[
          DemoSection('${size.name} · ${_px(sizes.height(size))}'),
          _Row(
            children: [
              Button('Button', size: size, onPressed: _noop),
              Button.icon(
                Icons.tune_rounded,
                semanticLabel: 'Filters',
                size: size,
                onPressed: _noop,
              ),
              _Input(size: size, hint: 'Plain'),
              _Input(size: size, hint: 'Search', leadingIcon: Icons.search),
              _Input(size: size, text: 'Clearable', clear: true),
              _Input(size: size, hint: 'Choose', chevron: true),
              _Trigger(size: size, label: 'Trigger'),
            ],
          ),
          const Gap(AdminSpacing.md),
          _Row(
            children: [
              _Input(size: size, text: 'Hovered', hovered: true),
              FieldStateScope(
                invalid: true,
                child: _Input(size: size, text: 'Invalid'),
              ),
              FieldStateScope(
                enabled: false,
                child: _Input(size: size, text: 'Disabled', clear: true),
              ),
              FieldStateScope(
                readOnly: true,
                child: _Input(size: size, text: 'Read-only', clear: true),
              ),
              _Trigger(size: size, label: 'Hovered', hovered: true),
              FieldStateScope(
                enabled: false,
                child: _Trigger(size: size, label: 'Disabled'),
              ),
              FieldStateScope(
                readOnly: true,
                child: _Trigger(size: size, label: 'Read-only'),
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
          _Row(
            children: [
              Segmented<String>(
                segments: const [
                  SegmentOption('list', 'List'),
                  SegmentOption('board', 'Board'),
                ],
                value: 'list',
                onChanged: (_) {},
                size: size,
              ),
              ColumnChooserButton(
                columns: _columns,
                layout: _layout,
                onChanged: (_) {},
                size: size,
              ),
              SizedBox(
                width: 240,
                child: Tabs(
                  tabs: const [TabItem('Content'), TabItem('Settings')],
                  selected: 0,
                  onChanged: (_) {},
                  size: size,
                ),
              ),
            ],
          ),
          const Gap(AdminSpacing.xl),
        ],
      ],
    );
  }
}

void _noop() {}

String _px(double value) => value.toStringAsFixed(0);

const _columns = [
  ColumnChoice(key: 'title', label: 'Title'),
  ColumnChoice(key: 'status', label: 'Status'),
];

const _layout = ColumnLayout(order: ['title', 'status']);

/// Controls in one row, the fields at a common width.
class _Row extends StatelessWidget {
  final List<Widget> children;

  const _Row({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminSpacing.md,
      runSpacing: AdminSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// A raw [TextField] on [fieldInputDecoration], owning its controller.
class _Input extends StatefulWidget {
  final ControlSize size;
  final String? hint;
  final String text;
  final IconData? leadingIcon;
  final bool clear;
  final bool chevron;
  final bool hovered;

  const _Input({
    required this.size,
    this.hint,
    this.text = '',
    this.leadingIcon,
    this.clear = false,
    this.chevron = false,
    this.hovered = false,
  });

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context);
    return SizedBox(
      width: 132,
      child: TextField(
        controller: _controller,
        readOnly: state.readOnly,
        style: fieldTextStyle(context),
        decoration: fieldInputDecoration(
          context,
          hint: widget.hint,
          size: widget.size,
          leadingIcon: widget.leadingIcon,
          hovered: widget.hovered,
          suffix: widget.clear
              ? ClearButton(onPressed: _controller.clear)
              : widget.chevron
              ? const FieldChevron()
              : null,
        ),
      ),
    );
  }
}

/// A [FieldTrigger] with a chevron over a one-line menu, or the bare
/// [FieldChrome] with its hover pinned.
class _Trigger extends StatelessWidget {
  final ControlSize size;
  final String label;
  final bool hovered;

  const _Trigger({
    required this.size,
    required this.label,
    this.hovered = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: fieldTextStyle(context),
    );
    return SizedBox(
      width: 132,
      child: hovered
          ? FieldChrome(size: size, hovered: true, child: text)
          : Popover(
              anchor: (context, controller) => FieldTrigger(
                controller: controller,
                size: size,
                chevron: true,
                semanticLabel: label,
                child: text,
              ),
              content: (context, controller) => const Padding(
                padding: EdgeInsets.all(AdminSpacing.md),
                child: Text('Options'),
              ),
            ),
    );
  }
}
