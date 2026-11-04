/// @docImport 'button.dart';
/// @docImport 'context_menu.dart';
/// @docImport '../../theme/typography.dart';
library;

import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'popover.dart';
import 'popover_menu.dart';
import 'tappable.dart';

/// One entry in a [Menu]: a [MenuItem], a [MenuCheckboxItem], a
/// [MenuSubmenu], a [MenuDivider], or a [MenuHeader].
sealed class MenuEntry {
  const MenuEntry();
}

/// A selectable row. A null [onSelect] renders it disabled; [danger] tints it
/// red for destructive actions; [shortcut] shows a muted hint at the end, read
/// left to right in either direction.
///
/// Set [uri] to render the row as a real link (an `<a>` on web): it then
/// supports the browser's native middle-click / ⌘-click / right-click ("open in
/// new tab", "open in split view"). Left click follows the link — opening a new
/// tab when [target] is [LinkTarget.blank] — and still closes the menu;
/// [onSelect] is ignored when [uri] is set.
class MenuItem extends MenuEntry {
  final String label;

  /// A second, muted line under [label] saying what the item does, as M3's
  /// supporting text and Fluent's secondary content. It wraps rather than
  /// widening the menu past its maximum width.
  final String? description;

  final IconData? icon;
  final String? shortcut;

  /// Called when the item is chosen, after the menu closes.
  final VoidCallback? onSelect;

  final bool danger;
  final Uri? uri;
  final LinkTarget target;

  /// Makes the item one choice of a single-select group, a menu radio item,
  /// and marks the chosen one with a trailing check. Null, it is a plain
  /// action.
  final bool? checked;

  const MenuItem(
    this.label, {
    this.description,
    this.icon,
    this.shortcut,
    this.onSelect,
    this.danger = false,
    this.uri,
    this.target = LinkTarget.defaultTarget,
    this.checked,
  });

  bool get _enabled => uri != null || onSelect != null;
}

/// A row that turns an option on or off, as Radix's `CheckboxItem`: a check
/// at its end shows [checked], in the column a radio [MenuItem] marks its
/// choice in, and choosing the row calls [onChanged] with the other value.
/// A null [onChanged] renders it disabled.
///
/// Choosing it closes the menu, then calls [onChanged]. With [keepOpen] the
/// menu stays open on it instead, for a menu that toggles several options
/// in a row, such as the columns a table shows; the host rebuilds it with
/// the new [checked].
class MenuCheckboxItem extends MenuEntry {
  final String label;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final String? shortcut;

  /// A second, muted line under [label], as [MenuItem.description].
  final String? description;

  final bool keepOpen;

  const MenuCheckboxItem(
    this.label, {
    required this.checked,
    required this.onChanged,
    this.icon,
    this.shortcut,
    this.description,
    this.keepOpen = false,
  });
}

/// A row that opens a nested menu of [entries] beside it, as Radix's `Sub`
/// and M3's cascading menus. The row ends in a chevron toward its end side,
/// where the menu opens with its first row level with this one; it opens on
/// the start side instead when the end has no room, and over the menu when
/// neither side has.
///
/// Resting the pointer on the row opens it, and moving on to another row
/// closes it after a short grace, so a diagonal move into it does not. A
/// click opens it, or closes one a click opened. From the keyboard, →
/// (← in a right-to-left app), Enter or Space opens it on its first item,
/// and ← (→) or Escape closes it back to the row. Choosing an item in it
/// closes every level. A submenu that is not [enabled], or has no entries,
/// is skipped by the arrow keys but still announced, as disabled.
class MenuSubmenu extends MenuEntry {
  final String label;
  final IconData? icon;

  /// A second, muted line under [label], as [MenuItem.description].
  final String? description;

  final List<MenuEntry> entries;
  final bool enabled;

  const MenuSubmenu(
    this.label, {
    this.icon,
    this.description,
    required this.entries,
    this.enabled = true,
  });
}

/// A hairline separating groups of items.
class MenuDivider extends MenuEntry {
  const MenuDivider();
}

/// A caption labelling a group of items, cased by the theme: in small
/// capitals where its type spec sets [AdminTypeSpec.uppercaseLabels], as
/// Iris does, and otherwise in sentence case, a muted caption as shadcn's
/// `DropdownMenuLabel`, Ant's group title and Fluent's `MenuGroupHeader` are.
/// Screen readers get the label as written.
class MenuHeader extends MenuEntry {
  final String label;
  const MenuHeader(this.label);
}

/// The rows a menu's keys and pointer move between, and what they show.
extension on MenuEntry {
  /// The row's label; null for a divider or a header, which take no focus.
  String? get _rowLabel => switch (this) {
    MenuItem(:final label) ||
    MenuCheckboxItem(:final label) ||
    MenuSubmenu(:final label) => label,
    MenuDivider() || MenuHeader() => null,
  };

