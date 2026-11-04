import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../theme/tokens.dart';
import '../motion.dart';
import 'side_sheet.dart' show SideSheetSide;

/// The OverlayPortal-based modal layer: a modal that inherits from its anchor
/// rather than from above the Navigator.
///
/// A route-pushed dialog builds under the navigator overlay, so it only sees
/// InheritedWidgets mounted above MaterialApp. A [ModalAnchor] instead shows
/// its modal as an element child of the anchor: the content paints in the root
/// [Overlay] but inherits from the anchor's position, so every scope above the
/// anchor propagates into the open modal — live, not snapshotted.
///
/// Mount the anchor below the scopes the modal needs, then
/// `controller.show(...)` (or `ModalAnchor.of(context).show(...)`). Scrim,
/// focus trap + restore, Escape, back-button (via the enclosing route's local
/// history) and the return value are handled here. While a modal is open the
/// anchor's child is hidden from assistive technology; what lies outside the
/// anchor is not, so mount it around the whole page (the shell, for a modal
/// that should hide the navigation too). A modal that needs a page's own
/// scopes as well takes them from the page's context: `showAssetDetail`
/// does, through its `context`.
///
/// The modal is laid out above the keyboard, whose inset it reads from the
/// window when a `Scaffold` between the window and the anchor took it out of
/// the [MediaQuery].
class ModalAnchorController {
  _ModalAnchorState? _state;

  bool get isOpen => _state?._completer != null;

  /// Opens [builder] over the app: scrim, focus trap, Escape and tap-outside
  /// dismiss. Resolves with the value passed to [close], or null on dismiss or
  /// when the anchor unmounts. It moves over [duration], or the theme's
  /// `motion.slow` when null, easing in on `motion.enter` and out on
  /// `motion.exit`; under reduced motion it appears at once.
  /// [slideFrom] gives the side-sheet entrance
  /// (e.g. `Offset(1, 0)` with [alignment] `AlignmentDirectional.centerEnd`);
  /// its x runs in the reading direction, so it is mirrored in right-to-left
  /// text. `Offset.zero` fades. [fade] defaults to fading only when there is
  /// no slide; pass `true` to combine both (the ⌘K drop-in). The scrim is the
  /// palette's `scrim` unless [barrierColor] overrides it.
  ///
  /// One modal at a time: shown while the anchor's modal is closing, it
  /// opens once that one has gone, so a drawer or a menu can [close] and
  /// open the next modal in the same turn.
  Future<T?> show<T>({
    required WidgetBuilder builder,
    AlignmentGeometry alignment = Alignment.center,
    Offset slideFrom = Offset.zero,
    bool? fade,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration? duration,
  }) {
    final state = _state;
    assert(state != null, 'controller is not attached to a ModalAnchor');
    return state!._show<T>(
      builder: builder,
      alignment: alignment,
      slideFrom: slideFrom,
      fade: fade ?? slideFrom == Offset.zero,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      duration: duration,
    );
  }

  /// [show] with the side-sheet geometry: docked to [side], [width] wide
  /// (capped to the screen), sliding in over `motion.slow` like
  /// `showSideSheet`.
  Future<T?> showSheet<T>({
    required WidgetBuilder builder,
    SideSheetSide side = SideSheetSide.end,
    double width = 420,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    final end = side == SideSheetSide.end;
    return show<T>(
      alignment: end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      slideFrom: end ? const Offset(1, 0) : const Offset(-1, 0),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (context) => SizedBox(
        width: math.min(width, MediaQuery.sizeOf(context).width),
        height: double.infinity,
        child: Builder(builder: builder),
      ),
    );
  }

  /// Plays the exit transition and resolves the pending [show] with [result].
  void close([Object? result]) => _state?._close(result);
}

/// Hosts portal modals for [child]'s subtree. The modal content sees exactly
/// the InheritedWidgets visible at this widget's position — place the anchor
/// below every scope the modal should consume.
class ModalAnchor extends StatefulWidget {
  /// The handle for opening modals on this anchor. Omit it when descendants
  /// reach the anchor through [of] instead of holding the controller.
  final ModalAnchorController? controller;

  final Widget child;

  const ModalAnchor({super.key, this.controller, required this.child});

