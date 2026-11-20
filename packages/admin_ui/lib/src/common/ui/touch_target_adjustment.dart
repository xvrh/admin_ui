/// @docImport 'admin_scope.dart';
/// @docImport 'tappable.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../pointer.dart';

/// Sends a finger's near miss to the control it was meant for.
///
/// The kit's smallest controls are 24px, which a mouse hits and a finger
/// often does not. Under this widget each [TouchTarget] (every enabled
/// [Tappable] is one) takes touches as if it were at least [minSize] wide
/// and tall, centred on itself: a finger that comes down on no control, but
/// within that grown area of one, presses it too. Nothing is laid out
/// larger and nothing moves; a phone browser does the same for a page's
/// links, and Jetpack Compose for its clickables.
///
/// What is under the finger keeps its claim:
///
/// - a finger on a control presses that control, however near another is;
/// - where the finger is on something that takes a tap itself (a row that
///   opens, a text field), that takes it, and the near control does not;
/// - a finger that moves scrolls, drags or resizes what it is on, as it
///   would have: the near control only takes a tap;
/// - of two controls it could mean, the one whose edge is nearer takes it.
///
/// So in a tight row of icons each grows by half the gap to its neighbour
/// and no more, and a small button inside a row that opens gains nothing:
/// the size is not guaranteed, as it is for a control laid out larger.
///
/// Only a finger or a pen is helped. A mouse presses what it points at.
///
/// It covers the controls below it that are hit inside its own box. An
/// [AdminScope] holds one around its page, and the kit's popovers and
/// modals each hold one around their content, so an app that uses them has
/// nothing to add. Around a whole app (`MaterialApp.builder`) one covers
/// routes and overlays of the app's own as well; one inside another does
/// nothing twice.
class TouchTargetAdjustment extends StatelessWidget {
  /// The side a control's touch area is grown to where the control is
  /// smaller. Null takes it from the adjustment above, or 48, Material's
  /// touch target and Compose's.
  final double? minSize;

  /// Whether near misses are retargeted; false leaves every touch where it
  /// landed. Null follows the adjustment above, so turning one off turns
  /// off those inside it, the kit's popovers and modals among them, and is
  /// on where there is none.
  final bool? enabled;

  final Widget child;

  const TouchTargetAdjustment({
    super.key,
    this.minSize,
    this.enabled,
    required this.child,
  }) : assert(minSize == null || minSize >= 0);

  @override
  Widget build(BuildContext context) {
    final above = context
        .dependOnInheritedWidgetOfExactType<_TouchTargetAdjustmentScope>();
    final enabled = this.enabled ?? above?.enabled ?? true;
    final minSize = this.minSize ?? above?.minSize ?? 48;
    return _TouchTargetAdjustmentScope(
      enabled: enabled,
      minSize: minSize,
      child: _TouchTargetAdjustmentBox(
        enabled: enabled,
        minSize: minSize,
        child: child,
      ),
    );
  }
}

/// Wraps what a route shows in the adjustment [context] is under: a route's
/// content is built away from the page that opened it, and follows the
/// page's choice all the same. Read [context] as the route opens.
@internal
Widget Function(Widget child) carryTouchTargetAdjustment(BuildContext context) {
  final above = context
      .getInheritedWidgetOfExactType<_TouchTargetAdjustmentScope>();
  return (child) => TouchTargetAdjustment(
    enabled: above?.enabled,
    minSize: above?.minSize,
    child: child,
  );
}

/// What a [TouchTargetAdjustment] settled on, for the ones inside it.
class _TouchTargetAdjustmentScope extends InheritedWidget {
  final bool enabled;
  final double minSize;

  const _TouchTargetAdjustmentScope({
    required this.enabled,
    required this.minSize,
    required super.child,
  });

  @override
  bool updateShouldNotify(_TouchTargetAdjustmentScope old) =>
      old.enabled != enabled || old.minSize != minSize;
}

class _TouchTargetAdjustmentBox extends SingleChildRenderObjectWidget {
  final double minSize;
  final bool enabled;

