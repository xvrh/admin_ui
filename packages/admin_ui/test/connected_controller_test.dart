import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// A row whose identity is its [id]; every fetch returns fresh objects, as a
/// server's DTOs are.
class _Row {
  final int id;
  final String name;
  _Row(this.id, this.name);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('dispose', () {
    test('while the fetcher is pending: the late result is dropped', () async {
      final pending = Completer<CollectionPage<int>>();
      final c = CollectionController<int>(fetcher: (_) => pending.future);
      var notified = 0;
      c.addListener(() => notified++);
      c.dispose();
      expect(c.isDisposed, isTrue);

      // Would notify a disposed notifier, which asserts in debug builds.
      pending.complete(const CollectionPage(items: [1], total: 1));
      await _settle();
      expect(notified, 0);
      expect(c.items, isEmpty);
    });

    test('a failed fetch landing after dispose is dropped too', () async {
      final pending = Completer<CollectionPage<int>>();
      final c = CollectionController<int>(fetcher: (_) => pending.future);
      c.dispose();
      pending.completeError(StateError('late'));
      await _settle();
      expect(c.error, isNull);
    });

    test('load() after dispose does nothing', () async {
      var fetches = 0;
      final c = CollectionController<int>(
        fetcher: (_) async {
          fetches++;
          return const CollectionPage(items: [], total: 0);
        },
      );
      await _settle();
      c.dispose();
      await c.load();
      expect(fetches, 1);
    });

    test('a search debounce pending at dispose never fires', () async {
      final queries = <String>[];
      final c = CollectionController<int>(
        searchDebounce: const Duration(milliseconds: 20),
        fetcher: (q) async {
          queries.add(q.search);
          return const CollectionPage(items: [], total: 0);
        },
      );
      await _settle();
      c.setSearch('abc');
      c.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(queries, ['']);
    });
  });

  group('search debounce', () {
    test('typed and taken back within the window: no fetch', () async {
      final queries = <String>[];
      final c = CollectionController<int>(
        searchDebounce: const Duration(milliseconds: 30),
        initialQuery: const CollectionQuery(search: 'boot'),
        fetcher: (q) async {
          queries.add(q.search);
          return const CollectionPage(items: [], total: 0);
        },
      );
      addTearDown(c.dispose);
      await _settle();
      expect(queries, ['boot']);

      c.searchController.text = 'boots';
      c.searchController.text = 'boot';
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(queries, ['boot']);
      expect(c.query.search, 'boot');
    });

    test('the timer applies the text as it stands when it fires', () async {
      final queries = <String>[];
      final c = CollectionController<int>(
        searchDebounce: const Duration(milliseconds: 30),
        fetcher: (q) async {
          queries.add(q.search);
          return const CollectionPage(items: [], total: 0);
        },
      );
      addTearDown(c.dispose);
      await _settle();
      c.searchController.text = 'a';
      await Future<void>.delayed(const Duration(milliseconds: 10));
      c.searchController.text = 'ab';
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(queries, ['', 'ab']);
    });

    test(
      'setSearch updates the box and goes through the same debounce',
      () async {
        final queries = <String>[];
        final c = CollectionController<int>(
          searchDebounce: const Duration(milliseconds: 30),
          fetcher: (q) async {
            queries.add(q.search);
            return const CollectionPage(items: [], total: 0);
          },
        );
        addTearDown(c.dispose);
        await _settle();
        c.setSearch('x');
        expect(c.searchController.text, 'x');
        expect(queries, ['']);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(queries, ['', 'x']);
      },
    );
  });

