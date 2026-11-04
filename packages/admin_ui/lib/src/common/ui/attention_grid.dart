import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'severity.dart';
import 'skeleton.dart';
import 'stat_card.dart';
import 'tappable.dart';

/// One tile of an [AttentionGrid]: a [count] of things in one state (drafts
/// to review, unresolved comments, failed jobs) with an action to go deal
/// with them. Tinted by [tone], and only worth showing when [count] is
/// non-zero — the caller filters.
class AttentionItem {
  final String label;
  final int count;
  final IconData icon;
  final Severity tone;

  /// Optional detail under the label ("across 3 pages", "oldest 2d ago").
  final String? caption;

  /// Goes to the things counted. Null renders a tile that is not a button.
  final VoidCallback? onTap;

  const AttentionItem({
    required this.label,
    required this.count,
    required this.icon,
    this.tone = Severity.info,
    this.caption,
    this.onTap,
  });
}

/// An [AttentionItem] as a tile tinted by its tone: a glyph, the count beside
/// its label and the caption under them. An actionable tile ends in a
/// chevron and darkens its fill under the pointer. The tile reads as one
/// phrase ("7 drafts to publish, across pages & articles").
class AttentionTile extends StatelessWidget {
  final AttentionItem item;

  const AttentionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final style = severityStyleOf(context, item.tone);
    final name = context.adminL10n.display.attentionItem(
      item.count,
      item.label,
      item.caption,
    );
    if (item.onTap == null) {
      return Semantics(
        container: true,
        label: name,
        excludeSemantics: true,
        child: _tile(context, style, false),
      );
    }
    return Tappable.builder(
      onTap: item.onTap,
      semanticLabel: name,
      excludeSemantics: true,
      focusRadius: context.radii.radiusLarge,
      builder: (context, hover) => _tile(context, style, hover),
    );
  }

  Widget _tile(BuildContext context, SeverityStyle style, bool hover) {
    final colors = context.colors;
    return _TonePanel(
      surface: style.surface,
      border: style.border,
      hover: hover,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // token-literal: an item's glyph tile, a wash of its accent
              color: style.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(context.radii.radius),
            ),
            child: Icon(
              item.icon,
              size: context.iconSizes.lg,
              color: style.foreground,
            ),
          ),
          const Gap(AdminSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      context.adminFormats.integer(item.count),
                      style: context.type.heading.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const Gap(AdminSpacing.sm),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodyStrong.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.caption != null) ...[
                  const Gap(AdminSpacing.xxs),
                  Text(
                    item.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.caption.copyWith(
                      color: colors.foregroundMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: context.iconSizes.lg,
              color: style.foreground,
            ),
        ],
      ),
    );
  }
}

/// The "needs your attention" block of a home screen: a [title] over a
/// responsive grid of [AttentionTile]s, as many columns as fit tiles of
/// [minTileWidth]. With no [items] it is one success-tinted line saying all
/// is caught up, and while [loading] it holds [placeholderCount] pulsing
/// tiles the height of real ones, so the page does not jump when they land.
class AttentionGrid extends StatelessWidget {
  final List<AttentionItem> items;

  /// The heading over the tiles; "Needs your attention" by default.
  final String? title;

  /// The line shown when [items] is empty; "You're all caught up — nothing
  /// needs attention." by default.
  final String? emptyMessage;

  /// Swaps the tiles for [placeholderCount] skeleton tiles.
  final bool loading;
  final int placeholderCount;

  final double minTileWidth;

  const AttentionGrid({
    super.key,
    required this.items,
    this.title,
    this.emptyMessage,
    this.loading = false,
    this.placeholderCount = 4,
    this.minTileWidth = 240,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.display;
    if (!loading && items.isEmpty) {
      return _AllClear(message: emptyMessage ?? strings.allCaughtUp);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
          child: Text(
            title ?? strings.needsAttention,
            style: context.type.sectionLabel.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
        ),
        if (loading)
          Semantics(
            label: context.adminL10n.loading,
            child: SkeletonGroup(
              child: StatGrid(
                minTileWidth: minTileWidth,
                children: [
                  for (var i = 0; i < placeholderCount; i++)
                    const _SkeletonTile(),
                ],
              ),
            ),
          )
        else
          StatGrid(
            minTileWidth: minTileWidth,
            children: [for (final it in items) AttentionTile(item: it)],
          ),
      ],
    );
  }
}

/// A loading [AttentionTile]: its two lines of text as pulsing bars, each
/// line as tall as the style it stands in for, so the tile is exactly as tall
/// as one with a caption.
///
/// The lines are measured rather than laid out as empty text: the grid sizes
/// its rows by intrinsic height, which a paragraph can report from the font
/// it had before a late font load while laying out in the new one.
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PaintingBinding.instance.systemFonts,
      builder: (context, _) {
        final c = context.colors;
        final type = context.type;
        Widget line(TextStyle style, double widthFactor, double height) =>
            SizedBox(
              height: lineHeightOf(context, style),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Skeleton(height: height),
                ),
              ),
            );
        return _TonePanel(
          surface: c.surface,
          border: c.border,
          child: Row(
            children: [
              Skeleton(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(context.radii.radius),
              ),
              const Gap(AdminSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The count's line, which the label beside it fits in.
                    line(type.heading, 0.6, 12),
                    const Gap(AdminSpacing.xxs),
                    line(type.caption, 0.4, 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AllClear extends StatelessWidget {
  final String message;

  const _AllClear({required this.message});

  @override
  Widget build(BuildContext context) {
    final style = severityStyleOf(context, Severity.success);
    return _TonePanel(
      surface: style.surface,
      border: style.border,
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: context.iconSizes.lg,
            color: style.foreground,
          ),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Text(
              message,
              style: context.type.body.copyWith(
                color: context.colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card with a tinted surface and border, like an `Alert`.
class _TonePanel extends StatelessWidget {
  final Color surface;
  final Color border;
  final bool hover;
  final Widget child;

  const _TonePanel({
    required this.surface,
    required this.border,
    required this.child,
    this.hover = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = hover
        ? Color.alphaBlend(context.colors.hoverOverlay, surface)
        : surface;
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}
