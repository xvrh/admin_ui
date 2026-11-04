/// @docImport 'menu.dart';
/// @docImport 'popover_menu.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../theme/tokens.dart';

/// Which side of the anchor the popover opens on.
///
/// [start] and [end] follow the text direction, as [PopoverAlign]'s do: in
/// a right-to-left app [start] is the anchor's right and [end] its left.
enum PopoverSide { bottom, top, start, end }

/// Where the popover lines up along the side it opens on.
///
/// Above or below the anchor, it is the horizontal edge lined up with the
/// anchor's: the leading one for [start] (the left in a left-to-right app),
/// the trailing one for [end], and the middles for [center]. Beside the
/// anchor, on [PopoverSide.start] or [PopoverSide.end], it runs down the
/// anchor instead: [start] lines up the tops, [end] the bottoms and [center]
/// the middles.
enum PopoverAlign { start, center, end }

/// Controls a single [Popover]; handed to the anchor builder so a trigger can
/// open/close it and reflect its open state.
abstract class PopoverController {
  void open();
  void close();
  void toggle();
  bool get isOpen;

  /// Width of the anchor, available once the popover is laid out — lets content
  /// size to its trigger without a [LayoutBuilder]. Null before first layout.
  double? get anchorWidth;
}

/// Where an open [Popover] ended up: the [side] it opened on once flipped,
/// its [align], and where its arrow stands. Read through
/// [Popover.placementOf].
@immutable
class PopoverPlacement {
  /// The side of the anchor the popover is on: the one it was given, or the
  /// opposite one where it flipped for room.
  final PopoverSide side;

  final PopoverAlign align;

  /// The middle of the arrow along the popover's edge that faces the anchor,
  /// from that edge's top or left end, in either text direction. It is
  /// across from the anchor's middle, or from the point the popover opened
  /// at, but kept clear of the popover's rounded corners. Null when the
  /// popover has no arrow.
  final double? arrowOffset;

  const PopoverPlacement({
    required this.side,
    required this.align,
    this.arrowOffset,
  });

  @override
  bool operator ==(Object other) =>
      other is PopoverPlacement &&
      other.side == side &&
      other.align == align &&
      other.arrowOffset == arrowOffset;

  @override
  int get hashCode => Object.hash(side, align, arrowOffset);

  @override
  String toString() =>
      'PopoverPlacement(${side.name}, ${align.name}'
      '${arrowOffset == null ? '' : ', arrow at $arrowOffset'})';
}

/// An anchored, dismissible popover.
///
/// A thin wrapper over [RawMenuAnchor]: the framework handles the overlay and
/// outside taps; we own positioning, dismissal and the content. Content is
/// rendered as-is — the primitive supplies no surface of its own.
///
/// **Placement.** The popover opens on [side] of the anchor, lined up by
/// [align] and shifted by [alignOffset], and flips to the opposite side when
/// it does not fit and that side has more room. It is then clamped into the
/// viewport with an 8px margin, on both axes, but never parted from its
/// anchor: an anchor scrolled out of view takes the popover with it rather
/// than leave it floating over other content (Radix's "partial" sticky).
/// Content that can scroll caps its size at [availableSizeOf] (a
/// [PopoverMenuSurface] with `fitAvailableHeight`), so a long list scrolls
/// on the side it fits instead of covering its trigger; content that cannot
/// shrink, like a calendar, keeps its size and is clamped. [placementOf]
/// tells the content where it ended up, and [showArrow] points it at the
/// anchor.
///
/// **Dismissal.** Escape closes the top-most open popover wherever focus is —
/// in it, on its trigger, or elsewhere on the page after a pointer open — and
/// returns focus to the trigger; a layer opened above the popover (a dialog)
/// keeps its own Escape. With [closeOnFocusOut], focus moving on past the
/// popover closes it too.
///
/// **Nesting.** A popover whose anchor sits in another's content, such as a
/// submenu, belongs to the same group: a tap in either is inside both, it
/// closes with its parent, and it answers Escape first, handing focus back
/// to its own anchor. Focus moving into it is still inside the parent, for
/// the parent's [closeOnFocusOut].
class Popover extends StatefulWidget {
  final Widget Function(BuildContext context, PopoverController controller)
  anchor;
  final Widget Function(BuildContext context, PopoverController controller)
  content;
  final PopoverSide side;
  final PopoverAlign align;

