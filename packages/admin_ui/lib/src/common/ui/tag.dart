import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'icon_action.dart';
import 'severity.dart';

enum TagVariant {
  /// Tinted fill, text in a darker (or, in dark themes, lighter) shade of the
  /// accent — status pills, counts.
  soft,

  /// Solid accent fill with white or near-black text, whichever reads better
  /// on it — strong emphasis.
  solid,

  /// Neutral fill with a token border — input tokens / chips.
  outline,
}

/// A compact pill: a status badge, a count, or (with [onRemove]) a removable
/// chip. Tone comes from [severity] or an explicit [color], defaulting to
/// neutral grey. The corners are the theme's pill radius, and a label longer
/// than the room it gets ends in an ellipsis.
class Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final Severity? severity;
  final TagVariant variant;

  /// Leading status dot.
  final bool dot;

  /// Leading icon (takes precedence over [dot]).
  final IconData? icon;

  /// Arbitrary leading widget (e.g. a colour swatch); takes precedence over
  /// [icon] and [dot].
  final Widget? leading;

  /// When set, shows a trailing × that calls this — turns the tag into a chip.
  /// The × is announced as the localized "Remove [label]".
  final VoidCallback? onRemove;

  const Tag(
    this.label, {
    super.key,
    this.color,
    this.severity,
    this.variant = TagVariant.soft,
    this.dot = false,
    this.icon,
    this.leading,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg, border) = switch (variant) {
      TagVariant.outline => (
        colors.surface,
        colors.foregroundSecondary,
        colors.border,
      ),
      _ when severity != null => _severityColors(
        severityStyleOf(context, severity!),
      ),
      TagVariant.soft => _softColors(colors, color ?? colors.foregroundMuted),
      TagVariant.solid => _solidColors(colors, color ?? colors.foregroundMuted),
    };

    final removable = onRemove != null;
    final radius = BorderRadius.circular(context.radii.radiusPill);
    // The outline is painted over the pill rather than inset around it, so
    // every variant is the same size. A removable chip is 24px tall so its ×
    // keeps a full 24px target, and the pill clips the action's hover fill to
    // its own shape.
    return Container(
      height: removable
          ? IconActionSize.inline.box +
                textGrowthOf(context, context.type.caption)
          : null,
      padding: EdgeInsetsDirectional.fromSTEB(
        leading != null || icon != null || dot
            ? AdminSpacing.sm
            : AdminSpacing.md,
        removable ? 0 : AdminSpacing.xxs,
        removable ? 0 : AdminSpacing.md,
        removable ? 0 : AdminSpacing.xxs,
      ),
      clipBehavior: removable ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      foregroundDecoration: border == null
          ? null
          : BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: border),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const Gap(AdminSpacing.sm),
          ] else if (icon != null) ...[
            Icon(icon, size: context.iconSizes.xs, color: fg),
            const Gap(AdminSpacing.xs),
          ] else if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const Gap(AdminSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: context.type
                  .weighted(context.type.caption, FontWeight.w600)
                  .copyWith(color: fg),
            ),
          ),
          if (removable)
            IconAction(
              Icons.close_rounded,
              label: context.adminL10n.removeItem(label),
              onPressed: onRemove,
              size: IconActionSize.inline,
              iconSize: context.iconSizes.sm,
              color: fg,
            ),
        ],
      ),
    );
  }

  (Color, Color, Color?) _severityColors(SeverityStyle style) =>
      variant == TagVariant.solid
      ? (style.accent, style.onAccent, null)
      : (style.surface, style.foreground, null);

  /// The accent's status fill, with the accent shaded until it reads on both
  /// that fill and the page.
  static (Color, Color, Color?) _softColors(AdminPalette colors, Color accent) {
    final fill = colors.statusFill(accent);
    return (
      fill,
      colors.readableOn(accent, surfaces: [fill, colors.surface]),
      null,
    );
  }

  static (Color, Color, Color?) _solidColors(
    AdminPalette colors,
    Color accent,
  ) => (
    accent,
    accent == colors.primary ? colors.onPrimary : colors.foregroundOn(accent),
    null,
  );
}
