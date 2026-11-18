import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind, SemanticsRole;

import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/avatar.dart';
import '../../common/ui/chrome_theme.dart';
import '../../common/ui/focus_ring.dart';
import '../../common/ui/leave_guard.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/contrast.dart';
import '../../theme/shell_style.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'navigation_drawer.dart';
import 'shell.dart';

/// One entry in a [Sidebar]: a [NavItem], a [NavGroup] that folds several
/// items under one row, or a [NavSection] header.
sealed class NavEntry {
  const NavEntry();
}

/// A navigation row. It is the current one when its [value] is the
/// [Sidebar.selected] one, or when [selected] says so; a null [onTap]
/// renders it inert. [badge] shows a trailing count.
class NavItem extends NavEntry {
  final String label;
  final IconData icon;
  final String? badge;

  /// Marks the row current whatever [Sidebar.selected] is.
  final bool selected;

  /// What the row stands for, such as the destination a route belongs to:
  /// the row is current when it equals [Sidebar.selected]. Null matches
  /// nothing.
  final Object? value;
  final VoidCallback? onTap;

  /// Whether opening the item leaves the page: it then first awaits
  /// [LeaveGuardScope.confirmLeave], and calls [onTap] only once the user
  /// lets the page's unsaved edits go. False for an item that keeps the
  /// page, such as one opening a panel, which opens at once.
  final bool guarded;

  /// Reports, and can seed, the row's hovered, pressed and focused states —
  /// e.g. to pin a hover in a catalog. Created internally when null.
  final WidgetStatesController? statesController;

  /// The key of the row built for this item, to find it by in a test.
  final Key? key;

  const NavItem(
    this.label, {
    this.key,
    required this.icon,
    this.badge,
    this.selected = false,
    this.value,
    this.onTap,
    this.guarded = true,
    this.statesController,
  });

  /// Whether the row is current in a sidebar whose selection is [current].
  bool _isSelected(Object? current) =>
      selected || (value != null && value == current);
}

/// A row that folds its [items] under it, for the pages few people open.
/// Closed, it is one row: its [icon], its [label], the number of its items
/// and a chevron. Open, the items follow it, a step in.
///
/// The sidebar keeps whether it is open, from [initiallyExpanded] on, and
/// opens it as the current item becomes one of its [items], so a deep link
/// shows where the user is. It can then be closed like any other, and
/// while it hides the current item its own row is drawn as the current
/// one. Pass [expanded] to control it instead, applying what
/// [onExpandedChanged] reports.
///
/// In the collapsed rail it is its icon alone, with its label in a tooltip
/// and none of its items; a click there opens the rail over the page, and
/// the group with it. In the open rail and in a navigation drawer it is as
/// in the whole sidebar.
///
/// Its row is a button announced as expanded or collapsed, which Enter or
/// Space toggles. Opening or closing it keeps the page, so it asks no leave
/// guard; its items ask as any item does.
class NavGroup extends NavEntry {
  final String label;
  final IconData icon;

  /// The rows folded under this one.
  final List<NavItem> items;

  /// Whether it starts open, when uncontrolled.
  final bool initiallyExpanded;

  /// Whether it is open, when controlled: then exactly as this says,
  /// whatever the current item. Null leaves it to the sidebar.
  final bool? expanded;

  /// Reports the state a click or a key on the row asks for. Required to
  /// change a controlled group; an uncontrolled one calls it too, for an
  /// app that remembers the state and hands it back as [initiallyExpanded].
  final ValueChanged<bool>? onExpandedChanged;

  /// Reports, and can seed, the row's hovered, pressed and focused states,
  /// as [NavItem.statesController] does.
  final WidgetStatesController? statesController;

  /// The key of the row built for this group, to find it by in a test. The
  /// sidebar also knows the group by it across rebuilds, or by its [label]
  /// without one: two groups under one label each need a key.
  final Key? key;

  const NavGroup(
    this.label, {
    this.key,
    required this.icon,
    required this.items,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpandedChanged,
    this.statesController,
  });

  Object get _id => key ?? label;

  /// The place among [items] of the current one in a sidebar whose
  /// selection is [current], or -1.
  int _currentIn(Object? current) =>
      items.indexWhere((item) => item._isSelected(current));
}

/// A small uppercase caption grouping items below it. Hidden when collapsed.
class NavSection extends NavEntry {
  final String label;
  const NavSection(this.label);
}

/// What a [Sidebar] keeps of a [NavGroup].
class _GroupState {
  bool open;

  /// [NavGroup._currentIn], as of the last build.
  int current;

  _GroupState({required this.open, required this.current});
}

/// A row a key can stand on: [item], on its own or under [group], or with
/// no item [group]'s own row.
typedef _Row = ({NavItem? item, NavGroup? group});

