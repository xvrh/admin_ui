import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The bare [Tree] over a product category tree, with rows the app draws: a
/// label and a count. It is one Tab stop with the arrow keys between its
/// rows, and a row moves by a drag of its handle, by Alt and an arrow, or
/// from the ⋯ menu at its end. Read-only, it has neither handles nor menus,
/// and keeps the keys that walk it.
class TreeDemo extends StatelessWidget {
  final bool _focused;

  @Preview(name: 'Tree', wrapper: adminUiPreview)
  const TreeDemo({super.key}) : _focused = false;

  /// The tree as Tab leaves it: its one Tab stop, the first row, ringed
  /// inside its edge.
  @Preview(name: 'Tree · keyboard focus', wrapper: adminUiPreview)
  const TreeDemo.focused({super.key}) : _focused = true;

  @override
  Widget build(BuildContext context) {
    if (_focused) {
      return const DemoPage(
        maxWidth: 520,
        children: [
          DemoVariant(
            'Tab stops on one row, ringed inside its edge; the arrows move '
            'the ring, and the next Tab goes to that row\'s ⋯',
            KeyboardHighlight(child: PinnedFocus(child: _LiveTree())),
          ),
        ],
      );
    }
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection(
          'Live — Tab to the tree, then ↑ ↓ Home End between rows and → ← to '
          'open, close and step in and out',
        ),
        const DemoVariant(
          'Move a row by its handle, with Alt+↑ ↓ → ←, or from its ⋯ menu',
          _LiveTree(),
        ),
        DemoVariant(
          'The ⋯ menu: every move beside its key; one the row cannot make '
          'is off',
          PinnedOpen(
            reserve: 96,
            child: Panel(
              padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
              child: Tree(
                roots: const [
                  TreeNode(id: 'kitchen'),
                  TreeNode(id: 'lighting'),
                ],
                onMove: (_, _, _) {},
                itemBuilder: (context, id, info) => _CategoryRow(id: id),
              ),
            ),
          ),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoSection('Three levels at most (maxDepth)'),
        const DemoVariant(
          'Indent is off where a row, or what it carries, would go deeper',
          _LiveTree(maxDepth: 2),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoSection('Read-only'),
        DemoVariant(
          'No onMove: no handles and no menus, the same keys between rows',
          Panel(
            padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
            child: Tree(
              roots: _seed,
              initiallyCollapsed: const {'home'},
              itemBuilder: (context, id, info) => _CategoryRow(id: id),
            ),
          ),
        ),
      ],
    );
  }
}

const _seed = [
  TreeNode(
    id: 'clothing',
    children: [
      TreeNode(
        id: 'outerwear',
        children: [
          TreeNode(id: 'coats'),
          TreeNode(id: 'rainwear'),
        ],
      ),
      TreeNode(id: 'knitwear'),
      TreeNode(id: 'shoes'),
    ],
  ),
  TreeNode(
    id: 'home',
    children: [
      TreeNode(id: 'kitchen'),
      TreeNode(id: 'lighting'),
    ],
  ),
  TreeNode(id: 'gifts'),
];

/// Each category's label and how many products it holds.
const _categories = <String, (String, int)>{
  'clothing': ('Clothing', 214),
  'outerwear': ('Outerwear', 58),
  'coats': ('Coats', 31),
  'rainwear': ('Rainwear', 27),
  'knitwear': ('Knitwear', 64),
  'shoes': ('Shoes', 92),
  'home': ('Home', 120),
  'kitchen': ('Kitchen', 75),
  'lighting': ('Lighting', 45),
  'gifts': ('Gifts', 18),
};

/// A tree that applies its own moves, as a host does from [Tree.onMove].
class _LiveTree extends StatefulWidget {
  final int? maxDepth;

  const _LiveTree({this.maxDepth});

  @override
  State<_LiveTree> createState() => _LiveTreeState();
}

class _LiveTreeState extends State<_LiveTree> {
  List<TreeNode> _roots = _seed;

  void _move(String id, String? parent, int index) {
    TreeNode? moved;
    List<TreeNode> without(List<TreeNode> nodes) => [
      for (final node in nodes)
        if (node.id == id)
          ...() {
            moved = node;
            return const <TreeNode>[];
          }()
        else
          TreeNode(id: node.id, children: without(node.children)),
    ];
    List<TreeNode> placed(List<TreeNode> nodes, String? under) {
      final here = under == parent && moved != null
          ? [...nodes.take(index), moved!, ...nodes.skip(index)]
          : nodes;
      return [
        for (final node in here)
          TreeNode(
            id: node.id,
            children: identical(node, moved)
                ? node.children
                : placed(node.children, node.id),
          ),
      ];
    }

    final rest = without(_roots);
    setState(() => _roots = placed(rest, null));
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
      child: Tree(
        roots: _roots,
        maxDepth: widget.maxDepth,
        onMove: _move,
        itemBuilder: (context, id, info) => _CategoryRow(id: id),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String id;

  const _CategoryRow({required this.id});

  @override
  Widget build(BuildContext context) {
    final (label, count) = _categories[id]!;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AdminSpacing.sm,
        end: AdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.bodyStrong,
            ),
          ),
          const Gap(AdminSpacing.md),
          Text(
            context.adminFormats.integer(count),
            style: context.type.caption.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
        ],
      ),
    );
  }
}
