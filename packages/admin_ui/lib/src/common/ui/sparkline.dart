import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

/// A compact inline line chart — no axes, no labels, no interaction. Drop it
/// into a table cell or beside a [StatCard] value to show a trend at a glance.
/// Drawn in the first chart colour unless given a [color], so it matches the
/// charts beside it. Pass the same [width] everywhere to keep a column aligned.
/// Right to left it runs from the right, like the charts.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final bool area;
  final bool showDot;
  final double strokeWidth;
  final double height;

  /// Fixed width, or null to fill the parent's width — handy in a stat card or a
  /// flexible table cell.
  final double? width;

  const Sparkline(
    this.values, {
    super.key,
    this.color,
    this.area = true,
    this.showDot = true,
    this.strokeWidth = 1.5,
    this.height = 24,
    this.width = 88,
  });

  @override
  Widget build(BuildContext context) {
    final painter = _SparklinePainter(
      values: values,
      color: color ?? context.colors.chart.first,
      area: area,
      showDot: showDot,
      strokeWidth: strokeWidth,
      textDirection: Directionality.of(context),
    );
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: CustomPaint(painter: painter),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool area;
  final bool showDot;
  final double strokeWidth;
  final TextDirection textDirection;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.area,
    required this.showDot,
    required this.strokeWidth,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    _mirror(canvas, size, textDirection);
    final dotR = showDot ? 2.5 : 0.0;
    final pad = strokeWidth + dotR;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    if (w <= 0 || h <= 0) return;

    var lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = hi - lo;

    double x(int i) =>
        pad + (values.length == 1 ? w / 2 : w * i / (values.length - 1));
    double y(double v) => pad + (span == 0 ? h / 2 : h * (1 - (v - lo) / span));

    final points = [
      for (var i = 0; i < values.length; i++) Offset(x(i), y(values[i])),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    if (area && points.length > 1) {
      final fill = Path.from(line)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // token-literal: the area under the line, fading out
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    if (showDot) {
      canvas.drawCircle(points.last, dotR, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.area != area ||
      old.showDot != showDot ||
      old.strokeWidth != strokeWidth ||
      old.textDirection != textDirection;
}

/// Flips [canvas] about the middle of [size] right to left, so a series
/// drawn from the left starts at the right.
void _mirror(Canvas canvas, Size size, TextDirection direction) {
  if (direction == TextDirection.ltr) return;
  canvas
    ..translate(size.width, 0)
    ..scale(-1, 1);
}

/// A compact inline bar chart — the bar-shaped sibling of [Sparkline], for
/// counts/volume where discrete bars read better than a line, in the same
/// default colour, and mirrored right to left the same way. [highlightLast]
/// draws the final bar in full colour and the rest muted, to spotlight "now":
/// the colour washed toward the surface, but held at 2:1 against it so no bar
/// fades into the page.
class BarSparkline extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final bool highlightLast;
  final double height;
  final double? width;

  const BarSparkline(
    this.values, {
    super.key,
    this.color,
    this.highlightLast = false,
    this.height = 24,
    this.width = 88,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = color ?? colors.chart.first;
    final painter = _BarSparklinePainter(
      values: values,
      color: base,
      mutedColor: highlightLast
          ? colors.readableOn(
              Color.lerp(base, colors.surface, 0.55)!,
              minContrast: _mutedContrast,
            )
          : base,
      radius: context.radii.radiusSmall,
      textDirection: Directionality.of(context),
    );
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: CustomPaint(painter: painter),
    );
  }
}

const _mutedContrast = 2.0;

class _BarSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  /// Every bar but the last.
  final Color mutedColor;

  /// The theme's small radius, which rounds a bar's top up to a quarter of
  /// its width: square in a square theme, never a pill at this size.
  final double radius;

  final TextDirection textDirection;

  _BarSparklinePainter({
    required this.values,
    required this.color,
    required this.mutedColor,
    required this.radius,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    _mirror(canvas, size, textDirection);
    var hi = 0.0;
    for (final v in values) {
      if (v > hi) hi = v;
    }
    if (hi == 0) hi = 1;

    final n = values.length;
    final slot = size.width / n;
    final barW = (slot * 0.62).clamp(1.0, slot);
    final corner = Radius.circular(math.min(radius, barW / 4));

    for (var i = 0; i < n; i++) {
      final barH = (values[i] / hi) * size.height;
      final left = slot * i + (slot - barW) / 2;
      final rect = Rect.fromLTWH(left, size.height - barH, barW, barH);
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: corner, topRight: corner),
        Paint()..color = i == n - 1 ? color : mutedColor,
      );
    }
  }

  @override
  bool shouldRepaint(_BarSparklinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.mutedColor != mutedColor ||
      old.radius != radius ||
      old.textDirection != textDirection;
}
