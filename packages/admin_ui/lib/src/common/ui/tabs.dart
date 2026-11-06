/// @docImport 'button.dart';
/// @docImport 'segmented.dart';
/// @docImport 'tag.dart';
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'focus_ring.dart';
import 'icon_action.dart';
import 'menu.dart';
import 'popover.dart';
import 'tappable.dart';

/// One tab in a [Tabs] strip.
class TabItem {
  final String label;
  final IconData? icon;

  /// Optional trailing widget — a count [Tag], a dot, etc.
  final Widget? trailing;

  /// Actions on this tab (rename, duplicate, delete…). They open from a caret
  /// at the tab's end — shown while the tab is hovered, focused or selected,
  /// and otherwise kept in place invisible, so nothing reflows as it appears —
  /// from a secondary click or a long press on the tab, and from Shift+F10 or
  /// the context-menu key on the focused tab. The selected tab's caret is also
  /// a Tab stop after the strip.
  final List<MenuEntry>? menu;

  /// The caret's accessible name and tooltip, e.g. "Published options"; the
  /// localized "More" when null.
  final String? menuLabel;

  /// A disabled tab is dimmed and skipped by both taps and keyboard focus.
  final bool enabled;

  /// The key of the tab built for this item, to find it by in a test.
  final Key? key;

  const TabItem(
    this.label, {
    this.key,
    this.icon,
    this.trailing,
    this.menu,
    this.menuLabel,
    this.enabled = true,
  });
}

/// The selected tab in a set of addressable tab sections, as a [Listenable] so
/// more than the strip can drive it — scroll-to-field switches to a field's
/// owning tab, URL binding reflects the active tab into the address bar. Holds
/// the active tab *id* (stable across relabeling/reordering, unlike an index).
/// [Tabs.keyed] draws a strip that follows and drives it.
class TabSelection extends ChangeNotifier {
  String _active;

  TabSelection(this._active);

  String get active => _active;

  void select(String id) {
    if (id == _active) return;
    _active = id;
    notifyListeners();
  }
}

/// Marks the subtree of one tab section with its [tabId] and the shared
/// [selection], so a descendant (e.g. a field being revealed by ⌘K or a comment
/// jump) can switch to its owning tab before scrolling into view. Read on demand
/// — no dependency, so activating doesn't rebuild the reader.
class TabScope extends InheritedWidget {
  final String tabId;
  final TabSelection selection;

  const TabScope({
    super.key,
    required this.tabId,
    required this.selection,
    required super.child,
  });

  static TabScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabScope>();

  /// True when this section is the one currently shown.
  bool get isActive => selection.active == tabId;

  /// Make this section the active tab.
  void activate() => selection.select(tabId);

  @override
  bool updateShouldNotify(TabScope old) =>
      tabId != old.tabId || selection != old.selection;
}

/// The visual style of the strip.
enum TabsVariant {
  /// Underline under the selected tab, on a hairline. Page/route-level nav.
  line,

  /// Folder tabs: the selected tab is a bordered surface with an open bottom
  /// that attaches to the panel below. For tabs nested inside a card/panel.
  enclosed,
}

/// How the tabs distribute across the available width.
enum TabsAlignment {
  /// Tabs hug their content from the start; the strip scrolls horizontally with
  /// fading edges when they outgrow the width. The default — right for
  /// navigation with a variable or large number of tabs.
  start,

  /// Tabs share the width equally (justified). Right for a small, fixed set.
  fill,
}

