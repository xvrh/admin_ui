/// @docImport 'sparkline.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
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
/// [delta] and a [caption] beneath, and a small [trend] chart. Fills its slot
/// — lay several out with [StatGrid]. Pass [onTap] to make the whole tile a
/// drill-in target: a focusable button, activated with Enter or Space.
///
/// The [trend], a [Sparkline] or a [BarSparkline] of the figure's recent
/// history, stands beside the figure, at the card's end and at its own width,
/// while it is no taller than the figure's line and the figure keeps beside
/// it its one-line width, and at least [minValueWidth]: the card is then as
/// tall as one without a trend. Otherwise it goes under the delta and the
/// caption, across the card, along its bottom edge. Either way the label, the
/// figure and the delta of the cards in a [StatGrid] row stay level, trend
/// or not, and the trends under their figures line up along the row's
/// bottom. A trend that fills the width it is given, such as a
/// `Sparkline(width: null)`, always goes under.
///
/// Assistive technology reads the tile as one sentence — "Revenue: $48.2k, up
/// 12%, vs last month" — so the trend arrow is spoken too. The [trend] chart
/// is not: the delta already speaks the change it draws.
///
/// While [loading], the figure is a pulsing bar, and so are the [delta] and
/// the [caption] the card is given, each as tall as what it stands in for,
/// and the [trend] is a pulsing block of its size, where the loaded card puts
/// it. Their words and values are not shown, so give a loading card the
/// delta, the caption and the trend the loaded card will have, with any
/// words and values (`Sparkline(const [])`): it is then exactly as tall as
/// the loaded card, and nothing moves when the figures land. It places the
/// trend for a figure [minValueWidth] wide: where the figure to come may be
/// wider, give it as the loading card's [value], such as the figure last
/// shown, and the trend stands where the loaded card's will. The [label] and
/// [icon] still show when given, so the page names what is coming; an empty
/// [label] is a bar too. A loading card takes no taps and reads as the label
/// and "Loading…".
class StatCard extends StatelessWidget {
  /// The muted name over the figure; a bar while [loading] when empty.
  /// Required, as [value] is, once the card is loaded.
  final String label;

  /// The figure. Not shown while [loading], when it may be left out.
  final String value;
  final IconData? icon;
  final StatDelta? delta;
  final String? caption;

  /// A small chart of the figure's recent history, such as a [Sparkline] of
  /// the last 30 days: beside the figure or under the delta and caption,
  /// as [StatCard] says. Decorative to assistive technology. Like any tile of
  /// a [StatGrid], it is built without a [LayoutBuilder].
  final Widget? trend;
  final VoidCallback? onTap;

  /// Draws the figure, and the delta, caption and trend it is given, as
  /// skeletons; see [StatCard].
  final bool loading;

  /// The least width the figure keeps beside a [trend]; with less room, the
  /// trend goes under.
  static const minValueWidth = 96.0;

