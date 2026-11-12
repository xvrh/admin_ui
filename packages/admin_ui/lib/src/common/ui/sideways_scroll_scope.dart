import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Below it, a swipe over something that scrolls sideways stays in the app:
/// on the web, a browser on a Mac would take it as "back".
///
/// Flutter's web engine lets the browser act on a wheel event that no scroll
/// view under the pointer can use: one at a scroll view's edge, or one a
/// little off the scroll view's axis. Chrome and Safari then give the browser
/// the rest of the swipe, and on a page that cannot scroll sideways a
/// sideways swipe means "back". So scrolling a wide table back to its start
/// often left the page.
///
/// This claims those events while the pointer is over a scroll view that
/// scrolls sideways and has room to: a wide table, a board, a tab strip that
/// overflows. Elsewhere the browser still gets them, and the back swipe still
/// works, as it does over a page that does not scroll sideways. Scroll views
/// get their events first; this takes only the ones none of them took. It is
/// a browser's `overscroll-behavior-x: contain` on each of them, which Safari
/// does not honor.
///
/// It reaches scroll views through the [ScrollConfiguration] it installs,
/// so one below that sets a [ScrollBehavior] of its own, instead of a
/// `copyWith` of the inherited one, is not covered. Off the web, the claim
/// goes nowhere. [AdminScope] mounts one.
class SidewaysScrollScope extends StatelessWidget {
  final Widget child;

  const SidewaysScrollScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _claimIfOverSideways,
    child: ScrollConfiguration(
      behavior: _MarkSideways(ScrollConfiguration.of(context)),
      child: child,
    ),
  );
}

/// The last scroll event that passed over a scroll view with room to scroll
/// sideways, as it came from the engine.
PointerEvent? _overSideways;

/// Runs after every listener below, so the claim registers only when no
/// scroll view did: the resolver calls the first callback registered.
void _claimIfOverSideways(PointerSignalEvent event) {
  final marked = identical(_overSideways, event.original ?? event);
  _overSideways = null;
  if (marked) {
    GestureBinding.instance.pointerSignalResolver.register(event, _keep);
  }
}

void _keep(PointerSignalEvent event) {
  (event as PointerScrollEvent).respond(allowPlatformDefault: false);
}

/// The inherited behavior, with a marker around each scroll view that
/// scrolls sideways. A view gets its chrome from [buildScrollbar], from
/// [buildOverscrollIndicator] or both, and some turn one off through
/// `copyWith`, so the marker goes in both: marking twice is harmless.
class _MarkSideways extends ScrollBehavior {
  final ScrollBehavior parent;

  const _MarkSideways(this.parent);

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => _marked(parent.buildScrollbar(context, child, details), details);

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => _marked(
    parent.buildOverscrollIndicator(context, child, details),
    details,
  );

  static Widget _marked(Widget child, ScrollableDetails details) {
    final controller = details.controller;
    if (axisDirectionToAxis(details.direction) != Axis.horizontal ||
        controller == null) {
      return child;
    }
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && _hasRoom(controller)) {
          _overSideways = event.original ?? event;
        }
      },
      child: child,
    );
  }

  static bool _hasRoom(ScrollController controller) => controller.positions.any(
    (p) => p.hasContentDimensions && p.maxScrollExtent > p.minScrollExtent,
  );

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      parent.getPlatform(context);

  @override
  Set<PointerDeviceKind> get dragDevices => parent.dragDevices;

  @override
  MultitouchDragStrategy getMultitouchDragStrategy(BuildContext context) =>
      parent.getMultitouchDragStrategy(context);

  @override
  Set<LogicalKeyboardKey> get pointerAxisModifiers =>
      parent.pointerAxisModifiers;

  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) =>
      parent.velocityTrackerBuilder(context);

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      parent.getScrollPhysics(context);

  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(
    BuildContext context,
  ) => parent.getKeyboardDismissBehavior(context);

  @override
  bool shouldNotify(_MarkSideways oldDelegate) =>
      parent.runtimeType != oldDelegate.parent.runtimeType ||
      parent.shouldNotify(oldDelegate.parent);
}
