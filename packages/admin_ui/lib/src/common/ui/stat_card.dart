import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/sections/display_messages.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'panel.dart';
import 'severity.dart';
import 'skeleton.dart';
import 'tappable.dart';

enum TrendDirection { up, down, flat }

/// A change indicator on a [StatCard] — the delta label plus its direction.
///
/// [goodWhenUp] carries the semantics: revenue rising is good (green), bounce
/// rate rising is bad (red). Direction sets the arrow; the pairing of direction
/// and [goodWhenUp] sets the colour.
class StatDelta {
  final String label;
  final TrendDirection direction;
  final bool goodWhenUp;

  const StatDelta(
    this.label, {
    this.direction = TrendDirection.up,
    this.goodWhenUp = true,
  });
}

/// A dashboard KPI tile: a muted [label], a large [value], an optional trend
/// [delta] and a [caption] beneath. Fills its slot — lay several out with
/// [StatGrid]. Pass [onTap] to make the whole tile a drill-in target: a
/// focusable button, activated with Enter or Space.
///
/// Assistive technology reads the tile as one sentence — "Revenue: $48.2k, up
/// 12%, vs last month" — so the trend arrow is spoken too.
///
/// While [loading], the figure, the delta and the caption are pulsing bars,
/// each as tall as the line it stands in for, so the card is exactly as tall
/// as a loaded one with a delta or a caption and nothing moves when the
/// figures land. The [label] and [icon] still show when given, so the page
/// names what is coming; an empty [label] is a bar too. A loading card takes
/// no taps and reads as the label and "Loading…".
class StatCard extends StatelessWidget {
  /// The muted name over the figure; a bar while [loading] when empty.
  /// Required, as [value] is, once the card is loaded.
  final String label;

  /// The figure. Not shown while [loading], when it may be left out.
  final String value;
  final IconData? icon;
  final StatDelta? delta;
  final String? caption;
  final VoidCallback? onTap;

  /// Draws the figure, delta and caption as skeleton bars; see [StatCard].
  final bool loading;

