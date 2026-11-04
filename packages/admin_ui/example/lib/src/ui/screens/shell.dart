import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Full-bleed demo: a realistic admin frame assembled from Shell + Sidebar +
/// TopBar + PageHeader, wired to the Button and Menu primitives. The item
/// after the selected one is pinned hovered, and the one after that focused
/// with the keyboard highlight on while the frame is up, so a still render
/// compares the states.
///
/// The frame's insets line up: the workspace logo sits over the sidebar's
/// icons ([Shell.inset]), and the top bar's "New" ends where the page
/// header's "Publish" does (the page gutter).
///
/// In a window narrower than the medium breakpoint the frame is compact:
/// the page takes the whole width and the top bar leads with the menu
/// button, which opens the sidebar as a drawer.
class ShellDemo extends StatefulWidget {
  /// The window width the frame is drawn at, or null for the whole preview.
  final double? windowWidth;

  /// Whether the sidebar starts as its icon rail.
  final bool collapsed;

  /// Opens with the compact frame's drawer open.
  final bool drawerOpen;

  @Preview(name: 'Shell (app frame)', wrapper: adminUiPreview)
  const ShellDemo({super.key})
    : windowWidth = null,
      collapsed = false,
      drawerOpen = false;

  /// The frame in a 500px window, compact: the menu button leads the top
  /// bar, the search folds to its icon and the gutter narrows.
  @Preview(name: 'Shell (narrow window)', wrapper: adminUiPreview)
  const ShellDemo.narrow({super.key})
    : windowWidth = 500,
      collapsed = false,
      drawerOpen = false;

  /// The frame at a phone's 360px, compact, its navigation in the drawer.
  @Preview(name: 'Shell (phone width)', wrapper: adminUiPreview)
  const ShellDemo.phone({super.key})
    : windowWidth = 360,
      collapsed = false,
      drawerOpen = false;

  /// The phone frame with its drawer open: `ShellDrawerDemo`'s.
  const ShellDemo.drawerOpen({super.key})
    : windowWidth = 360,
      collapsed = false,
      drawerOpen = true;

  @override
  State<ShellDemo> createState() => _ShellDemoState();
}

class _ShellDemoState extends State<ShellDemo> {
  String _page = 'Pages';
  late bool _collapsed = widget.collapsed;
  final _hovered = WidgetStatesController({WidgetState.hovered});
  final _focused = WidgetStatesController({WidgetState.focused});

  @override
  void dispose() {
    _hovered.dispose();
    _focused.dispose();
    super.dispose();
  }

  static const _nav = [
    ('Content', null, null),
    ('Dashboard', Icons.dashboard_outlined, null),
    ('Pages', Icons.description_outlined, '3'),
    ('Products', Icons.inventory_2_outlined, null),
    ('Media', Icons.photo_library_outlined, '12'),
    ('Settings', null, null),
    ('Users', Icons.group_outlined, null),
    ('Localization', Icons.translate_rounded, null),
    ('General', Icons.settings_outlined, null),
  ];

  List<NavEntry> get _entries {
    final items = [
      for (final (label, icon, _) in _nav)
        if (icon != null) label,
    ];
    String after(int n) => items[(items.indexOf(_page) + n) % items.length];
    final hovered = after(1), focused = after(2);
    return [
      for (final (label, icon, badge) in _nav)
        if (icon == null)
          NavSection(label)
        else
          NavItem(
            label,
            icon: icon,
            badge: badge,
            selected: _page == label,
            statesController: label == hovered
                ? _hovered
                : label == focused
                ? _focused
                : null,
            onTap: () => setState(() => _page = label),
          ),
    ];
  }

  void _openPalette(BuildContext context) {
    // ⌘K toggles — the palette sits below this shortcut, so the binding
    // still fires while it's open.
    final modals = ModalAnchor.of(context);
    if (modals.isOpen) {
      modals.close();
      return;
    }
    showCommandPalette(context, items: _paletteItems(context));
  }

