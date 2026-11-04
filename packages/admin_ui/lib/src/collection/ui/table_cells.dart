/// @docImport '../../common/ui/checkbox.dart';
/// @docImport '../../common/ui/tag.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/thumbnail_image.dart';
import '../../i18n/locale_status.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'collection_table.dart';
import 'view_support.dart';

/// Reusable cell widgets for [CollectionTable] — the content-table affordances a
/// generic grid doesn't ship: identity, thumbnail, relation chip, locale
/// roll-up. Compose with [Tag]/[Check] for status and booleans.

/// A small rounded media square: an [image], a flat [color] swatch, or an
/// [icon] placeholder. The image decodes at the size it is drawn and shows a
/// broken-image glyph when it fails to load.
class TableThumb extends StatelessWidget {
  final ImageProvider? image;
  final Color? color;
  final IconData? icon;
  final double size;

  const TableThumb({
    super.key,
    this.image,
    this.color,
    this.icon,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(context.radii.radiusSmall);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? colors.background,
        borderRadius: radius,
      ),
      // Over the image, so its edge stays crisp on a photo too.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.border),
      ),
      child: image != null
          ? ThumbnailImage(image: image!, size: size, borderRadius: radius)
          : color == null
          ? Icon(
              icon ?? Icons.image_outlined,
              size: size * 0.5,
              color: colors.foregroundFaint,
            )
          : null,
    );
  }
}

/// The primary column: a [leading] thumb/avatar, a [title], and an optional
/// [subtitle] (SKU, path, email). Truncates on overflow.
///
/// In a row too short for two lines — a compact density — the subtitle
/// follows the title on one line, and [leading] shrinks to leave the row
/// rules room.
class TableIdentity extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;

  const TableIdentity({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
  });

  /// The breathing room kept above and below the content.
  static const _inset = AdminSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final titleStyle = context.type.bodyStrong;
    final subtitleStyle = tableMutedStyle(context, context.type.caption);
    return LayoutBuilder(
      builder: (context, box) {
        final twoLines =
            subtitle != null &&
            lineHeightOf(context, titleStyle) +
                    lineHeightOf(context, subtitleStyle) +
                    2 * _inset <=
                box.maxHeight;
        final Widget text;
        if (subtitle == null || twoLines) {
          text = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
            ],
          );
        } else {
          text = Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title, style: titleStyle),
                const TextSpan(text: '  '),
                TextSpan(text: subtitle, style: subtitleStyle),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        final lead = leading;
        return Row(
          children: [
            if (lead != null) ...[
              if (twoLines || !box.maxHeight.isFinite)
                lead
              else
                ConstrainedBox(
                  constraints: BoxConstraints.loose(
                    Size.square(box.maxHeight - 2 * _inset),
                  ),
                  child: lead,
                ),
              const Gap(AdminSpacing.sm),
            ],
            Expanded(child: text),
          ],
        );
      },
    );
  }
}

/// A related entity rendered as a chip — a dot/swatch + label, link-tinted when
/// [onTap] is set. Not a raw id.
///
/// With [onTap] the chip is a link: focusable, announced as a link, opened by
/// Enter. In a [CollectionTable] cell, Enter on the cell moves focus onto the
/// chip, and Enter there opens the chip rather than the row.
class RelationChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const RelationChip({super.key, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color ?? context.colors.foregroundFaint,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(AdminSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.body.copyWith(
                color: onTap != null
                    ? context.colors.primaryText
                    : context.colors.foregroundSecondary,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Tappable(
      onTap: onTap,
      link: true,
      focusRadius: context.radii.radiusSmall,
      child: chip,
    );
  }
}

/// A compact row of per-locale pills — the multilingual roll-up. Each pill is a
/// locale code tinted by its [LocaleStatus] (the shared field enum); a null
/// status means not translated and renders as a muted outline.
class LocaleRollup extends StatelessWidget {
  final Map<String, LocaleStatus?> locales;

  const LocaleRollup({super.key, required this.locales});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminSpacing.xs,
      runSpacing: AdminSpacing.xs,
      children: [
        for (final e in locales.entries) _pill(context, e.key, e.value),
      ],
    );
  }

  Widget _pill(BuildContext context, String code, LocaleStatus? status) {
    final colors = context.colors;
    final color = status == null
        ? tableMutedStyle(context).color!
        : localeStatusMeta(context)[status]!.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        border: Border.all(
          // token-literal: a status tag's edge, its colour at a third
          color: status == null ? colors.border : color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        code.toUpperCase(),
        style: context.type
            .weighted(context.type.micro, FontWeight.w700)
            .copyWith(
              color: colors.readableOn(
                color,
                surfaces: tableRowSurfaces(colors),
              ),
            ),
      ),
    );
  }
}
