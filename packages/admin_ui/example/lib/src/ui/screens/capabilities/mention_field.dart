import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

const _team = [
  MentionCandidate(id: 'u1', name: 'Alice Martin'),
  MentionCandidate(id: 'u2', name: 'Alan Reyes'),
  MentionCandidate(id: 'u3', name: 'Bea Stone'),
  MentionCandidate(id: 'u4', name: 'Carlos Diaz'),
  MentionCandidate(id: 'u5', name: 'Dana Whitfield'),
];

const _teamAr = [
  MentionCandidate(id: 'a1', name: 'سارة خالد'),
  MentionCandidate(id: 'a2', name: 'سامي نور'),
  MentionCandidate(id: 'a3', name: 'ليلى حسن'),
];

String _nameOf(String id) =>
    [..._team, ..._teamAr].where((c) => c.id == id).firstOrNull?.name ??
    'Someone';

/// A note composer: the field, a send button, and the notes sent so far
/// drawn with their mentions.
class MentionFieldDemo extends StatefulWidget {
  @Preview(name: 'Mention field', wrapper: adminUiPreview)
  const MentionFieldDemo({super.key});

  @override
  State<MentionFieldDemo> createState() => _MentionFieldDemoState();
}

class _MentionFieldDemoState extends State<MentionFieldDemo> {
  final _text = TextEditingController();
  final _notes = <String>[
    'Moved the launch to Friday. <@u3>, <@u1>: can you check the copy?',
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send(String body) {
    setState(() => _notes.insert(0, body));
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Type @ to mention someone; Ctrl+Enter sends'),
        MentionField(
          controller: _text,
          candidates: _team,
          label: 'Note',
          hint: 'Only the team sees notes',
          minLines: 2,
          maxLines: 5,
          onSubmit: _send,
        ),
        const Gap(AdminSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ListenableBuilder(
            listenable: _text,
            builder: (context, _) => Button(
              'Add note',
              icon: Icons.send_outlined,
              onPressed: _text.text.trim().isEmpty
                  ? null
                  : () => _send(tokenizeMentions(_text.text.trim(), _team)),
            ),
          ),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoSection('Sent, as MentionText draws them'),
        for (final note in _notes)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.md),
            child: MentionText(note, nameOf: _nameOf),
          ),
      ],
    );
  }
}

/// The suggestions open over a field holding `@al`, the caret at its end:
/// in English, and [MentionFieldOpenDemo.arabic] in an Arabic admin, where
/// the list lines up on the right.
class MentionFieldOpenDemo extends StatefulWidget {
  final bool arabic;

  @Preview(name: 'Mention field / suggestions open', wrapper: adminUiPreview)
  const MentionFieldOpenDemo({super.key}) : arabic = false;

  @Preview(
    name: 'Mention field / suggestions open (ar)',
    wrapper: adminUiPreview,
  )
  const MentionFieldOpenDemo.arabic({super.key}) : arabic = true;

  @override
  State<MentionFieldOpenDemo> createState() => _MentionFieldOpenDemoState();
}

class _MentionFieldOpenDemoState extends State<MentionFieldOpenDemo> {
  late final _text = TextEditingController.fromValue(
    TextEditingValue(
      text: _query,
      selection: TextSelection.collapsed(offset: _query.length),
    ),
  );

  String get _query => widget.arabic ? '@سا' : '@al';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = DemoPage(
      maxWidth: 520,
      children: [
        DemoSection(widget.arabic ? 'ملاحظة' : 'Suggestions for "@al"'),
        MentionField(
          controller: _text,
          candidates: widget.arabic ? _teamAr : _team,
          hint: widget.arabic ? 'اكتب @ للإشارة إلى أحد' : 'Add a note',
          minLines: 2,
          maxLines: 5,
          autofocus: true,
          onSubmit: (_) {},
        ),
        // The list floats over what follows.
        const SizedBox(height: 240),
      ],
    );
    if (!widget.arabic) return page;
    return Localizations.override(
      context: context,
      locale: const Locale('ar'),
      child: page,
    );
  }
}
