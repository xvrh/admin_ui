import 'package:flutter/painting.dart';

/// WCAG 2.x relative luminance of [color]: 0 for black, 1 for white. Alpha is
/// ignored; composite a translucent colour first (see [contrastRatio]).
double relativeLuminance(Color color) => color.computeLuminance();

/// WCAG 2.x contrast ratio between [foreground] and [background], from 1 (no
/// contrast) to 21 (black on white). [background] is taken as opaque; a
/// translucent [foreground] is composited over it first, so a tint or overlay
/// is measured as it renders.
double contrastRatio(Color foreground, Color background) {
  final back = background.withValues(alpha: 1);
  final front = foreground.a < 1
      ? Color.alphaBlend(foreground, back)
      : foreground;
  final a = relativeLuminance(front);
  final b = relativeLuminance(back);
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}