  const StatCard({
    super.key,
    this.label = '',
    this.value = '',
    this.icon,
    this.delta,
    this.caption,
    this.onTap,
    this.loading = false,
  }) : assert(
         loading || (label != '' && value != ''),
         'A loaded StatCard shows its label and value; only a loading one '
         'may leave them out.',
       );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      final l10n = context.adminL10n;
      return Semantics(
        container: true,
        label: label.isEmpty
            ? l10n.loading
            : l10n.display.joinParts([label, l10n.loading]),
        excludeSemantics: true,
        // A bar is measured from a line of text, which a late font load
        // changes.
        child: ListenableBuilder(
          listenable: PaintingBinding.instance.systemFonts,
          builder: (context, _) => _card(context, false),
        ),
      );
    }
    final name = _semanticLabel(context.adminL10n.display);
    if (onTap == null) {
      return Semantics(
        container: true,
        label: name,
        excludeSemantics: true,
        child: _card(context, false),
      );
    }
    return Tappable.builder(
      onTap: onTap,
      semanticLabel: name,
      excludeSemantics: true,
      focusRadius: context.radii.radiusLarge,
      builder: (context, hover) => _card(context, hover),
    );
  }

  String _semanticLabel(DisplayMessages strings) {
    final delta = this.delta;
    return strings.joinParts([
      strings.statValue(label, value),
      if (delta != null)
        switch (delta.direction) {
          TrendDirection.up => strings.trendUp(delta.label),
          TrendDirection.down => strings.trendDown(delta.label),
          TrendDirection.flat => delta.label,
        },
      ?caption,
    ]);
  }

  Widget _card(BuildContext context, bool hover) {
    final colors = context.colors;
    final type = context.type;
    final labelStyle = type.weighted(
      type.caption.copyWith(color: colors.foregroundMuted),
      FontWeight.w600,
    );
    final valueStyle = type.pageTitle.copyWith(color: colors.foreground);
    final captionStyle = type.caption.copyWith(color: colors.foregroundMuted);
    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      color: hover ? colors.background : colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: loading && label.isEmpty
                    ? _SkeletonLine(style: labelStyle, widthFactor: 0.4)
                    : Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: context.iconSizes.md,
                  color: colors.foregroundMuted,
                ),
            ],
          ),
          const Gap(AdminSpacing.md),
          if (loading)
            _SkeletonLine(style: valueStyle, widthFactor: 0.55)
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          if (loading) ...[
            const Gap(AdminSpacing.md),
            Row(
              children: [
                const _SkeletonDeltaChip(),
                const Gap(AdminSpacing.md),
                Expanded(
                  child: _SkeletonLine(style: captionStyle, widthFactor: 0.5),
                ),
              ],
            ),
          ] else if (delta != null || caption != null) ...[
            const Gap(AdminSpacing.md),
            Row(
              children: [
                if (delta != null) ...[
                  _DeltaChip(delta: delta!),
                  if (caption != null) const Gap(AdminSpacing.md),
                ],
                if (caption != null)
                  Flexible(
                    child: Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: captionStyle,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A loading line of [style]: a bar about the height of its capitals, from
/// the start of a box one line tall, [widthFactor] of the width.
///
/// The line is measured rather than laid out as empty text: [StatGrid] sizes
/// its rows by intrinsic height, which a paragraph can report from the font
/// it had before a late font load while laying out in the new one.
class _SkeletonLine extends StatelessWidget {
  final TextStyle style;
  final double widthFactor;

  const _SkeletonLine({required this.style, required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14);
    return SizedBox(
      height: lineHeightOf(context, style),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: Skeleton(height: (size * 0.7).roundToDouble()),
        ),
      ),
    );
  }
}

/// A loading [_DeltaChip]: a pill of its height, its padding around the
/// taller of its arrow and its text.
class _SkeletonDeltaChip extends StatelessWidget {
  const _SkeletonDeltaChip();

  @override
  Widget build(BuildContext context) {
    final line = lineHeightOf(
      context,
      context.type.weighted(context.type.caption, FontWeight.w700),
    );
    final height = 2 * AdminSpacing.xxs + math.max(context.iconSizes.xs, line);
    return Skeleton(
      width: 3 * height,
      height: height,
      borderRadius: BorderRadius.circular(context.radii.radiusPill),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final StatDelta delta;

  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = switch ((delta.direction, delta.goodWhenUp)) {
      (TrendDirection.flat, _) => null,
      (TrendDirection.up, true) ||
      (TrendDirection.down, false) => Severity.success,
      _ => Severity.danger,
    };
    // A flat delta is neutral: foregroundMuted on its own faint tint, kept at
    // 4.5:1.
    final style = tone == null ? null : severityStyleOf(context, tone);
    final surface = style?.surface ?? colors.statusFill(colors.foregroundMuted);
    final foreground =
        style?.foreground ??
        colors.readableOn(colors.foregroundMuted, surfaces: [surface]);
    final icon = switch (delta.direction) {
      TrendDirection.up => Icons.arrow_upward_rounded,
      TrendDirection.down => Icons.arrow_downward_rounded,
      TrendDirection.flat => Icons.remove_rounded,
    };

    // A Tag's padding and pill, so the two read as one kind of chip.
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.sm,
        AdminSpacing.xxs,
        AdminSpacing.md,
        AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(context.radii.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.iconSizes.xs, color: foreground),
          const Gap(AdminSpacing.xxs),
          Text(
            delta.label,
            style: context.type.weighted(
              context.type.caption.copyWith(color: foreground),
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A responsive grid for [StatCard]s (or any equal-width tiles): packs as many
/// columns as fit at [minTileWidth], then splits the width evenly so tiles align
/// flush. Wraps to new rows as needed — drop it straight into a scrolling page.
/// The rows are balanced: four tiles with room for three lay out 2 + 2, not
/// 3 + 1.
///
/// Tiles in a row share its height — the tallest tile's — so a card with a
/// delta row doesn't stand taller than its neighbours. That takes the tiles'
/// intrinsic heights, so a tile can't be built by a [LayoutBuilder].
///
/// While the figures load, give it the same cards with `loading: true`,
/// labelled or not; they pulse in step:
///
/// ```dart
/// StatGrid(
///   children: [
///     for (final label in labels) StatCard(label: label, loading: true),
///   ],
/// )
/// ```
class StatGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  const StatGrid({
    super.key,
    required this.children,
    this.minTileWidth = 200,
    this.spacing = AdminSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fit = ((width + spacing) / (minTileWidth + spacing)).floor();
        final rows = (children.length / fit.clamp(1, children.length)).ceil();
        final columns = (children.length / rows).ceil();
        final tileWidth = (width - spacing * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var start = 0; start < children.length; start += columns) ...[
              if (start > 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var i = start;
                      i < math.min(start + columns, children.length);
                      i++
                    ) ...[
                      if (i > start) SizedBox(width: spacing),
                      SizedBox(width: tileWidth, child: children[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
    final loading = children.any((c) => c is StatCard && c.loading);
    return loading ? SkeletonGroup(child: grid) : grid;
  }
}
