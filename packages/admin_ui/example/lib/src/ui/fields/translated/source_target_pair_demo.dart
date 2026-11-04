import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// The source → target compare layout: a read-only source beside the editor
/// it is compared with, and the slots a workflow builds on.
class SourceTargetPairDemo extends StatelessWidget {
  @Preview(name: 'Source-target pair', wrapper: adminUiPreview)
  const SourceTargetPairDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DemoPage(
      maxWidth: 780,
      children: [
        const DemoSection('Source'),
        const DemoVariant(
          'text source',
          FieldShell(
            label: 'Title',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'fr',
              sourceText: 'Opening hours and directions',
              target: _Editor(value: 'Horaires et accès'),
            ),
          ),
        ),
        const DemoVariant(
          'rich source — the caller renders it',
          FieldShell(
            label: 'Body',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'fr',
              source: _RichSource(),
              target: _Editor(hint: 'Write the French text…'),
            ),
          ),
        ),
        const DemoVariant(
          'no source yet — a dash',
          FieldShell(
            label: 'Subtitle',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'de',
              target: _Editor(hint: 'Untertitel…'),
            ),
          ),
        ),
        const DemoVariant(
          'right-to-left target',
          FieldShell(
            label: 'Title',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'ar',
              sourceText: 'Opening hours and directions',
              target: _Editor(value: 'ساعات العمل والاتجاهات'),
            ),
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Slots'),
        const DemoVariant(
          'target badge — notched top-end',
          FieldShell(
            label: 'Title',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'fr',
              sourceText: 'Opening hours and directions',
              targetBadge: LocaleStatusPill(status: LocaleStatus.outdated),
              target: _Editor(value: 'Horaires'),
            ),
          ),
        ),
        DemoVariant(
          'target tint — a status colour in place of the chrome',
          FieldShell(
            label: 'Caption',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'fr',
              sourceText: 'Free entry on the first Sunday of the month.',
              targetTint: c.info,
              targetBadge: const LocaleStatusPill(status: LocaleStatus.review),
              target: const _Editor(
                value: 'Entrée libre le premier dimanche du mois.',
              ),
            ),
          ),
        ),
        DemoVariant(
          'target trailing and footer',
          FieldShell(
            label: 'Title',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'fr',
              sourceText: 'Opening hours and directions',
              targetTrailing: Button(
                'Copy source',
                icon: Icons.content_copy_rounded,
                size: ControlSize.small,
                onPressed: () {},
              ),
              footer: Text(
                'The source changed after this was written.',
                style: context.type.caption.copyWith(color: c.foregroundMuted),
              ),
              target: const _Editor(hint: 'Write the French title…'),
            ),
          ),
        ),
      ],
    );
  }
}

/// The pair in a 360px column — a phone, a split pane: the lanes stack, the
/// target under its source.
class SourceTargetPairNarrowDemo extends StatelessWidget {
  @Preview(
    name: 'Source-target pair — narrow (360 px)',
    wrapper: adminUiPreview,
  )
  const SourceTargetPairNarrowDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPage(
      maxWidth: 360 + 64,
      children: [
        DemoVariant(
          'stacked below stackBelow',
          FieldShell(
            label: 'Title',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'fr',
              sourceText: 'Opening hours and directions',
              targetBadge: LocaleStatusPill(status: LocaleStatus.translated),
              target: _Editor(value: 'Horaires et accès'),
            ),
          ),
        ),
        DemoVariant(
          'right-to-left target',
          FieldShell(
            label: 'Title',
            child: SourceTargetPair(
              sourceLocale: 'en',
              targetLocale: 'ar',
              sourceText: 'Opening hours and directions',
              target: _Editor(value: 'ساعات العمل والاتجاهات'),
            ),
          ),
        ),
      ],
    );
  }
}

/// A chrome-less text editor, as the pair expects: the lane owns the border,
/// and the kit's field text keeps it on the source's type.
class _Editor extends StatelessWidget {
  final String? value;
  final String? hint;

  const _Editor({this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      maxLines: null,
      style: fieldTextStyle(context),
      decoration: fieldInputDecoration(context, hint: hint),
    );
  }
}

class _RichSource extends StatelessWidget {
  const _RichSource();

  @override
  Widget build(BuildContext context) {
    final body = fieldTextStyle(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visiting', style: body.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'The reading room opens at nine. Bring a card; the desk can '
          'issue one on the day.',
          style: body,
        ),
      ],
    );
  }
}
