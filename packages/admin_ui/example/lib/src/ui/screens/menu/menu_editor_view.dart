import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

// Badges show a link's health, as a menu builder maps it: a link to a page
// is emphasised, an external link is a success, a path is neutral, an
// unpublished page a warning and a missing one a danger.
const _entityBadge = TreeEntryBadge(
  icon: Icons.description_outlined,
  label: 'Home',
  emphasised: true,
);
const _externalBadge = TreeEntryBadge(
  icon: Icons.open_in_new_rounded,
  label: 'blog.acme.com',
  tone: Severity.success,
);
const _pathBadge = TreeEntryBadge(icon: Icons.link_rounded, label: '/contact');
const _unpublishedBadge = TreeEntryBadge(
  icon: Icons.description_outlined,
  label: 'Pricing',
  tone: Severity.warning,
);
const _missingBadge = TreeEntryBadge(
  icon: Icons.error_outline_rounded,
  label: 'Deleted page',
  tone: Severity.danger,
);

/// A menu builder's own words for the tree's add button and header tag; the
/// kit's defaults are "Add item" and "Group".
const _addLabel = 'Add menu item';
const _headerLabel = 'Section';

/// [TreeEditor] as a menu builder, over a flat entry list: drag/nest,
/// keyboard moves, visibility, link-health badges, selection + the spliced
/// detail editor, the row actions' states, and read-only.
class MenuEditorDemo extends StatelessWidget {
  @Preview(name: 'Menu editor (tree)', wrapper: adminUiPreview)
  const MenuEditorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 560,
      children: [
        const DemoSection(
          'Live — drag, or Alt+arrows on a focused row, to reorder/nest; '
          'toggle the editor layout (inline vs focus card)',
        ),
        const _Live(),
        const Gap(AdminSpacing.xxxl),
        const DemoSection('Link health reads inline, before opening anything'),
        DemoVariant(
          'Resolved / external / path / unpublished (amber) / missing (red) / section',
          TreeEditor(
            addLabel: _addLabel,
            headerLabel: _headerLabel,
            maxDepth: 2,
            entries: const [
              TreeEditorEntry(id: 'a', title: 'Home', badge: _entityBadge),
              TreeEditorEntry(id: 'b', title: 'Blog', badge: _externalBadge),
              TreeEditorEntry(id: 'c', title: 'Contact', badge: _pathBadge),
              TreeEditorEntry(
                id: 'd',
                title: 'Pricing',
                badge: _unpublishedBadge,
              ),
              TreeEditorEntry(
                id: 'e',
                title: 'Old offer',
                badge: _missingBadge,
              ),
              TreeEditorEntry(id: 'f', title: 'Resources', isHeader: true),
              TreeEditorEntry(
                id: 'g',
                parentId: 'f',
                title: 'Docs',
                badge: _pathBadge,
              ),
            ],
          ),
        ),
        const DemoSection('Row actions'),
        DemoVariant(
          'Selected: add child and delete show, as under the pointer or focus',
          TreeEditor(
            addLabel: _addLabel,
            headerLabel: _headerLabel,
            maxDepth: 2,
            selectedId: 'm2',
            entries: const [
              TreeEditorEntry(id: 'm1', title: 'Home', badge: _entityBadge),
              TreeEditorEntry(id: 'm2', title: 'Pricing', badge: _pathBadge),
              TreeEditorEntry(id: 'm3', title: 'Contact', badge: _pathBadge),
            ],
            onSelect: (_) {},
            onMove: (_, _, _) {},
            onToggleVisible: (_) {},
            onAddChild: (_) {},
            onDelete: (_) {},
          ),
        ),
        DemoVariant(
          'Focus card: a nested entry’s editor, indented under its row',
          TreeEditor(
            addLabel: _addLabel,
            headerLabel: _headerLabel,
            maxDepth: 2,
            layout: TreeEditorLayout.focusCard,
            selectedId: 'f2',
            entries: const [
              TreeEditorEntry(id: 'f1', title: 'Shop', isHeader: true),
              TreeEditorEntry(
                id: 'f2',
                parentId: 'f1',
                title: 'New arrivals',
                badge: _entityBadge,
              ),
              TreeEditorEntry(id: 'f3', title: 'About us', badge: _entityBadge),
            ],
            onSelect: (_) {},
            onMove: (_, _, _) {},
            detailBuilder: (context, id) => Text(
              'Title, link and kind are edited here.',
              style: context.type.bodyMuted,
            ),
          ),
        ),
        DemoVariant(
          'The ⋯ menu: every move with its key, then add child and delete',
          PinnedOpen(
            reserve: 250,
            child: TreeEditor(
              addLabel: _addLabel,
              headerLabel: _headerLabel,
              maxDepth: 2,
              entries: const [
                TreeEditorEntry(id: 'p1', title: 'Services', badge: _pathBadge),
                TreeEditorEntry(id: 'p2', title: 'Team', badge: _entityBadge),
              ],
              onSelect: (_) {},
              onMove: (_, _, _) {},
              onToggleVisible: (_) {},
              onAddChild: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
        const DemoSection('Edge shapes'),
        DemoVariant(
          'Hidden entry (dimmed) + long title (ellipsis)',
          TreeEditor(
            addLabel: _addLabel,
            headerLabel: _headerLabel,
            maxDepth: 2,
            entries: const [
              TreeEditorEntry(
                id: 'h',
                title: 'A very long navigation label that should ellipsize rather than wrap or overflow',
                badge: _pathBadge,
              ),
              TreeEditorEntry(
                id: 'i',
                title: 'Hidden item',
                visible: false,
                badge: _entityBadge,
              ),
            ],
          ),
        ),
        DemoVariant(
          'Read-only preview (no callbacks → no drag handles, no actions)',
          TreeEditor(
            addLabel: _addLabel,
            headerLabel: _headerLabel,
            maxDepth: 2,
            entries: const [
              TreeEditorEntry(id: 'j', title: 'Home', badge: _entityBadge),
              TreeEditorEntry(id: 'k', title: 'Shop', isHeader: true),
              TreeEditorEntry(
                id: 'l',
                parentId: 'k',
                title: 'New in',
                badge: _entityBadge,
              ),
            ],
          ),
        ),
        DemoVariant(
          'Empty',
          TreeEditor(
            addLabel: _addLabel,
            headerLabel: _headerLabel,
            entries: const [],
            onAddRoot: () {},
            empty: Text('No menu items yet', style: context.type.bodyMuted),
          ),
        ),
      ],
    );
  }
}

class _Entry {
  _Entry(
    this.id,
    this.title, {
    this.parentId,
    this.isHeader = false,
    this.visible = true,
    this.badge,
  });
  final String id;
  String? parentId;
  String title;
  bool isHeader;
  bool visible;
  TreeEntryBadge? badge;
}

class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  final _entries = <_Entry>[
    _Entry('home', 'Home', badge: _entityBadge),
    _Entry('shop', 'Shop', isHeader: true),
    _Entry('new', 'New arrivals', parentId: 'shop', badge: _entityBadge),
    _Entry('sale', 'On sale', parentId: 'shop', badge: _pathBadge),
    _Entry('about', 'About us', badge: _entityBadge),
    _Entry('blog', 'Blog', visible: false, badge: _externalBadge),
  ];
  String? _selected;
  int _seq = 0;
  TreeEditorLayout _layout = TreeEditorLayout.focusCard;