/// The navigation column at the [Shell]'s leading edge: an optional [header]
/// (workspace / logo), the scrolling [entries], and an optional pinned
/// [footer] (the user). [collapsed] switches to an icon-only rail, each item's
/// label moving to its tooltip. Its hairline is on its trailing edge, against
/// the page, on the right in a left-to-right layout and on the left in a
/// right-to-left one.
///
/// The rail opens over the page, expanded, with a shadow on its edge, and the
/// page does not move. It opens when the pointer rests on it for
/// [railOpenDelay], and when keyboard focus enters it. It closes when the
/// pointer leaves it, when focus leaves it, on Escape, on a press outside
/// it, and as an item opens. While a menu opened from it (a
/// [SidebarAccount]'s) holds focus, it stays open. A click on the rail
/// before it opens keeps it shut until the pointer leaves, unless it is on
/// a [NavGroup]'s icon, which opens the rail at once to show the group's
/// items. Between a [Shell]'s breakpoints the rail also gives the top bar
/// its menu button, which opens the navigation drawer, for a touch screen.
///
/// The current item is the one whose [NavItem.value] equals [selected], so
/// a router that knows which destination a route belongs to passes that,
/// and builds the items once. An item can also mark itself
/// ([NavItem.selected]).
///
/// It paints the device's top and bottom insets in its own colour, keeping
/// its content clear of them: under a [Shell]'s top bar only the bottom one
/// is left, under its footer. Beside a top bar that spans the page alone
/// (`AdminShellStyle.topBarSpan`), it runs the window's height and keeps
/// both, and its head, as tall as the bar, holds the bar's `leading`: at the
/// shell's inset in the whole sidebar, centred in the rail, where it reads
/// [isCollapsed] to draw a form that fits (the mark without the wordmark).
/// It is laid out at its own width, as the bar lays it out, and clipped to
/// the sidebar. In the compact [Shell]'s navigation drawer it
/// draws expanded and as wide as the drawer, whatever [collapsed] says,
/// under the drawer's head, and closes the drawer as an item opens.
///
/// Its geometry is the theme's `AdminShellStyle` (`context.shellStyle`): the
/// widths ([widthOf]), the items' height, gap, padding, corner and glyph, and
/// how the selected item is marked. A style with a `sidebarPalette` draws
/// the whole column in that palette (Ant's dark sider), [header] and
/// [footer] included: build those with a context below the sidebar (a
/// [Builder]) for them to read it.
///
/// The column is a navigation landmark named [semanticLabel]. Every item on
/// the screen is a Tab stop announced as a button, the current one as
/// selected; ArrowUp and ArrowDown (Home and End) move focus between them,
/// and Enter or Space opens one. A [NavGroup]'s row is one more such
/// button, announced as expanded or collapsed, which Enter or Space
/// toggles; its items are stops only while it is open, and focus on one
/// goes to the group's row as they fold away.
///
/// An item leaves the page only as the page lets it: opening one, by
/// pointer or key, first awaits [LeaveGuardScope.confirmLeave], so a form
/// with unsaved edits asks whether to discard them. Cancelling keeps the
/// page, and keeps focus on the item. An item with [NavItem.guarded] false
/// opens at once, as a group opens and closes: it keeps the page.
class Sidebar extends StatefulWidget {
  final List<NavEntry> entries;

  /// Above the items (a workspace or logo), in the sidebar's palette: build
  /// a widget that reads the colours itself below the sidebar, in a
  /// [Builder], or it keeps the page's.
  final Widget? header;

  /// Pinned under the items (the user, as a [SidebarAccount]), in the
  /// sidebar's palette, as [header].
  final Widget? footer;
  final bool collapsed;

  /// The navigation landmark's name, read as a screen reader enters it;
  /// "Navigation" in the app's language when null.
  final String? semanticLabel;

  /// The [NavItem.value] of the current item. Null leaves it to the items'
  /// own [NavItem.selected].
  final Object? selected;

  const Sidebar({
    super.key,
    required this.entries,
    this.header,
    this.footer,
    this.collapsed = false,
    this.semanticLabel,
    this.selected,
  });

  /// The expanded width under the default `AdminShellStyle`; a theme sets
  /// its own, so read [widthOf].
  static const expandedWidth = 240.0;

  /// The collapsed rail's width under the default `AdminShellStyle`; a theme
  /// sets its own, so read [widthOf].
  static const collapsedWidth = 64.0;

  /// The most of the window an expanded sidebar wider than [expandedWidth]
  /// takes: a theme's wide drawer (M3's 360, which M3 stands beside the page
  /// only in an expanded window) narrows in a small window rather than
  /// squeezing the page.
  static const maxWindowShare = 0.4;

  /// How long the pointer rests on a [collapsed] rail before it opens over
  /// the page: short of an item's tooltip, so the rail opens rather than the
  /// tooltip, and long enough that a pointer crossing it on its way to the
  /// page leaves it shut.
  static const railOpenDelay = Duration(milliseconds: 200);

  /// The sidebar's width in [context]'s theme: its style's `sidebarWidth`,
  /// or its `railWidth` when [collapsed]. Expanded, it keeps to
  /// [maxWindowShare] of the window (`MediaQuery.sizeOf`), down to
  /// [expandedWidth] and never wider than the style's. In a navigation
  /// drawer, the drawer's width.
  static double widthOf(BuildContext context, {bool collapsed = false}) {
    if (NavigationDrawerScope.maybeOf(context) case final drawer?) {
      return drawer.width;
    }
    final style = context.shellStyle;
    if (collapsed) return style.railWidth;
    final window = MediaQuery.maybeSizeOf(context)?.width;
    if (window == null) return style.sidebarWidth;
    return math.min(
      style.sidebarWidth,
      math.max(expandedWidth, window * maxWindowShare),
    );
  }