  /// The nearest enclosing anchor. Note the modal inherits from the *anchor's*
  /// position, not from [context].
  static ModalAnchorController of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_ModalAnchorInherited>();
    if (inherited == null) {
      throw FlutterError(
        'ModalAnchor.of() was called with a context that has no ModalAnchor '
        'above it.\n'
        'Modal-opening widgets (asset fields, pickers, …) show their modals '
        'on the nearest anchor: mount a ModalAnchor below every scope the '
        'modal content should see.',
      );
    }
    return inherited.controller;
  }

  static final _openCount = ValueNotifier<int>(0);
  static final _openCounts = Expando<ValueNotifier<int>>();

  static ValueNotifier<int> _openCountOn(Route<Object?> route) =>
      _openCounts[route] ??= ValueNotifier(0);

  /// How many portal modals are open on [route]: shown by an anchor inside
  /// it, each holding the route's back with a [LocalHistoryEntry].
  ///
  /// Pop coordination hook: [ModalRoute.popDisposition] consults [PopScope]
  /// vetoes *before* local history, so a blocking guard on the page (e.g.
  /// `UnsavedChangesGuard`) must stand down while this is non-zero, or back
  /// would prompt instead of closing the modal. Counted per route, so a
  /// modal in another window or on another route leaves the guard alone.
  static ValueListenable<int> openCountOn(Route<Object?> route) =>
      _openCountOn(route);

  @override
  State<ModalAnchor> createState() => _ModalAnchorState();
}

