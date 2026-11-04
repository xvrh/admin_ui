import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// [InsertPicker] as the block picker a layout gallery and the prose insert
/// menu share: a search box over a sectioned listbox, with a live preview
/// pane where the catalog has previews — beside the list when there is room,
/// below it on demand when there is not. The kit words it neutrally
/// ("Search…"), so a block picker passes its own wording.
class UnifiedBlockPickerDemo extends StatelessWidget {
  @Preview(name: 'Block picker', wrapper: adminUiPreview)
  const UnifiedBlockPickerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 760,
      children: [
        const DemoSection('With previews'),
        DemoVariant(
          'Two panes: the highlighted block previews beside the list',
          _Surface(
            child: InsertPicker(
              entries: _gallery,
              hint: _searchBlocks,
              semanticLabel: _blocks,
              onSelect: (_) {},
            ),
          ),
        ),
        DemoVariant(
          'Narrower than both panes: one pane, the preview behind the eye',
          SizedBox(
            width: 420,
            child: _Surface(
              child: InsertPicker(
                entries: _gallery,
                hint: _searchBlocks,
                semanticLabel: _blocks,
                maxListHeight: 360,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
        DemoVariant(
          '… and with the preview open below the list',
          SizedBox(
            width: 420,
            child: _PreviewOpen(
              child: _Surface(
                child: InsertPicker(
                  entries: _gallery,
                  hint: _searchBlocks,
                  semanticLabel: _blocks,
                  maxListHeight: 480,
                  onSelect: (_) {},
                ),
              ),
            ),
          ),
        ),
        const DemoSection('Without previews'),
        DemoVariant(
          'The inline insert menu: one pane',
          _Surface(
            child: InsertPicker(
              entries: _inline,
              hint: 'Insert…',
              semanticLabel: _blocks,
              maxListHeight: 300,
              onSelect: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}

const _searchBlocks = 'Search blocks…';
const _blocks = 'Blocks';

/// The popover or dialog a host mounts the picker in.
class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(context.radii.radiusLarge),
          border: Border.all(color: colors.border),
          boxShadow: context.elevation.md,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// Presses the picker's Preview toggle once mounted, so a static preview shows
/// the one-pane layout with its preview open.
class _PreviewOpen extends StatefulWidget {
  final Widget child;

  const _PreviewOpen({required this.child});

  @override
  State<_PreviewOpen> createState() => _PreviewOpenState();
}

class _PreviewOpenState extends State<_PreviewOpen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      VoidCallback? toggle;
      void visit(Element element) {
        if (toggle != null) return;
        final widget = element.widget;
        if (widget is IconAction && widget.label == 'Preview') {
          toggle = widget.onPressed;
          return;
        }
        element.visitChildren(visit);
      }

      context.visitChildElements(visit);
      toggle?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A stand-in rendering of a section, sized to the preview pane.
class _MockSection extends StatelessWidget {
  final String heading;
  final int columns;
  final bool button;

  const _MockSection({
    required this.heading,
    this.columns = 1,
    this.button = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget bar(double width) => Container(
      width: width,
      height: 6,
      margin: const EdgeInsets.only(top: AdminSpacing.sm),
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    final section = Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.radii.radius),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(heading, style: context.type.heading),
          Row(
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const Gap(AdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [bar(double.infinity), bar(120), bar(80)],
                  ),
                ),
              ],
            ],
          ),
          if (button) ...[
            const Gap(AdminSpacing.lg),
            Button.primary('Get started', onPressed: () {}),
          ],
        ],
      ),
    );
    return SingleChildScrollView(child: section);
  }
}

final _gallery = [
  InsertPickerEntry(
    id: 'hero',
    label: 'Hero',
    description: 'A large heading, a line of copy and a call to action',
    icon: Icons.view_day_outlined,
    category: 'Layout',
    keywords: const ['banner', 'header'],
    preview: (_) => const _MockSection(heading: 'Plan your week', button: true),
  ),
  InsertPickerEntry(
    id: 'columns',
    label: 'Two columns',
    description: 'Side-by-side text blocks',
    icon: Icons.view_column_outlined,
    category: 'Layout',
    preview: (_) => const _MockSection(heading: 'Why it works', columns: 2),
  ),
  InsertPickerEntry(
    id: 'cta',
    label: 'Call to action',
    description: 'A band with a heading and a button',
    icon: Icons.campaign_outlined,
    category: 'Layout',
    preview: (_) =>
        const _MockSection(heading: 'Ready when you are', button: true),
  ),
  const InsertPickerEntry(
    id: 'prose',
    label: 'Text',
    description: 'Paragraphs, lists and links',
    icon: Icons.notes_rounded,
    category: 'Content',
  ),
  const InsertPickerEntry(
    id: 'quote',
    label: 'Quote',
    description: 'A pull quote with its source',
    icon: Icons.format_quote_outlined,
    category: 'Content',
  ),
  const InsertPickerEntry(
    id: 'image',
    label: 'Image',
    description: 'One picture with a caption',
    icon: Icons.image_outlined,
    category: 'Media',
  ),
  const InsertPickerEntry(
    id: 'gallery',
    label: 'Gallery',
    description: 'A grid of pictures',
    icon: Icons.photo_library_outlined,
    category: 'Media',
  ),
];

const _inline = [
  InsertPickerEntry(
    id: 'h2',
    label: 'Heading',
    description: 'A section title',
    icon: Icons.title_rounded,
    category: 'Text',
  ),
  InsertPickerEntry(
    id: 'bullets',
    label: 'Bulleted list',
    icon: Icons.format_list_bulleted_rounded,
    category: 'Text',
  ),
  InsertPickerEntry(
    id: 'numbers',
    label: 'Numbered list',
    icon: Icons.format_list_numbered_rounded,
    category: 'Text',
  ),
  InsertPickerEntry(
    id: 'divider',
    label: 'Divider',
    description: 'A thin rule between sections',
    icon: Icons.horizontal_rule_rounded,
    category: 'Layout',
  ),
  InsertPickerEntry(
    id: 'code',
    label: 'Code',
    description: 'Monospaced, with syntax colours',
    icon: Icons.code_rounded,
    category: 'Layout',
  ),
];
