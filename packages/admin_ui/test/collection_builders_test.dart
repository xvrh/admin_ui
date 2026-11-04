// The connected Collection forwards pinning and "Manage columns…" as it does
// hiding; card and cell builders take the context; ColumnChooserButton takes
// a size.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
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

CollectionController<_Row> _controller({int rows = 3}) =>
    CollectionController<_Row>(
      rowKey: (r) => r.id,
      searchDebounce: Duration.zero,
      fetcher: (q) async => CollectionPage(
        items: [for (var i = 0; i < rows; i++) _Row(i, 'row $i')],
        total: rows,
      ),
    );

final _columns = [
  TableColumn<_Row>(id: 'name', label: 'Name', cell: (r) => Text(r.name)),
  TableColumn<_Row>(
    id: 'id',
    label: 'Id',
    fixed: 90,
    cell: (r) => Text('${r.id}'),
  ),
];

Finder _menuButton(String label) => find.byWidgetPredicate(
  (w) => w is Tip && w.message == 'Column options for $label',
);

void main() {
  group('the connected Collection', () {
    testWidgets('forwards onPinColumn and onManageColumns to the table', (
      tester,
    ) async {
      final c = _controller();
      addTearDown(c.dispose);
      void pin(String key, bool pinned) {}
      void manage() {}
      await tester.pumpWidget(
        _host(
          Collection<_Row>(
            controller: c,
            columns: _columns,
            onPinColumn: pin,
            onManageColumns: manage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final table = tester.widget<CollectionTable<_Row>>(
        find.byType(CollectionTable<_Row>),
      );
      expect(table.onPinColumn, pin);
      expect(table.onManageColumns, manage);
    });

    testWidgets('offers "Pin column" and "Manage columns…" in a header menu', (
      tester,
    ) async {
      final c = _controller();
      addTearDown(c.dispose);
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Collection<_Row>(
            controller: c,
            columns: _columns,
            onPinColumn: (key, pinned) => calls.add('pin $key $pinned'),
            onManageColumns: () => calls.add('manage'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_menuButton('Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin column'));
      await tester.pumpAndSettle();
      await tester.tap(_menuButton('Id'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage columns…'));
      await tester.pumpAndSettle();
      expect(calls, ['pin name true', 'manage']);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('without them the header menu offers neither', (tester) async {
      final c = _controller();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _host(
          Collection<_Row>(
            controller: c,
            columns: _columns,
            onHideColumn: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_menuButton('Name'));
      await tester.pumpAndSettle();
      expect(find.text('Hide column'), findsOneWidget);
      expect(find.text('Pin column'), findsNothing);
      expect(find.text('Manage columns…'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  group('CollectionCards.cardBuilder', () {
    testWidgets('receives the card\'s own context', (tester) async {
      final contexts = <String, BuildContext>{};
      await tester.pumpWidget(
        _host(
          CollectionCards<String>(
            rows: const ['a', 'b'],
            cardBuilder: (context, row) {
              contexts[row] = context;
              return Text(row);
            },
          ),
        ),
      );
      expect(contexts.keys, ['a', 'b']);
      for (final MapEntry(key: row, value: context) in contexts.entries) {
        expect(context.mounted, isTrue);
        // Below the card's chrome: its Tappable is an ancestor.
        expect(context.findAncestorWidgetOfExactType<Tappable>(), isNotNull);
        expect(
          find.ancestor(of: find.text(row), matching: find.byType(Tappable)),
          findsWidgets,
        );
        expect(context.colors, defaultTokens.palette);
      }
    });

    testWidgets('a card\'s checkbox is a Tab stop of its own, after the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CollectionCards<String>(
            rows: const ['a', 'b'],
            selected: const {},
            onSelectionChanged: (_) {},
            onCardTap: (_) {},
            cardBuilder: (_, row) => SizedBox(height: 80, child: Text(row)),
          ),
        ),
      );
      final labels = <String?>[];
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus!;
        final text = find.descendant(
          of: find.byWidgetPredicate((w) => w is Focus && w.focusNode == focus),
          matching: find.byType(Text),
        );
        labels.add(
          text.evaluate().isEmpty
              ? 'checkbox'
              : tester.widget<Text>(text.first).data,
        );
      }
      expect(labels, ['a', 'checkbox', 'b', 'checkbox']);
      expect(tester.takeException(), isNull);
    });
  });

  group('TableColumn.cellBuilder', () {
    testWidgets('builds the cell with the cell\'s context', (tester) async {
      final contexts = <BuildContext>[];
      await tester.pumpWidget(
        _host(
          CollectionTable<_Row>(
            rows: [_Row(1, 'one'), _Row(2, 'two')],
            columns: [
              TableColumn<_Row>(
                label: 'Name',
                cellBuilder: (context, r) {
                  contexts.add(context);
                  return Text(r.name);
                },
              ),
            ],
          ),
        ),
      );
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(contexts, hasLength(2));
      for (final context in contexts) {
        expect(
          context.findAncestorWidgetOfExactType<CollectionTable<_Row>>(),
          isNotNull,
        );
        // Under the cell's text style, which a cell may read.
        expect(DefaultTextStyle.of(context).maxLines, 1);
      }
    });

    testWidgets('draws the same cell as the context-free cell', (tester) async {
      Future<Rect> rectOf(TableColumn<_Row> column) async {
        await tester.pumpWidget(
          _host(
            CollectionTable<_Row>(rows: [_Row(1, 'one')], columns: [column]),
          ),
        );
        return tester.getRect(find.text('one'));
      }

      expect(
        await rectOf(TableColumn(label: 'Name', cell: (r) => Text(r.name))),
        await rectOf(
          TableColumn(label: 'Name', cellBuilder: (_, r) => Text(r.name)),
        ),
      );
    });

    test('takes exactly one of cell and cellBuilder, and keeps it pinned', () {
      expect(
        () => TableColumn<_Row>(
          label: 'Name',
          cell: (r) => Text(r.name),
          cellBuilder: (_, r) => Text(r.name),
        ),
        throwsAssertionError,
      );
      expect(() => TableColumn<_Row>(label: 'Name'), throwsAssertionError);
      Widget build(BuildContext context, _Row r) => Text(r.name);
      final pinned = TableColumn<_Row>(
        label: 'Name',
        cellBuilder: build,
      ).withPinned(true);
      expect(pinned.pinned, isTrue);
      expect(pinned.cellBuilder, build);
      expect(pinned.cell, isNull);
    });
  });

  group('ColumnChooserButton.size', () {
    const columns = [
      ColumnChoice(key: 'name', label: 'Name'),
      ColumnChoice(key: 'status', label: 'Status'),
    ];
    Widget chooser({required ControlSize size}) => _host(
      Center(
        child: ColumnChooserButton(
          columns: columns,
          layout: const ColumnLayout(),
          onChanged: (_) {},
          size: size,
        ),
      ),
    );

    testWidgets('small is the icon trigger, medium and large the labelled '
        'button at that size', (tester) async {
      await tester.pumpWidget(chooser(size: ControlSize.small));
      expect(find.byType(IconAction), findsOneWidget);
      expect(find.byType(Button), findsNothing);

      for (final size in [ControlSize.medium, ControlSize.large]) {
        await tester.pumpWidget(chooser(size: size));
        expect(find.byType(IconAction), findsNothing);
        expect(tester.widget<Button>(find.byType(Button)).size, size);
      }
    });
  });
}