  bool get _rowEnabled => switch (this) {
    final MenuItem item => item._enabled,
    final MenuCheckboxItem item => item.onChanged != null,
    final MenuSubmenu submenu => submenu.enabled && submenu.entries.isNotEmpty,
    MenuDivider() || MenuHeader() => false,
  };
}

/// A dropdown action menu anchored to a trigger.
///
/// The [builder] supplies the trigger and is handed the [PopoverController] so it
/// can toggle the menu (typically an [Button] with `onPressed: c.toggle`).
/// Selecting an item closes the menu, then fires its callback.
///
/// **Keyboard**, as a WAI-ARIA menu button: Enter, Space or ↓ on the trigger
/// opens the menu on its first enabled item (↑ on its last); a pointer open
/// focuses the menu itself, so the keys work from there too. ↑/↓ move
/// between enabled items and wrap, Home/End jump to the ends, and typing
/// jumps to the next item starting with the typed letters. Enter or Space
/// runs the item. Escape closes the menu and returns focus to the trigger;
/// Tab and Shift+Tab close it and move on from the trigger. Disabled items
/// are skipped but still announced, as disabled. Each [MenuSubmenu] level
/// keeps these keys to itself; see there for the ones that open and close
/// it.
///
/// The pointer and the keyboard share one highlight: moving the pointer onto
/// an item focuses it, so the next arrow key continues from there.
///
/// Where any row of a menu carries an icon, the rows without one keep its
/// place empty, so the labels line up in one column.
///
/// A [header] heads the open menu with content of its own, such as the
/// signed-in account above its actions: it takes no focus, and the keys and
/// the screen reader's menu start at the first entry under it.
class Menu extends StatefulWidget {
  final List<MenuEntry> entries;

  /// Shown above the entries, in the menu's padding, and parted from them by
  /// a divider. Not an item: the arrow keys and typeahead never reach it.
  final Widget? header;
  final Widget Function(BuildContext context, PopoverController controller)
  builder;
  final PopoverSide side;
  final PopoverAlign align;

  /// Gap between the trigger and the menu — see [Popover.gap].
  final double gap;

  final double minWidth;
  final double maxWidth;

  /// Whether focus leaving the open menu closes it — see
  /// [Popover.closeOnFocusOut].
  final bool closeOnFocusOut;

  /// Called as the menu opens (true) and closes (false) — see
  /// [Popover.onOpenChanged].
  final ValueChanged<bool>? onOpenChanged;

  final List<MenuEntry> Function(BuildContext context)? _entriesOf;
  final FocusNode? Function()? _returnFocus;

  const Menu({
    super.key,
    required this.entries,
    required this.builder,
    this.header,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.start,
    this.gap = 6,
    this.minWidth = 180,
    this.maxWidth = 320,
    this.closeOnFocusOut = true,
    this.onOpenChanged,
  }) : _entriesOf = null,
       _returnFocus = null;

  /// The menu a [ContextMenuRegion] opens at a point, with no trigger of its
  /// own: [entries] builds its entries each time it builds open, ↑ and ↓ on
  /// its anchor do not open it, and Escape and Tab hand focus back to, or
  /// move on from, [returnFocus] — what held focus as it opened.
  @internal
  const Menu.region({
    super.key,
    required List<MenuEntry> Function(BuildContext context) entries,
    required this.builder,
    required this._returnFocus,
    this.gap = 6,
    this.minWidth = 180,
    this.maxWidth = 320,
    this.onOpenChanged,
  }) : entries = const [],
       header = null,
       side = PopoverSide.bottom,
       align = PopoverAlign.start,
       closeOnFocusOut = true,
       _entriesOf = entries;

