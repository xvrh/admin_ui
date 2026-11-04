import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Product {
  final int id;
  final String name;
  final double price;
  final String updated;
  const _Product(this.id, this.name, this.price, this.updated);
}

const _products = [
  _Product(1, 'Aurora Wool Coat', 248, '2026-06-12'),
  _Product(2, 'Cedar Throw Blanket', 64, '2026-05-21'),
  _Product(3, 'Harbor Wool Socks', 18, '2026-06-01'),
  _Product(4, 'Summit Daypack', 120, '2026-06-14'),
];

List<TableColumn<_Product>> _columns(BuildContext context) => [
  TableColumn(
    id: 'name',
    label: 'Product',
    pinned: true,
    minWidth: 200,
    sortKey: 'name',
    hideable: false,
    cell: (p) => Text(p.name),
  ),
  TableColumn(
    id: 'price',
    label: 'Price',
    fixed: 110,
    numeric: true,
    sortKey: 'price',
    cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
  ),
  TableColumn(
    id: 'updated',
    label: 'Updated',
    fixed: 130,
    cell: (p) => Text(p.updated, style: tableMutedStyle(context)),
  ),
];

/// The table's exhibits: a striped, sorted, selectable table with a
/// selection on a plain and on a striped row, and a filtered one with no
/// rows.
final _exhibits = <String, Widget Function(BuildContext)>{
  'rows': (context) => CollectionTable<_Product>(
    rows: _products,
    rowKey: (p) => p.id,
    striped: true,
    sort: const TableSort('price', ascending: false),
    onSort: (_, _) {},
    onClearSort: () {},
    onRowTap: (_) {},
    onHideColumn: (_) {},
    selected: {_products[0], _products[1]},
    onSelectionChanged: (_) {},
    columns: _columns(context),
  ),
  'no results': (context) => CollectionTable<_Product>(
    rows: const [],
    filtered: true,
    onClearFilters: () {},
    columns: _columns(context),
  ),
};

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      if (dark && !theme.hasDark) continue;
      final mode = dark ? 'Dark' : 'Light';
      // The theme's palette, radii, focus ring and table, without its font.
      final tokens = dark ? theme.dark! : theme.tokens;
      final data = buildAppTheme(
        AdminTokens.from(
          palette: tokens.palette,
          radii: tokens.radii,
          focus: tokens.focus,
          table: tokens.table,
        ),
      );

      for (final MapEntry(key: name, value: build) in _exhibits.entries) {
        for (final (guideline, what) in [
          (labeledTapTargetGuideline, 'labelled targets'),
          (textContrastGuideline, 'text contrast'),
        ]) {
          testWidgets('${theme.name} $mode, $name: $what', (tester) async {
            final handle = tester.ensureSemantics();
            tester.view.physicalSize = const Size(900, 500);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MaterialApp(
                theme: data,
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Builder(builder: build),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await expectLater(tester, meetsGuideline(guideline));
            handle.dispose();
          });
        }
      }
    }
  }

  group('grid semantics', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextButton(onPressed: () {}, child: const Text('Before')),
                Expanded(child: Builder(builder: _exhibits['rows']!)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The nearest node above [node] that has a role, and its role.
    SemanticsNode roleAbove(SemanticsNode node) {
      var parent = node.parent;
      while (parent != null && parent.role == SemanticsRole.none) {
        parent = parent.parent;
      }
      return parent!;
    }

    /// The node with a role that holds [text].
    SemanticsNode cellOf(WidgetTester tester, Finder text) {
      var node = tester.getSemantics(text);
      while (node.role == SemanticsRole.none) {
        node = node.parent!;
      }
      return node;
    }

    testWidgets('a table of rows, each of column headers or cells', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      final header = cellOf(tester, find.text('Price'));
      expect(header.role, SemanticsRole.columnHeader);
      final headerRow = roleAbove(header);
      expect(headerRow.role, SemanticsRole.row);
      expect(headerRow.indexInParent, 0);
      final table = roleAbove(headerRow);
      expect(table.role, SemanticsRole.table);

      final cell = cellOf(tester, find.text('Cedar Throw Blanket'));
      expect(cell.role, SemanticsRole.cell);
      final row = roleAbove(cell);
      expect(row.role, SemanticsRole.row);
      expect(row.indexInParent, 2);
      expect(roleAbove(row), same(table));

      // Every child of the table is a row, and every child of a row a cell
      // or a column header: the checks a debug build runs on each update.
      final roles = <SemanticsRole>{};
      table.visitChildren((row) {
        expect(row.role, SemanticsRole.row);
        row.visitChildren((cell) {
          roles.add(cell.role);
          return true;
        });
        return true;
      });
      expect(roles, {SemanticsRole.columnHeader, SemanticsRole.cell});
      handle.dispose();
    });

    testWidgets('the focused cell is the focus target, and moves with it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      bool focused(Finder text) =>
          cellOf(
            tester,
            text,
          ).getSemanticsData().flagsCollection.isFocused.toBoolOrNull() ??
          false;

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(find.text('Aurora Wool Coat')), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(find.text('Aurora Wool Coat')), isFalse);
      expect(focused(find.text('Cedar Throw Blanket')), isTrue);
      handle.dispose();
    });
  });
}
