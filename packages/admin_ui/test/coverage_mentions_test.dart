import 'package:admin_ui/comments.dart';
import 'package:flutter_test/flutter_test.dart';

const _lena = MentionCandidate(id: '2', name: 'Lena Fritz');
const _anna = MentionCandidate(id: '3', name: 'Anna');
const _annaLee = MentionCandidate(id: '4', name: 'Anna Lee');
const _qa = MentionCandidate(id: '5', name: r'J.R. (QA) $1+');

/// Shorter names first, so a test proves the longest-first order is the
/// function's and not the list's.
const _candidates = [_anna, _lena, _annaLee, _qa];

String _nameOf(String id) =>
    _candidates.where((c) => c.id == id).firstOrNull?.name ?? 'User #$id';

void main() {
  group('tokenizeMentions', () {
    test('the longest name wins, so "@Anna Lee" is never "@Anna" + " Lee"', () {
      expect(
        tokenizeMentions('ask @Anna Lee, then @Anna', _candidates),
        'ask <@4>, then <@3>',
      );
    });

    test('replaces every occurrence of a name', () {
      expect(
        tokenizeMentions(
          '@Lena Fritz, @Anna and @Lena Fritz again\n@Lena Fritz',
          _candidates,
        ),
        '<@2>, <@3> and <@2> again\n<@2>',
      );
    });

    test('matches names literally, not as patterns', () {
      expect(
        tokenizeMentions(r'cc @J.R. (QA) $1+ and @JxRx (QA) $1+', _candidates),
        r'cc <@5> and @JxRx (QA) $1+',
      );
    });

    test('leaves an @ that names no candidate alone', () {
      const body = 'hi @nobody, mail anna@example.com or @';
      expect(tokenizeMentions(body, _candidates), body);
      expect(tokenizeMentions('ping @Anna', const []), 'ping @Anna');
    });

    test('a name that runs on into a longer word is not a mention', () {
      expect(tokenizeMentions('cc @Annabel', _candidates), 'cc @Annabel');
      expect(
        tokenizeMentions('cc @Anna_b @Anna2', _candidates),
        'cc @Anna_b @Anna2',
      );
      expect(
        tokenizeMentions('cc @Anna, @Anna. @Anna!', _candidates),
        'cc <@3>, <@3>. <@3>!',
      );
    });

    test('an @ inside a word is not a mention, as in mentionQueryAt', () {
      expect(tokenizeMentions('x@Anna', _candidates), 'x@Anna');
      expect(tokenizeMentions('(@Anna)', _candidates), '(@Anna)');
      expect(
        tokenizeMentions('hi\n@Anna\t@Anna', _candidates),
        'hi\n<@3>\t<@3>',
      );
    });

    test('skips a candidate with an empty name', () {
      expect(
        tokenizeMentions('a lone @ sign', const [
          MentionCandidate(id: '9', name: ''),
        ]),
        'a lone @ sign',
      );
    });
  });

  group('detokenizeMentions', () {
    test('restores the @Name form, resolving each id through nameOf', () {
      final asked = <String>[];
      String nameOf(String id) {
        asked.add(id);
        return _nameOf(id);
      }

      expect(
        detokenizeMentions('ping <@2> and <@9>, <@2>', nameOf),
        'ping @Lena Fritz and @User #9, @Lena Fritz',
      );
      expect(asked, ['2', '9', '2']);
    });

    test('leaves text that is not a token alone', () {
      const body = 'a <@> b <@ 2> c <@2 d <2> e @2';
      expect(
        detokenizeMentions(body, (id) => fail('nameOf($id) was called')),
        body,
      );
    });

    test('round-trips with tokenizeMentions', () {
      for (final body in [
        'ask @Anna Lee about the FR copy',
        '@Lena Fritz@Anna',
        r'cc @J.R. (QA) $1+, @Anna and @Anna Lee'
            '\n@Lena Fritz',
        'no mentions at all',
        '',
      ]) {
        final stored = tokenizeMentions(body, _candidates);
        expect(detokenizeMentions(stored, _nameOf), body, reason: body);
        expect(tokenizeMentions(body, _candidates), stored, reason: body);
      }
    });
  });

  group('mentionRuns', () {
    List<(String?, String)> runs(String body) => [
      for (final r in mentionRuns(body, _nameOf)) (r.mentionId, r.text),
    ];

    test('alternates text and mention runs', () {
      expect(runs('hi <@2>, see <@3>.'), [
        (null, 'hi '),
        ('2', '@Lena Fritz'),
        (null, ', see '),
        ('3', '@Anna'),
        (null, '.'),
      ]);
    });

    test('adjacent tokens, and tokens at either end, leave no empty run', () {
      expect(runs('<@2><@3>'), [('2', '@Lena Fritz'), ('3', '@Anna')]);
      expect(runs('<@4> and <@9>'), [
        ('4', '@Anna Lee'),
        (null, ' and '),
        ('9', '@User #9'),
      ]);
    });

    test('a body with no tokens is one text run, an empty body none', () {
      expect(runs('plain text, @Anna'), [(null, 'plain text, @Anna')]);
      expect(runs(''), isEmpty);
    });

    test('the runs spell out the detokenized body', () {
      const body = 'x<@2> <@5>\n<@4><@4>y';
      expect(
        mentionRuns(body, _nameOf).map((r) => r.text).join(),
        detokenizeMentions(body, _nameOf),
      );
    });
  });

  group('mentionQueryAt', () {
    test('an @ at the start of the text', () {
      expect(mentionQueryAt('@', 1), (start: 0, query: ''));
      expect(mentionQueryAt('@le', 3), (start: 0, query: 'le'));
    });

    test('an @ after whitespace, the query running up to the caret', () {
      expect(mentionQueryAt('hi @le', 6), (start: 3, query: 'le'));
      expect(mentionQueryAt('hi @lena', 6), (start: 3, query: 'le'));
      expect(mentionQueryAt('line\n@le', 8), (start: 5, query: 'le'));
      expect(mentionQueryAt('a\t@', 3), (start: 2, query: ''));
      // Names have spaces, so the query may too.
      expect(mentionQueryAt('hi @Lena Fr', 11), (start: 3, query: 'Lena Fr'));
    });

    test('the @ nearest the caret wins', () {
      expect(mentionQueryAt('@a @b', 5), (start: 3, query: 'b'));
    });

    test('not an @ inside a word, like an email address', () {
      expect(mentionQueryAt('mail@ex', 7), isNull);
      expect(mentionQueryAt('v2@x', 4), isNull);
      expect(mentionQueryAt('@a b@c', 6), isNull);
    });

    test('not across a line break', () {
      expect(mentionQueryAt('@le\nnext', 8), isNull);
      expect(mentionQueryAt('@le\nnext', 3), (start: 0, query: 'le'));
    });

    test('not with the caret before the @, or outside the text', () {
      expect(mentionQueryAt('hi @le', 3), isNull);
      expect(mentionQueryAt('hi', 2), isNull);
      expect(mentionQueryAt('@le', 0), isNull);
      expect(mentionQueryAt('@le', -1), isNull);
      expect(mentionQueryAt('@le', 4), isNull);
      expect(mentionQueryAt('', 0), isNull);
    });
  });

  group('matchMentionCandidates', () {
    test('a case-insensitive substring of the name, in candidate order', () {
      expect(matchMentionCandidates(_candidates, 'an'), [_anna, _annaLee]);
      expect(matchMentionCandidates(_candidates, 'LEE'), [_annaLee]);
      expect(matchMentionCandidates(_candidates, 'itz'), [_lena]);
      expect(matchMentionCandidates(_candidates, '(qa)'), [_qa]);
      expect(matchMentionCandidates(_candidates, 'zoe'), isEmpty);
    });

    test('the empty query matches everyone', () {
      expect(matchMentionCandidates(_candidates, ''), _candidates);
      expect(matchMentionCandidates(const [], ''), isEmpty);
    });
  });
}