  group('page clamp', () {
    test(
      'the last page emptied: back to the page now holding the last rows',
      () async {
        var rows = List.generate(25, (i) => i);
        final pages = <int>[];
        final c = CollectionController<int>(
          initialQuery: const CollectionQuery(pageSize: 10),
          fetcher: (q) async {
            pages.add(q.pageIndex);
            final start = q.pageIndex * q.pageSize;
            return CollectionPage(
              items: rows.skip(start).take(q.pageSize).toList(),
              total: rows.length,
            );
          },
        );
        addTearDown(c.dispose);
        await _settle();
        c.nextPage();
        await _settle();
        c.nextPage();
        await _settle();
        expect((c.pageIndex, c.from, c.to), (2, 21, 25));

        // A bulk delete took the five rows of the last page.
        rows = rows.take(20).toList();
        await c.refresh();
        await _settle();
        expect(pages, [0, 1, 2, 2, 1]);
        expect(c.pageIndex, 1);
        expect((c.from, c.to, c.total), (11, 20, 20));
        expect(c.items, hasLength(10));
        expect(c.hasNext, isFalse);
        expect(c.loading, isFalse);
      },
    );

    test('every row gone: page 0, with no refetch', () async {
      var rows = List.generate(15, (i) => i);
      var fetches = 0;
      final c = CollectionController<int>(
        initialQuery: const CollectionQuery(pageSize: 10),
        fetcher: (q) async {
          fetches++;
          final start = q.pageIndex * q.pageSize;
          return CollectionPage(
            items: rows.skip(start).take(q.pageSize).toList(),
            total: rows.length,
          );
        },
      );
      addTearDown(c.dispose);
      await _settle();
      c.nextPage();
      await _settle();
      rows = [];
      await c.refresh();
      await _settle();
      expect(fetches, 3);
      expect((c.pageIndex, c.from, c.to, c.total), (0, 0, 0, 0));
      expect(c.hasPrev, isFalse);
    });

    test('an unknown total steps back one page', () async {
      var rows = List.generate(25, (i) => i);
      final c = CollectionController<int>(
        initialQuery: const CollectionQuery(pageSize: 10),
        fetcher: (q) async {
          final start = q.pageIndex * q.pageSize;
          return CollectionPage(
            items: rows.skip(start).take(q.pageSize).toList(),
            hasNext: start + q.pageSize < rows.length,
          );
        },
      );
      addTearDown(c.dispose);
      await _settle();
      c.nextPage();
      await _settle();
      c.nextPage();
      await _settle();
      rows = rows.take(20).toList();
      await c.refresh();
      await _settle();
      expect(c.pageIndex, 1);
      expect((c.from, c.to), (11, 20));
    });
  });

  group('selection', () {
    CollectionController<_Row> make() {
      return CollectionController<_Row>(
        rowKey: (r) => r.id,
        initialQuery: const CollectionQuery(pageSize: 3),
        fetcher: (q) async {
          final all = [
            for (var i = 0; i < 9; i++)
              if (q.filters.isEmpty || i.isEven) _Row(i, 'row $i'),
          ];
          final start = q.pageIndex * q.pageSize;
          return CollectionPage(
            items: all.skip(start).take(q.pageSize).toList(),
            total: all.length,
          );
        },
      );
    }

    test('survives a refetch of fresh objects, by key', () async {
      final c = make();
      addTearDown(c.dispose);
      await _settle();
      final first = c.items[1];
      c.setSelected({first});
      await c.refresh();
      await _settle();

      final fresh = c.items[1];
      expect(identical(fresh, first), isFalse);
      expect(c.isSelected(fresh), isTrue);
      expect(c.allOnPageSelected, isFalse);
      expect(c.selectedKeys, {1});
      // The selection now holds the fresh copy.
      expect(identical(c.selected.single, fresh), isTrue);
    });

    test(
      'kept across pages and sort; the bulk bar counts both pages',
      () async {
        final c = make();
        addTearDown(c.dispose);
        await _settle();
        c.toggleSelected(c.items[0]);
        c.nextPage();
        await _settle();
        c.toggleSelected(c.items[0]);
        expect(c.selectedKeys, {0, 3});
        c.sortBy('name', false);
        await _settle();
        c.setPageSize(5);
        await _settle();
        expect(c.selectedKeys, {0, 3});
      },
    );

    test('cleared when filters, search or advanced change', () async {
      final c = make();
      addTearDown(c.dispose);
      await _settle();
      c.setSelected({c.items[0]});
      c.setFilters(const [BoolFilter('even', true)]);
      expect(c.selected, isEmpty);
      await _settle();

      c.setSelected({c.items[0]});
      c.setAdvanced('x');
      expect(c.selected, isEmpty);
      await _settle();

      c.setSelected({c.items[0]});
      c.clearSearchAndFilters();
      expect(c.selected, isEmpty);
      await _settle();
    });

    test('is read-only from outside', () async {
      final c = make();
      addTearDown(c.dispose);
      await _settle();
      c.setSelected({c.items[0]});
      expect(() => c.selected.add(c.items[1]), throwsUnsupportedError);
    });

    test('without a rowKey, rows compare by ==', () async {
      final c = CollectionController<int>(
        fetcher: (_) async => const CollectionPage(items: [1, 2, 3], total: 3),
      );
      addTearDown(c.dispose);
      await _settle();
      c.toggleSelected(2);
      expect(c.isSelected(2), isTrue);
      c.toggleSelected(2);
      expect(c.selected, isEmpty);
    });
  });

