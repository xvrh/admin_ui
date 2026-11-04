import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

const _statuses = [
  SelectOption(value: 'draft', label: 'Draft'),
  SelectOption(value: 'review', label: 'In review'),
];

const _countries = [
  ComboboxOption('be', 'Belgium'),
  ComboboxOption('fr', 'France'),
];

/// Every single-line field body in one form column: each is the theme's
/// medium control height, so the column reads as one rhythm and a row of
/// fields lines up whatever mix of types it holds.
class FieldHeightsDemo extends StatelessWidget {
  @Preview(name: 'Field heights (one column)', wrapper: adminUiPreview)
  const FieldHeightsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('At rest'),
        const _Column(),
        const Gap(AdminSpacing.xxxl),
        DemoSection('Focused — the border thickens, the text stays put'),
        const _Focused(),
        const Gap(AdminSpacing.xxxl),
        DemoSection('Hovered — a step stronger outline, nothing moves'),
        const _Hovered(),
        const Gap(AdminSpacing.xxxl),
        DemoSection('Invalid — the same column under a failed validation'),
        const FieldStateScope(invalid: true, child: _Column()),
        const Gap(AdminSpacing.xxxl),
        DemoSection('Read-only'),
        const _Column(readOnly: true),
        const Gap(AdminSpacing.xxxl),
        DemoSection('Disabled'),
        const FieldStateScope(enabled: false, child: _Column()),
        const Gap(AdminSpacing.xxxl),
        DemoSection('Add — each collection body adds with one small button'),
        const _Adds(),
        const Gap(AdminSpacing.xxxl),
        DemoSection('Add, hovered — the ghost button takes its fill'),
        const _Adds(hovered: true),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final bool readOnly;

  const _Column({this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    void text(String _) {}
    void number(num? _) {}
    final bodies = <(String, Widget)>[
      (
        'Text',
        TextBody(
          value: 'A coast that keeps',
          onChanged: readOnly ? null : text,
        ),
      ),
      (
        'Number',
        NumberBody(value: 24, unit: 'px', onChanged: readOnly ? null : number),
      ),
      (
        'Stepper',
        NumberBody(
          value: 8,
          appearance: NumberAppearance.stepper,
          onChanged: readOnly ? null : number,
        ),
      ),
      (
        'Masked',
        MaskedBody(
          mask: Masks.phoneUS,
          value: '5551234567',
          onChanged: readOnly ? null : text,
        ),
      ),
      (
        'Select',
        SelectBody(
          options: _statuses,
          value: 'draft',
          onChanged: readOnly ? null : text,
        ),
      ),
      (
        'Combobox',
        Combobox<String>(
          options: _countries,
          value: 'be',
          onChanged: readOnly ? null : (_) {},
        ),
      ),
      (
        'Date',
        DateBody(
          value: DateTime(2026, 6, 18),
          onChanged: readOnly ? null : (_) {},
        ),
      ),
      (
        'Colour',
        ColorBody(value: '#5B5BD6', onChanged: readOnly ? null : text),
      ),
      (
        'Tags',
        TagsBody(
          value: const ['featured'],
          onChanged: readOnly ? null : (_) {},
        ),
      ),
      (
        'Key → value',
        KeyValueBody(
          value: const {'region': 'eu'},
          onChanged: readOnly ? null : (_) {},
        ),
      ),
      (
        'Boolean',
        BooleanBody(
          value: true,
          description: 'Visible',
          onChanged: readOnly ? null : (_) {},
        ),
      ),
    ];
    return _Rows(bodies);
  }
}

/// The single-line bodies with the pointer resting on each: the outline
/// steps up alike on every type.
class _Hovered extends StatelessWidget {
  const _Hovered();

