/// A successful fuzzy match: a [score] (higher is better) and the character
/// indexes in the target that the query matched, for highlighting.
class FuzzyMatch {
  final int score;
  final List<int> matched;

  const FuzzyMatch(this.score, this.matched);
}

bool _boundary(String ch) =>
    ch == ' ' || ch == '-' || ch == '_' || ch == '/' || ch == '.';

/// Case-insensitive subsequence fuzzy match of [query] against [text]. Returns
/// null when not every query character is found in order. Score rewards
/// consecutive runs, word-boundary starts, and early matches — so "np" ranks
/// "New page" above "Open profile". An empty query matches everything with a
/// neutral score (callers use this to show an unfiltered list).
FuzzyMatch? fuzzyMatch(String query, String text) {
  if (query.isEmpty) return const FuzzyMatch(0, []);
  final q = query.toLowerCase();
  final t = text.toLowerCase();

  final matched = <int>[];
  var qi = 0;
  var score = 0;
  var prev = -2;
  for (var i = 0; i < t.length && qi < q.length; i++) {
    if (t[i] != q[qi]) continue;
    var s = 1;
    if (i == prev + 1) s += 6; // consecutive
    if (i == 0 || _boundary(t[i - 1])) s += 10; // word start
    score += s;
    matched.add(i);
    prev = i;
    qi++;
  }
  if (qi < q.length) return null;

  // Earlier first match is better; full-prefix gets an extra nudge.
  score += (20 - matched.first).clamp(0, 20);
  if (t.startsWith(q)) score += 15;
  return FuzzyMatch(score, matched);
}
