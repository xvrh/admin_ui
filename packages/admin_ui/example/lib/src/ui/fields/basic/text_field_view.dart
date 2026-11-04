import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// The plain field, no capabilities — just label, control and states.
class TextFieldDemo extends StatelessWidget {
  @Preview(name: 'Text', wrapper: adminUiPreview)
  const TextFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoVariant(
          'Empty (hint)',
          const FieldShell(
            label: 'Slug',
            child: TextBody(hint: 'about-us'),
          ),
        ),
        DemoVariant(
          'Filled',
          FieldShell(
            label: 'Title',
            child: TextBody(
              controller: TextEditingController(
                text: 'A coast that keeps its own time',
              ),
            ),
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          FieldShell(
            label: 'Title',
            modified: true,
            child: TextBody(
              controller: TextEditingController(
                text: 'A coast that marks its own time',
              ),
            ),
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged) — full contrast, selectable',
          const FieldShell(
            label: 'Slug',
            child: TextBody(value: 'a-coast-that-keeps-its-own-time'),
          ),
        ),
        DemoVariant(
          'Disabled',
          const FieldShell(
            label: 'Slug',
            enabled: false,
            child: TextBody(
              value: 'a-coast-that-keeps-its-own-time',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'Validation error',
          const FieldShell(
            label: 'Title',
            errorText: 'A title is required before publishing.',
            child: TextBody(value: '', hint: 'Untitled', onChanged: _ignore),
          ),
        ),
        DemoVariant(
          'Long label truncates',
          const FieldShell(
            label:
                'A rather long field label that should truncate '
                'gracefully rather than overflow the row',
            child: TextBody(hint: 'Type here…'),
          ),
        ),
        Text(
          'Tap a label or field — the label turns primary while focused.',
          style: TextStyle(fontSize: 12, color: context.colors.foregroundMuted),
        ),
        const SizedBox(height: 32),
        DemoSection('Optional text — cleared, the value is unset'),
        const _OptionalText(),
      ],
    );
  }
}

void _ignore(String _) {}

/// The optional text field with [Field]'s text options: a counted text area
/// and a fixed prefix.
class _OptionalText extends StatefulWidget {
  const _OptionalText();

  @override
  State<_OptionalText> createState() => _OptionalTextState();
}

class _OptionalTextState extends State<_OptionalText> {
  final _scope = LocalScope();

  late final _bio = _scope.textOrNull('bio')
    ..set('Writes about coastal towns and the trains between them.');
  late final _website = _scope.textOrNull('website');

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoVariant(
          'Text area — 3 to 6 lines, counted to 160',
          OptionalField(
            _bio,
            label: 'Bio',
            minLines: 3,
            maxLines: 6,
            maxLength: 160,
            hint: 'A line or two for the author page',
          ),
        ),
        DemoVariant(
          'Prefix — shown while empty',
          OptionalField(
            _website,
            label: 'Website',
            prefix: 'https://',
            hint: 'example.com',
            keyboardType: TextInputType.url,
            autofillHints: const [AutofillHints.url],
          ),
        ),
      ],
    );
  }
}
