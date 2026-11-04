import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// The masked text field across mask templates and states. Type into the live
/// rows — separators auto-insert, the caret tracks mid-string edits, and pasting
/// a raw number reflows into the mask.
class MaskedFieldDemo extends StatelessWidget {
  @Preview(name: 'Masked (phone / card / date)', wrapper: adminUiPreview)
  const MaskedFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Live — separators auto-insert as you type'),
        DemoVariant(
          'Phone (US) · try pasting "+1 555 123 4567"',
          const _Live(label: 'Phone', mask: Masks.phoneUS),
        ),
        DemoVariant(
          'Credit card · groups of four',
          const _Live(label: 'Card number', mask: Masks.creditCard),
        ),
        DemoVariant(
          'Date · MM/DD/YYYY',
          const _Live(label: 'Publish date', mask: Masks.date),
        ),
        DemoVariant(
          'Time · HH:MM',
          const _Live(label: 'Time', mask: Masks.time),
        ),
        DemoSection('Eager — separator appears the moment a group fills'),
        DemoVariant(
          'Time · type "15" → "15:" (and backspace peels it back off)',
          const _Live(label: 'Time', mask: Masks.time, eager: true),
        ),
        DemoVariant(
          'Date · eager slashes',
          const _Live(label: 'Publish date', mask: Masks.date, eager: true),
        ),
        DemoSection('Ghost mask — unfilled positions stay visible inline'),
        DemoVariant(
          'Date · the grey __/__/____ fills in as you type',
          const _Live(label: 'Publish date', mask: Masks.date, ghostMask: true),
        ),
        DemoVariant(
          'Phone · ghost + eager separators',
          const _Live(
            label: 'Phone',
            mask: Masks.phoneUS,
            ghostMask: true,
            eager: true,
          ),
        ),
        DemoSection('More templates'),
        DemoVariant(
          'IPv4 address',
          const _Live(label: 'Host', mask: Masks.ipv4),
        ),
        DemoVariant(
          'Hex colour · literal # then 6 hex digits',
          const _Live(label: 'Accent', mask: Masks.hexColor),
        ),
        DemoVariant(
          'Letters + digits · licence "AAA-####"',
          const _Live(label: 'Plate', mask: 'AAA-####'),
        ),
        DemoSection('Seeded value — raw input reflows into the mask'),
        DemoVariant(
          'Pre-filled from "5551234567"',
          const _Live(
            label: 'Phone',
            mask: Masks.phoneUS,
            initial: '5551234567',
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged) — full contrast, selectable',
          const FieldShell(
            label: 'Phone',
            child: MaskedBody(mask: Masks.phoneUS, value: '5551234567'),
          ),
        ),
        DemoVariant(
          'Disabled',
          const FieldShell(
            label: 'Phone',
            enabled: false,
            child: MaskedBody(
              mask: Masks.phoneUS,
              value: '5551234567',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'No template hint',
          const _Live(label: 'Phone', mask: Masks.phoneUS, showTemplate: false),
        ),
        DemoVariant(
          'Draft override — amber',
          const FieldShell(
            label: 'Phone',
            modified: true,
            child: MaskedBody(
              mask: Masks.phoneUS,
              value: '5551234567',
              onChanged: _ignore,
            ),
          ),
        ),
        DemoVariant(
          'Validation error',
          const FieldShell(
            label: 'Card number',
            errorText: 'Enter all 16 digits.',
            child: MaskedBody(
              mask: Masks.creditCard,
              value: '424242',
              onChanged: _ignore,
            ),
          ),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final String mask;
  final String? initial;
  final bool showTemplate;
  final bool eager;
  final bool ghostMask;

  const _Live({
    required this.label,
    required this.mask,
    this.initial,
    this.showTemplate = true,
    this.eager = false,
    this.ghostMask = false,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String _value = widget.initial ?? '';

  @override
  Widget build(BuildContext context) {
    final raw = MaskFormatter.unmask(widget.mask, _value);
    return FieldShell(
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MaskedBody(
            mask: widget.mask,
            value: _value,
            showTemplate: widget.showTemplate,
            eager: widget.eager,
            ghostMask: widget.ghostMask,
            onChanged: (v) => setState(() => _value = v),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              raw.isEmpty ? 'raw: —' : 'raw: $raw',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.foregroundMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _ignore(String _) {}
