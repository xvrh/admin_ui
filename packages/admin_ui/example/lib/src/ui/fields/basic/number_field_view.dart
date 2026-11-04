import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

const _comments = [
  CommentEntry(
    author: 'Lena Fritz',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '5m',
    body: 'Is 12 the right cap, or should premium tiers go higher?',
  ),
];

const _versions = [
  FieldVersion(
    label: '8',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'just now',
    current: true,
  ),
  FieldVersion(
    label: '12',
    author: 'Diego Ruiz',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '1d ago',
  ),
];

/// The numeric field across appearances and states.
class NumberFieldDemo extends StatelessWidget {
  @Preview(name: 'Number', wrapper: adminUiPreview)
  const NumberFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Plain input'),
        DemoVariant(
          'Live — integer',
          const _Live(label: 'Items per page', initial: 24),
        ),
        DemoVariant(
          'Empty — placeholder',
          const _Live(label: 'Reading time', hint: 'Auto', unit: 'min'),
        ),
        DemoVariant(
          'Unit suffix',
          const _Live(label: 'Hero height', initial: 480, unit: 'px', step: 10),
        ),
        DemoVariant(
          'Currency prefix · 2 decimals',
          const _Live(
            label: 'Price',
            initial: 19.99,
            prefix: r'$ ',
            decimals: 2,
            step: 0.5,
          ),
        ),
        DemoSection('Range — typed values are checked, and clamped on blur'),
        DemoVariant(
          'Max 1200 — type 1400: red while typing, 1200 on blur',
          const _Live(
            label: 'Hero height',
            initial: 1400,
            unit: 'px',
            min: 0,
            max: 1200,
            step: 10,
          ),
        ),
        DemoVariant(
          'Negatives allowed — min −40: the minus sign leads',
          const _Live(
            label: 'Temperature offset',
            initial: -12,
            unit: '°C',
            min: -40,
            max: 40,
          ),
        ),
        DemoVariant(
          'No negatives — min 0: the minus key does nothing',
          const _Live(label: 'Retries', initial: 3, min: 0),
        ),
        DemoSection('Stepper — nudge by step, clamped to range'),
        DemoVariant(
          'Live — 0…12',
          const _Live(
            label: 'Featured slots',
            initial: 8,
            appearance: NumberAppearance.stepper,
            min: 0,
            max: 12,
          ),
        ),
        DemoSection('Slider — bounded range with a readout'),
        DemoVariant(
          'Live — 0…100 %',
          const _Live(
            label: 'Opacity',
            initial: 60,
            appearance: NumberAppearance.slider,
            min: 0,
            max: 100,
            step: 5,
            unit: '%',
          ),
        ),
        DemoVariant(
          'Decimals — quality 1.0…5.0',
          const _Live(
            label: 'Min. rating',
            initial: 3.5,
            appearance: NumberAppearance.slider,
            min: 1,
            max: 5,
            step: 0.5,
            decimals: 1,
          ),
        ),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only (no onChanged) — full contrast, no steppers',
          const FieldShell(
            label: 'Word count',
            child: NumberBody(
              value: 842,
              unit: 'words',
              appearance: NumberAppearance.stepper,
            ),
          ),
        ),
        DemoVariant(
          'Disabled',
          FieldShell(
            label: 'Word count',
            enabled: false,
            child: NumberBody(
              value: 842,
              unit: 'words',
              appearance: NumberAppearance.stepper,
              onChanged: (_) {},
            ),
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          FieldShell(
            label: 'Featured slots',
            modified: true,
            child: NumberBody(
              value: 8,
              appearance: NumberAppearance.stepper,
              min: 0,
              max: 12,
              onChanged: (_) {},
            ),
          ),
        ),
        DemoVariant(
          'Out of range — warning',
          FieldShell(
            label: 'Hero height',
            warning: 'Above the 1200px recommended maximum.',
            child: NumberBody(value: 1400, unit: 'px', onChanged: (_) {}),
          ),
        ),
        DemoVariant(
          'Validation error',
          FieldShell(
            label: 'Price',
            errorText: 'Price cannot be negative.',
            child: NumberBody(
              value: -5,
              prefix: r'$ ',
              decimals: 2,
              onChanged: (_) {},
            ),
          ),
        ),
        DemoSection('All capabilities — help · comments · history'),
        DemoVariant(
          'Step the value — it drives the draft and "Modified" tint',
          const _FullyLoaded(),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final num? initial;
  final String? hint;
  final NumberAppearance appearance;
  final num? min;
  final num? max;
  final num step;
  final int decimals;
  final String? prefix;
  final String? unit;

  const _Live({
    required this.label,
    this.initial,
    this.hint,
    this.appearance = NumberAppearance.plain,
    this.min,
    this.max,
    this.step = 1,
    this.decimals = 0,
    this.prefix,
    this.unit,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late num? _value = widget.initial;
  String? _invalid;

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      errorText: _invalid,
      child: NumberBody(
        value: _value,
        hint: widget.hint,
        onInvalid: (message) => setState(() => _invalid = message),
        appearance: widget.appearance,
        min: widget.min,
        max: widget.max,
        step: widget.step,
        decimals: widget.decimals,
        prefix: widget.prefix,
        unit: widget.unit,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

/// One field wired with every capability slot. Stepping the value updates the
/// draft, flipping the history chip to "Modified" and tinting the field until
/// reverted.
class _FullyLoaded extends StatefulWidget {
  const _FullyLoaded();

  @override
  State<_FullyLoaded> createState() => _FullyLoadedState();
}

class _FullyLoadedState extends State<_FullyLoaded> {
  static const num _published = 12;
  num? _value = 8;
  final List<CommentEntry> _messages = [..._comments];

  @override
  Widget build(BuildContext context) {
    var modified = _value != _published;
    return FieldShell(
      label: 'Featured slots',
      modified: modified,
      help: const HelpButton(
        text:
            'How many stories fill the featured strip on the section front. '
            'Beyond 12 the strip starts a second row.',
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: '${_value ?? '—'}',
        baseline: '$_published',
        versions: _versions,
        onRevert: () => setState(() => _value = _published),
      ),
      child: NumberBody(
        value: _value,
        appearance: NumberAppearance.stepper,
        min: 0,
        max: 12,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}
