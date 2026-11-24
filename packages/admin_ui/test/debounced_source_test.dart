import 'dart:async';

import 'package:admin_ui/src/common/ui/command_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A source that costs a request is asked once the typing pauses.

const _pause = Duration(milliseconds: 200);
const _short = Duration(milliseconds: 199);
const _tick = Duration(milliseconds: 1);

PaletteItem _item(String title, [String group = 'Plants']) => PaletteItem(
  id: title,
  title: title,
  icon: Icons.circle_outlined,
  group: group,
  onSelect: () {},
);

List<PaletteSection> _hits(String query) => [
  PaletteSection('Plants', [ScoredItem(_item('$query, found'), const [], 0)]),
];

/// Answers at once, and remembers what it was asked.
class _Local implements SearchSource {
  final asked = <String>[];

  @override
  List<PaletteSection> search(String query) {
    asked.add(query);
    return query.trim().isEmpty ? const [] : _hits(query);
  }
}

/// Answers when its test says so, as a request does.
class _Remote implements SearchSource {
  final asked = <String>[];
  final answers = <Completer<List<PaletteSection>>>[];

  @override
  Future<List<PaletteSection>> search(String query) {
    asked.add(query);
    answers.add(Completer());
    return answers.last.future;
  }
}

class _Broken implements SearchSource {
  final bool later;
  _Broken({required this.later});

  @override
  FutureOr<List<PaletteSection>> search(String query) =>
      later ? Future.error(StateError('offline')) : throw StateError('offline');
}

/// What a search answered: null while it has not, the error when it failed.
class _Answer {
  List<PaletteSection>? sections;
  Object? error;

  _Answer(FutureOr<List<PaletteSection>> search) {
    Future.value(search).then<void>(
      (s) {
        sections = s;
      },
      onError: (Object e) {
        error = e;
      },
    );
  }

  List<String>? get titles => sections == null
      ? null
      : [
          for (final s in sections!)
            for (final e in s.entries) e.item.title,
        ];
}

