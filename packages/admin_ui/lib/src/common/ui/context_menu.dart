import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'menu.dart';
import 'popover.dart';

/// Opens a [Menu] of [entries] where [child] is right-clicked, or where a
/// finger long-presses it: a context menu, as Radix's `ContextMenu` and Ant's
/// `contextMenu` trigger. The menu opens below the point and lined up with
/// it, flipping above it or shifting in from the window's edges where it
/// does not fit.
///
/// **Keyboard.** Shift+F10 or the context-menu key opens it while focus is
/// inside [child], below the focused control's start corner, on its first
/// item; the menu's own keys are [Menu]'s. Escape closes it and hands focus
/// back to what held it, as does choosing an item. Every other key, the
/// arrows included, is left to [child] and what holds it, such as a list
/// moving between its rows.
///
/// On the web the browser's own context menu is turned off while the
/// pointer is over an [enabled] region, and back on as it leaves, so it
/// still opens everywhere else.
class ContextMenuRegion extends StatefulWidget {
  /// Builds the menu's entries each time it opens, below the region: a
  /// region per row of a long list costs nothing until its menu opens, and
  /// the entries can reflect the state at that moment.
  final List<MenuEntry> Function(BuildContext context) entries;

  final Widget child;

  /// Whether the region opens its menu. A disabled one leaves the pointer
  /// and the keys to [child], and the browser's context menu too.
  final bool enabled;

  final double minWidth;
  final double maxWidth;

  /// Called as the menu opens (true) and closes (false), so the host can
  /// mark what it acts on while it is open — the row a table's menu was
  /// opened on, tinted as selected — as Radix's `data-state="open"` on the
  /// trigger.
  final ValueChanged<bool>? onOpenChanged;

  const ContextMenuRegion({
    super.key,
    required this.entries,
    required this.child,
    this.enabled = true,
    this.minWidth = 180,
    this.maxWidth = 320,
    this.onOpenChanged,
  });

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  /// How far below the point the menu opens: clear of the pointer's tip, as
  /// Radix's context menu stands 2px off it.
  static const _gap = 2.0;

  /// Regions the pointer is over, on the web: the browser's context menu is
  /// off while there is one.
  static var _hoveredRegions = 0;

  bool _hovered = false;
  PopoverController? _menu;
  FocusNode? _returnTo;

  @override
  void didUpdateWidget(ContextMenuRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _setHovered(false);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.enabled) _menu?.close();
      });
    }
  }

  @override
  void dispose() {
    _setHovered(false);
    super.dispose();
  }

  void _setHovered(bool hovered) {
    if (!kIsWeb || hovered == _hovered) return;
    _hovered = hovered;
    if (hovered) {
      if (_hoveredRegions++ == 0) {
        unawaited(BrowserContextMenu.disableContextMenu());
      }
    } else if (--_hoveredRegions == 0) {
      unawaited(BrowserContextMenu.enableContextMenu());
    }
  }

  void _openAt(Offset position) {
    final menu = _menu;
    if (!widget.enabled || menu == null) return;
    _returnTo = FocusManager.instance.primaryFocus;
    openPopoverAt(menu, position);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final menu = _menu;
    if (!widget.enabled || menu == null || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final opens =
        key == LogicalKeyboardKey.contextMenu ||
        (key == LogicalKeyboardKey.f10 &&
            keyboard.isShiftPressed &&
            !keyboard.isControlPressed &&
            !keyboard.isAltPressed &&
            !keyboard.isMetaPressed);
    if (!opens) return KeyEventResult.ignored;

    final focused = FocusManager.instance.primaryFocus;
    _returnTo = focused;
    final box = focused?.context?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize && !box.size.isEmpty) {
      final rect = MatrixUtils.transformRect(
        box.getTransformTo(null),
        Offset.zero & box.size,
      );
      final rtl = Directionality.of(context) == TextDirection.rtl;
      openPopoverAt(menu, rtl ? rect.bottomRight : rect.bottomLeft);
    } else {
      menu.open();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _onKey,
      child: MouseRegion(
        opaque: false,
        onEnter: (_) => _setHovered(widget.enabled),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          excludeFromSemantics: true,
          onSecondaryTapUp: enabled
              ? (details) => _openAt(details.globalPosition)
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            // A mouse's long press is a slow click; its menu is the right
            // button's.
            supportedDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
            },
            onLongPressStart: enabled
                ? (details) => _openAt(details.globalPosition)
                : null,
            child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                widget.child,
                // The menu's anchor lies over the child rather than around
                // it: the child's keys reach what holds the region without
                // passing the anchor's own, and a tap on the child is
                // outside the open menu, which closes it.
                Positioned.fill(
                  child: Menu.region(
                    entries: widget.entries,
                    returnFocus: () => _returnTo,
                    gap: _gap,
                    minWidth: widget.minWidth,
                    maxWidth: widget.maxWidth,
                    onOpenChanged: widget.onOpenChanged,
                    builder: (context, c) {
                      _menu = c;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
