import 'package:admin_ui/src/collection/collection_controller.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionController<int> _make() {
  final all = List.generate(25, (i) => i);
  return CollectionController<int>(
    searchDebounce: Duration.zero,
    initialQuery: const CollectionQuery(pageSize: 10),
    fetcher: (q) async {
      var list = all;
      if (q.search.isNotEmpty) {
        list = list.where((n) => '$n'.contains(q.search)).toList();
      }
      for (final c in q.filters) {
        if (c case NumberRangeFilter(:final min, :final max)) {
          list = list
              .where(
                (n) => (min == null || n >= min) && (max == null || n <= max),
              )
              .toList();
        }
      }
      if (q.sortKey == 'desc') list = list.reversed.toList();
      final start = q.pageIndex * q.pageSize;
      return CollectionPage(
        items: list.skip(start).take(q.pageSize).toList(),
        total: list.length,
      );
    },
  );
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  test('loads the first page on construction', () async {
    final c = _make();
    await _settle();
    expect(c.items.length, 10);
    expect(c.total, 25);
    expect(c.from, 1);
    expect(c.to, 10);
    expect(c.hasNext, isTrue);
    expect(c.hasPrev, isFalse);
  });

  test('nextPage advances the offset', () async {
    final c = _make();
    await _settle();
    c.nextPage();
    await _settle();
    expect(c.from, 11);
    expect(c.items.first, 10);
    expect(c.hasPrev, isTrue);
  });

  test('sortBy resets to the first page', () async {
    final c = _make();
    await _settle();
    c.nextPage();
    await _settle();
    c.sortBy('desc', true);
    await _settle();
    expect(c.from, 1);
    expect(c.items.first, 24);
  });

  test('setSearch filters and recomputes the total', () async {
    final c = _make();
    await _settle();
    c.setSearch('1'); // 1,10..19,21 → 12 matches
    await _settle();
    expect(c.total, 12);
    expect(c.from, 1);
  });

  test('searchController is the durable source: seeds, drives, and survives', () async {
    final all = List.generate(25, (i) => i);
    final c = CollectionController<int>(
      searchDebounce: Duration.zero,
      initialQuery: const CollectionQuery(pageSize: 10, search: '2'),
      fetcher: (q) async {
        final list = q.search.isEmpty
            ? all
            : all.where((n) => '$n'.contains(q.search)).toList();
        return CollectionPage(
          items: list.take(q.pageSize).toList(),
          total: list.length,
        );
      },
    );
    // The box text is seeded from the initial query (so a remounted field shows
    // the active filter, not an empty box).
    expect(c.searchController.text, '2');
    await _settle();

    // Editing the box drives the query.
    c.searchController.text = '1'; // 1,10..19,21 → 12 matches
    await _settle();
    expect(c.query.search, '1');
    expect(c.total, 12);

    // Clearing the box clears the filter.
    c.searchController.clear();
    await _settle();
    expect(c.query.search, '');
    expect(c.total, 25);
  });

  test(
    'setFilters applies, resets the page, and drops inactive conditions',
    () async {
      final c = _make();
      await _settle();
      c.nextPage();
      await _settle();
      c.setFilters([
        const NumberRangeFilter('n', min: 10, max: 19),
        const NumberRangeFilter('n'), // inactive (no bounds) → dropped
      ]);
      await _settle();
      expect(c.from, 1); // page reset
      expect(c.total, 10); // 10..19
      expect(c.query.filters.length, 1); // inactive dropped
    },
  );

  test('captures fetch errors', () async {
    final c = CollectionController<int>(
      fetcher: (q) async => throw StateError('boom'),
    );
    await _settle();
    expect(c.error, isA<StateError>());
    expect(c.items, isEmpty);
  });
}
