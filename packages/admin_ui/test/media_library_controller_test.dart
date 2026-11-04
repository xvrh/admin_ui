// AssetLibraryController: the picker's paging state machine, public. A
// request counter drops answers to a search since replaced, an empty page
// ends the library, a failed first page is retried, and a failed next page
// keeps what is shown.

import 'dart:async';
import 'dart:typed_data';

import 'package:admin_ui/src/assets/asset_library_controller.dart';
import 'package:admin_ui/src/assets/asset_source.dart';
import 'package:admin_ui/src/assets/ui/asset_library.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Call = ({
  int index,
  int size,
  String? query,
  AssetType? filter,
  List<FilterCondition> where,
  Completer<AssetBrowseResult> answer,
});

/// Answers each browse only when the test completes it.
class _Source implements AssetSource {
  final calls = <_Call>[];

  _Call get last => calls.last;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) {
    final answer = Completer<AssetBrowseResult>();
    calls.add((
      index: index,
      size: size,
      query: query,
      filter: filter,
      where: where,
      answer: answer,
    ));
    return answer.future;
  }

  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async => null;

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

List<Asset> _page(int from, int count, [String prefix = 'a']) => [
  for (var i = from; i < from + count; i++)
    Asset(id: '$prefix$i', name: '$prefix$i.jpg'),
];

/// Lets an answer's continuation run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _Source source;
  late AssetLibraryController library;
  late int notified;

  setUp(() {
    source = _Source();
    library = AssetLibraryController(
      source: source,
      pageSize: 10,
      initialFilter: AssetType.image,
    )..addListener(() => notified++);
    notified = 0;
  });

  tearDown(() => library.dispose());

  test('loads the first page as it is made', () async {
    expect(library.loading, isTrue);
    expect(source.calls, hasLength(1));
    expect(source.last.index, 0);
    expect(source.last.size, 10);
    expect(source.last.query, '');
    expect(source.last.filter, AssetType.image);
    expect(source.last.where, isEmpty);

    source.last.answer.complete(AssetBrowseResult(_page(0, 10), 25));
    await _settle();
    expect(library.loading, isFalse);
    expect(library.assets.map((a) => a.id), [
      for (var i = 0; i < 10; i++) 'a$i',
    ]);
    expect(library.total, 25);
    expect(library.hasMore, isTrue);
    expect(notified, 1);
  });

  test('an answer to a search since replaced is dropped', () async {
    final first = source.last;
    library.query = 'harbour';
    final second = source.last;
    expect(second.query, 'harbour');

    second.answer.complete(AssetBrowseResult(_page(0, 2, 'h'), 2));
    await _settle();
    first.answer.complete(AssetBrowseResult(_page(0, 10), 25));
    await _settle();
    expect(library.assets.map((a) => a.id), ['h0', 'h1']);
    expect(library.total, 2);
    expect(library.loading, isFalse);

    // An error from the stale search is dropped too.
    library.query = 'dusk';
    final third = source.last;
    library.query = 'night';
    third.answer.completeError(StateError('late'));
    source.last.answer.complete(const AssetBrowseResult([], 0));
    await _settle();
    expect(library.error, isNull);
  });

  test('a next page asked before a new search is dropped', () async {
    source.last.answer.complete(AssetBrowseResult(_page(0, 10), 25));
    await _settle();
    library.loadMore();
    final more = source.last;
    expect(more.index, 10);
    expect(library.loadingMore, isTrue);

    library.filter = null;
    expect(library.loadingMore, isFalse);
    more.answer.complete(AssetBrowseResult(_page(10, 10), 25));
    source.last.answer.complete(AssetBrowseResult(_page(0, 3, 'b'), 3));
    await _settle();
    expect(library.assets.map((a) => a.id), ['b0', 'b1', 'b2']);
  });

  test('pages append, and an empty page ends the library', () async {
    source.last.answer.complete(AssetBrowseResult(_page(0, 10), 25));
    await _settle();
    library.loadMore();
    // One page at a time.
    library.loadMore();
    expect(source.calls, hasLength(2));
    source.last.answer.complete(AssetBrowseResult(_page(10, 10), 25));
    await _settle();
    expect(library.assets, hasLength(20));
    expect(library.hasMore, isTrue);

    // The source counted 25, but the library ends at 20.
    library.loadMore();
    expect(source.last.index, 20);
    source.last.answer.complete(const AssetBrowseResult([], 25));
    await _settle();
    expect(library.assets, hasLength(20));
    expect(library.total, 20);
    expect(library.hasMore, isFalse);

    library.loadMore();
    expect(source.calls, hasLength(3));
  });

  test('a failed first page is shown, and retry loads it again', () async {
    source.last.answer.completeError(StateError('offline'));
    await _settle();
    expect(library.loading, isFalse);
    expect(library.error, isA<StateError>());

    library.retry();
    expect(library.loading, isTrue);
    expect(library.error, isNull);
    expect(source.calls, hasLength(2));
    source.last.answer.complete(AssetBrowseResult(_page(0, 4), 4));
    await _settle();
    expect(library.error, isNull);
    expect(library.assets, hasLength(4));
  });

  test('a failed next page keeps what is shown', () async {
    source.last.answer.complete(AssetBrowseResult(_page(0, 10), 25));
    await _settle();
    library.loadMore();
    source.last.answer.completeError(StateError('offline'));
    await _settle();
    expect(library.loadMoreError, isA<StateError>());
    expect(library.error, isNull);
    expect(library.assets, hasLength(10));
    expect(library.hasMore, isTrue);
    expect(library.loadingMore, isFalse);

    library.loadMore();
    expect(library.loadMoreError, isNull);
    source.last.answer.complete(AssetBrowseResult(_page(10, 10), 25));
    await _settle();
    expect(library.assets, hasLength(20));
  });

  test('where is passed through to every page', () async {
    const unused = [BoolFilter('inUse', false)];
    library.where = unused;
    expect(source.calls, hasLength(2));
    expect(source.last.where, unused);
    source.last.answer.complete(AssetBrowseResult(_page(0, 10), 12));
    await _settle();
    library.loadMore();
    expect(source.last.where, unused);
    expect(source.last.index, 10);

    // The same conditions again reload nothing.
    source.last.answer.complete(AssetBrowseResult(_page(10, 2), 12));
    await _settle();
    library.where = unused;
    expect(source.calls, hasLength(3));
  });

  test('setting what is set already reloads nothing', () {
    library
      ..query = ''
      ..filter = AssetType.image
      ..where = const [];
    expect(source.calls, hasLength(1));
  });

  test('the view changes without a reload', () {
    library.view = AssetView.list;
    expect(library.view, AssetView.list);
    expect(notified, 1);
    expect(source.calls, hasLength(1));
  });

  test('replace shows a saved asset in place', () async {
    source.last.answer.complete(AssetBrowseResult(_page(0, 3), 3));
    await _settle();
    library.replace(
      const Asset(id: 'a1', name: 'a1.jpg', alt: {'en': 'A harbour'}),
    );
    expect(library.assets[1].alt, {'en': 'A harbour'});
    expect(library.assets.map((a) => a.id), ['a0', 'a1', 'a2']);

    notified = 0;
    library.replace(const Asset(id: 'gone', name: 'gone.jpg'));
    expect(notified, 0);
  });

  test('an answer after dispose is dropped', () async {
    final pending = source.last;
    final disposed = library;
    library = AssetLibraryController(source: source);
    disposed.dispose();
    pending.answer.complete(AssetBrowseResult(_page(0, 3), 3));
    await _settle();
    expect(disposed.assets, isEmpty);
    expect(disposed.loading, isTrue);
  });
}