  /// Whether the [Sidebar] above [context] draws as the collapsed rail:
  /// false when it is expanded, in a navigation drawer (which draws it
  /// expanded whatever [collapsed] says), and outside a sidebar. A [header]
  /// or [footer] reads it to fit the rail.
  static bool isCollapsed(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SidebarScope>()?.collapsed ??
      false;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarScope extends InheritedWidget {
  final bool collapsed;

  /// Called as an item opens, before its `onTap`.
  final VoidCallback onItemOpen;

  const _SidebarScope({
    required this.collapsed,
    required this.onItemOpen,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SidebarScope old) => collapsed != old.collapsed;
}

/// Where a collapsed rail is.
enum _Rail {
  /// In its place beside the page.
  shut,

  /// Expanded over the page.
  open,

  /// Folding back to the rail's width over the page, before it returns to
  /// its place.
  closing,
}

class _SidebarState extends State<Sidebar> {
  /// One node per row of [_rows], in order, so the arrow keys can step
  /// between them. An item folded away keeps its node, so the rows after
  /// it keep theirs as a group opens and closes.
  final _nodes = <FocusNode>[];

  /// What is kept of each [NavGroup], by its [NavGroup._id].
  final _groups = <Object, _GroupState>{};

  /// The column, which moves to the overlay while the rail is open and back
  /// to its place after, keeping its scroll, focus and hover.
  final _column = GlobalKey(debugLabel: 'Sidebar column');
  final _portal = OverlayPortalController(debugLabel: 'Sidebar rail');

  /// Has focus while focus is anywhere in the column, or in a menu opened
  /// from it.
  final _focus = FocusNode(
    debugLabel: 'Sidebar',
    canRequestFocus: false,
    skipTraversal: true,
  );

  var _rail = _Rail.shut;

  /// Whether the sidebar draws as a collapsed rail, as of its last build.
  var _isRail = false;

  /// Whether the column is drawn at the rail's width, as of its last build:
  /// the items of its groups are then out of sight.
  var _columnCollapsed = false;

  /// Focus is going to a group's row as the rail folds over the item that
  /// held it: no key moved it, so it does not open the rail again.
  var _foldingFocus = false;

  /// Runs while the pointer rests on the shut rail, until it opens it.
  Timer? _rest;

  /// The pointer is over the rail in its place.
  var _overRail = false;

  /// The pointer is over the rail opened over the page.
  var _overOpen = false;

  /// The rail stays shut under the pointer that clicked it or opened an item
  /// from it, until that pointer leaves.
  var _held = false;

  /// The last input was a key, not a press: focus moving in the column is
  /// the keyboard's. Flutter's own highlight mode cannot say, since a
  /// desktop starts in its keyboard mode and a mouse never leaves it.
  var _byKeyboard = false;

  /// Every row a key can stand on, in order: each item, and each group's
  /// own row ahead of its items, shown or not.
  List<_Row> get _rows => [
    for (final entry in widget.entries)
      if (entry is NavItem)
        (item: entry, group: null)
      else if (entry is NavGroup) ...[
        (item: null, group: entry),
        for (final item in entry.items) (item: item, group: entry),
      ],
  ];

  @override
  void initState() {
    super.initState();
    _syncGroups();
    FocusManager.instance.addListener(_onFocus);
    HardwareKeyboard.instance.addHandler(_onKey);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  @override
  void didUpdateWidget(Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGroups();
    _refocusFolded();
  }

  /// Takes each group's state from the entries: a new group starts as it
  /// says, a controlled one is as it says, and the others open as the
  /// current item becomes one of theirs. A group that is gone is forgotten.
  void _syncGroups() {
    final seen = <Object>{};
    for (final entry in widget.entries) {
      if (entry is! NavGroup) continue;
      seen.add(entry._id);
      final current = entry._currentIn(widget.selected);
      final state = _groups[entry._id];
      if (state == null) {
        _groups[entry._id] = _GroupState(
          open: entry.expanded ?? (entry.initiallyExpanded || current >= 0),
          current: current,
        );
        continue;
      }
      if (entry.expanded case final expanded?) {
        state.open = expanded;
      } else if (current >= 0 && current != state.current) {
        state.open = true;
      }
      state.current = current;
    }
    _groups.removeWhere((id, _) => !seen.contains(id));
  }

  bool _isOpen(NavGroup group) => _groups[group._id]!.open;

  /// Whether [row] is on the screen and takes a key: a group's own row, or
  /// a live item that no closed group, and no rail, folds away.
  bool _reachable(_Row row) {
    final (:item, :group) = row;
    if (item == null) return true;
    if (item.onTap == null) return false;
    return group == null || (!_columnCollapsed && _isOpen(group));
  }

  /// Moves focus from an item that is folding away to its group's row, so
  /// it stays on the screen: an item of a closed group, or with [rail] of
  /// any group, as the column folds to the rail. Returns whether it did.
  bool _refocusFolded({bool rail = false}) {
    final rows = _rows;
    var groupRow = 0;
    for (var i = 0; i < rows.length && i < _nodes.length; i++) {
      final (:item, :group) = rows[i];
      if (item == null) groupRow = i;
      if (item == null || group == null || !_nodes[i].hasPrimaryFocus) continue;
      if (!rail && _isOpen(group)) return false;
      _nodes[groupRow].requestFocus();
      return true;
    }
    return false;
  }

  /// Opens or closes [group]; a controlled one only asks its app to.
  void _setGroup(NavGroup group, bool open) {
    final state = _groups[group._id]!;
    if (state.open == open) return;
    if (group.expanded == null) {
      setState(() => state.open = open);
      _refocusFolded();
    }
    group.onExpandedChanged?.call(open);
  }

  /// A click or a key on [group]'s row. In the rail, where its items are
  /// out of sight, it opens the rail over the page and the group with it.
  void _onGroupTap(NavGroup group) {
    if (!_columnCollapsed) {
      _setGroup(group, !_isOpen(group));
      return;
    }
    _setGroup(group, true);
    _open();
  }

  @override
  void dispose() {
    _rest?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    FocusManager.instance.removeListener(_onFocus);
    _focus.dispose();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) _byKeyboard = true;
    return false;
  }

  void _onPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    _byKeyboard = false;
    // A press outside the open rail closes it: a finger, which never
    // leaves it as a mouse does, or a mouse beside a rail a key opened. A
    // press in a menu opened from it is not one.
    if (_rail != _Rail.open || _inColumn(event.position)) return;
    if (_focus.hasFocus && _focusInMenu) return;
    _close();
  }

  /// Whether [position], in the window, is on the column.
  bool _inColumn(Offset position) {
    final column = _column.currentContext?.findRenderObject();
    if (column is! RenderBox || !column.hasSize) return false;
    return column.size.contains(column.globalToLocal(position));
  }

  void _onRailEnter(PointerEnterEvent _) {
    _overRail = true;
    if (!_isRail || _held || _rail != _Rail.shut) return;
    _rest?.cancel();
    _rest = Timer(Sidebar.railOpenDelay, _open);
  }

  void _onRailExit(PointerExitEvent _) {
    _overRail = false;
    _held = false;
    _rest?.cancel();
    _rest = null;
  }

  /// A click on the shut rail keeps it shut: the click is on its icon.
  void _onRailDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    _rest?.cancel();
    _rest = null;
    if (_rail == _Rail.shut) _held = true;
  }

  void _onOpenEnter(PointerEnterEvent _) {
    _overOpen = true;
    if (_rail == _Rail.closing && !_held) _open();
  }

  void _onOpenExit(PointerExitEvent _) {
    _overOpen = false;
    _held = false;
    if (!_keptOpen) _close();
  }

  /// Focus moving into or within the column by keyboard opens the rail;
  /// focus leaving it, or coming back from a menu with the pointer
  /// elsewhere, closes it.
  void _onFocus() {
    if (!mounted || !_isRail || _foldingFocus) return;
    if (_focus.hasFocus && _byKeyboard) {
      _open();
    } else if (!_overOpen && !_keptOpen) {
      _close();
    }
  }

  /// Whether focus holds the open rail with the pointer gone: a keyboard
  /// user moving through it, or a menu opened from it.
  bool get _keptOpen {
    if (!_focus.hasFocus) return false;
    return _byKeyboard || _focusInMenu;
  }

  /// Whether focus is in a menu opened from the column: focused through the
  /// column, but drawn outside it, in the overlay.
  bool get _focusInMenu {
    final focused = FocusManager.instance.primaryFocus?.context
        ?.findRenderObject();
    final column = _column.currentContext?.findRenderObject();
    if (focused == null || column == null) return false;
    for (RenderObject? o = focused; o != null; o = o.parent) {
      if (identical(o, column)) return false;
    }
    return true;
  }

  void _open() {
    _rest?.cancel();
    _rest = null;
    if (!mounted || !_isRail || _rail == _Rail.open) return;
    if (Overlay.maybeOf(context) == null) return;
    setState(() => _rail = _Rail.open);
    _portal.show();
  }

  /// Folds the open rail back; with [held], it then stays shut under the
  /// pointer until the pointer leaves.
  void _close({bool held = false}) {
    if (_rail != _Rail.open) return;
    if (held) _held = _overOpen || _overRail;
    if (_refocusFolded(rail: true)) {
      _foldingFocus = true;
      // After the focus manager's own microtask, which tells [_onFocus].
      scheduleMicrotask(() => _foldingFocus = false);
    }
    final animates =
        context.motion.medium > Duration.zero &&
        Sidebar.widthOf(context) != Sidebar.widthOf(context, collapsed: true);
    if (animates) {
      setState(() => _rail = _Rail.closing);
    } else {
      _shut();
    }
  }

  /// Puts the column back in its place.
  void _shut() {
    if (!mounted) return;
    setState(() => _rail = _Rail.shut);
    _overOpen = false;
    _portal.hide();
  }

  void _onWidthEnd() {
    if (_rail == _Rail.closing) _shut();
  }

  void _onItemOpen() {
    _rest?.cancel();
    _rest = null;
    if (_rail == _Rail.open) {
      _close(held: true);
    } else if (_overRail) {
      _held = true;
    }
  }

  void _syncNodes(int count) {
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: 'NavItem ${_nodes.length}'));
    }
    while (_nodes.length > count) {
      _nodes.removeLast().dispose();
    }
  }

  /// Moves focus [delta] rows on from the focused one, or with [toEnd] to
  /// the last (true) or first (false) row, among the rows on the screen
  /// that take a key ([_reachable]).
  void _move({int delta = 0, bool? toEnd}) {
    final rows = _rows;
    final live = [
      for (var i = 0; i < rows.length; i++)
        if (_reachable(rows[i])) i,
    ];
    if (live.isEmpty) return;
    final int target;
    if (toEnd != null) {
      target = toEnd ? live.last : live.first;
    } else {
      final current = live.indexWhere((i) => _nodes[i].hasPrimaryFocus);
      if (current < 0) return;
      final next = current + delta;
      if (next < 0 || next >= live.length) return;
      target = live[next];
    }
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(_nodes[target]);
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes(_rows.length);
    final palette = context.shellStyle.sidebarPalette;
    final framed = Builder(builder: _framed);
    return palette == null
        ? framed
        : ChromeTheme(palette: palette, child: framed);
  }

  /// The column in its place, or, while the rail is open, a gap as wide as
  /// the rail with the column over the page in the overlay.
  Widget _framed(BuildContext context) {
    final drawer = NavigationDrawerScope.maybeOf(context);
    final rail = drawer == null && widget.collapsed;
    _isRail = rail;
    if (drawer == null) Shell.reportRail(context, rail: rail);
    if (!rail) {
      if (_rail != _Rail.shut) {
        // No longer a rail, so the column is back in its place, expanded.
        _rest?.cancel();
        _rest = null;
        _rail = _Rail.shut;
        _overOpen = false;
        _portal.hide();
      }
      return _keyedColumn(collapsed: false);
    }
    return MouseRegion(
      onEnter: _onRailEnter,
      onExit: _onRailExit,
      child: Listener(
        onPointerDown: _onRailDown,
        child: OverlayPortal.overlayChildLayoutBuilder(
          controller: _portal,
          overlayChildBuilder: _overlay,
          child: _rail == _Rail.shut
              ? _keyedColumn(collapsed: true)
              : SizedBox(
                  width: Sidebar.widthOf(context, collapsed: true),
                  height: double.infinity,
                ),
        ),
      ),
    );
  }

  /// The open rail, over the gap it left: as tall, from the same edge.
  Widget _overlay(BuildContext context, OverlayChildLayoutInfo info) {
    if (_rail == _Rail.shut) return const SizedBox.shrink();
    final gap = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    final start = switch (Directionality.of(context)) {
      // Physical: the overlay's coordinates, turned into the gap's start.
      TextDirection.ltr => gap.left,
      TextDirection.rtl => info.overlaySize.width - gap.right,
    };
    return Stack(
      children: [
        PositionedDirectional(
          top: gap.top,
          height: gap.height,
          start: start,
          child: MouseRegion(
            onEnter: _onOpenEnter,
            onExit: _onOpenExit,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    _close(held: true),
              },
              // A platform view under the page (an embedded frame) would
              // otherwise take the clicks meant for the rail's items.
              child: PointerInterceptor(
                child: _keyedColumn(
                  collapsed: _rail == _Rail.closing,
                  raised: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _keyedColumn({required bool collapsed, bool raised = false}) =>
      KeyedSubtree(
        key: _column,
        child: Focus(
          focusNode: _focus,
          includeSemantics: false,
          child: Builder(
            builder: (context) =>
                _buildColumn(context, collapsed: collapsed, raised: raised),
          ),
        ),
      );

  /// The column, [collapsed] to the rail or expanded, and [raised] over the
  /// page with a shadow while the rail is open.
  Widget _buildColumn(
    BuildContext context, {
    required bool collapsed,
    required bool raised,
  }) {
    final colors = context.colors;
    final drawer = NavigationDrawerScope.maybeOf(context);
    final leading = drawer == null ? Shell.sidebarLeadingOf(context) : null;
    _columnCollapsed = collapsed;
    final rows = <Widget>[];
    var node = 0;
    for (final entry in widget.entries) {
      switch (entry) {
        case NavItem():
          rows.add(
            _NavTile(
              item: entry,
              selected: entry._isSelected(widget.selected),
              collapsed: collapsed,
              focusNode: _nodes[node++],
            ),
          );
        case NavSection():
          rows.add(_NavSectionLabel(entry, collapsed: collapsed));
        case NavGroup():
          final open = !collapsed && _isOpen(entry);
          rows.add(
            _NavGroupTile(
              group: entry,
              open: open,
              // It stands for the current item while it hides it.
              selected: !open && entry._currentIn(widget.selected) >= 0,
              collapsed: collapsed,
              focusNode: _nodes[node++],
              onTap: () => _onGroupTap(entry),
            ),
          );
          final first = node;
          node += entry.items.length;
          // Kept in the rail too, folded, so the rows after it keep their
          // place in the list as the rail opens.
          rows.add(
            _NavGroupItems(
              open: open,
              children: [
                for (final (i, item) in entry.items.indexed)
                  _NavTile(
                    item: item,
                    selected: item._isSelected(widget.selected),
                    collapsed: false,
                    nested: true,
                    focusNode: _nodes[first + i],
                  ),
              ],
            ),
          );
      }
    }

    final column = Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: widget.semanticLabel ?? context.adminL10n.shell.navigation,
      child: FocusTraversalGroup(
        child: AnimatedContainer(
          duration: context.motion.medium,
          curve: context.motion.standard,
          onEnd: _onWidthEnd,
          width: Sidebar.widthOf(context, collapsed: collapsed),
          decoration: BoxDecoration(
            color: colors.background,
            border: BorderDirectional(
              end: BorderSide(
                color: colors.border,
                width: context.stroke.hairline,
              ),
            ),
            boxShadow: raised && !collapsed ? context.elevation.md : null,
          ),
          // The column's colour runs under the insets; its content keeps
          // clear of them.
          child: SafeArea(
            left: false,
            right: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?drawer?.head,
                if (leading != null)
                  _ShellHead(leading: leading, collapsed: collapsed),
                ?widget.header,
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                          _move(delta: 1),
                      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                          _move(delta: -1),
                      const SingleActivator(LogicalKeyboardKey.home): () =>
                          _move(toEnd: false),
                      const SingleActivator(LogicalKeyboardKey.end): () =>
                          _move(toEnd: true),
                    },
                    child: ListView(
                      // The tiles' content, like the section labels, starts at
                      // the shell inset — under the top bar's leading slot.
                      padding: EdgeInsets.symmetric(
                        horizontal: _NavTile.marginOf(
                          context,
                          collapsed: collapsed,
                        ),
                        vertical: AdminSpacing.md,
                      ),
                      children: rows,
                    ),
                  ),
                ),
                ?widget.footer,
              ],
            ),
          ),
        ),
      ),
    );
    return _SidebarScope(
      collapsed: collapsed,
      onItemOpen: _onItemOpen,
      child: column,
    );
  }
}