/// A horizontal page-tab strip: labels with a primary underline under the
/// selected one, sitting on a full-width hairline. The view is selection-only —
/// it reports taps via [onChanged]; wiring tabs to routes/content stays with the
/// caller. [Tabs.keyed] addresses the tabs by id through a [TabSelection]
/// instead of by index.
///
/// Keyboard: the strip is one Tab stop, landing on the selected tab. Arrow
/// Left/Right move to the previous/next enabled tab (wrapping, and mirrored
/// right-to-left), Home/End jump to the first/last, and moving selects —
/// [onChanged] fires as focus lands. Enter/Space re-activate the focused tab,
/// and the theme's [FocusRing] shows inside it on keyboard focus. Screen
/// readers get a tab bar of tabs with their selected state.
///
/// Overflow is handled per [alignment] (scroll vs justify). A scrolling strip
/// also follows a vertical mouse wheel and a mouse drag, keeps the selected
/// tab in view, and with [overflowMenuLabel] ends in a menu of every tab
/// while it overflows. A tab with a [TabItem.menu] opens it from its caret, a
/// secondary click, a long press, or Shift+F10 / the context-menu key. With
/// animations disabled (reduced motion) the strip scrolls a tab into view at
/// once.
///
/// This is the page-navigation cousin of [Segmented] (a compact pill toggle for
/// 2–4 either/or choices).
class Tabs extends StatefulWidget {
  final List<TabItem> tabs;

  /// The index of the selected tab; in a [Tabs.keyed] strip, the index of the
  /// [selection]'s active id, or -1 when no tab has it.
  int get selected {
    final selection = this.selection;
    if (selection == null) return _selected;
    return ids!.indexOf(selection.active);
  }

  final int _selected;

  /// Called with the index of the tab the user selects; in a [Tabs.keyed]
  /// strip, it selects that tab's id in the [selection].
  final ValueChanged<int> onChanged;

  /// The id of each tab of a [Tabs.keyed] strip, in order; null otherwise.
  final List<String>? ids;

  /// The selection a [Tabs.keyed] strip shows and updates; null otherwise.
  final TabSelection? selection;

  final TabsAlignment alignment;
  final TabsVariant variant;

  /// Draws the full-width baseline hairline under the strip. Turn off when the
  /// host already draws one (e.g. a toolbar embedding the strip in a row beside
  /// other controls).
  final bool baseline;

  /// The strip's height: 40 at medium, the default; 32 with tighter tab
  /// padding at small, for a compact strip (e.g. a saved-views row) rather
  /// than top-level page navigation; 48 at large.
  ///
  /// These are strip heights, the same in every theme, not the theme's
  /// control heights (`context.sizes`) that a [Button] or a [Segmented] of
  /// the same size takes: a strip sits on its own baseline rather than in a
  /// row of controls, and a theme's large control is often no taller than
  /// its medium strip.
  final ControlSize size;

  /// When set, a scrolling strip too long for its width ends in a menu of
  /// every tab, announced by this label (e.g. "More views"), beside the edge
  /// fade. Null leaves the fade as the only cue.
  final String? overflowMenuLabel;

  const Tabs({
    super.key,
    required this.tabs,
    required this._selected,
    required this.onChanged,
    this.alignment = TabsAlignment.start,
    this.variant = TabsVariant.line,
    this.baseline = true,
    this.size = ControlSize.medium,
    this.overflowMenuLabel,
  }) : ids = null,
       selection = null;

  /// A strip whose tabs are addressed by id: [tabs] maps each id to its tab,
  /// in the map's order, and the strip shows [selection]'s active id and
  /// selects a tab's id there when the user picks it. For tab sections under
  /// [TabScope]s sharing the same [selection], so a reveal elsewhere switches
  /// the strip too.
  Tabs.keyed({
    super.key,
    required Map<String, TabItem> tabs,
    required TabSelection this.selection,
    this.alignment = TabsAlignment.start,
    this.variant = TabsVariant.line,
    this.baseline = true,
    this.size = ControlSize.medium,
    this.overflowMenuLabel,
  }) : tabs = tabs.values.toList(),
       ids = tabs.keys.toList(),
       _selected = -1,
       onChanged = _selectIn(selection, tabs.keys.toList());

  static ValueChanged<int> _selectIn(
    TabSelection selection,
    List<String> ids,
  ) =>
      (i) => selection.select(ids[i]);

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  final ScrollController _scroll = ScrollController();

  /// Keeps the scroll view's state as the edge fade wraps and unwraps it.
  final GlobalKey _viewKey = GlobalKey();
  bool _fadeStart = false;
  bool _fadeEnd = false;
  bool _overflows = false;

  /// One node per tab. Only the strip's Tab stop is traversable; the rest are
  /// reached with the arrow keys.
  final List<FocusNode> _nodes = [];

