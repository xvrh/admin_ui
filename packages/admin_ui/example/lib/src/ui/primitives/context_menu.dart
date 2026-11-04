import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// A menu opened where the pointer right-clicks, or from the keyboard.
///
/// A list of files, each row a [ContextMenuRegion], with one menu pinned
/// open where a row was right-clicked; and a tile in the window's
/// bottom-end corner right-clicked near its edge, whose menu flips above
/// the point and shifts in from the edge. A screen rather than a page, so
/// the corner is the window's.
class ContextMenuDemo extends StatelessWidget {
  @Preview(name: 'Context menu', wrapper: adminUiPreview)
  const ContextMenuDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoSection('Right-click a row, or long-press it'),
            Text(
              'Shift+F10 or the context-menu key opens the menu of the row '
              'holding focus.',
              style: context.type.bodyMuted,
            ),
            const Gap(AdminSpacing.xl),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const _FileList(),
              ),
            ),
            const Spacer(),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: _PinnedRightClick(
                at: const AlignmentDirectional(0.8, -0.5),
                child: ContextMenuRegion(
                  entries: _trashMenu,
                  child: const _TrashTile(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _File = ({String name, IconData icon, String size, String edited});

const _files = <_File>[
  (
    name: 'Quarterly report.pdf',
    icon: Icons.picture_as_pdf_outlined,
    size: '2.4 MB',
    edited: 'Today',
  ),
  (
    name: 'Invoice 1042.pdf',
    icon: Icons.picture_as_pdf_outlined,
    size: '184 KB',
    edited: 'Yesterday',
  ),
  (
    name: 'Team offsite.jpg',
    icon: Icons.image_outlined,
    size: '3.1 MB',
    edited: 'Mar 4',
  ),
  (
    name: 'Roadmap.xlsx',
    icon: Icons.table_chart_outlined,
    size: '96 KB',
    edited: 'Feb 27',
  ),
];

const _folders = ['Archive', 'Finance', 'Marketing', 'Shared'];

List<MenuEntry> _fileMenu(BuildContext context) => [
  const MenuItem('Open', icon: Icons.open_in_new_rounded, onSelect: _noop),
  MenuItem(
    'Rename',
    icon: Icons.edit_outlined,
    shortcut: shortcutLabel(
      context,
      const SingleActivator(LogicalKeyboardKey.f2),
    ),
    onSelect: _noop,
  ),
  const MenuItem('Duplicate', icon: Icons.copy_rounded, onSelect: _noop),
  MenuSubmenu(
    'Move to',
    icon: Icons.drive_file_move_outlined,
    entries: [
      for (final folder in _folders)
        MenuItem(folder, icon: Icons.folder_outlined, onSelect: _noop),
    ],
  ),
  const MenuDivider(),
  MenuItem(
    'Delete',
    icon: Icons.delete_outline_rounded,
    shortcut: shortcutLabel(
      context,
      const SingleActivator(LogicalKeyboardKey.backspace),
    ),
    danger: true,
    onSelect: _noop,
  ),
];

List<MenuEntry> _trashMenu(BuildContext context) => const [
  MenuItem('Open trash', icon: Icons.delete_outline_rounded, onSelect: _noop),
  MenuItem('Restore all', icon: Icons.restore_rounded, onSelect: _noop),
  MenuDivider(),
  MenuItem(
    'Empty trash',
    icon: Icons.delete_forever_outlined,
    danger: true,
    onSelect: _noop,
  ),
];

void _noop() {}

/// The files as a bordered list, the second row right-clicked.
class _FileList extends StatelessWidget {
  const _FileList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      // A tinted first or last row keeps the list's corners.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(context.radii.radius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, file) in _files.indexed) ...[
            if (i > 0)
              Divider(
                height: context.stroke.hairline,
                thickness: context.stroke.hairline,
                color: colors.separator,
              ),
            if (i == 1)
              _PinnedRightClick(
                at: const AlignmentDirectional(-0.3, 0),
                child: _FileRow(file),
              )
            else
              _FileRow(file),
          ],
        ],
      ),
    );
  }
}

/// One file, whose menu its right-click opens; tinted while the menu is
/// open, so it is plain which file the menu acts on.
class _FileRow extends StatefulWidget {
  final _File file;

  const _FileRow(this.file);

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final file = widget.file;
    return ContextMenuRegion(
      entries: _fileMenu,
      onOpenChanged: (open) => setState(() => _menuOpen = open),
      child: Tappable(
        onTap: () {},
        semanticLabel: file.name,
        child: Container(
          color: _menuOpen ? colors.tableRowHover : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                file.icon,
                size: context.iconSizes.md,
                color: colors.foregroundMuted,
              ),
              const Gap(AdminSpacing.md),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.body,
                ),
              ),
              const Gap(AdminSpacing.lg),
              SizedBox(
                width: 72,
                child: Text(
                  file.size,
                  textAlign: TextAlign.end,
                  style: context.type.caption,
                ),
              ),
              const Gap(AdminSpacing.lg),
              SizedBox(
                width: 72,
                child: Text(file.edited, style: context.type.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrashTile extends StatelessWidget {
  const _TrashTile();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tappable(
      onTap: () {},
      semanticLabel: 'Trash',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(context.radii.radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: context.iconSizes.md,
              color: colors.foregroundMuted,
            ),
            const Gap(AdminSpacing.md),
            Text('Trash', style: context.type.body),
            const Gap(AdminSpacing.lg),
            Text('3 items', style: context.type.caption),
          ],
        ),
      ),
    );
  }
}

/// Right-clicks [child] once it is laid out, at [at] within it, so a static
/// preview shows the menu a right-click opens there. Every one on a page
/// clicks in the same frame, before any of their menus is up to take the
/// next click for a click outside it. Its mouse is unplugged when this
/// leaves the tree.
class _PinnedRightClick extends StatefulWidget {
  final AlignmentGeometry at;
  final Widget child;

  const _PinnedRightClick({required this.at, required this.child});

  @override
  State<_PinnedRightClick> createState() => _PinnedRightClickState();
}

class _PinnedRightClickState extends State<_PinnedRightClick> {
  /// Device and pointer ids apart from the real mice's and the pinned
  /// hovers', one per pinned click.
  static var _nextDevice = 0x6000;

  final _device = _nextDevice++;
  Offset? _position;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _click());
  }

  @override
  void dispose() {
    if (_position case final position?) {
      final device = _device;
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

  void _click() {
    final box = context.findRenderObject();
    if (!mounted || box is! RenderBox || !box.hasSize) return;
    final at = widget.at
        .resolve(Directionality.of(context))
        .withinRect(Offset.zero & box.size);
    final position = box.localToGlobal(at);
    _position = position;
    final gestures = GestureBinding.instance;
    gestures.handlePointerEvent(
      PointerDownEvent(
        pointer: _device,
        device: _device,
        position: position,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      ),
    );
    gestures.handlePointerEvent(
      PointerUpEvent(
        pointer: _device,
        device: _device,
        position: position,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
