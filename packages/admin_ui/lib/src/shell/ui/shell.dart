/// @docImport '../../common/ui/admin_scope.dart';
/// @docImport '../../common/ui/leave_guard.dart';
/// @docImport '../../common/ui/modal_anchor.dart';
library;

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/modal_anchor.dart';
import '../../theme/breakpoints.dart';
import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'navigation_drawer.dart';
import 'page_header.dart';
import 'save_bar.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// The app frame: a full-width [topBar] (logo, command palette, user) over a row
/// of the [sidebar] and the page [child]. The pieces ([Sidebar], [TopBar]) are
/// supplied by the Screen.
///
/// The top bar spans the whole width so the logo sits above the sidebar column,
/// not beside it — the modern admin frame. [topBar] is optional; without it the
/// shell is just sidebar + content.
///
/// Shell *is* the page [Scaffold] — it provides the [Material] ancestor that ink,
/// text fields and tooltips need, and the registered scaffold that
/// [ScaffoldMessenger] snackbars target. It's a top-level frame, so don't nest
/// it inside another Scaffold.
///
/// The frame keeps two horizontal insets. The chrome's own, [inset], puts the
/// top bar's leading content over the sidebar's icons. The page's,
/// [PageHeader.gutterOf], insets the page header and body, and ends the top
/// bar and a [SaveBar] too, so their trailing actions line up with the
/// page's.
///
/// Narrower than the theme's medium breakpoint (`context.breakpoints`,
/// measured on the shell's own width), it is compact: the page takes the
/// whole width, and the navigation moves into a drawer, opened by the menu
/// button a [TopBar] then leads with, or by [openDrawer]. The drawer holds
/// [drawer], or else [sidebar], expanded, with [drawerLeading], or else the
/// [TopBar]'s own `leading` (its logo), at its head (see
/// [showNavigationDrawer]). That `leading` is then built twice while the
/// drawer is open, under the scrim and in the drawer, so a logo carrying a
/// `GlobalKey` goes to the head as a [drawerLeading] of its own. A top bar
/// of the app's own, rather than a [TopBar], has no menu button: it opens
/// the drawer from one of its own with [openDrawer], and gives the head its
/// logo as [drawerLeading]. It opens on the [ModalAnchor] above
/// the shell ([AdminScope] mounts one), so its items ask the page's
/// [LeaveGuardScope] before they leave, and it closes as the shell widens
/// again. Between the breakpoints the app keeps its rail
/// ([Sidebar.collapsed]), which opens over the page under the pointer or
/// keyboard focus. Beside that rail the top bar leads with the menu button
/// too, and the same drawer opens from it, for a touch screen.
///
/// On a device with insets, the top bar runs under the status bar in its
/// own colour and keeps its content below it, and the sidebar keeps the
/// bottom inset under its footer in its own colour.
class Shell extends StatefulWidget {
  final Widget sidebar;
  final Widget? topBar;
  final Widget child;

  /// What the compact shell's drawer holds in place of [sidebar]: a sidebar
  /// built apart for it, such as one carrying a key of its own.
  final Widget? drawer;

  /// What the drawer's head shows after its close button, in place of the
  /// [TopBar]'s `leading`: a logo built apart for it, such as one carrying a
  /// key of its own, or the logo of a top bar that is not a [TopBar].
  final Widget? drawerLeading;

  const Shell({
    super.key,
    required this.sidebar,
    this.topBar,
    this.drawer,
    this.drawerLeading,
    required this.child,
  });

  /// Where the chrome's content starts from the window's leading edge: the
  /// top bar's leading slot, and the sidebar's icons and section labels.
  static const inset = AdminSpacing.xl;

  /// The navigation drawer's width, narrowed to the window's.
  static const drawerWidth = 320.0;

  /// Whether the [Shell] around [context] is compact, its navigation in a
  /// drawer; true in that drawer too, and false outside a shell. [context]
  /// rebuilds as it changes.
  static bool isCompact(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ShellScope>();
    if (scope != null) return scope.compact;
    return NavigationDrawerScope.maybeOf(context) != null;
  }

  /// Whether the [Shell] around [context] opens its navigation as a drawer
  /// from its top bar's menu button: while it is compact, and between the
  /// breakpoints beside a collapsed rail ([Sidebar.collapsed]). False
  /// outside a shell. [context] rebuilds as it changes. A top bar of the
  /// app's own shows its menu button by it.
  static bool hasDrawer(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ShellScope>();
    return scope != null && (scope.compact || scope.rail);
  }

