import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

const _validJson = '''
{
  "id": "prod_4821",
  "title": "Stone-pressed cider",
  "price": 14.5,
  "inStock": true,
  "archived": false,
  "tags": ["seasonal", "estate", "small-batch"],
  "origin": { "region": "North", "yield": "12t" },
  "discount": null
}''';

const _invalidJson = '''
{
  "id": "prod_4821",
  "tags": ["seasonal" "estate"],
  "price": 14.5,
}''';

const _plain = '''
server {
  listen 443 ssl;
  server_name admin.example.com;
  location /api/ {
    proxy_pass http://127.0.0.1:8080;
  }
}''';

/// The [CodeBody] field — a monospace editor for raw config / metadata. JSON
/// mode highlights tokens, validates live (the footer names the failing line),
/// and the Format button re-indents valid JSON. Drive the parameters to flip
/// language, line numbers and read-only.
class CodeFieldDemo extends StatefulWidget {
  @Preview(name: 'Code / JSON field', wrapper: adminUiPreview)
  const CodeFieldDemo({super.key});

  @override
  State<CodeFieldDemo> createState() => _CodeFieldDemoState();
}

class _CodeFieldDemoState extends State<CodeFieldDemo> {
  String _value = _validJson;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DemoPage(
      maxWidth: 880,
      children: [
        Text(
          'A monospace code field. Its value is a plain string, so it sits in a '
          'FieldShell or a translatable lane like any other body. JSON mode adds '
          'syntax highlighting, live validation and a prettify action.',
          style: TextStyle(color: colors.foregroundMuted, height: 1.5),
        ),
        const SizedBox(height: 24),

        FieldShell(
          label: 'Metadata',
          help: const HelpButton(
            text:
                'Stored as a JSON string. The field validates on every edit; '
                'Format re-indents when the document parses.',
          ),
          child: CodeBody(
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
        ),
        const SizedBox(height: 28),

        const DemoVariant(
          'Invalid — the outline turns red, the footer pins the failing '
          'line/column',
          CodeBody(value: _invalidJson, onChanged: _noop),
        ),

        const DemoVariant(
          'Plain mode — no highlighting or validation',
          CodeBody(
            value: _plain,
            language: CodeLanguage.plain,
            onChanged: _noop,
          ),
        ),

        const DemoVariant(
          'Read-only (onChanged: null) — no Format action',
          CodeBody(value: _validJson),
        ),

        const DemoVariant(
          'Disabled',
          FieldStateScope(
            enabled: false,
            child: CodeBody(value: _validJson, onChanged: _noop),
          ),
        ),

        const DemoVariant(
          'Validation error from the field',
          FieldShell(
            label: 'Metadata',
            errorText: 'Metadata must include a "locale" key.',
            child: CodeBody(value: _validJson, onChanged: _noop),
          ),
        ),

        const DemoVariant(
          'Empty — hint, no gutter, no footer',
          CodeBody(
            value: '',
            onChanged: _noop,
            showLineNumbers: false,
            showFooter: false,
            hint: '{ }',
            minHeight: 80,
          ),
        ),
      ],
    );
  }
}

void _noop(String _) {}
