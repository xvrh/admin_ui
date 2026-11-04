import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import 'mock_diff.dart';

/// The inline word-level text diff on its own, unified and split.
class TextDiffDemo extends StatelessWidget {
  @Preview(name: 'Inline text diff', wrapper: adminUiPreview)
  const TextDiffDemo({super.key});

  static const _pairs = [
    ('Small edit', 'Build faster with Acme', 'Ship faster with Acme Cloud'),
    (
      'Sentence rewrite',
      'Acme helps engineering teams build and deploy software faster.',
      'Acme Cloud helps engineering teams build, test, and deploy software faster than ever.',
    ),
    ('Added from empty', '', 'A brand new tagline.'),
    ('Removed entirely', 'This line is going away.', ''),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 640,
      children: [
        const DemoSection('Unified'),
        for (final (label, before, after) in _pairs)
          DemoVariant(label, TextDiff(before: before, after: after)),
        const SizedBox(height: 8),
        const DemoSection('Split (before | after)'),
        for (final (label, before, after) in _pairs)
          DemoVariant(
            label,
            TextDiff(before: before, after: after, layout: DiffLayout.split),
          ),
      ],
    );
  }
}

/// The block-id-keyed body diff on its own — added / removed / changed / moved,
/// in both layouts, with a toggle for unchanged blocks.
class BlockDiffDemo extends StatefulWidget {
  @Preview(name: 'Block diff', wrapper: adminUiPreview)
  const BlockDiffDemo({super.key});

  @override
  State<BlockDiffDemo> createState() => _BlockDiffDemoState();
}

class _BlockDiffDemoState extends State<BlockDiffDemo> {
  bool _showUnchanged = false;

  @override
  Widget build(BuildContext context) {
    final blocks =
        (diffAgainst('v4').fields
                .firstWhere((f) => f.fieldKey == 'body')
                .locales
                .firstWhere((l) => l.locale == 'en'))
            .blocks;

    return DemoPage(
      maxWidth: 720,
      children: [
        Row(
          children: [
            Text('Show unchanged blocks', style: context.type.body),
            const SizedBox(width: 12),
            Toggle(
              value: _showUnchanged,
              onChanged: (v) => setState(() => _showUnchanged = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const DemoSection('Unified'),
        BlockDiff(blocks: blocks, showUnchanged: _showUnchanged),
        const SizedBox(height: 28),
        const DemoSection('Split (before | after)'),
        BlockDiff(
          blocks: blocks,
          layout: DiffLayout.split,
          showUnchanged: _showUnchanged,
        ),
      ],
    );
  }
}
