import 'package:admin_ui/src/common/fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty query matches everything with neutral score', () {
    final m = fuzzyMatch('', 'anything');
    expect(m, isNotNull);
    expect(m!.matched, isEmpty);
  });

  test('returns null when not all chars are present in order', () {
    expect(fuzzyMatch('zzz', 'New page'), isNull);
    expect(fuzzyMatch('gpa', 'page'), isNull); // wrong order
  });

  test('reports matched indexes for highlighting', () {
    final m = fuzzyMatch('np', 'New page')!;
    expect('New page'[m.matched[0]].toLowerCase(), 'n');
    expect('New page'[m.matched[1]].toLowerCase(), 'p');
  });

  test('word-boundary subsequence scores above a mid-word one', () {
    final boundary = fuzzyMatch('np', 'New page')!; // N…p (both word starts)
    final midword = fuzzyMatch('np', 'Open profile')!;
    expect(boundary.score, greaterThan(midword.score));
  });

  test('exact prefix beats a scattered match', () {
    final prefix = fuzzyMatch('pa', 'page')!;
    final scattered = fuzzyMatch('pa', 'previous area')!;
    expect(prefix.score, greaterThan(scattered.score));
  });

  test('consecutive run scores above a gapped match', () {
    final consec = fuzzyMatch('page', 'page')!;
    final gapped = fuzzyMatch('page', 'p a g e split')!;
    expect(consec.score, greaterThan(gapped.score));
  });
}