  /// Renders one [MenuEntry] row — shared with popovers that mix entries with
  /// non-menu content (an overflow popover with a form in it). Outside a
  /// [Menu] an item is a plain focusable button, with no arrow-key model of
  /// its own, and a [MenuSubmenu] opens its menu on a tap or on Enter.
  ///
  /// Pass [iconColumn] when another row of the same surface carries an icon:
  /// a row without one then keeps its place empty, so the labels line up, as
  /// in a [Menu].
  static Widget entry(
    BuildContext context,
    MenuEntry entry,
    PopoverController controller, {
    bool iconColumn = false,
  }) {
    return switch (entry) {
      MenuItem() || MenuCheckboxItem() || MenuSubmenu() => _MenuRow(
        entry: entry,
        iconColumn: iconColumn,
        tree: _MenuTree(
          close: controller.close,
          tabOut: (_) => controller.close(),
          minWidth: 180,
          maxWidth: 320,
        ),
      ),
      MenuDivider() => const _MenuDividerRow(),
      MenuHeader() => _MenuHeaderRow(entry),
    };
  }

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final _anchorNode = FocusNode(
    debugLabel: 'Menu trigger',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// Set by ↑ on the closed trigger, so the menu opens on its last item.
  bool _openOnLast = false;

  @override
  void dispose() {
    _anchorNode.dispose();
    super.dispose();
  }

  KeyEventResult _onTriggerKey(PopoverController c, KeyEvent event) {
    if (event is! KeyDownEvent || widget._entriesOf != null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    if (c.isOpen) return KeyEventResult.ignored;
    _openOnLast = key == LogicalKeyboardKey.arrowUp;
    c.open();
    return KeyEventResult.handled;
  }

  /// What held focus as the region's menu opened, if it can take it back.
  FocusNode? get _returnNode {
    final node = widget._returnFocus?.call();
    if (node == null || node is FocusScopeNode || node.context == null) {
      return null;
    }
    return node;
  }

  /// Tab out of the open menu: close it, then move on from the trigger (a
  /// region's menu, from what held focus as it opened) once the menu has
  /// left the tree, so traversal never lands on a closing item.
  void _tabOut(PopoverController c, {required bool forward}) {
    final from = _returnNode;
    c.close();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nodes = _anchorNode.traversalDescendants.toList();
      final trigger =
          from ??
          nodes
              .where((node) => !node.ancestors.any(nodes.contains))
              .firstOrNull;
      if (trigger == null) return;
      forward ? trigger.nextFocus() : trigger.previousFocus();
    });
  }

  /// Escape in a region's menu: close it and hand focus back to what held
  /// it as the menu opened.
  void _escape(PopoverController c) {
    final back = _returnNode;
    c.close();
    back?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Popover(
      side: widget.side,
      align: widget.align,
      gap: widget.gap,
      closeOnFocusOut: widget.closeOnFocusOut,
      onOpenChanged: widget.onOpenChanged,
      anchor: (context, c) => Focus(
        focusNode: _anchorNode,
        includeSemantics: false,
        onKeyEvent: (_, event) => _onTriggerKey(c, event),
        child: widget.builder(context, c),
      ),
      content: (context, c) {
        final last = _openOnLast;
        _openOnLast = false;
        return _MenuPanel(
          entries: widget._entriesOf?.call(context) ?? widget.entries,
          header: widget.header,
          controller: c,
          tree: _MenuTree(
            close: c.close,
            tabOut: (forward) => _tabOut(c, forward: forward),
            minWidth: widget.minWidth,
            maxWidth: widget.maxWidth,
          ),
          startOnLast: last,
          onEscape: widget._returnFocus == null ? null : () => _escape(c),
        );
      },
    );
  }
}

/// What every level of one open menu shares.
class _MenuTree {
  /// Closes every level.
  final VoidCallback close;

  /// Closes every level and moves focus on from the trigger: forward when
  /// true, back when false.
  final ValueChanged<bool> tabOut;

  final double minWidth;
  final double maxWidth;

  const _MenuTree({
    required this.close,
    required this.tabOut,
    required this.minWidth,
    required this.maxWidth,
  });
}

/// A panel's handle on one of its [MenuSubmenu] rows: the row's popover once
/// it is built, and the panel it opens.
class _SubmenuLink {
  PopoverController? controller;
  final panel = GlobalKey<_MenuPanelState>();

  /// Whether the pointer resting on the row opened it, rather than a click
  /// or a key: a click then keeps it open instead of closing it.
  bool openedByHover = false;

  bool get isOpen => controller?.isOpen ?? false;

