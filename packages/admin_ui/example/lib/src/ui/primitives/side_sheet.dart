import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class SideSheetDemo extends StatelessWidget {
  @Preview(name: 'Side sheet', wrapper: adminUiPreview)
  const SideSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Edit in context — end edge, with footer actions'),
        DemoRow(
          'A form sheet with a pinned Cancel / Save footer.',
          Button(
            'Open',
            icon: Icons.edit_outlined,
            onPressed: () => _editSheet(context),
          ),
        ),

        const DemoSection('Filters — start edge'),
        DemoRow(
          'From the start edge; tap the scrim or press Esc to close.',
          Button(
            'Open',
            icon: Icons.filter_list_rounded,
            onPressed: () => _filtersSheet(context),
          ),
        ),

        const DemoSection('Long content — body scrolls under a pinned header'),
        DemoRow(
          'A threaded list, header stays put.',
          Button(
            'Open',
            icon: Icons.forum_outlined,
            onPressed: () => _commentsSheet(context),
          ),
        ),

        const DemoSection('No header — bare panel'),
        DemoRow(
          'No title row; content owns the whole sheet.',
          Button('Open', onPressed: () => _bareSheet(context)),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Surface (inline preview)'),
        Text(
          'The sheet over the scrimmed page, as showSideSheet stacks them. The '
          'scrim dims the page in both modes; the sheet keeps a hairline along '
          'its inner edge.',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.lg),
        const _InlineSheet(),
      ],
    );
  }

  void _editSheet(BuildContext context) {
    showSideSheet(
      context,
      builder: (context) => SideSheet(
        title: 'Edit details',
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Button.ghost('Cancel', onPressed: () => Navigator.pop(context)),
            const Gap(AdminSpacing.sm),
            Button.primary('Save', onPressed: () => Navigator.pop(context)),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          children: const [
            FieldGroup(
              title: 'Content',
              children: [
                FieldShell(
                  label: 'Title',
                  child: TextBody(hint: 'About us'),
                ),
                FieldShell(
                  label: 'Slug',
                  child: TextBody(hint: 'about-us'),
                ),
                FieldShell(
                  label: 'Summary',
                  child: TextBody(hint: 'A short description'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _filtersSheet(BuildContext context) {
    showSideSheet(
      context,
      side: SideSheetSide.start,
      width: 320,
      builder: (context) => SideSheet(
        title: 'Filters',
        side: SideSheetSide.start,
        child: ListView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          children: const [
            FieldShell(
              label: 'Status',
              child: TextBody(hint: 'Any'),
            ),
            Gap(AdminSpacing.lg),
            FieldShell(
              label: 'Author',
              child: TextBody(hint: 'Anyone'),
            ),
            Gap(AdminSpacing.lg),
            FieldShell(
              label: 'Updated',
              child: TextBody(hint: 'Any time'),
            ),
          ],
        ),
      ),
    );
  }

  void _commentsSheet(BuildContext context) {
    showSideSheet(
      context,
      builder: (context) => SideSheet(
        title: 'Comments',
        actions: [const Tag('4 open', severity: Severity.info)],
        child: ListView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          children: [
            for (var i = 0; i < 12; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
                child: Panel(
                  padding: const EdgeInsets.all(AdminSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reviewer ${i + 1}', style: context.type.bodyStrong),
                      const Gap(AdminSpacing.xs),
                      Text(
                        'A note on this section that may run a little long so '
                        'the body has something to scroll.',
                        style: context.type.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _bareSheet(BuildContext context) {
    showSideSheet(
      context,
      width: 360,
      builder: (context) => SideSheet(
        child: Center(
          child: Button.ghost('Close', onPressed: () => Navigator.pop(context)),
        ),
      ),
    );
  }
}

/// A page, the scrim and a docked [SideSheet], painted in place so the preview
/// shows what a live sheet looks like without opening a route.
class _InlineSheet extends StatelessWidget {
  const _InlineSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // In the page, clear of the screen's edges and their insets.
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeTop: true,
      removeRight: true,
      removeBottom: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        child: SizedBox(
          height: 320,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: colors.background)),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(AdminSpacing.xl),
                  child: Panel(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About us', style: context.type.heading),
                        const Gap(AdminSpacing.xs),
                        Text(
                          'The page under the sheet: a card on the canvas.',
                          style: context.type.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: ColoredBox(color: colors.scrim)),
              PositionedDirectional(
                top: 0,
                end: 0,
                bottom: 0,
                width: 300,
                child: SideSheet(
                  title: 'Edit details',
                  onDismiss: () {},
                  footer: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button.ghost('Cancel', onPressed: () {}),
                      const Gap(AdminSpacing.sm),
                      Button.primary('Save', onPressed: () {}),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(AdminSpacing.xl),
                    children: const [
                      FieldShell(
                        label: 'Title',
                        child: TextBody(hint: 'About us'),
                      ),
                      Gap(AdminSpacing.lg),
                      FieldShell(
                        label: 'Slug',
                        child: TextBody(hint: 'about-us'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