  /// Shifts the popover along its [align] axis, away from the edge it lines
  /// up, as Radix's `alignOffset`: toward the end for [PopoverAlign.start]
  /// and [PopoverAlign.center], toward the start for [PopoverAlign.end].
  /// Above or below the anchor, start and end follow the text direction, so
  /// the shift mirrors in a right-to-left app; beside it, start is the top.
  final double alignOffset;

  /// Gap between the anchor and the popover; with [showArrow], between the
  /// anchor and the arrow's tip.
  final double gap;

  /// Whether the popover points at its anchor with an arrow, sized by the
  /// theme's `context.overlayStyle`. A [PopoverMenuSurface] draws it, on its
  /// edge that faces the anchor; the popover stands off by the arrow's
  /// height to make room for it. Other content can read [placementOf] to
  /// draw its own.
  final bool showArrow;

  /// Whether opening moves focus into the popover when nothing else holds it.
  /// Interactive content wants this; a read-only tip should pass false to
  /// keep the caller's focus.
  final bool autofocus;

  /// Whether focus leaving the open popover — Tab past its last field, a
  /// shortcut focusing a field elsewhere — closes it. Focus returning to the
  /// anchor, falling back to an enclosing scope or leaving the app keeps it
  /// open. [Menu] turns this on.
  final bool closeOnFocusOut;

  /// Called as the popover opens (true) and closes (false), whatever did it:
  /// the controller, Escape, a tap outside, focus leaving.
  final ValueChanged<bool>? onOpenChanged;

  const Popover({
    super.key,
    required this.anchor,
    required this.content,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.start,
    this.alignOffset = 0,
    this.gap = 6,
    this.showArrow = false,
    this.autofocus = true,
    this.closeOnFocusOut = false,
    this.onOpenChanged,
  });

  /// The room the open popover around [context] has to grow into without
  /// covering its anchor, as Radix's `--radix-popper-available-width` and
  /// `-height`. Along the axis it opens on, it is the room between the
  /// anchor and the viewport margin on the side it opens toward, or on the
  /// far side when that has more (a popover capped to it flips there when
  /// the near side is short). Across that axis, it is the viewport less its
  /// margins. Null outside a popover.
  static Size? availableSizeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PopoverScope>()?.availableSize;

  /// The height of [availableSizeOf]: for a popover above or below its
  /// anchor, the most it can take without covering it.
  static double? availableHeightOf(BuildContext context) =>
      availableSizeOf(context)?.height;

  /// Where the open popover around [context] ended up: the side it opened
  /// on once flipped, and where its arrow stands. The popover sets it as it
  /// lays out, and its listeners hear of a change once that frame is done,
  /// since a widget cannot rebuild in the middle of one: a widget rebuilding
  /// on it shows the change a frame later. A painter can read it as it
  /// paints, which is after the layout that set it. Null outside a popover.
  static ValueListenable<PopoverPlacement>? placementOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PopoverScope>()?.state._placement;

