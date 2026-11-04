import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// A card of detail that opens while the pointer rests on a reference: a
/// person's card below a mention, and a record's card beside a reference
/// chip at the end edge, opening toward the start with an arrow. Both are
/// pinned open, so a static render shows them.
class HoverCardDemo extends StatelessWidget {
  @Preview(name: 'Hover card', wrapper: adminUiPreview)
  const HoverCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = context.type.bodyMuted;
    return DemoPage(
      maxWidth: 560,
      children: [
        const DemoSection('Hover a reference'),
        Text(
          'A hover card previews what a mention or a reference leads to. It '
          'opens once the pointer rests on it, or at once on keyboard focus, '
          'and never on touch — so what it shows is reachable through the '
          'link too.',
          style: muted,
        ),
        const Gap(AdminSpacing.xl),
        PinnedOpen(
          makeRoom: true,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Assigned to ', style: context.type.body),
              HoverCard(
                content: (context) => const _Person(),
                child: TextLink('@Jordan Ellis', onPressed: () {}),
              ),
              Text(' for review.', style: context.type.body),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Toward the start, with an arrow'),
        Text(
          'Beside a reference at the end edge, the card opens on its start '
          'side and points back at it.',
          style: muted,
        ),
        const Gap(AdminSpacing.xxxl * 2),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PinnedOpen(
            child: HoverCard(
              side: PopoverSide.start,
              showArrow: true,
              width: 280,
              content: (context) => const _Record(),
              child: RelationChip(
                label: 'Spring catalogue',
                color: context.colors.info,
                onTap: () {},
              ),
            ),
          ),
        ),
        const Gap(AdminSpacing.xxxl * 2),
      ],
    );
  }
}

/// A person: avatar, name and role, a two-line bio, and when they joined.
class _Person extends StatelessWidget {
  const _Person();

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Avatar(name: 'Jordan Ellis', size: 40),
        const Gap(AdminSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jordan Ellis', style: type.bodyStrong),
              Text(
                '@jordan · Editor',
                style: type.caption.copyWith(color: colors.foregroundMuted),
              ),
              const Gap(AdminSpacing.sm),
              Text(
                'Writes the product pages and keeps the spring catalogue on '
                'schedule.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: type.bodySmall.copyWith(
                  color: colors.foregroundSecondary,
                ),
              ),
              const Gap(AdminSpacing.md),
              _Meta(
                icon: Icons.calendar_today_outlined,
                label: 'Joined March 2024',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A record: its title and status, what it is, and when it last changed.
class _Record extends StatelessWidget {
  const _Record();

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Spring catalogue', style: type.bodyStrong)),
            const Tag('In review', severity: Severity.info),
          ],
        ),
        const Gap(AdminSpacing.sm),
        Text(
          'Twelve product pages for the spring range, due before the launch.',
          style: type.bodySmall.copyWith(
            color: context.colors.foregroundSecondary,
          ),
        ),
        const Gap(AdminSpacing.md),
        _Meta(icon: Icons.schedule_rounded, label: 'Updated 2 days ago'),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.foregroundMuted;
    return Row(
      children: [
        Icon(icon, size: context.iconSizes.sm, color: muted),
        const Gap(AdminSpacing.xs),
        Text(label, style: context.type.caption.copyWith(color: muted)),
      ],
    );
  }
}