  /// The open submenu's box, in global coordinates.
  Rect? get panelRect {
    final box = panel.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// The way from a submenu's row to the open submenu, which the pointer may
/// cross over other rows without closing it, as Radix's pointer grace: the
/// triangle from where the pointer left the row to the submenu's near edge.
class _PointerGrace {
  final Offset from;
  final Offset top;
  final Offset bottom;

  const _PointerGrace(this.from, this.top, this.bottom);

  /// The grace from [exit], where the pointer left the row, to [submenu].
  /// Its tip stands a little behind the exit, so the pointer's next move,
  /// however slight, is inside it.
  factory _PointerGrace.toward(Offset exit, Rect submenu) {
    final right = submenu.center.dx > exit.dx;
    final edge = right ? submenu.left : submenu.right;
    return _PointerGrace(
      exit.translate(right ? -5 : 5, 0),
      Offset(edge, submenu.top),
      Offset(edge, submenu.bottom),
    );
  }

  bool contains(Offset p) {
    double side(Offset a, Offset b) =>
        (b.dx - a.dx) * (p.dy - a.dy) - (b.dy - a.dy) * (p.dx - a.dx);
    final d1 = side(from, top);
    final d2 = side(top, bottom);
    final d3 = side(bottom, from);
    final negative = d1 < 0 || d2 < 0 || d3 < 0;
    final positive = d1 > 0 || d2 > 0 || d3 > 0;
    return !(negative && positive);
  }
}

/// One level of the open menu: the surface, its rows, and the keyboard and
/// pointer model over them.
class _MenuPanel extends StatefulWidget {
  final List<MenuEntry> entries;

  /// [Menu.header]; a submenu has none.
  final Widget? header;

  /// This level's popover.
  final PopoverController controller;

  final _MenuTree tree;
  final bool startOnLast;

  /// A submenu's panel: ← (→ in a right-to-left app) closes it, and a
  /// pointer open leaves focus on its row in the parent.
  final bool submenu;

  /// Called as the pointer enters a submenu's panel, which keeps it open.
  final VoidCallback? onPointerEnter;

  /// Answers Escape in place of the popover, which closes it and focuses its
  /// trigger.
  final VoidCallback? onEscape;

  const _MenuPanel({
    super.key,
    required this.entries,
    this.header,
    required this.controller,
    required this.tree,
    this.startOnLast = false,
    this.submenu = false,
    this.onPointerEnter,
    this.onEscape,
  });

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  static const _typeaheadWindow = Duration(seconds: 1);

  /// How long the pointer rests on a submenu's row before it opens, and how
  /// long it may spend over other rows before an open one closes: Radix's
  /// timings, long enough to cross a row on the way in.
  static const _openDelay = Duration(milliseconds: 100);
  static const _closeDelay = Duration(milliseconds: 150);

  final _panelNode = FocusNode(debugLabel: 'Menu', skipTraversal: true);
  final _scroll = ScrollController();

  /// One node per row that takes focus, in order. Kept across rebuilds by
  /// position, so a host rebuilding with a fresh `entries` list leaves the
  /// highlighted item focused.
  final List<FocusNode> _itemNodes = [];

  /// [_itemNodes] laid over the entries; null for dividers and headers.
  List<FocusNode?> _nodes = const [];

  /// One link per [MenuSubmenu] row, kept by position as [_itemNodes] are.
  final List<_SubmenuLink> _submenus = [];

  /// [_submenus] laid over the entries; null for every other entry.
  List<_SubmenuLink?> _links = const [];

  /// Whether the pointer, rather than a key, put the highlight where it is —
  /// so a row the list scrolls away from under a still pointer keeps it.
  bool _pointerDriven = false;

  String _typed = '';
  Timer? _typedReset;

  /// The row under the pointer.
  int? _hovered;
  Timer? _openTimer;
  Timer? _closeTimer;
  _PointerGrace? _grace;

  @override
  void initState() {
    super.initState();
    _syncNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final enabled = _enabledIndexes;
      if (Popover.openedByKeyboard(context) && enabled.isNotEmpty) {
        _focusItem(widget.startOnLast ? enabled.last : enabled.first);
      } else if (!widget.submenu) {
        _panelNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(_MenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  @override
  void dispose() {
    _typedReset?.cancel();
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _panelNode.dispose();
    _scroll.dispose();
    for (final node in _itemNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    final entries = widget.entries;
    final rows = entries.where((entry) => entry._rowLabel != null).length;
    while (_itemNodes.length > rows) {
      // The row it served unmounts in the coming build, still holding it.
      final node = _itemNodes.removeLast();
      WidgetsBinding.instance.addPostFrameCallback((_) => node.dispose());
    }
    while (_itemNodes.length < rows) {
      _itemNodes.add(FocusNode());
    }
    final submenus = entries.whereType<MenuSubmenu>().length;
    if (_submenus.length > submenus) _submenus.length = submenus;
    while (_submenus.length < submenus) {
      _submenus.add(_SubmenuLink());
    }
    var k = 0;
    var s = 0;
    _nodes = [
      for (final entry in entries)
        if (entry._rowLabel case final label?)
          (_itemNodes[k++]..debugLabel = label)
        else
          null,
    ];
    _links = [
      for (final entry in entries)
        if (entry is MenuSubmenu) _submenus[s++] else null,
    ];
  }

  List<int> get _enabledIndexes => [
    for (var i = 0; i < widget.entries.length; i++)
      if (widget.entries[i]._rowEnabled) i,
  ];

  int? get _focusedIndex {
    for (var i = 0; i < _nodes.length; i++) {
      if (_nodes[i]?.hasFocus ?? false) return i;
    }
    return null;
  }

  /// The row whose submenu is open.
  int? get _openSubmenu {
    for (var i = 0; i < _links.length; i++) {
      if (_links[i]?.isOpen ?? false) return i;
    }
    return null;
  }

  void _focusItem(int index, {bool pointer = false}) {
    final node = _nodes[index];
    if (node == null) return;
    // The keyboard moving on closes a submenu at once; the pointer gives it
    // a grace, see [_onPointerMove].
    if (!pointer) _closeSubmenus(except: index);
    _pointerDriven = pointer;
    node.requestFocus();
    final itemContext = node.context;
    if (!pointer && itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      Scrollable.ensureVisible(
        itemContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  /// Focuses the first enabled row, as a submenu opened from the keyboard.
  void _focusFirst() {
    final enabled = _enabledIndexes;
    if (enabled.isNotEmpty) _focusItem(enabled.first);
  }

  void _move(int delta) {
    final enabled = _enabledIndexes;
    if (enabled.isEmpty) return;
    final at = enabled.indexOf(_focusedIndex ?? -1);
    final next = at < 0
        ? (delta > 0 ? 0 : enabled.length - 1)
        : (at + delta) % enabled.length;
    _focusItem(enabled[next]);
  }

  /// Radix's typeahead: letters typed within a second of each other build a
  /// prefix; a repeated single letter cycles through the items starting with
  /// it.
  void _typeahead(String char) {
    _typedReset?.cancel();
    _typedReset = Timer(_typeaheadWindow, () => _typed = '');
    _typed += char.toLowerCase();
    final repeated = _typed.split('').every((c) => c == _typed[0]);
    final search = repeated ? _typed[0] : _typed;

    final enabled = _enabledIndexes;
    if (enabled.isEmpty) return;
    final current = _focusedIndex;
    final start = current == null ? 0 : enabled.indexOf(current);
    final order = [
      for (var k = 0; k < enabled.length; k++)
        enabled[(start + k) % enabled.length],
    ];
    if (search.length == 1 && current != null) order.remove(current);
    for (final i in order) {
      final label = widget.entries[i]._rowLabel!;
      if (label.toLowerCase().startsWith(search)) {
        if (i != current) _focusItem(i);
        return;
      }
    }
  }

  /// Opens the submenu of the row at [index], closing any other; from the
  /// keyboard, with [focusFirst], on its first item.
  void _openSubmenuAt(
    int index, {
    bool focusFirst = false,
    bool hover = false,
  }) {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _grace = null;
    _closeSubmenus(except: index);
    final link = _links[index]!;
    if (link.isOpen) {
      if (!hover) link.openedByHover = false;
      if (focusFirst) link.panel.currentState?._focusFirst();
      return;
    }
    link.openedByHover = hover;
    // Opened while the key is down, the submenu focuses its first item.
    link.controller?.open();
  }

  /// A click on a submenu's row: opens it, or closes one a click opened.
  void _clickSubmenu(int index) {
    final link = _links[index]!;
    if (!link.isOpen || link.openedByHover) {
      _openSubmenuAt(index);
    } else {
      link.controller?.close();
    }
  }

  void _closeSubmenus({int? except}) {
    _closeTimer?.cancel();
    for (var i = 0; i < _links.length; i++) {
      final link = _links[i];
      if (i != except && link != null && link.isOpen) {
        link.controller?.close();
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // A key an open submenu left alone is not this level's to answer.
    final primary = FocusManager.instance.primaryFocus;
    if (primary != _panelNode && !_itemNodes.contains(primary)) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final down = event is KeyDownEvent;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final inward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final outward = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == inward ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final focused = _focusedIndex;
      if (focused != null && _links[focused] != null) {
        if (down) _openSubmenuAt(focused, focusFirst: true);
        return KeyEventResult.handled;
      }
      // Enter and Space run the row itself.
      return key == inward ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (key == outward) {
      // A menu has no neighbour to move to: the key is spent here rather
      // than moving focus out of it.
      if (down && widget.submenu) Popover.dismiss(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && widget.onEscape != null) {
      if (down) widget.onEscape!();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
      final enabled = _enabledIndexes;
      if (enabled.isNotEmpty) {
        _focusItem(
          key == LogicalKeyboardKey.home ? enabled.first : enabled.last,
        );
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      if (down) {
        widget.tree.tabOut(!HardwareKeyboard.instance.isShiftPressed);
      }
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    final char = event.character;
    if (char != null &&
        char.length == 1 &&
        char.trim().isNotEmpty &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed &&
        !keyboard.isAltPressed) {
      _typeahead(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// [_onKey] for a submenu's row, which answers before the popover it
  /// anchors, whose own keys would take the arrows and Escape: Escape
  /// closes this level, as it would from any other row.
  KeyEventResult _onSubmenuRowKey(FocusNode node, KeyEvent event) {
    final result = _onKey(node, event);
    if (result != KeyEventResult.ignored ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return result;
    }
    Popover.dismiss(context);
    return KeyEventResult.handled;
  }

  /// The pointer moving over the row at [index]. With another row's submenu
  /// open, that submenu closes after [_closeDelay] unless the pointer
  /// reaches it first, and the highlight stays on its row while the pointer
  /// is on the way there.
  void _onPointerMove(int index, Offset position) {
    _hovered = index;
    final open = _openSubmenu;
    if (open != null && open != index) {
      _closeAfterGrace();
      if (_grace?.contains(position) ?? false) return;
    } else if (open == index) {
      _closeTimer?.cancel();
    }
    _grace = null;
    _hover(index);
  }

  /// Highlights the row at [index] under the pointer, and a submenu's row
  /// opens its submenu once the pointer has rested on it for [_openDelay].
  void _hover(int index) {
    if (widget.entries[index]._rowEnabled) {
      if (!(_nodes[index]?.hasPrimaryFocus ?? false)) {
        _focusItem(index, pointer: true);
      }
      final link = _links[index];
      if (link != null && !link.isOpen && !(_openTimer?.isActive ?? false)) {
        _openTimer = Timer(_openDelay, () {
          if (mounted && _hovered == index) {
            _openSubmenuAt(index, hover: true);
          }
        });
      }
    } else if (_focusedIndex != null) {
      _pointerDriven = true;
      _panelNode.requestFocus();
    }
  }

  void _onPointerExit(int index, Offset position) {
    if (_hovered == index) _hovered = null;
    _openTimer?.cancel();
    final link = _links[index];
    if (link != null && link.isOpen) {
      // On its way into the submenu: the row keeps the highlight, and the
      // keys, until the pointer settles elsewhere.
      if (link.panelRect case final submenu?) {
        _grace = _PointerGrace.toward(position, submenu);
      }
      return;
    }
    if (_pointerDriven && (_nodes[index]?.hasFocus ?? false)) {
      _panelNode.requestFocus();
    }
  }

  void _onSubmenuEntered() {
    _closeTimer?.cancel();
    _grace = null;
  }

  void _closeAfterGrace() {
    if (_closeTimer?.isActive ?? false) return;
    _closeTimer = Timer(_closeDelay, () {
      if (!mounted) return;
      _grace = null;
      final open = _openSubmenu;
      final hovered = _hovered;
      if (open == null || open == hovered) return;
      _links[open]!.controller?.close();
      if (hovered != null) _hover(hovered);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final iconColumn = entries.any(
      (entry) => switch (entry) {
        MenuItem(:final icon) ||
        MenuCheckboxItem(:final icon) ||
        MenuSubmenu(:final icon) => icon != null,
        MenuDivider() || MenuHeader() => false,
      },
    );
    Widget list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Gap(AdminSpacing.xs),
        for (var i = 0; i < entries.length; i++)
          if (_nodes[i] != null)
            _MenuRow(
              entry: entries[i],
              tree: widget.tree,
              focusNode: _nodes[i],
              onPointerMove: (position) => _onPointerMove(i, position),
              onPointerExit: (position) => _onPointerExit(i, position),
              submenu: _links[i],
              onSubmenuClick: () => _clickSubmenu(i),
              onSubmenuEntered: _onSubmenuEntered,
              onSubmenuKey: _onSubmenuRowKey,
              iconColumn: iconColumn,
            )
          else
            Menu.entry(context, entries[i], widget.controller),
        const Gap(AdminSpacing.xs),
      ],
    );
    if (entries.isNotEmpty) {
      list = Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.menu,
        child: list,
      );
    }
    if (widget.header case final header?) {
      list = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.lg,
              AdminSpacing.md,
              AdminSpacing.lg,
              AdminSpacing.sm,
            ),
            child: header,
          ),
          if (entries.isNotEmpty) const _MenuDividerRow(),
          list,
        ],
      );
    }
    Widget panel = PopoverMenuSurface(
      minWidth: widget.tree.minWidth,
      maxWidth: widget.tree.maxWidth,
      fitAvailableHeight: true,
      child: Focus(
        focusNode: _panelNode,
        onKeyEvent: _onKey,
        // A menu capped short of its rows keeps its scrollbar showing, so
        // the rows below the cap are not a secret.
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(controller: _scroll, child: list),
          ),
        ),
      ),
    );
    if (widget.onPointerEnter case final onEnter?) {
      // Opaque, so the popover's tap region around the panel counts a press
      // on it as inside the menu, and a level it lies over gets no pointer.
      panel = MouseRegion(onEnter: (_) => onEnter(), child: panel);
    }
    return panel;
  }
}

/// A row that takes focus: a [MenuItem], a [MenuCheckboxItem] or a
/// [MenuSubmenu], whose row also anchors its submenu's popover.
class _MenuRow extends StatefulWidget {
  final MenuEntry entry;
  final _MenuTree tree;

  /// Set inside a [Menu], whose panel moves focus between rows; the row is
  /// then a menu item, highlighted while it holds focus.
  final FocusNode? focusNode;
  final ValueChanged<Offset>? onPointerMove;
  final ValueChanged<Offset>? onPointerExit;

  /// A [MenuSubmenu] row's link to its panel, which opens and closes the
  /// submenu for the pointer and the keys; outside a [Menu] a tap toggles
  /// it.
  final _SubmenuLink? submenu;
  final VoidCallback? onSubmenuClick;
  final VoidCallback? onSubmenuEntered;
  final FocusOnKeyEventCallback? onSubmenuKey;

  /// Whether a row of the same menu carries an icon: a row without one then
  /// keeps its place empty, so every label starts in one column, as
  /// Fluent's and Carbon's menus line them up.
  final bool iconColumn;

  const _MenuRow({
    required this.entry,
    required this.tree,
    this.focusNode,
    this.onPointerMove,
    this.onPointerExit,
    this.submenu,
    this.onSubmenuClick,
    this.onSubmenuEntered,
    this.onSubmenuKey,
    this.iconColumn = false,
  });

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  /// Rows are this tall at the default text size, as shadcn's, Ant's,
  /// Fluent's and Carbon's compact menus are.
  static const _rowHeight = 32.0;

  bool _focused = false;

  bool get _inMenu => widget.focusNode != null;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    Widget child;
    if (entry is MenuSubmenu) {
      child = Popover(
        side: PopoverSide.end,
        align: PopoverAlign.start,
        // The submenu's first row level with this one, past its panel's
        // top inset; its edge on this row's highlight, over the parent's
        // side inset, as Radix's.
        alignOffset: -AdminSpacing.xs,
        gap: 0,
        autofocus: false,
        anchor: (context, c) {
          widget.submenu?.controller = c;
          final row = _row(
            context,
            onTap: widget.onSubmenuClick ?? c.toggle,
            open: c.isOpen,
          );
          final onKey = widget.onSubmenuKey;
          if (onKey == null) return row;
          return Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onKeyEvent: onKey,
            child: row,
          );
        },
        content: (context, c) => _MenuPanel(
          key: widget.submenu?.panel,
          entries: entry.entries,
          controller: c,
          tree: widget.tree,
          submenu: true,
          onPointerEnter: widget.onSubmenuEntered,
        ),
      );
    } else if (entry case MenuItem(:final uri?, :final target)) {
      // A real anchor (web) so right-click / ⌘-click / middle-click hit the
      // browser; left-click follows the link and closes the menu.
      child = Link(
        uri: uri,
        target: target,
        builder: (context, followLink) => _row(
          context,
          onTap: () {
            followLink?.call();
            widget.tree.close();
          },
        ),
      );
    } else {
      child = _row(context, onTap: _select);
    }

    if (widget.onPointerMove != null) {
      // Movement, not entry: a row the list scrolls under a still pointer
      // must not take the highlight from the keyboard.
      child = MouseRegion(
        onHover: (event) => widget.onPointerMove!(event.position),
        onExit: (event) => widget.onPointerExit?.call(event.position),
        child: child,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs),
      child: child,
    );
  }

  /// Choosing an item or a checkbox: closes the menu, every level of it,
  /// then acts.
  void _select() {
    switch (widget.entry) {
      case MenuItem(:final onSelect?):
        widget.tree.close();
        onSelect();
      case MenuCheckboxItem(:final onChanged?, :final checked, :final keepOpen):
        if (!keepOpen) widget.tree.close();
        onChanged(!checked);
      default:
    }
  }

  Widget _row(
    BuildContext context, {
    required VoidCallback onTap,
    bool open = false,
  }) {
    final entry = widget.entry;
    final enabled = entry._rowEnabled;
    final colors = context.colors;
    final type = context.type;
    final radius = context.radii.radiusSmall;
    final (icon, description, shortcut, danger) = switch (entry) {
      final MenuItem item => (
        item.icon,
        item.description,
        item.shortcut,
        item.danger,
      ),
      final MenuCheckboxItem item => (
        item.icon,
        item.description,
        item.shortcut,
        false,
      ),
      final MenuSubmenu submenu => (
        submenu.icon,
        submenu.description,
        null,
        false,
      ),
      MenuDivider() || MenuHeader() => (null, null, null, false),
    };
    final checked = switch (entry) {
      MenuItem(:final checked) => checked,
      MenuCheckboxItem(:final checked) => checked,
      _ => null,
    };

    final fg = !enabled
        ? colors.foregroundSubtle
        : danger
        ? colors.dangerText
        : colors.foreground;
    final highlightFill = danger
        ? Color.alphaBlend(
            colors.danger.withValues(alpha: colors.stateLayer.tintHover),
            colors.surface,
          )
        : colors.listHighlight;
    final muted = colors.readableOn(
      colors.foregroundMuted,
      surfaces: [colors.surface, highlightFill],
    );
    // 32 tall on a one-line row whatever the theme's body line: 6 above and
    // below a 20px line, 5 around Ant's 22.
    final body = type.body;
    final line = (body.fontSize ?? 14) * (body.height ?? 1);
    final inset = ((_rowHeight - line) / 2).clamp(
      AdminSpacing.xxs,
      AdminSpacing.sm,
    );

    return Tappable.states(
      onTap: enabled ? onTap : null,
      focusNode: widget.focusNode,
      showFocusRing: false,
      role: !_inMenu
          ? null
          : switch (entry) {
              MenuCheckboxItem() => SemanticsRole.menuItemCheckbox,
              MenuItem(checked: _?) => SemanticsRole.menuItemRadio,
              _ => SemanticsRole.menuItem,
            },
      checked: checked,
      inMutuallyExclusiveGroup: entry is MenuItem && entry.checked != null,
      expanded: entry is MenuSubmenu ? open : null,
      onFocusChange: (focused) {
        if (_inMenu) setState(() => _focused = focused);
      },
      builder: (context, states) {
        final highlighted =
            enabled &&
            (open ||
                (_inMenu
                    ? _focused
                    : states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)));
        return DecoratedBox(
          decoration: BoxDecoration(
            color: highlighted ? highlightFill : null,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AdminSpacing.md,
              vertical: inset,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 20),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: context.iconSizes.md, color: fg),
                    const Gap(AdminSpacing.md),
                  ] else if (widget.iconColumn)
                    Gap(context.iconSizes.md + AdminSpacing.md),
                  Expanded(
                    child: _label(context, fg, description, muted, enabled),
                  ),
                  if (shortcut != null) ...[
                    const Gap(AdminSpacing.lg),
                    Text(
                      shortcut,
                      // Physical: shortcuts read left to right.
                      textDirection: TextDirection.ltr,
                      style: type.caption.copyWith(color: muted),
                    ),
                  ],
                  if (checked != null) ...[
                    const Gap(AdminSpacing.lg),
                    SizedBox.square(
                      dimension: 16,
                      child: checked
                          ? Icon(
                              Icons.check_rounded,
                              size: context.iconSizes.md,
                              color: fg,
                            )
                          : null,
                    ),
                  ],
                  if (entry is MenuSubmenu) ...[
                    const Gap(AdminSpacing.lg),
                    // Toward the end side, where the submenu opens unless
                    // it has to flip: mirrors in a right-to-left app.
                    Icon(
                      Icons.chevron_right_rounded,
                      size: context.iconSizes.md,
                      color: enabled ? muted : fg,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The label, and under it the row's description when it has one.
  Widget _label(
    BuildContext context,
    Color fg,
    String? description,
    Color muted,
    bool enabled,
  ) {
    final label = Text(
      widget.entry._rowLabel!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.type.body.copyWith(color: fg),
    );
    if (description == null) return label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        Text(
          description,
          style: context.type.caption.copyWith(color: enabled ? muted : fg),
        ),
      ],
    );
  }
}

class _MenuDividerRow extends StatelessWidget {
  const _MenuDividerRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
      child: Divider(
        height: context.stroke.hairline,
        thickness: context.stroke.hairline,
        color: context.colors.separator,
      ),
    );
  }
}

class _MenuHeaderRow extends StatelessWidget {
  final MenuHeader header;

  const _MenuHeaderRow(this.header);

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final capitals = type.spec.uppercaseLabels;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.lg,
        AdminSpacing.md,
        AdminSpacing.lg,
        AdminSpacing.xs,
      ),
      // A 16px line box keeps the header on the rows' 4px grid: 28 tall, 32
      // on Ant's 20px caption line.
      child: Container(
        constraints: const BoxConstraints(minHeight: 16),
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          capitals ? header.label.toUpperCase() : header.label,
          semanticsLabel: capitals ? header.label : null,
          style: capitals
              ? type.micro
              : type.weighted(type.caption, type.spec.strong),
        ),
      ),
    );
  }
}
