import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'button.dart';
import 'icon_action.dart';
import 'severity.dart';
import 'spinner.dart';

/// A transient notification. For an in-flow message use an `Alert`; for a
/// blocking choice a `Modal`.
///
/// A toast is data handed to [ToastScopeState.show], which builds its card,
/// so its action is data too: an [actionLabel] and an [onAction] callback,
/// drawn as a small ghost button. A widget such as an `Alert` takes its
/// action as a widget instead.
///
/// Every toast shows a close button, whether or not [onDismiss] is set: the
/// one exception to the kit's rule that an overlay shows its close button
/// exactly when it has an `onDismiss`, since a toast must always be
/// dismissible.
class Toast {
  final String message;

  /// A bold line above [message], which then reads as its description, in
  /// the secondary text colour.
  final String? title;

  final Severity severity;

  /// Optional inline action (e.g. "Undo").
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The key of the action button, to find it by in a test.
  final Key? actionKey;

  /// Replaces the severity's leading glyph.
  final IconData? icon;

  /// Whether the leading glyph shows; false starts the message at the
  /// padding.
  final bool showIcon;

  /// Whether a spinner stands in for the leading glyph: work under way,
  /// from [Toast.loading].
  final bool loading;

  /// Called once, when the toast starts to leave, with why it left.
  final ValueChanged<ToastDismissReason>? onDismiss;

  final Duration? _duration;

  const Toast(
    this.message, {
    this.title,
    this.severity = Severity.info,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.icon,
    this.showIcon = true,
    this._duration = _automatic,
    this.onDismiss,
  }) : loading = false;

  /// Work under way: a spinner in place of the glyph, kept until it is
  /// updated or closed. Raise it with [ToastScopeState.show] and update the
  /// handle once the work is done, or let [ToastScopeState.promise] do both.
  const Toast.loading(this.message, {this.title})
    : severity = Severity.info,
      actionLabel = null,
      onAction = null,
      actionKey = null,
      icon = null,
      showIcon = true,
      loading = true,
      onDismiss = null,
      _duration = null;

  const Toast._copy(
    this.message, {
    required this.title,
    required this.severity,
    required this.actionLabel,
    required this.onAction,
    required this.actionKey,
    required this.icon,
    required this.showIcon,
    required this.loading,
    required this.onDismiss,
    required this._duration,
  });

  /// Time on screen before auto-dismiss, counted only while the toast is
  /// neither hovered, holding focus nor being swiped; null keeps it until it
  /// is closed.
  ///
  /// Unless given, 4s — or 10s for a toast carrying an action or reporting a
  /// danger, which the reader may need time to act on. A [Toast.loading] is
  /// kept.
  Duration? get duration => identical(_duration, _automatic)
      ? (actionLabel != null || severity == Severity.danger
            ? const Duration(seconds: 10)
            : const Duration(seconds: 4))
      : _duration;

  /// Whether the toast stays until closed while assistive technology is
  /// driving the app — an action or a danger could not otherwise be relied
  /// on to still be there once reached.
  bool get _stickyForAssistiveTech =>
      actionLabel != null || severity == Severity.danger;

  Toast _withActionLabel(String label) => Toast._copy(
    message,
    title: title,
    severity: severity,
    actionLabel: label,
    onAction: onAction,
    actionKey: actionKey,
    icon: icon,
    showIcon: showIcon,
    loading: loading,
    onDismiss: onDismiss,
    duration: _duration,
  );
}

/// Stands for "no duration given" so [Toast.duration] can tell it apart from
/// an explicit null (sticky).
const _automatic = Duration(microseconds: -1);

/// Why a toast left, as [Toast.onDismiss] and [ToastHandle.dismissed] report
/// it.
enum ToastDismissReason {
  /// Its [Toast.duration] ran out.
  timeout,

  /// The reader closed it: its close button, or Escape while it held focus.
  closed,

  /// The reader pressed its action.
  action,

  /// The reader swiped it off toward the side edge.
  swiped,

