import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Row {
  final int id;
  final String name;
  _Row(this.id, this.name);
}

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 900, height: 600, child: child),
    ),
  ),
);

final _columns = [TableColumn<_Row>(label: 'Name', cell: (r) => Text(r.name))];

/// A source of [count] rows, paged, with a search on the name.
CollectionController<_Row> _controller(
  int Function() count, {
  CollectionQuery query = const CollectionQuery(pageSize: 10),
}) => CollectionController<_Row>(
  rowKey: (r) => r.id,
  searchDebounce: Duration.zero,
  initialQuery: query,
  fetcher: (q) async {
    final all = [
      for (var i = 0; i < count(); i++)
        if ('row $i'.contains(q.search)) _Row(i, 'row $i'),
    ];
    final start = q.pageIndex * q.pageSize;
    return CollectionPage(
      items: all.skip(start).take(q.pageSize).toList(),
      total: all.length,
    );
  },
);

void main() {
  testWidgets('forwards the table props and the controller\'s hooks', (
    tester,
  ) async {
    final c = _controller(() => 30);
    addTearDown(c.dispose);
    void resize(String key, double width) {}
    void resizeEnd(String key, double width) {}
    await tester.pumpWidget(
      _host(
        Collection<_Row>(
          controller: c,
          columns: _columns,
          selectable: true,
          density: TableDensity.compact,
          rowHeight: 44,
          headerHeight: 40,
          striped: true,
          columnWidths: const {'Name': 200},
          onColumnResize: resize,
          onColumnResizeEnd: resizeEnd,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final table = tester.widget<CollectionTable<_Row>>(
      find.byType(CollectionTable<_Row>),
    );
    expect(table.rowKey, same(c.rowKey));
    expect(table.density, TableDensity.compact);
    expect(table.rowHeight, 44);
    expect(table.headerHeight, 40);
    expect(table.striped, isTrue);
    expect(table.columnWidths, {'Name': 200});
    expect(table.onColumnResize, resize);
    expect(table.onColumnResizeEnd, resizeEnd);
    expect(table.onClearSort, c.clearSort);
    expect(table.filtered, isFalse);
    expect(table.onClearFilters, isNull);
  });

  testWidgets('a failed load shows the kit ErrorState, in words, with Retry', (
    tester,
  ) async {
    var fail = true;
    var fetches = 0;
    final c = CollectionController<_Row>(
      rowKey: (r) => r.id,
      fetcher: (_) async {
        fetches++;
        if (fail) throw Exception('SocketException: Connection refused');
        return CollectionPage(items: [_Row(1, 'one')], total: 1);
      },
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(Collection<_Row>(controller: c, columns: _columns)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Couldn’t load'), findsOneWidget);
    expect(
      find.text('Can’t reach the server. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.byType(Pager), findsNothing);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(fetches, 2);
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('an ErrorTextScope words the error its own way', (tester) async {
    final c = CollectionController<_Row>(
      fetcher: (_) async => throw StateError('boom'),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(
        ErrorTextScope(
          describe: (e) => 'Custom: ${e.runtimeType}',
          child: Collection<_Row>(controller: c, columns: _columns),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Custom: StateError'), findsOneWidget);
  });

  testWidgets('the pager hides while there is nothing to page', (tester) async {
    var count = 0;
    final c = _controller(() => count);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(Collection<_Row>(controller: c, columns: _columns)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Pager), findsNothing);
    expect(find.textContaining('0 of 0'), findsNothing);

    count = 12;
    await c.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(Pager), findsOneWidget);
    expect(find.text('1–10 of 12'), findsOneWidget);
  });

  testWidgets('a failed reload hides the pager with the rows it counted', (
    tester,
  ) async {
    var fail = false;
    final c = _controller(() {
      if (fail) throw Exception('SocketException: Connection refused');
      return 3;
    });
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(Collection<_Row>(controller: c, columns: _columns)),
    );
    await tester.pumpAndSettle();
    expect(find.text('1–3 of 3'), findsOneWidget);

    fail = true;
    await c.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.byType(Pager), findsNothing);
    expect(find.text('1–3 of 3'), findsNothing);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsNothing);
    expect(find.text('1–3 of 3'), findsOneWidget);
  });

  testWidgets('deleting the last page\'s rows lands on the page before', (
    tester,
  ) async {
    var count = 25;
    final c = _controller(() => count);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(Collection<_Row>(controller: c, columns: _columns)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Page 3'));
    await tester.pumpAndSettle();
    expect(find.text('21–25 of 25'), findsOneWidget);

    count = 20;
    await c.refresh();
    await tester.pumpAndSettle();
    expect(find.textContaining('21–20'), findsNothing);
    expect(find.text('11–20 of 20'), findsOneWidget);
    expect(find.text('row 19'), findsOneWidget);
  });

  testWidgets('a filtered empty result clears search and filters in one go', (
    tester,
  ) async {
    final c = _controller(
      () => 5,
      query: const CollectionQuery(
        search: 'zzz',
        filters: [BoolFilter('flag', true)],
      ),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(
        Collection<_Row>(
          controller: c,
          columns: _columns,
          viewMode: CollectionViewMode.cards,
          cardBuilder: (_, r) => Text(r.name),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cards = tester.widget<CollectionCards<_Row>>(
      find.byType(CollectionCards<_Row>),
    );
    expect(cards.filtered, isTrue);
    expect(find.text('No results'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(c.query.search, isEmpty);
    expect(c.query.filters, isEmpty);
    expect(c.searchController.text, isEmpty);
    expect(find.text('row 4'), findsOneWidget);
  });

  testWidgets('a page-size pick from the footer reloads at that size', (
    tester,
  ) async {
    final c = _controller(() => 60);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(
        Collection<_Row>(
          controller: c,
          columns: _columns,
          showPageSize: true,
          pageSizes: const [10, 25],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 / page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25 / page').last);
    await tester.pumpAndSettle();
    expect(c.pageSize, 25);
    expect(find.text('1–25 of 60'), findsOneWidget);
  });
}
