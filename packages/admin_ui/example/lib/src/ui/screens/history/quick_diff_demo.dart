import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import 'mock_diff.dart';

/// The popover-sized diffs behind a field's Edited marker and a block's
/// gutter bar, shown open: the op tags, a translated field, a record list and
/// every block op — each with the one Restore verb.
class QuickDiffDemo extends StatelessWidget {
  @Preview(name: 'Quick diffs', wrapper: adminUiPreview)
  const QuickDiffDemo({super.key});

  static const _surface = 360.0;

  @override
  Widget build(BuildContext context) {
    final title = diffAgainst('v4').fields
        .firstWhere((f) => f.fieldKey == 'title');
    return DemoPage(
      maxWidth: 840,
      children: [
        const DemoSection('Op tags'),
        const DemoVariant(
          'One word and one tone per op, shared with the block and version '
          'diffs',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DiffOpTag(DiffOp.added),
              DiffOpTag(DiffOp.changed),
              DiffOpTag(DiffOp.moved),
              DiffOpTag(DiffOp.removed),
            ],
          ),
        ),
        const DemoSection('Field quick diff'),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            DemoVariant(
              'Translated text — the changed lanes, with Restore',
              SizedBox(
                width: _surface,
                child: FieldQuickDiff(
                  title,
                  laneLabel: (code) => code.toUpperCase(),
                  onRevert: () {},
                ),
              ),
            ),
            const DemoVariant(
              'A record list — each changed record and its fields',
              SizedBox(width: _surface, child: FieldQuickDiff(sectionsDiff)),
            ),
          ],
        ),
        const DemoSection('Block quick diff'),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (final block in bodyBlocks)
              if (block.op != DiffOp.unchanged)
                DemoVariant(
                  '${DiffOpStyle.of(context, block.op).label} '
                  '${block.type.startsWith('heading') ? 'heading' : block.type}',
                  SizedBox(
                    width: _surface,
                    child: QuickDiffSurface(
                      child: BlockQuickDiff(block, onRevert: () {}),
                    ),
                  ),
                ),
            const DemoVariant(
              'A block with no text reads its summary',
              SizedBox(
                width: _surface,
                child: QuickDiffSurface(
                  child: BlockQuickDiff(
                    BlockChange(
                      id: 'img',
                      type: 'image',
                      op: DiffOp.changed,
                      summary: 'Image replaced · hero-dark.png',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
