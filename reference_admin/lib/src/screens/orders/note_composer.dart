import 'package:admin_ui/comments.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/orders_keys.dart';
import '../../l10n/ref_strings.dart';

/// A note's text with its mentions in the primary colour, as the notes
/// list and the activity show it. [nameOf] resolves a mention's teammate.
class NoteText extends StatelessWidget {
  final String text;
  final String Function(String id) nameOf;
  final TextStyle? style;

  const NoteText(this.text, {super.key, required this.nameOf, this.style});

  @override
  Widget build(BuildContext context) =>
      MentionText(text, nameOf: nameOf, style: style);
}

/// Where a note is written: a text box that offers the active team's names
/// as soon as an `@` is typed, and the button that sends the note with each
/// mention as its durable token, so the mentioned teammate is notified.
class NoteComposer extends StatefulWidget {
  final List<StaffMember> team;

  /// Sends the note, in mention-token form; the box clears once it lands.
  final Future<void> Function(String text) onSubmit;

  const NoteComposer({super.key, required this.team, required this.onSubmit});

  @override
  State<NoteComposer> createState() => _NoteComposerState();
}

class _NoteComposerState extends State<NoteComposer> {
  final _text = TextEditingController();
  late var _candidates = _candidatesOf(widget.team);
  var _sending = false;

  static List<MentionCandidate> _candidatesOf(List<StaffMember> team) => [
    for (final s in team)
      if (s.status == StaffStatus.active)
        MentionCandidate(id: s.id, name: s.name),
  ];

  @override
  void didUpdateWidget(NoteComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.team != oldWidget.team) _candidates = _candidatesOf(widget.team);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(String note) async {
    if (note.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSubmit(note);
      _text.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.orders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MentionField(
          key: OrdersKeys.noteField,
          controller: _text,
          candidates: _candidates,
          label: strings.noteLabel,
          hint: strings.noteHint,
          minLines: 2,
          maxLines: 5,
          onSubmit: _send,
        ),
        const Gap(AdminSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ListenableBuilder(
            listenable: _text,
            builder: (context, _) => Button(
              strings.addNote,
              key: OrdersKeys.addNote,
              icon: Icons.send_outlined,
              loading: _sending,
              onPressed: _text.text.trim().isEmpty
                  ? null
                  : () =>
                        _send(tokenizeMentions(_text.text.trim(), _candidates)),
            ),
          ),
        ),
      ],
    );
  }
}
