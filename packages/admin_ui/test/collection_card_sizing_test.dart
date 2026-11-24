import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A Collection in cards hands its grid the sizing a CollectionCards takes.

class _Row {
  final int id;
  final String name;
  _Row(this.id, this.name);
}

CollectionController<_Row> _controller() => CollectionController<_Row>(
  rowKey: (r) => r.id,
  searchDebounce: Duration.zero,
  initialQuery: const CollectionQuery(pageSize: 10),
  fetcher: (q) async => CollectionPage(
    items: [for (var i = 0; i < 10; i++) _Row(i, 'row $i')],
    total: 10,
  ),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view
    ..physicalSize = const Size(1000, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

CollectionCards<_Row> _grid(WidgetTester tester) =>
    tester.widget(find.byType(CollectionCards<_Row>));

/// How many cards stand on the first row of the grid.
int _columns(WidgetTester tester) {
  final top = tester.getTopLeft(find.text('row 0')).dy;
  return [
    for (var i = 0; i < 10; i++)
      if (tester.getTopLeft(find.text('row $i')).dy == top) i,
  ].length;
}

void main() {
  late CollectionController<_Row> c;

  setUp(() => c = _controller());
  tearDown(() => c.dispose());

  Collection<_Row> collection({
    double minTileWidth = 240,
    double? tileHeight,
    double tileSpacing = AdminSpacing.xl,
    EdgeInsetsGeometry gridPadding = const EdgeInsets.all(AdminSpacing.xl),
  }) => Collection<_Row>(
    controller: c,
    columns: [TableColumn<_Row>(label: 'Name', cell: (r) => Text(r.name))],
    viewMode: CollectionViewMode.cards,
    cardBuilder: (_, r) => Text(r.name),
    minTileWidth: minTileWidth,
    tileHeight: tileHeight,
    tileSpacing: tileSpacing,
    gridPadding: gridPadding,
  );

  testWidgets('given none, the grid keeps its own sizing', (tester) async {
    await _pump(
      tester,
      Collection<_Row>(
        controller: c,
        columns: const [],
        viewMode: CollectionViewMode.cards,
        cardBuilder: (_, r) => Text(r.name),
      ),
    );

    final grid = _grid(tester);
    final own = CollectionCards<_Row>(
      rows: const [],
      cardBuilder: (_, _) => const SizedBox(),
    );
    expect(grid.minTileWidth, own.minTileWidth);
    expect(grid.tileHeight, own.tileHeight);
    expect(grid.spacing, own.spacing);
    expect(grid.padding, own.padding);
  });

  testWidgets('a wider minimum width leaves fewer columns', (tester) async {
    await _pump(tester, collection());
    expect(_columns(tester), 3);

    await _pump(tester, collection(minTileWidth: 400));
    expect(_columns(tester), 2);
  });

  testWidgets('the height, the spacing and the padding reach the grid', (
    tester,
  ) async {
    await _pump(
      tester,
      collection(
        tileHeight: 120,
        tileSpacing: AdminSpacing.md,
        gridPadding: EdgeInsets.zero,
      ),
    );

    final grid = _grid(tester);
    expect(grid.tileHeight, 120);
    expect(grid.spacing, AdminSpacing.md);
    expect(grid.padding, EdgeInsets.zero);
    // Unpadded, the first card stands at the grid's corner.
    expect(tester.getTopLeft(find.text('row 0')).dx, lessThan(AdminSpacing.xl));
  });
}