  List<PaletteItem> _paletteItems(BuildContext context) => [
    for (final (label, icon, _) in _nav)
      if (icon != null)
        PaletteItem(
          id: label,
          title: label,
          icon: icon,
          group: 'Navigate',
          onSelect: () => setState(() => _page = label),
        ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = widget.windowWidth;
    return KeyboardHighlight(
      child: width == null
          ? _frame(context)
          : _Window(width: width, child: _frame(context)),
    );
  }

  Widget _frame(BuildContext context) {
    // The Builder context sits below AdminScope's modal anchor, so
    // _openPalette resolves it.
    return AdminScope(
      child: Builder(
        builder: (context) => CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
                _openPalette(context),
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
                _openPalette(context),
          },
          child: Focus(
            autofocus: true,
            child: Shell(
              // The footer and the leading are built below the sidebar and
              // the top bar, in the palette each draws with.
              sidebar: Sidebar(
                collapsed: _collapsed,
                footer: SidebarAccount(
                  name: 'Jane Doe',
                  detail: 'jane@example.com',
                  badge: const Tag('Owner'),
                  entries: const [
                    MenuItem('Profile', icon: Icons.person_outline_rounded),
                    MenuItem('Preferences', icon: Icons.tune_rounded),
                    MenuDivider(),
                    MenuItem('Sign out', icon: Icons.logout_rounded),
                  ],
                ),
                entries: _entries,
              ),
              topBar: TopBar(
                leading: Builder(builder: _leading),
                search: CommandTrigger(onTap: () => _openPalette(context)),
                onSearch: () => _openPalette(context),
                actions: [
                  Menu(
                    align: PopoverAlign.end,
                    builder: (context, c) => Button.primary(
                      'New',
                      icon: Icons.add_rounded,
                      onPressed: c.toggle,
                    ),
                    entries: const [
                      MenuItem('Page', icon: Icons.description_outlined),
                      MenuItem('Product', icon: Icons.inventory_2_outlined),
                      MenuItem('Upload media', icon: Icons.upload_rounded),
                    ],
                  ),
                ],
              ),
              child: widget.drawerOpen
                  ? _OpenDrawer(child: _Content(page: _page))
                  : _Content(page: _page),
            ),
          ),
        ),
      ),
    );
  }

  /// The workspace mark's side.
  static const _mark = 26.0;

  /// [Icons.menu_open_rounded], mirrored in a right-to-left layout: its
  /// arrow points to the rail's side, which is the right there.
  static const _menuOpen = IconData(
    0xf8b5,
    fontFamily: 'MaterialIcons',
    matchTextDirection: true,
  );

  /// How far the mark moves in over a collapsed rail, from [Shell.inset] to
  /// centred on the rail's icons (the theme's rail width inside its 1px
  /// border).
  static double _railInset(BuildContext context) =>
      (Sidebar.widthOf(context, collapsed: true) - 1) / 2 -
      _mark / 2 -
      Shell.inset;

  /// The workspace and the sidebar toggle, moved over a collapsed rail in
  /// step with the rail's own width. A narrow rail centres the mark short of
  /// [Shell.inset], so the move is a shift rather than a padding. A compact
  /// frame has no rail to toggle: the workspace alone, after the shell's
  /// menu button (and in its drawer, after the close button).
  Widget _leading(BuildContext context) {
    if (Shell.isCompact(context)) return _workspace(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _collapsed ? _railInset(context) : 0),
      duration: context.motion.medium,
      curve: context.motion.standard,
      builder: (context, shift, child) => Transform.translate(
        offset: Offset(
          Directionality.of(context) == TextDirection.rtl ? -shift : shift,
          0,
        ),
        child: child,
      ),
      child: Row(
        children: [
          _workspace(context),
          IconAction(
            _collapsed ? _menuOpen : Icons.menu_rounded,
            label: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
            onPressed: () => setState(() => _collapsed = !_collapsed),
          ),
        ],
      ),
    );
  }

  Widget _workspace(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AdminSpacing.md),
      child: Row(
        children: [
          Container(
            width: _mark,
            height: _mark,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(context.radii.radiusSmall),
            ),
            alignment: Alignment.center,
            // A mark, not a label: it keeps its size at any text scale, as
            // the box around it does.
            child: Text(
              'A',
              textScaler: TextScaler.noScaling,
              style: context.type.heading.copyWith(
                color: context.colors.onPrimary,
                fontSize: 14,
                height: 1,
              ),
            ),
          ),
          const Gap(AdminSpacing.md),
          Text('Acme Admin', style: context.type.bodyStrong),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final String page;
  const _Content({required this.page});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: page,
      subtitle: 'Manage your $page',
      scrollable: false,
      actions: [
        Button('Preview', icon: Icons.visibility_outlined, onPressed: () {}),
        Builder(
          builder: (context) => Button.primary(
            'Publish',
            icon: Icons.send_rounded,
            onPressed: () => ToastScope.of(context)
                .show(const Toast('Published.', severity: Severity.success)),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Alert(
            'This is a layout demo — the content area is a placeholder.',
            severity: Severity.info,
          ),
          const Gap(AdminSpacing.lg),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(context.radii.radiusLarge),
                border: Border.all(color: context.colors.border),
              ),
              child: Center(
                child: Text(
                  '$page content',
                  style: context.type.body.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the shell's drawer once the frame is up.
class _OpenDrawer extends StatefulWidget {
  final Widget child;

  const _OpenDrawer({required this.child});

  @override
  State<_OpenDrawer> createState() => _OpenDrawerState();
}

class _OpenDrawerState extends State<_OpenDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Shell.openDrawer(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Draws [child] as a window [width] wide: the width it lays out in and the
/// size [MediaQuery] reports, framed by a hairline. It sits at the preview's
/// start edge, where the compact frame's drawer slides in. On a phone (a
/// preview narrower than the medium breakpoint) it is the whole screen.
class _Window extends StatelessWidget {
  final double width;
  final Widget child;

  const _Window({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size.width;
    final width = screen < context.breakpoints.medium ? screen : this.width;
    return ColoredBox(
      color: context.colors.surfaceMuted,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          width: width,
          foregroundDecoration: width == screen
              ? null
              : BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: context.colors.border),
                  ),
                ),
          child: MediaQuery(
            data: media.copyWith(size: Size(width, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
