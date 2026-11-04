import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../sample.dart';

/// Demo — each header cell reveals a discreet ⋮ on hover, or when its cell
/// has keyboard focus (Alt+↓ opens it), that opens a per-column menu: Sort
/// ascending / descending, Clear sort, Pin / Unpin column, Reset width once a
/// column is resized, Hide column and Manage columns…. Pins, hiding and
/// widths flow out into a [ColumnLayout]; the small [ColumnChooserButton]
/// in the controls, or Manage columns…, restores hidden columns. The Name
/// column opts out of hiding (`hideable: false`).
class DataTableHeaderMenuDemo extends StatefulWidget {
  @Preview(name: 'Column header menu', wrapper: adminUiPreview)
  const DataTableHeaderMenuDemo({super.key});

  @override
  State<DataTableHeaderMenuDemo> createState() =>
      _DataTableHeaderMenuDemoState();
}

class _DataTableHeaderMenuDemoState extends State<DataTableHeaderMenuDemo> {
  ColumnLayout _layout = const ColumnLayout();
  TableSort? _sort = const TableSort('name');

  static const _choices = [
    ColumnChoice(key: 'name', label: 'Name', locked: true),
    ColumnChoice(key: 'category', label: 'Category'),
    ColumnChoice(key: 'status', label: 'Status'),
    ColumnChoice(key: 'price', label: 'Price'),
    ColumnChoice(key: 'stock', label: 'Stock'),
  ];

  @override
  Widget build(BuildContext context) {
    return collectionFrame(
      context,
      controls: _controls(context),
      table: CollectionTable<Product>(
        rows: _rows,
        rowKey: (p) => p.id,
        sort: _sort,
        onSort: (key, asc) =>
            setState(() => _sort = TableSort(key, ascending: asc)),
        onClearSort: () => setState(() => _sort = null),
        columnWidths: _layout.widths,
        onColumnResize: (key, width) =>
            setState(() => _layout = _layout.withWidth(key, width)),
        onHideColumn: (key) =>
            setState(() => _layout = _layout.withVisible(key, false)),
        onPinColumn: (key, pinned) =>
            setState(() => _layout = _layout.withPinned(key, pinned)),
        onManageColumns: _manageColumns,
        columns: _layout.apply(_allColumns),
      ),
    );
  }

  Future<void> _manageColumns() => showModal<void>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) => Modal(
        title: 'Columns',
        onDismiss: () => Navigator.of(context).maybePop(),
        maxWidth: 320,
        body: ColumnChooser(
          columns: _choices,
          layout: _layout,
          onChanged: (layout) {
            setState(() => _layout = layout);
            setSheet(() {});
          },
        ),
      ),
    ),
  );

  Widget _controls(BuildContext context) {
    final hidden = _choices.where((c) => !_layout.isVisible(c.key)).toList();
    return Row(
      children: [
        Expanded(
          child: Text(
            hidden.isEmpty
                ? 'Hover a header → ⋮ → Sort / Clear sort / Hide column · '
                      'Alt+↓ on a focused header'
                : 'Hidden: ${hidden.map((c) => c.label).join(', ')}',
            style: context.type.caption,
          ),
        ),
        const Gap(AdminSpacing.md),
        ColumnChooserButton(
          size: ControlSize.small,
          columns: _choices,
          layout: _layout,
          onChanged: (l) => setState(() => _layout = l),
          onReset: _layout == const ColumnLayout()
              ? null
              : () => setState(() => _layout = const ColumnLayout()),
        ),
      ],
    );
  }

  List<Product> get _rows {
    final list = sampleProducts(12);
    final sort = _sort;
    if (sort == null) return list;
    int cmp(Product a, Product b) => switch (sort.key) {
      'category' => a.category.compareTo(b.category),
      'price' => a.price.compareTo(b.price),
      _ => a.name.compareTo(b.name),
    };
    list.sort((a, b) => sort.ascending ? cmp(a, b) : cmp(b, a));
    return list;
  }

  List<TableColumn<Product>> get _allColumns => [
    TableColumn(
      id: 'name',
      label: 'Name',
      flex: 2,
      minWidth: 200,
      pinned: true,
      hideable: false,
      sortKey: 'name',
      cell: productIdentity,
    ),
    TableColumn(
      id: 'category',
      label: 'Category',
      fixed: 150,
      sortKey: 'category',
      cellBuilder: (context, p) =>
          Text(p.category, style: tableMutedStyle(context)),
    ),
    TableColumn(
      id: 'status',
      label: 'Status',
      fixed: 150,
      cell: (p) => Tag(p.status, severity: p.tone, dot: true),
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
      id: 'stock',
      label: 'Stock',
      fixed: 90,
      numeric: true,
      cellBuilder: (context, p) =>
          Text(p.stock?.toString() ?? '—', style: tableMutedStyle(context)),
    ),
  ];
}