  _Entry _byId(String id) => _entries.firstWhere((e) => e.id == id);

  void _move(String id, String? parentId, int index) {
    setState(() {
      final e = _byId(id);
      _entries.remove(e);
      e.parentId = parentId;
      final siblings = _entries.where((x) => x.parentId == parentId).toList();
      if (index >= siblings.length) {
        if (siblings.isEmpty) {
          _entries.add(e);
        } else {
          _entries.insert(_entries.indexOf(siblings.last) + 1, e);
        }
      } else {
        _entries.insert(_entries.indexOf(siblings[index]), e);
      }
    });
  }

  void _delete(String id) {
    setState(() {
      final doomed = <String>{id};
      bool grow() {
        final before = doomed.length;
        for (final e in _entries) {
          if (e.parentId != null && doomed.contains(e.parentId)) {
            doomed.add(e.id);
          }
        }
        return doomed.length != before;
      }

      while (grow()) {}
      _entries.removeWhere((e) => doomed.contains(e.id));
      if (doomed.contains(_selected)) _selected = null;
    });
  }

  void _addRoot() => setState(() {
    final e = _Entry('n${_seq++}', 'New item', badge: _pathBadge);
    _entries.add(e);
    _selected = e.id;
  });

  void _addChild(String id) => setState(() {
    final e = _Entry('n${_seq++}', 'New item', parentId: id, badge: _pathBadge);
    _entries.add(e);
    _selected = e.id;
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Segmented<TreeEditorLayout>(
            value: _layout,
            onChanged: (v) => setState(() => _layout = v),
            segments: const [
              SegmentOption(TreeEditorLayout.inline, 'Inline'),
              SegmentOption(TreeEditorLayout.focusCard, 'Focus card'),
            ],
          ),
        ),
        const Gap(AdminSpacing.lg),
        _editor(),
      ],
    );
  }

  Widget _editor() {
    return TreeEditor(
      addLabel: _addLabel,
      headerLabel: _headerLabel,
      maxDepth: 2,
      layout: _layout,
      selectedId: _selected,
      entries: [
        for (final e in _entries)
          TreeEditorEntry(
            id: e.id,
            parentId: e.parentId,
            title: e.title,
            isHeader: e.isHeader,
            visible: e.visible,
            badge: e.isHeader ? null : e.badge,
          ),
      ],
      onSelect: (id) => setState(() => _selected = id == _selected ? null : id),
      onMove: _move,
      onToggleVisible: (id) =>
          setState(() => _byId(id).visible = !_byId(id).visible),
      onAddChild: _addChild,
      onDelete: _delete,
      onAddRoot: _addRoot,
      detailBuilder: (context, id) =>
          _Detail(entry: _byId(id), onChanged: () => setState(() {})),
    );
  }
}

/// A stand-in for the connected per-entry editor (Slice E splices the real
/// title / kind / LinkField + host payload form here).
class _Detail extends StatelessWidget {
  final _Entry entry;
  final VoidCallback onChanged;

  const _Detail({required this.entry, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldShell(
          label: 'Title',
          child: TextBody(
            value: entry.title,
            onChanged: (v) {
              entry.title = v;
              onChanged();
            },
          ),
        ),
        const Gap(AdminSpacing.lg),
        FieldShell(
          label: 'Type',
          child: Segmented<bool>(
            value: entry.isHeader,
            onChanged: (v) {
              entry.isHeader = v;
              onChanged();
            },
            segments: const [
              SegmentOption(false, 'Link'),
              SegmentOption(true, 'Section'),
            ],
          ),
        ),
        const Gap(AdminSpacing.lg),
        Text(
          'Link, visibility and any host payload fields are spliced here in the '
          'real form (Slice E).',
          style: context.type.bodyMuted,
        ),
      ],
    );
  }
}