/// The head of a sidebar as tall as the window, beside a top bar that spans
/// the page alone: as tall as the bar, with the bar's [leading] at the
/// shell's inset, where it sits above the sidebar in the other span, or
/// centred in the [collapsed] rail. A clear rule where the bar has its
/// hairline centres the leading as the bar centres its content.
class _ShellHead extends StatelessWidget {
  final Widget leading;
  final bool collapsed;

  const _ShellHead({required this.leading, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.shellStyle.topBarHeight,
      padding: EdgeInsetsDirectional.only(start: collapsed ? 0 : Shell.inset),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x00000000))),
      ),
      // Laid out at its own width, as the bar lays it out, so a leading
      // reads the same in either span. The sidebar clips what it cannot
      // hold, and reveals it as it widens, as it does an item's row.
      child: ClipRect(
        child: OverflowBox(
          alignment: collapsed
              ? AlignmentDirectional.center
              : AlignmentDirectional.centerStart,
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          child: leading,
        ),
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  final NavSection section;
  final bool collapsed;

  const _NavSectionLabel(this.section, {required this.collapsed});

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AdminSpacing.sm),
        child: Divider(height: 1),
      );
    }
    final colors = context.colors;
    final padX = context.shellStyle.itemPaddingX;
    final width = _NavTile._contentWidth(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padX,
        AdminSpacing.lg,
        padX,
        AdminSpacing.xs,
      ),
      // Laid out at the expanded width and revealed as the rail opens, as an
      // item's row is, rather than wrapped to the opening width.
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          fit: OverflowBoxFit.deferToChild,
          minWidth: width,
          maxWidth: width,
          child: Text(
            section.label.toUpperCase(),
            style: context.type.micro.copyWith(
              // The micro caption is small text: it needs 4.5:1 on the rail.
              color: colors.readableOn(
                colors.foregroundMuted,
                surfaces: [colors.background],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool collapsed;

  /// Under a [NavGroup]'s row.
  final bool nested;
  final FocusNode focusNode;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    this.nested = false,
    required this.focusNode,
  });

  /// The room between the rail's edges and a tile: the style's
  /// [AdminShellStyle.itemMarginX], or what the tile's own padding leaves of
  /// the shell inset, so its content starts under the top bar's leading
  /// slot; and at least the reach of a focus ring drawn outside the tile,
  /// which the list would otherwise clip. None where both allow it: the tile
  /// spans the rail, as Carbon's links do.
  ///
  /// In the [collapsed] rail there is no content to line up, so the margin
  /// shrinks as far as leaves a tile as wide as it is tall (Fluent's square
  /// rail items), still clear of the focus ring; a tile the rail already
  /// leaves wider keeps its margin.
  static double marginOf(BuildContext context, {bool collapsed = false}) {
    final style = context.shellStyle;
    final reach = math.max(0.0, FocusRing.reachOf(context));
    final margin = math.max(
      style.itemMarginX ?? Shell.inset - style.itemPaddingX,
      reach,
    );
    if (!collapsed) return margin;
    // Inside the rail's hairline on its trailing edge.
    final rail = style.railWidth - context.stroke.hairline;
    return math.min(margin, math.max((rail - style.itemHeight) / 2, reach));
  }

  /// The style's item height, grown by as much as the label grows at the
  /// platform's text size: a large text scale makes a taller tile rather
  /// than clipping it.
  static double _heightOf(BuildContext context) =>
      context.shellStyle.itemHeight +
      textGrowthOf(context, context.type.bodyStrong);

  /// The expanded row's width: the expanded sidebar less a tile's margin
  /// and padding on either side.
  static double _contentWidth(BuildContext context) =>
      Sidebar.widthOf(context) -
      (marginOf(context) + context.shellStyle.itemPaddingX) * 2;

  /// Calls the item's [NavItem.onTap], once the page's guards let it leave,
  /// closing the navigation drawer it is in first.
  Future<void> _open(BuildContext context) async {
    if (item.guarded && !await LeaveGuardScope.confirmLeave(context)) return;
    if (!context.mounted) return;
    context.getInheritedWidgetOfExactType<NavigationDrawerScope>()?.close();
    context.getInheritedWidgetOfExactType<_SidebarScope>()?.onItemOpen();
    item.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _NavRow(
      tileKey: item.key,
      label: item.label,
      icon: item.icon,
      // One name whether the label shows or the rail is collapsed, and for
      // an inert item too.
      semanticLabel: item.badge == null
          ? item.label
          : context.adminL10n.shell.navItemWithBadge(item.label, item.badge!),
      badge: item.badge,
      selected: selected,
      collapsed: collapsed,
      nested: nested,
      focusNode: focusNode,
      statesController: item.statesController,
      onTap: item.onTap == null ? null : () => _open(context),
    );
  }
}

