import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// Shared scaffolding for the catalog demo pages, so each demo file only spells
/// out its own variants — not the page shell, section headers, or caption rows.

/// The standard demo page: a centred, width-capped scrolling column.
class DemoPage extends StatelessWidget {
  final double maxWidth;
  final EdgeInsets padding;
  final List<Widget> children;

  const DemoPage({
    super.key,
    this.maxWidth = 460,
    this.padding = const EdgeInsets.all(32),
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(padding: padding, children: children),
        ),
      ),
    );
  }
}

/// A section header between groups of variants, in the theme's section label.
class DemoSection extends StatelessWidget {
  final String title;

  const DemoSection(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(title, style: context.type.sectionLabel),
    );
  }
}

/// A captioned variant: a muted caption above the demoed widget.
class DemoVariant extends StatelessWidget {
  final String caption;
  final Widget child;

  const DemoVariant(this.caption, this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(caption, style: context.type.caption),
          ),
          child,
        ],
      ),
    );
  }
}

/// A caption + trailing control row — for capability demos (a label on the left,
/// the button under test on the right).
class DemoRow extends StatelessWidget {
  final String caption;
  final Widget trailing;

  const DemoRow(this.caption, this.trailing, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              caption,
              style: context.type.bodySmall.copyWith(
                color: context.colors.foregroundSecondary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Holds one value in local state and rebuilds [builder] on change — the
/// interactive wrapper every field demo needs, without a bespoke `_Live` class.
class LiveValue<T> extends StatefulWidget {
  final T initial;
  final Widget Function(T value, ValueChanged<T> onChanged) builder;

  const LiveValue({super.key, required this.initial, required this.builder});

  @override
  State<LiveValue<T>> createState() => _LiveValueState<T>();
}

class _LiveValueState<T> extends State<LiveValue<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return widget.builder(_value, (v) => setState(() => _value = v));
  }
}

/// Opens the first [Popover] below it once mounted — a [Menu], a
/// [NotificationCenter], a field's help or history card — so a static preview
/// shows the open state without a click. [reserve] keeps room below for the
/// popover, which floats over whatever follows.
class PinnedOpen extends StatefulWidget {
  final double reserve;

  /// How many popovers deep to open: the first below [child], then, a frame
  /// after each one opens, the first closed popover inside it — a submenu,
  /// or a popover in a card — until this many are open. [reserve] and
  /// [makeRoom] keep room for the outermost one.
  final int levels;

  /// Keeps as much room below [child] as the open popover reaches past it,
  /// measured every frame, in place of [reserve]: what follows starts right
  /// below the popover, as it would below the closed control, whatever the
  /// theme makes of the popover's height.
  final bool makeRoom;

  final Widget child;

  const PinnedOpen({
    super.key,
    this.reserve = 0,
    this.levels = 1,
    this.makeRoom = false,
    required this.child,
  }) : assert(levels >= 1);

  @override
  State<PinnedOpen> createState() => _PinnedOpenState();
}

class _PinnedOpenState extends State<PinnedOpen> {
  double _room = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _open(context as Element, 1);
      if (widget.makeRoom) _measure();
    });
  }

  /// Opens the first popover below [scope], and [PinnedOpen.levels]
  /// allowing, the first closed one inside it once it has laid out.
  void _open(Element scope, int level) {
    final popover = _popoverBelow(scope, closed: level > 1);
    if (popover == null) return;
    (popover.state as PopoverController).open();
    if (level >= widget.levels) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !popover.mounted) return;
      if (_contentBelow(popover) case final content?) {
        _open(content, level + 1);
      }
    });
  }

  /// The first popover below [scope], or the first closed one.
  StatefulElement? _popoverBelow(Element scope, {required bool closed}) {
    StatefulElement? found;
    void visit(Element element) {
      if (found != null) return;
      if (element case StatefulElement(:final PopoverController state)
          when !closed || !state.isOpen) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    scope.visitChildren(visit);
    return found;
  }

  /// The element laying out the first open popover's content below [scope]:
  /// it fills the overlay, and its one child is the content. The content
  /// sits in the overlay, which the element tree still holds below [scope].
  Element? _contentBelow(Element scope) {
    Element? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget is CustomSingleChildLayout &&
          Popover.availableSizeOf(element) != null) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    scope.visitChildren(visit);
    return found;
  }

  /// Sizes [_room] to the open popover after each frame.
  void _measure([Duration? _]) {
    if (!mounted) return;
    final room = _popoverReach();
    if (room != null && room != _room) setState(() => _room = room);
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  /// How far the open popover's box reaches below the child, or null while
  /// none is laid out. Its content sits in the overlay, which the element
  /// tree still holds below this.
  double? _popoverReach() {
    RenderBox? content;
    _contentBelow(context as Element)?.renderObject
        ?.visitChildren((child) => content ??= child as RenderBox);
    final box = context.findRenderObject();
    if (content case final content? when content.hasSize && box is RenderBox) {
      final bottom = content.localToGlobal(Offset(0, content.size.height)).dy;
      final childBottom = box
          .localToGlobal(Offset(0, box.size.height - _room))
          .dy;
      return (bottom - childBottom).clamp(0, double.infinity).ceilToDouble();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: widget.makeRoom ? _room : widget.reserve),
    child: widget.child,
  );
}

