import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// Per-field comment affordance, sidebar-primary: tapping signals "comment
/// here" (the host opens the sidebar with the composer anchored to this
/// field). A quiet 24px inline [IconAction] when the field has no threads;
/// with open threads the glyph and their count sit side by side in the same
/// 24px height, in the warning tone, so the count never leaves the label row.
/// The tone is held to 4.5:1 on a page or panel, hovered or pressed.
class CommentFieldButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const CommentFieldButton({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = context.adminL10n.fields.commentOnField(math.max(0, count));
    if (count <= 0) {
      // maps_ugc = a round add-comment bubble; the squared-off add_comment
      // glyph reads as a cropped box at this size.
      return IconAction(
        Icons.maps_ugc_outlined,
        label: label,
        size: IconActionSize.inline,
        onPressed: onTap,
      );
    }
    final colors = context.colors;
    final radius = context.radii.radiusSmall;
    const size = IconActionSize.inline;
    final tone = colors.readableOn(
      colors.warningText,
      surfaces: [
        for (final surface in [colors.surface, colors.background]) ...[
          surface,
          Color.alphaBlend(colors.hoverOverlay, surface),
          Color.alphaBlend(colors.pressedOverlay, surface),
        ],
      ],
    );
    return Tip(
      message: label,
      excludeFromSemantics: true,
      child: Tappable.states(
        onTap: onTap,
        semanticLabel: label,
        excludeSemantics: true,
        focusRadius: radius,
        builder: (context, states) => Container(
          height: size.box + textGrowthOf(context, context.type.caption),
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs),
          decoration: BoxDecoration(
            color: states.contains(WidgetState.pressed)
                ? colors.pressedOverlay
                : states.contains(WidgetState.hovered)
                ? colors.hoverOverlay
                : null,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mode_comment_outlined, size: size.glyph, color: tone),
              const Gap(AdminSpacing.xs),
              Text(
                count > 99
                    ? '${context.adminFormats.integer(99)}+'
                    : context.adminFormats.integer(count),
                style: context.type
                    .weighted(context.type.caption, FontWeight.w700)
                    .copyWith(color: tone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The margin pin the body editor shows beside a commented text range;
/// tapping opens the range's thread in the sidebar.
class CommentAnnotationPin extends StatelessWidget {
  final VoidCallback onTap;

  const CommentAnnotationPin({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = context.adminL10n.fields.openThread;
    return Tip(
      message: label,
      excludeFromSemantics: true,
      child: Tappable.builder(
        onTap: onTap,
        semanticLabel: label,
        excludeSemantics: true,
        focusRadius: 12,
        builder: (context, hovered) => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: hovered
                ? context.colors.primaryFaint
                : context.colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.borderSubtle),
          ),
          child: Icon(
            Icons.mode_comment,
            size: context.iconSizes.xs,
            color: hovered
                ? context.colors.primaryText
                : context.colors.warningText,
          ),
        ),
      ),
    );
  }
}