  /// The app took it down: [ToastHandle.dismiss],
  /// [ToastScopeState.dismissAll], or its [ToastScope] going away.
  dismissed,
}

/// Where a [ToastScope] stacks its toasts, inside the safe area and 16px
/// from its edges.
///
/// Start and end follow the text direction: [topEnd] is the top right
/// corner in a left-to-right app and the top left in a right-to-left one.
enum ToastPosition {
  topStart,
  topCenter,
  topEnd,
  bottomStart,
  bottomCenter,
  bottomEnd;

  bool get _top => switch (this) {
    topStart || topCenter || topEnd => true,
    bottomStart || bottomCenter || bottomEnd => false,
  };

  _Edge get _edge => switch (this) {
    topStart || bottomStart => _Edge.start,
    topCenter || bottomCenter => _Edge.center,
    topEnd || bottomEnd => _Edge.end,
  };
}

enum _Edge { start, center, end }

/// A toast raised by [ToastScopeState.show]: swap its content, take it down
/// early, or wait for it to leave.
abstract interface class ToastHandle {
  /// Whether the toast is still waiting its turn or on screen: false once it
  /// has started to leave.
  bool get isActive;

  /// Completes once, with why the toast left, as it starts to leave: before
  /// its exit animation, and at once for a toast still waiting its turn.
  Future<ToastDismissReason> get dismissed;

  /// Swaps the toast's content for [toast] in place: the same card, with no
  /// exit or entry animation. Its countdown starts over from [toast]'s
  /// duration, and a screen reader hears it again when its severity or text
  /// changed. Does nothing once the toast has started to leave.
  void update(Toast toast);

  /// Takes the toast down, with [ToastDismissReason.dismissed]. Does nothing
  /// once it has started to leave.
  void dismiss();
}

/// Hosts the toast stack over [child], at [position]. Call
/// `ToastScope.of(context).show(const Toast(...))` from anywhere below it.
///
/// Mount it in `MaterialApp.builder`, above the Navigator:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => ToastScope(child: child!),
///   ...
/// )
/// ```
///
/// There the stack paints over every route — dialogs and side sheets
/// included, so a toast raised from a confirm stays visible and clickable —
/// and [of] resolves from any route's context. Mounted inside a page instead,
/// it still works but only covers that page, under any dialog.
///
/// The newest toast sits nearest the edge the stack is anchored to: on top
/// in a top position, at the bottom in a bottom one. The stack shows the
/// newest [maxVisible] toasts; older ones wait, their timers stopped, until
/// a slot frees up. A toast slides in from the side edge it is nearest, or
/// from the top or bottom edge when centred, and is swiped off toward that
/// side edge (either way when centred).
///
/// Above the Navigator the toasts sit outside every route's Tab cycle, so F8
/// moves keyboard focus to them (as in Radix); Escape closes the toast
/// holding focus and hands focus back to where it was, as the focused toast
/// leaving does.
class ToastScope extends StatefulWidget {
  final Widget child;

  /// How many toasts show at once.
  final int maxVisible;

  /// The corner or edge the stack is anchored to.
  final ToastPosition position;

  /// Room kept clear between the stack and the safe area's edges, on top of
  /// its 16px gutter: `EdgeInsets.only(top: 56)` opens a top stack below a
  /// 56px app bar rather than over it.
  final EdgeInsetsGeometry margin;

  const ToastScope({
    super.key,
    required this.child,
    this.maxVisible = 3,
    this.position = ToastPosition.topEnd,
    this.margin = EdgeInsets.zero,
  }) : assert(maxVisible > 0);

  static ToastScopeState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw FlutterError(
        'ToastScope.of() was called with a context that has no ToastScope '
        'above it.\n'
        'Mount a ToastScope in MaterialApp.builder so every route can reach '
        'it.',
      );
    }
    return state;
  }

  /// The nearest scope's state, or null when no [ToastScope] is above
  /// [context].
  static ToastScopeState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ToastScopeMarker>()?.state;

  @override
  State<ToastScope> createState() => ToastScopeState();
}

