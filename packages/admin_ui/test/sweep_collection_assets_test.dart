import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {double width = 900, double height = 600}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

/// The focused node's widget ancestors include one of type [T].
bool _focusIn<T extends Widget>() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<T>() !=
    null;

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

class _Row {
  final String name;
  final double price;
  const _Row(this.name, this.price);
}

const _rows = [_Row('Coat', 20), _Row('Boots', 30), _Row('Scarf', 10)];

const _assets = [
  Asset(id: 'a', name: 'hero.jpg', width: 2400, height: 1350),
  Asset(id: 'b', name: 'logo.png', width: 512, height: 512),
];

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('table', () {
    Widget table({Set<_Row> selected = const {}, TableSort? sort}) =>
        CollectionTable<_Row>(
          rows: _rows,
          rowKey: (r) => r.name,
          selected: selected,
          onSelectionChanged: (_) {},
          sort: sort,
          onSort: (_, _) {},
          onHideColumn: (_) {},
          columns: [
            TableColumn(label: 'Name', cell: (r) => Text(r.name)),
            TableColumn(
              label: 'Price',
              sortKey: 'price',
              numeric: true,
              cell: (r) => Text('${r.price}'),
            ),
          ],
        );

    testWidgets('selection checkboxes are named', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(table(selected: {_rows[1]})));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Select all on page')),
        isSemantics(hasCheckedState: true, isCheckStateMixed: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Select row 1')),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Select row 2')),
        isSemantics(isChecked: true),
      );
      expect(find.bySemanticsLabel('Select row 3'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('sort headers announce their state; ⋮ names its column', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(table(sort: const TableSort('price'))));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Price, sorted ascending')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel('Column options for Price'), findsOneWidget);
      expect(find.bySemanticsLabel('Column options for Name'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('one Tab stop; arrows reach a header, whose ⋮ shows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              Expanded(child: table()),
              TextButton(onPressed: () {}, child: const Text('After')),
            ],
          ),
        ),
      );
      await _tab(tester);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'CollectionTable');
      Opacity menu(String column) => tester.widget<Opacity>(
        find.ancestor(
          of: find.bySemanticsLabel('Column options for $column'),
          matching: find.byType(Opacity),
        ),
      );
      // Focus starts on row 1: ↑ to the header, → to Name, → to Price.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(menu('Price').opacity, 1);
      expect(menu('Name').opacity, 0);
      expect(_focusIn<IconAction>(), isFalse, reason: 'the grid keeps focus');

      await _tab(tester);
      expect(_focusIn<TextButton>(), isTrue, reason: 'Tab leaves the table');
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  testWidgets('the filter pill × is its own named action', (tester) async {
    final handle = tester.ensureSemantics();
    List<FilterCondition> active = const [
      OptionsFilter('zone', {'north'}, label: 'Zone'),
    ];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => FilterBar(
            fields: const [
              OptionsFilterField('zone', 'Zone', [
                FilterOption('north', 'North'),
                FilterOption('south', 'South'),
              ]),
            ],
            active: active,
            onChanged: (next) => setState(() => active = next),
          ),
        ),
      ),
    );
    final clear = find.bySemanticsLabel('Clear Zone filter');
    expect(clear, findsOneWidget);
    final box = tester.getSize(
      find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconAction),
      ),
    );
    expect(box, const Size(24, 24));

    // The pill, then its ×: Enter on the × clears.
    await _tab(tester);
    await _tab(tester);
    expect(_focusIn<IconAction>(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(active, isEmpty);
    handle.dispose();
  });

  testWidgets('kanban cards and card tiles open on Enter', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            SizedBox(
              height: 220,
              child: KanbanBoard<_Row>(
                columns: const [
                  KanbanColumn(id: 'todo', title: 'To do', items: _rows),
                ],
                itemKey: (r) => r.name,
                cardBuilder: (_, r) => Text('card ${r.name}'),
                onCardTap: (r) => opened.add('kanban ${r.name}'),
              ),
            ),
            Expanded(
              child: CollectionCards<_Row>(
                rows: _rows,
                tileHeight: 80,
                cardBuilder: (_, r) => Text('tile ${r.name}'),
                onCardTap: (r) => opened.add('tile ${r.name}'),
              ),
            ),
          ],
        ),
      ),
    );
    await _tab(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['kanban Coat']);

    for (var i = 0; i < 3; i++) {
      await _tab(tester);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened.last, 'tile Coat');
  });

  group('assets', () {
    testWidgets('a grid tile is a named, selectable Tab stop', (tester) async {
      final handle = tester.ensureSemantics();
      final toggled = <String>[];
      var confirmed = 0;
      await tester.pumpWidget(
        _host(
          AssetLibrary(
            assets: _assets,
            selectionMode: AssetSelectionMode.multiple,
            selected: const {'b'},
            onToggle: toggled.add,
            onConfirm: () => confirmed++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('hero.jpg, 2400 × 1350')),
        isSemantics(
          isButton: true,
          isFocusable: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('logo.png, 512 × 512')),
        isSemantics(isSelected: true),
      );
      expect(find.bySemanticsLabel('Grid view'), findsOneWidget);
      expect(find.bySemanticsLabel('List view'), findsOneWidget);

      // Search, type filter, view toggle, then the first tile.
      for (var i = 0; i < 12 && !_focusIn<GridView>(); i++) {
        await _tab(tester);
      }
      expect(_focusIn<GridView>(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(toggled, ['a']);
      expect(confirmed, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(toggled, ['a', 'a'], reason: 'Enter picks an unpicked asset');
      expect(confirmed, 1);
      handle.dispose();
    });

    testWidgets('a provider tile selects on Space and confirms on Enter', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final picked = <String>[];
      var confirmed = 0;
      await tester.pumpWidget(
        _host(
          ProviderBrowser(
            providerLabel: 'Stock',
            items: const [
              ProviderItem(id: 'p1', title: 'Harbour', width: 800, height: 600),
            ],
            onSelect: (i) => picked.add(i.id),
            onConfirm: () => confirmed++,
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('^Harbour')), findsOneWidget);
      for (var i = 0; i < 12 && !_focusIn<GridView>(); i++) {
        await _tab(tester);
      }
      expect(_focusIn<GridView>(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(picked, ['p1']);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(confirmed, 1);
      handle.dispose();
    });
  });
}
