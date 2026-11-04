import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Popover placement: the four corners' triggers, a trigger at the bottom
/// edge that flips above, and a pinned grid of every side and alignment with
/// an arrow, beside a start-side popover whose trigger sits at the start
/// edge and so opens on the end side.
class PopoverDemo extends StatelessWidget {
  @Preview(name: 'Popover', wrapper: adminUiPreview)
  const PopoverDemo({super.key});

  /// Above the bottom row, room kept for the card "Below · flips" opens
  /// into, so it never covers the grid.
  static const _flipRoom = 168.0;

  @override
  Widget build(BuildContext context) {
    // The bottom row stays on the window's bottom edge while everything
    // fits; a shorter window scrolls instead, the row below the grid.
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outside-tap and Esc both dismiss — Esc also after a '
                    'click, wherever focus is, and focus returns to the '
                    'trigger. Re-tap toggles. "Below · flips" asks for the '
                    'bottom side, finds no room there and opens above; '
                    '"Start · flips" asks for the start side at the start '
                    'edge and opens on the end. The grid shows every side '
                    'and alignment, with an arrow.',
                    style: TextStyle(color: context.colors.foregroundMuted),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Trigger(
                        label: 'Below · start',
                        side: PopoverSide.bottom,
                        align: PopoverAlign.start,
                      ),
                      _Trigger(
                        label: 'Below · end',
                        side: PopoverSide.bottom,
                        align: PopoverAlign.end,
                      ),
                    ],
                  ),
                  const _PlacementGrid(),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, _flipRoom, 40, 40),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Trigger(
                      label: 'Above · start',
                      side: PopoverSide.top,
                      align: PopoverAlign.start,
                      child: const _ReplyBox(),
                    ),
                    const PinnedOpen(
                      child: _Trigger(
                        label: 'Below · flips',
                        side: PopoverSide.bottom,
                        align: PopoverAlign.start,
                      ),
                    ),
                    _Trigger(
                      label: 'Above · end',
                      side: PopoverSide.top,
                      align: PopoverAlign.end,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Trigger extends StatelessWidget {
  final String label;
  final PopoverSide side;
  final PopoverAlign align;
  final Widget? child;

  const _Trigger({
    required this.label,
    required this.side,
    required this.align,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Popover(
      side: side,
      align: align,
      anchor: (context, controller) =>
          Button(label, onPressed: controller.toggle),
      content: (context, controller) => child ?? const _Card(),
    );
  }
}

/// Every side and alignment, open with an arrow: above and below, then
/// beside, with the start side's trigger at the start edge flipped to the
/// end. Each trigger stands in a cell with room for its card, and the cells
/// wrap onto more lines in a narrow window, so no two cards meet.
class _PlacementGrid extends StatelessWidget {
  const _PlacementGrid();

  static const _aligns = PopoverAlign.values;

  /// Across the trigger, a card and its standoff from it: the arrow and the
  /// gap.
  static const _cardRoom = _PlacementCard.width + 16;

  /// Above or below a small trigger, the room a card opened there takes,
  /// with its arrow and gap, in the theme with the tallest lines.
  static const _cardDepth = 88.0;

  /// Above and below a trigger with a card beside it: the most a card lined
  /// up with one of its edges reaches past the other.
  static const _besideDepth = AdminSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    // A card above or below its trigger, in a cell as wide as the card:
    // lined up with the trigger's start or end edge, or centred on it.
    Widget stacked(PopoverSide side, {bool both = false}) => Padding(
      padding: EdgeInsets.only(
        top: both || side == PopoverSide.top ? _cardDepth : 0,
        bottom: both || side == PopoverSide.bottom ? _cardDepth : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final align in _aligns)
            SizedBox(
              width: _cardRoom,
              child: Align(
                alignment: switch (align) {
                  PopoverAlign.start => AlignmentDirectional.centerStart,
                  PopoverAlign.center => Alignment.center,
                  PopoverAlign.end => AlignmentDirectional.centerEnd,
                },
                child: _Pinned(side: side, align: align),
              ),
            ),
        ],
      ),
    );

    // A card beside its trigger, in a cell as wide as both: the room for the
    // card on the side it ends up on, whatever the trigger's width.
    Widget beside(PopoverSide side, PopoverAlign align, {String? label}) {
      const room = SizedBox(width: _cardRoom);
      final pinned = _Pinned(side: side, align: align, label: label);
      // Asked for the start side at the start edge, it opens on the end.
      final opensAtStart = side == PopoverSide.start && label == null;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: _besideDepth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: opensAtStart ? [room, pinned] : [pinned, room],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // On one line where they fit, their triggers level; else the top
        // ones over the bottom ones, with no room kept that no card takes.
        LayoutBuilder(
          builder: (context, box) =>
              box.maxWidth >= 6 * _cardRoom + AdminSpacing.xxl
              ? Row(
                  children: [
                    stacked(PopoverSide.top, both: true),
                    const Gap(AdminSpacing.xxl),
                    stacked(PopoverSide.bottom, both: true),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stacked(PopoverSide.top),
                    const Gap(AdminSpacing.xxl),
                    stacked(PopoverSide.bottom),
                  ],
                ),
        ),
        Wrap(
          spacing: AdminSpacing.xxl,
          children: [
            beside(
              PopoverSide.start,
              PopoverAlign.start,
              label: 'Start · flips',
            ),
            for (final align in _aligns) beside(PopoverSide.start, align),
          ],
        ),
        Wrap(
          spacing: AdminSpacing.xxl,
          children: [
            for (final align in _aligns) beside(PopoverSide.end, align),
          ],
        ),
      ],
    );
  }
}