  const StatCard({
    super.key,
    this.label = '',
    this.value = '',
    this.icon,
    this.delta,
    this.caption,
    this.trend,
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
        child: _measured(context, false),
      );
    }
    final name = _semanticLabel(context.adminL10n.display);
    if (onTap == null) {
      return Semantics(
        container: true,
        label: name,
        excludeSemantics: true,
        child: _measured(context, false),
      );
    }
    return Tappable.builder(
      onTap: onTap,
      semanticLabel: name,
      excludeSemantics: true,
      focusRadius: context.radii.radiusLarge,
      builder: (context, hover) => _measured(context, hover),
    );
  }

  /// The card, built again when a font loads if it measures text: a loading
  /// card's bars are measured from a line of text, and a trend's place from
  /// the figure's width, which a late font load changes.
  Widget _measured(BuildContext context, bool hover) {
    if (!loading && trend == null) return _card(context, hover);
    return ListenableBuilder(
      listenable: PaintingBinding.instance.systemFonts,
      builder: (context, _) => _card(context, hover),
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
    final trend = this.trend;
    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      color: hover ? colors.background : colors.surface,
      child: _StatBody(
        textDirection: Directionality.of(context),
        figureWidth: trend == null
            ? 0
            : math.max(minValueWidth, textWidthOf(context, value, valueStyle)),
        label: Row(
          children: [
            Expanded(
              child: loading && label.isEmpty
                  ? SkeletonText(style: labelStyle, widthFactor: 0.4)
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
        figure: loading
            ? SkeletonText(style: valueStyle, widthFactor: 0.55)
            : Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
        details: delta == null && caption == null
            ? null
            : loading
            ? Row(
                children: [
                  if (delta != null) const _SkeletonDeltaChip(),
                  if (delta != null && caption != null)
                    const Gap(AdminSpacing.md),
                  if (caption != null)
                    Expanded(
                      child: SkeletonText(
                        style: captionStyle,
                        widthFactor: 0.5,
                      ),
                    ),
                ],
              )
            : Row(
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
        trend: trend == null
            ? null
            : loading
            ? _SkeletonTrend(trend)
            : trend,
      ),
    );
  }
}

enum _StatSlot { label, figure, details, trend }

/// A [StatCard]'s contents, one under the other: its [label] row, its
/// [figure], its [details] (the delta and the caption) and its [trend], which
/// stands beside the figure while it is no taller than the figure and the
/// figure keeps [figureWidth] beside it, and otherwise goes under the rest,
/// along the bottom edge of the height the card is given.
class _StatBody
    extends SlottedMultiChildRenderObjectWidget<_StatSlot, RenderBox> {
  final Widget label;
  final Widget figure;
  final Widget? details;
  final Widget? trend;

  /// The least the figure keeps beside the trend.
  final double figureWidth;
  final TextDirection textDirection;

  const _StatBody({
    required this.label,
    required this.figure,
    required this.details,
    required this.trend,
    required this.figureWidth,
    required this.textDirection,
  });

  @override
  Iterable<_StatSlot> get slots => _StatSlot.values;

  @override
  Widget? childForSlot(_StatSlot slot) => switch (slot) {
    _StatSlot.label => label,
    _StatSlot.figure => figure,
    _StatSlot.details => details,
    _StatSlot.trend => trend,
  };

  @override
  _RenderStatBody createRenderObject(BuildContext context) =>
      _RenderStatBody(figureWidth: figureWidth, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderStatBody renderObject) {
    renderObject
      ..figureWidth = figureWidth
      ..textDirection = textDirection;
  }
}

class _RenderStatBody extends RenderBox
    with SlottedContainerRenderObjectMixin<_StatSlot, RenderBox> {
  _RenderStatBody({required this._figureWidth, required this._textDirection});

  /// Between the label, the figure and the details.
  static const _gap = AdminSpacing.md;

  /// Between the figure and the trend beside it, or the details and the
  /// trend under them.
  static const _trendGap = AdminSpacing.lg;

  double _figureWidth;
  set figureWidth(double value) {
    if (value == _figureWidth) return;
    _figureWidth = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _label => childForSlot(_StatSlot.label)!;
  RenderBox get _figure => childForSlot(_StatSlot.figure)!;
  RenderBox? get _details => childForSlot(_StatSlot.details);
  RenderBox? get _trend => childForSlot(_StatSlot.trend);

  @override
  double computeMinIntrinsicWidth(double height) =>
      [for (final child in children) child.getMinIntrinsicWidth(height)]
          .fold(0, math.max);

  @override
  double computeMaxIntrinsicWidth(double height) {
    final trend = _trend?.getMaxIntrinsicWidth(height);
    return math.max(
      math.max(
        _label.getMaxIntrinsicWidth(height),
        _details?.getMaxIntrinsicWidth(height) ?? 0,
      ),
      _figure.getMaxIntrinsicWidth(height) +
          (trend == null ? 0 : _trendGap + trend),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) => _plan(
    BoxConstraints(maxWidth: width),
    ChildLayoutHelper.dryLayoutChild,
  ).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _label.getDistanceToActualBaseline(baseline);

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => _label.getDryBaseline(
    BoxConstraints.tightFor(width: _width(constraints)),
    baseline,
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _plan(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  void performLayout() {
    final plan = _plan(constraints, ChildLayoutHelper.layoutChild);
    size = plan.size;
    for (final (child, offset) in plan.offsets) {
      (child.parentData! as BoxParentData).offset = offset;
    }
  }

  double _width(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : computeMaxIntrinsicWidth(double.infinity);

  ({Size size, List<(RenderBox, Offset)> offsets}) _plan(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    final width = _width(constraints);
    final rtl = _textDirection == TextDirection.rtl;
    // The x of a box [w] wide starting [start] in from the leading edge.
    double x(double start, double w) => rtl ? width - start - w : start;
    final across = BoxConstraints.tightFor(width: width);
    final offsets = <(RenderBox, Offset)>[];

    final label = _label;
    var y = layoutChild(label, across).height + _gap;
    offsets.add((label, Offset(x(0, width), 0)));

    final figure = _figure;
    var figureSize = layoutChild(figure, across);
    final trend = _trend;
    var beside = false;
    if (trend != null) {
      // At its own width, as a row lays out a child it does not stretch.
      final trendSize = layoutChild(trend, BoxConstraints(maxWidth: width));
      final room = width - _trendGap - trendSize.width;
      beside = trendSize.height <= figureSize.height && room >= _figureWidth;
      if (beside) {
        figureSize = layoutChild(figure, BoxConstraints.tightFor(width: room));
        offsets.add((
          trend,
          Offset(
            x(width - trendSize.width, trendSize.width),
            y + (figureSize.height - trendSize.height) / 2,
          ),
        ));
      }
    }
    offsets.add((figure, Offset(x(0, figureSize.width), y)));
    y += figureSize.height;

    final details = _details;
    if (details != null) {
      y += _gap;
      final detailsSize = layoutChild(details, across);
      offsets.add((details, Offset(x(0, detailsSize.width), y)));
      y += detailsSize.height;
    }

    if (trend == null || beside) {
      return (size: constraints.constrain(Size(width, y)), offsets: offsets);
    }
    y += _trendGap;
    final trendSize = layoutChild(trend, across);
    final size = constraints.constrain(Size(width, y + trendSize.height));
    // On the bottom edge of a card stretched to its row's height.
    offsets.add((
      trend,
      Offset(
        x(0, trendSize.width),
        math.max(y, size.height - trendSize.height),
      ),
    ));
    return (size: size, offsets: offsets);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// A loading [StatCard.trend]: a pulsing block the size the trend lays out
/// at, in its place. The trend itself is laid out, not shown.
class _SkeletonTrend extends StatelessWidget {
  final Widget trend;

  const _SkeletonTrend(this.trend);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Visibility.maintain(visible: false, child: trend),
        const Positioned.fill(child: Skeleton(height: double.infinity)),
      ],
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
/// delta row, or a trend under its figure, doesn't stand taller than its
/// neighbours. That takes the tiles' intrinsic heights, so a tile can't be
/// built by a [LayoutBuilder].
///
/// While the figures load, give it the same cards with `loading: true`,
/// labelled or not; they pulse in step:
///
/// ```dart
/// StatGrid(
///   children: [
///     for (final label in labels)
///       StatCard(label: label, caption: 'vs last month', loading: true),
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
