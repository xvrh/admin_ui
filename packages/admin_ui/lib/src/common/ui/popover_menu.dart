/// @docImport 'menu.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';
import 'popover.dart';

/// The floating card a popover menu sits in — the elevated, rounded, clipped,
/// hairline-bordered `surface` card shared by the action [Menu] and the field
/// dropdowns, rounded to the theme's menu radius.
///
/// A popover loosens to the whole screen, so the content must declare its own
/// width. Two modes:
/// - pass [width] for a fixed surface (e.g. a colour or date picker), or to
///   match the trigger via `controller.anchorWidth`;
/// - leave [width] null to size to the content between [minWidth] and [maxWidth]
///   (an action menu) — rows are sized to the widest via [IntrinsicWidth].
///
/// In a [Popover] with `showArrow`, the surface draws the arrow on its edge
/// that faces the anchor, where [Popover.placementOf] puts it, outside its
/// box and over its border. The surface must then be the content's outer
/// box, so its edge is the one the popover placed.
class PopoverMenuSurface extends StatelessWidget {
  final double? width;
  final double minWidth;
  final double maxWidth;
  final double maxHeight;

  /// Also caps the height at the room the enclosing [Popover] has beside its
  /// anchor ([Popover.availableSizeOf]), for content that scrolls — a menu,
  /// an options list — so it scrolls on the side it fits instead of covering
  /// its trigger or running off-screen. Leave false for content that cannot
  /// shrink, such as a calendar: it keeps its size and the popover clamps it
  /// into view.
  ///
  /// Beside its anchor, on [PopoverSide.start] or [PopoverSide.end], it caps
  /// the width too: a fixed [width] narrows to the room there, and a surface
  /// sized to its content narrows to it only down to [minWidth]. With less
  /// room than that on either side, as for a submenu on a phone, it keeps
  /// its width and the popover slides it over the anchor rather than crush
  /// its rows.
  final bool fitAvailableHeight;

  /// Corner radius; the theme's `radiusMenu` when null.
  final double? radius;

  final Widget child;

  const PopoverMenuSurface({
    super.key,
    this.width,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.maxHeight = 360,
    this.fitAvailableHeight = false,
    this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final request = popoverRequestOf(context);
    final available = fitAvailableHeight
        ? Popover.availableSizeOf(context)
        : null;
    final maxHeight = available == null
        ? this.maxHeight
        : math.min(this.maxHeight, available.height);
    final beside =
        request?.side == PopoverSide.start || request?.side == PopoverSide.end;
    final room = available != null && beside
        ? available.width
        : double.infinity;
    Widget inner;
    if (width case final width?) {
      inner = SizedBox(
        width: math.min(width, room),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: child,
        ),
      );
    } else {
      final widthCap = room >= minWidth ? room : double.infinity;
      inner = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: math.min(maxWidth, widthCap),
          maxHeight: maxHeight,
        ),
        child: IntrinsicWidth(child: child),
      );
    }
    final colors = context.colors;
    final shadow = context.elevation.md;
    final corners = BorderRadius.circular(radius ?? context.radii.radiusMenu);
    final edge = BorderSide(color: colors.border);
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(borderRadius: corners, boxShadow: shadow),
      child: Material(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: corners, side: edge),
        clipBehavior: Clip.antiAlias,
        child: inner,
      ),
    );
    final placement = Popover.placementOf(context);
    if (placement != null && (request?.showArrow ?? false)) {
      final overlay = context.overlayStyle;
      surface = CustomPaint(
        foregroundPainter: PopoverArrowPainter(
          placement: placement,
          textDirection: Directionality.of(context),
          width: overlay.arrowWidth,
          height: overlay.arrowHeight,
          fill: colors.surface,
          border: edge.color,
          hairline: edge.width,
          shadow: shadow,
        ),
        child: surface,
      );
    }
    return surface;
  }
}

/// The standard picker popover: a fixed-width [PopoverMenuSurface] with the
/// uniform inset that the date and colour pickers share around their body.
Widget pickerSurface({
  double width = 296,
  double inset = 12,
  double maxHeight = 360,
  required Widget child,
}) {
  return PopoverMenuSurface(
    width: width,
    maxHeight: maxHeight,
    // The body keeps its size, so where a large text size makes it taller
    // than [maxHeight] it scrolls rather than overflows.
    child: SingleChildScrollView(
      child: Padding(padding: EdgeInsets.all(inset), child: child),
    ),
  );
}