/// Rests a mouse on [child] once mounted — on the centre of the first widget
/// below it that [target] accepts, past [skip] earlier ones, when given — so
/// a static preview shows the hover of a control that keeps that state to
/// itself (a text input, a field trigger, a tab, a calendar day). The mouse
/// follows the target when a later frame moves it (a font that loads late,
/// a scroll). Each one is a mouse of its own, so several can hover on one
/// page, and it is unplugged when this leaves the tree.
class PinnedHover extends StatefulWidget {
  final bool Function(Widget widget)? target;
  final int skip;
  final Widget child;

  const PinnedHover({
    super.key,
    this.target,
    this.skip = 0,
    required this.child,
  });

  @override
  State<PinnedHover> createState() => _PinnedHoverState();
}

class _PinnedHoverState extends State<PinnedHover> {
  /// Device ids apart from the real mice's, one per pinned hover.
  static var _nextDevice = 0x5000;

  final _device = _nextDevice++;
  Offset? _position;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_follow);
  }

  @override
  void dispose() {
    if (_position case final position?) {
      final device = _device;
      // Once the frame that unmounts this is done, so the event never meets
      // a tree half torn down.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => GestureBinding.instance.handlePointerEvent(
          PointerRemovedEvent(
            device: device,
            position: position,
            kind: PointerDeviceKind.mouse,
          ),
        ),
      );
    }
    super.dispose();
  }

  /// Moves the mouse onto the target's centre when it is not there, after
  /// this frame and every later one while mounted. A post-frame callback
  /// schedules no frame of its own, so a still page stays still.
  void _follow(Duration _) {
    if (!mounted) return;
    final box = _target()?.renderObject;
    if (box is RenderBox && box.attached && box.hasSize) {
      final position = box.localToGlobal(box.size.center(Offset.zero));
      if (position != _position) {
        _position = position;
        GestureBinding.instance.handlePointerEvent(
          PointerHoverEvent(
            device: _device,
            position: position,
            kind: PointerDeviceKind.mouse,
          ),
        );
      }
    }
    WidgetsBinding.instance.addPostFrameCallback(_follow);
  }

  Element? _target() {
    final target = widget.target;
    if (target == null) return context as Element;
    var skip = widget.skip;
    Element? found;
    void visit(Element element) {
      if (found != null) return;
      if (target(element.widget)) {
        if (skip-- == 0) found = element;
        return;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shows the keyboard focus highlight while mounted, as a Tab press would,
/// so a control below holding focus — real, or pinned through its states
/// controller — draws its ring in a static preview. Switched after the first
/// frame, since the switch rebuilds every control listening for it.
///
/// The strategy from before the first one mounted comes back when the last
/// one leaves. Each restoring what it found would not do: a page that shows
/// one mounts before the page it replaces unmounts, so it would find the
/// highlight forced on, and leave it so.
class KeyboardHighlight extends StatefulWidget {
  final Widget child;

  const KeyboardHighlight({super.key, required this.child});

  @override
  State<KeyboardHighlight> createState() => _KeyboardHighlightState();
}

class _KeyboardHighlightState extends State<KeyboardHighlight> {
  static var _mounted = 0;
  static var _previous = FocusHighlightStrategy.automatic;

  @override
  void initState() {
    super.initState();
    if (_mounted++ == 0) _previous = FocusManager.instance.highlightStrategy;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });
  }

  @override
  void dispose() {
    if (--_mounted == 0) FocusManager.instance.highlightStrategy = _previous;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