  /// The selected index the strip last showed, to tell a new selection from
  /// a rebuild.
  late int _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.selected;
    _scroll.addListener(_updateFades);
    widget.selection?.addListener(_onSelection);
    _syncNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(widget.selected, animate: false);
    });
  }

  @override
  void didUpdateWidget(Tabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection != oldWidget.selection) {
      oldWidget.selection?.removeListener(_onSelection);
      widget.selection?.addListener(_onSelection);
    }
    _syncNodes();
    _onSelected();
  }

  @override
  void dispose() {
    widget.selection?.removeListener(_onSelection);
    for (final node in _nodes) {
      node.removeListener(_syncStop);
      node.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _onSelection() => setState(_onSelected);

  /// Keeps a newly selected tab in view.
  void _onSelected() {
    final selected = widget.selected;
    if (selected == _shown) return;
    _shown = selected;
    _syncStop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(selected, animate: true);
    });
  }

  void _syncNodes() {
    while (_nodes.length > widget.tabs.length) {
      // The tab it served unmounts in the coming build, still holding it.
      final node = _nodes.removeLast()..removeListener(_syncStop);
      WidgetsBinding.instance.addPostFrameCallback((_) => node.dispose());
    }
    while (_nodes.length < widget.tabs.length) {
      _nodes.add(
        FocusNode(debugLabel: 'Tab ${_nodes.length}')..addListener(_syncStop),
      );
    }
    _syncStop();
  }

  bool _enabled(int i) => widget.tabs[i].enabled;

  /// The strip's one Tab stop: the focused tab while focus is in the strip,
  /// otherwise the selected tab, falling back to the first enabled one.
  int? get _stop {
    final focused = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (focused >= 0) return focused;
    final selected = widget.selected;
    if (selected >= 0 && selected < widget.tabs.length && _enabled(selected)) {
      return selected;
    }
    for (var i = 0; i < widget.tabs.length; i++) {
      if (_enabled(i)) return i;
    }
    return null;
  }

  void _syncStop() {
    final stop = _stop;
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != stop;
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final current = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (current < 0) return KeyEventResult.ignored;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed ||
        keys.isAltPressed ||
        keys.isMetaPressed ||
        keys.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final int? target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => _step(current, rtl ? -1 : 1),
      LogicalKeyboardKey.arrowLeft => _step(current, rtl ? 1 : -1),
      LogicalKeyboardKey.home => _step(-1, 1),
      LogicalKeyboardKey.end => _step(widget.tabs.length, -1),
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    if (target != current) {
      _nodes[target].requestFocus();
      _reveal(target, animate: true);
      widget.onChanged(target);
    }
    return KeyEventResult.handled;
  }

  /// The next enabled tab from [from] in [direction], wrapping around.
  int? _step(int from, int direction) {
    final count = widget.tabs.length;
    for (var n = 1; n <= count; n++) {
      final i = (from + direction * n) % count;
      if (_enabled(i)) return i;
    }
    return null;
  }

  /// Scrolls the strip the least distance that shows tab [i] whole, clear of
  /// the edge fades.
  void _reveal(int i, {required bool animate}) {
    if (widget.alignment != TabsAlignment.start) return;
    if (i < 0 || i >= _nodes.length || !_scroll.hasClients) return;
    final box = _nodes[i].context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final position = _scroll.position;
    final margin = _fadeWidth(position.viewportDimension);
    final rect = Rect.fromLTRB(
      -margin,
      0,
      box.size.width + margin,
      box.size.height,
    );
    final atStart = viewport.getOffsetToReveal(box, 0, rect: rect).offset;
    final atEnd = viewport.getOffsetToReveal(box, 1, rect: rect).offset;
    final target =
        (atEnd > atStart ? atStart : position.pixels.clamp(atEnd, atStart))
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;
    final motion = context.motion;
    if (animate && motion.medium > Duration.zero) {
      position.animateTo(
        target,
        duration: motion.medium,
        curve: motion.standard,
      );
    } else {
      position.jumpTo(target);
    }
  }

  /// A vertical wheel scrolls an overflowing strip sideways, while it has
  /// room to move that way; otherwise the page takes it.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scroll.hasClients) return;
    final delta = event.scrollDelta;
    if (delta.dy == 0 || delta.dx.abs() > delta.dy.abs()) return;
    final position = _scroll.position;
    final canMove = delta.dy > 0
        ? position.pixels < position.maxScrollExtent
        : position.pixels > position.minScrollExtent;
    if (!canMove) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      _scroll.position.pointerScroll(
        (event as PointerScrollEvent).scrollDelta.dy,
      );
    });
  }

  void _updateFades() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final start = p.pixels > 0.5;
    final end = p.pixels < p.maxScrollExtent - 0.5;
    final overflows = p.maxScrollExtent > 0.5;
    if (start != _fadeStart || end != _fadeEnd || overflows != _overflows) {
      setState(() {
        _fadeStart = start;
        _fadeEnd = end;
        _overflows = overflows;
      });
    }
  }

  void _pick(int i) {
    widget.onChanged(i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(i, animate: true);
    });
  }

  /// Every tab in a menu, the selected one checked — for a strip too long to
  /// show them all.
  Widget _overflowMenu(String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AdminSpacing.xs),
      child: Menu(
        align: PopoverAlign.end,
        entries: [
          for (final (i, tab) in widget.tabs.indexed)
            MenuItem(
              tab.label,
              icon: tab.icon,
              checked: i == widget.selected,
              onSelect: tab.enabled ? () => _pick(i) : null,
            ),
        ],
        builder: (context, c) => IconAction(
          Icons.more_horiz_rounded,
          label: label,
          size: IconActionSize.small,
          expanded: c.isOpen,
          onPressed: c.toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget strip;
    if (widget.alignment == TabsAlignment.fill) {
      strip = _tabBar(
        Row(
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              Expanded(child: _tab(i)),
          ],
        ),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
      strip = _faded(
        Listener(
          key: _viewKey,
          onPointerSignal: _onPointerSignal,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: {
                ...ScrollConfiguration.of(context).dragDevices,
                PointerDeviceKind.mouse,
              },
            ),
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: _tabBar(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Whole-pixel widths keep every tab edge crisp.
                    for (var i = 0; i < widget.tabs.length; i++)
                      IntrinsicWidth(stepWidth: 1, child: _tab(i)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final overflowLabel = widget.overflowMenuLabel;
      if (overflowLabel != null && _overflows) {
        strip = Row(
          children: [
            Expanded(child: strip),
            _overflowMenu(overflowLabel),
          ],
        );
      }
    }
    strip = FocusTraversalGroup(
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: strip,
      ),
    );
    if (!widget.baseline) return strip;
    switch (widget.variant) {
      case TabsVariant.line:
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.colors.tabDivider),
            ),
          ),
          child: strip,
        );
      case TabsVariant.enclosed:
        // The baseline runs full width; the selected tab's open bottom paints
        // over it, so the folder attaches to the panel placed below.
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: context.stroke.hairline,
                child: ColoredBox(color: context.colors.border),
              ),
            ),
            strip,
          ],
        );
    }
  }

  /// The tab bar node the tabs announce under — inside the scroll view, so the
  /// tabs are its direct children.
  Widget _tabBar(Widget row) => Semantics(
    role: SemanticsRole.tabBar,
    container: true,
    explicitChildNodes: true,
    child: row,
  );

  Widget _tab(int i) => _Tab(
    widget.tabs[i],
    node: _nodes[i],
    selected: i == widget.selected,
    variant: widget.variant,
    size: widget.size,
    truncates: widget.alignment == TabsAlignment.fill,
    onTap: () => widget.onChanged(i),
  );

  /// How far an edge fade reaches: twice the gap between two labels, so
  /// wherever the edge falls, some of a label shows in it — never only the
  /// padding between two. At most a fifth of a narrow strip.
  double _fadeWidth(double viewport) {
    final padding = _Tab.paddingFor(widget.size);
    return math.min(4 * padding, viewport / 5);
  }

  /// Fades whichever edge has content scrolled past it — so an overflowing strip
  /// signals there's more, without painting a surface-coloured gradient. The
  /// start edge is the right one in a right-to-left strip.
  Widget _faded(Widget child) {
    if (!_fadeStart && !_fadeEnd) return child;
    final direction = Directionality.of(context);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final fade = _fadeWidth(rect.width) / rect.width;
        return LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            _fadeStart ? Colors.transparent : Colors.white,
            Colors.white,
            Colors.white,
            _fadeEnd ? Colors.transparent : Colors.white,
          ],
          stops: [0, _fadeStart ? fade : 0, _fadeEnd ? 1 - fade : 1, 1],
        ).createShader(rect, textDirection: direction);
      },
      child: child,
    );
  }
}

