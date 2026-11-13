import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// While one is mounted, a two-finger swipe does not take the browser back a
/// page: on the web, every wheel and trackpad scroll stays in the app.
///
/// Flutter's web engine lets the browser act on a scroll that no scroll view
/// under the pointer uses: one at a scroll view's edge, one over something
/// that does not scroll, one a little off a view's axis. On a Mac the
/// browser takes a sideways one as "back", so scrolling a wide table back to
/// its start often left the page. Keeping only the scrolls over such a table
/// is not enough: once one scroll anywhere on the page has reached Chrome,
/// later swipes go back even when the app keeps every event of them.
///
/// It takes each scroll event that nothing else took, wherever the pointer
/// is, a dialog or a route outside it included. Scroll views still get
/// theirs first. The browser's back button and Cmd+[ still go back. A
/// Flutter view embedded in a page that scrolls would keep that page from
/// scrolling on past the view's edge. Off the web the answer goes nowhere.
///
/// [AdminScope] mounts one. An app with a screen outside it, such as its
/// sign-in, mounts one above that screen too, around the app: a scroll that
/// reached Chrome there stays in effect after the screen is gone.
class BrowserSwipeGuard extends StatefulWidget {
  final Widget child;

  const BrowserSwipeGuard({super.key, required this.child});

  @override
  State<BrowserSwipeGuard> createState() => _BrowserSwipeGuardState();
}

class _BrowserSwipeGuardState extends State<BrowserSwipeGuard> {
  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_claimLast);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_claimLast);
    super.dispose();
  }

  // A global route runs as the binding handles the event: after every
  // listener in the tree, and before the resolver calls the first callback
  // registered. So this one is called only when nothing else registered.
  void _claimLast(PointerEvent event) {
    if (event is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(event, _keep);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void _keep(PointerSignalEvent event) {
  (event as PointerScrollEvent).respond(allowPlatformDefault: false);
}
