import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The status pill and dot over every [Severity] tone, plus the muted ones:
/// the tinted word-and-dot a status wears, and the bare dot beside a label.
class StatusPillDemo extends StatelessWidget {
  @Preview(name: 'Status pill', wrapper: adminUiPreview)
  const StatusPillDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    StatusMeta tone(Severity severity, String label) {
      final style = severityStyleOf(context, severity);
      return StatusMeta(label, style.accent, text: style.foreground);
    }

    final metas = [
      tone(Severity.info, 'Scheduled'),
      tone(Severity.success, 'Active'),
      tone(Severity.warning, 'Expiring soon'),
      tone(Severity.danger, 'Failed'),
      StatusMeta('Archived', c.foregroundMuted),
      StatusMeta('Not started', c.foregroundMuted, ring: true),
    ];
    return DemoPage(
      maxWidth: 560,
      children: [
        const DemoSection('Pill — one per tone'),
        Text(
          'A tone tints the pill and draws its dot; the word is held to 4.5:1 '
          'on the tint. A hollow ring marks a state that is not real yet.',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.lg),
        for (final meta in metas)
          _row(context, meta, StatusPill(meta), meta.ring ? 'ring' : 'filled'),
        const Gap(AdminSpacing.xl),

        const DemoSection('Dot'),
        Text(
          'The dot alone, beside a label that carries the word.',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.lg),
        for (final meta in metas)
          _row(
            context,
            meta,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusDot.of(meta),
                const Gap(AdminSpacing.sm),
                Text(meta.label, style: context.type.body),
              ],
            ),
            meta.ring ? 'ring' : 'filled',
          ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Dot on its own'),
        Text(
          'With no word beside it, the dot takes a semantic label, which '
          'assistive technology reads in place of the colour.',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.lg),
        Row(
          children: [
            StatusDot(
              color: severityStyleOf(context, Severity.success).accent,
              semanticLabel: 'Online',
            ),
            const Gap(AdminSpacing.md),
            StatusDot(
              color: c.foregroundMuted,
              ring: true,
              semanticLabel: 'Offline',
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, StatusMeta meta, Widget glyph, String how) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.md),
      child: Row(
        children: [
          // At least the column's width, and as wide as the glyph needs: a
          // longer label or a wider font grows it rather than clipping it.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: glyph,
            ),
          ),
          const Gap(AdminSpacing.md),
          Expanded(child: Text(how, style: context.type.bodyMuted)),
        ],
      ),
    );
  }
}
