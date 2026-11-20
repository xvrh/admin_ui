import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A Collection with a compactViewMode lays its rows out that way while its
// window is compact, and as viewMode says in a wider one.

class _Row {
  final int id;
  final String name;
  _Row(this.id, this.name);
}

final _columns = [TableColumn<_Row>(label: 'Name', cell: (r) => Text(r.name))];

CollectionController<_Row> _controller() => CollectionController<_Row>(
  rowKey: (r) => r.id,
  searchDebounce: Duration.zero,
  initialQuery: const CollectionQuery(pageSize: 10),
  fetcher: (q) async {
    final all = [for (var i = 0; i < 30; i++) _Row(i, 'row $i')];
    final start = q.pageIndex * q.pageSize;
    return CollectionPage(
      items: all.skip(start).take(q.pageSize).toList(),
      total: all.length,
    );
  },
);

Widget _card(BuildContext context, _Row row) => Text('card ${row.name}');

/// A window [width] wide.
void _window(WidgetTester tester, double width) {
  tester.view
    ..physicalSize = Size(width, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  AdminBreakpoints? breakpoints,
}) async {
  final tokens = breakpoints == null
      ? irisTheme.tokens
      : irisTheme.tokens.copyWith(breakpoints: breakpoints);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

final _table = find.byType(CollectionTable<_Row>);
final _cards = find.byType(CollectionCards<_Row>);

void main() {
  late CollectionController<_Row> c;

  setUp(() => c = _controller());
  tearDown(() => c.dispose());

  Collection<_Row> collection({
    CollectionViewMode viewMode = CollectionViewMode.table,
    CollectionViewMode? compactViewMode = CollectionViewMode.cards,
    bool selectable = false,
  }) => Collection<_Row>(
    controller: c,
    columns: _columns,
    viewMode: viewMode,
    compactViewMode: compactViewMode,
    cardBuilder: _card,
    selectable: selectable,
  );

  testWidgets('with none, a table stays a table on a phone', (tester) async {
    _window(tester, 393);
    await _pump(tester, collection(compactViewMode: null));
    expect(_table, findsOneWidget);
    expect(_cards, findsNothing);
  });

  testWidgets('a compact window shows the compact layout', (tester) async {
    _window(tester, 393);
    await _pump(tester, collection());
    expect(_cards, findsOneWidget);
    expect(_table, findsNothing);
    expect(find.text('card row 0'), findsOneWidget);
  });

  testWidgets('a wider window shows viewMode', (tester) async {
    _window(tester, 1000);
    await _pump(tester, collection());
    expect(_table, findsOneWidget);
    expect(_cards, findsNothing);
  });

  testWidgets('it switches at the theme\'s medium breakpoint', (tester) async {
    _window(tester, 599);
    await _pump(tester, collection());
    expect(_cards, findsOneWidget);

    _window(tester, 600);
    await tester.pumpAndSettle();
    expect(_table, findsOneWidget);

    // A theme with its own width.
    await _pump(
      tester,
      collection(),
      breakpoints: const AdminBreakpoints(medium: 800, expanded: 1200),
    );
    expect(_cards, findsOneWidget);
    _window(tester, 800);
    await tester.pumpAndSettle();
    expect(_table, findsOneWidget);
  });

  testWidgets('the page and the selection carry across the switch', (
    tester,
  ) async {
    _window(tester, 1000);
    await _pump(tester, collection(selectable: true));
    c.nextPage();
    await tester.pumpAndSettle();
    c.setSelected({c.items.firstWhere((r) => r.id == 12)});
    await tester.pumpAndSettle();
    expect(find.text('row 12'), findsOneWidget);

    _window(tester, 393);
    await tester.pumpAndSettle();
    expect(find.text('card row 12'), findsOneWidget);
    expect(find.text('card row 0'), findsNothing);
    expect(
      tester.widget<CollectionCards<_Row>>(_cards).selected!.map((r) => r.id),
      [12],
    );

    _window(tester, 1000);
    await tester.pumpAndSettle();
    expect(find.text('row 12'), findsOneWidget);
    expect(
      tester.widget<CollectionTable<_Row>>(_table).selected!.map((r) => r.id),
      [12],
    );
  });

  testWidgets('it follows the window, not the collection\'s own width', (
    tester,
  ) async {
    _window(tester, 1000);
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 320, height: 600, child: collection()),
      ),
    );
    expect(_table, findsOneWidget);
  });

  testWidgets('either layout can be the compact one', (tester) async {
    _window(tester, 393);
    await _pump(
      tester,
      collection(
        viewMode: CollectionViewMode.cards,
        compactViewMode: CollectionViewMode.table,
      ),
    );
    expect(_table, findsOneWidget);
    _window(tester, 1000);
    await tester.pumpAndSettle();
    expect(_cards, findsOneWidget);
  });

  test('compact cards need a cardBuilder', () {
    expect(
      () => Collection<_Row>(
        controller: c,
        columns: _columns,
        compactViewMode: CollectionViewMode.cards,
      ),
      throwsAssertionError,
    );
    // A compact table needs none.
    Collection<_Row>(
      controller: c,
      columns: _columns,
      compactViewMode: CollectionViewMode.table,
    );
  });
}