/// A [NavGroup]'s own row: closed, it trails the number of its items, and
/// either way a chevron that turns as it opens.
class _NavGroupTile extends StatelessWidget {
  final NavGroup group;

  /// Its items show under it.
  final bool open;
  final bool selected;
  final bool collapsed;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _NavGroupTile({
    required this.group,
    required this.open,
    required this.selected,
    required this.collapsed,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = context.adminFormats.integer(group.items.length);
    return _NavRow(
      tileKey: group.key,
      label: group.label,
      icon: group.icon,
      // One name open or closed, with the count the open row leaves out.
      semanticLabel: context.adminL10n.shell.navItemWithBadge(
        group.label,
        count,
      ),
      badge: open ? null : count,
      selected: selected,
      collapsed: collapsed,
      expanded: open,
      focusNode: focusNode,
      statesController: group.statesController,
      onTap: onTap,
    );
  }
}

/// A [NavGroup]'s items under its row, which take their room as it opens
/// and give it back as it closes.
class _NavGroupItems extends StatelessWidget {
  final bool open;
  final List<Widget> children;

  const _NavGroupItems({required this.open, required this.children});

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final items = open
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          )
        : const SizedBox(width: double.infinity);
    // An AnimatedSize cannot run at zero: under reduced motion the items
    // just appear.
    if (motion.medium == Duration.zero) return items;
    return AnimatedSize(
      duration: motion.medium,
      curve: motion.standard,
      alignment: Alignment.topCenter,
      child: items,
    );
  }
}

