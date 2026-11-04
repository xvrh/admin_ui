import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// The free-form tags field (`List<String>`) across states. For a tag picker
/// bound to a known option set, see the multi-select demo's creatable tokens.
class TagsFieldDemo extends StatelessWidget {
  @Preview(name: 'Tags (free-form)', wrapper: adminUiPreview)
  const TagsFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Editor — type, enter to add, × or backspace to remove'),
        DemoVariant(
          'Live — order is preserved, duplicates rejected',
          const _Live(
            label: 'Tags',
            initial: ['launch-2026', 'featured', 'summer'],
          ),
        ),
        DemoVariant(
          'Empty — just the add input, with the kit\'s own hint',
          const _Live(label: 'Tags', initial: [], hint: null),
        ),
        DemoVariant(
          'Long values wrap within the box',
          const _Live(
            label: 'Audience',
            initial: [
              'early-access-subscribers',
              'newsletter',
              'returning-customers-2025',
            ],
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged)',
          const FieldShell(
            label: 'Tags',
            child: TagsBody(value: ['featured', 'summer']),
          ),
        ),
        DemoVariant(
          'Read-only & empty — the box stays, with a neutral "No tags"',
          const FieldShell(label: 'Tags', child: TagsBody()),
        ),
        DemoVariant(
          'Disabled',
          const FieldShell(
            label: 'Tags',
            enabled: false,
            child: TagsBody(value: ['featured', 'summer'], onChanged: _ignore),
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          const FieldShell(
            label: 'Tags',
            modified: true,
            child: TagsBody(
              value: ['featured', 'editor-pick'],
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'Validation error',
          const FieldShell(
            label: 'Tags',
            errorText: 'Add at least one tag before publishing.',
            child: TagsBody(onChanged: _ignore),
          ),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final List<String> initial;
  final String? hint;

  const _Live({required this.label, required this.initial, this.hint = 'Add…'});

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late List<String> _value = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      child: TagsBody(
        value: _value,
        hint: widget.hint,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

void _ignore(List<String> _) {}
