import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class MenuDemo extends StatefulWidget {
  @Preview(name: 'Menu', wrapper: adminUiPreview)
  const MenuDemo({super.key});

  @override
  State<MenuDemo> createState() => _MenuDemoState();
}

class _MenuDemoState extends State<MenuDemo> {
  String _last = '—';
  bool _inNavigation = true;
  bool _comments = false;

  void _pick(String action) => setState(() => _last = action);

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Action menu'),
        Menu(
          builder: (context, c) => Button(
            'Actions',
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            onPressed: c.toggle,
          ),
          entries: [
            MenuItem(
              'Edit',
              icon: Icons.edit_outlined,
              shortcut: _edit(context),
              onSelect: () => _pick('Edit'),
            ),
            MenuItem(
              'Duplicate',
              icon: Icons.copy_rounded,
              onSelect: () => _pick('Duplicate'),
            ),
            const MenuItem('Archive', icon: Icons.archive_outlined),
            const MenuDivider(),
            MenuItem(
              'Delete',
              icon: Icons.delete_outline_rounded,
              shortcut: _delete(context),
              danger: true,
              onSelect: () => _pick('Delete'),
            ),
          ],
        ),
        const Gap(AdminSpacing.lg),
        Text('Last selected: $_last', style: context.type.bodyMuted),
        const Gap(AdminSpacing.xxl),