void main() {
  group('a debounced source', () {
    testWidgets('asks its source once the pause has passed, and not before', (
      tester,
    ) async {
      final inner = _Local();
      final answer = _Answer(DebouncedSource(inner).search('fern'));
      await tester.pump(_short);
      expect(inner.asked, isEmpty);
      expect(answer.sections, isNull, reason: 'a search in progress');

      await tester.pump(_tick);
      expect(inner.asked, ['fern']);
      expect(answer.titles, ['fern, found']);
    });

    testWidgets('asks about the last of the queries typed within a pause', (
      tester,
    ) async {
      final inner = _Local();
      final source = DebouncedSource(inner);
      final answers = <_Answer>[];
      for (final query in ['f', 'fe', 'fer', 'fern']) {
        answers.add(_Answer(source.search(query)));
        await tester.pump(_short);
      }
      expect(inner.asked, isEmpty, reason: 'each keystroke starts the pause');

      await tester.pump(_tick);
      expect(inner.asked, ['fern']);
      expect(answers.last.titles, ['fern, found']);
    });

    testWidgets('answers an overtaken search with nothing, at once', (
      tester,
    ) async {
      final source = DebouncedSource(_Local());
      final first = _Answer(source.search('f'));
      await tester.pump(_tick);
      expect(first.sections, isNull);

      final second = _Answer(source.search('fe'));
      await tester.pump();
      expect(first.sections, isEmpty);
      expect(second.sections, isNull);
      await tester.pump(_pause);
      expect(first.sections, isEmpty, reason: 'and nothing later');
      expect(second.titles, ['fe, found']);
    });

    testWidgets('asks again about each query that had its pause', (
      tester,
    ) async {
      final inner = _Local();
      final source = DebouncedSource(inner);
      source.search('fern');
      await tester.pump(_pause);
      source.search('moss');
      await tester.pump(_pause);
      source.search('fern');
      await tester.pump(_pause);
      expect(inner.asked, ['fern', 'moss', 'fern']);
    });

    testWidgets("answers with a request's answer, when it comes", (
      tester,
    ) async {
      final inner = _Remote();
      final answer = _Answer(DebouncedSource(inner).search('fern'));
      await tester.pump(_pause);
      expect(inner.asked, ['fern']);
      expect(answer.sections, isNull, reason: 'the request is out');

      final hits = _hits('fern');
      inner.answers.single.complete(hits);
      await tester.pump();
      expect(answer.sections, same(hits));
    });

    testWidgets('hands an empty query over as it comes', (tester) async {
      final inner = _Local();
      final source = DebouncedSource(inner);
      final empty = source.search('');
      expect(empty, isA<List<PaletteSection>>(), reason: 'no wait, no future');
      expect(empty, isEmpty);
      expect(source.search('   '), isEmpty);
      expect(inner.asked, ['', '   ']);
      await tester.pump(_pause);
      expect(inner.asked, ['', '   ']);
    });

    testWidgets('drops the query it was waiting on when the box is emptied', (
      tester,
    ) async {
      final inner = _Local();
      final source = DebouncedSource(inner);
      final typed = _Answer(source.search('fern'));
      await tester.pump(_tick);
      source.search('');
      await tester.pump(_pause);
      expect(inner.asked, [''], reason: '"fern" was taken back');
      expect(typed.sections, isEmpty);
    });

    testWidgets('waits as long as it is told', (tester) async {
      final inner = _Local();
      DebouncedSource(
        inner,
        debounce: const Duration(milliseconds: 500),
      ).search('fern');
      await tester.pump(const Duration(milliseconds: 499));
      expect(inner.asked, isEmpty);
      await tester.pump(_tick);
      expect(inner.asked, ['fern']);
    });

    testWidgets('told not to wait hands each query over as it comes', (
      tester,
    ) async {
      final inner = _Local();
      final source = DebouncedSource(inner, debounce: Duration.zero);
      expect(source.search('f'), isA<List<PaletteSection>>());
      source.search('fe');
      expect(inner.asked, ['f', 'fe']);
      await tester.pump(_pause);
      expect(inner.asked, ['f', 'fe']);
    });

    test('waits 200ms unless told', () {
      expect(DebouncedSource(_Local()).debounce, _pause);
    });

    testWidgets("fails as its source does, at once or later", (tester) async {
      for (final later in [false, true]) {
        final answer = _Answer(
          DebouncedSource(_Broken(later: later)).search('fern'),
        );
        await tester.pump(_pause);
        await tester.pump();
        expect(answer.error, isStateError, reason: 'later: $later');
        expect(answer.sections, isNull);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancelled, does not ask and answers with nothing', (
      tester,
    ) async {
      final inner = _Local();
      final source = DebouncedSource(inner);
      final answer = _Answer(source.search('fern'));
      await tester.pump(_tick);
      source.cancel();
      await tester.pump();
      expect(answer.sections, isEmpty);
      await tester.pump(_pause);
      expect(inner.asked, isEmpty);

      // With nothing waiting, cancelling changes nothing.
      source.cancel();
      final next = _Answer(source.search('moss'));
      await tester.pump(_pause);
      source.cancel();
      expect(next.titles, ['moss, found']);
      expect(inner.asked, ['moss']);
    });
  });

  group('a palette over a debounced source', () {
    testWidgets('asks once for a word typed letter by letter', (tester) async {
      final inner = _Remote();
      final palette = CommandPaletteController(
        sources: [DebouncedSource(inner)],
      );
      addTearDown(palette.dispose);
      expect(inner.asked, [''], reason: 'opened on an empty query');
      inner.answers.single.complete(const []);
      await tester.pump();
      expect(palette.loading, isFalse);

      for (final query in ['f', 'fe', 'fer', 'fern']) {
        palette.setQuery(query);
        await tester.pump(const Duration(milliseconds: 60));
        expect(palette.loading, isTrue, reason: 'from the first keystroke');
      }
      expect(inner.asked, ['']);

      await tester.pump(_pause);
      expect(inner.asked, ['', 'fern']);
      expect(palette.loading, isTrue, reason: 'the request is out');

      inner.answers.last.complete(_hits('fern'));
      await tester.pump();
      expect(palette.loading, isFalse);
      expect(palette.sections.single.entries.single.item.title, 'fern, found');
    });

    testWidgets('shows what its other sources find without the wait', (
      tester,
    ) async {
      final palette = CommandPaletteController(
        sources: [
          CommandSource(() => [_item('Ferns', 'Pages')]),
          DebouncedSource(_Local()),
        ],
      );
      addTearDown(palette.dispose);
      palette.setQuery('fern');
      expect(palette.sections.single.title, 'Pages');
      expect(palette.loading, isTrue);

      await tester.pump(_pause);
      expect(palette.sections.map((s) => s.title), ['Pages', 'Plants']);
      expect(palette.loading, isFalse);
    });

    testWidgets('emptied, clears at once and asks nothing more', (
      tester,
    ) async {
      final inner = _Local();
      final palette = CommandPaletteController(
        sources: [DebouncedSource(inner)],
      );
      addTearDown(palette.dispose);
      palette.setQuery('fern');
      await tester.pump(_pause);
      expect(palette.sections, isNotEmpty);

      palette.setQuery('fer');
      palette.setQuery('');
      expect(palette.sections, isEmpty);
      expect(palette.loading, isFalse);
      await tester.pump(_pause);
      expect(inner.asked, ['', 'fern', '']);
    });

    testWidgets('closed during the pause asks nothing', (tester) async {
      final inner = _Local();
      final palette = CommandPaletteController(
        sources: [DebouncedSource(inner)],
      );
      var notified = 0;
      palette
        ..addListener(() => notified++)
        ..setQuery('fern');
      await tester.pump(_tick);
      final before = notified;

      palette.dispose();
      await tester.pump(_pause);
      expect(inner.asked, [''], reason: 'only the query it opened on');
      expect(notified, before);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closed during the pause leaves no timer behind', (
      tester,
    ) async {
      final palette = CommandPaletteController(
        sources: [DebouncedSource(_Local())],
      );
      palette.setQuery('fern');
      await tester.pump(_tick);
      palette.dispose();
      // The test fails on a timer still pending when it ends.
    });

    testWidgets('closed while the request is out drops its answer', (
      tester,
    ) async {
      final inner = _Remote();
      final palette = CommandPaletteController(
        sources: [DebouncedSource(inner)],
      );
      palette.setQuery('fern');
      await tester.pump(_pause);
      expect(inner.asked, ['', 'fern']);

      palette.dispose();
      for (final answer in inner.answers) {
        answer.complete(_hits('fern'));
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a palette closed while a source of its own is asked drops the '
      'answer, and its failure', (tester) async {
    for (final fails in [false, true]) {
      final remote = _Remote();
      final palette = CommandPaletteController(sources: [remote]);
      palette.setQuery('fern');
      palette.dispose();
      for (final answer in remote.answers) {
        fails
            ? answer.completeError(StateError('offline'))
            : answer.complete(_hits('fern'));
      }
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'fails: $fails');
    }
  });
}
