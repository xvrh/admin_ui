import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'icon_action.dart';
import 'menu.dart';
import 'popover.dart';
import 'tappable.dart';
import 'tip.dart';

/// An icon trigger that opens a [Menu] — the reusable kebab / caret behind row
/// actions, a card's overflow menu, etc. The [Menu] stays mounted whenever this
/// widget is in the tree, so moving the pointer from the trigger onto the open
/// popover (which drops a hover signal) can't dismiss it.
///
/// The trigger is a focusable button announced as [tooltip] (the localized
/// "More" when null) with its menu's expanded state; Enter, Space or ↓ opens
/// the menu on its first item.
///
/// Two shapes:
/// - **standalone** (default): an [IconAction] of [size] — small, a 28px
///   target, unless set — with its hover fill and tooltip, always visible — a
///   table row kebab. [iconSize] does not apply; the glyph is the action's
///   own.
/// - **overlay** ([maskColor] set, [revealed] driven by a parent's hover): a
///   caret that floats over content, shown only while hovered, focused or
///   open, with a gradient that masks whatever it covers.
class MenuButton extends StatelessWidget {
  final IconData icon;
  final List<MenuEntry> entries;

  /// Glyph size of the overlay shape.
  final double iconSize;

  /// The standalone trigger's box and glyph.
  final IconActionSize size;
  final Color? color;
  final PopoverSide side;
  final PopoverAlign align;

  /// The accessible name, and the tooltip. The localized "More" when null;
  /// the overlay shape shows a tooltip only when this is set.
  final String? tooltip;

  /// When false the trigger shows only while its menu is open or it holds
  /// keyboard focus — for a caret revealed by a parent's hover state. It stays
  /// in the Tab order either way, and takes no pointer while hidden. Defaults
  /// to always visible.
  final bool revealed;

  /// Start-to-end gradient to [maskColor] behind the icon, so it can overlay
  /// content without colliding with it. Null = no mask (standalone use).
  final Color? maskColor;

  /// Fixed width of the masked overlay; null hugs the icon.
  final double? width;

  const MenuButton({
    super.key,
    required this.icon,
    required this.entries,
    this.iconSize = 18,
    this.size = IconActionSize.small,
    this.color,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.end,
    this.tooltip,
    this.revealed = true,
    this.maskColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Menu(
      side: side,
      align: align,
      entries: entries,
      builder: (context, c) {
        final label =
            tooltip ?? MaterialLocalizations.of(context).moreButtonTooltip;
        if (maskColor == null) {
          // One tree shape whether revealed or not, so a parent driving
          // [revealed] from its hover keeps the trigger, and its focus.
          return _Revealable(
            open: c.isOpen || revealed,
            builder: (shown, onFocusChange) => Focus(
              canRequestFocus: false,
              skipTraversal: true,
              includeSemantics: false,
              onFocusChange: onFocusChange,
              child: IconAction(
                icon,
                label: label,
                onPressed: c.toggle,
                expanded: c.isOpen,
                size: size,
                color: color,
              ),
            ),
          );
        }
        return _Revealable(
          open: c.isOpen || revealed,
          builder: (shown, onFocusChange) {
            Widget trigger = Tappable(
              onTap: c.toggle,
              semanticLabel: label,
              excludeSemantics: true,
              expanded: c.isOpen,
              focusRadius: context.radii.radiusSmall,
              onFocusChange: onFocusChange,
              child: Container(
                width: width,
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsetsDirectional.only(end: AdminSpacing.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [maskColor!.withValues(alpha: 0), maskColor!],
                    stops: const [0, 0.55],
                  ),
                ),
                // Hidden, the caret is not drawn at all: only its Tab stop
                // and its name remain.
                child: shown
                    ? Icon(
                        icon,
                        size: iconSize,
                        color: color ?? context.colors.foregroundMuted,
                      )
                    : SizedBox.square(dimension: iconSize),
              ),
            );
            if (tooltip != null) {
              trigger = Tip(
                message: tooltip!,
                excludeFromSemantics: true,
                child: trigger,
              );
            }
            return trigger;
          },
        );
      },
    );
  }
}

/// Shows its child while [open] or while focus is inside it; otherwise keeps
/// it laid out, focusable and announced, but unpainted and deaf to the
/// pointer.
class _Revealable extends StatefulWidget {
  final bool open;
  final Widget Function(bool shown, ValueChanged<bool> onFocusChange) builder;

  const _Revealable({required this.open, required this.builder});

  @override
  State<_Revealable> createState() => _RevealableState();
}

class _RevealableState extends State<_Revealable> {
  bool _focused = false;

  void _onFocusChange(bool focused) {
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.open || _focused;
    return IgnorePointer(
      ignoring: !shown,
      child: Opacity(
        opacity: shown ? 1 : 0,
        alwaysIncludeSemantics: true,
        child: widget.builder(shown, _onFocusChange),
      ),
    );
  }
}
