/// @docImport 'tip.dart';
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'popover.dart';
import 'popover_menu.dart';

/// A card of detail about [child] — the person behind a mention, the record
/// behind a reference — that opens while the pointer rests on it, as
/// Radix's HoverCard. Where a [Tip] names a control, a hover card previews
/// what a link leads to.
///
/// It opens [openDelay] after the pointer comes to [child], and at once when
/// focus arrives in [child] from the keyboard (a click that focuses it waits
/// for the pointer's delay). It stays open while the pointer is over [child]
/// or the card, and closes [closeDelay] after it has left both, on Escape,
/// which returns focus to [child], or when focus moves on. It never opens on
/// touch, and a tap on [child] still does what [child] does.
///
/// The card is supplementary: on touch, and to a screen reader, it never
/// shows. Its content must not be the only way to reach an action or a fact —
/// let [child] lead to the full record, and offer the card's actions there
/// too.
class HoverCard extends StatefulWidget {
  /// The trigger: a mention, a reference chip, a link.
  final Widget child;

  /// The card's content, inside its padding. Content taller than the room
  /// the card has scrolls.
  final WidgetBuilder content;

  /// How long the pointer rests on [child] before the card opens.
  final Duration openDelay;

  /// How long the card stays after the pointer has left it and [child].
  final Duration closeDelay;

  /// The side of [child] the card opens on; it flips where that side has
  /// no room, as a [Popover] does.
  final PopoverSide side;

  final PopoverAlign align;

  /// Whether the card points at [child] with an arrow.
  final bool showArrow;

  /// The card's width, padding included. Beside [child], it narrows to the
  /// room there.
  final double width;

  /// Called as the card opens (true) and closes (false).
  final ValueChanged<bool>? onOpenChanged;

  const HoverCard({
    super.key,
    required this.child,
    required this.content,
    this.openDelay = const Duration(milliseconds: 700),
    this.closeDelay = const Duration(milliseconds: 300),
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.center,
    this.showArrow = false,
    this.width = 320,
    this.onOpenChanged,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  final _popover = GlobalKey();
  final _childNode = FocusNode(
    debugLabel: 'Hover card trigger',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final _cardNode = FocusNode(
    debugLabel: 'Hover card',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// The pending open or close.
  Timer? _timer;

  bool _overChild = false;
  bool _overCard = false;

  /// The card is open for keyboard focus in [HoverCard.child], and stays
  /// until focus leaves.
  bool _heldByFocus = false;

  /// The card was dismissed while focus stayed with it: focus returning to
  /// [HoverCard.child] does not reopen it until it has left.
  bool _dismissed = false;

  PopoverController? get _controller =>
      _popover.currentState as PopoverController?;

  bool get _isOpen => _controller?.isOpen ?? false;

  bool get _hovered => _overChild || _overCard;

  @override
  void dispose() {
    _timer?.cancel();
    _childNode.dispose();
    _cardNode.dispose();
    super.dispose();
  }

  void _onHover() {
    _timer?.cancel();
    _timer = null;
    if (_hovered && !_isOpen) {
      _timer = Timer(widget.openDelay, () => _controller?.open());
    } else if (!_hovered && _isOpen && !_heldByFocus) {
      _timer = Timer(widget.closeDelay, () => _controller?.close());
    }
  }

  void _onChildFocus(bool focused) {
    if (!focused) return _onFocusOut();
    if (_dismissed || !_fromKeyboard) return;
    _timer?.cancel();
    _heldByFocus = true;
    if (!_isOpen) _controller?.open();
  }

  /// Whether focus is arriving from the keyboard: the keyboard highlight is
  /// on, and the key that moved it (Tab, an arrow) is still down, as it is
  /// while the focus change lands. A click that focuses the trigger is not.
  static bool get _fromKeyboard =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional &&
      LogicalKeyboardKey.collapseSynonyms(
        HardwareKeyboard.instance.logicalKeysPressed,
      ).difference(_modifiers).isNotEmpty;

  void _onFocusOut() {
    // Focus moving from the trigger into the card, or back, stays with it.
    if (_childNode.hasFocus || _cardNode.hasFocus) return;
    _dismissed = false;
    if (!_heldByFocus) return;
    _heldByFocus = false;
    if (!_hovered) {
      _timer?.cancel();
      _controller?.close();
    }
  }

  void _onOpenChanged(bool open) {
    if (!open) {
      _timer?.cancel();
      _heldByFocus = false;
      // A card closed under the pointer tells it nothing.
      _overCard = false;
      // Escape hands focus back to the trigger once the card has closed;
      // that focus is no reason to open it again.
      _dismissed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _childNode.hasFocus || _cardNode.hasFocus) return;
        _dismissed = false;
      });
    }
    widget.onOpenChanged?.call(open);
  }

  @override
  Widget build(BuildContext context) {
    return Popover(
      key: _popover,
      side: widget.side,
      align: widget.align,
      showArrow: widget.showArrow,
      autofocus: false,
      closeOnFocusOut: true,
      onOpenChanged: _onOpenChanged,
      anchor: (context, controller) => Focus(
        focusNode: _childNode,
        includeSemantics: false,
        onFocusChange: _onChildFocus,
        child: MouseRegion(
          onEnter: (_) {
            _overChild = true;
            _onHover();
          },
          onExit: (_) {
            _overChild = false;
            _onHover();
          },
          child: widget.child,
        ),
      ),
      content: (context, controller) => MouseRegion(
        onEnter: (_) {
          _overCard = true;
          _onHover();
        },
        onExit: (_) {
          _overCard = false;
          _onHover();
        },
        child: Focus(
          focusNode: _cardNode,
          includeSemantics: false,
          onFocusChange: (focused) {
            if (!focused) _onFocusOut();
          },
          child: _FadeIn(
            child: PopoverMenuSurface(
              width: widget.width,
              fitAvailableHeight: true,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AdminSpacing.lg),
                  child: Builder(builder: widget.content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _modifiers = {
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.meta,
};

/// Fades the card in as it opens, at once under reduced motion.
class _FadeIn extends StatelessWidget {
  final Widget child;

  const _FadeIn({required this.child});

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion.fast,
      curve: motion.enter,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: child,
    );
  }
}
