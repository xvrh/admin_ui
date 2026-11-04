import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class InputFieldDemo extends StatelessWidget {
  @Preview(name: 'Input field', wrapper: adminUiPreview)
  const InputFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        const DemoVariant(
          'Focused (the default shape in a dialog or settings pane)',
          InputField(label: 'Title', hint: 'Untitled page', autofocus: true),
        ),
        const DemoVariant(
          'Hovered — a step stronger outline, never past the focused one',
          PinnedHover(
            target: _isTextField,
            child: InputField(label: 'Title', hint: 'Untitled page'),
          ),
        ),
        const DemoVariant(
          'With a description under the label',
          InputField(
            label: 'Slug',
            description:
                'Used in the page address: lowercase, numbers, dashes.',
            hint: 'about-us',
          ),
        ),
        const DemoVariant(
          'Sizes — small, medium, large',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputField(hint: 'Small', size: ControlSize.small),
              Gap(AdminSpacing.md),
              InputField(hint: 'Medium'),
              Gap(AdminSpacing.md),
              InputField(hint: 'Large', size: ControlSize.large),
            ],
          ),
        ),
        const DemoVariant(
          'Multi-line',
          InputField(
            label: 'Summary',
            hint: 'A sentence or two for search results',
            maxLines: 4,
            minLines: 3,
          ),
        ),
        const DemoVariant(
          'Invalid — red border plus the message',
          InputField(label: 'Title', value: '', errorText: 'Title is required'),
        ),
        const DemoVariant(
          'Leading glyph, trailing label affordance',
          InputField(
            label: 'Deep link',
            labelTrailing: Text('optional'),
            icon: Icons.link,
            hint: 'example://article/42',
          ),
        ),
        const DemoVariant(
          'No label — bare control for a caller with its own chrome',
          InputField(hint: 'Search term'),
        ),
        const DemoVariant(
          'No label, invalid',
          InputField(value: 'not a number', errorText: 'Enter a number'),
        ),
        const DemoVariant(
          'Read-only — full contrast, focusable and selectable',
          InputField(label: 'Page id', value: 'page_7f3a21', readOnly: true),
        ),
        const DemoVariant(
          'Disabled',
          InputField(
            label: 'App id',
            value: 'com.example.app',
            icon: Icons.apps_rounded,
            enabled: false,
          ),
        ),
        DemoVariant(
          'Live — validates as you type, the message line kept free',
          LiveValue<String>(
            initial: '',
            builder: (value, onChanged) => InputField(
              label: 'Title',
              hint: 'Type something',
              onChanged: onChanged,
              reserveErrorLine: true,
              errorText: value.trim().isEmpty ? 'Title is required' : null,
            ),
          ),
        ),
        const DemoVariant(
          'reserveErrorLine — the next field stays put, message or not',
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ReservedPair(errorText: null)),
              Gap(AdminSpacing.lg),
              Expanded(child: _ReservedPair(errorText: 'Enter a title')),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isTextField(Widget widget) => widget is TextField;

/// A field that reserves its message line, above the next one.
class _ReservedPair extends StatelessWidget {
  final String? errorText;

  const _ReservedPair({required this.errorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputField(
          label: 'Title',
          value: errorText == null ? 'Launch notes' : '',
          reserveErrorLine: true,
          errorText: errorText,
        ),
        const Gap(AdminSpacing.md),
        const InputField(label: 'Slug', value: 'launch-notes'),
      ],
    );
  }
}
