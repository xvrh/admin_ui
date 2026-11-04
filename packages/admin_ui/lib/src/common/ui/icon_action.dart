import 'package:material_ui/material_ui.dart';

import '../../theme/sizes.dart';
import '../../theme/tokens.dart';
import 'tappable.dart';
import 'tip.dart';

/// The box and glyph of an [IconAction].
enum IconActionSize {
  /// A 24px box and a 16px glyph: chips, tags, clear and field affordances.
  inline(24, 16),

  /// A 28px box and a 16px glyph: dense rows and small toolbars.
  small(28, 16),

  /// The theme's medium control height (`context.sizes.medium`, 36 in Iris)
  /// and an 18px glyph, the height of a medium [Button]: toolbars, page
  /// headers, the save bar and the top bar.
  medium(null, 18);

  final double? _box;
  final double glyph;

  const IconActionSize(this._box, this.glyph);

  /// Side of the square hit box of a fixed size — [inline] or [small] — at
  /// least WCAG 2.5.8's 24px. [medium] has none of its own: it follows the
  /// theme, so read it with [boxOf] (asserted in debug builds).
  double get box {
    assert(
      _box != null,
      'IconActionSize.medium follows the theme: read boxOf(context).',
    );
    return _box ?? defaultControlSizes.medium;
  }

  /// Side of the square hit box under the active theme: [medium] follows the
  /// theme's medium control height, the others are fixed.
  double boxOf(BuildContext context) => _box ?? context.sizes.medium;
}

/// An icon-only button: close, dismiss, clear, overflow, a toolbar action.
///
/// [label] is required: it is the accessible name, read once, and the tooltip.
/// The glyph rests in `foregroundMuted` with no fill; hover lays the neutral
/// hover overlay under it, in the corner of the theme's small button, and
/// lifts it to `foregroundSecondary` (the danger text colour with [danger]),
/// press deepens the overlay, and keyboard focus draws the theme's focus
/// ring. [selected] marks a toggled-on action — a
/// primary-tinted fill and glyph — and announces it as selected. A null
/// [onPressed] renders the disabled look.
class IconAction extends StatelessWidget {
  final IconData icon;

  /// The accessible name and tooltip. Null only for [IconAction.close], which
  /// reads the localized "Close".
  final String? label;

  final VoidCallback? onPressed;
  final IconActionSize size;

  /// The glyph's size in place of the [size]'s own — a smaller glyph in the
  /// same box, as beside caption text.
  final double? iconSize;

  /// The glyph at rest and under the pointer, for an action drawn on a tinted
  /// surface; hover still lays its fill.
  final Color? color;

  /// A destructive action: the glyph turns to the danger text colour under
  /// the pointer.
  final bool danger;

  /// A toggled-on action (a pinned panel, an active filter).
  final bool selected;

  /// The expanded state of what the action discloses (a menu, a panel), for
  /// assistive technology.
  final bool? expanded;

  /// Shows [label] as a tooltip on hover and keyboard focus.
  final bool tooltip;

  final FocusNode? focusNode;
  final bool autofocus;

  /// Reports, and can seed, the hovered, pressed and focused states — e.g. to
  /// pin a state in a catalog. Created internally when null.
  final WidgetStatesController? statesController;

  const IconAction(
    this.icon, {
    super.key,
    required String this.label,
    this.onPressed,
    this.size = IconActionSize.medium,
    this.iconSize,
    this.color,
    this.danger = false,
    this.selected = false,
    this.expanded,
    this.tooltip = true,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
  });

  /// The close / dismiss action of a dialog, sheet, toast or banner. [label]
  /// defaults to the localized "Close".
  const IconAction.close({
    super.key,
    required this.onPressed,
    this.label,
    this.size = IconActionSize.medium,
    this.iconSize,
    this.color,
    this.tooltip = true,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
  }) : icon = Icons.close_rounded,
       danger = false,
       selected = false,
       expanded = null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A small button's corner at every size: a circle where the theme's
    // buttons are full-round, square where they are square.
    final radius = context.radii.button(ControlSize.small);
    final name = label ?? MaterialLocalizations.of(context).closeButtonTooltip;

    Widget action = Tappable.states(
      onTap: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      statesController: statesController,
      focusRadius: radius,
      semanticLabel: name,
      excludeSemantics: true,
      selected: selected ? true : null,
      expanded: expanded,
      builder: (context, states) {
        final enabled = !states.contains(WidgetState.disabled);
        final pressed = enabled && states.contains(WidgetState.pressed);
        final hovered = enabled && states.contains(WidgetState.hovered);
        final overlay = pressed
            ? colors.pressedOverlay
            : (hovered ? colors.hoverOverlay : null);
        final base = selected ? colors.primarySubtle : null;
        final fill = overlay == null
            ? base
            : (base == null ? overlay : Color.alphaBlend(overlay, base));
        final glyph = !enabled
            ? colors.foregroundSubtle
            : selected
            ? colors.primaryText
            : (hovered || pressed)
            ? (danger
                  ? colors.dangerText
                  : (color ?? colors.foregroundSecondary))
            : (color ?? colors.foregroundMuted);
        return SizedBox.square(
          dimension: size.boxOf(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Center(
              child: Icon(icon, size: iconSize ?? size.glyph, color: glyph),
            ),
          ),
        );
      },
    );
    if (tooltip) {
      action = Tip(message: name, excludeFromSemantics: true, child: action);
    }
    return action;
  }
}