        const DemoSection('With header, end-aligned'),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Menu(
            align: PopoverAlign.end,
            builder: (context, c) => Button.ghost(
              'More',
              icon: Icons.more_horiz_rounded,
              onPressed: c.toggle,
            ),
            entries: [
              const MenuHeader('Workspace'),
              MenuItem(
                'Settings',
                icon: Icons.settings_outlined,
                onSelect: () => _pick('Settings'),
              ),
              MenuItem(
                'Members',
                icon: Icons.group_outlined,
                onSelect: () => _pick('Members'),
              ),
              const MenuDivider(),
              MenuItem(
                'Sign out',
                icon: Icons.logout_rounded,
                onSelect: () => _pick('Sign out'),
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Open — header, shortcut, disabled and danger rows'),
        PinnedOpen(
          child: Menu(
            builder: (context, c) => Button(
              'Page',
              trailingIcon: Icons.keyboard_arrow_down_rounded,
              onPressed: c.toggle,
            ),
            entries: [
              const MenuHeader('Page'),
              MenuItem(
                'Edit',
                icon: Icons.edit_outlined,
                shortcut: _edit(context),
                onSelect: () => _pick('Edit'),
              ),
              MenuItem(
                'Duplicate',
                icon: Icons.copy_rounded,
                onSelect: () => _pick('Duplicate'),
              ),
              const MenuItem('Archive', icon: Icons.archive_outlined),
              const MenuDivider(),
              MenuItem(
                'Delete',
                icon: Icons.delete_outline_rounded,
                shortcut: _delete(context),
                danger: true,
                onSelect: () => _pick('Delete'),
              ),
            ],
          ),
        ),
        // Room for the open menu, which floats over whatever sits below.
        SizedBox(height: MediaQuery.textScalerOf(context).scale(240)),

        const DemoSection('Open — a submenu, checkbox items and a description'),
        PinnedOpen(
          levels: 2,
          child: Menu(
            builder: (context, c) => Button(
              'Organize',
              trailingIcon: Icons.keyboard_arrow_down_rounded,
              onPressed: c.toggle,
            ),
            entries: [
              MenuItem(
                'Duplicate',
                icon: Icons.copy_rounded,
                description: 'With its drafts and translations',
                onSelect: () => _pick('Duplicate'),
              ),
              MenuSubmenu(
                'Move to',
                icon: Icons.drive_file_move_outlined,
                entries: [
                  for (final folder in _folders.take(4))
                    MenuItem(
                      folder,
                      icon: Icons.folder_outlined,
                      onSelect: () => _pick('Move to $folder'),
                    ),
                  const MenuDivider(),
                  MenuItem(
                    'New folder',
                    icon: Icons.create_new_folder_outlined,
                    onSelect: () => _pick('New folder'),
                  ),
                ],
              ),
              MenuSubmenu(
                'Share',
                icon: Icons.share_outlined,
                entries: [
                  MenuItem(
                    'Copy link',
                    icon: Icons.link_rounded,
                    onSelect: () => _pick('Copy link'),
                  ),
                  MenuItem(
                    'Email',
                    icon: Icons.mail_outline_rounded,
                    onSelect: () => _pick('Email'),
                  ),
                ],
              ),
              const MenuDivider(),
              MenuCheckboxItem(
                'Show in navigation',
                checked: _inNavigation,
                onChanged: (value) => setState(() => _inNavigation = value),
              ),
              MenuCheckboxItem(
                'Allow comments',
                checked: _comments,
                onChanged: (value) => setState(() => _comments = value),
              ),
              const MenuDivider(),
              MenuItem(
                'Delete',
                icon: Icons.delete_outline_rounded,
                danger: true,
                onSelect: () => _pick('Delete'),
              ),
            ],
          ),
        ),
        // Room for the menu below its trigger, as tall as its text is.
        SizedBox(height: MediaQuery.textScalerOf(context).scale(260)),

        const DemoSection('Open — content of its own above the entries'),
        PinnedOpen(
          child: Menu(
            minWidth: 240,
            builder: (context, c) => Button(
              'Account',
              trailingIcon: Icons.keyboard_arrow_down_rounded,
              onPressed: c.toggle,
            ),
            header: Row(
              children: [
                const Avatar(name: 'Jane Doe', size: 32),
                const Gap(AdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jane Doe',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodyStrong,
                      ),
                      Text(
                        'jane@example.com',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            entries: [
              MenuItem(
                'Profile',
                icon: Icons.person_outline_rounded,
                onSelect: () => _pick('Profile'),
              ),
              const MenuDivider(),
              MenuItem(
                'Sign out',
                icon: Icons.logout_rounded,
                onSelect: () => _pick('Sign out'),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.textScalerOf(context).scale(200)),
      ],
    );
  }
}

/// Static menu surfaces pinning each row state. On the first, the second row
/// holds keyboard focus — the highlight the pointer and the arrow keys share
/// — with the keyboard highlight forced on while this page is up. On the
/// second, the pointer rests on the danger row, above a checked radio row
/// and a label too long for the surface. The third shows the other kinds of
/// row: checkbox items checked and not, a submenu's row with its chevron,
/// and a row with a description. Its own page, since an open menu takes
/// focus and closes when it leaves.
class MenuHighlightDemo extends StatefulWidget {
  @Preview(name: 'Menu keyboard highlight', wrapper: adminUiPreview)
  const MenuHighlightDemo({super.key});

  @override
  State<MenuHighlightDemo> createState() => _MenuHighlightDemoState();
}

class _MenuHighlightDemoState extends State<MenuHighlightDemo> {
  final _scope = FocusScopeNode(debugLabel: 'Pinned menu');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scope.traversalDescendants.elementAtOrNull(1)?.requestFocus();
    });
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 520,
        children: [
          const DemoSection(
            'Duplicate holds keyboard focus; Archive is disabled',
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FocusScope(
              node: _scope,
              child: _StaticMenu(entries: _staticEntries(context)),
            ),
          ),
          const Gap(AdminSpacing.xl),
          const DemoSection(
            'The pointer on Delete; a checked row; a label that ellipsizes',
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PinnedHover(
              target: (widget) => widget is Text && widget.data == 'Delete',
              child: const _StaticMenu(entries: _sortEntries),
            ),
          ),
          const Gap(AdminSpacing.xl),
          const DemoSection(
            'Checkbox items, a submenu row and a row with a description',
          ),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: _StaticMenu(entries: _viewEntries),
          ),
        ],
      ),
    );
  }
}

/// [entries] on a menu surface, as an open menu lays them out.
class _StaticMenu extends StatelessWidget {
  final List<MenuEntry> entries;

  const _StaticMenu({required this.entries});

  @override
  Widget build(BuildContext context) {
    // As a menu lines its labels up where a row has an icon.
    final iconColumn = entries.any(
      (entry) => switch (entry) {
        MenuItem(:final icon) ||
        MenuCheckboxItem(:final icon) ||
        MenuSubmenu(:final icon) => icon != null,
        MenuDivider() || MenuHeader() => false,
      },
    );
    return PopoverMenuSurface(
      minWidth: 200,
      maxWidth: 240,
      // Not a popover, so not capped to one's room: large text keeps every
      // row.
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(AdminSpacing.xs),
          for (final entry in entries)
            Menu.entry(
              context,
              entry,
              _staticController,
              iconColumn: iconColumn,
            ),
          const Gap(AdminSpacing.xs),
        ],
      ),
    );
  }
}

