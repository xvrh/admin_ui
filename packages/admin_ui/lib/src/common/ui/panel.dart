import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

/// A bordered, rounded surface — the standard container for a table, a form
/// section, or any grouped block of content. Clips its [child] to the radius so
/// a flush table, image, or list can't bleed past the corners.
///
/// The border paints over the child, so flush content that fills its rows to
/// the edge never hides the panel's frame; it takes no layout space, and a
/// [padding] measures from the outer edge.
///
/// Replaces the hand-rolled `DecoratedBox` + `ClipRRect` border that screens
/// were copying around every table and card.
class Panel extends StatelessWidget {
  final Widget child;

  /// Inner padding. Omit for flush content (a table that draws its own rows).
  final EdgeInsetsGeometry? padding;

  final Color? color;
  final double? radius;

  /// Clips [child] to [radius]. Keep on for flush content; harmless otherwise.
  final bool clip;

  const Panel({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius,
    this.clip = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.surface;
    final radius = this.radius ?? context.radii.radiusLarge;
    final corners = BorderRadius.circular(radius);
    Widget content = child;
    if (padding != null) content = Padding(padding: padding!, child: content);
    if (clip) content = ClipRRect(borderRadius: corners, child: content);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: corners,
        border: Border.all(color: context.colors.border),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: corners),
        child: content,
      ),
    );
  }
}