/// One row of the sidebar's list, a [NavItem]'s or a [NavGroup]'s own: its
/// glyph, and in the expanded column its label and what trails it.
class _NavRow extends StatelessWidget {
  /// The key of the row's tap target.
  final Key? tileKey;
  final String label;
  final IconData icon;
  final String semanticLabel;
  final String? badge;
  final bool selected;
  final bool collapsed;

  /// Under a [NavGroup]'s row: its content starts a step in, its glyph
  /// under the group's label.
  final bool nested;

  /// For a group's row, whether its items show: it then ends in a chevron
  /// and is announced as expanded or collapsed. Null for an item.
  final bool? expanded;
  final FocusNode focusNode;
  final WidgetStatesController? statesController;
  final VoidCallback? onTap;

  const _NavRow({
    required this.tileKey,
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.badge,
    required this.selected,
    required this.collapsed,
    this.nested = false,
    this.expanded,
    required this.focusNode,
    required this.statesController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.shellStyle;
    final radius = style.itemRadiusOf(context.radii);
    final glyph = style.itemIconSizeOf(context.iconSizes);
    final mark = colors.navIndicator.a > 0
        ? style.indicatorOf(colors, context.radii)
        : NavIndicator.none;
    final enabled = onTap != null;
    final height = _NavTile._heightOf(context);
    final indent = nested ? glyph + AdminSpacing.md : 0.0;
    final contentWidth = _NavTile._contentWidth(context) - indent;

    Widget tile = Tappable.states(
      key: tileKey,
      onTap: onTap,
      focusNode: focusNode,
      statesController: statesController,
      focusRadius: radius,
      selected: selected ? true : null,
      expanded: expanded,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states) {
        final lit =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        // Selection keeps its own fill under the pointer: hover never makes
        // the current item read weaker.
        final fill = selected
            ? colors.navSelectedFill
            : (lit && enabled ? colors.navHoverFill : null);
        final fg = selected
            ? colors.navSelectedText
            : (enabled ? colors.foregroundSecondary : colors.foregroundSubtle);

        final row = Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: glyph, color: fg),
            if (!collapsed) ...[
              const Gap(AdminSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (selected ? context.type.bodyStrong : context.type.body)
                          .copyWith(color: fg),
                ),
              ),
              if (badge case final badge?) _NavBadge(badge, selected: selected),
              if (expanded case final expanded?) ...[
                const Gap(AdminSpacing.sm),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: context.motion.fast,
                  curve: context.motion.standard,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: context.iconSizes.sm,
                    color: fg,
                  ),
                ),
              ],
            ],
          ],
        );

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The rail's glyph is centred in the whole tile, which a
              // narrow rail leaves no room to pad.
              if (collapsed)
                row
              else
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: style.itemPaddingX + indent,
                    end: style.itemPaddingX,
                  ),
                  // While the rail animates open, lay the row out at its
                  // final width and clip to the (narrower) current width —
                  // so it reveals instead of squishing the label to zero
                  // and overflowing the fixed-width badge.
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerStart,
                      minWidth: contentWidth,
                      maxWidth: contentWidth,
                      child: row,
                    ),
                  ),
                ),
              if (selected && mark != NavIndicator.none)
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _Indicator(
                      colors.navIndicator,
                      edge: mark == NavIndicator.edge,
                      width: style.indicatorWidth,
                      length: mark == NavIndicator.edge ? height : glyph,
                      radius: radius,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (collapsed) {
      tile = Tip(message: label, excludeFromSemantics: true, child: tile);
    }
    return Padding(
      padding: EdgeInsets.only(bottom: style.itemGap),
      child: tile,
    );
  }
}