  /// Opens the navigation drawer of the [Shell] around [context], resolving
  /// once it has closed. Does nothing while the shell has no drawer
  /// ([hasDrawer]), or outside a shell.
  static Future<void> openDrawer(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ShellScope>()?.state._open() ??
      Future.value();

  /// Tells the [Shell] around [context] whether its sidebar is a collapsed
  /// rail, which gives the top bar its menu button.
  @internal
  static void reportRail(BuildContext context, {required bool rail}) => context
      .getInheritedWidgetOfExactType<_ShellScope>()
      ?.state
      ._reportRail(rail);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  /// What the open drawer shows, following [widget].
  late final _drawer = ValueNotifier<NavigationDrawerContent>(_content);

  /// The anchor the drawer is open on, while it is.
  ModalAnchorController? _anchor;
  bool _compact = false;

  /// Whether the sidebar beside the page is a collapsed rail. It says so
  /// as it builds, after the top bar has, so the top bar reads it a frame
  /// later.
  bool _rail = false;

  /// What the sidebar last said, while it waits for that frame.
  bool _railSaid = false;

  /// Whether the drawer opens beside the rail, between the breakpoints.
  bool _railDrawer = false;

  void _reportRail(bool rail) {
    if (rail == _railSaid) return;
    _railSaid = rail;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rail != _railSaid) setState(() => _rail = _railSaid);
    });
  }

  NavigationDrawerContent get _content => (
    sidebar: widget.drawer ?? widget.sidebar,
    leading:
        widget.drawerLeading ??
        switch (widget.topBar) {
          TopBar(:final leading) => leading,
          _ => null,
        },
  );

  @override
  void didUpdateWidget(Shell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_anchor == null) return;
    // The drawer is built on the anchor, outside this subtree, which may
    // already be built this frame.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drawer.value = _content;
    });
  }

  @override
  void dispose() {
    if (_anchor case final anchor?) {
      // The drawer goes with the shell, though the anchor may stay; [_open]
      // lets its content go once it has.
      SchedulerBinding.instance.addPostFrameCallback((_) => anchor.close());
    } else {
      _drawer.dispose();
    }
    super.dispose();
  }

  Future<void> _open() async {
    if (!(_compact || _railDrawer) || _anchor != null) return;
    _drawer.value = _content;
    final anchor = _anchor = ModalAnchor.of(context);
    try {
      await showShellDrawer(anchor, content: _drawer);
    } finally {
      _anchor = null;
      if (!mounted) _drawer.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = AdminBreakpoint.forWidth(
          constraints.maxWidth,
          context.breakpoints,
        );
        final compact = breakpoint.isCompact;
        _compact = compact;
        // An expanded window's rail is the user's choice, with a toggle of
        // the app's own.
        final rail = breakpoint.isMedium && _rail;
        _railDrawer = rail;
        if (!compact && !rail && _anchor != null) {
          // Wide again: the whole sidebar is back beside the page.
          final anchor = _anchor!;
          SchedulerBinding.instance.addPostFrameCallback((_) => anchor.close());
        }
        final topBar = widget.topBar;
        final row = Row(
          children: [
            if (!compact) widget.sidebar,
            Expanded(child: widget.child),
          ],
        );
        return _ShellScope(
          state: this,
          compact: compact,
          rail: rail,
          child: Scaffold(
            backgroundColor: context.colors.background,
            body: Column(
              children: [
                ?topBar,
                Expanded(
                  child: topBar == null
                      ? row
                      // The top bar takes the top inset. Read below the
                      // Scaffold, which takes the keyboard's out of the body.
                      : Builder(
                          builder: (context) => MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: row,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShellScope extends InheritedWidget {
  final _ShellState state;
  final bool compact;

  /// The sidebar beside the page is a collapsed rail.
  final bool rail;

  const _ShellScope({
    required this.state,
    required this.compact,
    required this.rail,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ShellScope old) =>
      compact != old.compact || rail != old.rail || state != old.state;
}

/// Draws [child] in [palette] in place of the page's, for a part of the frame
/// a theme draws in another scheme (Carbon's g100 header, Ant's dark sider):
/// the enclosing kit theme rebuilt with that palette, its type colours
/// following. Only the theme changes, so the commands, toasts and modal
/// anchor below stay the app's.
@internal
class ChromeTheme extends StatefulWidget {
  final AdminPalette palette;
  final Widget child;

  const ChromeTheme({super.key, required this.palette, required this.child});

  @override
  State<ChromeTheme> createState() => _ChromeThemeState();
}

class _ChromeThemeState extends State<ChromeTheme> {
  /// The theme built for [_tokens] with [_palette], kept while both stay
  /// equal.
  ThemeData? _theme;
  AdminTokens? _tokens;
  AdminPalette? _palette;

  @override
  Widget build(BuildContext context) {
    final tokens = context.adminTokens;
    final palette = widget.palette;
    if (tokens != _tokens || palette != _palette) {
      _theme = buildAppTheme(tokens.copyWith(palette: palette));
      _tokens = tokens;
      _palette = palette;
    }
    return Theme(
      data: _theme!,
      // Text that sets no colour of its own reads on the chrome, not in the
      // page's ink the enclosing Material set.
      child: DefaultTextStyle.merge(
        style: TextStyle(color: palette.foreground),
        child: widget.child,
      ),
    );
  }
}
