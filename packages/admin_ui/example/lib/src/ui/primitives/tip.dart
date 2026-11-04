import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Tooltips on hover and on keyboard focus. A pinned block shows a chip on
/// each side of its trigger, and one with a shortcut, with the theme's
/// arrow. The long message's trigger holds real keyboard focus, with the
/// keyboard highlight forced on while this page is up, so a static render
/// shows the open chip wrapping at the theme's maximum width.
class TipDemo extends StatefulWidget {
  @Preview(name: 'Tooltip', wrapper: adminUiPreview)
  const TipDemo({super.key});

  @override
  State<TipDemo> createState() => _TipDemoState();
}

class _TipDemoState extends State<TipDemo> {
  final _focused = FocusNode(debugLabel: 'Tip demo focused trigger');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focused.requestFocus();
    });
  }

  @override
  void dispose() {
    _focused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = context.overlayStyle.tooltipMaxWidth.round();
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 560,
        children: [
          const DemoSection('Hover or focus to reveal'),
          Text(
            'The chip styling comes from the theme’s tooltipTheme, so a bare '
            'Material Tooltip gets the same chip, without the arrow. A Tip '
            'also opens while keyboard focus is inside its child, and Escape '
            'closes it.',
            style: context.type.bodyMuted,
          ),
          const Gap(AdminSpacing.xl),
          Wrap(
            spacing: AdminSpacing.lg,
            runSpacing: AdminSpacing.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tip(
                message: 'Settings',
                child: Icon(
                  Icons.settings_outlined,
                  color: context.colors.foregroundMuted,
                ),
              ),
              Tip(
                message: 'Edit this item',
                child: Button.ghost(
                  'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: () {},
                ),
              ),
              const Tip(
                message: 'Status of the current draft',
                child: Tag('Draft', severity: Severity.warning),
              ),
            ],
          ),
          const Gap(AdminSpacing.xxl),

          const DemoSection('Sides and a shortcut — pinned open'),
          Text(
            'A Tip opens on any side of its trigger and flips where that side '
            'has no room. shadcn, Ant, Fluent and Carbon point at the trigger '
            'with an arrow; Iris and Material keep a plain chip.',
            style: context.type.bodyMuted,
          ),
          const _PinnedTips(child: _Sides()),

          const DemoSection('Long message — opened by focus'),
          Text(
            'It wraps at the theme’s $maxWidth px.',
            style: context.type.bodyMuted,
          ),
          const Gap(AdminSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Tip(
              message:
                  'Scheduled pages go live at the time you pick, in the '
                  'workspace time zone. You can still edit them until then; '
                  'changes are published with them.',
              child: IconAction(
                Icons.schedule_rounded,
                label: 'Schedule',
                tooltip: false,
                focusNode: _focused,
                onPressed: () {},
              ),
            ),
          ),
          // Room below the trigger for the chip at its narrowest wrap,
          // Material's 200px: five lines, clear of the next title.
          const Gap(AdminSpacing.xxl * 6),

          const DemoSection('Bare Material Tooltip — themed too'),
          const Tooltip(
            message: 'I am a plain Tooltip, styled by the theme',
            child: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}

/// A trigger for each side, each chip pointing into the middle of the
/// block, and a save action whose chip carries its shortcut.
class _Sides extends StatelessWidget {
  const _Sides();

  /// Narrower than this, the end and start triggers take a line each, so
  /// their chips, which open toward each other, do not meet.
  static const _besideWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final after = Tip(
      message: 'Opens after',
      side: PopoverSide.end,
      child: Button('End', onPressed: () {}),
    );
    final before = Tip(
      message: 'Opens before',
      side: PopoverSide.start,
      child: Button('Start', onPressed: () {}),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxxl + 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tip(
                message: 'Opens above',
                side: PopoverSide.top,
                child: Button('Top', onPressed: () {}),
              ),
              Tip(
                message: 'Opens below',
                child: Button('Bottom', onPressed: () {}),
              ),
              Tip(
                message: 'Save',
                shortcut: '⌘S',
                child: IconAction(
                  Icons.save_outlined,
                  label: 'Save',
                  tooltip: false,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const Gap(AdminSpacing.xxxl + 16),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= _besideWidth
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [after, before],
                  )
                : Column(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: after,
                      ),
                      const Gap(AdminSpacing.xl),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: before,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Opens every tooltip below it once it has laid out, so a static render
/// shows them all.
class _PinnedTips extends StatefulWidget {
  final Widget child;

  const _PinnedTips({required this.child});

  @override
  State<_PinnedTips> createState() => _PinnedTipsState();
}

class _PinnedTipsState extends State<_PinnedTips> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void open(Element element) {
        if (element case StatefulElement(:final TooltipState state)) {
          state.ensureTooltipVisible();
        }
        element.visitChildren(open);
      }

      (context as Element).visitChildren(open);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
