import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Spacing rhythm for the admin UI. The scale captures the gaps already in use
/// across the field components (a roughly 2-step ramp) so new components stay
/// on the same beat instead of inventing one-off literals.
class AdminSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0; // workhorse gap
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// A gap of [size]: `Gap(AdminSpacing.md)` reads better than a bare
/// `SizedBox(width/height: 8)`.
///
/// As a child of a [Row] or a [Column] (any [Flex]) it is [size] along the
/// main axis and nothing across it, so it never makes a row taller or a
/// column wider than its other children. Anywhere else — in a [Wrap], a
/// [Stack], a [Padding] — it is a [size] square.
///
/// It reads the axis from its parent as it lays out, and nothing tells a
/// child that its parent turned: under one `Flex(direction: …)` rebuilt with
/// the other axis and handing its children the same constraints as before
/// (unbounded both ways), a Gap would keep the old axis's size. Give such a
/// Gap a key that changes with the direction, `ValueKey(direction)`. A [Row]
/// swapped for a [Column] builds new children and needs none.
class Gap extends LeafRenderObjectWidget {
  final double size;

  const Gap(this.size, {super.key}) : assert(size >= 0);

  @override
  RenderBox createRenderObject(BuildContext context) => _RenderGap(size);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderGap).extent = size;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size));
  }
}

class _RenderGap extends RenderBox {
  _RenderGap(this._extent);

  double _extent;
  set extent(double value) {
    if (value == _extent) return;
    _extent = value;
    markNeedsLayout();
  }

  /// [_extent] along a flex parent's main axis and nothing across it, or a
  /// square under any other parent.
  Size get _preferred => switch (parent) {
    RenderFlex(direction: Axis.horizontal) => Size(_extent, 0),
    RenderFlex(direction: Axis.vertical) => Size(0, _extent),
    _ => Size.square(_extent),
  };

  @override
  double computeMinIntrinsicWidth(double height) => _preferred.width;

  @override
  double computeMaxIntrinsicWidth(double height) => _preferred.width;

  @override
  double computeMinIntrinsicHeight(double width) => _preferred.height;

  @override
  double computeMaxIntrinsicHeight(double width) => _preferred.height;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.constrain(_preferred);

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => null;

  @override
  void performLayout() {
    size = constraints.constrain(_preferred);
  }
}