class _ModalAnchorState extends State<ModalAnchor>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  late final _anim = AnimationController(vsync: this);
  late final _curved = CurvedAnimation(
    parent: _anim,
    curve: context.motion.enter,
    reverseCurve: context.motion.exit,
  );

  Completer<Object?>? _completer;
  WidgetBuilder? _builder;
  AlignmentGeometry _alignment = Alignment.center;
  Offset _slideFrom = Offset.zero;
  bool _fade = true;
  bool _dismissible = true;
  Color? _barrierColor;
  bool _closing = false;
  FocusNode? _restoreTo;
  LocalHistoryEntry? _historyEntry;
  ValueNotifier<int>? _routeOpenCount;

  ModalAnchorController? _fallback;
  ModalAnchorController get _controller =>
      widget.controller ?? (_fallback ??= ModalAnchorController());

  @override
  void initState() {
    super.initState();
    _controller._state = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    _curved
      ..curve = motion.enter
      ..reverseCurve = motion.exit;
  }

  @override
  void didUpdateWidget(ModalAnchor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _fallback)?._state = null;
      _controller._state = this;
    }
  }

  @override
  void dispose() {
    _controller._state = null;
    // A dying anchor takes its modal with it; awaiting callers must not hang.
    // Completing first makes the entry's onRemove re-entry a no-op.
    if (_completer != null) {
      _completer!.complete(null);
      _completer = null;
      _countClosed();
    }
    _removeHistory();
    _curved.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _removeHistory() {
    final entry = _historyEntry;
    _historyEntry = null;
    entry?.remove();
  }

  void _countOpen(Route<Object?>? route) {
    ModalAnchor._openCount.value++;
    if (route != null) {
      _routeOpenCount = ModalAnchor._openCountOn(route)..value += 1;
    }
  }

  void _countClosed() {
    ModalAnchor._openCount.value--;
    _routeOpenCount?.value--;
    _routeOpenCount = null;
  }

  Future<T?> _show<T>({
    required WidgetBuilder builder,
    required AlignmentGeometry alignment,
    required Offset slideFrom,
    required bool fade,
    required bool barrierDismissible,
    required Color? barrierColor,
    required Duration? duration,
  }) {
    final leaving = _completer;
    if (leaving != null && _closing) {
      return leaving.future.then(
        (_) => mounted
            ? _show<T>(
                builder: builder,
                alignment: alignment,
                slideFrom: slideFrom,
                fade: fade,
                barrierDismissible: barrierDismissible,
                barrierColor: barrierColor,
                duration: duration,
              )
            : null,
      );
    }
    assert(_completer == null, 'this anchor already has an open modal');
    // Release-mode safety: a second show takes over — the first caller's
    // future resolves null instead of leaking.
    if (_completer != null) {
      _completer!.complete(null);
      _completer = null;
      _countClosed();
      _removeHistory();
    }
    final completer = Completer<Object?>();
    _completer = completer;
    _builder = builder;
    _alignment = alignment;
    _slideFrom = slideFrom;
    _fade = fade;
    _dismissible = barrierDismissible;
    _barrierColor = barrierColor;
    _closing = false;
    _restoreTo = FocusManager.instance.primaryFocus;
    _anim.duration = duration == null
        ? context.motion.slow
        : motionDuration(context, duration);
    // Android back (and anything else funnelled through Navigator.maybePop)
    // closes the modal, not the page under it.
    final route = ModalRoute.of(context);
    if (route != null) {
      route.addLocalHistoryEntry(
        _historyEntry = LocalHistoryEntry(
          impliesAppBarDismissal: false,
          onRemove: () {
            _historyEntry = null;
            _close(null);
          },
        ),
      );
    }
    setState(() {});
    _portal.show();
    _anim.forward(from: 0);
    _countOpen(route);
    return completer.future.then((v) => v as T?);
  }

  Future<void> _close(Object? result) async {
    final completer = _completer;
    if (completer == null || _closing) return;
    _closing = true;
    _removeHistory();
    await _anim.reverse();
    // The anchor may have been disposed mid-exit (dispose resolved the future).
    if (!mounted || completer.isCompleted) return;
    _portal.hide();
    setState(() {
      _completer = null;
      _builder = null;
    });
    completer.complete(result);
    _countClosed();
    final restore = _restoreTo;
    _restoreTo = null;
    if (restore != null && restore.context != null) restore.requestFocus();
  }

  Widget _overlay(BuildContext context) {
    final slide = _slideFrom != Offset.zero;
    // FocusScope bounds Tab traversal to the modal; the traversal group pins
    // the policy. The autofocus node takes focus on open (so Escape works
    // immediately) but is skipped by Tab, which lands on real content. Escape
    // is bound above the scope, so it still closes the modal once focus falls
    // back to the scope itself (its focused descendant removed or hidden).
    Widget content = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _close(null),
      },
      child: FocusScope(
        child: FocusTraversalGroup(
          child: Focus(
            autofocus: true,
            skipTraversal: true,
            // Same shim as showModal: keeps the surface clickable when it
            // floats over a web platform view (an embedded iframe, say).
            child: PointerInterceptor(child: Builder(builder: _builder!)),
          ),
        ),
      ),
    );
    content = Align(alignment: _alignment, child: content);
    if (slide) {
      content = SlideTransition(
        position: Tween(begin: _slideFrom, end: Offset.zero).animate(_curved),
        textDirection: Directionality.of(context),
        child: content,
      );
    }
    if (_fade) {
      content = FadeTransition(opacity: _curved, child: content);
    }
    // A route of its own to assistive technology, named by its content (a
    // Modal, a SideSheet). The overlay's semantics join the tree at the
    // anchor, not above the page, so the barrier's blocking must stay inside
    // this container (outside it, it blanks the modal too); build() hides the
    // page instead.
    return Semantics(
      container: true,
      scopesRoute: true,
      explicitChildNodes: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _curved,
              child: ModalBarrier(
                dismissible: _dismissible,
                onDismiss: () => _close(null),
                color: _barrierColor ?? context.colors.scrim,
                semanticsLabel: MaterialLocalizations.of(context)
                    .modalBarrierDismissLabel,
              ),
            ),
          ),
          Positioned.fill(child: _AboveKeyboard(child: content)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ModalAnchorInherited(
      controller: _controller,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _overlay,
        overlayLocation: OverlayChildLocation.rootOverlay,
        child: ExcludeSemantics(
          excluding: _completer != null,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Lays [child] out above the keyboard, as a `Scaffold` does its body: below
/// it, the [MediaQuery] has no bottom inset left. The inset is the larger of
/// the [MediaQuery]'s and the window's, since a modal covers the window
/// while its anchor may sit under a `Scaffold` that took the inset out.
class _AboveKeyboard extends StatefulWidget {
  final Widget child;

  const _AboveKeyboard({required this.child});

  @override
  State<_AboveKeyboard> createState() => _AboveKeyboardState();
}

class _AboveKeyboardState extends State<_AboveKeyboard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The window's inset changed, which the [MediaQuery] here may not show.
  @override
  void didChangeMetrics() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final window = view.viewInsets.bottom / view.devicePixelRatio;
    final keyboard = math.max(MediaQuery.viewInsetsOf(context).bottom, window);
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: widget.child,
      ),
    );
  }
}

class _ModalAnchorInherited extends InheritedWidget {
  final ModalAnchorController controller;

  const _ModalAnchorInherited({required this.controller, required super.child});

  @override
  bool updateShouldNotify(_ModalAnchorInherited old) =>
      controller != old.controller;
}