  const _TouchTargetAdjustmentBox({
    required this.minSize,
    required this.enabled,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchTargetAdjustment(minSize: minSize, enabled: enabled);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    renderObject as _RenderTouchTargetAdjustment;
    renderObject
      ..minSize = minSize
      ..enabled = enabled;
  }
}

/// Marks [child] as a control a [TouchTargetAdjustment] sends near misses
/// to. Every enabled [Tappable] is one already; wrap a tap target of your
/// own, a `GestureDetector` or an `InkWell`, to have it helped the same
/// way. It draws nothing and takes no room.
class TouchTarget extends SingleChildRenderObjectWidget {
  const TouchTarget({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTouchTarget();
}

class _RenderTouchTarget extends RenderProxyBox {
  /// Hit-tests the child as if the pointer were at the point of this box
  /// nearest [position], which lies outside it.
  bool hitTestNear(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || size.isEmpty) return false;
    final inside = Offset(
      position.dx.clamp(0.0, size.width - _inset),
      position.dy.clamp(0.0, size.height - _inset),
    );
    if (!child.hitTest(result, position: inside)) return false;
    result.add(BoxHitTestEntry(this, inside));
    return true;
  }

  /// How far inside its far edges a point is taken: an edge itself is
  /// outside the box.
  static const _inset = 0.5;
}

/// The entry a near miss adds to a hit test: the adjustment itself, holding
/// what the near control would have been hit with.
class _NearMissEntry extends BoxHitTestEntry {
  _NearMissEntry(super.target, super.localPosition, this.forwarded);

  /// The near control's own entries, their transforms from the
  /// adjustment's coordinates.
  final List<HitTestEntry> forwarded;
}

class _RenderTouchTargetAdjustment extends RenderProxyBox {
  _RenderTouchTargetAdjustment({required this.minSize, required this.enabled});

  // Neither changes the layout or the paint: the next hit test reads them.
  double minSize;
  bool enabled;

  /// Whether an adjustment is looking for a near control: one inside it
  /// then leaves the looking to it.
  static bool _probing = false;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!enabled || _probing || child == null || !size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final before = result.path.length;
    final hit = super.hitTest(result, position: position);
    // A control under the finger is the one meant, and so is one a nested
    // adjustment has found.
    final claimed = result.path
        .skip(before)
        .any(
          (entry) =>
              entry.target is _RenderTouchTarget || entry is _NearMissEntry,
        );
    if (claimed) return hit;
    final target = _nearest(position);
    if (target == null) return hit;

    // What the control would be hit with, kept apart from the hit test:
    // the pointer's kind, which decides whether it is told, is known only
    // once the event comes.
    final near = BoxHitTestResult();
    near.addWithPaintTransform(
      transform: target.getTransformTo(this),
      position: position,
      hitTest: (result, local) => target.hitTestNear(result, position: local),
    );
    final forwarded = near.path.toList();
    if (forwarded.isEmpty) return hit;
    result.add(_NearMissEntry(this, position, forwarded));
    // Hit, though nothing else here may have been.
    return true;
  }

  /// The control whose grown area [position] is in and whose edge is
  /// nearest, found by hit-testing around the point.
  _RenderTouchTarget? _nearest(Offset position) {
    final reach = minSize / 2;
    if (reach <= 0) return null;
    _RenderTouchTarget? best;
    var bestDistance = double.infinity;
    final seen = <_RenderTouchTarget>{};
    _probing = true;
    try {
      for (var ring = 1; ring <= _rings; ring++) {
        final radius = reach * ring / _rings;
        for (var step = 0; step < _directions; step++) {
          final at =
              position +
              Offset.fromDirection(2 * math.pi * step / _directions, radius);
          if (!size.contains(at)) continue;
          final probe = BoxHitTestResult();
          if (!super.hitTest(probe, position: at)) continue;
          final target = probe.path
              .map((entry) => entry.target)
              .whereType<_RenderTouchTarget>()
              .firstOrNull;
          if (target == null || !seen.add(target)) continue;
          final rect = MatrixUtils.transformRect(
            target.getTransformTo(this),
            Offset.zero & target.size,
          );
          final grown = Rect.fromCenter(
            center: rect.center,
            width: math.max(rect.width, minSize),
            height: math.max(rect.height, minSize),
          );
          if (!grown.contains(position)) continue;
          final distance = _distance(rect, position);
          if (distance < bestDistance) {
            bestDistance = distance;
            best = target;
          }
        }
      }
    } finally {
      _probing = false;
    }
    return best;
  }

  /// From [point] to the nearest edge of [rect]; zero inside it.
  static double _distance(Rect rect, Offset point) {
    final dx = math.max(
      0.0,
      math.max(rect.left - point.dx, point.dx - rect.right),
    );
    final dy = math.max(
      0.0,
      math.max(rect.top - point.dy, point.dy - rect.bottom),
    );
    return math.sqrt(dx * dx + dy * dy);
  }

  /// The search around the point: [_rings] circles out to half [minSize],
  /// [_directions] points on each.
  static const _rings = 4;
  static const _directions = 12;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    super.handleEvent(event, entry);
    if (entry is! _NearMissEntry || !isCoarsePointer(event.kind)) return;
    final toHere = entry.transform;
    for (final near in entry.forwarded) {
      final toNear = near.transform;
      final transform = toNear == null
          ? toHere
          : toHere == null
          ? toNear
          : toNear.multiplied(toHere);
      near.target.handleEvent(event.transformed(transform), near);
    }
  }
}
