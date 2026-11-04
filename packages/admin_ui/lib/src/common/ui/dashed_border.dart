import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

/// A dashed rounded-rectangle border drawn around [child] — the drop-zone /
/// add-affordance outline shared by the media field and the upload panel.
///
/// Painted over the child, inside its edge: the stroke is inset by half its
/// width, so a child that fills the same rounded rect never covers half of it,
/// and a whole-pixel [strokeWidth] lands on whole pixels.
class DashedBorder extends StatelessWidget {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final Widget child;

  const DashedBorder({
    super.key,
    required this.color,
    required this.radius,
    this.strokeWidth = 1,
    this.dash = 5,
    this.gap = 4,
    required this.child,
  });

  /// The dashes of a zone at rest: the control border, standing 3:1 off every
  /// surface a zone sits on, so the target reads as one before it is hovered.
  static Color restingColor(BuildContext context) {
    final colors = context.colors;
    return colors.readableOn(
      colors.controlBorder,
      surfaces: [colors.surface, colors.background, colors.surfaceMuted],
      minContrast: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dash: dash,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final inset = strokeWidth / 2;
    var rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset),
      Radius.circular(math.max(0, radius - inset)),
    );
    var path = Path()..addRRect(rrect);
    for (var metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}