/// The mark beside the selected item's fill, at its leading edge: a short
/// rounded bar as tall as the item's glyph (Fluent's nav), or with [edge] a
/// rule down the item's whole height, square to its leading corners
/// (Carbon's side nav).
class _Indicator extends StatelessWidget {
  final Color color;
  final bool edge;

  /// Across the item.
  final double width;

  /// Down the item: its glyph's size for a bar, its height for an edge.
  final double length;

  /// The item's corner.
  final double radius;

  const _Indicator(
    this.color, {
    required this.edge,
    required this.width,
    required this.length,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final corner = Radius.circular(radius);
    return Container(
      width: width,
      height: length,
      decoration: BoxDecoration(
        color: color,
        borderRadius: edge
            ? BorderRadiusDirectional.horizontal(start: corner)
            : BorderRadius.all(corner),
      ),
    );
  }
}

/// A [NavItem]'s trailing count. On the selected item it takes the primary
/// fill, or, where the selection is filled with (nearly) the primary itself
/// (Ant's dark sider), the selected label's colour, so the count still
/// stands off the tile. Otherwise it is a neutral pill: a foreground wash
/// rather than an opaque colour, so it stays a step off whatever the tile
/// paints beneath it (the rail, or the hover fill).
class _NavBadge extends StatelessWidget {
  final String label;
  final bool selected;