class _Tab extends StatefulWidget {
  final TabItem item;
  final FocusNode node;
  final bool selected;
  final TabsVariant variant;
  final ControlSize size;

  /// Whether a label too long for its share of a filled strip ellipsizes. A
  /// scrolling strip sizes each tab to its label, which a label measured with
  /// negative tracking can fall a fraction short of, so there it never does.
  final bool truncates;

  final VoidCallback onTap;

  const _Tab(
    this.item, {
    required this.node,
    required this.selected,
    required this.variant,
    required this.size,
    required this.truncates,
    required this.onTap,
  });

  /// The tab's height at [size], before the label's growth at a large text
  /// size: a strip height, fixed across themes (see [Tabs.size]).
  static double heightFor(ControlSize size) => switch (size) {
    ControlSize.small => 32,
    ControlSize.medium => 40,
    ControlSize.large => 48,
  };

  /// The inset of the tab's content from either side at [size].
  static double paddingFor(ControlSize size) =>
      size == ControlSize.small ? AdminSpacing.md : AdminSpacing.lg;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  /// The tab's [TabItem.menu], once built.
  PopoverController? _menu;

  @override
  void initState() {
    super.initState();
    widget.node.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_Tab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node != oldWidget.node) {
      oldWidget.node.removeListener(_onFocusChange);
      widget.node.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.node.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  void _activate() {
    // A pointer tap leaves focus where it was, so a tab that keyboard focus
    // lit keeps its ring after a click elsewhere; drop it, keeping the ring
    // keyboard-only. Enter/Space come from the focused tab itself.
    if (!widget.node.hasPrimaryFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    widget.onTap();
  }

  void _openMenu() => _menu?.open();

  /// Shift+F10 and the context-menu key open the menu of the tab itself —
  /// not while focus is in its caret or its open menu.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final contextMenu =
        key == LogicalKeyboardKey.contextMenu ||
        (key == LogicalKeyboardKey.f10 &&
            HardwareKeyboard.instance.isShiftPressed);
    if (!contextMenu || _menu == null) return KeyEventResult.ignored;
    _menu!.open();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.item.enabled;
    if (widget.item.menu == null) _menu = null;
    Widget tab = Tappable.states(
      key: widget.item.key,
      onTap: enabled ? _activate : null,
      focusNode: widget.node,
      showFocusRing: false,
      role: SemanticsRole.tab,
      selected: widget.selected,
      builder: (context, states) => SizedBox(
        // Taller by as much as the label grows at a large text size.
        height:
            _Tab.heightFor(widget.size) +
            textGrowthOf(context, context.type.button),
        child: _content(context, states),
      ),
    );
    if (widget.item.menu != null && enabled) {
      tab = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: _onKey,
        child: GestureDetector(
          excludeFromSemantics: true,
          onSecondaryTapUp: (_) => _openMenu(),
          onLongPress: _openMenu,
          child: tab,
        ),
      );
    }
    return tab;
  }

