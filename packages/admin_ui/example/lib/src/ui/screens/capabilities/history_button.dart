import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

const _versions = [
  FieldVersion(
    label: 'Editing now',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'live',
    current: true,
  ),
  FieldVersion(
    label: 'Reworded headline',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: '1 hr ago',
  ),
  FieldVersion(
    label: 'Published v3',
    author: 'Marina Cole',
    initials: 'MC',
    color: Color(0xFF9333a8),
    time: 'Yesterday',
  ),
  FieldVersion(
    label: 'Created from outline',
    author: 'Marina Cole',
    initials: 'MC',
    color: Color(0xFF9333a8),
    time: '3 days ago',
  ),
];

class HistoryDemo extends StatelessWidget {
  @Preview(name: 'History / draft', wrapper: adminUiPreview)
  const HistoryDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      children: const [
        DemoVariant(
          'Open — compare, revert and the version list',
          PinnedOpen(
            makeRoom: true,
            child: Align(
              alignment: Alignment.centerRight,
              child: HistoryButton(
                draft: 'A coast that marks its own time',
                baseline: 'A coast that keeps its own time',
                versions: _versions,
                onRevert: _noop,
              ),
            ),
          ),
        ),
        DemoRow(
          'Clean — draft matches published (quiet icon)',
          HistoryButton(
            draft: 'A coast that keeps its own time',
            baseline: 'A coast that keeps its own time',
            versions: _versions,
          ),
        ),
        DemoRow(
          'Never published (quiet icon, no override)',
          HistoryButton(draft: 'A new field', versions: _versions),
        ),
        DemoRow('Modified — compare + revert', _LiveHistory()),
      ],
    );
  }
}

class _LiveHistory extends StatefulWidget {
  const _LiveHistory();

  @override
  State<_LiveHistory> createState() => _LiveHistoryState();
}

class _LiveHistoryState extends State<_LiveHistory> {
  static const _published = 'A coast that keeps its own time';
  String _draft = 'A coast that marks its own time';

  @override
  Widget build(BuildContext context) {
    return HistoryButton(
      draft: _draft,
      baseline: _published,
      versions: _versions,
      onRevert: () => setState(() => _draft = _published),
    );
  }
}

void _noop() {}
