import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// The key→value (map) field across states. The live ones are
/// [KeyValueField]s bound to a `LocalScope.map` cell.
class KeyValueFieldDemo extends StatelessWidget {
  @Preview(name: 'Key → value (map)', wrapper: adminUiPreview)
  const KeyValueFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        DemoSection('Editor — add · edit · remove rows'),
        DemoVariant(
          'Live — type a key and a value, add or remove rows',
          const _Live(
            label: 'SEO meta',
            initial: {
              'og:title': 'Summer Collection',
              'og:type': 'website',
              'twitter:card': 'summary_large_image',
            },
          ),
        ),
        DemoVariant(
          'Empty — nothing yet, just the add affordance',
          const _Live(label: 'Custom metadata', initial: {}),
        ),
        DemoVariant(
          'Custom labels — HTTP headers',
          const _Live(
            label: 'Request headers',
            initial: {
              'Authorization': 'Bearer …',
              'Accept': 'application/json',
            },
            keyHint: 'Header',
            valueHint: 'Value',
            addLabel: 'Add header',
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged)',
          const FieldShell(
            label: 'Environment',
            child: KeyValueBody(
              value: {'REGION': 'eu-west-1', 'TIER': 'production'},
            ),
          ),
        ),
        DemoVariant(
          'Read-only & empty',
          const FieldShell(
            label: 'Environment',
            child: KeyValueBody(emptyLabel: 'No variables set'),
          ),
        ),
        DemoVariant(
          'Disabled',
          const FieldShell(
            label: 'Environment',
            enabled: false,
            child: KeyValueBody(
              value: {'REGION': 'eu-west-1', 'TIER': 'production'},
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'Duplicate key — add a row, retype an existing key: both flag red '
          'and a message says the lower row wins',
          const _Live(label: 'Settings', initial: {'theme': 'dark'}),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          const FieldShell(
            label: 'SEO meta',
            modified: true,
            child: KeyValueBody(
              value: {'og:title': 'Edited title'},
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'Validation error',
          const FieldShell(
            label: 'SEO meta',
            errorText: 'At least one tag is required before publishing.',
            child: KeyValueBody(value: {'og:type': ''}, onChanged: _ignore),
          ),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final Map<String, String> initial;
  final String? keyHint;
  final String? valueHint;
  final String? addLabel;

  const _Live({
    required this.label,
    required this.initial,
    this.keyHint,
    this.valueHint,
    this.addLabel,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  final _scope = LocalScope();
  late final _cell = _scope.map('value')..set(widget.initial);

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyValueField(
      _cell,
      label: widget.label,
      keyHint: widget.keyHint,
      valueHint: widget.valueHint,
      addLabel: widget.addLabel,
    );
  }
}

void _ignore(Map<String, String> _) {}