  Widget _content(BuildContext context, Set<WidgetState> states) {
    final enabled = widget.item.enabled;
    final hovered = enabled && states.contains(WidgetState.hovered);
    // A line tab's selected label takes the primary (it's the only cue); an
    // enclosed tab's surface already marks it, so its label stays foreground.
    final selectedColor = widget.variant == TabsVariant.enclosed
        ? context.colors.foreground
        : context.colors.primaryText;
    final color = !enabled
        ? context.colors.foregroundSubtle
        : widget.selected
        ? selectedColor
        : (hovered
              ? context.colors.foregroundSecondary
              : context.colors.foregroundMuted);

    final menu = enabled ? widget.item.menu : null;
    final padding = _Tab.paddingFor(widget.size);
    // The caret's box pads its glyph; the tab's end padding gives that back,
    // so the glyph sits as far from the edge as the icon does from the start.
    final caretInset =
        (IconActionSize.inline.box - IconActionSize.inline.glyph) / 2;
    Widget label = Padding(
      padding: EdgeInsetsDirectional.only(
        start: padding,
        end: menu == null ? padding : padding - caretInset,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.item.icon != null) ...[
            Icon(widget.item.icon, size: context.iconSizes.md, color: color),
            const Gap(AdminSpacing.sm),
          ],
          Flexible(
            child: Text(
              widget.item.label,
              maxLines: 1,
              softWrap: false,
              overflow: widget.truncates
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
              style: context.type.button.copyWith(color: color),
            ),
          ),
          if (widget.item.trailing != null) ...[
            const Gap(AdminSpacing.sm),
            widget.item.trailing!,
          ],
          if (menu != null) ...[
            Gap(AdminSpacing.sm - caretInset),
            _caret(menu, color: color, hovered: hovered),
          ],
        ],
      ),
    );

    // The keyboard focus ring, drawn round a box inset far enough that the
    // whole ring, offset gap included, stays inside the tab: the strip's scroll
    // clip can't cut it, and it keeps clear of the underline and of a folder
    // tab's border. It sits behind the label and takes no space, so it never
    // shifts layout and the label keeps the constraints a filled strip gives
    // it. Gated on *primary* focus, not focus-within: an open overflow menu
    // parents its focus under this tab (hasFocus true), but the ring should
    // stay off then.
    final showRing =
        states.contains(WidgetState.focused) && widget.node.hasPrimaryFocus;
    label = Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(_ringInset(context)),
            child: FocusRing(
              focused: showRing,
              radius: context.radii.radiusSmall,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        label,
      ],
    );

    return widget.variant == TabsVariant.enclosed
        ? _enclosed(label)
        : _underlined(label);
  }

  /// How far in from the tab's edge the focus ring's box sits: as far as the
  /// [FocusRing] reaches outside it, plus a small gap.
  double _ringInset(BuildContext context) =>
      AdminSpacing.xxs + math.max(0, FocusRing.reachOf(context));

  /// The [TabItem.menu] trigger. Hidden, it keeps its place (so the label
  /// never moves), its name and its focusability, and takes no pointer; only
  /// the strip's current tab offers it to Tab.
  Widget _caret(
    List<MenuEntry> entries, {
    required Color color,
    required bool hovered,
  }) {
    return Menu(
      align: PopoverAlign.end,
      entries: entries,
      builder: (context, c) {
        _menu = c;
        final shown =
            c.isOpen || hovered || widget.selected || widget.node.hasFocus;
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          descendantsAreTraversable: !widget.node.skipTraversal,
          child: IgnorePointer(
            ignoring: !shown,
            child: Opacity(
              opacity: shown ? 1 : 0,
              alwaysIncludeSemantics: true,
              child: IconAction(
                Icons.expand_more_rounded,
                label:
                    widget.item.menuLabel ??
                    MaterialLocalizations.of(context).moreButtonTooltip,
                size: IconActionSize.inline,
                color: color,
                expanded: c.isOpen,
                onPressed: c.toggle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _underlined(Widget label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: label),
        Container(
          height: context.stroke.indicator,
          color: widget.selected
              ? context.colors.controlAccent
              : Colors.transparent,
        ),
      ],
    );
  }

  /// Folder tab: a hairline box behind a white box with no bottom inset, so
  /// the border wraps top + sides with an open bottom that meets the
  /// baseline. Unselected tabs reserve the same hairline so labels stay
  /// aligned.
  Widget _enclosed(Widget label) {
    final line = context.stroke.hairline;
    final inset = EdgeInsets.only(left: line, right: line, top: line);
    if (!widget.selected) return Padding(padding: inset, child: label);
    final radius = context.radii.radiusSmall;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.border,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Padding(
        padding: inset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(math.max(0, radius - line)),
            ),
          ),
          child: label,
        ),
      ),
    );
  }
}
