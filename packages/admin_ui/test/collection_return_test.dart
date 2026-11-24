import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A list that gives its place to a row's page and gets it back stands where
// it stood, with the focus on the row it opened.

class _Row {
  final int id;
  final String name;
  _Row(this.id, this.name);
}

final _columns = [TableColumn<_Row>(label: 'Name', cell: (r) => Text(r.name))];

/// The rows the fetcher serves, which a test may change while the list is
/// away.
List<_Row> _source = [];

CollectionController<_Row> _controller() {
  _source = [for (var i = 0; i < 40; i++) _Row(i, 'row $i')];
  return CollectionController<_Row>(
    rowKey: (r) => r.id,
    searchDebounce: Duration.zero,
    initialQuery: const CollectionQuery(pageSize: 50),
    fetcher: (q) async {
      final rows = [..._source];
      if (q.sortKey != null && !q.ascending) rows.setAll(0, rows.reversed);
      return CollectionPage(items: rows, total: rows.length);
    },
  );
}

/// A list page that a row's page takes the place of, as a router swaps them.
class _Host extends StatefulWidget {
  final CollectionController<_Row> controller;
  final CollectionViewMode viewMode;

  /// Whether opening a row leaves for its page.
  final bool leaves;
  final Widget? above;
  final bool ringOnReturn;

  const _Host(
    this.controller, {
    super.key,
    this.viewMode = CollectionViewMode.table,
    this.leaves = true,
    this.above,
    this.ringOnReturn = true,
  });

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool away = false;

  void leave() => setState(() => away = true);
  void back() => setState(() => away = false);

  @override
  Widget build(BuildContext context) {
    if (away) return const Text('a row\'s page');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?widget.above,
        Expanded(
          child: Collection<_Row>(
            controller: widget.controller,
            columns: _columns,
            viewMode: widget.viewMode,
            ringOnReturn: widget.ringOnReturn,
            cardBuilder: (context, row) =>
                SizedBox(height: 120, child: Text('card ${row.name}')),
            onRowTap: (_) {
              if (widget.leaves) leave();
            },
          ),
        ),
      ],
    );
  }
}

final _host = GlobalKey<_HostState>();

Future<void> _pump(WidgetTester tester, Widget host) async {
  tester.view
    ..physicalSize = const Size(800, 600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(body: host),
    ),
  );
  await tester.pumpAndSettle();
}

/// The rows' vertical scroll, in a table or a card view.
ScrollPosition _rows(WidgetTester tester) => tester
    .stateList<ScrollableState>(
      find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    )
    .single
    .position;

Future<void> _scrollTo(WidgetTester tester, double offset) async {
  _rows(tester).jumpTo(offset);
  await tester.pumpAndSettle();
}

