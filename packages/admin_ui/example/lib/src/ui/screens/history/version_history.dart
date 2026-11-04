import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';
import 'mock_diff.dart';

/// Full-screen surface: the version rail beside the diff panel. Tapping a
/// version sets the BEFORE endpoint; the draft stays the AFTER side.
class VersionHistoryDemo extends StatefulWidget {
  @Preview(name: 'Version diff (full screen)', wrapper: adminUiPreview)
  const VersionHistoryDemo({super.key});

  @override
  State<VersionHistoryDemo> createState() => _VersionHistoryDemoState();
}

class _VersionHistoryDemoState extends State<VersionHistoryDemo> {
  String _baseId = 'v4';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 312,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.background,
                border: Border(
                  right: BorderSide(color: context.colors.borderSubtle),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AdminSpacing.xl,
                      AdminSpacing.xl,
                      AdminSpacing.xl,
                      AdminSpacing.md,
                    ),
                    child: Text('Version history', style: context.type.heading),
                  ),
                  Expanded(
                    child: VersionTimeline(
                      versions: versions,
                      baseId: _baseId,
                      compareId: draftRef.id,
                      onTap: (v) {
                        if (v.id != draftRef.id) setState(() => _baseId = v.id);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DiffView(
              diff: diffAgainst(_baseId),
              onRestore: () => _restore(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final base = versionById(_baseId);
    final ok = await showConfirmDialog(
      context,
      title: 'Restore this version?',
      message:
          'The working draft will be rewound to “${base.label}”. '
          'Collaborators see the change live.',
      confirmLabel: 'Restore',
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored “${base.label}” (demo)')),
      );
    }
  }
}

/// In-editor surface: the same diff panel inside a side sheet over a stand-in
/// editor, shown open here; the button opens the real modal sheet.
class DiffSheetDemo extends StatelessWidget {
  @Preview(name: 'Diff in side sheet', wrapper: adminUiPreview)
  const DiffSheetDemo({super.key});

  static const _sheetWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 1180,
      children: [
        const DemoSection('Diff in a side sheet'),
        Text(
          'The diff panel is surface-agnostic: full-screen beside the rail, or '
          'slid in over the editor. At sheet width it tightens its inset, '
          'folds Restore into an icon and wraps the endpoints.',
          style: context.type.bodyMuted,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Button.primary(
            'Open version history',
            icon: Icons.history_rounded,
            onPressed: () => _open(context),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final sheetWidth = constraints.maxWidth < _sheetWidth
                ? constraints.maxWidth
                : _sheetWidth;
            final editor = constraints.maxWidth - sheetWidth >= 240;
            return SizedBox(
              height: 680,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.background,
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (editor) const Expanded(child: _StandInEditor()),
                    SizedBox(
                      width: sheetWidth,
                      child: SideSheet(
                        title: 'Version history',
                        onDismiss: () {},
                        child: DiffView(
                          diff: diffAgainst('v4'),
                          onRestore: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _open(BuildContext context) {
    showSideSheet(
      context,
      width: _sheetWidth,
      builder: (context) => SideSheet(
        title: 'Version history',
        child: DiffView(
          diff: diffAgainst('v4'),
          onRestore: () {
            Navigator.of(context).maybePop();
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Restored (demo)')));
          },
        ),
      ),
    );
  }
}

/// The page being edited, under the sheet.
class _StandInEditor extends StatelessWidget {
  const _StandInEditor();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget line(double widthFactor) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: 8,
        margin: const EdgeInsets.only(bottom: AdminSpacing.md),
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Home page', style: context.type.heading),
          const SizedBox(height: AdminSpacing.xl),
          line(0.9),
          line(0.75),
          line(0.82),
          const SizedBox(height: AdminSpacing.lg),
          line(0.6),
          line(0.7),
        ],
      ),
    );
  }
}