class ToastScopeState extends State<ToastScope> {
  /// Oldest first.
  final List<_Entry> _entries = [];
  int _seq = 0;

  /// Parent of the toasts' controls: F8 lands on its first one.
  final _stack = FocusNode(
    debugLabel: 'Toasts',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// Where focus was before F8, to go back to.
  FocusNode? _returnTo;

  /// Raises [toast], and returns the handle that updates or dismisses it.
  ToastHandle show(Toast toast) {
    final entry = _Entry(this, ValueKey(_seq++), toast);
    setState(() => _entries.add(entry));
    return entry;
  }

  /// Takes down every toast, those waiting their turn included, with
  /// [ToastDismissReason.dismissed].
  void dismissAll() {
    for (final entry in [..._entries]) {
      _dismiss(entry, ToastDismissReason.dismissed);
    }
  }

  /// Shows [loading] while [future] runs, then updates it in place to
  /// [success] with the value or to [error] with the error, and completes as
  /// [future] does: with its value, or failing with its error, which the
  /// caller then handles.
  ///
  /// When the reader closed the loading toast in the meantime, the outcome
  /// is raised as a new toast: a failure must still be seen.
  Future<T> promise<T>(
    Future<T> future, {
    required Toast loading,
    required Toast Function(T value) success,
    required Toast Function(Object error) error,
  }) async {
    final handle = show(loading);
    void settle(Toast toast) {
      if (handle.isActive) {
        handle.update(toast);
      } else if (mounted) {
        show(toast);
      }
    }

    final T value;
    try {
      value = await future;
    } on Object catch (e) {
      settle(error(e));
      rethrow;
    }
    settle(success(value));
    return value;
  }

  /// Shows [toast] with an undo action, and runs [commit] only once the
  /// toast leaves without it being pressed: when its time runs out, it is
  /// closed or swiped, or the app takes it down. Pressing the action calls
  /// [onUndo] instead, and [commit] never runs.
  ///
  /// The action is [Toast.actionLabel], or the localized "Undo" when the
  /// toast has none. Completes with true once [commit] has run, false when
  /// undone, and fails as [commit] does.
  ///
  /// This is the deferred half of an undoable change: whatever the change
  /// hides from the screen is hidden before this is called, and [commit]
  /// makes it real. Where a `CollectionController` hides the rows and takes
  /// them back itself, its own `undoable` holds the commit instead: show the
  /// toast and hand it the handle's dismissal as `undone`.
  ///
  /// ```dart
  /// await controller.undoable(
  ///   update: (rows) => rows.where((r) => r.id != page.id).toList(),
  ///   commit: () => api.delete(page.id),
  ///   undone: ToastScope.of(context)
  ///       .show(Toast('Page deleted.', actionLabel: l10n.inputs.undo))
  ///       .dismissed
  ///       .then((reason) => reason == ToastDismissReason.action),
  /// );
  /// ```
  Future<bool> undoable(
    Toast toast, {
    required Future<void> Function() commit,
    VoidCallback? onUndo,
  }) async {
    final shown = toast.actionLabel != null
        ? toast
        : toast._withActionLabel(context.adminL10n.inputs.undo);
    final reason = await show(shown).dismissed;
    if (reason == ToastDismissReason.action) {
      onUndo?.call();
      return false;
    }
    await commit();
    return true;
  }

  /// The toasts on screen, oldest first: the newest [maxVisible] still
  /// active, and those leaving, which keep their card until their exit is
  /// over.
  List<_Entry> get _visible {
    var room = widget.maxVisible;
    return [
      for (final entry in _entries.reversed)
        if (!entry.isActive || room-- > 0) entry,
    ].reversed.toList();
  }

  void _update(_Entry entry, Toast toast) {
    if (!entry.isActive || !mounted) return;
    setState(() {
      entry.toast = toast;
      entry.revision++;
    });
  }

  void _dismiss(_Entry entry, ToastDismissReason reason) {
    if (!entry.isActive) return;
    // One waiting its turn has no card to animate out.
    final shown = mounted && _visible.contains(entry);
    entry._leave(reason);
    if (mounted) {
      setState(() {
        if (!shown) _entries.remove(entry);
      });
    }
    entry.toast.onDismiss?.call(reason);
  }

  void _remove(_Entry entry) {
    if (mounted) setState(() => _entries.remove(entry));
  }

  @override
  void dispose() {
    _stack.dispose();
    for (final entry in _entries) {
      if (!entry.isActive) continue;
      entry._leave(ToastDismissReason.dismissed);
      // Not while the tree is being torn down.
      final onDismiss = entry.toast.onDismiss;
      if (onDismiss != null) {
        scheduleMicrotask(() => onDismiss(ToastDismissReason.dismissed));
      }
    }
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.f8 && !_stack.hasFocus) {
      final first = _stack.traversalDescendants.firstOrNull;
      if (first == null) return KeyEventResult.ignored;
      _returnTo = FocusManager.instance.primaryFocus;
      first.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _stack.hasFocus) {
      _giveFocusBack();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _giveFocusBack() {
    final to = _returnTo;
    _returnTo = null;
    if (to != null && to.context != null) to.requestFocus();
  }

  /// A toast holding focus left: unless focus went somewhere on purpose, it
  /// fell back to a scope, so return it to where F8 took it from.
  void _onStackFocus(bool focused) {
    if (focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _stack.hasFocus) return;
      if (FocusManager.instance.primaryFocus is FocusScopeNode) {
        _giveFocusBack();
      } else {
        _returnTo = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToastScopeMarker(
      state: this,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            // Its own overlay, beside the child rather than around it: the
            // toasts' tooltips have somewhere to open even above a Navigator,
            // and the app's root overlay stays the Navigator's.
            Positioned.fill(
              child: Focus(
                focusNode: _stack,
                includeSemantics: false,
                onFocusChange: _onStackFocus,
                child: Overlay.wrap(
                  child: _ToastStack(
                    position: widget.position,
                    margin: widget.margin,
                    children: [
                      for (final e in _visible)
                        _ToastCard(
                          key: e.key,
                          toast: e.toast,
                          revision: e.revision,
                          leaving: e.reason,
                          position: widget.position,
                          onDismiss: (reason) => _dismiss(e, reason),
                          onGone: () => _remove(e),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToastScopeMarker extends InheritedWidget {
  final ToastScopeState state;

  const _ToastScopeMarker({required this.state, required super.child});

  @override
  bool updateShouldNotify(_ToastScopeMarker old) => state != old.state;
}

class _Entry implements ToastHandle {
  final ToastScopeState _scope;
  final Key key;
  Toast toast;

  /// Bumped by every [update], so the card starts its countdown over.
  int revision = 0;

  ToastDismissReason? reason;
  final _done = Completer<ToastDismissReason>();

  _Entry(this._scope, this.key, this.toast);

  @override
  bool get isActive => reason == null;

  @override
  Future<ToastDismissReason> get dismissed => _done.future;

  @override
  void update(Toast toast) => _scope._update(this, toast);

  @override
  void dismiss() => _scope._dismiss(this, ToastDismissReason.dismissed);

  void _leave(ToastDismissReason reason) {
    this.reason = reason;
    _done.complete(reason);
  }
}

/// The toasts, stacked from [position] inside the safe area less [margin],
/// the newest nearest its edge. As wide as a toast should be (356) and never
/// wider than the space less its gutters; taps outside the cards fall
/// through to the app.
class _ToastStack extends StatelessWidget {
  final ToastPosition position;
  final EdgeInsetsGeometry margin;

  /// Oldest first.
  final List<Widget> children;

  const _ToastStack({
    required this.position,
    required this.margin,
    required this.children,
  });

  static const _gutter = AdminSpacing.xl;
  static const _width = 356.0;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final top = position._top;
    return SafeArea(
      child: Padding(
        padding: margin,
        child: LayoutBuilder(
          builder: (context, box) {
            final width = math.max(
              0.0,
              math.min(_width, box.maxWidth - 2 * _gutter),
            );
            final column = Align(
              alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
              child: SingleChildScrollView(
                primary: false,
                // Overflowing, a bottom stack keeps its newest in view.
                reverse: !top,
                // The gutter is inside the scroll view, whose clip then leaves
                // the cards' shadows whole; only the cards take taps.
                padding: const EdgeInsets.all(_gutter),
                hitTestBehavior: HitTestBehavior.deferToChild,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: top ? children.reversed.toList() : children,
                ),
              ),
            );
            final span = width + 2 * _gutter;
            return Stack(
              children: [
                switch (position._edge) {
                  _Edge.start => PositionedDirectional(
                    top: 0,
                    start: 0,
                    bottom: 0,
                    width: span,
                    child: column,
                  ),
                  _Edge.center => PositionedDirectional(
                    top: 0,
                    start: (box.maxWidth - span) / 2,
                    bottom: 0,
                    width: span,
                    child: column,
                  ),
                  _Edge.end => PositionedDirectional(
                    top: 0,
                    end: 0,
                    bottom: 0,
                    width: span,
                    child: column,
                  ),
                },
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  final Toast toast;
  final int revision;

  /// Why the toast is leaving, once it is.
  final ToastDismissReason? leaving;

  final ToastPosition position;

  /// Asks the scope to take the toast down.
  final ValueChanged<ToastDismissReason> onDismiss;

  /// The exit animation is over.
  final VoidCallback onGone;

  const _ToastCard({
    super.key,
    required this.toast,
    required this.revision,
    required this.leaving,
    required this.position,
    required this.onDismiss,
    required this.onGone,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  /// Slides and fades the card in, over the theme's `motion.slow`, opening
  /// its slot in the stack as it comes; and out again as it leaves. At once
  /// under reduced motion.
  late final AnimationController _anim = AnimationController(vsync: this);
  late final _curve = CurvedAnimation(
    parent: _anim,
    curve: context.motion.enter,
    reverseCurve: context.motion.exit,
  );

  /// How far the card is swiped, in logical pixels to the right.
  late final AnimationController _drag = AnimationController.unbounded(
    vsync: this,
  );

  /// The countdown's granularity: the time left is kept to this step, so a
  /// pause resumes with what remained rather than starting over.
  static const _tick = Duration(milliseconds: 100);

  /// A swipe past this share of the card's width dismisses it on release.
  static const _swipeThreshold = 0.4;

  /// A release this fast toward the edge dismisses whatever the distance, in
  /// logical pixels per second (as Dismissible's fling).
  static const _flingVelocity = 700.0;

  Timer? _timer;
  Duration? _remaining;
  bool _hovered = false;
  bool _focused = false;
  bool _dragging = false;
  bool _leaving = false;

  /// The card's width when the swipe began.
  double _extent = 0;

  /// The direction a swipe dismissed the card in: -1 left, 1 right.
  double? _swipedToward;

  @override
  void initState() {
    super.initState();
    _remaining = widget.toast.duration;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    _anim.duration = motion.slow;
    _curve
      ..curve = motion.enter
      ..reverseCurve = motion.exit;
    if (_anim.isDismissed && !_leaving) {
      // A card first built for a toast already leaving has nothing to show.
      if (widget.leaving case final reason?) {
        _leave(reason);
      } else {
        _anim.forward();
      }
    }
    _sync();
  }

  @override
  void didUpdateWidget(_ToastCard old) {
    super.didUpdateWidget(old);
    if (widget.revision != old.revision) {
      _remaining = widget.toast.duration;
      _timer?.cancel();
      _timer = null;
      _reannounce(old.toast, widget.toast);
    }
    if (widget.leaving case final reason? when !_leaving) _leave(reason);
    _sync();
  }

  /// The card is a live region, so new words are read out as its label
  /// changes. The same words in a new severity leave the label as it was:
  /// say them again.
  void _reannounce(Toast old, Toast now) {
    if (old.severity == now.severity ||
        old.title != now.title ||
        old.message != now.message) {
      return;
    }
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        [?now.title, now.message].join('\n'),
        Directionality.of(context),
      ),
    );
  }

  bool get _sticky =>
      _remaining == null ||
      (widget.toast._stickyForAssistiveTech &&
          MediaQuery.accessibleNavigationOf(context));

  /// Runs the countdown unless the toast is leaving, sticky, hovered,
  /// focused or being swiped.
  void _sync() {
    final run = !_leaving && !_sticky && !_hovered && !_focused && !_dragging;
    if (!run) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(_tick, (_) {
        _remaining = _remaining! - _tick;
        if (_remaining! <= Duration.zero) {
          _timer?.cancel();
          _timer = null;
          widget.onDismiss(ToastDismissReason.timeout);
        }
      });
    }
  }

  void _setHovered(bool value) {
    _hovered = value;
    _sync();
  }

  void _setFocused(bool value) {
    _focused = value;
    _sync();
  }

  Future<void> _leave(ToastDismissReason reason) async {
    _leaving = true;
    _dragging = false;
    _sync();
    final motion = context.motion;
    if (_swipedToward case final toward?) {
      unawaited(
        _drag.animateTo(
          toward * (_extent + _ToastStack._gutter),
          duration: motion.slow,
          curve: motion.exit,
        ),
      );
    }
    await _anim.reverse();
    if (mounted) widget.onGone();
  }

  /// Whether a swipe may take the card left, and right: toward the side edge
  /// its stack is nearest, either way when centred.
  (bool, bool) get _swipeable {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return switch (widget.position._edge) {
      _Edge.center => (true, true),
      _Edge.start => (!rtl, rtl),
      _Edge.end => (rtl, !rtl),
    };
  }

  void _onDragStart(DragStartDetails details) {
    if (_leaving) return;
    _dragging = true;
    _extent = context.size?.width ?? 0;
    _drag.stop();
    _sync();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final (left, right) = _swipeable;
    final dx = _drag.value + details.primaryDelta!;
    _drag.value = (dx < 0 && !left) || (dx > 0 && !right) ? 0.0 : dx;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final (left, right) = _swipeable;
    final dx = _drag.value;
    final velocity = details.primaryVelocity ?? 0;
    double? toward;
    if (dx != 0 && dx.abs() >= _swipeThreshold * _extent) {
      toward = dx.sign;
    } else if (velocity.abs() >= _flingVelocity &&
        (velocity < 0 ? left : right) &&
        (dx == 0 || dx.sign == velocity.sign)) {
      toward = velocity.sign;
    }
    if (toward != null) {
      _swipedToward = toward;
      widget.onDismiss(ToastDismissReason.swiped);
    } else {
      _springBack();
    }
    _sync();
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _springBack();
    _sync();
  }

  void _springBack() {
    final motion = context.motion;
    unawaited(
      _drag.animateTo(0, duration: motion.medium, curve: motion.standard),
    );
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss(ToastDismissReason.closed);
    }
    // The scope hands focus back.
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _anim.dispose();
    _drag.dispose();
    super.dispose();
  }

  /// Where the card slides in from, as a share of its size: the side edge
  /// its stack is nearest, or the top or bottom edge when centred.
  Offset _enterFrom() {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const shift = 0.08;
    return switch (widget.position._edge) {
      _Edge.start => Offset(rtl ? shift : -shift, 0),
      _Edge.end => Offset(rtl ? -shift : shift, 0),
      _Edge.center => Offset(0, widget.position._top ? -0.5 : 0.5),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = severityStyleOf(context, widget.toast.severity);
    final corners = BorderRadius.circular(context.radii.radiusMenu);
    final top = widget.position._top;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: context.elevation.md,
      ),
      child: Material(
        color: context.colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: corners,
          side: BorderSide(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: style.accent),
              Expanded(child: _content(context, style)),
            ],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _curve,
      // The slot opens and closes with the card, from the stack's edge side,
      // so the others move rather than jump; the card paints whole over it.
      builder: (context, child) => Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: _curve.value,
        child: child,
      ),
      child: Padding(
        padding: top
            ? const EdgeInsets.only(bottom: AdminSpacing.md)
            : const EdgeInsets.only(top: AdminSpacing.md),
        child: FadeTransition(
          opacity: _curve,
          child: SlideTransition(
            position: _swipedToward != null
                ? const AlwaysStoppedAnimation(Offset.zero)
                : Tween(begin: _enterFrom(), end: Offset.zero).animate(_curve),
            child: AnimatedBuilder(
              animation: _drag,
              builder: (context, child) {
                final dx = _drag.value;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Opacity(
                    opacity: _extent > 0
                        ? (1 - dx.abs() / _extent).clamp(0.0, 1.0)
                        : 1,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                onHorizontalDragCancel: _onDragCancel,
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  child: Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onFocusChange: _setFocused,
                    onKeyEvent: _onKey,
                    child: MouseRegion(
                      onEnter: (_) => _setHovered(true),
                      onExit: (_) => _setHovered(false),
                      child: card,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, SeverityStyle style) {
    final toast = widget.toast;
    const close = IconActionSize.inline;
    final icon = context.iconSizes.lg;
    final hasAction = toast.actionLabel != null;
    final title = toast.title;
    final firstLine = title == null
        ? context.type.body
        : context.type.bodyStrong;
    final action =
        context.sizes.small + textGrowthOf(context, context.type.buttonSmall);
    final line = lineHeightOf(context, firstLine);
    // Everything centres on one band, the height of the tallest of the
    // controls and the first line of text; the icon keeps 12px from the
    // card's top edge and from the accent, so a toast is as tall with an
    // action as without while the action fits the band.
    final band = math.max(math.max(close.box, line), hasAction ? action : 0);
    double centre(double height) => (band - height) / 2;
    // A band taller than the icon and its insets, as at a large text size,
    // takes the room itself.
    final inset = math.max(0.0, AdminSpacing.lg - centre(icon));
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg,
        inset,
        // The close glyph, not its hit box, keeps 12px from the edge.
        AdminSpacing.lg - (close.box - close.glyph) / 2,
        inset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toast.showIcon) ...[
            Padding(
              padding: EdgeInsets.only(top: centre(icon)),
              child: toast.loading
                  ? SizedBox.square(
                      dimension: icon,
                      child: Center(
                        child: Spinner(
                          // The glyph's drawn circle, 20 of its 24 units, so
                          // the ring reads as the icon it stands in for.
                          size: icon * 20 / 24,
                          color: style.foreground,
                          // The card is the live region, and reads its
                          // message.
                          announce: false,
                        ),
                      ),
                    )
                  : Icon(
                      toast.icon ?? style.icon,
                      size: icon,
                      color: style.foreground,
                    ),
            ),
            const Gap(AdminSpacing.md),
          ],
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: centre(line)),
              child: title == null
                  ? Text(toast.message, style: firstLine)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: firstLine),
                        const Gap(AdminSpacing.xxs),
                        Text(
                          toast.message,
                          style: context.type.body.copyWith(
                            color: context.colors.foregroundSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (hasAction) ...[
            const Gap(AdminSpacing.sm),
            Padding(
              padding: EdgeInsets.only(top: centre(action)),
              child: Button.ghost(
                toast.actionLabel!,
                key: toast.actionKey,
                size: ControlSize.small,
                onPressed: () {
                  toast.onAction?.call();
                  widget.onDismiss(ToastDismissReason.action);
                },
              ),
            ),
          ],
          const Gap(AdminSpacing.xs),
          Padding(
            padding: EdgeInsets.only(top: centre(close.box)),
            child: IconAction.close(
              size: close,
              label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
              onPressed: () => widget.onDismiss(ToastDismissReason.closed),
            ),
          ),
        ],
      ),
    );
  }
}
