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

/// The text field in a right-to-left form. Text follows the page; an email
/// or a URL still reads left to right, with its hint and its prefix, under
/// a label and beside a counter that stay on the page's side.
class TextFieldRtlDemo extends StatefulWidget {
  @Preview(name: 'Text · right to left', wrapper: adminUiPreview)
  const TextFieldRtlDemo({super.key});

  @override
  State<TextFieldRtlDemo> createState() => _TextFieldRtlDemoState();
}

class _TextFieldRtlDemoState extends State<TextFieldRtlDemo> {
  final _scope = LocalScope();
  late final _name = _scope.text('name')..set('أمينة');
  late final _email = _scope.text('email')..set('amina@example.com');
  late final _invite = _scope.text('invite');
  late final _page = _scope.text('page');
  late final _code = _scope.text('code')..set('AB-1234');

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  Widget _rtl(Widget field) =>
      Directionality(textDirection: TextDirection.rtl, child: field);

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoVariant(
          'Text follows the page',
          _rtl(Field(_name, label: 'الاسم')),
        ),
        DemoVariant(
          'An email reads left to right, from the left',
          _rtl(
            Field(
              _email,
              label: 'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
        DemoVariant(
          'Its hint starts where the address will',
          _rtl(
            Field(
              _invite,
              label: 'دعوة',
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
        DemoVariant(
          'A URL keeps its prefix in front; the counter stays the page\'s',
          _rtl(
            Field(
              _page,
              label: 'الصفحة',
              prefix: 'https://',
              hint: 'example.com',
              maxLength: 60,
              keyboardType: TextInputType.url,
            ),
          ),
        ),
        DemoVariant(
          'textDirection — a code, whatever the keyboard',
          _rtl(Field(_code, label: 'الرمز', textDirection: TextDirection.ltr)),
        ),
      ],
    );
  }
}