const _sortEntries = <MenuEntry>[
  MenuHeader('Sort by'),
  MenuItem('Last edited', checked: true, onSelect: _noop),
  MenuItem('Title', checked: false, onSelect: _noop),
  MenuDivider(),
  MenuItem(
    'Move to another collection and keep its translations',
    icon: Icons.drive_file_move_outlined,
    onSelect: _noop,
  ),
  MenuItem(
    'Delete',
    icon: Icons.delete_outline_rounded,
    danger: true,
    onSelect: _noop,
  ),
];

const _viewEntries = <MenuEntry>[
  MenuHeader('View'),
  MenuCheckboxItem('Show drafts', checked: true, onChanged: _noopChanged),
  MenuCheckboxItem('Show archived', checked: false, onChanged: _noopChanged),
  MenuDivider(),
  MenuSubmenu(
    'Group by',
    icon: Icons.segment_rounded,
    entries: [MenuItem('Status', onSelect: _noop)],
  ),
  MenuItem(
    'Export',
    icon: Icons.download_rounded,
    description: 'A CSV of the rows shown',
    onSelect: _noop,
  ),
];

/// Edit's shortcut as the platform writes it: ⌘E, or Ctrl+E.
String _edit(BuildContext context) =>
    shortcutLabel(context, primaryModifierActivator(LogicalKeyboardKey.keyE));

/// Delete's shortcut as the platform writes it: ⌫, or Backspace.
String _delete(BuildContext context) =>
    shortcutLabel(context, const SingleActivator(LogicalKeyboardKey.backspace));

List<MenuEntry> _staticEntries(BuildContext context) => [
  MenuItem(
    'Edit',
    icon: Icons.edit_outlined,
    shortcut: _edit(context),
    onSelect: _noop,
  ),
  const MenuItem('Duplicate', icon: Icons.copy_rounded, onSelect: _noop),
  const MenuItem('Archive', icon: Icons.archive_outlined),
  const MenuDivider(),
  MenuItem(
    'Delete',
    icon: Icons.delete_outline_rounded,
    shortcut: _delete(context),
    danger: true,
    onSelect: _noop,
  ),
];

void _noop() {}

void _noopChanged(bool _) {}

final _staticController = _StaticController();

/// Stands in for an open popover's controller, so rows render without one.
class _StaticController implements PopoverController {
  @override
  bool get isOpen => true;

  @override
  double? get anchorWidth => null;

  @override
  void open() {}

  @override
  void close() {}

  @override
  void toggle() {}
}

/// Where a menu opens: one hung from a trigger at the bottom edge flips above
/// it, and a long one is capped to the room beside its trigger and scrolls.
class MenuPlacementDemo extends StatelessWidget {
  @Preview(name: 'Menu placement', wrapper: adminUiPreview)
  const MenuPlacementDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Left: no room below the trigger, so the menu flips above it. '
              'Right: 24 items, capped to the room below the trigger — the '
              'list scrolls.',
              style: context.type.bodyMuted,
            ),
            const Gap(AdminSpacing.xxl),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: PinnedOpen(
                        child: Menu(
                          builder: (context, c) => Button(
                            'Bottom edge',
                            trailingIcon: Icons.keyboard_arrow_down_rounded,
                            onPressed: c.toggle,
                          ),
                          entries: _staticEntries(context),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: const Alignment(-1, -0.2),
                      child: PinnedOpen(
                        child: Menu(
                          builder: (context, c) => Button(
                            'Long menu',
                            trailingIcon: Icons.keyboard_arrow_down_rounded,
                            onPressed: c.toggle,
                          ),
                          entries: [
                            const MenuHeader('Move to'),
                            for (final folder in _folders)
                              MenuItem(
                                folder,
                                icon: Icons.folder_outlined,
                                onSelect: _noop,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _folders = [
  'Archive',
  'Blog',
  'Careers',
  'Case studies',
  'Changelog',
  'Community',
  'Contact',
  'Docs',
  'Events',
  'Guides',
  'Help center',
  'Home',
  'Integrations',
  'Legal',
  'Newsletter',
  'Partners',
  'Press',
  'Pricing',
  'Product',
  'Roadmap',
  'Security',
  'Status',
  'Support',
  'Team',
];
