// The sample under "Comments and mentions" in README.md, verbatim below the
// imports. docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

class NoteBox extends StatefulWidget {
  final List<MentionCandidate> team;
  final String Function(String id) nameOf;
  final ValueChanged<String> onSend;

  const NoteBox({
    super.key,
    required this.team,
    required this.nameOf,
    required this.onSend,
  });

  @override
  State<NoteBox> createState() => _NoteBoxState();
}

class _NoteBoxState extends State<NoteBox> {
  final _text = TextEditingController();
  final _sent = <String>[];

  void _send(String body) {
    // body holds tokens: 'Can you check, <@u2>?'
    widget.onSend(body);
    setState(() => _sent.add(body));
    _text.clear();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final body in _sent) MentionText(body, nameOf: widget.nameOf),
      MentionField(
        controller: _text,
        candidates: widget.team,
        label: 'Note',
        minLines: 2,
        maxLines: 5,
        onSubmit: _send,
      ),
    ],
  );
}
