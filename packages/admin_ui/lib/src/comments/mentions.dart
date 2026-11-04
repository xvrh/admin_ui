/// @-mentions in comment bodies.
///
/// Stored form is a durable token — `<@userId>` — so display names resolve
/// live at render time (a renamed user updates everywhere). The composer is a
/// plain text field: the picker inserts the human form (`@Lena Fritz`), and
/// the body is tokenized on submit / detokenized for editing.
library;

/// One mentionable user, from the entity's author directory.
class MentionCandidate {
  final String id;
  final String name;

  const MentionCandidate({required this.id, required this.name});
}

String mentionToken(String id) => '<@$id>';

final _tokenPattern = RegExp(r'<@([^>\s]+)>');

/// Replaces `@Name` occurrences with their durable `<@id>` token. Longer
/// names match first so `@Anna Lee` never half-matches a candidate `@Anna`.
///
/// A mention starts where [mentionQueryAt] would open one (at the start or
/// after whitespace) and ends where the name does: `@Annabel` and `x@Anna`
/// are not mentions of Anna.
String tokenizeMentions(String body, List<MentionCandidate> candidates) {
  var out = body;
  var sorted = [...candidates]
    ..sort((a, b) => b.name.length.compareTo(a.name.length));
  for (var c in sorted) {
    if (c.name.isEmpty) continue;
    var pattern = RegExp(
      '(?<=^|\\s)@${RegExp.escape(c.name)}(?![\\p{L}\\p{N}_])',
      unicode: true,
    );
    out = out.replaceAll(pattern, mentionToken(c.id));
  }
  return out;
}

/// Replaces `<@id>` tokens with their `@Name` human form, for editing.
String detokenizeMentions(String body, String Function(String id) nameOf) =>
    body.replaceAllMapped(_tokenPattern, (m) => '@${nameOf(m[1]!)}');

/// One run of a comment body: plain [text], or a mention of [mentionId].
class MentionRun {
  final String text;
  final String? mentionId;

  const MentionRun.text(this.text) : mentionId = null;
  const MentionRun.mention(this.mentionId, this.text);
}

/// Splits a stored body into plain-text and mention runs for rendering.
List<MentionRun> mentionRuns(String body, String Function(String id) nameOf) {
  var runs = <MentionRun>[];
  var index = 0;
  for (var m in _tokenPattern.allMatches(body)) {
    if (m.start > index) {
      runs.add(MentionRun.text(body.substring(index, m.start)));
    }
    var id = m[1]!;
    runs.add(MentionRun.mention(id, '@${nameOf(id)}'));
    index = m.end;
  }
  if (index < body.length) runs.add(MentionRun.text(body.substring(index)));
  return runs;
}

/// The `@query` being typed at [caret] in [text], or null when the caret
/// isn't in a mention position. The query runs from the `@` (preceded by
/// start-of-text or whitespace) up to the caret, with no line break inside.
({int start, String query})? mentionQueryAt(String text, int caret) {
  if (caret <= 0 || caret > text.length) return null;
  var at = text.lastIndexOf('@', caret - 1);
  if (at < 0) return null;
  if (at > 0 && !RegExp(r'\s').hasMatch(text[at - 1])) return null;
  var query = text.substring(at + 1, caret);
  if (query.contains('\n')) return null;
  return (start: at, query: query);
}

/// Candidates matching [query] (case-insensitive substring on the name).
List<MentionCandidate> matchMentionCandidates(
  List<MentionCandidate> candidates,
  String query,
) {
  var q = query.toLowerCase();
  return [
    for (var c in candidates)
      if (c.name.toLowerCase().contains(q)) c,
  ];
}