  /// Whether the open popover around [context] was opened from the keyboard —
  /// Enter, Space or an arrow key on its trigger — rather than by a pointer or
  /// programmatically. Content moves focus to its first (or selected) item
  /// only then, as a menu does; after a pointer open it leaves focus on the
  /// surface itself.
  static bool openedByKeyboard(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<_PopoverScope>()
          ?.state
          ._openedByKeyboard ??
      false;

  /// Closes the open popover around [context] and returns focus to its
  /// trigger, as Escape does — for content that closes itself, such as a
  /// listbox on a pick. Does nothing outside a popover.
  static void dismiss(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PopoverScope>()?.state._dismiss();

  /// Whether a popover whose trigger sits inside [context] is open. Its
  /// content lives in the overlay, so a [TapRegion] around the trigger takes
  /// a tap in it for a tap outside; this tells the two apart.
  static bool isOpenWithin(BuildContext context) =>
      _PopoverState._stack.any((popover) {
        if (!popover.mounted) return false;
        var within = false;
        popover.context.visitAncestorElements((element) {
          within = identical(element, context);
          return !within;
        });
        return within;
      });

  @override
  State<Popover> createState() => _PopoverState();
}

/// Opens [controller], a [Popover]'s, at [globalPosition] instead of at its
/// anchor: the popover places itself around that point as around an anchor
/// of no size, flipping and shifting from it and pointing its arrow at it,
/// as a context menu opens where the pointer was. A later
/// [PopoverController.open] opens it at the anchor again.
@internal
void openPopoverAt(PopoverController controller, Offset globalPosition) {
  assert(
    controller is _PopoverState,
    'openPopoverAt opens a Popover; $controller is not one',
  );
  (controller as _PopoverState)._openAt(globalPosition);
}

/// What the popover around [context] was asked for, for the surface that
/// draws its arrow and caps its width: the [PopoverSide] it opens on and
/// whether it shows an arrow. Null outside a popover.
@internal
({PopoverSide side, bool showArrow})? popoverRequestOf(BuildContext context) {
  final popover = context
      .getInheritedWidgetOfExactType<_PopoverScope>()
      ?.state
      .widget;
  if (popover == null) return null;
  return (side: popover.side, showArrow: popover.showArrow);
}

class _PopoverState extends State<Popover> implements PopoverController {
  /// Open popovers, oldest first; the last one answers a stray Escape.
  static final _stack = <_PopoverState>[];

  final _menu = MenuController();
  final _anchorNode = FocusNode(
    debugLabel: 'Popover anchor',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final _contentNode = FocusNode(debugLabel: 'Popover', skipTraversal: true);
  late final _placement = _PlacementNotifier(_requested);
  bool _isOpen = false;
  bool _openedByKeyboard = false;
  bool _focusWasInside = false;
  double? _anchorWidth;

  PopoverPlacement get _requested =>
      PopoverPlacement(side: widget.side, align: widget.align);

  @override
  bool get isOpen => _isOpen;

  @override
  double? get anchorWidth => _anchorWidth;

  @override
  void open() => _menu.open();

  @override
  void close() => _menu.close();

  @override
  void toggle() => _menu.isOpen ? _menu.close() : _menu.open();

  void _openAt(Offset globalPosition) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return _menu.open();
    _menu.open(position: box.globalToLocal(globalPosition));
  }

  @override
  void didUpdateWidget(Popover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen && widget.closeOnFocusOut != oldWidget.closeOnFocusOut) {
      if (widget.closeOnFocusOut) {
        FocusManager.instance.addListener(_onFocusChanged);
      } else {
        FocusManager.instance.removeListener(_onFocusChanged);
      }
    }
  }

  @override
  void dispose() {
    // A popover torn down while open gets no onClose.
    _untrack();
    _anchorNode.dispose();
    _contentNode.dispose();
    _placement.dispose();
    super.dispose();
  }

  void _onOpen() {
    // Read while the activating key is still down: the content builds a
    // frame later, when it may already be up.
    _openedByKeyboard = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) => !_modifiers.contains(key),
    );
    _focusWasInside = false;
    _placement.value = _requested;
    _track();
    setState(() => _isOpen = true);
    widget.onOpenChanged?.call(true);
  }

  void _onClose() {
    _untrack();
    setState(() => _isOpen = false);
    widget.onOpenChanged?.call(false);
  }

  void _track() {
    if (_stack.contains(this)) return;
    if (_stack.isEmpty) {
      FocusManager.instance.addEarlyKeyEventHandler(_onEarlyKey);
    }
    _stack.add(this);
    if (widget.closeOnFocusOut) {
      FocusManager.instance.addListener(_onFocusChanged);
    }
  }

  void _untrack() {
    if (!_stack.remove(this)) return;
    if (_stack.isEmpty) {
      FocusManager.instance.removeEarlyKeyEventHandler(_onEarlyKey);
    }
    FocusManager.instance.removeListener(_onFocusChanged);
  }

  /// Escape reaches the top-most open popover before the focus tree does,
  /// unless focus is inside it (its content, and anything nested there,
  /// answers first) or in a layer above its anchor, such as a dialog opened
  /// from it.
  static KeyEventResult _onEarlyKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        _stack.isEmpty) {
      return KeyEventResult.ignored;
    }
    final top = _stack.last;
    if (!top.mounted || top._contentNode.hasFocus) {
      return KeyEventResult.ignored;
    }
    final layer = FocusManager.instance.primaryFocus?.nearestScope;
    if (layer != null && !top._anchorNode.ancestors.contains(layer)) {
      return KeyEventResult.ignored;
    }
    top._dismiss();
    return KeyEventResult.handled;
  }

  void _dismiss() {
    close();
    // The trigger itself, not a control nested in it (a clear ×).
    final nodes = _anchorNode.traversalDescendants.toList();
    nodes
        .where((node) => !node.ancestors.any(nodes.contains))
        .firstOrNull
        ?.requestFocus();
  }

  void _onFocusChanged() {
    if (!_isOpen) return;
    if (_contentNode.hasFocus) {
      _focusWasInside = true;
      return;
    }
    final primary = FocusManager.instance.primaryFocus;
    if (!_focusWasInside ||
        primary == null ||
        _anchorNode.hasFocus ||
        _contentNode.ancestors.contains(primary)) {
      return;
    }
    final lifecycle = SchedulerBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    close();
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _menu,
      onOpen: _onOpen,
      onClose: _onClose,
      builder: (context, controller, child) => Focus(
        focusNode: _anchorNode,
        includeSemantics: false,
        child: widget.anchor(context, this),
      ),
      overlayBuilder: (context, info) {
        _anchorWidth = info.anchorRect.width;
        final anchor = switch (info.position) {
          final at? => (info.anchorRect.topLeft + at) & Size.zero,
          null => info.anchorRect,
        };
        // An anchor laid out where nothing paints it, such as in a list's
        // cache extent, can measure no finite rect: the content is then
        // laid out as at the viewport's corner but not shown.
        final placeable = anchor.isFinite;
        final arrow = widget.showArrow ? context.overlayStyle : null;
        final layout = _PopoverLayout(
          anchor: placeable ? anchor : Rect.zero,
          side: widget.side,
          align: widget.align,
          gap: widget.gap,
          alignOffset: widget.alignOffset,
          arrowHeight: arrow?.arrowHeight ?? 0,
          arrowPadding: arrow == null
              ? 0
              : context.radii.radiusMenu + arrow.arrowWidth / 2,
          textDirection: Directionality.of(context),
          placement: _placement,
        );
        return _PopoverScope(
          state: this,
          availableSize: layout.availableSize(info.overlaySize),
          child: CustomSingleChildLayout(
            delegate: layout,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): _dismiss,
              },
              child: Focus(
                focusNode: _contentNode,
                autofocus: widget.autofocus,
                // A bare RawMenuAnchor's own handler only closes child
                // submenus, so we close on taps outside the group ourselves.
                child: TapRegion(
                  groupId: info.tapRegionGroupId,
                  onTapOutside: (_) => close(),
                  child: Offstage(
                    offstage: !placeable,
                    // Same shim as the modals: a popover can open over a web
                    // platform view (an embedded iframe, say), which would
                    // otherwise take the clicks meant for its items.
                    child: PointerInterceptor(
                      child: Builder(
                        builder: (context) => widget.content(context, this),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final _modifiers = {
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.capsLock,
  LogicalKeyboardKey.fn,
};

class _PopoverScope extends InheritedWidget {
  final _PopoverState state;
  final Size availableSize;

  const _PopoverScope({
    required this.state,
    required this.availableSize,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PopoverScope old) =>
      old.state != state || old.availableSize != availableSize;
}

/// Lays the content out with [placePopover], and publishes where it went to
/// [placement].
class _PopoverLayout extends SingleChildLayoutDelegate {
  final Rect anchor;
  final PopoverSide side;
  final PopoverAlign align;
  final double gap;
  final double alignOffset;
  final double arrowHeight;
  final double arrowPadding;
  final TextDirection textDirection;
  final _PlacementNotifier placement;

  _PopoverLayout({
    required this.anchor,
    required this.side,
    required this.align,
    required this.gap,
    required this.alignOffset,
    required this.arrowHeight,
    required this.arrowPadding,
    required this.textDirection,
    required this.placement,
  });

  Size availableSize(Size viewport) => _availableSize(
    anchor: anchor,
    viewport: viewport,
    side: side,
    gap: gap + arrowHeight,
    textDirection: textDirection,
    margin: _popoverMargin,
  );

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final placed = placePopover(
      anchor: anchor,
      child: childSize,
      viewport: size,
      side: side,
      align: align,
      gap: gap,
      alignOffset: alignOffset,
      arrowHeight: arrowHeight,
      arrowPadding: arrowPadding,
      textDirection: textDirection,
    );
    placement.value = placed.placement;
    return placed.offset;
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      old.anchor != anchor ||
      old.side != side ||
      old.align != align ||
      old.gap != gap ||
      old.alignOffset != alignOffset ||
      old.arrowHeight != arrowHeight ||
      old.arrowPadding != arrowPadding ||
      old.textDirection != textDirection ||
      old.placement != placement;
}

/// [Popover.placementOf]'s listenable, which the popover's layout sets.
///
/// A widget cannot rebuild in the middle of a frame, so a change made while
/// one is being built or laid out reaches the listeners once it is done.
/// [PopoverArrowPainter] repaints on [repaint] instead, which hears of it at
/// once, so the arrow moves in the frame that moved the popover.
class _PlacementNotifier extends ChangeNotifier
    implements ValueListenable<PopoverPlacement> {
  _PlacementNotifier(this._value);

  PopoverPlacement _value;

  /// Bumped as soon as [value] changes, during layout too.
  final repaint = ValueNotifier(0);

  bool _pending = false;
  bool _disposed = false;

  @override
  PopoverPlacement get value => _value;

  set value(PopoverPlacement value) {
    if (value == _value) return;
    _value = value;
    repaint.value++;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_pending) return;
    _pending = true;
    scheduler.addPostFrameCallback((_) {
      _pending = false;
      if (!_disposed) notifyListeners();
    }, debugLabel: 'Popover.placementOf');
  }

  @override
  void dispose() {
    _disposed = true;
    repaint.dispose();
    super.dispose();
  }
}

/// The margin a popover keeps from the viewport's edges.
const _popoverMargin = 8.0;

/// Where [placePopover] put a popover: its top-left corner in the viewport,
/// and the placement it resolved.
@internal
typedef PopoverPlacementResult = ({Offset offset, PopoverPlacement placement});

/// Places a popover of size [child] beside [anchor] in [viewport]: the
/// placement [Popover] lays its content out with, and a tooltip its chip.
///
/// The popover opens on [side] of the anchor, lined up by [align] and
/// shifted by [alignOffset] (see [Popover.alignOffset]), [gap] plus
/// [arrowHeight] off it. It keeps [side] when it fits there, and otherwise
/// flips to the opposite side only when that has more room. It is then kept
/// [margin] inside the viewport on both axes, but never parted from the
/// anchor: at most flush with its far edge, so an anchor scrolled out of view
/// takes the popover with it.
///
/// With an [arrowHeight], the placement's [PopoverPlacement.arrowOffset] is
/// across from the anchor's middle, and at least [arrowPadding] from either
/// end of the edge — the popover's corner radius plus half the arrow's width,
/// so the arrow never runs into a rounded corner.
@internal
PopoverPlacementResult placePopover({
  required Rect anchor,
  required Size child,
  required Size viewport,
  required PopoverSide side,
  required PopoverAlign align,
  required double gap,
  double alignOffset = 0,
  double arrowHeight = 0,
  double arrowPadding = 0,
  required TextDirection textDirection,
  double margin = _popoverMargin,
}) {
  final ltr = textDirection == TextDirection.ltr;
  final offAnchor = gap + arrowHeight;
  double room(AxisDirection toward) =>
      _room(anchor, viewport, toward, offAnchor, margin);

  var toward = _directionOf(side, textDirection);
  final vertical = axisDirectionToAxis(toward) == Axis.vertical;
  final preferred = room(toward);
  if ((vertical ? child.height : child.width) > preferred &&
      room(flipAxisDirection(toward)) > preferred) {
    toward = flipAxisDirection(toward);
  }

  // Away from the edge lined up: toward the end, or the start for `end`.
  var shift = align == PopoverAlign.end ? -alignOffset : alignOffset;
  double dx, dy;
  if (vertical) {
    if (!ltr) shift = -shift;
    final leading = (align == PopoverAlign.start) == ltr;
    dx =
        (align == PopoverAlign.center
            ? anchor.center.dx - child.width / 2
            : leading
            ? anchor.left
            : anchor.right - child.width) +
        shift;
    dy = toward == AxisDirection.down
        ? anchor.bottom + offAnchor
        : anchor.top - offAnchor - child.height;
  } else {
    dy =
        switch (align) {
          PopoverAlign.start => anchor.top,
          PopoverAlign.center => anchor.center.dy - child.height / 2,
          PopoverAlign.end => anchor.bottom - child.height,
        } +
        shift;
    dx = toward == AxisDirection.right
        ? anchor.right + offAnchor
        : anchor.left - offAnchor - child.width;
  }

  dx = _clampInto(dx, viewport.width, child.width, margin);
  dy = _clampInto(dy, viewport.height, child.height, margin);
  // At most flush with the anchor's far edge, so the clamp never parts
  // them; a no-op while the anchor is at least partly on screen.
  if (vertical) {
    dx = dx.clamp(anchor.left - child.width, anchor.right);
    dy = dy.clamp(
      anchor.top - offAnchor - child.height,
      anchor.bottom + offAnchor,
    );
  } else {
    dx = dx.clamp(
      anchor.left - offAnchor - child.width,
      anchor.right + offAnchor,
    );
    dy = dy.clamp(anchor.top - child.height, anchor.bottom);
  }

  double? arrowOffset;
  if (arrowHeight > 0) {
    final (target, edge) = vertical
        ? (anchor.center.dx - dx, child.width)
        : (anchor.center.dy - dy, child.height);
    arrowOffset = edge < 2 * arrowPadding
        ? edge / 2
        : target.clamp(arrowPadding, edge - arrowPadding);
  }
  return (
    offset: Offset(dx, dy),
    placement: PopoverPlacement(
      side: _sideOf(toward, textDirection),
      align: align,
      arrowOffset: arrowOffset,
    ),
  );
}

/// The physical direction [side] opens toward from the anchor.
AxisDirection _directionOf(PopoverSide side, TextDirection textDirection) {
  final ltr = textDirection == TextDirection.ltr;
  return switch (side) {
    PopoverSide.bottom => AxisDirection.down,
    PopoverSide.top => AxisDirection.up,
    PopoverSide.start => ltr ? AxisDirection.left : AxisDirection.right,
    PopoverSide.end => ltr ? AxisDirection.right : AxisDirection.left,
  };
}

/// The [PopoverSide] that opens toward [direction].
PopoverSide _sideOf(AxisDirection direction, TextDirection textDirection) {
  final ltr = textDirection == TextDirection.ltr;
  return switch (direction) {
    AxisDirection.down => PopoverSide.bottom,
    AxisDirection.up => PopoverSide.top,
    AxisDirection.left => ltr ? PopoverSide.start : PopoverSide.end,
    AxisDirection.right => ltr ? PopoverSide.end : PopoverSide.start,
  };
}

/// Room between [anchor], [gap] off it, and the viewport's [margin] toward
/// [direction].
double _room(
  Rect anchor,
  Size viewport,
  AxisDirection direction,
  double gap,
  double margin,
) => math.max(0, switch (direction) {
  AxisDirection.down => viewport.height - anchor.bottom - gap - margin,
  AxisDirection.up => anchor.top - gap - margin,
  AxisDirection.left => anchor.left - gap - margin,
  AxisDirection.right => viewport.width - anchor.right - gap - margin,
});

/// [Popover.availableSizeOf]: along [side]'s axis, the larger of the two
/// sides' room — the popover keeps [side] when it fits there and otherwise
/// flips only toward more room, so this is the room of whichever side it
/// ends up on whenever a cap to it binds — and across it, the viewport less
/// its margins.
Size _availableSize({
  required Rect anchor,
  required Size viewport,
  required PopoverSide side,
  required double gap,
  required TextDirection textDirection,
  required double margin,
}) {
  final toward = _directionOf(side, textDirection);
  final along = math.max(
    _room(anchor, viewport, toward, gap, margin),
    _room(anchor, viewport, flipAxisDirection(toward), gap, margin),
  );
  return axisDirectionToAxis(toward) == Axis.vertical
      ? Size(math.max(0, viewport.width - 2 * margin), along)
      : Size(along, math.max(0, viewport.height - 2 * margin));
}

double _clampInto(
  double value,
  double extent,
  double childExtent,
  double margin,
) {
  final max = extent - childExtent - margin;
  if (max < margin) return margin;
  return value.clamp(margin, max);
}

/// Paints a popover's arrow: a triangle standing on the edge of the painted
/// box that faces the anchor, pointing out at it.
///
/// The triangle's base reaches [hairline] into the box, so the box's own
/// border is hidden under it; it is filled with [fill], the box's colour,
/// and only its two slanted edges are stroked, in [border]. Given as the
/// `foregroundPainter` of a [CustomPaint] around the box, it paints over the
/// box's border and outside its bounds.
///
/// Where it stands comes from [placement], [Popover.placementOf]'s, which
/// also repaints it in the frame the popover moves, or else from a fixed
/// [side] and [offset] (see [PopoverPlacement.side] and
/// [PopoverPlacement.arrowOffset]). A [shadow] is drawn outside the box
/// only.
@internal
class PopoverArrowPainter extends CustomPainter {
  final ValueListenable<PopoverPlacement>? placement;
  final PopoverSide? side;
  final double? offset;
  final TextDirection textDirection;
  final double width;
  final double height;
  final Color fill;
  final Color border;
  final double hairline;
  final List<BoxShadow> shadow;

  PopoverArrowPainter({
    this.placement,
    this.side,
    this.offset,
    required this.textDirection,
    required this.width,
    required this.height,
    required this.fill,
    required this.border,
    this.hairline = 1,
    this.shadow = const [],
  }) : assert(
         placement != null || side != null,
         'Give the arrow a placement, or a side and an offset',
       ),
       super(
         repaint: placement is _PlacementNotifier
             ? placement.repaint
             : placement,
       );

  @override
  void paint(Canvas canvas, Size size) {
    final placed = placement?.value;
    final side = placed?.side ?? this.side!;
    final at = placed == null ? offset : placed.arrowOffset;
    if (at == null || width <= 0 || height <= 0) return;

    final toward = _directionOf(side, textDirection);
    // A point [along] the edge that faces the anchor, [out] beyond it.
    Offset point(double along, double out) => switch (toward) {
      AxisDirection.down => Offset(along, -out),
      AxisDirection.up => Offset(along, size.height + out),
      AxisDirection.right => Offset(-out, along),
      AxisDirection.left => Offset(size.width + out, along),
    };
    final half = width / 2;
    final corners = [
      point(at - half, -hairline),
      point(at - half, 0),
      point(at, height),
      point(at + half, 0),
      point(at + half, -hairline),
    ];
    final body = Path()..addPolygon(corners, true);

    if (shadow.isNotEmpty) {
      final box = Offset.zero & size;
      canvas
        ..save()
        ..clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(box.inflate(height + 64))
            ..addRect(box),
        );
      for (final s in shadow) {
        canvas.drawPath(
          body.shift(s.offset),
          Paint()
            ..color = s.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma),
        );
      }
      canvas.restore();
    }
    canvas.drawPath(body, Paint()..color = fill);
    if (hairline > 0) {
      canvas.drawPath(
        Path()..addPolygon(corners.sublist(1, 4), false),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = hairline,
      );
    }
  }

  @override
  bool shouldRepaint(PopoverArrowPainter old) =>
      old.placement != placement ||
      old.side != side ||
      old.offset != offset ||
      old.textDirection != textDirection ||
      old.width != width ||
      old.height != height ||
      old.fill != fill ||
      old.border != border ||
      old.hairline != hairline ||
      !listEquals(old.shadow, shadow);
}
