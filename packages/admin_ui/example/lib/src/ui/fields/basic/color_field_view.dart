import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

const _brand = [
  '#5B5BD6',
  '#4A4AC4',
  '#0F9D8F',
  '#2F9E63',
  '#CF8A00',
  '#D24B3E',
  '#9333A8',
  '#15181D',
  '#6B7280',
  '#FFFFFF',
];

const _comments = [
  CommentEntry(
    author: 'Marina Cole',
    initials: 'MC',
    color: Color(0xFF9333a8),
    time: '3m',
    body: 'Can we use the brand indigo here rather than the red?',
  ),
];

const _versions = [
  FieldVersion(
    label: 'Editing now',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'just now',
    current: true,
  ),
  FieldVersion(
    label: 'Published',
    author: 'Diego Ruiz',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '5d ago',
  ),
];

/// The colour field across states.
class ColorFieldDemo extends StatelessWidget {
  @Preview(name: 'Color', wrapper: adminUiPreview)
  const ColorFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Picker — palette + hex'),
        DemoVariant(
          'Open — white selected, so the check must read on #FFFFFF',
          const PinnedOpen(
            reserve: 180,
            child: FieldShell(
              label: 'Background',
              child: ColorBody(value: '#FFFFFF', onChanged: _ignore),
            ),
          ),
        ),
        DemoVariant(
          'Live — tap the swatch, pick or type a hex',
          const _Live(label: 'Accent', initial: '#5B5BD6'),
        ),
        DemoVariant(
          'Empty — nothing chosen',
          const _Live(label: 'Accent', hint: 'Pick an accent'),
        ),
        DemoVariant(
          'Custom hex value (off the palette)',
          const _Live(label: 'Background', initial: '#FAF3E0'),
        ),
        DemoVariant(
          'Brand palette, hex input off',
          const _Live(
            label: 'Label colour',
            initial: '#0F9D8F',
            palette: _brand,
            allowCustomHex: false,
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged) — full contrast, no chevron',
          const FieldShell(
            label: 'Accent',
            child: ColorBody(value: '#D24B3E'),
          ),
        ),
        DemoVariant(
          'Disabled',
          const FieldShell(
            label: 'Accent',
            enabled: false,
            child: ColorBody(value: '#D24B3E', onChanged: _ignore),
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          const FieldShell(
            label: 'Accent',
            modified: true,
            child: ColorBody(value: '#9333A8', onChanged: _ignore),
          ),
        ),
        DemoVariant(
          'Validation error',
          const FieldShell(
            label: 'Accent',
            errorText: 'An accent colour is required before publishing.',
            child: ColorBody(hint: 'Pick an accent', onChanged: _ignore),
          ),
        ),
        DemoSection('All capabilities — help · comments · history'),
        DemoVariant(
          'Picking a colour drives the draft and "Modified" tint',
          const _FullyLoaded(),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final String? initial;
  final String? hint;
  final List<String>? palette;
  final bool allowCustomHex;

  const _Live({
    required this.label,
    this.initial,
    this.hint,
    this.palette,
    this.allowCustomHex = true,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    var palette = widget.palette;
    var hint = widget.hint;
    void onChanged(String v) => setState(() => _value = v);
    return FieldShell(
      label: widget.label,
      child: palette != null
          ? ColorBody(
              value: _value,
              palette: palette,
              allowCustomHex: widget.allowCustomHex,
              onChanged: onChanged,
            )
          : hint != null
          ? ColorBody(
              value: _value,
              hint: hint,
              allowCustomHex: widget.allowCustomHex,
              onChanged: onChanged,
            )
          : ColorBody(
              value: _value,
              allowCustomHex: widget.allowCustomHex,
              onChanged: onChanged,
            ),
    );
  }
}

class _FullyLoaded extends StatefulWidget {
  const _FullyLoaded();

  @override
  State<_FullyLoaded> createState() => _FullyLoadedState();
}

class _FullyLoadedState extends State<_FullyLoaded> {
  static const _published = '#5B5BD6';
  String _value = '#5B5BD6';
  final List<CommentEntry> _messages = [..._comments];

  @override
  Widget build(BuildContext context) {
    var modified = _value.toUpperCase() != _published;
    return FieldShell(
      label: 'Accent',
      modified: modified,
      help: const HelpButton(
        text:
            'Tints buttons and links on this entry. Falls back to the theme '
            'accent when unset.',
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: _value.toUpperCase(),
        baseline: _published,
        versions: _versions,
        onRevert: () => setState(() => _value = _published),
      ),
      child: ColorBody(
        value: _value,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

void _ignore(String _) {}