  @override
  Widget build(BuildContext context) {
    void text(String _) {}
    return _Rows([
      ('Text', TextBody(value: 'A coast that keeps', onChanged: text)),
      ('Number', NumberBody(value: 24, unit: 'px', onChanged: (_) {})),
      (
        'Select',
        SelectBody(options: _statuses, value: 'draft', onChanged: text),
      ),
      (
        'Combobox',
        Combobox<String>(options: _countries, value: 'be', onChanged: (_) {}),
      ),
      ('Date', DateBody(value: DateTime(2026, 6, 18), onChanged: (_) {})),
      ('Colour', ColorBody(value: '#5B5BD6', onChanged: text)),
    ], hovered: true);
  }
}

/// A text body holding real focus, beside one at rest: the thicker focus
/// border is taken from the padding, so the text does not move. Empty, so a
/// touch platform's selection handle does not show.
class _Focused extends StatefulWidget {
  const _Focused();

  @override
  State<_Focused> createState() => _FocusedState();
}

class _FocusedState extends State<_Focused> {
  final _focus = FocusNode(debugLabel: 'Field heights · focused');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void text(String _) {}
    return _Rows([
      (
        'Focused',
        TextBody(
          value: '',
          hint: 'Untitled',
          onChanged: text,
          focusNode: _focus,
        ),
      ),
      ('At rest', TextBody(value: '', hint: 'Untitled', onChanged: text)),
    ]);
  }
}

/// The empty collection bodies, down to their add buttons: the same small
/// ghost button, at the small control height, in each. [hovered] rests a
/// pointer on each button.
class _Adds extends StatelessWidget {
  final bool hovered;

  const _Adds({this.hovered = false});

  @override
  Widget build(BuildContext context) {
    Widget pin(Widget body) =>
        hovered ? PinnedHover(target: (w) => w is Button, child: body) : body;
    return _Rows([
      ('Key → value', pin(KeyValueBody(value: const {}, onChanged: (_) {}))),
      (
        'Repeater',
        pin(
          Repeater(
            itemCount: 0,
            itemBuilder: (_, _) => const SizedBox.shrink(),
            emptyState: const SizedBox.shrink(),
            onAdd: () {},
          ),
        ),
      ),
      (
        'Reference',
        pin(
          ReferenceBody<String, String>(
            value: const [],
            onChanged: (_) {},
            idOf: (id) => id,
            resolve: (ids) async => [...ids],
            search: (query, {cursor}) async => const ReferencePage([]),
            tile: (context, id) => ReferenceTileCard(title: id),
          ),
        ),
      ),
    ]);
  }
}

/// [bodies] beside their labels, one form column; [hovered] rests a pointer
/// on each body.
class _Rows extends StatelessWidget {
  final List<(String, Widget)> bodies;
  final bool hovered;

  const _Rows(this.bodies, {this.hovered = false});

  @override
  Widget build(BuildContext context) {
    final style = context.type.caption.copyWith(
      color: context.colors.foregroundMuted,
    );
    final width = _labelWidth(context, style);
    // Each label on its control's first line of text, like a form's side
    // labels: on the baseline, which holds when a body grows (key → value)
    // and when a large text size grows the control.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (label, body)) in bodies.indexed) ...[
          if (i > 0) const Gap(AdminSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: width,
                child: Text(label, style: style),
              ),
              Expanded(child: hovered ? PinnedHover(child: body) : body),
            ],
          ),
        ],
      ],
    );
  }
}

/// Every label a row shows, in every section.
const _labels = [
  'Text',
  'Number',
  'Stepper',
  'Masked',
  'Select',
  'Combobox',
  'Date',
  'Colour',
  'Tags',
  'Key → value',
  'Boolean',
  'Focused',
  'At rest',
  'Repeater',
  'Reference',
];

/// The label column's width: 88, or the widest label and a gap at a text
/// size where that is more, so no label breaks and every section's fields
/// start at the same x.
double _labelWidth(BuildContext context, TextStyle style) {
  var widest = 0.0;
  for (final label in _labels) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }
  return math.max(88, (widest + AdminSpacing.lg).ceilToDouble());
}