Future<void> _goAndComeBack(WidgetTester tester) async {
  if (!_host.currentState!.away) _host.currentState!.leave();
  await tester.pumpAndSettle();
  expect(find.text('a row\'s page'), findsOneWidget);
  _host.currentState!.back();
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

bool get _gridFocused =>
    FocusManager.instance.primaryFocus?.debugLabel == 'CollectionTable';

Finder get _ring => find.byWidgetPredicate((w) => w is FocusRing && w.focused);

bool _ringOn(WidgetTester tester, String text) => tester
    .getRect(_ring)
    .inflate(8)
    .contains(tester.getCenter(find.text(text)));

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('a table back from a row\'s page shows that row where it was, '
      'ringed', (tester) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(tester, _Host(rows, key: _host));
    await _scrollTo(tester, 600);
    final before = _top(tester, 'row 20');

    await tester.tap(find.text('row 20'));
    await _goAndComeBack(tester);

    expect(_rows(tester).pixels, 600);
    expect(_top(tester, 'row 20'), before);
    expect(_gridFocused, isTrue);
    expect(_ringOn(tester, 'row 20'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_ringOn(tester, 'row 21'), isTrue);
  });

  testWidgets('without ringOnReturn, a row a click opened comes back focused '
      'but not ringed', (tester) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(tester, _Host(rows, key: _host, ringOnReturn: false));
    await _scrollTo(tester, 600);

    await tester.tap(find.text('row 20'));
    await _goAndComeBack(tester);

    expect(_gridFocused, isTrue);
    expect(_ring, findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_ringOn(tester, 'row 21'), isTrue);
  });

  testWidgets('rows that came above it while away do not move it', (
    tester,
  ) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(tester, _Host(rows, key: _host));
    await _scrollTo(tester, 600);
    final before = _top(tester, 'row 20');
    await tester.tap(find.text('row 20'));
    await tester.pumpAndSettle();

    _source.insertAll(0, [for (var i = 0; i < 3; i++) _Row(100 + i, 'new $i')]);
    await rows.refresh(background: true);
    await _goAndComeBack(tester);

    expect(_top(tester, 'row 20'), before);
  });

  testWidgets('without ringOnReturn, a row the keyboard opened still comes '
      'back with its ring', (tester) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(tester, _Host(rows, key: _host, ringOnReturn: false));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(_gridFocused, isTrue);
    // Focus lands on the first row.
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.pump();
    expect(_ringOn(tester, 'row 5'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _goAndComeBack(tester);

    expect(_gridFocused, isTrue);
    expect(_ringOn(tester, 'row 5'), isTrue);
  });

  testWidgets('a list left with its opened row out of sight comes back '
      'scrolled as it was, its focus left alone', (tester) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(tester, _Host(rows, key: _host, leaves: false));
    await tester.tap(find.text('row 2'));
    await _scrollTo(tester, 1000);
    FocusManager.instance.primaryFocus?.unfocus();

    await _goAndComeBack(tester);

    expect(_rows(tester).pixels, 1000);
    expect(_gridFocused, isFalse);
  });

  testWidgets('focus another control holds stays there', (tester) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(
      tester,
      _Host(rows, key: _host, above: const TextField(autofocus: true)),
    );
    await _scrollTo(tester, 600);
    await tester.tap(find.text('row 20'));
    await _goAndComeBack(tester);

    expect(_rows(tester).pixels, 600);
    expect(_gridFocused, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextField>(),
      isNotNull,
    );
  });

  testWidgets('a click on a selectable page leaves the focus to the row', (
    tester,
  ) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(tester, SelectionArea(child: _Host(rows, key: _host)));
    await _scrollTo(tester, 600);
    await tester.tap(find.text('row 20'));
    await tester.pumpAndSettle();

    // A click on the page gives the SelectionArea around it the focus,
    // which is the focus given back when the page goes.
    await tester.tap(find.text('a row\'s page'));
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<SelectableRegion>(),
      isNotNull,
    );
    _host.currentState!.back();
    await tester.pumpAndSettle();

    expect(_gridFocused, isTrue);
    expect(_ringOn(tester, 'row 20'), isTrue);
  });

  testWidgets('a query changed while away starts the list at the top', (
    tester,
  ) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(tester, _Host(rows, key: _host));
    await _scrollTo(tester, 600);
    await tester.tap(find.text('row 20'));
    await tester.pumpAndSettle();

    rows.sortBy('name', false);
    await _goAndComeBack(tester);

    expect(rows.position, isNull);
    expect(_rows(tester).pixels, 0);
    expect(_gridFocused, isFalse);
  });

  testWidgets('rows that land after the table is built are scrolled to', (
    tester,
  ) async {
    const position = CollectionPosition(offset: 400);
    Widget table({required bool loaded}) => CollectionTable<_Row>(
      rows: loaded ? [for (var i = 0; i < 40; i++) _Row(i, 'row $i')] : [],
      loading: !loaded,
      rowKey: (r) => r.id,
      columns: _columns,
      initialPosition: position,
    );
    await _pump(tester, table(loaded: false));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: Scaffold(body: table(loaded: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(_rows(tester).pixels, 400);
  });

  testWidgets('a card view back from a card\'s page is scrolled as it was, '
      'the card focused', (tester) async {
    final rows = _controller();
    addTearDown(rows.dispose);
    await _pump(
      tester,
      _Host(rows, key: _host, viewMode: CollectionViewMode.cards),
    );
    await _scrollTo(tester, 500);

    await tester.tap(find.text('card row 12'));
    await _goAndComeBack(tester);

    expect(_rows(tester).pixels, 500);
    expect(
      Focus.of(tester.element(find.text('card row 12'))).hasPrimaryFocus,
      isTrue,
    );
  });
}