  group('partial pagination', () {
    test(
      'no total: hasNext comes from the page, the total is a lower bound',
      () async {
        final c = CollectionController<int>(
          initialQuery: const CollectionQuery(pageSize: 10),
          fetcher: (q) async => CollectionPage(
            items: List.generate(10, (i) => q.pageIndex * 10 + i),
            hasNext: q.pageIndex < 2,
          ),
        );
        addTearDown(c.dispose);
        await _settle();
        expect(c.totalKnown, isFalse);
        expect(c.pageCount, isNull);
        expect(c.hasNext, isTrue);
        expect((c.from, c.to, c.total), (1, 10, 10));
        c.nextPage();
        await _settle();
        c.nextPage();
        await _settle();
        expect(c.pageIndex, 2);
        expect(c.hasNext, isFalse);
        expect((c.from, c.to), (21, 30));
      },
    );

    test('a known total gives a page count and a goToPage bound', () async {
      final c = CollectionController<int>(
        initialQuery: const CollectionQuery(pageSize: 10),
        fetcher: (q) async => CollectionPage(
          items: List.generate(
            10,
            (i) => q.pageIndex * 10 + i,
          ).where((n) => n < 42).toList(),
          total: 42,
        ),
      );
      addTearDown(c.dispose);
      await _settle();
      expect(c.totalKnown, isTrue);
      expect(c.pageCount, 5);
      c.goToPage(99);
      await _settle();
      expect(c.pageIndex, 4);
      expect((c.from, c.to), (41, 42));
    });
  });

  test('clearSort drops the sort key', () async {
    final c = CollectionController<int>(
      initialQuery: const CollectionQuery(sortKey: 'name', ascending: false),
      fetcher: (_) async => const CollectionPage(items: [], total: 0),
    );
    addTearDown(c.dispose);
    await _settle();
    c.clearSort();
    expect(c.query.sortKey, isNull);
    expect(c.query.ascending, isTrue);
  });

  test('clearSearchAndFilters applies at once, past the debounce', () async {
    final queries = <CollectionQuery>[];
    final c = CollectionController<int>(
      initialQuery: const CollectionQuery(
        search: 'x',
        filters: [BoolFilter('f', true)],
        advanced: 'adv',
      ),
      fetcher: (q) async {
        queries.add(q);
        return const CollectionPage(items: [], total: 0);
      },
    );
    addTearDown(c.dispose);
    await _settle();
    expect(c.isFiltered, isTrue);
    c.clearSearchAndFilters();
    await _settle();
    expect(queries, hasLength(2));
    expect(c.isFiltered, isFalse);
    expect(c.searchController.text, isEmpty);
    // No second, debounced fetch for the emptied box.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(queries, hasLength(2));
  });
}