  const _NavBadge(this.label, {required this.selected});

  /// The least contrast at which the primary pill still reads off the
  /// selection's fill, its hue helping; nearer, the pill merges into it.
  static const _standOff = 1.5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final (fill, ink) = !selected
        ? (
            // token-literal: a count's neutral pill on the rail
            colors.foreground.withValues(alpha: 0.08),
            colors.foregroundSecondary,
          )
        : contrastRatio(colors.primary, colors.navSelectedFill) >= _standOff
        ? (colors.primary, colors.onPrimary)
        : (colors.navSelectedText, colors.navSelectedFill);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(context.radii.radiusPill),
      ),
      child: Text(
        label,
        style: type.weighted(
          type.caption.copyWith(color: ink),
          type.spec.strong,
        ),
      ),
    );
  }
}

/// The signed-in account, pinned at the foot of a [Sidebar] as its
/// [Sidebar.footer]: a row with the account's [Avatar], [name] and [detail]
/// that opens a [Menu] of [entries] (signing out, a profile), headed by the
/// same identity and a [badge].
///
/// Expanded, the menu opens above the row, lined up with its leading edge.
/// In the collapsed rail the row is the avatar alone, with the name in its
/// tooltip, and the menu opens beside it: its header is then where the rail
/// says who is signed in. In a navigation drawer it draws expanded, as the
/// sidebar does ([Sidebar.isCollapsed]).
///
/// The row is one button named [name] and announced as expanded while the
/// menu is open; the menu's keys are [Menu]'s.
class SidebarAccount extends StatelessWidget {
  final String name;

  /// A second line under [name]: an email, or what the account is.
  final String? detail;

  /// The avatar's picture; the initials of [name] without one, or while it
  /// loads.
  final ImageProvider? image;

  /// After the name in the menu's header, such as a role or a plan as a
  /// `Tag`.
  final Widget? badge;

  final List<MenuEntry> entries;

  const SidebarAccount({
    super.key,
    required this.name,
    this.detail,
    this.image,
    this.badge,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.shellStyle;
    final collapsed = Sidebar.isCollapsed(context);
    final radius = style.itemRadiusOf(context.radii);
    final hairline = context.stroke.hairline;
    final margin = _NavTile.marginOf(context, collapsed: collapsed);
    // As wide as the expanded row, in the rail too, so the header lines up
    // with it; a theme's narrower sidebar still leaves the default one's
    // room for the name beside its badge.
    final rowMargins = hairline + 2 * _NavTile.marginOf(context);
    final menuWidth =
        math.max(Sidebar.widthOf(context), Sidebar.expandedWidth) - rowMargins;
    const gap = 6.0;

    Widget menu = Menu(
      side: collapsed ? PopoverSide.end : PopoverSide.top,
      align: collapsed ? PopoverAlign.end : PopoverAlign.start,
      // Beside the rail, clear of its edge rather than over it.
      gap: collapsed ? margin + hairline + gap : gap,
      minWidth: menuWidth,
      maxWidth: menuWidth,
      header: _AccountIdentity(this, avatarSize: 32, badge: badge),
      entries: entries,
      builder: (context, c) => Tappable.states(
        onTap: c.toggle,
        semanticLabel: name,
        excludeSemantics: true,
        expanded: c.isOpen,
        focusRadius: radius,
        builder: (context, states) {
          final lit =
              c.isOpen ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed);
          return Container(
            constraints: BoxConstraints(minHeight: _NavTile._heightOf(context)),
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : style.itemPaddingX,
              vertical: AdminSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: lit ? colors.navHoverFill : null,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: collapsed
                ? Center(child: _AccountAvatar(this, size: 28))
                // Revealed as the rail opens, as a nav item's row is.
                : ClipRect(
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerStart,
                      fit: OverflowBoxFit.deferToChild,
                      minWidth: _NavTile._contentWidth(context),
                      maxWidth: _NavTile._contentWidth(context),
                      child: Row(
                        children: [
                          Expanded(
                            child: _AccountIdentity(this, avatarSize: 28),
                          ),
                          const Gap(AdminSpacing.sm),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: context.iconSizes.sm,
                            color: colors.foregroundMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
    if (collapsed) {
      menu = Tip(message: name, excludeFromSemantics: true, child: menu);
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: margin,
        vertical: AdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border, width: hairline),
        ),
      ),
      child: menu,
    );
  }
}

/// The account's avatar, silent: the name beside it, or the button around
/// it, says who it is.
class _AccountAvatar extends StatelessWidget {
  final SidebarAccount account;
  final double size;

  const _AccountAvatar(this.account, {required this.size});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Avatar(name: account.name, image: account.image, size: size),
    );
  }
}

/// The avatar beside the name and the detail under it: the row's content,
/// and with a [badge] after the name, the menu's header.
class _AccountIdentity extends StatelessWidget {
  final SidebarAccount account;
  final double avatarSize;
  final Widget? badge;

  const _AccountIdentity(this.account, {required this.avatarSize, this.badge});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = account.detail;
    final name = Text(
      account.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.type.bodyStrong.copyWith(color: colors.foreground),
    );
    return Row(
      children: [
        _AccountAvatar(account, size: avatarSize),
        const Gap(AdminSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge case final badge?)
                Row(
                  children: [
                    Flexible(child: name),
                    const Gap(AdminSpacing.sm),
                    badge,
                  ],
                )
              else
                name,
              if (detail != null)
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.caption.copyWith(
                    color: colors.foregroundMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
