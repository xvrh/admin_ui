import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'tappable.dart';

/// An action that reads as part of a line of text: a caption-sized label in
/// the primary text colour, underlined while the pointer is on it or presses
/// it, with the kit's focus ring. It is for the "Show", "Edit" or "Use
/// source" at the end of a lane label or a footer line; an action that is a
/// control of its own is a [Button].
///
/// Its hit box hugs the label, so give it a line of its own height (a lane
/// strip, a caption row) rather than a place a full control would sit.
class TextLink extends StatelessWidget {
  final String label;

  /// Null disables the link: it draws in the subtle colour and does not
  /// underline.
  final VoidCallback? onPressed;

  /// A leading glyph, at `context.iconSizes.xs`, in the label's colour.
  final IconData? icon;

  /// The label's colour: `colors.primaryText` when null. Pass one readable
  /// on the surface the link sits on when that is not the page.
  final Color? color;

  /// What a screen reader hears instead of [label], when the label alone
  /// does not say what the action acts on ("Show" → "Show 3 shared fields").
  final String? semanticLabel;

  /// Set on a link that reveals content, announced as expanded or collapsed.
  final bool? expanded;

  /// Underlines the label at rest too, not only while hovered or pressed:
  /// for a link drawn in the colour of the text around it (an error
  /// summary's rows), which only the underline tells apart.
  final bool underlined;

  const TextLink(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.color,
    this.semanticLabel,
    this.expanded,
    this.underlined = false,
  });

  /// A link's text style in [states], for a larger target that ends in one
  /// (a whole row that reads "… Edit"): caption at the theme's strong
  /// weight (`AdminTypeSpec.strong`) in [color], or
  /// `colors.primaryText`, underlined while hovered or pressed (always,
  /// when [underlined]) and lighter while pressed. Disabled, it is
  /// `colors.foregroundSubtle` and plain.
  static TextStyle styleOf(
    BuildContext context,
    Set<WidgetState> states, {
    Color? color,
    bool underlined = false,
  }) {
    final colors = context.colors;
    final enabled = !states.contains(WidgetState.disabled);
    final ink = enabled ? color ?? colors.primaryText : colors.foregroundSubtle;
    final pressed = enabled && states.contains(WidgetState.pressed);
    final underline =
        enabled &&
        (underlined || pressed || states.contains(WidgetState.hovered));
    return context.type.weighted(
      context.type.caption.copyWith(
        color: pressed ? ink.withValues(alpha: _pressedAlpha) : ink,
        decoration: underline ? TextDecoration.underline : null,
        decorationColor: ink,
      ),
      context.type.spec.strong,
    );
  }

  /// How much of the colour a pressed link keeps.
  static const _pressedAlpha = 0.75;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tappable.states(
      onTap: onPressed,
      semanticLabel: semanticLabel ?? label,
      excludeSemantics: true,
      expanded: expanded,
      focusRadius: context.radii.radiusSmall,
      builder: (context, states) {
        final style = styleOf(
          context,
          {...states, if (!enabled) WidgetState.disabled},
          color: color,
          underlined: underlined,
        );
        final text = Text(label, style: style);
        final glyph = icon;
        if (glyph == null) return text;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(glyph, size: context.iconSizes.xs, color: style.color),
            const Gap(AdminSpacing.xs),
            text,
          ],
        );
      },
    );
  }
}