/// A trigger pinned open on [side], lined up by [align], with an arrow; its
/// card names where the popover ended up.
class _Pinned extends StatelessWidget {
  final PopoverSide side;
  final PopoverAlign align;
  final String? label;

  const _Pinned({required this.side, required this.align, this.label});

  @override
  Widget build(BuildContext context) {
    return PinnedOpen(
      child: Popover(
        side: side,
        align: align,
        showArrow: true,
        autofocus: false,
        anchor: (context, controller) => Button(
          label ?? _alignNames[align]!,
          size: ControlSize.small,
          onPressed: controller.toggle,
        ),
        content: (context, controller) => _PlacementCard(asked: side),
      ),
    );
  }
}

const _sideNames = {
  PopoverSide.top: 'Top',
  PopoverSide.bottom: 'Bottom',
  PopoverSide.start: 'Start',
  PopoverSide.end: 'End',
};

const _alignNames = {
  PopoverAlign.start: 'start',
  PopoverAlign.center: 'center',
  PopoverAlign.end: 'end',
};

/// Reads where its popover ended up from [Popover.placementOf]: the side it
/// opened on, and its alignment or the side it flipped from.
class _PlacementCard extends StatelessWidget {
  final PopoverSide asked;

  const _PlacementCard({required this.asked});

  static const width = 120.0;

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.md,
          vertical: AdminSpacing.sm,
        ),
        child: ValueListenableBuilder(
          valueListenable: Popover.placementOf(context)!,
          builder: (context, placed, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_sideNames[placed.side]!, style: context.type.bodyStrong),
              Text(
                placed.side == asked
                    ? 'align ${_alignNames[placed.align]}'
                    : 'flipped from ${_sideNames[asked]!.toLowerCase()}',
                style: context.type.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      width: 240,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          'A floating popover, anchored to its trigger.\n\n'
          'It sits in the Overlay — content below is untouched.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: context.colors.foregroundSecondary,
          ),
        ),
      ),
    );
  }
}

class _ReplyBox extends StatelessWidget {
  const _ReplyBox();

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Typing works inside the overlay:',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.foregroundMuted,
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: 'Reply…'),
            ),
          ],
        ),
      ),
    );
  }
}
