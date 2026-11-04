import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

const _two = [
  CommentEntry(
    author: 'Lena Fritz',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '14m',
    body: 'Love this headline — keep the rhythm in ES.',
  ),
  CommentEntry(
    author: 'Diego Ruiz',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '6m',
    body: 'Agreed. Flagged so MT won’t take it literally.',
  ),
];

class CommentsDemo extends StatelessWidget {
  @Preview(name: 'Comments (field button)', wrapper: adminUiPreview)
  const CommentsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      children: [
        const DemoSection('Open — anchor, messages, reply and resolve'),
        const PinnedOpen(
          makeRoom: true,
          child: DemoRow('Thread', _LiveComments()),
        ),
        const SizedBox(height: 12),
        const DemoSection(
          'Field affordance (sidebar-primary) — every field/lane shows this; '
          'tapping opens the comments sidebar anchored there.',
        ),
        DemoRow(
          'No threads (quiet, hover to reveal intent)',
          CommentFieldButton(count: 0, onTap: () {}),
        ),
        DemoRow(
          'Open threads (badged)',
          CommentFieldButton(count: 3, onTap: () {}),
        ),
        DemoRow('Overflow count', CommentFieldButton(count: 120, onTap: () {})),
        const SizedBox(height: 12),
        const DemoSection('Legacy popover thread (superseded by the sidebar)'),
        const DemoRow('No comments (icon only)', CommentsButton(count: 0)),
        const DemoRow(
          'With anchor + count',
          CommentsButton(
            count: 2,
            messages: _two,
            anchor: 'its own time',
            onResolve: _noop,
          ),
        ),
        const DemoRow(
          'No anchor',
          CommentsButton(count: 2, messages: _two, onResolve: _noop),
        ),
        const DemoRow(
          'Overflow count',
          CommentsButton(
            count: 142,
            messages: _two,
            anchor: 'rhythm',
            onResolve: _noop,
          ),
        ),
        const DemoRow(
          'Interactive — reply appends, resolve clears',
          _LiveComments(),
        ),
      ],
    );
  }
}

class _LiveComments extends StatefulWidget {
  const _LiveComments();

  @override
  State<_LiveComments> createState() => _LiveCommentsState();
}

class _LiveCommentsState extends State<_LiveComments> {
  final _messages = [..._two];

  @override
  Widget build(BuildContext context) {
    return CommentsButton(
      count: _messages.length,
      messages: _messages,
      anchor: 'its own time',
      onReply: (text) => setState(() => _messages.add(youReply(text))),
      onResolve: () => setState(_messages.clear),
    );
  }
}

void _noop() {}
